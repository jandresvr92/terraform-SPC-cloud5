#!/bin/bash

# Logging para debugging
exec > >(tee /var/log/user-data.log) 2>&1
echo "Iniciando configuración del backend..."

# Actualizar sistema
sudo yum update -y
sudo yum install -y git

# Obtener IP pública de la instancia
BACKEND_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "IP del backend: $BACKEND_IP"

# Instalar NVM y Node.js como ec2-user
sudo -u ec2-user bash -c '
export HOME=/home/ec2-user
cd $HOME

# Instalar NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Instalar Node.js LTS
nvm install --lts
nvm use --lts

# Clonar el repositorio
git clone https://github.com/jandresvr92/secretos-para-contar.git /home/ec2-user/secretos-para-contar

# Navegar al directorio del backend (corregido)
cd /home/ec2-user/secretos-para-contar/backend-new

# Instalar dependencias
npm install

# Obtener IP pública
BACKEND_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# Crear archivo de entorno para desarrollo
cat << EOT > .env
NODE_ENV=development
PORT=3001

# Database Configuration
DATABASE_URL=./database/spc.db

# JWT Configuration
JWT_SECRET=spc-super-secret-jwt-key-change-in-production-2024
JWT_EXPIRES_IN=7d

# CORS Configuration
FRONTEND_URL=https://18.219.121.194:5173

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# File Upload Configuration
MAX_FILE_SIZE=10485760

# Server Configuration
HOST=localhost
EOT

# Verificar que la base de datos existe, si no, crearla
if [ ! -f database/spc.db ]; then
  echo "Creando base de datos..."
  # Ejecutar script de inicialización si existe
  if [ -f database/init.js ]; then
    node database/init.js
  fi
fi

# Inicializar/poblar la base de datos si el script existe
if [ -f package.json ] && grep -q "seed" package.json; then
  npm run seed
fi

# Instalar PM2 globalmente
npm install -g pm2

# Crear archivo de configuración PM2
cat << EOT > ecosystem.config.js
module.exports = {
  apps: [{
    name: "spc-backend",
    script: "server.js",
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: "1G",
    env: {
      NODE_ENV: "production",
      PORT: 3001
    }
  }]
};
EOT

# Iniciar el backend con PM2
pm2 start ecosystem.config.js

# Configurar PM2 para arrancar con el sistema
pm2 startup
pm2 save

# Verificar que el proceso está corriendo
pm2 list
pm2 logs spc-backend --lines 10
'

# Verificar que el puerto 3001 está escuchando
echo "Verificando que el backend está corriendo..."
sleep 15
netstat -tlnp | grep :3001 || echo "Advertencia: El puerto 3001 no está escuchando"

# Mostrar información útil
echo "Configuración del backend completada."
echo "Backend IP: $BACKEND_IP"
echo "Backend URL: http://$BACKEND_IP:3001"
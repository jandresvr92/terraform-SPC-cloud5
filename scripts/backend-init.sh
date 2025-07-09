#!/bin/bash
sudo yum update -y
sudo yum install -y git

# Instalar NVM (Node Version Manager) y Node.js/npm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts
nvm use --lts

# Clonar el repositorio del backend
git clone https://github.com/jandresvr92/secretos-para-contar.git /home/ec2-user/secretos-para-contar

# Navegar al directorio del backend
cd /home/ec2-user/secretos-para-contar/project/backend

# Instalar dependencias
npm install

# Copiar archivo de entorno si no existe
if [ ! -f .env ]; then
  cp .env.example .env
  # Aquí puedes usar sed o echo para modificar variables si lo necesitas
fi

# Inicializar la base de datos (opcional, solo si es la primera vez)
npm run seed

# Instalar PM2 globalmente para mantener el proceso activo
npm install -g pm2

# Iniciar el backend con PM2
pm2 start server.js --name spc-backend

# Hacer que PM2 arranque con el sistema
pm2 startup
pm2 save
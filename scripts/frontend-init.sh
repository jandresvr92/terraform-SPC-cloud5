#!/bin/bash

# Logging para debugging
exec > >(tee /var/log/user-data.log) 2>&1
echo "Iniciando configuración del frontend..."

# Actualizar sistema
sudo yum update -y
sudo yum install -y git

# Obtener IP del frontend
FRONTEND_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

echo "IP del frontend: $FRONTEND_IP"
echo "IP del backend (inyectada por Terraform): ${backend_ip}"

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

# Navegar al directorio del frontend
cd /home/ec2-user/secretos-para-contar/frontend

# Crear archivo de entorno para el frontend con la IP del backend inyectada por Terraform
echo "VITE_API_URL=http://${backend_ip}:3001" > .env

# Instalar dependencias
npm install

# Construir la aplicación
npm run build
'

# Instalar y configurar Nginx
sudo yum install -y nginx

# Verificar que la build se creó correctamente
if [ ! -d "/home/ec2-user/secretos-para-contar/frontend/dist" ]; then
    echo "Error: La carpeta dist no se creó correctamente"
    ls -la /home/ec2-user/secretos-para-contar/frontend/
    exit 1
fi

# Crear archivo de configuración de Nginx para la SPA
sudo bash -c 'cat << EOT > /etc/nginx/conf.d/default.conf
server {
    listen 80;
    server_name _;

    root /home/ec2-user/secretos-para-contar/frontend/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Configuración para el cache de assets
    location ~* \.(?:ico|css|js|gif|jpe?g|png)$ {
        expires 1y;
        add_header Cache-Control "public";
    }
}
EOT'

# Limpiar la configuración por defecto de Nginx
sudo sed -i '/server_name _;/a \    return 444;' /etc/nginx/nginx.conf

# Verificar la configuración de Nginx
sudo nginx -t

# Iniciar y habilitar Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

sudo systemctl restart nginx

# Verificar el estado de Nginx
sudo systemctl status nginx

echo "Configuración del frontend completada."
echo "Frontend URL: http://$FRONTEND_IP"
echo "Nginx status:"
sudo systemctl is-active nginx

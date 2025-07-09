#!/bin/bash
sudo yum update -y
sudo yum install -y git

# Instalar NVM (Node Version Manager) y Node.js/npm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts
nvm use --lts

# Clonar el repositorio del frontend
git clone https://github.com/jandresvr92/secretos-para-contar.git /home/ec2-user/secretos-para-contar

# Navegar al directorio y construir la aplicación React
cd /home/ec2-user/secretos-para-contar/frontend
npm install
npm run build

# Instalar y configurar Nginx
sudo yum install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Limpiar el directorio HTML predeterminado de Nginx
sudo rm -rf /usr/share/nginx/html/*
# Copiar los archivos de la build de React al directorio de Nginx
sudo cp -r build/* /usr/share/nginx/html/

# Configurar Nginx para servir la aplicación React (manejo de SPA routing)
sudo bash -c 'cat << EOT > /etc/nginx/nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  "\$remote_addr - \$remote_user [\$time_local] \"\$request\" "
                      "\$status \$body_bytes_sent \"\$http_referer\" "
                      "\"\$http_user_agent\" \"\$http_x_forwarded_for\"";

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    server {
        listen       80 default_server;
        listen       [::]:80 default_server;
        server_name  _;
        root         /usr/share/nginx/html;

        location / {
            try_files \$uri \$uri/ /index.html;
        }

        error_page 404 /404.html;
            location = /40x.html {
        }

        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }
    }
}
EOT'

sudo systemctl restart
#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Развертывание Cynical Circle на Ubuntu/Debian...${NC}"

# Получаем IP сервера
SERVER_IP=$(curl -s ifconfig.me)
echo -e "${YELLOW}📡 IP сервера: $SERVER_IP${NC}"

# Обновляем систему
echo -e "${YELLOW}🔄 Обновляем систему...${NC}"
apt update && apt upgrade -y

# Устанавливаем необходимые пакеты
echo -e "${YELLOW}📦 Устанавливаем пакеты...${NC}"
apt install -y python3 python3-pip python3-venv nginx git curl

# Настраиваем файрвол (ufw для Ubuntu/Debian)
echo -e "${YELLOW}🔥 Настраиваем файрвол...${NC}"
ufw allow ssh
ufw allow 80
ufw allow 443
ufw --force enable

# Создаем директорию
echo -e "${YELLOW}📁 Создаем директорию...${NC}"
mkdir -p /var/www/cynical-circle
chown -R www-data:www-data /var/www/cynical-circle

# Копируем файлы (предполагаем, что мы в директории проекта)
echo -e "${YELLOW}📋 Копируем файлы...${NC}"
cp -r frontend /var/www/cynical-circle/
cp -r backend /var/www/cynical-circle/

# Переходим в директорию проекта
cd /var/www/cynical-circle/frontend

# Создаем виртуальное окружение
echo -e "${YELLOW}🐍 Создаем виртуальное окружение...${NC}"
python3 -m venv venv
source venv/bin/activate

# Устанавливаем зависимости
echo -e "${YELLOW}📦 Устанавливаем зависимости...${NC}"
pip install --upgrade pip
pip install -r requirements.txt
pip install gunicorn

# Создаем systemd сервис
echo -e "${YELLOW}⚙️ Создаем systemd сервис...${NC}"
tee /etc/systemd/system/cynical-circle.service > /dev/null <<EOF
[Unit]
Description=Cynical Circle FastAPI Application
After=network.target

[Service]
Type=exec
User=www-data
Group=www-data
WorkingDirectory=/var/www/cynical-circle/frontend
Environment=PATH=/var/www/cynical-circle/frontend/venv/bin
ExecStart=/var/www/cynical-circle/frontend/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Создаем nginx конфигурацию
echo -e "${YELLOW}🌐 Создаем nginx конфигурацию...${NC}"
tee /etc/nginx/sites-available/cynical-circle > /dev/null <<EOF
server {
    listen 80;
    server_name $SERVER_IP;
    
    access_log /var/log/nginx/cynical-circle.access.log;
    error_log /var/log/nginx/cynical-circle.error.log;
    
    location /static/ {
        alias /var/www/cynical-circle/frontend/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location / {
        try_files \$uri \$uri/ @fallback;
    }
    
    location @fallback {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Активируем конфигурации
echo -e "${YELLOW}🔗 Активируем конфигурации...${NC}"
ln -sf /etc/nginx/sites-available/cynical-circle /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Устанавливаем права
echo -e "${YELLOW}🔐 Настраиваем права...${NC}"
chown -R www-data:www-data /var/www/cynical-circle
chmod -R 755 /var/www/cynical-circle

# Перезапускаем сервисы
echo -e "${YELLOW}🔄 Перезапускаем сервисы...${NC}"
systemctl daemon-reload
systemctl enable cynical-circle
systemctl start cynical-circle
systemctl restart nginx

# Проверяем статус
echo -e "${YELLOW}✅ Проверяем статус...${NC}"
systemctl status cynical-circle --no-pager
systemctl status nginx --no-pager

echo -e "${GREEN}🎉 Развертывание завершено!${NC}"
echo -e "${GREEN}🌐 Сайт доступен по адресу: http://$SERVER_IP${NC}"
echo -e "${YELLOW}📝 API доступен по адресу: http://$SERVER_IP/api/${NC}"

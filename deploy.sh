#!/bin/bash

# Скрипт автоматического развертывания Cynical Circle
# Использование: ./deploy.sh [server_ip] [domain]

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Параметры
SERVER_IP=${1:-"localhost"}
DOMAIN=${2:-"$SERVER_IP"}
APP_DIR="/opt/cynical-circle"
DB_NAME="cynical_circle"
DB_USER="cynical_app"
DB_PASSWORD="secure_password_123"

echo -e "${BLUE}🚀 Начинаем развертывание Cynical Circle${NC}"
echo -e "${BLUE}📊 Сервер: $SERVER_IP${NC}"
echo -e "${BLUE}🌐 Домен: $DOMAIN${NC}"

# Функция для вывода сообщений
log() {
    echo -e "${GREEN}✅ $1${NC}"
}

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

# Проверка прав sudo
if [ "$EUID" -ne 0 ]; then
    error "Запустите скрипт с правами sudo: sudo ./deploy.sh"
fi

# 1. Обновление системы
log "Обновление системы..."
apt update && apt upgrade -y

# 2. Установка необходимых пакетов
log "Установка пакетов..."
apt install -y curl wget git python3 python3-pip python3-venv postgresql postgresql-contrib nginx ufw

# 3. Настройка PostgreSQL
log "Настройка PostgreSQL..."
systemctl start postgresql
systemctl enable postgresql

# Создание базы данных и пользователя
sudo -u postgres psql << EOF
CREATE DATABASE $DB_NAME;
CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
\q
EOF

# 4. Создание директории приложения
log "Создание директории приложения..."
mkdir -p $APP_DIR
chown -R www-data:www-data $APP_DIR

# 5. Копирование файлов приложения
log "Копирование файлов приложения..."
if [ -d "./frontend" ]; then
    cp -r ./frontend/* $APP_DIR/
    cp -r ./database $APP_DIR/
else
    error "Директория frontend не найдена. Запустите скрипт из корня проекта."
fi

# 6. Настройка базы данных
log "Настройка базы данных..."
cd $APP_DIR/database
chmod +x setup.sh setup-no-password.sh fix-postgres-connection.sh

# Пробуем сначала обычный способ
if ./setup.sh $DB_NAME $DB_USER $DB_PASSWORD localhost 5432; then
    log "База данных настроена обычным способом"
else
    warn "Обычный способ не сработал, пробуем альтернативный..."
    if ./setup-no-password.sh $DB_NAME $DB_USER $DB_PASSWORD localhost 5432; then
        log "База данных настроена альтернативным способом"
    else
        error "Не удалось настроить базу данных. Запустите: sudo ./fix-postgres-connection.sh"
    fi
fi

# 7. Настройка Python окружения
log "Настройка Python окружения..."
cd $APP_DIR
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# 8. Создание файла конфигурации
log "Создание конфигурации..."
cat > $APP_DIR/.env << EOF
DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME
HOST=0.0.0.0
PORT=8000
DEBUG=False
SECRET_KEY=$(openssl rand -hex 32)
EOF

# 9. Создание systemd сервиса
log "Создание systemd сервиса..."
cat > /etc/systemd/system/cynical-circle.service << EOF
[Unit]
Description=Cynical Circle API
After=network.target postgresql.service

[Service]
Type=exec
User=www-data
Group=www-data
WorkingDirectory=$APP_DIR
Environment=PATH=$APP_DIR/venv/bin
ExecStart=$APP_DIR/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# 10. Настройка Nginx
log "Настройка Nginx..."
cat > /etc/nginx/sites-available/cynical-circle << EOF
server {
    listen 80;
    server_name $DOMAIN;

    access_log /var/log/nginx/cynical-circle.access.log;
    error_log /var/log/nginx/cynical-circle.error.log;

    location /static/ {
        alias $APP_DIR/static/;
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
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# 11. Активация конфигурации Nginx
log "Активация конфигурации Nginx..."
ln -sf /etc/nginx/sites-available/cynical-circle /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t

# 12. Настройка прав доступа
log "Настройка прав доступа..."
chown -R www-data:www-data $APP_DIR
chmod -R 755 $APP_DIR
chmod +x $APP_DIR/database/setup.sh

# 13. Настройка firewall
log "Настройка firewall..."
ufw --force enable
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw deny 5432/tcp
ufw deny 8000/tcp

# 14. Запуск сервисов
log "Запуск сервисов..."
systemctl daemon-reload
systemctl restart postgresql
systemctl restart nginx
systemctl start cynical-circle
systemctl enable cynical-circle

# 15. Проверка статуса
log "Проверка статуса сервисов..."
sleep 5

if systemctl is-active --quiet cynical-circle; then
    log "✅ Cynical Circle сервис запущен"
else
    error "❌ Cynical Circle сервис не запустился"
fi

if systemctl is-active --quiet nginx; then
    log "✅ Nginx запущен"
else
    error "❌ Nginx не запустился"
fi

if systemctl is-active --quiet postgresql; then
    log "✅ PostgreSQL запущен"
else
    error "❌ PostgreSQL не запустился"
fi

# 16. Тестирование API
log "Тестирование API..."
sleep 10

if curl -s http://localhost/api/ > /dev/null; then
    log "✅ API отвечает"
else
    warn "⚠️  API не отвечает, проверьте логи"
fi

# 17. Создание скрипта бэкапа
log "Создание скрипта бэкапа..."
mkdir -p /opt/backups/cynical-circle
cat > /opt/cynical-circle/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/backups/cynical-circle"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Бэкап базы данных
sudo -u postgres pg_dump cynical_circle > $BACKUP_DIR/db_$DATE.sql

# Бэкап кода
tar -czf $BACKUP_DIR/code_$DATE.tar.gz /opt/cynical-circle

# Удаление старых бэкапов
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete

echo "Backup completed: $DATE"
EOF

chmod +x /opt/cynical-circle/backup.sh

# 18. Настройка cron для бэкапов
log "Настройка автоматических бэкапов..."
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/cynical-circle/backup.sh") | crontab -

# 19. Финальная проверка
log "Финальная проверка..."
echo -e "${BLUE}📊 Статус сервисов:${NC}"
systemctl status cynical-circle --no-pager -l
echo -e "${BLUE}🌐 Проверка портов:${NC}"
netstat -tlnp | grep -E ':(80|8000|5432)'

echo -e "${GREEN}🎉 Развертывание завершено!${NC}"
echo -e "${BLUE}🌐 Приложение доступно по адресу: http://$SERVER_IP${NC}"
echo -e "${BLUE}📊 API документация: http://$SERVER_IP/docs${NC}"
echo -e "${BLUE}📋 Логи приложения: journalctl -u cynical-circle -f${NC}"
echo -e "${BLUE}🔧 Конфигурация: $APP_DIR${NC}"

echo -e "${YELLOW}⚠️  Не забудьте:${NC}"
echo -e "${YELLOW}   1. Настроить SSL сертификат для HTTPS${NC}"
echo -e "${YELLOW}   2. Изменить пароли по умолчанию${NC}"
echo -e "${YELLOW}   3. Настроить мониторинг${NC}"
echo -e "${YELLOW}   4. Регулярно обновлять систему${NC}"

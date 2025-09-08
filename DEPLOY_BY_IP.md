# 🌐 Развертывание Cynical Circle по IP адресу

## 📋 Быстрый старт

### 1. Подготовка сервера

#### Подключение к серверу
```bash
ssh username@YOUR_SERVER_IP
```

#### Обновление системы
```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y

# CentOS/RHEL
sudo yum update -y
```

#### Установка необходимых пакетов
```bash
# Ubuntu/Debian
sudo apt install -y python3 python3-pip python3-venv nginx git curl

# CentOS/RHEL
sudo yum install -y python3 python3-pip nginx git curl
```

### 2. Настройка файрвола
```bash
# Ubuntu/Debian (ufw)
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable

# CentOS/RHEL (firewalld)
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

## 🚀 Развертывание приложения

### 1. Клонирование проекта
```bash
# Создаем директорию
sudo mkdir -p /var/www
cd /var/www

# Клонируем проект
sudo git clone https://github.com/yourusername/QA_TRAINER.git cynical-circle
sudo chown -R $USER:$USER cynical-circle
cd cynical-circle/frontend
```

### 2. Настройка Python окружения
```bash
# Создаем виртуальное окружение
python3 -m venv venv
source venv/bin/activate

# Устанавливаем зависимости
pip install --upgrade pip
pip install -r requirements.txt

# Устанавливаем gunicorn для продакшена
pip install gunicorn
```

### 3. Создание systemd сервиса

Создайте файл `/etc/systemd/system/cynical-circle.service`:
```ini
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
```

### 4. Настройка nginx

Создайте файл `/etc/nginx/sites-available/cynical-circle`:
```nginx
server {
    listen 80;
    server_name YOUR_SERVER_IP;  # Замените на ваш IP
    
    # Логи
    access_log /var/log/nginx/cynical-circle.access.log;
    error_log /var/log/nginx/cynical-circle.error.log;
    
    # Статические файлы
    location /static/ {
        alias /var/www/cynical-circle/frontend/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # API запросы
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # HTML страницы
    location / {
        try_files $uri $uri/ @fallback;
    }
    
    # Fallback для SPA
    location @fallback {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 5. Активация конфигураций

```bash
# Включаем сайт в nginx
sudo ln -s /etc/nginx/sites-available/cynical-circle /etc/nginx/sites-enabled/

# Удаляем дефолтную конфигурацию
sudo rm /etc/nginx/sites-enabled/default

# Проверяем конфигурацию nginx
sudo nginx -t

# Перезапускаем nginx
sudo systemctl restart nginx

# Включаем автозапуск приложения
sudo systemctl daemon-reload
sudo systemctl enable cynical-circle
sudo systemctl start cynical-circle

# Проверяем статус
sudo systemctl status cynical-circle
```

## 🔧 Настройка для работы по IP

### 1. Обновление CORS в приложении

Создайте файл `frontend/app/ip_config.py`:
```python
# Настройки для работы по IP
CORS_ORIGINS = [
    "http://YOUR_SERVER_IP",
    "http://YOUR_SERVER_IP:80",
    "http://YOUR_SERVER_IP:8000",
    "http://localhost",
    "http://127.0.0.1",
]

# Добавьте в main.py
from fastapi.middleware.cors import CORSMiddleware
from .ip_config import CORS_ORIGINS

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### 2. Обновление JavaScript для работы с IP

В файле `frontend/static/script.js` замените:
```javascript
// Было
const API_BASE_URL = '/api';

// Стало (если нужно)
const API_BASE_URL = '/api';  // Оставляем как есть, nginx проксирует
```

### 3. Проверка доступности

```bash
# Проверяем, что приложение слушает порт 8000
sudo netstat -tlnp | grep 8000

# Проверяем nginx
sudo systemctl status nginx

# Тестируем API
curl http://YOUR_SERVER_IP/api/

# Тестируем главную страницу
curl http://YOUR_SERVER_IP/
```

## 🛠️ Автоматический скрипт развертывания

Создайте файл `deploy_ip.sh`:
```bash
#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Развертывание Cynical Circle по IP...${NC}"

# Получаем IP сервера
SERVER_IP=$(curl -s ifconfig.me)
echo -e "${YELLOW}📡 IP сервера: $SERVER_IP${NC}"

# Обновляем систему
echo -e "${YELLOW}🔄 Обновляем систему...${NC}"
sudo apt update && sudo apt upgrade -y

# Устанавливаем необходимые пакеты
echo -e "${YELLOW}📦 Устанавливаем пакеты...${NC}"
sudo apt install -y python3 python3-pip python3-venv nginx git curl

# Настраиваем файрвол
echo -e "${YELLOW}🔥 Настраиваем файрвол...${NC}"
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw --force enable

# Создаем директорию
echo -e "${YELLOW}📁 Создаем директорию...${NC}"
sudo mkdir -p /var/www/cynical-circle
sudo chown -R $USER:$USER /var/www/cynical-circle

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
sudo tee /etc/systemd/system/cynical-circle.service > /dev/null <<EOF
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
sudo tee /etc/nginx/sites-available/cynical-circle > /dev/null <<EOF
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
sudo ln -sf /etc/nginx/sites-available/cynical-circle /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Устанавливаем права
echo -e "${YELLOW}🔐 Настраиваем права...${NC}"
sudo chown -R www-data:www-data /var/www/cynical-circle
sudo chmod -R 755 /var/www/cynical-circle

# Перезапускаем сервисы
echo -e "${YELLOW}🔄 Перезапускаем сервисы...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable cynical-circle
sudo systemctl start cynical-circle
sudo systemctl restart nginx

# Проверяем статус
echo -e "${YELLOW}✅ Проверяем статус...${NC}"
sudo systemctl status cynical-circle --no-pager
sudo systemctl status nginx --no-pager

echo -e "${GREEN}🎉 Развертывание завершено!${NC}"
echo -e "${GREEN}🌐 Сайт доступен по адресу: http://$SERVER_IP${NC}"
echo -e "${YELLOW}📝 API доступен по адресу: http://$SERVER_IP/api/${NC}"
```

### Использование скрипта:
```bash
# Сделать скрипт исполняемым
chmod +x deploy_ip.sh

# Запустить развертывание
./deploy_ip.sh
```

## 🔍 Проверка работы

### 1. Проверка сервисов
```bash
# Статус приложения
sudo systemctl status cynical-circle

# Статус nginx
sudo systemctl status nginx

# Проверка портов
sudo netstat -tlnp | grep -E ':(80|8000)'
```

### 2. Тестирование API
```bash
# Тест главной страницы
curl http://YOUR_SERVER_IP/

# Тест API
curl http://YOUR_SERVER_IP/api/

# Тест пользователей
curl http://YOUR_SERVER_IP/api/users/
```

### 3. Проверка логов
```bash
# Логи приложения
sudo journalctl -u cynical-circle -f

# Логи nginx
sudo tail -f /var/log/nginx/cynical-circle.access.log
```

## 🛠️ Устранение неполадок

### Проблема: Сайт не открывается
```bash
# Проверяем статус сервисов
sudo systemctl status cynical-circle nginx

# Проверяем порты
sudo netstat -tlnp | grep -E ':(80|8000)'

# Проверяем файрвол
sudo ufw status
```

### Проблема: 502 Bad Gateway
```bash
# Проверяем, что приложение слушает порт 8000
sudo netstat -tlnp | grep 8000

# Перезапускаем приложение
sudo systemctl restart cynical-circle

# Проверяем логи
sudo journalctl -u cynical-circle -n 50
```

### Проблема: Статические файлы не загружаются
```bash
# Проверяем права доступа
sudo chown -R www-data:www-data /var/www/cynical-circle
sudo chmod -R 755 /var/www/cynical-circle

# Перезапускаем nginx
sudo systemctl restart nginx
```

## 📱 Доступ к сайту

После успешного развертывания сайт будет доступен по адресу:
- **Главная страница**: `http://YOUR_SERVER_IP/`
- **API**: `http://YOUR_SERVER_IP/api/`
- **Документация API**: `http://YOUR_SERVER_IP/docs`

## 🔄 Обновление приложения

```bash
# Переходим в директорию проекта
cd /var/www/cynical-circle

# Обновляем код
git pull origin main

# Перезапускаем приложение
sudo systemctl restart cynical-circle
```

## 📊 Мониторинг

### Просмотр логов в реальном времени
```bash
# Логи приложения
sudo journalctl -u cynical-circle -f

# Логи nginx
sudo tail -f /var/log/nginx/cynical-circle.access.log
```

### Проверка ресурсов
```bash
# Использование CPU и памяти
htop

# Использование диска
df -h

# Сетевые соединения
sudo netstat -tlnp
```

---

**Готово!** Ваш сайт теперь доступен по IP адресу без необходимости в домене! 🎉

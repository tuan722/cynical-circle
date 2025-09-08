# Руководство по развертыванию Cynical Circle

## Обзор

Это руководство описывает процесс развертывания полного стека Cynical Circle на одном сервере без домена. Включает в себя:
- PostgreSQL база данных
- FastAPI backend
- HTML/CSS/JavaScript frontend
- Nginx как reverse proxy

## Системные требования

### Минимальные требования:
- **OS**: Ubuntu 20.04+ / CentOS 8+ / Debian 11+
- **RAM**: 2GB (рекомендуется 4GB)
- **CPU**: 2 ядра
- **Диск**: 20GB свободного места
- **Порты**: 80, 443, 5432, 8000

### Рекомендуемые требования:
- **OS**: Ubuntu 22.04 LTS
- **RAM**: 4GB+
- **CPU**: 4 ядра+
- **Диск**: 50GB+ SSD

## Быстрый старт

### 1. Подготовка сервера

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка необходимых пакетов
sudo apt install -y curl wget git python3 python3-pip python3-venv postgresql postgresql-contrib nginx

# Проверка версий
python3 --version  # Должно быть 3.8+
psql --version     # Должно быть 12+
nginx -v           # Должно быть 1.18+
```

### 2. Настройка PostgreSQL

```bash
# Запуск PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Переход к пользователю postgres
sudo -u postgres psql

# В psql выполнить:
CREATE DATABASE cynical_circle;
CREATE USER cynical_app WITH PASSWORD 'secure_password_123';
GRANT ALL PRIVILEGES ON DATABASE cynical_circle TO cynical_app;
\q
```

### 3. Настройка базы данных

```bash
# Клонирование репозитория (или загрузка файлов)
git clone <your-repo-url> /opt/cynical-circle
cd /opt/cynical-circle

# Настройка базы данных
cd database
chmod +x setup.sh
./setup.sh cynical_circle cynical_app secure_password_123 localhost 5432
```

### 4. Настройка Python окружения

```bash
# Создание виртуального окружения
cd /opt/cynical-circle/frontend
python3 -m venv venv
source venv/bin/activate

# Установка зависимостей
pip install --upgrade pip
pip install -r requirements.txt
```

### 5. Настройка переменных окружения

```bash
# Создание файла конфигурации
sudo nano /opt/cynical-circle/.env
```

Содержимое `.env`:
```bash
# База данных
DATABASE_URL=postgresql://cynical_app:secure_password_123@localhost:5432/cynical_circle

# Приложение
HOST=0.0.0.0
PORT=8000
DEBUG=False

# Безопасность
SECRET_KEY=your-secret-key-here-change-this
```

### 6. Создание systemd сервиса

```bash
# Создание сервиса для backend
sudo nano /etc/systemd/system/cynical-circle.service
```

Содержимое сервиса:
```ini
[Unit]
Description=Cynical Circle API
After=network.target postgresql.service

[Service]
Type=exec
User=www-data
Group=www-data
WorkingDirectory=/opt/cynical-circle/frontend
Environment=PATH=/opt/cynical-circle/frontend/venv/bin
ExecStart=/opt/cynical-circle/frontend/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

### 7. Настройка Nginx

```bash
# Создание конфигурации Nginx
sudo nano /etc/nginx/sites-available/cynical-circle
```

Содержимое конфигурации:
```nginx
server {
    listen 80;
    server_name _;  # Принимает запросы с любого домена/IP

    # Логи
    access_log /var/log/nginx/cynical-circle.access.log;
    error_log /var/log/nginx/cynical-circle.error.log;

    # Статические файлы
    location /static/ {
        alias /opt/cynical-circle/frontend/static/;
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
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 8. Активация конфигурации

```bash
# Активация сайта
sudo ln -s /etc/nginx/sites-available/cynical-circle /etc/nginx/sites-enabled/

# Удаление дефолтного сайта
sudo rm /etc/nginx/sites-enabled/default

# Проверка конфигурации
sudo nginx -t

# Перезапуск Nginx
sudo systemctl restart nginx
```

### 9. Запуск сервисов

```bash
# Установка прав на файлы
sudo chown -R www-data:www-data /opt/cynical-circle
sudo chmod -R 755 /opt/cynical-circle

# Запуск сервиса
sudo systemctl daemon-reload
sudo systemctl start cynical-circle
sudo systemctl enable cynical-circle

# Проверка статуса
sudo systemctl status cynical-circle
sudo systemctl status nginx
sudo systemctl status postgresql
```

### 10. Проверка работы

```bash
# Проверка портов
sudo netstat -tlnp | grep -E ':(80|8000|5432)'

# Проверка логов
sudo journalctl -u cynical-circle -f
sudo tail -f /var/log/nginx/cynical-circle.access.log

# Тест API
curl http://localhost/api/
curl http://localhost/
```

## Детальная настройка

### Настройка PostgreSQL

#### Оптимизация производительности

```bash
# Редактирование конфигурации PostgreSQL
sudo nano /etc/postgresql/*/main/postgresql.conf
```

Добавить/изменить:
```conf
# Память
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB

# Подключения
max_connections = 100

# Логирование
log_statement = 'all'
log_duration = on
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '

# Автовакуум
autovacuum = on
autovacuum_max_workers = 3
```

#### Настройка аутентификации

```bash
# Редактирование pg_hba.conf
sudo nano /etc/postgresql/*/main/pg_hba.conf
```

Добавить:
```conf
# Cynical Circle
local   cynical_circle    cynical_app    md5
host    cynical_circle    cynical_app    127.0.0.1/32    md5
```

### Настройка безопасности

#### Firewall

```bash
# Настройка UFW
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw deny 5432/tcp  # Закрыть PostgreSQL для внешнего доступа
sudo ufw deny 8000/tcp  # Закрыть FastAPI для внешнего доступа
```

#### SSL сертификат (Let's Encrypt)

```bash
# Установка Certbot
sudo apt install certbot python3-certbot-nginx

# Получение сертификата
sudo certbot --nginx -d your-domain.com

# Автообновление
sudo crontab -e
# Добавить: 0 12 * * * /usr/bin/certbot renew --quiet
```

### Мониторинг и логирование

#### Настройка логирования

```bash
# Ротация логов
sudo nano /etc/logrotate.d/cynical-circle
```

Содержимое:
```
/var/log/nginx/cynical-circle.*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
    postrotate
        systemctl reload nginx
    endscript
}
```

#### Мониторинг системы

```bash
# Установка htop и iotop
sudo apt install htop iotop

# Мониторинг PostgreSQL
sudo -u postgres psql -c "SELECT * FROM pg_stat_activity;"
```

### Резервное копирование

#### Скрипт бэкапа

```bash
# Создание скрипта бэкапа
sudo nano /opt/cynical-circle/backup.sh
```

Содержимое:
```bash
#!/bin/bash
BACKUP_DIR="/opt/backups/cynical-circle"
DATE=$(date +%Y%m%d_%H%M%S)

# Создание директории
mkdir -p $BACKUP_DIR

# Бэкап базы данных
sudo -u postgres pg_dump cynical_circle > $BACKUP_DIR/db_$DATE.sql

# Бэкап кода
tar -czf $BACKUP_DIR/code_$DATE.tar.gz /opt/cynical-circle

# Удаление старых бэкапов (старше 30 дней)
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete

echo "Backup completed: $DATE"
```

```bash
# Делаем скрипт исполняемым
sudo chmod +x /opt/cynical-circle/backup.sh

# Добавляем в cron (ежедневно в 2:00)
sudo crontab -e
# Добавить: 0 2 * * * /opt/cynical-circle/backup.sh
```

## Обновление приложения

### Процедура обновления

```bash
# 1. Остановка сервиса
sudo systemctl stop cynical-circle

# 2. Бэкап текущей версии
/opt/cynical-circle/backup.sh

# 3. Обновление кода
cd /opt/cynical-circle
git pull origin main

# 4. Обновление зависимостей
cd frontend
source venv/bin/activate
pip install -r requirements.txt

# 5. Применение миграций БД (если есть)
cd ../database
psql -U cynical_app -d cynical_circle -f migrations/new_migration.sql

# 6. Запуск сервиса
sudo systemctl start cynical-circle

# 7. Проверка
curl http://localhost/api/
```

## Troubleshooting

### Частые проблемы

#### 1. Сервис не запускается

```bash
# Проверка логов
sudo journalctl -u cynical-circle -f

# Проверка конфигурации
sudo nginx -t

# Проверка портов
sudo netstat -tlnp | grep 8000
```

#### 2. Ошибки базы данных

```bash
# Проверка подключения
psql -U cynical_app -d cynical_circle -h localhost

# Проверка логов PostgreSQL
sudo tail -f /var/log/postgresql/postgresql-*.log
```

#### 3. Nginx ошибки

```bash
# Проверка конфигурации
sudo nginx -t

# Перезапуск
sudo systemctl restart nginx

# Проверка логов
sudo tail -f /var/log/nginx/cynical-circle.error.log
```

### Полезные команды

```bash
# Перезапуск всех сервисов
sudo systemctl restart postgresql nginx cynical-circle

# Проверка статуса
sudo systemctl status postgresql nginx cynical-circle

# Просмотр логов
sudo journalctl -u cynical-circle --since "1 hour ago"
sudo tail -f /var/log/nginx/cynical-circle.access.log

# Мониторинг ресурсов
htop
iotop
df -h
free -h
```

## Производительность

### Оптимизация Nginx

```nginx
# В /etc/nginx/nginx.conf
worker_processes auto;
worker_connections 1024;

# Кэширование
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=cynical_cache:10m max_size=1g inactive=60m;

# В конфигурации сайта
location /api/ {
    proxy_cache cynical_cache;
    proxy_cache_valid 200 1m;
    proxy_pass http://127.0.0.1:8000;
}
```

### Оптимизация PostgreSQL

```sql
-- Анализ производительности
EXPLAIN ANALYZE SELECT * FROM posts WHERE owner_id = 'some-uuid';

-- Создание дополнительных индексов
CREATE INDEX CONCURRENTLY idx_posts_title ON posts USING gin(to_tsvector('russian', title));
```

## Безопасность

### Рекомендации по безопасности

1. **Регулярные обновления**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Ограничение доступа к PostgreSQL**:
   ```bash
   # В postgresql.conf
   listen_addresses = 'localhost'
   ```

3. **Мониторинг логов**:
   ```bash
   # Установка fail2ban
   sudo apt install fail2ban
   ```

4. **Регулярные бэкапы**:
   - Автоматические бэкапы через cron
   - Тестирование восстановления

## Заключение

После выполнения всех шагов у вас будет полностью функциональное приложение Cynical Circle, доступное по IP адресу сервера на порту 80. Все компоненты будут работать как единая система с автоматическим запуском при перезагрузке сервера.

Для доступа к приложению откройте браузер и перейдите по адресу: `http://YOUR_SERVER_IP`
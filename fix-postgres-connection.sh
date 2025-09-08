#!/bin/bash

# Скрипт для исправления проблем с подключением к PostgreSQL
# Использование: sudo ./fix-postgres-connection.sh

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Параметры
DB_NAME="cynical_circle"
DB_USER="cynical_app"
DB_PASSWORD="secure_password_123"

echo -e "${BLUE}🔧 Исправление проблем с подключением к PostgreSQL${NC}"

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

# 1. Проверка статуса PostgreSQL
log "Проверка статуса PostgreSQL..."
if systemctl is-active --quiet postgresql; then
    log "PostgreSQL запущен"
else
    warn "PostgreSQL не запущен, запускаем..."
    systemctl start postgresql
    systemctl enable postgresql
    sleep 5
fi

# 2. Проверка версии PostgreSQL
log "Проверка версии PostgreSQL..."
psql --version

# 3. Проверка конфигурации PostgreSQL
log "Проверка конфигурации PostgreSQL..."

# Находим версию PostgreSQL
PG_VERSION=$(psql --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
PG_CONFIG_DIR="/etc/postgresql/$PG_VERSION/main"

if [ ! -d "$PG_CONFIG_DIR" ]; then
    # Альтернативные пути
    PG_CONFIG_DIR="/var/lib/pgsql/data"
    if [ ! -d "$PG_CONFIG_DIR" ]; then
        PG_CONFIG_DIR="/usr/local/pgsql/data"
    fi
fi

echo "Конфигурация PostgreSQL: $PG_CONFIG_DIR"

# 4. Настройка pg_hba.conf
log "Настройка аутентификации..."
PG_HBA_FILE="$PG_CONFIG_DIR/pg_hba.conf"

if [ -f "$PG_HBA_FILE" ]; then
    # Создаем бэкап
    cp "$PG_HBA_FILE" "$PG_HBA_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Добавляем настройки для нашего пользователя
    if ! grep -q "cynical_app" "$PG_HBA_FILE"; then
        echo "# Cynical Circle settings" >> "$PG_HBA_FILE"
        echo "local   $DB_NAME    $DB_USER    md5" >> "$PG_HBA_FILE"
        echo "host    $DB_NAME    $DB_USER    127.0.0.1/32    md5" >> "$PG_HBA_FILE"
        echo "host    $DB_NAME    $DB_USER    ::1/128         md5" >> "$PG_HBA_FILE"
        log "Добавлены настройки аутентификации"
    else
        log "Настройки аутентификации уже существуют"
    fi
else
    warn "Файл pg_hba.conf не найден в $PG_CONFIG_DIR"
fi

# 5. Настройка postgresql.conf
log "Настройка postgresql.conf..."
PG_CONF_FILE="$PG_CONFIG_DIR/postgresql.conf"

if [ -f "$PG_CONF_FILE" ]; then
    # Создаем бэкап
    cp "$PG_CONF_FILE" "$PG_CONF_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Настраиваем listen_addresses
    if grep -q "^#listen_addresses" "$PG_CONF_FILE"; then
        sed -i 's/^#listen_addresses.*/listen_addresses = '\''localhost'\''/' "$PG_CONF_FILE"
        log "Настроен listen_addresses"
    elif ! grep -q "^listen_addresses" "$PG_CONF_FILE"; then
        echo "listen_addresses = 'localhost'" >> "$PG_CONF_FILE"
        log "Добавлен listen_addresses"
    fi
    
    # Настраиваем port
    if ! grep -q "^port" "$PG_CONF_FILE"; then
        echo "port = 5432" >> "$PG_CONF_FILE"
        log "Добавлен port"
    fi
else
    warn "Файл postgresql.conf не найден в $PG_CONFIG_DIR"
fi

# 6. Перезапуск PostgreSQL
log "Перезапуск PostgreSQL..."
systemctl restart postgresql
sleep 5

# 7. Проверка подключения
log "Проверка подключения к PostgreSQL..."

# Проверяем, что PostgreSQL слушает на порту 5432
if netstat -tlnp | grep -q ":5432"; then
    log "PostgreSQL слушает на порту 5432"
else
    warn "PostgreSQL не слушает на порту 5432"
    systemctl status postgresql
fi

# 8. Создание пользователя и базы данных
log "Создание пользователя и базы данных..."

# Переключаемся на пользователя postgres
sudo -u postgres psql << EOF
-- Удаляем пользователя и базу, если они существуют
DROP DATABASE IF EXISTS $DB_NAME;
DROP USER IF EXISTS $DB_USER;

-- Создаем пользователя
CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';

-- Создаем базу данных
CREATE DATABASE $DB_NAME OWNER $DB_USER;

-- Предоставляем права
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;

-- Подключаемся к базе и предоставляем права на схему
\c $DB_NAME
GRANT ALL ON SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO $DB_USER;

-- Устанавливаем права по умолчанию
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO $DB_USER;

\q
EOF

# 9. Тестирование подключения
log "Тестирование подключения..."

# Тест 1: Подключение от имени postgres
if sudo -u postgres psql -c "SELECT 1;" > /dev/null 2>&1; then
    log "✅ Подключение от имени postgres работает"
else
    error "❌ Подключение от имени postgres не работает"
fi

# Тест 2: Подключение к нашей базе
if sudo -u postgres psql -d $DB_NAME -c "SELECT 1;" > /dev/null 2>&1; then
    log "✅ Подключение к базе $DB_NAME работает"
else
    error "❌ Подключение к базе $DB_NAME не работает"
fi

# Тест 3: Подключение от имени нашего пользователя
if PGPASSWORD=$DB_PASSWORD psql -h localhost -U $DB_USER -d $DB_NAME -c "SELECT 1;" > /dev/null 2>&1; then
    log "✅ Подключение от имени $DB_USER работает"
else
    warn "⚠️  Подключение от имени $DB_USER не работает, проверяем настройки..."
    
    # Показываем текущие настройки pg_hba.conf
    echo -e "${YELLOW}Текущие настройки pg_hba.conf:${NC}"
    grep -E "(local|host).*$DB_NAME.*$DB_USER" "$PG_HBA_FILE" || echo "Настройки не найдены"
    
    # Показываем логи PostgreSQL
    echo -e "${YELLOW}Последние ошибки PostgreSQL:${NC}"
    tail -20 /var/log/postgresql/postgresql-*.log | grep -i error || echo "Ошибок не найдено"
fi

# 10. Создание тестового подключения
log "Создание тестового подключения..."
cat > /tmp/test_connection.py << EOF
import psycopg2
import sys

try:
    conn = psycopg2.connect(
        host="localhost",
        database="$DB_NAME",
        user="$DB_USER",
        password="$DB_PASSWORD"
    )
    print("✅ Python подключение к PostgreSQL работает")
    conn.close()
except Exception as e:
    print(f"❌ Python подключение не работает: {e}")
    sys.exit(1)
EOF

if python3 /tmp/test_connection.py; then
    log "✅ Python подключение работает"
else
    warn "⚠️  Python подключение не работает"
fi

rm /tmp/test_connection.py

# 11. Показ информации о подключении
log "Информация о подключении:"
echo -e "${BLUE}Host: localhost${NC}"
echo -e "${BLUE}Port: 5432${NC}"
echo -e "${BLUE}Database: $DB_NAME${NC}"
echo -e "${BLUE}User: $DB_USER${NC}"
echo -e "${BLUE}Password: $DB_PASSWORD${NC}"
echo -e "${BLUE}Connection String: postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME${NC}"

# 12. Проверка логов
log "Проверка логов PostgreSQL..."
if [ -f "/var/log/postgresql/postgresql-*.log" ]; then
    echo -e "${YELLOW}Последние записи в логе:${NC}"
    tail -10 /var/log/postgresql/postgresql-*.log
fi

echo -e "${GREEN}🎉 Исправление завершено!${NC}"
echo -e "${BLUE}Теперь попробуйте запустить настройку базы данных снова.${NC}"

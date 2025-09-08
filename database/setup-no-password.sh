#!/bin/bash

# Скрипт настройки базы данных PostgreSQL без запроса пароля
# Использование: ./setup-no-password.sh [database_name] [username] [password]

set -e

# Параметры по умолчанию
DB_NAME=${1:-cynical_circle}
DB_USER=${2:-cynical_app}
DB_PASSWORD=${3:-secure_password_123}
DB_HOST=${4:-localhost}
DB_PORT=${5:-5432}

echo "🚀 Настройка базы данных PostgreSQL для Cynical Circle"
echo "📊 База данных: $DB_NAME"
echo "👤 Пользователь: $DB_USER"
echo "🌐 Хост: $DB_HOST:$DB_PORT"

# Проверяем, установлен ли PostgreSQL
if ! command -v psql &> /dev/null; then
    echo "❌ PostgreSQL не установлен. Установите PostgreSQL и повторите попытку."
    exit 1
fi

# Проверяем, что мы запущены от root или можем использовать sudo
if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then
    echo "❌ Запустите скрипт с правами sudo: sudo ./setup-no-password.sh"
    exit 1
fi

# Проверяем статус PostgreSQL
echo "🔍 Проверка статуса PostgreSQL..."
if ! systemctl is-active --quiet postgresql; then
    echo "⚠️  PostgreSQL не запущен, запускаем..."
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    sleep 5
fi

# Проверяем подключение от имени postgres
echo "🔍 Проверка подключения к PostgreSQL..."
if ! sudo -u postgres psql -c '\q' 2>/dev/null; then
    echo "❌ Не удается подключиться к PostgreSQL от имени postgres."
    echo "🔧 Попробуйте запустить скрипт исправления: sudo ./fix-postgres-connection.sh"
    exit 1
fi

echo "✅ Подключение к PostgreSQL успешно"

# Создаем базу данных и пользователя
echo "📝 Создание базы данных и пользователя..."

# Удаляем существующие объекты, если они есть
sudo -u postgres psql << EOF
-- Удаляем базу данных и пользователя, если они существуют
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

echo "✅ База данных и пользователь созданы"

# Применяем миграции
echo "🔄 Применение миграций..."

# Миграция 001: Создание схемы
echo "  📋 Применение миграции 001: Создание схемы..."
sudo -u postgres psql -d $DB_NAME -f migrations/001_initial_schema.sql

# Миграция 002: Функции и триггеры
echo "  ⚙️  Применение миграции 002: Функции и триггеры..."
sudo -u postgres psql -d $DB_NAME -f migrations/002_functions_and_triggers.sql

# Миграция 003: Представления и функции
echo "  📊 Применение миграции 003: Представления и функции..."
sudo -u postgres psql -d $DB_NAME -f migrations/003_views_and_functions.sql

# Предоставляем права на таблицы
echo "🔐 Настройка прав на таблицы..."
sudo -u postgres psql -d $DB_NAME << EOF
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO $DB_USER;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO $DB_USER;
EOF

# Инициализируем тестовые данные
echo "🌱 Инициализация тестовых данных..."
sudo -u postgres psql -d $DB_NAME -f init.sql

# Тестируем подключение
echo "🧪 Тестирование подключения..."
if PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT 1;" > /dev/null 2>&1; then
    echo "✅ Подключение от имени $DB_USER работает"
else
    echo "⚠️  Подключение от имени $DB_USER не работает, но база данных создана"
fi

echo "✅ Настройка базы данных завершена!"
echo ""
echo "📋 Информация о подключении:"
echo "   Host: $DB_HOST"
echo "   Port: $DB_PORT"
echo "   Database: $DB_NAME"
echo "   Username: $DB_USER"
echo "   Password: $DB_PASSWORD"
echo ""
echo "🔗 Строка подключения:"
echo "   postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME"
echo ""
echo "🚀 Теперь можно запускать приложение!"

#!/bin/bash

# Скрипт для настройки базы данных PostgreSQL для Cynical Circle
# Использование: ./setup.sh [database_name] [username] [password]

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

# Проверяем подключение к PostgreSQL
echo "🔍 Проверка подключения к PostgreSQL..."
if ! psql -h $DB_HOST -p $DB_PORT -U postgres -c '\q' 2>/dev/null; then
    echo "❌ Не удается подключиться к PostgreSQL. Проверьте настройки подключения."
    echo "🔧 Попробуйте запустить скрипт исправления: sudo ./fix-postgres-connection.sh"
    echo ""
    echo "Возможные причины:"
    echo "1. PostgreSQL не запущен"
    echo "2. Неправильные настройки аутентификации"
    echo "3. Проблемы с конфигурацией"
    echo ""
    echo "Для диагностики выполните:"
    echo "sudo systemctl status postgresql"
    echo "sudo -u postgres psql -c 'SELECT version();'"
    exit 1
fi

echo "✅ Подключение к PostgreSQL успешно"

# Создаем базу данных
echo "📝 Создание базы данных $DB_NAME..."
psql -h $DB_HOST -p $DB_PORT -U postgres -c "CREATE DATABASE $DB_NAME;" 2>/dev/null || echo "⚠️  База данных $DB_NAME уже существует"

# Создаем пользователя
echo "👤 Создание пользователя $DB_USER..."
psql -h $DB_HOST -p $DB_PORT -U postgres -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';" 2>/dev/null || echo "⚠️  Пользователь $DB_USER уже существует"

# Предоставляем права
echo "🔐 Настройка прав доступа..."
psql -h $DB_HOST -p $DB_PORT -U postgres -c "GRANT CONNECT ON DATABASE $DB_NAME TO $DB_USER;"
psql -h $DB_HOST -p $DB_PORT -U postgres -c "GRANT USAGE ON SCHEMA public TO $DB_USER;"
psql -h $DB_HOST -p $DB_PORT -U postgres -c "GRANT CREATE ON SCHEMA public TO $DB_USER;"

# Применяем миграции
echo "🔄 Применение миграций..."

# Миграция 001: Создание схемы
echo "  📋 Применение миграции 001: Создание схемы..."
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f migrations/001_initial_schema.sql

# Миграция 002: Функции и триггеры
echo "  ⚙️  Применение миграции 002: Функции и триггеры..."
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f migrations/002_functions_and_triggers.sql

# Миграция 003: Представления и функции
echo "  📊 Применение миграции 003: Представления и функции..."
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f migrations/003_views_and_functions.sql

# Предоставляем права на таблицы
echo "🔐 Настройка прав на таблицы..."
psql -h $DB_HOST -p $DB_PORT -U postgres -d $DB_NAME -c "GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO $DB_USER;"
psql -h $DB_HOST -p $DB_PORT -U postgres -d $DB_NAME -c "GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;"
psql -h $DB_HOST -p $DB_PORT -U postgres -d $DB_NAME -c "GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO $DB_USER;"

# Инициализируем тестовые данные
echo "🌱 Инициализация тестовых данных..."
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f init.sql

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

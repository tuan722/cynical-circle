#!/bin/bash

# Скрипт развертывания Cynical Circle с Docker
# Использование: ./docker-deploy.sh [server_ip]

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Параметры
SERVER_IP=${1:-"localhost"}

echo -e "${BLUE}🐳 Начинаем развертывание Cynical Circle с Docker${NC}"
echo -e "${BLUE}📊 Сервер: $SERVER_IP${NC}"

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

# Проверка Docker
if ! command -v docker &> /dev/null; then
    error "Docker не установлен. Установите Docker и повторите попытку."
fi

if ! command -v docker-compose &> /dev/null; then
    error "Docker Compose не установлен. Установите Docker Compose и повторите попытку."
fi

# 1. Остановка существующих контейнеров
log "Остановка существующих контейнеров..."
docker-compose down 2>/dev/null || true

# 2. Создание необходимых директорий
log "Создание директорий..."
mkdir -p nginx/ssl
mkdir -p postgres_data

# 3. Создание .env файла
log "Создание конфигурации..."
cat > .env << EOF
# База данных
POSTGRES_DB=cynical_circle
POSTGRES_USER=cynical_app
POSTGRES_PASSWORD=secure_password_123

# Приложение
DATABASE_URL=postgresql://cynical_app:secure_password_123@postgres:5432/cynical_circle
HOST=0.0.0.0
PORT=8000
DEBUG=False
SECRET_KEY=$(openssl rand -hex 32)

# pgAdmin
PGADMIN_DEFAULT_EMAIL=admin@cynical.com
PGADMIN_DEFAULT_PASSWORD=admin123
EOF

# 4. Сборка и запуск контейнеров
log "Сборка и запуск контейнеров..."
docker-compose up --build -d

# 5. Ожидание запуска сервисов
log "Ожидание запуска сервисов..."
sleep 30

# 6. Проверка статуса контейнеров
log "Проверка статуса контейнеров..."
docker-compose ps

# 7. Проверка здоровья сервисов
log "Проверка здоровья сервисов..."

# Проверка PostgreSQL
if docker-compose exec -T postgres pg_isready -U cynical_app -d cynical_circle > /dev/null 2>&1; then
    log "✅ PostgreSQL готов"
else
    warn "⚠️  PostgreSQL не готов, ожидаем..."
    sleep 10
fi

# Проверка API
if curl -s http://localhost/api/ > /dev/null 2>&1; then
    log "✅ API готов"
else
    warn "⚠️  API не готов, проверьте логи: docker-compose logs api"
fi

# 8. Создание скрипта управления
log "Создание скрипта управления..."
cat > manage.sh << 'EOF'
#!/bin/bash

case "$1" in
    start)
        echo "Запуск Cynical Circle..."
        docker-compose up -d
        ;;
    stop)
        echo "Остановка Cynical Circle..."
        docker-compose down
        ;;
    restart)
        echo "Перезапуск Cynical Circle..."
        docker-compose restart
        ;;
    logs)
        echo "Просмотр логов..."
        docker-compose logs -f
        ;;
    status)
        echo "Статус сервисов..."
        docker-compose ps
        ;;
    backup)
        echo "Создание бэкапа..."
        docker-compose exec postgres pg_dump -U cynical_app cynical_circle > backup_$(date +%Y%m%d_%H%M%S).sql
        echo "Бэкап создан"
        ;;
    update)
        echo "Обновление Cynical Circle..."
        docker-compose down
        docker-compose pull
        docker-compose up --build -d
        ;;
    *)
        echo "Использование: $0 {start|stop|restart|logs|status|backup|update}"
        exit 1
        ;;
esac
EOF

chmod +x manage.sh

# 9. Создание скрипта мониторинга
log "Создание скрипта мониторинга..."
cat > monitor.sh << 'EOF'
#!/bin/bash

echo "=== Cynical Circle Status ==="
echo "Время: $(date)"
echo ""

echo "=== Контейнеры ==="
docker-compose ps
echo ""

echo "=== Использование ресурсов ==="
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
echo ""

echo "=== Логи ошибок (последние 10 строк) ==="
docker-compose logs --tail=10 nginx | grep -i error || echo "Ошибок не найдено"
echo ""

echo "=== Проверка API ==="
if curl -s http://localhost/api/ > /dev/null; then
    echo "✅ API отвечает"
else
    echo "❌ API не отвечает"
fi
EOF

chmod +x monitor.sh

# 10. Финальная проверка
log "Финальная проверка..."

echo -e "${BLUE}📊 Статус контейнеров:${NC}"
docker-compose ps

echo -e "${BLUE}🌐 Проверка портов:${NC}"
netstat -tlnp | grep -E ':(80|8000|5432|8080)' || ss -tlnp | grep -E ':(80|8000|5432|8080)'

echo -e "${GREEN}🎉 Развертывание завершено!${NC}"
echo -e "${BLUE}🌐 Приложение доступно по адресу: http://$SERVER_IP${NC}"
echo -e "${BLUE}📊 API документация: http://$SERVER_IP/docs${NC}"
echo -e "${BLUE}🗄️  pgAdmin: http://$SERVER_IP:8080${NC}"
echo -e "${BLUE}📋 Управление: ./manage.sh {start|stop|restart|logs|status|backup|update}${NC}"
echo -e "${BLUE}📊 Мониторинг: ./monitor.sh${NC}"

echo -e "${YELLOW}⚠️  Учетные данные по умолчанию:${NC}"
echo -e "${YELLOW}   pgAdmin: admin@cynical.com / admin123${NC}"
echo -e "${YELLOW}   PostgreSQL: cynical_app / secure_password_123${NC}"

echo -e "${YELLOW}⚠️  Не забудьте:${NC}"
echo -e "${YELLOW}   1. Изменить пароли по умолчанию${NC}"
echo -e "${YELLOW}   2. Настроить SSL сертификат${NC}"
echo -e "${YELLOW}   3. Настроить мониторинг${NC}"
echo -e "${YELLOW}   4. Регулярно создавать бэкапы${NC}"

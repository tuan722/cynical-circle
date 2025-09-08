# Быстрый старт Cynical Circle

## 🚀 Развертывание за 5 минут

### Вариант 1: Docker (Рекомендуется)

```bash
# 1. Клонирование репозитория
git clone <your-repo-url> cynical-circle
cd cynical-circle

# 2. Запуск с Docker
./docker-deploy.sh

# 3. Открыть в браузере
# http://localhost
```

### Вариант 2: Нативная установка

```bash
# 1. Клонирование репозитория
git clone <your-repo-url> cynical-circle
cd cynical-circle

# 2. Автоматическая установка
sudo ./deploy.sh

# 3. Открыть в браузере
# http://YOUR_SERVER_IP
```

## 📋 Что включено

- ✅ **PostgreSQL** - база данных
- ✅ **FastAPI** - backend API
- ✅ **HTML/CSS/JS** - frontend
- ✅ **Nginx** - reverse proxy
- ✅ **pgAdmin** - управление БД (только Docker)
- ✅ **Автоматические бэкапы**
- ✅ **Мониторинг**

## 🔧 Управление

### Docker версия
```bash
./manage.sh start    # Запуск
./manage.sh stop     # Остановка
./manage.sh restart  # Перезапуск
./manage.sh logs     # Логи
./manage.sh status   # Статус
./manage.sh backup   # Бэкап
./manage.sh update   # Обновление
```

### Нативная версия
```bash
sudo systemctl start cynical-circle    # Запуск
sudo systemctl stop cynical-circle     # Остановка
sudo systemctl restart cynical-circle  # Перезапуск
sudo journalctl -u cynical-circle -f   # Логи
```

## 🌐 Доступ

- **Приложение**: http://localhost (или IP сервера)
- **API документация**: http://localhost/docs
- **pgAdmin** (Docker): http://localhost:8080

## 🔑 Учетные данные по умолчанию

- **pgAdmin**: admin@cynical.com / admin123
- **PostgreSQL**: cynical_app / secure_password_123

## ⚠️ Важно

1. **Измените пароли** после установки
2. **Настройте SSL** для продакшена
3. **Регулярно обновляйте** систему
4. **Создавайте бэкапы** данных

## 🆘 Помощь

### Если возникли проблемы с PostgreSQL:
```bash
# Автоматическое исправление
sudo ./fix-postgres-connection.sh

# Альтернативная настройка БД
cd database
sudo ./setup-no-password.sh
```

### Общая диагностика:
- **Логи**: `docker-compose logs` или `journalctl -u cynical-circle`
- **Статус**: `docker-compose ps` или `systemctl status cynical-circle`
- **Мониторинг**: `./monitor.sh` (Docker) или `htop` (нативная)

### Подробное решение проблем:
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - полное руководство по решению проблем

## 📚 Документация

- [Полное руководство по развертыванию](DEPLOYMENT_GUIDE.md)
- [API документация](API_DOCUMENTATION.md)
- [Документация фронтенда](FRONTEND_FLOW_DOCUMENTATION.md)
- [Документация базы данных](database/README.md)

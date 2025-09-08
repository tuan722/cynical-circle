# Решение проблем Cynical Circle

## ❌ Ошибка подключения к PostgreSQL

### Проблема
```
❌ Не удается подключиться к PostgreSQL. Проверьте настройки подключения.
```

### Решение

#### 1. Автоматическое исправление
```bash
# Запустите скрипт исправления
sudo ./fix-postgres-connection.sh
```

#### 2. Ручная диагностика

**Проверьте статус PostgreSQL:**
```bash
sudo systemctl status postgresql
```

**Проверьте, что PostgreSQL запущен:**
```bash
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

**Проверьте подключение от имени postgres:**
```bash
sudo -u postgres psql -c "SELECT version();"
```

**Проверьте порт:**
```bash
sudo netstat -tlnp | grep 5432
# или
sudo ss -tlnp | grep 5432
```

#### 3. Альтернативная настройка БД
```bash
# Используйте скрипт без запроса пароля
cd database
sudo ./setup-no-password.sh
```

### Возможные причины

1. **PostgreSQL не запущен**
   - Решение: `sudo systemctl start postgresql`

2. **Неправильные настройки аутентификации**
   - Файл: `/etc/postgresql/*/main/pg_hba.conf`
   - Добавьте: `local cynical_circle cynical_app md5`

3. **Проблемы с конфигурацией**
   - Файл: `/etc/postgresql/*/main/postgresql.conf`
   - Убедитесь: `listen_addresses = 'localhost'`

4. **Проблемы с правами доступа**
   - Проверьте: `sudo chown -R postgres:postgres /var/lib/postgresql/`

## 🔧 Другие частые проблемы

### API не запускается

**Проверьте логи:**
```bash
sudo journalctl -u cynical-circle -f
```

**Проверьте зависимости:**
```bash
cd frontend
source venv/bin/activate
pip install -r requirements.txt
```

**Проверьте переменные окружения:**
```bash
cat .env
```

### Nginx ошибки

**Проверьте конфигурацию:**
```bash
sudo nginx -t
```

**Проверьте логи:**
```bash
sudo tail -f /var/log/nginx/cynical-circle.error.log
```

**Перезапустите Nginx:**
```bash
sudo systemctl restart nginx
```

### База данных не создается

**Проверьте права пользователя postgres:**
```bash
sudo -u postgres psql -c "SELECT 1;"
```

**Создайте пользователя и базу вручную:**
```bash
sudo -u postgres psql << EOF
CREATE USER cynical_app WITH PASSWORD 'secure_password_123';
CREATE DATABASE cynical_circle OWNER cynical_app;
GRANT ALL PRIVILEGES ON DATABASE cynical_circle TO cynical_app;
\q
EOF
```

### Проблемы с Docker

**Очистите контейнеры:**
```bash
docker-compose down
docker system prune -a
docker-compose up --build -d
```

**Проверьте логи:**
```bash
docker-compose logs -f
```

## 📊 Полезные команды для диагностики

### Система
```bash
# Статус сервисов
sudo systemctl status postgresql nginx cynical-circle

# Использование ресурсов
htop
df -h
free -h

# Сетевые подключения
sudo netstat -tlnp
sudo ss -tlnp
```

### PostgreSQL
```bash
# Подключение
sudo -u postgres psql

# Список баз данных
sudo -u postgres psql -l

# Список пользователей
sudo -u postgres psql -c "\du"

# Логи PostgreSQL
sudo tail -f /var/log/postgresql/postgresql-*.log
```

### Приложение
```bash
# Логи приложения
sudo journalctl -u cynical-circle -f

# Тест API
curl http://localhost/api/

# Проверка портов
sudo lsof -i :8000
sudo lsof -i :80
```

## 🆘 Если ничего не помогает

1. **Полная переустановка:**
   ```bash
   sudo systemctl stop cynical-circle nginx postgresql
   sudo apt remove --purge postgresql postgresql-*
   sudo apt autoremove
   sudo rm -rf /var/lib/postgresql
   sudo ./deploy.sh
   ```

2. **Использование Docker:**
   ```bash
   ./docker-deploy.sh
   ```

3. **Проверка логов:**
   ```bash
   # Все логи
   sudo journalctl -u cynical-circle --since "1 hour ago"
   
   # Логи PostgreSQL
   sudo tail -50 /var/log/postgresql/postgresql-*.log
   
   # Логи Nginx
   sudo tail -50 /var/log/nginx/cynical-circle.error.log
   ```

## 📞 Получение помощи

Если проблема не решается:

1. Запустите диагностику: `sudo ./fix-postgres-connection.sh`
2. Соберите логи: `sudo journalctl -u cynical-circle > logs.txt`
3. Проверьте статус: `sudo systemctl status postgresql nginx cynical-circle`
4. Создайте issue с описанием проблемы и логами

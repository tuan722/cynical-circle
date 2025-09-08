# База данных PostgreSQL для Cynical Circle

## Обзор

Этот модуль содержит настройку и миграции для базы данных PostgreSQL, используемой в приложении Cynical Circle.

## Структура

```
database/
├── schema.sql                 # Полная схема базы данных
├── init.sql                   # Инициализация тестовых данных
├── setup.sh                   # Скрипт автоматической настройки
├── database.py                # Модуль для работы с БД
├── requirements.txt           # Python зависимости
├── README.md                  # Документация
└── migrations/                # Папка с миграциями
    ├── 001_initial_schema.sql
    ├── 002_functions_and_triggers.sql
    └── 003_views_and_functions.sql
```

## Быстрый старт

### 1. Установка PostgreSQL

**macOS (с Homebrew):**
```bash
brew install postgresql
brew services start postgresql
```

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

**Windows:**
Скачайте и установите с официального сайта: https://www.postgresql.org/download/windows/

### 2. Настройка базы данных

```bash
# Перейдите в папку database
cd database

# Запустите скрипт настройки
./setup.sh

# Или с кастомными параметрами
./setup.sh [database_name] [username] [password] [host] [port]
```

### 3. Установка Python зависимостей

```bash
pip install -r requirements.txt
```

## Схема базы данных

### Таблицы

#### users (Пользователи)
- `id` (UUID) - Первичный ключ
- `username` (VARCHAR) - Имя пользователя (уникальное)
- `email` (VARCHAR) - Email (уникальный)
- `password_hash` (VARCHAR) - Хеш пароля
- `is_active` (BOOLEAN) - Активен ли пользователь
- `status` (ENUM) - Экзистенциальный статус
- `created_at` (TIMESTAMP) - Дата создания
- `updated_at` (TIMESTAMP) - Дата обновления

#### posts (Посты)
- `id` (UUID) - Первичный ключ
- `title` (VARCHAR) - Заголовок поста
- `content` (TEXT) - Содержимое поста
- `owner_id` (UUID) - ID автора (FK на users.id)
- `created_at` (TIMESTAMP) - Дата создания
- `updated_at` (TIMESTAMP) - Дата обновления

#### reactions (Реакции)
- `id` (UUID) - Первичный ключ
- `post_id` (UUID) - ID поста (FK на posts.id)
- `user_id` (UUID) - ID пользователя (FK на users.id)
- `reaction_type` (ENUM) - Тип реакции
- `created_at` (TIMESTAMP) - Дата создания
- Уникальный ключ: (post_id, user_id)

#### comments (Комментарии)
- `id` (UUID) - Первичный ключ
- `post_id` (UUID) - ID поста (FK на posts.id)
- `owner_id` (UUID) - ID автора (FK на users.id)
- `content` (TEXT) - Текст комментария
- `created_at` (TIMESTAMP) - Дата создания
- `updated_at` (TIMESTAMP) - Дата обновления

### ENUM типы

#### user_status
- `contemplating_the_void` - "Размышляет о пустоте"
- `pretending_to_work` - "Притворяется, что работает"
- `on_the_verge` - "На грани"
- `running_on_caffeine` - "Работает на кофеине"

#### reaction_type
- `sigh` - "Вздох" 😮‍💨
- `facepalm` - "Фейспалм" 🤦
- `cringe` - "Кринж" 😬
- `seen` - "Просмотрено" 👁️

### Представления

#### posts_with_reactions
Объединяет посты с их реакциями в JSON формате.

#### posts_with_stats
Добавляет статистику (количество реакций, комментариев) к постам.

### Функции

#### add_or_update_reaction()
Добавляет новую реакцию или обновляет существующую.

#### get_system_stats()
Возвращает общую статистику системы.

## Использование в приложении

### Подключение к базе данных

```python
from database.database import db

# Инициализация подключения
await db.connect()

# Использование
users = await db.get_users()
posts = await db.get_posts()

# Закрытие подключения
await db.close()
```

### Переменные окружения

```bash
# URL подключения к базе данных
DATABASE_URL=postgresql://cynical_app:secure_password_123@localhost:5432/cynical_circle

# Или отдельные параметры
DB_HOST=localhost
DB_PORT=5432
DB_NAME=cynical_circle
DB_USER=cynical_app
DB_PASSWORD=secure_password_123
```

## Миграции

### Применение миграций

```bash
# Применить все миграции
psql -U cynical_app -d cynical_circle -f migrations/001_initial_schema.sql
psql -U cynical_app -d cynical_circle -f migrations/002_functions_and_triggers.sql
psql -U cynical_app -d cynical_circle -f migrations/003_views_and_functions.sql
```

### Создание новой миграции

1. Создайте файл в папке `migrations/` с номером следующей миграции
2. Добавьте SQL команды для изменения схемы
3. Обновите скрипт `setup.sh` для применения новой миграции

## Тестовые данные

Скрипт `init.sql` создает тестовых пользователей, посты, реакции и комментарии для демонстрации функциональности.

### Тестовые пользователи:
- `cynical_admin` - Администратор
- `sarcastic_user` - Саркастичный пользователь
- `jaded_developer` - Уставший разработчик
- `existential_crisis` - Экзистенциальный кризис
- `optimistic_pessimist` - Оптимистичный пессимист

## Производительность

### Индексы
Созданы индексы для оптимизации запросов:
- По email и username пользователей
- По owner_id и created_at постов
- По post_id, user_id и reaction_type реакций
- По post_id, owner_id и created_at комментариев

### Пул подключений
Используется пул подключений asyncpg для эффективного управления соединениями.

## Безопасность

- Пароли хранятся в виде хешей
- Используются prepared statements для защиты от SQL инъекций
- Ограниченные права доступа для пользователя приложения
- CASCADE удаление для поддержания целостности данных

## Мониторинг

### Проверка состояния базы данных

```sql
-- Проверка подключений
SELECT * FROM pg_stat_activity WHERE datname = 'cynical_circle';

-- Размер базы данных
SELECT pg_size_pretty(pg_database_size('cynical_circle'));

-- Статистика таблиц
SELECT schemaname, tablename, n_tup_ins, n_tup_upd, n_tup_del 
FROM pg_stat_user_tables;
```

### Логирование

Рекомендуется настроить логирование PostgreSQL для мониторинга производительности и отладки.

## Резервное копирование

```bash
# Создание бэкапа
pg_dump -U cynical_app -h localhost cynical_circle > backup.sql

# Восстановление из бэкапа
psql -U cynical_app -h localhost cynical_circle < backup.sql
```

## Troubleshooting

### Частые проблемы

1. **Ошибка подключения**: Проверьте, что PostgreSQL запущен и доступен
2. **Ошибка прав доступа**: Убедитесь, что пользователь имеет необходимые права
3. **Ошибка миграций**: Проверьте порядок применения миграций

### Логи

```bash
# Логи PostgreSQL (macOS)
tail -f /usr/local/var/log/postgres.log

# Логи PostgreSQL (Ubuntu)
tail -f /var/log/postgresql/postgresql-*.log
```

# Cynical Circle API - Подробная документация

## 📋 Обзор

**Cynical Circle API** — это тестовое FastAPI приложение, имитирующее социальную сеть для циников. API предоставляет функциональность для управления пользователями, постами, комментариями и реакциями с характерным саркастическим подходом к документации.

**Версия:** 0.0.1  
**Автор:** Кейбонес  
**GitHub:** https://github.com/kbonesssss  
**Лицензия:** The Unlicense (Делай что хочешь)

## 🏗️ Архитектура

### Технологический стек
- **FastAPI** 0.111.0 - веб-фреймворк
- **Pydantic** - валидация данных и модели
- **Uvicorn** 0.29.0 - ASGI сервер
- **Python 3.13** - язык программирования

### Структура проекта
```
APIForQA/
├── app/
│   ├── main.py              # Точка входа FastAPI
│   ├── models/              # Модели данных
│   │   ├── user.py         # Модели пользователей
│   │   ├── post.py         # Модели постов
│   │   ├── comment.py      # Модели комментариев
│   │   └── enums.py        # Перечисления
│   └── routers/            # API эндпоинты
│       ├── users.py        # Управление пользователями
│       ├── posts.py        # Управление постами
│       ├── comments.py     # Управление комментариями
│       └── stats.py        # Статистика
├── requirements.txt        # Зависимости
└── README.md              # Основная документация
```

## 📊 Модели данных

### 1. Пользователь (User)

#### UserBase
```python
{
    "username": str,     # Имя пользователя
    "email": str         # Email адрес
}
```

#### UserCreate (наследует UserBase)
```python
{
    "username": str,     # Имя пользователя
    "email": str,        # Email адрес
    "password": str      # Пароль
}
```

#### User (наследует UserBase)
```python
{
    "id": UUID,                    # Уникальный идентификатор
    "username": str,               # Имя пользователя
    "email": str,                  # Email адрес
    "is_active": bool,             # Активен ли пользователь (по умолчанию True)
    "status": UserStatus | null    # Экзистенциальный статус (опционально)
}
```

#### UserStatus (enum)
- `contemplating_the_void` - Размышляет о пустоте
- `pretending_to_work` - Притворяется, что работает
- `on_the_verge` - На грани
- `running_on_caffeine` - Работает на кофеине

### 2. Пост (Post)

#### PostBase
```python
{
    "title": str,        # Заголовок поста
    "content": str       # Содержимое поста
}
```

#### PostCreate (наследует PostBase)
```python
{
    "title": str,        # Заголовок поста
    "content": str       # Содержимое поста
}
```

#### Post (наследует PostBase)
```python
{
    "id": UUID,                    # Уникальный идентификатор
    "title": str,                  # Заголовок поста
    "content": str,                # Содержимое поста
    "owner_id": UUID,              # ID автора поста
    "created_at": datetime,        # Дата создания
    "reactions": List[Reaction]    # Список реакций
}
```

#### Reaction
```python
{
    "user_id": UUID,           # ID пользователя, оставившего реакцию
    "type": ReactionType       # Тип реакции
}
```

#### ReactionType (enum)
- `sigh` - Вздох
- `facepalm` - Фейспалм
- `cringe` - Кринж
- `seen` - Просмотрено (высшая степень безразличия)

### 3. Комментарий (Comment)

#### CommentBase
```python
{
    "content": str       # Содержимое комментария
}
```

#### CommentCreate (наследует CommentBase)
```python
{
    "content": str       # Содержимое комментария
}
```

#### Comment (наследует CommentBase)
```python
{
    "id": UUID,              # Уникальный идентификатор
    "content": str,          # Содержимое комментария
    "post_id": UUID,         # ID поста
    "owner_id": UUID,        # ID автора комментария
    "created_at": datetime   # Дата создания
}
```

## 🚀 API Эндпоинты

### Базовый URL
```
http://127.0.0.1:8000
```

### 1. Пользователи (`/users`)

#### POST `/users/` - Создать пользователя
**Описание:** Регистрирует нового пользователя в системе

**Тело запроса:**
```json
{
    "username": "string",
    "email": "string",
    "password": "string"
}
```

**Ответ:** `201 Created`
```json
{
    "id": "uuid",
    "username": "string",
    "email": "string",
    "is_active": true,
    "status": null
}
```

**Ошибки:**
- `400 Bad Request` - Email уже занят

#### GET `/users/` - Получить всех пользователей
**Описание:** Возвращает список всех зарегистрированных пользователей

**Ответ:** `200 OK`
```json
[
    {
        "id": "uuid",
        "username": "string",
        "email": "string",
        "is_active": true,
        "status": "contemplating_the_void"
    }
]
```

**Ошибки:**
- `404 Not Found` - База пользователей пуста

#### GET `/users/{user_id}` - Получить пользователя по ID
**Описание:** Ищет пользователя по его уникальному ID

**Параметры:**
- `user_id` (UUID) - ID пользователя

**Ответ:** `200 OK`
```json
{
    "id": "uuid",
    "username": "string",
    "email": "string",
    "is_active": true,
    "status": "pretending_to_work"
}
```

**Ошибки:**
- `404 Not Found` - Пользователь не найден

#### PUT `/users/{user_id}/status` - Обновить статус пользователя
**Описание:** Позволяет пользователю заявить о своем текущем состоянии

**Параметры:**
- `user_id` (UUID) - ID пользователя
- `status` (UserStatus) - Новый статус

**Тело запроса:**
```json
"contemplating_the_void"
```

**Ответ:** `200 OK`
```json
{
    "id": "uuid",
    "username": "string",
    "email": "string",
    "is_active": true,
    "status": "contemplating_the_void"
}
```

**Ошибки:**
- `404 Not Found` - Пользователь не найден

#### DELETE `/users/{user_id}` - Удалить пользователя
**Описание:** Удаляет пользователя навсегда

**Параметры:**
- `user_id` (UUID) - ID пользователя

**Ответ:** `204 No Content`

**Ошибки:**
- `404 Not Found` - Пользователь не найден

### 2. Посты (`/posts`)

#### POST `/posts/` - Создать пост
**Описание:** Создает новый пост от имени пользователя

**Параметры запроса:**
- `user_id` (UUID) - ID автора поста

**Тело запроса:**
```json
{
    "title": "string",
    "content": "string"
}
```

**Ответ:** `201 Created`
```json
{
    "id": "uuid",
    "title": "string",
    "content": "string",
    "owner_id": "uuid",
    "created_at": "2024-01-01T12:00:00Z",
    "reactions": []
}
```

**Ошибки:**
- `404 Not Found` - Пользователь не найден

#### GET `/posts/` - Получить все посты
**Описание:** Возвращает все посты

**Ответ:** `200 OK`
```json
[
    {
        "id": "uuid",
        "title": "string",
        "content": "string",
        "owner_id": "uuid",
        "created_at": "2024-01-01T12:00:00Z",
        "reactions": [
            {
                "user_id": "uuid",
                "type": "sigh"
            }
        ]
    }
]
```

**Ошибки:**
- `404 Not Found` - База постов пуста

#### GET `/posts/{post_id}` - Получить пост по ID
**Описание:** Ищет пост по его ID

**Параметры:**
- `post_id` (UUID) - ID поста

**Ответ:** `200 OK`
```json
{
    "id": "uuid",
    "title": "string",
    "content": "string",
    "owner_id": "uuid",
    "created_at": "2024-01-01T12:00:00Z",
    "reactions": []
}
```

**Ошибки:**
- `404 Not Found` - Пост не найден

#### POST `/posts/{post_id}/react` - Реагировать на пост
**Описание:** Позволяет пользователю отреагировать на пост

**Параметры:**
- `post_id` (UUID) - ID поста
- `user_id` (UUID) - ID пользователя
- `reaction_type` (ReactionType) - Тип реакции

**Тело запроса:**
```json
"sigh"
```

**Ответ:** `200 OK`
```json
{
    "id": "uuid",
    "title": "string",
    "content": "string",
    "owner_id": "uuid",
    "created_at": "2024-01-01T12:00:00Z",
    "reactions": [
        {
            "user_id": "uuid",
            "type": "sigh"
        }
    ]
}
```

**Ошибки:**
- `404 Not Found` - Пост или пользователь не найден

#### DELETE `/posts/{post_id}` - Удалить пост
**Описание:** Удаляет пост

**Параметры:**
- `post_id` (UUID) - ID поста

**Ответ:** `204 No Content`

**Ошибки:**
- `404 Not Found` - Пост не найден

### 3. Комментарии (`/posts/{post_id}/comments`)

#### POST `/posts/{post_id}/comments/` - Создать комментарий
**Описание:** Добавляет комментарий к посту от имени пользователя

**Параметры:**
- `post_id` (UUID) - ID поста
- `user_id` (UUID) - ID автора комментария

**Тело запроса:**
```json
{
    "content": "string"
}
```

**Ответ:** `201 Created`
```json
{
    "id": "uuid",
    "content": "string",
    "post_id": "uuid",
    "owner_id": "uuid",
    "created_at": "2024-01-01T12:00:00Z"
}
```

**Ошибки:**
- `404 Not Found` - Пост или пользователь не найден

#### GET `/posts/{post_id}/comments/` - Получить комментарии к посту
**Описание:** Возвращает список всех комментариев для конкретного поста

**Параметры:**
- `post_id` (UUID) - ID поста

**Ответ:** `200 OK`
```json
[
    {
        "id": "uuid",
        "content": "string",
        "post_id": "uuid",
        "owner_id": "uuid",
        "created_at": "2024-01-01T12:00:00Z"
    }
]
```

**Ошибки:**
- `404 Not Found` - Пост не существует

### 4. Статистика (`/stats`)

#### GET `/stats/` - Получить статистику
**Описание:** Собирает и вычисляет метрики системы

**Ответ:** `200 OK`
```json
{
    "total_users": 5,
    "total_posts": 12,
    "total_comments": 23,
    "most_common_reaction": "sigh",
    "most_active_procrastinator": "TiredJoe",
    "average_comments_per_post": 1.92
}
```

### 5. Корневой эндпоинт

#### GET `/` - Проверка пульса
**Описание:** Корневой эндпоинт для проверки работоспособности сервера

**Ответ:** `200 OK`
```json
{
    "message": "Сервер работает, но энтузиазма в этом мало."
}
```

## 🔧 Установка и запуск

### Предварительные требования
- Python 3.13+
- pip

### Установка
```bash
# Клонирование репозитория
git clone <URL_РЕПОЗИТОРИЯ>
cd APIForQA

# Создание виртуального окружения
python3 -m venv venv
source venv/bin/activate  # macOS/Linux
# или
venv\Scripts\activate     # Windows

# Установка зависимостей
pip install -r requirements.txt
```

### Запуск
```bash
uvicorn app.main:app --reload
```

Сервер будет доступен по адресу: `http://127.0.0.1:8000`

## 📚 Интерактивная документация

FastAPI автоматически генерирует интерактивную документацию:

- **Swagger UI**: http://127.0.0.1:8000/docs
- **ReDoc**: http://127.0.0.1:8000/redoc

## 🧪 Примеры использования

### Создание пользователя
```bash
curl -X POST "http://127.0.0.1:8000/users/" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "TiredJoe",
    "email": "joe@example.com",
    "password": "password123"
  }'
```

### Создание поста
```bash
curl -X POST "http://127.0.0.1:8000/posts/?user_id=USER_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Мысли о понедельнике",
    "content": "Он наступает. Снова. Неизбежно."
  }'
```

### Реакция на пост
```bash
curl -X POST "http://127.0.0.1:8000/posts/POST_ID/react?user_id=USER_ID&reaction_type=sigh"
```

## ⚠️ Особенности реализации

### Хранение данных
- Все данные хранятся в памяти (in-memory)
- Данные сбрасываются при перезапуске сервера
- Идеально для тестирования и обучения

### Валидация
- Все входные данные валидируются с помощью Pydantic
- UUID автоматически генерируются для новых сущностей
- Временные метки создаются автоматически

### Обработка ошибок
- Детальные сообщения об ошибках с характерным юмором
- Стандартные HTTP коды статуса
- Валидация существования связанных сущностей

## 🎯 Назначение

Этот API создан специально для:
- Обучения автоматизации тестирования API
- Изучения FastAPI и Pydantic
- Практики работы с REST API
- Тестирования различных сценариев без сложной настройки БД

## 📝 Заключение

Cynical Circle API предоставляет полнофункциональный пример REST API с современными технологиями Python. Его циничный подход к документации делает изучение более запоминающимся, а простота архитектуры позволяет легко понять принципы работы веб-API.

---

*Документация создана автоматически на основе анализа исходного кода API*

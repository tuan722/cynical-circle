# API Документация Cynical Circle

## Обзор

Cynical Circle API - это RESTful API для социальной сети циников, построенный на FastAPI. API предоставляет эндпоинты для управления пользователями, постами, комментариями и статистикой.

**Базовый URL**: `http://localhost:8000`  
**API Base Path**: `/api`  
**Версия**: 0.0.1

## Аутентификация

API использует простую систему идентификации по ID пользователя через query параметры. В реальном приложении рекомендуется использовать JWT токены или OAuth2.

## Общие заголовки

Все запросы должны содержать:
```
Content-Type: application/json
Accept: application/json
```

## Коды ответов

- `200 OK` - Успешный запрос
- `201 Created` - Ресурс успешно создан
- `204 No Content` - Успешное удаление
- `400 Bad Request` - Некорректный запрос
- `404 Not Found` - Ресурс не найден
- `422 Unprocessable Entity` - Ошибка валидации данных

---

## Модели данных

### User (Пользователь)

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "username": "cynical_user",
  "email": "user@example.com",
  "is_active": true,
  "status": "contemplating_the_void"
}
```

**Поля:**
- `id` (UUID) - Уникальный идентификатор пользователя
- `username` (string) - Имя пользователя (обязательное)
- `email` (string) - Email адрес (обязательное)
- `is_active` (boolean) - Активен ли пользователь (по умолчанию: true)
- `status` (UserStatus, optional) - Экзистенциальный статус пользователя

### UserCreate (Создание пользователя)

```json
{
  "username": "new_cynical_user",
  "email": "newuser@example.com",
  "password": "secure_password123"
}
```

**Поля:**
- `username` (string) - Имя пользователя (обязательное)
- `email` (string) - Email адрес (обязательное)
- `password` (string) - Пароль (обязательное)

### Post (Пост)

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "title": "Заголовок поста",
  "content": "Содержимое поста",
  "owner_id": "550e8400-e29b-41d4-a716-446655440000",
  "created_at": "2024-01-15T10:30:00Z",
  "reactions": [
    {
      "user_id": "550e8400-e29b-41d4-a716-446655440002",
      "type": "sigh"
    }
  ]
}
```

**Поля:**
- `id` (UUID) - Уникальный идентификатор поста
- `title` (string) - Заголовок поста (обязательное)
- `content` (string) - Содержимое поста (обязательное)
- `owner_id` (UUID) - ID автора поста
- `created_at` (datetime) - Дата и время создания
- `reactions` (array) - Массив реакций на пост

### PostCreate (Создание поста)

```json
{
  "title": "Новый пост",
  "content": "Содержимое нового поста"
}
```

**Поля:**
- `title` (string) - Заголовок поста (обязательное)
- `content` (string) - Содержимое поста (обязательное)

### Comment (Комментарий)

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440003",
  "content": "Текст комментария",
  "post_id": "550e8400-e29b-41d4-a716-446655440001",
  "owner_id": "550e8400-e29b-41d4-a716-446655440000",
  "created_at": "2024-01-15T10:35:00Z"
}
```

**Поля:**
- `id` (UUID) - Уникальный идентификатор комментария
- `content` (string) - Текст комментария (обязательное)
- `post_id` (UUID) - ID поста, к которому относится комментарий
- `owner_id` (UUID) - ID автора комментария
- `created_at` (datetime) - Дата и время создания

### CommentCreate (Создание комментария)

```json
{
  "content": "Новый комментарий"
}
```

**Поля:**
- `content` (string) - Текст комментария (обязательное)

### Enums (Перечисления)

#### UserStatus (Статус пользователя)
- `contemplating_the_void` - "Размышляет о пустоте"
- `pretending_to_work` - "Притворяется, что работает"
- `on_the_verge` - "На грани"
- `running_on_caffeine` - "Работает на кофеине"

#### ReactionType (Тип реакции)
- `sigh` - "Вздох" 😮‍💨
- `facepalm` - "Фейспалм" 🤦
- `cringe` - "Кринж" 😬
- `seen` - "Просмотрено" 👁️

---

## Эндпоинты

## 1. Пользователи (`/api/users`)

### 1.1 Создать пользователя

**POST** `/api/users/`

Создает нового пользователя в системе.

**Параметры запроса:**
- `user_in` (UserCreate) - Данные нового пользователя

**Пример запроса:**
```bash
curl -X POST "http://localhost:8000/api/users/" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "cynical_user",
    "email": "user@example.com",
    "password": "password123"
  }'
```

**Ответы:**
- `201 Created` - Пользователь успешно создан
  ```json
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "username": "cynical_user",
    "email": "user@example.com",
    "is_active": true,
    "status": null
  }
  ```
- `400 Bad Request` - Email уже занят
  ```json
  {
    "detail": "Эта почта уже занята кем-то более удачливым."
  }
  ```

### 1.2 Получить всех пользователей

**GET** `/api/users/`

Возвращает список всех зарегистрированных пользователей.

**Пример запроса:**
```bash
curl -X GET "http://localhost:8000/api/users/" \
  -H "Accept: application/json"
```

**Ответы:**
- `200 OK` - Список пользователей
  ```json
  [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "username": "cynical_user",
      "email": "user@example.com",
      "is_active": true,
      "status": "contemplating_the_void"
    }
  ]
  ```
- `404 Not Found` - База пользователей пуста
  ```json
  {
    "detail": "Никто еще не совершил ошибку и не зарегистрировался. База пуста, как и наши надежды."
  }
  ```

### 1.3 Получить пользователя по ID

**GET** `/api/users/{user_id}`

Возвращает информацию о конкретном пользователе.

**Параметры пути:**
- `user_id` (UUID) - ID пользователя

**Пример запроса:**
```bash
curl -X GET "http://localhost:8000/api/users/550e8400-e29b-41d4-a716-446655440000" \
  -H "Accept: application/json"
```

**Ответы:**
- `200 OK` - Информация о пользователе
  ```json
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "username": "cynical_user",
    "email": "user@example.com",
    "is_active": true,
    "status": "contemplating_the_void"
  }
  ```
- `404 Not Found` - Пользователь не найден
  ```json
  {
    "detail": "Пользователь не найден. Возможно, он обрёл свободу."
  }
  ```

### 1.4 Обновить статус пользователя

**PUT** `/api/users/{user_id}/status`

Обновляет экзистенциальный статус пользователя.

**Параметры пути:**
- `user_id` (UUID) - ID пользователя

**Query параметры:**
- `status` (UserStatus, optional) - Новый статус пользователя

**Пример запроса:**
```bash
curl -X PUT "http://localhost:8000/api/users/550e8400-e29b-41d4-a716-446655440000/status?status=pretending_to_work" \
  -H "Accept: application/json"
```

**Ответы:**
- `200 OK` - Статус обновлен
  ```json
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "username": "cynical_user",
    "email": "user@example.com",
    "is_active": true,
    "status": "pretending_to_work"
  }
  ```
- `404 Not Found` - Пользователь не найден
  ```json
  {
    "detail": "Пользователь не найден. Нельзя обновить статус пустоты."
  }
  ```

### 1.5 Удалить пользователя

**DELETE** `/api/users/{user_id}`

Удаляет пользователя и все связанные с ним данные.

**Параметры пути:**
- `user_id` (UUID) - ID пользователя

**Пример запроса:**
```bash
curl -X DELETE "http://localhost:8000/api/users/550e8400-e29b-41d4-a716-446655440000"
```

**Ответы:**
- `204 No Content` - Пользователь успешно удален
- `404 Not Found` - Пользователь не найден
  ```json
  {
    "detail": "Нельзя удалить того, кого не существует. Философия, однако."
  }
  ```

---

## 2. Посты (`/api/posts`)

### 2.1 Создать пост

**POST** `/api/posts/`

Создает новый пост от имени пользователя.

**Query параметры:**
- `user_id` (UUID) - ID автора поста

**Параметры запроса:**
- `post_in` (PostCreate) - Данные нового поста

**Пример запроса:**
```bash
curl -X POST "http://localhost:8000/api/posts/?user_id=550e8400-e29b-41d4-a716-446655440000" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Мой первый циничный пост",
    "content": "Жизнь - это то, что происходит, пока ты делаешь другие планы."
  }'
```

**Ответы:**
- `201 Created` - Пост успешно создан
  ```json
  {
    "id": "550e8400-e29b-41d4-a716-446655440001",
    "title": "Мой первый циничный пост",
    "content": "Жизнь - это то, что происходит, пока ты делаешь другие планы.",
    "owner_id": "550e8400-e29b-41d4-a716-446655440000",
    "created_at": "2024-01-15T10:30:00Z",
    "reactions": []
  }
  ```
- `404 Not Found` - Пользователь не найден
  ```json
  {
    "detail": "Нельзя постить от имени несуществующего пользователя. Это уже шизофрения."
  }
  ```

### 2.2 Получить все посты

**GET** `/api/posts/`

Возвращает список всех постов.

**Пример запроса:**
```bash
curl -X GET "http://localhost:8000/api/posts/" \
  -H "Accept: application/json"
```

**Ответы:**
- `200 OK` - Список постов
  ```json
  [
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "title": "Мой первый циничный пост",
      "content": "Жизнь - это то, что происходит, пока ты делаешь другие планы.",
      "owner_id": "550e8400-e29b-41d4-a716-446655440000",
      "created_at": "2024-01-15T10:30:00Z",
      "reactions": [
        {
          "user_id": "550e8400-e29b-41d4-a716-446655440002",
          "type": "sigh"
        }
      ]
    }
  ]
  ```
- `404 Not Found` - Постов нет
  ```json
  {
    "detail": "Здесь пусто. Так же, как и в душе автора этого API."
  }
  ```

### 2.3 Получить пост по ID

**GET** `/api/posts/{post_id}`

Возвращает информацию о конкретном посте.

**Параметры пути:**
- `post_id` (UUID) - ID поста

**Пример запроса:**
```bash
curl -X GET "http://localhost:8000/api/posts/550e8400-e29b-41d4-a716-446655440001" \
  -H "Accept: application/json"
```

**Ответы:**
- `200 OK` - Информация о посте
  ```json
  {
    "id": "550e8400-e29b-41d4-a716-446655440001",
    "title": "Мой первый циничный пост",
    "content": "Жизнь - это то, что происходит, пока ты делаешь другие планы.",
    "owner_id": "550e8400-e29b-41d4-a716-446655440000",
    "created_at": "2024-01-15T10:30:00Z",
    "reactions": []
  }
  ```
- `404 Not Found` - Пост не найден
  ```json
  {
    "detail": "Пост не найден. Наверное, его удалили из-за чрезмерного оптимизма."
  }
  ```

### 2.4 Добавить реакцию на пост

**POST** `/api/posts/{post_id}/react`

Добавляет или изменяет реакцию пользователя на пост.

**Параметры пути:**
- `post_id` (UUID) - ID поста

**Query параметры:**
- `user_id` (UUID) - ID пользователя
- `reaction_type` (ReactionType) - Тип реакции

**Пример запроса:**
```bash
curl -X POST "http://localhost:8000/api/posts/550e8400-e29b-41d4-a716-446655440001/react?user_id=550e8400-e29b-41d4-a716-446655440002&reaction_type=sigh" \
  -H "Accept: application/json"
```

**Ответы:**
- `200 OK` - Реакция добавлена/изменена
  ```json
  {
    "id": "550e8400-e29b-41d4-a716-446655440001",
    "title": "Мой первый циничный пост",
    "content": "Жизнь - это то, что происходит, пока ты делаешь другие планы.",
    "owner_id": "550e8400-e29b-41d4-a716-446655440000",
    "created_at": "2024-01-15T10:30:00Z",
    "reactions": [
      {
        "user_id": "550e8400-e29b-41d4-a716-446655440002",
        "type": "sigh"
      }
    ]
  }
  ```
- `404 Not Found` - Пост или пользователь не найден
  ```json
  {
    "detail": "Пост не найден. Реагировать на пустоту бессмысленно."
  }
  ```

### 2.5 Удалить пост

**DELETE** `/api/posts/{post_id}`

Удаляет пост и все связанные с ним комментарии.

**Параметры пути:**
- `post_id` (UUID) - ID поста

**Пример запроса:**
```bash
curl -X DELETE "http://localhost:8000/api/posts/550e8400-e29b-41d4-a716-446655440001"
```

**Ответы:**
- `204 No Content` - Пост успешно удален
- `404 Not Found` - Пост не найден
  ```json
  {
    "detail": "Удалять нечего. Мир и так пуст."
  }
  ```

---

## 3. Комментарии (`/api/posts/{post_id}/comments`)

### 3.1 Получить комментарии к посту

**GET** `/api/posts/{post_id}/comments/`

Возвращает список всех комментариев к конкретному посту.

**Параметры пути:**
- `post_id` (UUID) - ID поста

**Пример запроса:**
```bash
curl -X GET "http://localhost:8000/api/posts/550e8400-e29b-41d4-a716-446655440001/comments/" \
  -H "Accept: application/json"
```

**Ответы:**
- `200 OK` - Список комментариев
  ```json
  [
    {
      "id": "550e8400-e29b-41d4-a716-446655440003",
      "content": "Отличный пост! Полностью согласен.",
      "post_id": "550e8400-e29b-41d4-a716-446655440001",
      "owner_id": "550e8400-e29b-41d4-a716-446655440002",
      "created_at": "2024-01-15T10:35:00Z"
    }
  ]
  ```
- `404 Not Found` - Пост не найден
  ```json
  {
    "detail": "Пост не существует, как и объективность."
  }
  ```

### 3.2 Добавить комментарий к посту

**POST** `/api/posts/{post_id}/comments/`

Добавляет новый комментарий к посту.

**Параметры пути:**
- `post_id` (UUID) - ID поста

**Query параметры:**
- `user_id` (UUID) - ID автора комментария

**Параметры запроса:**
- `comment_in` (CommentCreate) - Данные нового комментария

**Пример запроса:**
```bash
curl -X POST "http://localhost:8000/api/posts/550e8400-e29b-41d4-a716-446655440001/comments/?user_id=550e8400-e29b-41d4-a716-446655440002" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Отличный пост! Полностью согласен."
  }'
```

**Ответы:**
- `201 Created` - Комментарий успешно создан
  ```json
  {
    "id": "550e8400-e29b-41d4-a716-446655440003",
    "content": "Отличный пост! Полностью согласен.",
    "post_id": "550e8400-e29b-41d4-a716-446655440001",
    "owner_id": "550e8400-e29b-41d4-a716-446655440002",
    "created_at": "2024-01-15T10:35:00Z"
  }
  ```
- `404 Not Found` - Пост или пользователь не найден
  ```json
  {
    "detail": "Пост не найден. Мысль потеряна, как и все наши мечты."
  }
  ```

---

## 4. Статистика (`/api/stats`)

### 4.1 Получить статистику

**GET** `/api/stats/`

Возвращает общую статистику системы.

**Пример запроса:**
```bash
curl -X GET "http://localhost:8000/api/stats/" \
  -H "Accept: application/json"
```

**Ответ:**
- `200 OK` - Статистика системы
  ```json
  {
    "total_users": 5,
    "total_posts": 12,
    "total_comments": 23,
    "most_common_reaction": "sigh",
    "most_active_procrastinator": "cynical_user",
    "average_comments_per_post": 1.92
  }
  ```

**Поля ответа:**
- `total_users` (int) - Общее количество пользователей
- `total_posts` (int) - Общее количество постов
- `total_comments` (int) - Общее количество комментариев
- `most_common_reaction` (string) - Самая популярная реакция
- `most_active_procrastinator` (string) - Самый активный пользователь
- `average_comments_per_post` (float) - Среднее количество комментариев на пост

---

## 5. Статические страницы

### 5.1 Главная страница

**GET** `/`

Возвращает главную страницу приложения.

### 5.2 Страница входа

**GET** `/login`

Возвращает страницу входа в систему.

### 5.3 Страница регистрации

**GET** `/register`

Возвращает страницу регистрации нового пользователя.

### 5.4 Страница постов

**GET** `/posts`

Возвращает страницу с лентой постов.

### 5.5 Страница создания поста

**GET** `/create-post`

Возвращает страницу создания нового поста.

### 5.6 Страница профиля

**GET** `/profile`

Возвращает страницу профиля пользователя.

---

## 6. Служебные эндпоинты

### 6.1 Проверка API

**GET** `/api/`

Проверяет работоспособность API сервера.

**Пример запроса:**
```bash
curl -X GET "http://localhost:8000/api/" \
  -H "Accept: application/json"
```

**Ответ:**
- `200 OK`
  ```json
  {
    "message": "API сервер работает, но энтузиазма в этом мало."
  }
  ```

### 6.2 SPA Fallback

**GET** `/{full_path:path}`

Возвращает главную страницу для всех неизвестных маршрутов (кроме API и статических файлов).

---

## Примеры использования

### Создание пользователя и поста

```bash
# 1. Создать пользователя
curl -X POST "http://localhost:8000/api/users/" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "test_user",
    "email": "test@example.com",
    "password": "password123"
  }'

# Ответ: {"id": "550e8400-e29b-41d4-a716-446655440000", ...}

# 2. Создать пост от имени пользователя
curl -X POST "http://localhost:8000/api/posts/?user_id=550e8400-e29b-41d4-a716-446655440000" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Мой первый пост",
    "content": "Содержимое поста"
  }'

# Ответ: {"id": "550e8400-e29b-41d4-a716-446655440001", ...}
```

### Добавление реакции и комментария

```bash
# 1. Добавить реакцию на пост
curl -X POST "http://localhost:8000/api/posts/550e8400-e29b-41d4-a716-446655440001/react?user_id=550e8400-e29b-41d4-a716-446655440000&reaction_type=sigh"

# 2. Добавить комментарий к посту
curl -X POST "http://localhost:8000/api/posts/550e8400-e29b-41d4-a716-446655440001/comments/?user_id=550e8400-e29b-41d4-a716-446655440000" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Отличный пост!"
  }'
```

### Получение статистики

```bash
# Получить общую статистику
curl -X GET "http://localhost:8000/api/stats/" \
  -H "Accept: application/json"
```

---

## Обработка ошибок

API возвращает детальные сообщения об ошибках в формате JSON:

```json
{
  "detail": "Описание ошибки"
}
```

### Типичные ошибки:

1. **Валидация данных (422)**:
   ```json
   {
     "detail": [
       {
         "loc": ["body", "email"],
         "msg": "field required",
         "type": "value_error.missing"
       }
     ]
   }
   ```

2. **Ресурс не найден (404)**:
   ```json
   {
     "detail": "Пользователь не найден. Возможно, он обрёл свободу."
   }
   ```

3. **Конфликт данных (400)**:
   ```json
   {
     "detail": "Эта почта уже занята кем-то более удачливым."
   }
   ```

---

## CORS

API настроен для работы с CORS и принимает запросы с любых доменов. В продакшене рекомендуется ограничить разрешенные домены.

---

## Swagger UI

API автоматически генерирует интерактивную документацию Swagger UI, доступную по адресу:
- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`
- **OpenAPI Schema**: `http://localhost:8000/openapi.json`

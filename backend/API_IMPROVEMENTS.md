# Доработки API для улучшения работы с сессиями

## 📋 Обзор

Данный документ содержит предложения по доработке Cynical Circle API для улучшения работы с пользовательскими сессиями и безопасности.

## 🔐 Предлагаемые доработки

### 1. Эндпоинт для проверки сессии

**Цель:** Позволить клиенту проверить валидность сохраненной сессии пользователя.

#### GET `/users/me`
**Описание:** Возвращает информацию о текущем авторизованном пользователе на основе сессии.

**Заголовки запроса:**
```
Authorization: Bearer <session_token>
```
или
```
X-User-ID: <user_id>
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
- `401 Unauthorized` - Неверная или отсутствующая сессия
- `404 Not Found` - Пользователь не найден

### 2. Эндпоинт для завершения сессии

**Цель:** Позволить клиенту корректно завершить сессию пользователя.

#### POST `/users/logout`
**Описание:** Завершает текущую сессию пользователя.

**Заголовки запроса:**
```
Authorization: Bearer <session_token>
```
или
```
X-User-ID: <user_id>
```

**Ответ:** `200 OK`
```json
{
    "message": "Сессия успешно завершена"
}
```

**Ошибки:**
- `401 Unauthorized` - Неверная или отсутствующая сессия

### 3. Эндпоинт для обновления сессии

**Цель:** Позволить клиенту обновить время жизни сессии.

#### POST `/users/refresh-session`
**Описание:** Обновляет время жизни текущей сессии.

**Заголовки запроса:**
```
Authorization: Bearer <session_token>
```
или
```
X-User-ID: <user_id>
```

**Ответ:** `200 OK`
```json
{
    "message": "Сессия обновлена",
    "expires_at": "2024-01-08T12:00:00Z"
}
```

**Ошибки:**
- `401 Unauthorized` - Неверная или отсутствующая сессия

## 🔧 Альтернативные подходы

### Вариант 1: JWT токены
```python
# Пример реализации с JWT
from jose import jwt
from datetime import datetime, timedelta

def create_access_token(user_id: str):
    expire = datetime.utcnow() + timedelta(days=7)
    to_encode = {"sub": user_id, "exp": expire}
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def verify_token(token: str):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        return user_id
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")
```

### Вариант 2: Сессии в базе данных
```python
# Пример модели сессии
class UserSession(BaseModel):
    id: UUID
    user_id: UUID
    session_token: str
    created_at: datetime
    expires_at: datetime
    is_active: bool = True

# Эндпоинт для создания сессии
@app.post("/users/{user_id}/sessions/")
async def create_session(user_id: UUID):
    session_token = generate_session_token()
    expires_at = datetime.utcnow() + timedelta(days=7)
    
    session = UserSession(
        id=uuid4(),
        user_id=user_id,
        session_token=session_token,
        created_at=datetime.utcnow(),
        expires_at=expires_at
    )
    
    # Сохранить в БД
    return {"session_token": session_token, "expires_at": expires_at}
```

## 🛡️ Рекомендации по безопасности

### 1. Валидация сессий
- Проверка времени истечения сессии
- Проверка активности пользователя
- Возможность отзыва сессий

### 2. Безопасность cookies
- Использование флага `HttpOnly`
- Использование флага `Secure` для HTTPS
- Правильная настройка `SameSite`

### 3. Логирование
- Логирование входов и выходов
- Отслеживание подозрительной активности
- Мониторинг неудачных попыток входа

## 📝 Примеры использования

### Проверка сессии при загрузке страницы
```javascript
async function checkSession() {
    const sessionToken = getCookie('session_token');
    if (sessionToken) {
        try {
            const response = await fetch('/users/me', {
                headers: {
                    'Authorization': `Bearer ${sessionToken}`
                }
            });
            
            if (response.ok) {
                const user = await response.json();
                // Пользователь авторизован
                return user;
            }
        } catch (error) {
            // Ошибка проверки сессии
            deleteCookie('session_token');
        }
    }
    return null;
}
```

### Корректный выход из системы
```javascript
async function logout() {
    const sessionToken = getCookie('session_token');
    if (sessionToken) {
        try {
            await fetch('/users/logout', {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${sessionToken}`
                }
            });
        } catch (error) {
            console.error('Ошибка при выходе:', error);
        }
    }
    
    // Очищаем локальные данные
    deleteCookie('session_token');
    currentUser = null;
    updateUI();
}
```

## 🎯 Приоритеты реализации

1. **Высокий приоритет:**
   - Эндпоинт `/users/me` для проверки сессии
   - Улучшение безопасности cookies

2. **Средний приоритет:**
   - Эндпоинт `/users/logout` для завершения сессии
   - Логирование активности пользователей

3. **Низкий приоритет:**
   - Эндпоинт обновления сессии
   - Расширенная аналитика

## 📊 Ожидаемые улучшения

- **Безопасность:** Более надежная система аутентификации
- **Удобство:** Автоматическое восстановление сессий
- **Производительность:** Кэширование данных пользователя
- **Мониторинг:** Лучшее отслеживание активности пользователей

---

*Документ создан для улучшения системы управления сессиями в Cynical Circle API*

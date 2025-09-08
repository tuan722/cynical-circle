# Задачи для фронтенда

## Обзор

Фронтенд размещен на отдельном сервере и должен интегрироваться с API сервером `http://127.0.0.1:8000`. API полностью готов и настроен для работы с фронтендом.

## 🔧 Необходимые изменения на фронтенде

### 1. Обработка ошибок API
**Приоритет:** Высокий

**Задача:** Добавить обработку fallback ответов от API

**Проблема:** При обращении к неизвестным маршрутам API возвращает информативный JSON вместо стандартной ошибки 404.

**Детали:**
- При получении 404 от API с полем `"message": "Это API сервер. Фронтенд размещен отдельно."` показывать пользователю информативное сообщение
- Использовать информацию из `available_routes` для отображения доступных API эндпоинтов
- Обрабатывать случаи, когда пользователь случайно переходит на API URL

**Пример обработки:**
```javascript
// В обработчике ошибок фронтенда
if (error.response?.data?.message === "Это API сервер. Фронтенд размещен отдельно.") {
  // Показать пользователю, что запрос был сделан к API серверу
  // Можно отобразить доступные маршруты из error.response.data.available_routes
  console.log('Доступные API маршруты:', error.response.data.available_routes);
  
  // Показать пользователю информативное сообщение
  showNotification('Это API сервер. Фронтенд размещен отдельно.', 'info');
}
```

**Структура fallback ответа:**
```json
{
  "error": "Маршрут не найден",
  "requested_path": "/profile",
  "message": "Это API сервер. Фронтенд размещен отдельно.",
  "available_routes": {
    "api_routes": {
      "users": { "base_url": "/users", "methods": ["GET", "POST"], "endpoints": [...] },
      "posts": { "base_url": "/posts", "methods": ["GET", "POST", "DELETE"], "endpoints": [...] },
      "comments": { "base_url": "/posts/{post_id}/comments", "methods": ["GET", "POST"], "endpoints": [...] },
      "stats": { "base_url": "/stats", "methods": ["GET"], "endpoints": [...] }
    },
    "documentation": {
      "swagger_ui": "/docs",
      "redoc": "/redoc",
      "openapi_json": "/openapi.json"
    },
    "frontend_info": {
      "note": "Фронтенд размещен на отдельном сервере",
      "cors_enabled": true,
      "supported_origins": "Все домены (для разработки)"
    }
  }
}
```

### 2. Настройка базового URL
**Приоритет:** Высокий

**Задача:** Убедиться, что фронтенд обращается к правильному API серверу

**Детали:**
- API сервер: `http://127.0.0.1:8000` (или соответствующий домен в продакшене)
- Все API запросы должны идти к этому серверу
- CORS настроен для работы с любыми доменами (в разработке)

**Пример настройки:**
```javascript
// Конфигурация API
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://127.0.0.1:8000';

// Или для других фреймворков
const config = {
  apiUrl: 'http://127.0.0.1:8000',
  // другие настройки
};
```

### 3. Обработка CORS
**Приоритет:** Высокий

**Задача:** Настроить фронтенд для работы с CORS

**Детали:**
- API поддерживает preflight OPTIONS запросы
- Разрешены все HTTP методы и заголовки
- Credentials включены

**Пример настройки axios:**
```javascript
import axios from 'axios';

const api = axios.create({
  baseURL: 'http://127.0.0.1:8000',
  withCredentials: true,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Добавление интерсепторов для обработки ошибок
api.interceptors.response.use(
  (response) => response,
  (error) => {
    // Обработка fallback ответов от API
    if (error.response?.data?.message === "Это API сервер. Фронтенд размещен отдельно.") {
      console.warn('Обращение к API серверу:', error.response.data);
      // Можно перенаправить пользователя или показать уведомление
    }
    return Promise.reject(error);
  }
);

export default api;
```

**Пример для fetch:**
```javascript
const apiRequest = async (endpoint, options = {}) => {
  const url = `http://127.0.0.1:8000${endpoint}`;
  
  const defaultOptions = {
    credentials: 'include',
    headers: {
      'Content-Type': 'application/json',
    },
  };
  
  const response = await fetch(url, { ...defaultOptions, ...options });
  
  if (!response.ok) {
    const errorData = await response.json();
    
    // Обработка fallback ответов
    if (errorData.message === "Это API сервер. Фронтенд размещен отдельно.") {
      console.warn('Обращение к API серверу:', errorData);
    }
    
    throw new Error(errorData.message || 'Ошибка API');
  }
  
  return response.json();
};
```

### 4. Интеграция с API эндпоинтами
**Приоритет:** Средний

**Задача:** Реализовать функции для работы с API

**Доступные эндпоинты:**

#### Пользователи
```javascript
// Создание пользователя
const createUser = async (userData) => {
  return api.post('/users/', userData);
};

// Получение всех пользователей
const getUsers = async () => {
  return api.get('/users/');
};

// Получение пользователя по ID
const getUser = async (userId) => {
  return api.get(`/users/${userId}`);
};

// Обновление статуса пользователя
const updateUserStatus = async (userId, status) => {
  return api.put(`/users/${userId}/status`, status);
};

// Удаление пользователя
const deleteUser = async (userId) => {
  return api.delete(`/users/${userId}`);
};
```

#### Посты
```javascript
// Создание поста
const createPost = async (userId, postData) => {
  return api.post(`/posts/?user_id=${userId}`, postData);
};

// Получение всех постов
const getPosts = async () => {
  return api.get('/posts/');
};

// Получение поста по ID
const getPost = async (postId) => {
  return api.get(`/posts/${postId}`);
};

// Реакция на пост
const reactToPost = async (postId, userId, reactionType) => {
  return api.post(`/posts/${postId}/react?user_id=${userId}&reaction_type=${reactionType}`);
};

// Удаление поста
const deletePost = async (postId) => {
  return api.delete(`/posts/${postId}`);
};
```

#### Комментарии
```javascript
// Создание комментария
const createComment = async (postId, userId, commentData) => {
  return api.post(`/posts/${postId}/comments/?user_id=${userId}`, commentData);
};

// Получение комментариев к посту
const getComments = async (postId) => {
  return api.get(`/posts/${postId}/comments/`);
};
```

#### Статистика
```javascript
// Получение статистики
const getStats = async () => {
  return api.get('/stats/');
};
```

### 5. Обработка состояний загрузки и ошибок
**Приоритет:** Средний

**Задача:** Добавить обработку состояний загрузки и ошибок

**Примеры:**
```javascript
// Хук для работы с API
const useApi = () => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const apiCall = async (apiFunction) => {
    try {
      setLoading(true);
      setError(null);
      const result = await apiFunction();
      return result;
    } catch (err) {
      setError(err.message);
      throw err;
    } finally {
      setLoading(false);
    }
  };

  return { loading, error, apiCall };
};
```

### 6. Валидация данных
**Приоритет:** Низкий

**Задача:** Добавить валидацию данных перед отправкой на API

**Примеры:**
```javascript
// Валидация пользователя
const validateUser = (userData) => {
  const errors = {};
  
  if (!userData.username || userData.username.length < 3) {
    errors.username = 'Имя пользователя должно содержать минимум 3 символа';
  }
  
  if (!userData.email || !/\S+@\S+\.\S+/.test(userData.email)) {
    errors.email = 'Введите корректный email';
  }
  
  if (!userData.password || userData.password.length < 6) {
    errors.password = 'Пароль должен содержать минимум 6 символов';
  }
  
  return errors;
};

// Валидация поста
const validatePost = (postData) => {
  const errors = {};
  
  if (!postData.title || postData.title.trim().length === 0) {
    errors.title = 'Заголовок не может быть пустым';
  }
  
  if (!postData.content || postData.content.trim().length === 0) {
    errors.content = 'Содержимое не может быть пустым';
  }
  
  return errors;
};
```

## Тестирование интеграции

### 1. Проверка подключения к API
```javascript
// Тест подключения
const testApiConnection = async () => {
  try {
    const response = await api.get('/');
    console.log('API подключен:', response.data);
    return true;
  } catch (error) {
    console.error('Ошибка подключения к API:', error);
    return false;
  }
};
```

### 2. Тест CORS
```javascript
// Тест CORS
const testCors = async () => {
  try {
    const response = await api.options('/users/');
    console.log('CORS работает:', response.status === 200);
    return true;
  } catch (error) {
    console.error('Ошибка CORS:', error);
    return false;
  }
};
```

### 3. Тест fallback
```javascript
// Тест fallback
const testFallback = async () => {
  try {
    const response = await api.get('/unknown-route');
    console.log('Fallback работает:', response.data.message);
    return true;
  } catch (error) {
    console.error('Ошибка fallback:', error);
    return false;
  }
};
```

## Рекомендации по реализации

### 1. Структура проекта
```
src/
├── api/
│   ├── index.js          # Основная конфигурация API
│   ├── users.js          # API для пользователей
│   ├── posts.js          # API для постов
│   ├── comments.js       # API для комментариев
│   └── stats.js          # API для статистики
├── hooks/
│   └── useApi.js         # Хук для работы с API
├── utils/
│   ├── validation.js     # Валидация данных
│   └── errorHandler.js   # Обработка ошибок
└── components/
    └── ErrorBoundary.js  # Компонент для обработки ошибок
```

### 2. Переменные окружения
```bash
# .env
REACT_APP_API_URL=http://127.0.0.1:8000
REACT_APP_API_TIMEOUT=10000
```

### 3. Типизация (для TypeScript)
```typescript
interface ApiResponse<T> {
  data: T;
  status: number;
  message?: string;
}

interface User {
  id: string;
  username: string;
  email: string;
  is_active: boolean;
  status?: string;
}

interface Post {
  id: string;
  title: string;
  content: string;
  owner_id: string;
  created_at: string;
  reactions: Reaction[];
}
```

## Статус задач

### 🔄 В процессе
- [ ] Настройка базового URL API
- [ ] Обработка CORS
- [ ] Обработка ошибок API

### ⏳ Планируется
- [ ] Интеграция с API эндпоинтами
- [ ] Обработка состояний загрузки
- [ ] Валидация данных
- [ ] Тестирование интеграции

### ✅ Завершено
- [ ] Анализ требований API
- [ ] Создание документации задач

---

**Примечание:** API сервер полностью готов и протестирован. Все эндпоинты работают корректно, CORS настроен, fallback реализован. Фронтенд может начинать интеграцию с API.

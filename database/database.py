"""
Модуль для работы с базой данных PostgreSQL
"""

import os
import asyncio
import asyncpg
from typing import List, Optional, Dict, Any
from datetime import datetime
import uuid
import json
from contextlib import asynccontextmanager

# Настройки подключения к базе данных
DATABASE_URL = os.getenv(
    "DATABASE_URL", 
    "postgresql://cynical_app:secure_password_123@localhost:5432/cynical_circle"
)

class Database:
    """Класс для работы с базой данных PostgreSQL"""
    
    def __init__(self, database_url: str = DATABASE_URL):
        self.database_url = database_url
        self._pool = None
    
    async def connect(self):
        """Создание пула подключений к базе данных"""
        self._pool = await asyncpg.create_pool(
            self.database_url,
            min_size=1,
            max_size=10,
            command_timeout=60
        )
    
    async def close(self):
        """Закрытие пула подключений"""
        if self._pool:
            await self._pool.close()
    
    @asynccontextmanager
    async def get_connection(self):
        """Контекстный менеджер для получения подключения"""
        if not self._pool:
            await self.connect()
        
        async with self._pool.acquire() as connection:
            yield connection
    
    # Методы для работы с пользователями
    async def get_users(self) -> List[Dict[str, Any]]:
        """Получить всех пользователей"""
        async with self.get_connection() as conn:
            rows = await conn.fetch("""
                SELECT id, username, email, is_active, status, created_at, updated_at
                FROM users
                ORDER BY created_at DESC
            """)
            return [dict(row) for row in rows]
    
    async def get_user_by_id(self, user_id: uuid.UUID) -> Optional[Dict[str, Any]]:
        """Получить пользователя по ID"""
        async with self.get_connection() as conn:
            row = await conn.fetchrow("""
                SELECT id, username, email, is_active, status, created_at, updated_at
                FROM users
                WHERE id = $1
            """, user_id)
            return dict(row) if row else None
    
    async def get_user_by_email(self, email: str) -> Optional[Dict[str, Any]]:
        """Получить пользователя по email"""
        async with self.get_connection() as conn:
            row = await conn.fetchrow("""
                SELECT id, username, email, is_active, status, created_at, updated_at
                FROM users
                WHERE email = $1
            """, email)
            return dict(row) if row else None
    
    async def create_user(self, username: str, email: str, password_hash: str, status: Optional[str] = None) -> Dict[str, Any]:
        """Создать нового пользователя"""
        async with self.get_connection() as conn:
            row = await conn.fetchrow("""
                INSERT INTO users (username, email, password_hash, status)
                VALUES ($1, $2, $3, $4::user_status)
                RETURNING id, username, email, is_active, status, created_at, updated_at
            """, username, email, password_hash, status)
            return dict(row)
    
    async def update_user_status(self, user_id: uuid.UUID, status: Optional[str]) -> Optional[Dict[str, Any]]:
        """Обновить статус пользователя"""
        async with self.get_connection() as conn:
            row = await conn.fetchrow("""
                UPDATE users 
                SET status = $2::user_status, updated_at = CURRENT_TIMESTAMP
                WHERE id = $1
                RETURNING id, username, email, is_active, status, created_at, updated_at
            """, user_id, status)
            return dict(row) if row else None
    
    async def delete_user(self, user_id: uuid.UUID) -> bool:
        """Удалить пользователя"""
        async with self.get_connection() as conn:
            result = await conn.execute("""
                DELETE FROM users WHERE id = $1
            """, user_id)
            return result == "DELETE 1"
    
    # Методы для работы с постами
    async def get_posts(self) -> List[Dict[str, Any]]:
        """Получить все посты с реакциями"""
        async with self.get_connection() as conn:
            rows = await conn.fetch("""
                SELECT * FROM posts_with_reactions
                ORDER BY created_at DESC
            """)
            return [dict(row) for row in rows]
    
    async def get_post_by_id(self, post_id: uuid.UUID) -> Optional[Dict[str, Any]]:
        """Получить пост по ID"""
        async with self.get_connection() as conn:
            row = await conn.fetchrow("""
                SELECT * FROM posts_with_reactions
                WHERE id = $1
            """, post_id)
            return dict(row) if row else None
    
    async def create_post(self, title: str, content: str, owner_id: uuid.UUID) -> Dict[str, Any]:
        """Создать новый пост"""
        async with self.get_connection() as conn:
            row = await conn.fetchrow("""
                INSERT INTO posts (title, content, owner_id)
                VALUES ($1, $2, $3)
                RETURNING id, title, content, owner_id, created_at, updated_at
            """, title, content, owner_id)
            
            # Получаем пост с реакциями
            post_with_reactions = await conn.fetchrow("""
                SELECT * FROM posts_with_reactions
                WHERE id = $1
            """, row['id'])
            
            return dict(post_with_reactions)
    
    async def delete_post(self, post_id: uuid.UUID) -> bool:
        """Удалить пост"""
        async with self.get_connection() as conn:
            result = await conn.execute("""
                DELETE FROM posts WHERE id = $1
            """, post_id)
            return result == "DELETE 1"
    
    # Методы для работы с реакциями
    async def add_reaction(self, post_id: uuid.UUID, user_id: uuid.UUID, reaction_type: str) -> Dict[str, Any]:
        """Добавить или обновить реакцию на пост"""
        async with self.get_connection() as conn:
            # Используем функцию add_or_update_reaction
            reaction_id = await conn.fetchval("""
                SELECT add_or_update_reaction($1, $2, $3::reaction_type)
            """, post_id, user_id, reaction_type)
            
            # Получаем обновленный пост с реакциями
            post = await conn.fetchrow("""
                SELECT * FROM posts_with_reactions
                WHERE id = $1
            """, post_id)
            
            return dict(post)
    
    # Методы для работы с комментариями
    async def get_comments_by_post_id(self, post_id: uuid.UUID) -> List[Dict[str, Any]]:
        """Получить комментарии к посту"""
        async with self.get_connection() as conn:
            rows = await conn.fetch("""
                SELECT c.id, c.content, c.post_id, c.owner_id, c.created_at, c.updated_at,
                       u.username as owner_username
                FROM comments c
                JOIN users u ON c.owner_id = u.id
                WHERE c.post_id = $1
                ORDER BY c.created_at ASC
            """, post_id)
            return [dict(row) for row in rows]
    
    async def create_comment(self, post_id: uuid.UUID, owner_id: uuid.UUID, content: str) -> Dict[str, Any]:
        """Создать новый комментарий"""
        async with self.get_connection() as conn:
            row = await conn.fetchrow("""
                INSERT INTO comments (post_id, owner_id, content)
                VALUES ($1, $2, $3)
                RETURNING id, content, post_id, owner_id, created_at, updated_at
            """, post_id, owner_id, content)
            return dict(row)
    
    # Методы для статистики
    async def get_system_stats(self) -> Dict[str, Any]:
        """Получить статистику системы"""
        async with self.get_connection() as conn:
            row = await conn.fetchrow("SELECT * FROM get_system_stats()")
            return dict(row)
    
    # Методы для проверки существования
    async def user_exists(self, user_id: uuid.UUID) -> bool:
        """Проверить существование пользователя"""
        async with self.get_connection() as conn:
            result = await conn.fetchval("""
                SELECT EXISTS(SELECT 1 FROM users WHERE id = $1)
            """, user_id)
            return result
    
    async def post_exists(self, post_id: uuid.UUID) -> bool:
        """Проверить существование поста"""
        async with self.get_connection() as conn:
            result = await conn.fetchval("""
                SELECT EXISTS(SELECT 1 FROM posts WHERE id = $1)
            """, post_id)
            return result

# Глобальный экземпляр базы данных
db = Database()

# Функции для обратной совместимости с существующим кодом
async def get_users() -> List[Dict[str, Any]]:
    """Получить всех пользователей (обратная совместимость)"""
    return await db.get_users()

async def get_posts() -> List[Dict[str, Any]]:
    """Получить все посты (обратная совместимость)"""
    return await db.get_posts()

async def get_comments() -> List[Dict[str, Any]]:
    """Получить все комментарии (обратная совместимость)"""
    # Для обратной совместимости возвращаем пустой список
    # В реальном приложении можно получить все комментарии
    return []

async def add_user(user_data: Dict[str, Any]) -> Dict[str, Any]:
    """Добавить пользователя (обратная совместимость)"""
    return await db.create_user(
        username=user_data['username'],
        email=user_data['email'],
        password_hash=user_data.get('password_hash', ''),
        status=user_data.get('status')
    )

async def add_post(post_data: Dict[str, Any]) -> Dict[str, Any]:
    """Добавить пост (обратная совместимость)"""
    return await db.create_post(
        title=post_data['title'],
        content=post_data['content'],
        owner_id=post_data['owner_id']
    )

async def add_comment(comment_data: Dict[str, Any]) -> Dict[str, Any]:
    """Добавить комментарий (обратная совместимость)"""
    return await db.create_comment(
        post_id=comment_data['post_id'],
        owner_id=comment_data['owner_id'],
        content=comment_data['content']
    )

async def remove_user(user_id: uuid.UUID) -> bool:
    """Удалить пользователя (обратная совместимость)"""
    return await db.delete_user(user_id)

async def remove_post(post_id: uuid.UUID) -> bool:
    """Удалить пост (обратная совместимость)"""
    return await db.delete_post(post_id)

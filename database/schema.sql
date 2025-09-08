-- Схема базы данных PostgreSQL для Cynical Circle
-- Создание базы данных и таблиц

-- Создание базы данных (выполняется от имени суперпользователя)
-- CREATE DATABASE cynical_circle;
-- \c cynical_circle;

-- Создание расширений
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Создание ENUM типов
CREATE TYPE user_status AS ENUM (
    'contemplating_the_void',
    'pretending_to_work', 
    'on_the_verge',
    'running_on_caffeine'
);

CREATE TYPE reaction_type AS ENUM (
    'sigh',
    'facepalm',
    'cringe',
    'seen'
);

-- Таблица пользователей
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    status user_status,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Таблица постов
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Таблица реакций на посты
CREATE TABLE reactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reaction_type reaction_type NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(post_id, user_id) -- Один пользователь может иметь только одну реакцию на пост
);

-- Таблица комментариев
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Индексы для оптимизации запросов
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_status ON users(status);

CREATE INDEX idx_posts_owner_id ON posts(owner_id);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);

CREATE INDEX idx_reactions_post_id ON reactions(post_id);
CREATE INDEX idx_reactions_user_id ON reactions(user_id);
CREATE INDEX idx_reactions_type ON reactions(reaction_type);

CREATE INDEX idx_comments_post_id ON comments(post_id);
CREATE INDEX idx_comments_owner_id ON comments(owner_id);
CREATE INDEX idx_comments_created_at ON comments(created_at DESC);

-- Функция для автоматического обновления updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Триггеры для автоматического обновления updated_at
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_posts_updated_at 
    BEFORE UPDATE ON posts 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_comments_updated_at 
    BEFORE UPDATE ON comments 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Представления для удобства работы
CREATE VIEW posts_with_reactions AS
SELECT 
    p.id,
    p.title,
    p.content,
    p.owner_id,
    p.created_at,
    p.updated_at,
    COALESCE(
        json_agg(
            json_build_object(
                'id', r.id,
                'user_id', r.user_id,
                'type', r.reaction_type,
                'created_at', r.created_at
            )
        ) FILTER (WHERE r.id IS NOT NULL),
        '[]'::json
    ) as reactions
FROM posts p
LEFT JOIN reactions r ON p.id = r.post_id
GROUP BY p.id, p.title, p.content, p.owner_id, p.created_at, p.updated_at;

CREATE VIEW posts_with_stats AS
SELECT 
    p.id,
    p.title,
    p.content,
    p.owner_id,
    p.created_at,
    p.updated_at,
    u.username as owner_username,
    COUNT(DISTINCT r.id) as reactions_count,
    COUNT(DISTINCT c.id) as comments_count,
    COALESCE(
        json_agg(
            json_build_object(
                'id', r.id,
                'user_id', r.user_id,
                'type', r.reaction_type,
                'created_at', r.created_at
            )
        ) FILTER (WHERE r.id IS NOT NULL),
        '[]'::json
    ) as reactions
FROM posts p
LEFT JOIN users u ON p.owner_id = u.id
LEFT JOIN reactions r ON p.id = r.post_id
LEFT JOIN comments c ON p.id = c.post_id
GROUP BY p.id, p.title, p.content, p.owner_id, p.created_at, p.updated_at, u.username;

-- Функции для работы с реакциями
CREATE OR REPLACE FUNCTION add_or_update_reaction(
    p_post_id UUID,
    p_user_id UUID,
    p_reaction_type reaction_type
)
RETURNS UUID AS $$
DECLARE
    reaction_id UUID;
BEGIN
    -- Проверяем, есть ли уже реакция от этого пользователя
    SELECT id INTO reaction_id 
    FROM reactions 
    WHERE post_id = p_post_id AND user_id = p_user_id;
    
    IF reaction_id IS NOT NULL THEN
        -- Обновляем существующую реакцию
        UPDATE reactions 
        SET reaction_type = p_reaction_type,
            created_at = CURRENT_TIMESTAMP
        WHERE id = reaction_id;
        RETURN reaction_id;
    ELSE
        -- Создаем новую реакцию
        INSERT INTO reactions (post_id, user_id, reaction_type)
        VALUES (p_post_id, p_user_id, p_reaction_type)
        RETURNING id INTO reaction_id;
        RETURN reaction_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Функция для получения статистики
CREATE OR REPLACE FUNCTION get_system_stats()
RETURNS TABLE (
    total_users BIGINT,
    total_posts BIGINT,
    total_comments BIGINT,
    most_common_reaction TEXT,
    most_active_user TEXT,
    average_comments_per_post NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM users) as total_users,
        (SELECT COUNT(*) FROM posts) as total_posts,
        (SELECT COUNT(*) FROM comments) as total_comments,
        (SELECT reaction_type::TEXT 
         FROM reactions 
         GROUP BY reaction_type 
         ORDER BY COUNT(*) DESC 
         LIMIT 1) as most_common_reaction,
        (SELECT u.username 
         FROM users u
         JOIN (
             SELECT owner_id, COUNT(*) as activity_count
             FROM (
                 SELECT owner_id FROM posts
                 UNION ALL
                 SELECT owner_id FROM comments
             ) activity
             GROUP BY owner_id
             ORDER BY activity_count DESC
             LIMIT 1
         ) most_active ON u.id = most_active.owner_id) as most_active_user,
        (SELECT ROUND(AVG(comment_count), 2)
         FROM (
             SELECT COUNT(*) as comment_count
             FROM comments
             GROUP BY post_id
         ) post_comments) as average_comments_per_post;
END;
$$ LANGUAGE plpgsql;

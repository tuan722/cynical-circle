-- Миграция 003: Представления и функции
-- Дата: 2024-01-15
-- Описание: Добавление представлений и функций для работы с данными

-- Представление для постов с реакциями
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

-- Представление для постов со статистикой
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

-- Функция для работы с реакциями
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

-- Скрипт инициализации базы данных Cynical Circle
-- Выполняется после создания схемы

-- Вставка тестовых данных
INSERT INTO users (username, email, password_hash, status) VALUES
('cynical_admin', 'admin@cynical.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/4.5.6.7', 'contemplating_the_void'),
('sarcastic_user', 'sarcasm@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/4.5.6.7', 'pretending_to_work'),
('jaded_developer', 'dev@cynical.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/4.5.6.7', 'running_on_caffeine'),
('existential_crisis', 'crisis@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/4.5.6.7', 'on_the_verge'),
('optimistic_pessimist', 'pessimist@cynical.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/4.5.6.7', 'contemplating_the_void');

-- Получаем ID пользователей для создания постов
DO $$
DECLARE
    admin_id UUID;
    sarcastic_id UUID;
    dev_id UUID;
    crisis_id UUID;
    pessimist_id UUID;
BEGIN
    SELECT id INTO admin_id FROM users WHERE username = 'cynical_admin';
    SELECT id INTO sarcastic_id FROM users WHERE username = 'sarcastic_user';
    SELECT id INTO dev_id FROM users WHERE username = 'jaded_developer';
    SELECT id INTO crisis_id FROM users WHERE username = 'existential_crisis';
    SELECT id INTO pessimist_id FROM users WHERE username = 'optimistic_pessimist';

    -- Создаем тестовые посты
    INSERT INTO posts (title, content, owner_id) VALUES
    ('Добро пожаловать в Cynical Circle', 
     'Добро пожаловать в место, где цинизм встречается с социальными сетями. Здесь мы делимся своими разочарованиями и наслаждаемся чужими страданиями.', 
     admin_id),
    
    ('Почему я все еще здесь?', 
     'Каждый день я просыпаюсь и задаюсь вопросом: зачем? Зачем я здесь? Зачем я создаю еще один пост в социальной сети? Ответа нет, но я продолжаю.', 
     sarcastic_id),
    
    ('Жизнь программиста', 
     'Код работает. Это подозрительно. Обычно в этот момент что-то ломается. Жду, когда все рухнет.', 
     dev_id),
    
    ('Экзистенциальный кризис в 3 утра', 
     'Почему я не сплю? Почему я думаю о смысле жизни в 3 утра? Почему я пишу об этом в социальной сети? Круг вопросов без ответов.', 
     crisis_id),
    
    ('Оптимистичный пессимизм', 
     'Все будет плохо, но я готов к этому. Это и есть мой способ быть оптимистом. Низкие ожидания - ключ к счастью.', 
     pessimist_id),
    
    ('Понедельник', 
     'Понедельник - это способ вселенной напомнить нам, что жизнь - это не вечеринка. Особенно если ты программист.', 
     dev_id),
    
    ('Социальные сети и одиночество', 
     'Ирония в том, что мы используем социальные сети, чтобы чувствовать себя менее одинокими, но в итоге чувствуем себя еще более одинокими.', 
     sarcastic_id);

    -- Добавляем реакции на посты
    INSERT INTO reactions (post_id, user_id, reaction_type)
    SELECT p.id, u.id, 'sigh'
    FROM posts p, users u
    WHERE p.title = 'Добро пожаловать в Cynical Circle' 
    AND u.username IN ('sarcastic_user', 'jaded_developer', 'existential_crisis');

    INSERT INTO reactions (post_id, user_id, reaction_type)
    SELECT p.id, u.id, 'facepalm'
    FROM posts p, users u
    WHERE p.title = 'Почему я все еще здесь?' 
    AND u.username = 'cynical_admin';

    INSERT INTO reactions (post_id, user_id, reaction_type)
    SELECT p.id, u.id, 'cringe'
    FROM posts p, users u
    WHERE p.title = 'Жизнь программиста' 
    AND u.username IN ('sarcastic_user', 'optimistic_pessimist');

    INSERT INTO reactions (post_id, user_id, reaction_type)
    SELECT p.id, u.id, 'seen'
    FROM posts p, users u
    WHERE p.title = 'Экзистенциальный кризис в 3 утра' 
    AND u.username = 'jaded_developer';

    -- Добавляем комментарии
    INSERT INTO comments (post_id, owner_id, content)
    SELECT p.id, u.id, 'Полностью согласен. Жизнь - это серия разочарований.'
    FROM posts p, users u
    WHERE p.title = 'Почему я все еще здесь?' 
    AND u.username = 'cynical_admin';

    INSERT INTO comments (post_id, owner_id, content)
    SELECT p.id, u.id, 'Код работает? Это точно баг, а не фича.'
    FROM posts p, users u
    WHERE p.title = 'Жизнь программиста' 
    AND u.username = 'sarcastic_user';

    INSERT INTO comments (post_id, owner_id, content)
    SELECT p.id, u.id, 'Попробуйте кофе. Много кофе.'
    FROM posts p, users u
    WHERE p.title = 'Экзистенциальный кризис в 3 утра' 
    AND u.username = 'jaded_developer';

    INSERT INTO comments (post_id, owner_id, content)
    SELECT p.id, u.id, 'Низкие ожидания - это путь к счастью. Или к меньшему разочарованию.'
    FROM posts p, users u
    WHERE p.title = 'Оптимистичный пессимизм' 
    AND u.username = 'existential_crisis';

    INSERT INTO comments (post_id, owner_id, content)
    SELECT p.id, u.id, 'Понедельник - это способ вселенной сказать нам, что выходные закончились.'
    FROM posts p, users u
    WHERE p.title = 'Понедельник' 
    AND u.username = 'optimistic_pessimist';

END $$;

-- Создаем пользователя для приложения (если нужно)
-- CREATE USER cynical_app WITH PASSWORD 'secure_password_123';
-- GRANT CONNECT ON DATABASE cynical_circle TO cynical_app;
-- GRANT USAGE ON SCHEMA public TO cynical_app;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO cynical_app;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO cynical_app;

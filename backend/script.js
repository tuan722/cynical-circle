// Конфигурация API
const API_BASE_URL = 'http://127.0.0.1:8000';

// Обработка ошибок API
function handleApiError(error, context = '') {
    console.error(`API Error ${context}:`, error);
    
    // Проверяем, является ли это fallback ответом от API
    if (error.message && error.message.includes('Это API сервер. Фронтенд размещен отдельно.')) {
        showNotification('Ошибка: обращение к API серверу вместо фронтенда', 'error');
        console.warn('Fallback response from API:', error);
        return;
    }
    
    // Обработка других ошибок
    if (error.message) {
        showNotification(error.message, 'error');
    } else {
        showNotification('Ошибка соединения с сервером', 'error');
    }
}

// Валидация данных
function validateUser(userData) {
    const errors = {};
    
    if (!userData.username || userData.username.trim().length < 3) {
        errors.username = 'Имя пользователя должно содержать минимум 3 символа';
    }
    
    if (!userData.email || !/\S+@\S+\.\S+/.test(userData.email)) {
        errors.email = 'Введите корректный email';
    }
    
    if (!userData.password || userData.password.length < 6) {
        errors.password = 'Пароль должен содержать минимум 6 символов';
    }
    
    return errors;
}

function validatePost(postData) {
    const errors = {};
    
    if (!postData.title || postData.title.trim().length === 0) {
        errors.title = 'Заголовок не может быть пустым';
    }
    
    if (!postData.content || postData.content.trim().length === 0) {
        errors.content = 'Содержимое не может быть пустым';
    }
    
    return errors;
}

function validateComment(commentData) {
    const errors = {};
    
    if (!commentData.content || commentData.content.trim().length === 0) {
        errors.content = 'Комментарий не может быть пустым';
    }
    
    return errors;
}

// Глобальные переменные
let currentUser = null;
let allUsers = [];
let allPosts = [];

// Константы для cookies
const COOKIE_USER_ID = 'cynical_user_id';
const COOKIE_EXPIRES_DAYS = 7;

// Элементы DOM
const loginBtn = document.getElementById('loginBtn');
const registerBtn = document.getElementById('registerBtn');
const postsBtn = document.getElementById('postsBtn');
const createPostBtn = document.getElementById('createPostBtn');
const profileBtn = document.getElementById('profileBtn');
const logoutBtn = document.getElementById('logoutBtn');

const loginForm = document.getElementById('loginForm');
const registerForm = document.getElementById('registerForm');
const postsContainer = document.getElementById('postsContainer');
const createPostForm = document.getElementById('createPostForm');
const profileContainer = document.getElementById('profileContainer');

const loginFormElement = document.getElementById('loginFormElement');
const registerFormElement = document.getElementById('registerFormElement');
const createPostFormElement = document.getElementById('createPostFormElement');
const statusForm = document.getElementById('statusForm');

const postsList = document.getElementById('postsList');

// Тестирование API подключения
async function testApiConnection() {
    try {
        const response = await fetch(`${API_BASE_URL}/`, {
            method: 'GET',
            mode: 'cors',
            headers: {
                'Accept': 'application/json',
            }
        });
        
        if (response.ok) {
            const data = await response.json();
            console.log('✅ API подключен:', data);
            return true;
        } else {
            console.warn('⚠️ API ответил с ошибкой:', response.status);
            return false;
        }
    } catch (error) {
        console.error('❌ Ошибка подключения к API:', error);
        return false;
    }
}

// Инициализация
document.addEventListener('DOMContentLoaded', async function() {
    setupEventListeners();
    setupRouting();
    
    // Тестируем подключение к API
    const apiConnected = await testApiConnection();
    if (!apiConnected) {
        showNotification('Предупреждение: не удается подключиться к API серверу', 'error');
    }
    
    loadUsers();
    checkSavedSession();
});

// Функции для работы с cookies
function setCookie(name, value, days) {
    const expires = new Date();
    expires.setTime(expires.getTime() + (days * 24 * 60 * 60 * 1000));
    document.cookie = `${name}=${value};expires=${expires.toUTCString()};path=/;SameSite=Lax`;
}

function getCookie(name) {
    const nameEQ = name + "=";
    const ca = document.cookie.split(';');
    for (let i = 0; i < ca.length; i++) {
        let c = ca[i];
        while (c.charAt(0) === ' ') c = c.substring(1, c.length);
        if (c.indexOf(nameEQ) === 0) return c.substring(nameEQ.length, c.length);
    }
    return null;
}

function deleteCookie(name) {
    document.cookie = `${name}=;expires=Thu, 01 Jan 1970 00:00:00 UTC;path=/;`;
}

// Проверка сохраненной сессии
async function checkSavedSession() {
    const savedUserId = getCookie(COOKIE_USER_ID);
    if (savedUserId) {
        try {
            // Пытаемся загрузить пользователя по сохраненному ID
            const response = await fetch(`${API_BASE_URL}/users/${savedUserId}`, {
                method: 'GET',
                mode: 'cors',
                headers: {
                    'Accept': 'application/json',
                }
            });

            if (response.ok) {
                const user = await response.json();
                currentUser = user;
                
                // Обновляем локальный список пользователей
                const existingUserIndex = allUsers.findIndex(u => u.id === user.id);
                if (existingUserIndex !== -1) {
                    allUsers[existingUserIndex] = user;
                } else {
                    allUsers.push(user);
                }
                
                updateUI();
                showNotification('Добро пожаловать обратно! Сессия восстановлена.', 'success');
                
                // Перенаправляем на посты если не на странице авторизации
                if (window.location.pathname === '/' || window.location.pathname === '/login') {
                    await navigateTo('/posts');
                }
            } else {
                // Пользователь не найден, удаляем cookie
                deleteCookie(COOKIE_USER_ID);
            }
        } catch (error) {
            handleApiError(error, 'при восстановлении сессии');
            deleteCookie(COOKIE_USER_ID);
        }
    }
}

// Настройка роутинга
function setupRouting() {
    // Обработка изменения URL
    window.addEventListener('popstate', handleRoute);
    
    // Обработка начального URL
    handleRoute();
}

// Обработка маршрутов
async function handleRoute() {
    const path = window.location.pathname;
    
    switch(path) {
        case '/':
        case '/login':
            showForm('login');
            break;
        case '/register':
            showForm('register');
            break;
        case '/posts':
            showForm('posts');
            break;
        case '/create-post':
            showForm('createPost');
            break;
        case '/profile':
            showForm('profile');
            break;
        default:
            // Неизвестный маршрут - перенаправляем на авторизацию
            await navigateTo('/login');
            break;
    }
}

// Навигация по URL
async function navigateTo(path) {
    window.history.pushState({}, '', path);
    await handleRoute();
}

// Настройка обработчиков событий
function setupEventListeners() {
    // Навигация
    loginBtn.addEventListener('click', async () => await navigateTo('/login'));
    registerBtn.addEventListener('click', async () => await navigateTo('/register'));
    postsBtn.addEventListener('click', async () => await navigateTo('/posts'));
    createPostBtn.addEventListener('click', async () => await navigateTo('/create-post'));
    profileBtn.addEventListener('click', async () => await navigateTo('/profile'));
    logoutBtn.addEventListener('click', logout);

    // Формы
    loginFormElement.addEventListener('submit', handleLogin);
    registerFormElement.addEventListener('submit', handleRegister);
    createPostFormElement.addEventListener('submit', handleCreatePost);
    statusForm.addEventListener('submit', handleStatusUpdate);

    // Хлебные крошки
    document.addEventListener('click', async function(e) {
        if (e.target.classList.contains('breadcrumb-link')) {
            e.preventDefault();
            await navigateTo(e.target.getAttribute('href'));
        }
    });
}

// Показать нужную форму/контейнер
async function showForm(formType) {
    // Скрыть все формы
    [loginForm, registerForm, postsContainer, createPostForm, profileContainer].forEach(form => {
        form.style.display = 'none';
    });

    // Управление хлебными крошками
    const breadcrumbs = document.getElementById('breadcrumbs');
    const currentPage = document.getElementById('currentPage');

    // Показать нужную форму
    switch(formType) {
        case 'login':
            loginForm.style.display = 'block';
            breadcrumbs.style.display = 'none'; // Скрываем хлебные крошки на странице авторизации
            break;
        case 'register':
            registerForm.style.display = 'block';
            breadcrumbs.style.display = 'flex';
            currentPage.textContent = 'Регистрация';
            break;
        case 'posts':
            postsContainer.style.display = 'block';
            breadcrumbs.style.display = 'flex';
            currentPage.textContent = 'Посты';
            loadPosts();
            break;
        case 'createPost':
            createPostForm.style.display = 'block';
            breadcrumbs.style.display = 'flex';
            currentPage.textContent = 'Создание поста';
            break;
        case 'profile':
            profileContainer.style.display = 'block';
            breadcrumbs.style.display = 'flex';
            currentPage.textContent = 'Профиль';
            await displayProfile();
            break;
    }
}

// Загрузка пользователей
async function loadUsers() {
    try {
        const response = await fetch(`${API_BASE_URL}/users/`, {
            method: 'GET',
            mode: 'cors',
            headers: {
                'Accept': 'application/json',
            }
        });
        
        if (response.ok) {
            allUsers = await response.json();
            displayUsersList();
        } else if (response.status === 404) {
            allUsers = [];
            displayNoUsersMessage();
        } else {
            console.error('Ошибка загрузки пользователей:', response.status, response.statusText);
            allUsers = [];
        }
    } catch (error) {
        handleApiError(error, 'при загрузке пользователей');
        allUsers = [];
    }
}

// Загрузка постов
async function loadPosts() {
    try {
        const response = await fetch(`${API_BASE_URL}/posts/`, {
            method: 'GET',
            mode: 'cors',
            headers: {
                'Accept': 'application/json',
            }
        });
        if (response.ok) {
            allPosts = await response.json();
            displayPosts();
        } else if (response.status === 404) {
            postsList.innerHTML = '<p style="text-align: center; color: #718096; font-style: italic;">Пока нет постов. Будьте первым, кто поделится своим цинизмом!</p>';
        }
    } catch (error) {
        handleApiError(error, 'при загрузке постов');
    }
}

// Отображение списка пользователей
function displayUsersList() {
    const usersContainer = document.getElementById('usersList');
    if (!usersContainer) return;
    
    if (allUsers.length === 0) {
        usersContainer.innerHTML = '<p style="text-align: center; color: #718096; font-style: italic;">База пользователей пуста. Как и наши надежды на лучшее.</p>';
        return;
    }
    
    usersContainer.innerHTML = `
        <div class="users-section">
            <h3>Зарегистрированные циники (${allUsers.length})</h3>
            <div class="users-grid">
                ${allUsers.map(user => `
                    <div class="user-card">
                        <div class="user-info">
                            <div class="user-username">${escapeHtml(user.username)}</div>
                            <div class="user-id">ID: ${escapeHtml(user.id)}</div>
                            <div class="user-email">${escapeHtml(user.email)}</div>
                            ${user.status ? `<div class="user-status status-${user.status}">${getStatusText(user.status)}</div>` : ''}
                        </div>
                        <div class="user-actions">
                            <button class="btn btn-small" onclick="loginAsUser('${user.id}')">Войти</button>
                        </div>
                    </div>
                `).join('')}
            </div>
        </div>
    `;
}

// Отображение сообщения об отсутствии пользователей
function displayNoUsersMessage() {
    const usersContainer = document.getElementById('usersList');
    if (!usersContainer) return;
    
    usersContainer.innerHTML = `
        <div class="no-users-message">
            <h3>База пользователей пуста</h3>
            <p>Как и наши надежды на лучшее. Никто еще не решился присоединиться к нашему циничному кругу.</p>
            <p>Будьте первым, кто осмелится зарегистрироваться в этой социальной сети для разочарованных.</p>
            <button class="btn btn-primary" onclick="navigateTo('/register')">Стать первым циником</button>
        </div>
    `;
}

// Вход под выбранным пользователем
async function loginAsUser(userId) {
    try {
        // Отправляем GET запрос к конкретному пользователю по ID
        const response = await fetch(`${API_BASE_URL}/users/${userId}`, {
            method: 'GET',
            mode: 'cors',
            headers: {
                'Accept': 'application/json',
            }
        });

        if (response.ok) {
            const user = await response.json();
            currentUser = user;
            
            // Сохраняем ID пользователя в cookies
            setCookie(COOKIE_USER_ID, user.id, COOKIE_EXPIRES_DAYS);
            
            // Обновляем локальный список пользователей
            const existingUserIndex = allUsers.findIndex(u => u.id === user.id);
            if (existingUserIndex !== -1) {
                allUsers[existingUserIndex] = user;
            } else {
                allUsers.push(user);
            }
            
            updateUI();
            showNotification(`Добро пожаловать, ${user.username}!`, 'success');
            await navigateTo('/posts');
        } else if (response.status === 404) {
            showNotification('Пользователь не найден', 'error');
        } else if (response.status === 422) {
            try {
                const errorData = await response.json();
                if (errorData.detail && errorData.detail.length > 0) {
                    const errorMessage = errorData.detail[0].msg || 'Ошибка валидации';
                    showNotification(errorMessage, 'error');
                } else {
                    showNotification('Ошибка валидации данных', 'error');
                }
            } catch (parseError) {
                showNotification('Ошибка валидации данных', 'error');
            }
        } else {
            showNotification('Ошибка загрузки пользователя', 'error');
        }
    } catch (error) {
        handleApiError(error, 'при входе в систему');
    }
}

// Получение текста статуса пользователя
function getStatusText(status) {
    const statusTexts = {
        'contemplating_the_void': 'Размышляет о пустоте',
        'pretending_to_work': 'Притворяется, что работает',
        'on_the_verge': 'На грани',
        'running_on_caffeine': 'Работает на кофеине'
    };
    return statusTexts[status] || status;
}

// Отображение постов
function displayPosts() {
    if (allPosts.length === 0) {
        postsList.innerHTML = '<p style="text-align: center; color: #718096; font-style: italic;">Пока нет постов. Будьте первым, кто поделится своим цинизмом!</p>';
        return;
    }

    postsList.innerHTML = allPosts.map(post => {
        const author = allUsers.find(user => user.id === post.owner_id);
        const authorName = author ? author.username : 'Неизвестный автор';
        const createdDate = new Date(post.created_at).toLocaleString('ru-RU');
        
        // Группировка реакций по типам
        const reactions = {};
        post.reactions.forEach(reaction => {
            if (!reactions[reaction.type]) {
                reactions[reaction.type] = 0;
            }
            reactions[reaction.type]++;
        });

        return `
            <div class="post-card" data-post-id="${post.id}">
                <div class="post-header">
                    <div>
                        <h3 class="post-title">${escapeHtml(post.title)}</h3>
                        <div class="post-meta">
                            <div>Автор: ${escapeHtml(authorName)}</div>
                            <div>${createdDate}</div>
                        </div>
                    </div>
                    ${currentUser && currentUser.id === post.owner_id ? `
                        <div class="post-actions">
                            <button class="btn-delete" onclick="deletePost('${post.id}')" title="Удалить пост">
                                🗑️
                            </button>
                        </div>
                    ` : ''}
                </div>
                <div class="post-content">${escapeHtml(post.content)}</div>
                <div class="post-reactions">
                    <button class="reaction-btn" onclick="addReaction('${post.id}', 'sigh')">
                        😮‍💨 Вздох
                        <span class="reaction-count">${reactions.sigh || 0}</span>
                    </button>
                    <button class="reaction-btn" onclick="addReaction('${post.id}', 'facepalm')">
                        🤦 Фейспалм
                        <span class="reaction-count">${reactions.facepalm || 0}</span>
                    </button>
                    <button class="reaction-btn" onclick="addReaction('${post.id}', 'cringe')">
                        😬 Кринж
                        <span class="reaction-count">${reactions.cringe || 0}</span>
                    </button>
                    <button class="reaction-btn" onclick="addReaction('${post.id}', 'seen')">
                        👁️ Просмотрено
                        <span class="reaction-count">${reactions.seen || 0}</span>
                    </button>
                </div>
                <div class="comments-section">
                    <div class="comments-title">Комментарии</div>
                    <div id="comments-${post.id}">
                        <!-- Комментарии будут загружены динамически -->
                    </div>
                    <div style="margin-top: 10px;">
                        <input type="text" id="comment-${post.id}" placeholder="Добавить комментарий..." 
                               style="width: 70%; padding: 8px; border: 1px solid #e2e8f0; border-radius: 5px;">
                        <button onclick="addComment('${post.id}')" 
                                style="margin-left: 10px; padding: 8px 16px; background: #667eea; color: white; border: none; border-radius: 5px; cursor: pointer;">
                            Комментировать
                        </button>
                    </div>
                </div>
            </div>
        `;
    }).join('');

    // Загрузить комментарии для каждого поста
    allPosts.forEach(post => {
        loadComments(post.id);
    });
}

// Загрузка комментариев
async function loadComments(postId) {
    try {
        const response = await fetch(`${API_BASE_URL}/posts/${postId}/comments/`, {
            method: 'GET',
            mode: 'cors',
            headers: {
                'Accept': 'application/json',
            }
        });
        if (response.ok) {
            const comments = await response.json();
            const commentsContainer = document.getElementById(`comments-${postId}`);
            
            if (comments.length === 0) {
                commentsContainer.innerHTML = '<p style="color: #718096; font-style: italic; font-size: 0.9rem;">Пока нет комментариев</p>';
                return;
            }

            commentsContainer.innerHTML = comments.map(comment => {
                const author = allUsers.find(user => user.id === comment.owner_id);
                const authorName = author ? author.username : 'Неизвестный автор';
                const createdDate = new Date(comment.created_at).toLocaleString('ru-RU');
                
                return `
                    <div class="comment">
                        <div class="comment-content">${escapeHtml(comment.content)}</div>
                        <div class="comment-meta">${escapeHtml(authorName)} • ${createdDate}</div>
                    </div>
                `;
            }).join('');
        }
    } catch (error) {
        handleApiError(error, 'при загрузке комментариев');
    }
}

// Обработка входа
async function handleLogin(e) {
    e.preventDefault();
    
    const userId = document.getElementById('loginUserId').value.trim();

    if (!userId) {
        showNotification('Введите ID пользователя', 'error');
        return;
    }

    try {
        // Отправляем GET запрос к конкретному пользователю по ID
        const response = await fetch(`${API_BASE_URL}/users/${userId}`, {
            method: 'GET',
            mode: 'cors',
            headers: {
                'Accept': 'application/json',
            }
        });

        if (response.ok) {
            // Статус 200 - пользователь найден
            const user = await response.json();
            currentUser = user;
            
            // Сохраняем ID пользователя в cookies
            setCookie(COOKIE_USER_ID, user.id, COOKIE_EXPIRES_DAYS);
            
            // Обновляем локальный список пользователей
            const existingUserIndex = allUsers.findIndex(u => u.id === user.id);
            if (existingUserIndex !== -1) {
                allUsers[existingUserIndex] = user;
            } else {
                allUsers.push(user);
            }
            
            updateUI();
            showNotification('Добро пожаловать обратно!', 'success');
            await navigateTo('/posts');
        } else if (response.status === 404) {
            // Статус 404 - пользователь не найден
            showNotification('Пользователь не найден', 'error');
        } else if (response.status === 422) {
            // Статус 422 - ошибка валидации
            try {
                const errorData = await response.json();
                if (errorData.detail && errorData.detail.length > 0) {
                    const errorMessage = errorData.detail[0].msg || 'Ошибка валидации';
                    showNotification(errorMessage, 'error');
                } else {
                    showNotification('Ошибка валидации данных', 'error');
                }
            } catch (parseError) {
                showNotification('Ошибка валидации данных', 'error');
            }
        } else {
            // Другие ошибки
            showNotification('Ошибка сервера. Попробуйте позже.', 'error');
        }
    } catch (error) {
        handleApiError(error, 'при входе в систему');
    }
}

// Обработка регистрации
async function handleRegister(e) {
    e.preventDefault();
    
    const username = document.getElementById('regUsername').value;
    const email = document.getElementById('regEmail').value;
    const password = document.getElementById('regPassword').value;
    
    // Валидация данных
    const userData = { username, email, password };
    const errors = validateUser(userData);
    if (Object.keys(errors).length > 0) {
        Object.values(errors).forEach(error => {
            showNotification(error, 'error');
        });
        return;
    }

    try {
        const response = await fetch(`${API_BASE_URL}/users/`, {
            method: 'POST',
            mode: 'cors',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
            },
            body: JSON.stringify({
                username: username,
                email: email,
                password: password
            })
        });

        if (response.ok) {
            const newUser = await response.json();
            currentUser = newUser;
            
            // Сохраняем ID пользователя в cookies
            setCookie(COOKIE_USER_ID, newUser.id, COOKIE_EXPIRES_DAYS);
            
            allUsers.push(newUser);
            displayUsersList(); // Обновляем список пользователей
            updateUI();
            showNotification('Регистрация успешна! Добро пожаловать в наш циничный круг.', 'success');
            await navigateTo('/posts');
        } else {
            const error = await response.json();
            showNotification(error.detail || 'Ошибка регистрации', 'error');
        }
    } catch (error) {
        handleApiError(error, 'при регистрации');
    }
}

// Обработка создания поста
async function handleCreatePost(e) {
    e.preventDefault();
    
    if (!currentUser) {
        showNotification('Необходимо войти в систему', 'error');
        return;
    }

    const title = document.getElementById('postTitle').value;
    const content = document.getElementById('postContent').value;
    
    // Валидация данных
    const postData = { title, content };
    const errors = validatePost(postData);
    if (Object.keys(errors).length > 0) {
        Object.values(errors).forEach(error => {
            showNotification(error, 'error');
        });
        return;
    }

    try {
        const response = await fetch(`${API_BASE_URL}/posts/?user_id=${currentUser.id}`, {
            method: 'POST',
            mode: 'cors',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
            },
            body: JSON.stringify({
                title: title,
                content: content
            })
        });

        if (response.ok) {
            const newPost = await response.json();
            allPosts.unshift(newPost); // Добавляем в начало списка
            showNotification('Пост создан!', 'success');
            await navigateTo('/posts');
            document.getElementById('createPostFormElement').reset();
        } else {
            const error = await response.json();
            showNotification(error.detail || 'Ошибка создания поста', 'error');
        }
    } catch (error) {
        handleApiError(error, 'при создании поста');
    }
}

// Добавление реакции
async function addReaction(postId, reactionType) {
    if (!currentUser) {
        showNotification('Необходимо войти в систему', 'error');
        return;
    }

    try {
        const response = await fetch(`${API_BASE_URL}/posts/${postId}/react?user_id=${currentUser.id}&reaction_type=${reactionType}`, {
            method: 'POST',
            mode: 'cors',
            headers: {
                'Accept': 'application/json',
            }
        });

        if (response.ok) {
            const updatedPost = await response.json();
            // Обновляем пост в списке
            const postIndex = allPosts.findIndex(p => p.id === postId);
            if (postIndex !== -1) {
                allPosts[postIndex] = updatedPost;
                // Перерисовываем посты только если находимся на странице постов
                if (window.location.pathname === '/posts') {
                    displayPosts();
                }
            }
            showNotification('Реакция добавлена!', 'success');
        } else {
            const error = await response.json();
            showNotification(error.detail || 'Ошибка добавления реакции', 'error');
        }
    } catch (error) {
        handleApiError(error, 'при добавлении реакции');
    }
}

// Добавление комментария
async function addComment(postId) {
    if (!currentUser) {
        showNotification('Необходимо войти в систему', 'error');
        return;
    }

    const commentInput = document.getElementById(`comment-${postId}`);
    const content = commentInput.value.trim();

    // Валидация данных
    const commentData = { content };
    const errors = validateComment(commentData);
    if (Object.keys(errors).length > 0) {
        Object.values(errors).forEach(error => {
            showNotification(error, 'error');
        });
        return;
    }

    try {
        const response = await fetch(`${API_BASE_URL}/posts/${postId}/comments/?user_id=${currentUser.id}`, {
            method: 'POST',
            mode: 'cors',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
            },
            body: JSON.stringify({
                content: content
            })
        });

        if (response.ok) {
            commentInput.value = '';
            loadComments(postId); // Перезагружаем комментарии
            showNotification('Комментарий добавлен!', 'success');
        } else {
            const error = await response.json();
            showNotification(error.detail || 'Ошибка добавления комментария', 'error');
        }
    } catch (error) {
        handleApiError(error, 'при добавлении комментария');
    }
}

// Удаление поста
async function deletePost(postId) {
    if (!currentUser) {
        showNotification('Необходимо войти в систему', 'error');
        return;
    }

    // Подтверждение удаления
    if (!confirm('Вы уверены, что хотите удалить этот пост? Это действие нельзя отменить.')) {
        return;
    }

    try {
        const response = await fetch(`${API_BASE_URL}/posts/${postId}`, {
            method: 'DELETE',
            mode: 'cors',
            headers: {
                'Accept': 'application/json',
            }
        });

        if (response.ok || response.status === 204) {
            // Удаляем пост из локального списка
            allPosts = allPosts.filter(post => post.id !== postId);
            // Перерисовываем посты только если находимся на странице постов
            if (window.location.pathname === '/posts') {
                displayPosts();
            }
            showNotification('Пост удален. Как и ваши надежды на лучшее.', 'success');
        } else {
            const error = await response.json();
            showNotification(error.detail || 'Ошибка удаления поста', 'error');
        }
    } catch (error) {
        handleApiError(error, 'при удалении поста');
    }
}

// Выход из системы
async function logout() {
    // Очищаем cookies
    deleteCookie(COOKIE_USER_ID);
    
    currentUser = null;
    updateUI();
    showNotification('Вы вышли из системы. Сессия завершена.', 'success');
    await navigateTo('/login');
}

// Отображение профиля пользователя
async function displayProfile() {
    // Сначала проверяем куки
    const savedUserId = getCookie(COOKIE_USER_ID);
    if (!savedUserId) {
        showNotification('Необходимо войти в систему', 'error');
        await navigateTo('/login');
        return;
    }

    // Если у нас нет данных о пользователе или ID не совпадает, загружаем из API
    if (!currentUser || currentUser.id !== savedUserId) {
        try {
            const response = await fetch(`${API_BASE_URL}/users/${savedUserId}`, {
                method: 'GET',
                mode: 'cors',
                headers: {
                    'Accept': 'application/json',
                }
            });

            if (response.ok) {
                currentUser = await response.json();
            } else if (response.status === 404) {
                showNotification('Пользователь не найден', 'error');
                deleteCookie(COOKIE_USER_ID);
                await navigateTo('/login');
                return;
            } else {
                showNotification('Ошибка загрузки профиля', 'error');
                return;
            }
        } catch (error) {
            handleApiError(error, 'при загрузке профиля');
            return;
        }
    }

    // Заполняем информацию о пользователе
    document.getElementById('profileUsername').textContent = currentUser.username;
    document.getElementById('profileUserId').textContent = currentUser.id;
    document.getElementById('profileEmail').textContent = currentUser.email;
    document.getElementById('profileActive').textContent = currentUser.is_active ? 'Да' : 'Нет';
    
    // Отображаем статус
    const statusElement = document.getElementById('profileStatus');
    if (currentUser.status) {
        statusElement.textContent = getStatusText(currentUser.status);
        statusElement.className = `profile-status status-${currentUser.status}`;
    } else {
        statusElement.textContent = 'Без статуса';
        statusElement.className = 'profile-status';
    }
    
    // Устанавливаем текущий статус в селекте
    const statusSelect = document.getElementById('statusSelect');
    statusSelect.value = currentUser.status || '';
}

// Обработка обновления статуса
async function handleStatusUpdate(e) {
    e.preventDefault();
    
    if (!currentUser) {
        showNotification('Необходимо войти в систему', 'error');
        return;
    }

    const newStatus = document.getElementById('statusSelect').value;

    try {
        // Формируем URL с query параметром status
        const url = newStatus 
            ? `${API_BASE_URL}/users/${currentUser.id}/status?status=${encodeURIComponent(newStatus)}`
            : `${API_BASE_URL}/users/${currentUser.id}/status`;
            
        const response = await fetch(url, {
            method: 'PUT',
            mode: 'cors',
            headers: {
                'Accept': 'application/json',
            }
        });

        if (response.ok) {
            const updatedUser = await response.json();
            currentUser = updatedUser;
            
            // Обновляем локальный список пользователей
            const existingUserIndex = allUsers.findIndex(u => u.id === updatedUser.id);
            if (existingUserIndex !== -1) {
                allUsers[existingUserIndex] = updatedUser;
            }
            
            // Обновляем отображение профиля
            displayProfile();
            showNotification('Статус успешно обновлен!', 'success');
        } else if (response.status === 404) {
            showNotification('Пользователь не найден', 'error');
        } else if (response.status === 422) {
            try {
                const errorData = await response.json();
                if (errorData.detail && errorData.detail.length > 0) {
                    const errorMessage = errorData.detail[0].msg || 'Ошибка валидации';
                    showNotification(errorMessage, 'error');
                } else {
                    showNotification('Ошибка валидации данных', 'error');
                }
            } catch (parseError) {
                showNotification('Ошибка валидации данных', 'error');
            }
        } else {
            showNotification('Ошибка обновления статуса', 'error');
        }
    } catch (error) {
        handleApiError(error, 'при обновлении статуса');
    }
}

// Обновление интерфейса
function updateUI() {
    if (currentUser) {
        loginBtn.style.display = 'none';
        registerBtn.style.display = 'none';
        postsBtn.style.display = 'inline-block';
        createPostBtn.style.display = 'inline-block';
        profileBtn.style.display = 'inline-block';
        logoutBtn.style.display = 'inline-block';
    } else {
        loginBtn.style.display = 'inline-block';
        registerBtn.style.display = 'inline-block';
        postsBtn.style.display = 'none';
        createPostBtn.style.display = 'none';
        profileBtn.style.display = 'none';
        logoutBtn.style.display = 'none';
    }
}

// Вспомогательные функции
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function getReactionEmoji(type) {
    const emojis = {
        'sigh': '😮‍💨',
        'facepalm': '🤦',
        'cringe': '😬',
        'seen': '👁️'
    };
    return emojis[type] || '❓';
}

function getReactionText(type) {
    const texts = {
        'sigh': 'Вздох',
        'facepalm': 'Фейспалм',
        'cringe': 'Кринж',
        'seen': 'Просмотрено'
    };
    return texts[type] || type;
}

function showNotification(message, type = 'success') {
    // Удаляем существующие уведомления
    const existingNotifications = document.querySelectorAll('.notification');
    existingNotifications.forEach(notification => notification.remove());

    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.textContent = message;
    
    document.body.appendChild(notification);
    
    // Показываем уведомление
    setTimeout(() => notification.classList.add('show'), 100);
    
    // Скрываем через 3 секунды
    setTimeout(() => {
        notification.classList.remove('show');
        setTimeout(() => notification.remove(), 300);
    }, 3000);
}

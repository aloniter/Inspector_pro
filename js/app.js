/**
 * Inspectort Pro - Professional Inspection App
 * Main Application JavaScript
 * RTL Hebrew Support | Mobile-First Design
 */

// App Configuration
const APP_CONFIG = {
    name: 'Inspectort Pro',
    version: '1.0.0',
    defaultLanguage: 'he',
    storagePrefix: 'inspectort_',
    loadingDuration: 1500,
    animationDuration: 300
};

// Storage Keys
const STORAGE_KEYS = {
    user: 'user_data',
    projects: 'projects_data',
    photos: 'photos_data',
    settings: 'app_settings'
};

// App State
let appState = {
    currentUser: null,
    currentProject: null,
    currentPage: 'auth',
    isAuthenticated: false,
    projects: [],
    photos: []
};

// DOM Elements
let elements = {};

/**
 * Initialize the application
 */
function initApp() {
    // Cache DOM elements
    cacheElements();
    
    // Initialize components
    initializeComponents();
    
    // Show loading screen
    showLoadingScreen();
    
    // Load saved data
    loadSavedData();
    
    // Setup event listeners
    setupEventListeners();
    
    // Hide loading screen after initialization
    setTimeout(() => {
        hideLoadingScreen();
        
        // Check authentication state
        if (appState.isAuthenticated) {
            navigateToPage('dashboard');
        } else {
            navigateToPage('auth');
        }
    }, APP_CONFIG.loadingDuration);
}

/**
 * Cache DOM elements for performance
 */
function cacheElements() {
    elements = {
        // App containers
        loading: document.getElementById('loading'),
        app: document.getElementById('app'),
        modalsContainer: document.getElementById('modalsContainer'),
        
        // Pages
        authPage: document.getElementById('authPage'),
        dashboardPage: document.getElementById('dashboardPage'),
        projectPage: document.getElementById('projectPage'),
        
        // Navigation
        menuToggle: document.getElementById('menuToggle'),
        userMenuBtn: document.getElementById('userMenuBtn'),
        
        // Authentication forms
        loginForm: document.getElementById('loginForm'),
        registerForm: document.getElementById('registerForm'),
        showRegister: document.getElementById('showRegister'),
        showLogin: document.getElementById('showLogin'),
        
        // Authentication inputs
        loginEmail: document.getElementById('loginEmail'),
        loginPassword: document.getElementById('loginPassword'),
        registerName: document.getElementById('registerName'),
        registerEmail: document.getElementById('registerEmail'),
        registerPassword: document.getElementById('registerPassword'),
        
        // Dashboard elements
        createProjectBtn: document.getElementById('createProjectBtn'),
        projectsGrid: document.getElementById('projectsGrid'),
        
        // Project elements
        backToDashboard: document.getElementById('backToDashboard'),
        projectTitle: document.getElementById('projectTitle'),
        exportReportBtn: document.getElementById('exportReportBtn'),
        capturePhotoBtn: document.getElementById('capturePhotoBtn'),
        uploadPhotoBtn: document.getElementById('uploadPhotoBtn'),
        photosGrid: document.getElementById('photosGrid')
    };
}

/**
 * Initialize app components
 */
function initializeComponents() {
    // Initialize modal system
    initializeModals();
    
    // Initialize tooltips
    initializeTooltips();
    
    // Initialize responsive behavior
    initializeResponsive();
}

/**
 * Load saved data from localStorage
 */
function loadSavedData() {
    try {
        // Load user data
        const userData = getStorageItem(STORAGE_KEYS.user);
        if (userData) {
            appState.currentUser = userData;
            appState.isAuthenticated = true;
        }
        
        // Load projects
        const projectsData = getStorageItem(STORAGE_KEYS.projects);
        if (projectsData) {
            appState.projects = projectsData;
        }
        
        // Load photos
        const photosData = getStorageItem(STORAGE_KEYS.photos);
        if (photosData) {
            appState.photos = photosData;
        }
        
        console.log('Data loaded successfully');
    } catch (error) {
        console.error('Error loading saved data:', error);
        showNotification('שגיאה בטעינת הנתונים', 'error');
    }
}

/**
 * Setup event listeners
 */
function setupEventListeners() {
    // Authentication events
    if (elements.loginForm) {
        elements.loginForm.addEventListener('submit', handleLogin);
    }
    
    if (elements.registerForm) {
        elements.registerForm.addEventListener('submit', handleRegister);
    }
    
    if (elements.showRegister) {
        elements.showRegister.addEventListener('click', (e) => {
            e.preventDefault();
            toggleAuthForm('register');
        });
    }
    
    if (elements.showLogin) {
        elements.showLogin.addEventListener('click', (e) => {
            e.preventDefault();
            toggleAuthForm('login');
        });
    }
    
    // Navigation events
    if (elements.backToDashboard) {
        elements.backToDashboard.addEventListener('click', () => {
            navigateToPage('dashboard');
        });
    }
    
    if (elements.createProjectBtn) {
        elements.createProjectBtn.addEventListener('click', showCreateProjectModal);
    }
    
    if (elements.userMenuBtn) {
        elements.userMenuBtn.addEventListener('click', showUserMenu);
    }
    
    // Project events
    if (elements.capturePhotoBtn) {
        elements.capturePhotoBtn.addEventListener('click', capturePhoto);
    }
    
    if (elements.uploadPhotoBtn) {
        elements.uploadPhotoBtn.addEventListener('click', uploadPhoto);
    }
    
    if (elements.exportReportBtn) {
        elements.exportReportBtn.addEventListener('click', exportReport);
    }
    
    // Global events
    window.addEventListener('resize', handleResize);
    window.addEventListener('beforeunload', saveAppState);
    document.addEventListener('keydown', handleKeyboardShortcuts);
}

/**
 * Handle login form submission
 */
async function handleLogin(e) {
    e.preventDefault();
    
    // Clear previous errors
    clearFormErrors();
    
    const email = elements.loginEmail.value.trim();
    const password = elements.loginPassword.value;
    
    // Validate inputs
    const validationErrors = validateLoginForm(email, password);
    if (validationErrors.length > 0) {
        showFormErrors(validationErrors);
        return;
    }
    
    // Show loading state
    const submitBtn = e.target.querySelector('button[type="submit"]');
    const originalText = submitBtn.textContent;
    submitBtn.textContent = 'מתחבר...';
    submitBtn.disabled = true;
    
    try {
        // Simulate authentication (replace with real API call)
        const userData = await authenticateUser(email, password);
        
        if (userData) {
            appState.currentUser = userData;
            appState.isAuthenticated = true;
            
            // Save user data
            setStorageItem(STORAGE_KEYS.user, userData);
            
            showNotification(`ברוך הבא, ${userData.name}!`, 'success');
            navigateToPage('dashboard');
        } else {
            showNotification('כתובת אימייל או סיסמה שגויים', 'error');
            highlightFieldError(elements.loginEmail);
            highlightFieldError(elements.loginPassword);
        }
    } catch (error) {
        console.error('Login error:', error);
        showNotification('שגיאה בהתחברות לשרת. אנא נסה שוב.', 'error');
    } finally {
        // Reset button state
        submitBtn.textContent = originalText;
        submitBtn.disabled = false;
    }
}

/**
 * Handle registration form submission
 */
async function handleRegister(e) {
    e.preventDefault();
    
    // Clear previous errors
    clearFormErrors();
    
    const name = elements.registerName.value.trim();
    const email = elements.registerEmail.value.trim();
    const password = elements.registerPassword.value;
    
    // Validate inputs
    const validationErrors = validateRegisterForm(name, email, password);
    if (validationErrors.length > 0) {
        showFormErrors(validationErrors);
        return;
    }
    
    // Show loading state
    const submitBtn = e.target.querySelector('button[type="submit"]');
    const originalText = submitBtn.textContent;
    submitBtn.textContent = 'נרשם...';
    submitBtn.disabled = true;
    
    try {
        // Check if email already exists
        const existingUser = checkEmailExists(email);
        if (existingUser) {
            showNotification('כתובת האימייל כבר קיימת במערכת', 'error');
            highlightFieldError(elements.registerEmail);
            return;
        }
        
        // Simulate registration (replace with real API call)
        const userData = await registerUser(name, email, password);
        
        if (userData) {
            appState.currentUser = userData;
            appState.isAuthenticated = true;
            
            // Save user data
            setStorageItem(STORAGE_KEYS.user, userData);
            
            showNotification(`ברוך הבא, ${userData.name}! נרשמת בהצלחה.`, 'success');
            navigateToPage('dashboard');
        } else {
            showNotification('שגיאה בהרשמה. אנא נסה שוב.', 'error');
        }
    } catch (error) {
        console.error('Registration error:', error);
        showNotification('שגיאה בהרשמה לשרת. אנא נסה שוב.', 'error');
    } finally {
        // Reset button state
        submitBtn.textContent = originalText;
        submitBtn.disabled = false;
    }
}

/**
 * Toggle between login and register forms
 */
function toggleAuthForm(form) {
    if (form === 'register') {
        elements.loginForm.classList.add('hidden');
        elements.registerForm.classList.remove('hidden');
    } else {
        elements.registerForm.classList.add('hidden');
        elements.loginForm.classList.remove('hidden');
    }
}

/**
 * Navigate to a specific page
 */
function navigateToPage(page) {
    // Hide all pages
    document.querySelectorAll('.page').forEach(p => {
        p.classList.remove('active');
    });
    
    // Show target page
    const targetPage = document.getElementById(`${page}Page`);
    if (targetPage) {
        targetPage.classList.add('active');
        appState.currentPage = page;
        
        // Update page content
        updatePageContent(page);
    }
}

/**
 * Update page content based on current page
 */
function updatePageContent(page) {
    switch (page) {
        case 'dashboard':
            updateDashboardContent();
            break;
        case 'project':
            updateProjectContent();
            break;
        case 'auth':
            // Reset forms
            if (elements.loginForm) elements.loginForm.reset();
            if (elements.registerForm) elements.registerForm.reset();
            break;
    }
}

/**
 * Update dashboard content
 */
function updateDashboardContent() {
    const projectsGrid = elements.projectsGrid;
    if (!projectsGrid) return;
    
    // Update user info in header
    updateUserInfo();
    
    // Clear existing content
    projectsGrid.innerHTML = '';
    
    if (appState.projects.length === 0) {
        projectsGrid.innerHTML = `
            <div class="empty-state">
                <div class="empty-icon">📁</div>
                <h3>שלום ${appState.currentUser?.name || 'משתמש'}!</h3>
                <h4>אין עדיין פרויקטים</h4>
                <p>צור פרויקט חדש כדי להתחיל בדיקות</p>
                <button class="btn btn-primary" onclick="showCreateProjectModal()">
                    <span class="btn-icon">+</span>
                    צור פרויקט ראשון
                </button>
            </div>
        `;
    } else {
        // Add welcome message
        const welcomeDiv = document.createElement('div');
        welcomeDiv.className = 'dashboard-welcome';
        welcomeDiv.innerHTML = `
            <h3>שלום ${appState.currentUser?.name}!</h3>
            <p>יש לך ${appState.projects.length} פרויקט${appState.projects.length === 1 ? '' : 'ים'} פעיל${appState.projects.length === 1 ? '' : 'ים'}</p>
        `;
        projectsGrid.appendChild(welcomeDiv);
        
        // Add projects
        appState.projects.forEach(project => {
            const projectCard = createProjectCard(project);
            projectsGrid.appendChild(projectCard);
        });
    }
}

/**
 * Update user info in header
 */
function updateUserInfo() {
    if (appState.currentUser && elements.userMenuBtn) {
        // Update user button to show name initial
        const userIcon = elements.userMenuBtn.querySelector('.user-icon');
        if (userIcon && appState.currentUser.name) {
            const initial = appState.currentUser.name.charAt(0).toUpperCase();
            userIcon.textContent = initial;
            userIcon.style.backgroundColor = 'var(--primary-color)';
            userIcon.style.color = 'white';
            userIcon.style.borderRadius = '50%';
            userIcon.style.width = '32px';
            userIcon.style.height = '32px';
            userIcon.style.display = 'flex';
            userIcon.style.alignItems = 'center';
            userIcon.style.justifyContent = 'center';
            userIcon.style.fontSize = 'var(--font-size-sm)';
            userIcon.style.fontWeight = '600';
        }
        
        // Add tooltip with user name
        elements.userMenuBtn.title = `${appState.currentUser.name} - לחץ לתפריט משתמש`;
    }
}

/**
 * Create project card element
 */
function createProjectCard(project) {
    const card = document.createElement('div');
    card.className = 'project-card';
    card.dataset.projectId = project.id;
    
    const photoCount = appState.photos.filter(photo => photo.projectId === project.id).length;
    const createdDate = new Date(project.createdAt).toLocaleDateString('he-IL');
    
    card.innerHTML = `
        <h3>${project.name}</h3>
        <div class="project-meta">
            <span>נוצר: ${createdDate}</span>
        </div>
        <div class="project-stats">
            <span>📷 ${photoCount} תמונות</span>
            <span>📝 ${project.description ? 'עם תיאור' : 'ללא תיאור'}</span>
        </div>
    `;
    
    card.addEventListener('click', () => {
        appState.currentProject = project;
        navigateToPage('project');
    });
    
    return card;
}

/**
 * Update project content
 */
function updateProjectContent() {
    if (!appState.currentProject) return;
    
    // Update project title
    if (elements.projectTitle) {
        elements.projectTitle.textContent = appState.currentProject.name;
    }
    
    // Update photos grid
    updatePhotosGrid();
}

/**
 * Update photos grid
 */
function updatePhotosGrid() {
    const photosGrid = elements.photosGrid;
    if (!photosGrid) return;
    
    // Clear existing content
    photosGrid.innerHTML = '';
    
    const projectPhotos = appState.photos.filter(photo => 
        photo.projectId === appState.currentProject.id
    );
    
    if (projectPhotos.length === 0) {
        photosGrid.innerHTML = `
            <div class="empty-state">
                <div class="empty-icon">📷</div>
                <h3>אין עדיין תמונות</h3>
                <p>צלם או העלה תמונות כדי להתחיל</p>
            </div>
        `;
    } else {
        projectPhotos.forEach(photo => {
            const photoCard = createPhotoCard(photo);
            photosGrid.appendChild(photoCard);
        });
    }
}

/**
 * Create photo card element
 */
function createPhotoCard(photo) {
    const card = document.createElement('div');
    card.className = 'photo-card';
    card.dataset.photoId = photo.id;
    
    card.innerHTML = `
        <img src="${photo.url}" alt="${photo.name}">
        <div class="photo-info">
            <h4>${photo.name}</h4>
            <p>${photo.description || 'ללא תיאור'}</p>
        </div>
    `;
    
    card.addEventListener('click', () => {
        // Open photo annotation modal
        openPhotoAnnotation(photo);
    });
    
    return card;
}

/**
 * Show/hide loading screen
 */
function showLoadingScreen() {
    if (elements.loading) {
        elements.loading.classList.remove('hidden');
    }
    if (elements.app) {
        elements.app.classList.add('hidden');
    }
}

function hideLoadingScreen() {
    if (elements.loading) {
        elements.loading.classList.add('hidden');
    }
    if (elements.app) {
        elements.app.classList.remove('hidden');
    }
}

/**
 * Show notification
 */
function showNotification(message, type = 'info', duration = 3000) {
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.textContent = message;
    
    // Add notification styles
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        padding: 15px 20px;
        border-radius: 8px;
        color: white;
        font-weight: 500;
        z-index: 10000;
        animation: slideInRight 0.3s ease-out;
        max-width: 300px;
        box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    `;
    
    // Set background color based on type
    const colors = {
        success: '#10b981',
        error: '#ef4444',
        warning: '#f59e0b',
        info: '#3b82f6'
    };
    
    notification.style.backgroundColor = colors[type] || colors.info;
    
    document.body.appendChild(notification);
    
    // Remove notification after duration
    setTimeout(() => {
        notification.style.animation = 'slideOutRight 0.3s ease-in';
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }
        }, 300);
    }, duration);
}

/**
 * Authentication functions (mock implementation)
 */
async function authenticateUser(email, password) {
    // Mock authentication - replace with real API call
    await new Promise(resolve => setTimeout(resolve, 500));
    
    // Check credentials against saved users
    const allUsers = getStorageItem('all_users') || [];
    const user = allUsers.find(u => u.email.toLowerCase() === email.toLowerCase());
    
    if (user) {
        // In a real app, you'd verify the password hash here
        // For demo purposes, we'll accept any password for existing users
        return {
            ...user,
            lastLogin: new Date().toISOString()
        };
    }
    
    // For demo purposes, create a new user if email/password is provided
    if (email && password) {
        return {
            id: Date.now().toString(),
            name: 'משתמש לדוגמה',
            email: email,
            createdAt: new Date().toISOString(),
            lastLogin: new Date().toISOString()
        };
    }
    
    return null;
}

async function registerUser(name, email, password) {
    // Mock registration - replace with real API call
    await new Promise(resolve => setTimeout(resolve, 500));
    
    const userData = {
        id: Date.now().toString(),
        name: name,
        email: email,
        createdAt: new Date().toISOString(),
        lastLogin: new Date().toISOString()
    };
    
    // Save user to all users list
    const allUsers = getStorageItem('all_users') || [];
    allUsers.push(userData);
    setStorageItem('all_users', allUsers);
    
    return userData;
}

/**
 * Form validation functions
 */
function validateLoginForm(email, password) {
    const errors = [];
    
    if (!email.trim()) {
        errors.push({
            field: 'email',
            message: 'כתובת אימייל נדרשת'
        });
    } else if (!isValidEmail(email)) {
        errors.push({
            field: 'email',
            message: 'כתובת אימייל לא תקינה'
        });
    }
    
    if (!password) {
        errors.push({
            field: 'password',
            message: 'סיסמה נדרשת'
        });
    }
    
    return errors;
}

function validateRegisterForm(name, email, password) {
    const errors = [];
    
    if (!name.trim()) {
        errors.push({
            field: 'name',
            message: 'שם מלא נדרש'
        });
    } else if (name.trim().length < 2) {
        errors.push({
            field: 'name',
            message: 'השם חייב להכיל לפחות 2 תווים'
        });
    }
    
    if (!email.trim()) {
        errors.push({
            field: 'email',
            message: 'כתובת אימייל נדרשת'
        });
    } else if (!isValidEmail(email)) {
        errors.push({
            field: 'email',
            message: 'כתובת אימייל לא תקינה'
        });
    }
    
    if (!password) {
        errors.push({
            field: 'password',
            message: 'סיסמה נדרשת'
        });
    } else if (password.length < 6) {
        errors.push({
            field: 'password',
            message: 'הסיסמה חייבת להכיל לפחות 6 תווים'
        });
    } else if (!isValidPassword(password)) {
        errors.push({
            field: 'password',
            message: 'הסיסמה חייבת להכיל לפחות אות אחת ומספר אחד'
        });
    }
    
    return errors;
}

function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

function isValidPassword(password) {
    // Password must contain at least one letter and one number
    const passwordRegex = /^(?=.*[A-Za-z])(?=.*\d).{6,}$/;
    return passwordRegex.test(password);
}

function checkEmailExists(email) {
    // Check if email already exists in localStorage
    const users = getStorageItem('all_users') || [];
    return users.find(user => user.email.toLowerCase() === email.toLowerCase());
}

/**
 * Form error handling
 */
function clearFormErrors() {
    // Remove error styling from all form fields
    document.querySelectorAll('.form-group input, .form-group textarea').forEach(field => {
        field.classList.remove('error');
        const errorMsg = field.parentNode.querySelector('.error-message');
        if (errorMsg) {
            errorMsg.remove();
        }
    });
}

function showFormErrors(errors) {
    errors.forEach(error => {
        const fieldName = error.field;
        let fieldElement;
        
        // Map field names to elements
        switch (fieldName) {
            case 'name':
                fieldElement = elements.registerName;
                break;
            case 'email':
                fieldElement = appState.currentPage === 'auth' ? 
                    (elements.loginForm.classList.contains('hidden') ? elements.registerEmail : elements.loginEmail) :
                    elements.loginEmail;
                break;
            case 'password':
                fieldElement = appState.currentPage === 'auth' ? 
                    (elements.loginForm.classList.contains('hidden') ? elements.registerPassword : elements.loginPassword) :
                    elements.loginPassword;
                break;
        }
        
        if (fieldElement) {
            highlightFieldError(fieldElement);
            showFieldError(fieldElement, error.message);
        }
    });
    
    // Show first error as notification
    if (errors.length > 0) {
        showNotification(errors[0].message, 'error');
    }
}

function highlightFieldError(fieldElement) {
    fieldElement.classList.add('error');
    
    // Remove error styling after 5 seconds
    setTimeout(() => {
        fieldElement.classList.remove('error');
    }, 5000);
}

function showFieldError(fieldElement, message) {
    // Remove existing error message
    const existingError = fieldElement.parentNode.querySelector('.error-message');
    if (existingError) {
        existingError.remove();
    }
    
    // Create new error message
    const errorElement = document.createElement('div');
    errorElement.className = 'error-message';
    errorElement.textContent = message;
    fieldElement.parentNode.appendChild(errorElement);
    
    // Remove error message after 5 seconds
    setTimeout(() => {
        if (errorElement.parentNode) {
            errorElement.parentNode.removeChild(errorElement);
        }
    }, 5000);
}

/**
 * Storage utilities
 */
function getStorageItem(key) {
    try {
        const item = localStorage.getItem(APP_CONFIG.storagePrefix + key);
        return item ? JSON.parse(item) : null;
    } catch (error) {
        console.error('Error getting storage item:', error);
        return null;
    }
}

function setStorageItem(key, value) {
    try {
        localStorage.setItem(APP_CONFIG.storagePrefix + key, JSON.stringify(value));
    } catch (error) {
        console.error('Error setting storage item:', error);
    }
}

/**
 * Placeholder functions for future implementation
 */
function initializeModals() {
    // Modal system initialization
    console.log('Modal system initialized');
    
    // Close modals when clicking outside
    document.addEventListener('click', (e) => {
        if (e.target.classList.contains('modal-overlay')) {
            closeModal(e.target);
        }
    });
    
    // Close modals with Escape key
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            const activeModal = document.querySelector('.modal-overlay.active');
            if (activeModal) {
                closeModal(activeModal);
            }
        }
    });
}

/**
 * Create modal element
 */
function createModal(title, content, buttons = []) {
    const modal = document.createElement('div');
    modal.className = 'modal-overlay';
    
    const buttonsHtml = buttons.map(btn => 
        `<button class="btn ${btn.class || 'btn-primary'}" onclick="${btn.action === 'close' ? 'closeModal(this.closest(\'.modal-overlay\'))' : btn.action}">${btn.text}</button>`
    ).join('');
    
    modal.innerHTML = `
        <div class="modal-content">
            <div class="modal-header">
                <h3 class="modal-title">${title}</h3>
                <button class="modal-close" onclick="closeModal(this.closest('.modal-overlay'))">&times;</button>
            </div>
            <div class="modal-body">
                ${content}
            </div>
            ${buttons.length > 0 ? `<div class="modal-buttons">${buttonsHtml}</div>` : ''}
        </div>
    `;
    
    return modal;
}

/**
 * Show modal
 */
function showModal(modal) {
    elements.modalsContainer.appendChild(modal);
    
    // Trigger animation
    setTimeout(() => {
        modal.classList.add('active');
    }, 10);
}

/**
 * Close modal
 */
function closeModal(modal) {
    modal.classList.remove('active');
    
    setTimeout(() => {
        if (modal.parentNode) {
            modal.parentNode.removeChild(modal);
        }
    }, 300);
}

function initializeTooltips() {
    // Tooltip system initialization
    console.log('Tooltip system initialized');
}

function initializeResponsive() {
    // Responsive behavior initialization
    console.log('Responsive behavior initialized');
}

function showCreateProjectModal() {
    // TODO: Implement create project modal
    console.log('Create project modal');
}

function showUserMenu() {
    // Create user menu modal
    const modal = createModal('תפריט משתמש', '', [
        {
            text: 'סגור',
            class: 'btn-secondary',
            action: 'close'
        }
    ]);
    
    // Add user menu content
    const userInfo = document.createElement('div');
    userInfo.className = 'user-menu-content';
    userInfo.innerHTML = `
        <div class="user-profile">
            <div class="user-avatar">
                ${appState.currentUser?.name?.charAt(0)?.toUpperCase() || 'U'}
            </div>
            <div class="user-details">
                <h3>${appState.currentUser?.name || 'משתמש'}</h3>
                <p>${appState.currentUser?.email || ''}</p>
                <small>נרשם: ${appState.currentUser?.createdAt ? new Date(appState.currentUser.createdAt).toLocaleDateString('he-IL') : ''}</small>
            </div>
        </div>
        
        <div class="user-stats">
            <div class="stat-item">
                <span class="stat-value">${appState.projects.length}</span>
                <span class="stat-label">פרויקטים</span>
            </div>
            <div class="stat-item">
                <span class="stat-value">${appState.photos.length}</span>
                <span class="stat-label">תמונות</span>
            </div>
        </div>
        
        <div class="user-actions">
            <button class="btn btn-outline" onclick="editProfile()">
                <span class="btn-icon">✏️</span>
                ערוך פרופיל
            </button>
            <button class="btn btn-secondary" onclick="exportUserData()">
                <span class="btn-icon">📁</span>
                יצוא נתונים
            </button>
            <button class="btn btn-danger" onclick="logout()">
                <span class="btn-icon">🚪</span>
                התנתק
            </button>
        </div>
    `;
    
    // Insert content before buttons
    const modalBody = modal.querySelector('.modal-content');
    const buttonContainer = modalBody.querySelector('.modal-buttons');
    modalBody.insertBefore(userInfo, buttonContainer);
    
    showModal(modal);
}

function capturePhoto() {
    // TODO: Implement photo capture
    console.log('Capture photo');
}

function uploadPhoto() {
    // TODO: Implement photo upload
    console.log('Upload photo');
}

function exportReport() {
    // TODO: Implement report export
    console.log('Export report');
}

function openPhotoAnnotation(photo) {
    // TODO: Implement photo annotation
    console.log('Open photo annotation for:', photo.name);
}

function handleResize() {
    // Handle window resize
    console.log('Window resized');
}

function handleKeyboardShortcuts(e) {
    // Handle keyboard shortcuts
    if (e.ctrlKey || e.metaKey) {
        switch (e.key) {
            case 'n':
                e.preventDefault();
                if (appState.currentPage === 'dashboard') {
                    showCreateProjectModal();
                }
                break;
        }
    }
}

function saveAppState() {
    // Save app state before unload
    setStorageItem(STORAGE_KEYS.projects, appState.projects);
    setStorageItem(STORAGE_KEYS.photos, appState.photos);
}

/**
 * User management functions
 */
function logout() {
    const modal = createModal(
        'התנתקות', 
        'האם אתה בטוח שברצונך להתנתק?',
        [
            {
                text: 'ביטול',
                class: 'btn-secondary',
                action: 'closeModal(this.closest(\'.modal-overlay\'))'
            },
            {
                text: 'התנתק',
                class: 'btn-danger',
                action: 'confirmLogout()'
            }
        ]
    );
    
    showModal(modal);
}

function confirmLogout() {
    // Clear user data
    appState.currentUser = null;
    appState.isAuthenticated = false;
    appState.currentProject = null;
    
    // Clear stored user data
    localStorage.removeItem(APP_CONFIG.storagePrefix + STORAGE_KEYS.user);
    
    // Close any open modals
    document.querySelectorAll('.modal-overlay').forEach(modal => {
        closeModal(modal);
    });
    
    // Show notification and redirect
    showNotification('התנתקת בהצלחה', 'info');
    navigateToPage('auth');
}

function editProfile() {
    showNotification('תכונה זו תהיה זמינה בקרוב', 'info');
    // TODO: Implement profile editing
}

function exportUserData() {
    try {
        const userData = {
            user: appState.currentUser,
            projects: appState.projects,
            photos: appState.photos,
            exportDate: new Date().toISOString()
        };
        
        const dataStr = JSON.stringify(userData, null, 2);
        const dataBlob = new Blob([dataStr], {type: 'application/json'});
        
        const link = document.createElement('a');
        link.href = URL.createObjectURL(dataBlob);
        link.download = `inspectort-backup-${new Date().toISOString().split('T')[0]}.json`;
        link.click();
        
        showNotification('הנתונים יוצאו בהצלחה', 'success');
    } catch (error) {
        console.error('Export error:', error);
        showNotification('שגיאה ביצוא הנתונים', 'error');
    }
}

// Add CSS animations for notifications
const style = document.createElement('style');
style.textContent = `
    @keyframes slideInRight {
        from {
            transform: translateX(100%);
            opacity: 0;
        }
        to {
            transform: translateX(0);
            opacity: 1;
        }
    }
    
    @keyframes slideOutRight {
        from {
            transform: translateX(0);
            opacity: 1;
        }
        to {
            transform: translateX(100%);
            opacity: 0;
        }
    }
`;
document.head.appendChild(style);

// Initialize app when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initApp);
} else {
    initApp();
} 
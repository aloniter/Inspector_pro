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
    
    const email = elements.loginEmail.value.trim();
    const password = elements.loginPassword.value;
    
    if (!email || !password) {
        showNotification('אנא מלא את כל השדות', 'error');
        return;
    }
    
    try {
        // Simulate authentication (replace with real API call)
        const userData = await authenticateUser(email, password);
        
        if (userData) {
            appState.currentUser = userData;
            appState.isAuthenticated = true;
            
            // Save user data
            setStorageItem(STORAGE_KEYS.user, userData);
            
            showNotification('התחברת בהצלחה!', 'success');
            navigateToPage('dashboard');
        } else {
            showNotification('פרטי התחברות שגויים', 'error');
        }
    } catch (error) {
        console.error('Login error:', error);
        showNotification('שגיאה בהתחברות', 'error');
    }
}

/**
 * Handle registration form submission
 */
async function handleRegister(e) {
    e.preventDefault();
    
    const name = elements.registerName.value.trim();
    const email = elements.registerEmail.value.trim();
    const password = elements.registerPassword.value;
    
    if (!name || !email || !password) {
        showNotification('אנא מלא את כל השדות', 'error');
        return;
    }
    
    if (password.length < 6) {
        showNotification('הסיסמה חייבת להכיל לפחות 6 תווים', 'error');
        return;
    }
    
    try {
        // Simulate registration (replace with real API call)
        const userData = await registerUser(name, email, password);
        
        if (userData) {
            appState.currentUser = userData;
            appState.isAuthenticated = true;
            
            // Save user data
            setStorageItem(STORAGE_KEYS.user, userData);
            
            showNotification('נרשמת בהצלחה!', 'success');
            navigateToPage('dashboard');
        } else {
            showNotification('שגיאה בהרשמה', 'error');
        }
    } catch (error) {
        console.error('Registration error:', error);
        showNotification('שגיאה בהרשמה', 'error');
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
    
    // Clear existing content
    projectsGrid.innerHTML = '';
    
    if (appState.projects.length === 0) {
        projectsGrid.innerHTML = `
            <div class="empty-state">
                <div class="empty-icon">📁</div>
                <h3>אין עדיין פרויקטים</h3>
                <p>צור פרויקט חדש כדי להתחיל</p>
            </div>
        `;
    } else {
        appState.projects.forEach(project => {
            const projectCard = createProjectCard(project);
            projectsGrid.appendChild(projectCard);
        });
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
    
    // For demo purposes, accept any email/password
    return {
        id: Date.now().toString(),
        name: 'משתמש לדוגמה',
        email: email,
        createdAt: new Date().toISOString()
    };
}

async function registerUser(name, email, password) {
    // Mock registration - replace with real API call
    await new Promise(resolve => setTimeout(resolve, 500));
    
    return {
        id: Date.now().toString(),
        name: name,
        email: email,
        createdAt: new Date().toISOString()
    };
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
    // TODO: Implement user menu
    console.log('User menu');
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
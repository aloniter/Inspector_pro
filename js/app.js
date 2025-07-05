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
            
            // Load user's projects from new storage system
            const userProjects = getAllProjects();
            appState.projects = userProjects;
            
            // Load user's photos from new storage system
            const userPhotos = getAllPhotos();
            appState.photos = userPhotos;
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
    
    const photoCount = project.totalPhotos || 0;
    const createdDate = new Date(project.createdAt).toLocaleDateString('he-IL');
    const updatedDate = new Date(project.updatedAt).toLocaleDateString('he-IL');
    
    // Format project type
    const typeLabels = {
        'safety': 'בטיחות',
        'quality': 'איכות',
        'maintenance': 'תחזוקה',
        'compliance': 'ציות',
        'inspection': 'בדיקה כללית',
        'other': 'אחר'
    };
    
    const typeLabel = typeLabels[project.type] || 'בדיקה כללית';
    
    // Format deadline
    let deadlineHtml = '';
    if (project.deadline) {
        const deadlineDate = new Date(project.deadline);
        const today = new Date();
        const timeDiff = deadlineDate - today;
        const daysDiff = Math.ceil(timeDiff / (1000 * 60 * 60 * 24));
        
        let deadlineClass = 'project-deadline';
        if (daysDiff < 0) {
            deadlineClass += ' overdue';
        } else if (daysDiff <= 7) {
            deadlineClass += ' due-soon';
        }
        
        deadlineHtml = `
            <div class="${deadlineClass}">
                ⏰ יעד: ${deadlineDate.toLocaleDateString('he-IL')}
            </div>
        `;
    }
    
    card.innerHTML = `
        <div class="project-actions-menu">
            <button class="project-menu-btn" onclick="showProjectMenu(event, '${project.id}')">
                ⋮
            </button>
        </div>
        
        <div class="project-type">${typeLabel}</div>
        
        <h3>${project.name}</h3>
        
        ${project.description ? `<p class="project-description">${project.description}</p>` : ''}
        
        <div class="project-meta">
            <span>📅 נוצר: ${createdDate}</span>
            ${updatedDate !== createdDate ? `<span>📝 עודכן: ${updatedDate}</span>` : ''}
            ${project.location ? `<span>📍 ${project.location}</span>` : ''}
            ${project.client ? `<span>🏢 ${project.client}</span>` : ''}
        </div>
        
        <div class="project-stats">
            <span>📷 ${photoCount} תמונות</span>
            <span>📊 ${project.annotatedPhotos || 0} מוכנות</span>
            <span>🎯 ${project.completionPercentage || 0}%</span>
        </div>
        
        ${deadlineHtml}
    `;
    
    // Add click handler for the card (except for the menu button)
    card.addEventListener('click', (e) => {
        if (!e.target.closest('.project-actions-menu')) {
            appState.currentProject = project;
            navigateToPage('project');
        }
    });
    
    return card;
}

function showProjectMenu(event, projectId) {
    event.stopPropagation();
    
    const project = getProjectById(projectId);
    if (!project) return;
    
    const menuContent = `
        <div class="project-menu-actions">
            <button class="menu-action" onclick="editProject('${projectId}')">
                <span class="menu-icon">✏️</span>
                ערוך פרויקט
            </button>
            <button class="menu-action" onclick="duplicateProject('${projectId}')">
                <span class="menu-icon">📋</span>
                שכפל פרויקט
            </button>
            <button class="menu-action" onclick="exportProject('${projectId}')">
                <span class="menu-icon">📤</span>
                יצוא פרויקט
            </button>
            <button class="menu-action menu-action-danger" onclick="confirmDeleteProject('${projectId}')">
                <span class="menu-icon">🗑️</span>
                מחק פרויקט
            </button>
        </div>
    `;

    const modal = createModal(
        project.name,
        menuContent,
        [
            {
                text: 'סגור',
                class: 'btn-secondary',
                action: 'closeModal(this.closest(\'.modal-overlay\'))'
            }
        ]
    );

    showModal(modal);
}

function editProject(projectId) {
    const project = getProjectById(projectId);
    if (!project) return;
    
    const modalContent = `
        <form id="editProjectForm" class="project-form">
            <div class="form-group">
                <label for="editProjectName">שם הפרויקט *</label>
                <input type="text" id="editProjectName" name="projectName" required maxlength="100" 
                       value="${project.name}" placeholder="שם הפרויקט">
            </div>
            
            <div class="form-group">
                <label for="editProjectDescription">תיאור הפרויקט</label>
                <textarea id="editProjectDescription" name="projectDescription" rows="4" maxlength="500"
                          placeholder="תיאור קצר של הפרויקט...">${project.description || ''}</textarea>
            </div>
            
            <div class="form-row">
                <div class="form-group">
                    <label for="editProjectLocation">מיקום</label>
                    <input type="text" id="editProjectLocation" name="projectLocation" maxlength="200"
                           value="${project.location || ''}" placeholder="כתובת או מיקום">
                </div>
                
                <div class="form-group">
                    <label for="editProjectType">סוג בדיקה</label>
                    <select id="editProjectType" name="projectType">
                        <option value="">בחר סוג בדיקה</option>
                        <option value="safety" ${project.type === 'safety' ? 'selected' : ''}>בדיקת בטיחות</option>
                        <option value="quality" ${project.type === 'quality' ? 'selected' : ''}>בדיקת איכות</option>
                        <option value="maintenance" ${project.type === 'maintenance' ? 'selected' : ''}>בדיקת תחזוקה</option>
                        <option value="compliance" ${project.type === 'compliance' ? 'selected' : ''}>בדיקת ציות</option>
                        <option value="inspection" ${project.type === 'inspection' ? 'selected' : ''}>בדיקה כללית</option>
                        <option value="other" ${project.type === 'other' ? 'selected' : ''}>אחר</option>
                    </select>
                </div>
            </div>
            
            <div class="form-row">
                <div class="form-group">
                    <label for="editProjectClient">לקוח</label>
                    <input type="text" id="editProjectClient" name="projectClient" maxlength="100"
                           value="${project.client || ''}" placeholder="שם הלקוח">
                </div>
                
                <div class="form-group">
                    <label for="editProjectDeadline">תאריך יעד</label>
                    <input type="date" id="editProjectDeadline" name="projectDeadline"
                           value="${project.deadline || ''}">
                </div>
            </div>
            
            <div class="form-group">
                <label for="editProjectNotes">הערות נוספות</label>
                <textarea id="editProjectNotes" name="projectNotes" rows="3" maxlength="300"
                          placeholder="הערות נוספות...">${project.notes || ''}</textarea>
            </div>
        </form>
    `;

    const modal = createModal(
        'ערוך פרויקט',
        modalContent,
        [
            {
                text: 'ביטול',
                class: 'btn-secondary',
                action: 'closeModal(this.closest(\'.modal-overlay\'))'
            },
            {
                text: 'שמור שינויים',
                class: 'btn-primary',
                action: `handleEditProject('${projectId}')`
            }
        ]
    );

    showModal(modal);
}

function handleEditProject(projectId) {
    const form = document.getElementById('editProjectForm');
    const formData = new FormData(form);
    
    const projectName = formData.get('projectName').trim();
    if (!projectName) {
        showNotification('שם הפרויקט הוא שדה חובה', 'error');
        return;
    }
    
    const updates = {
        name: projectName,
        description: formData.get('projectDescription').trim(),
        location: formData.get('projectLocation').trim(),
        type: formData.get('projectType'),
        client: formData.get('projectClient').trim(),
        deadline: formData.get('projectDeadline'),
        notes: formData.get('projectNotes').trim()
    };
    
    const updatedProject = updateProject(projectId, updates);
    
    if (updatedProject) {
        closeModal(document.querySelector('.modal-overlay'));
        showNotification('הפרויקט עודכן בהצלחה!', 'success');
        renderProjects();
    }
}

function duplicateProject(projectId) {
    const project = getProjectById(projectId);
    if (!project) return;
    
    const duplicatedProject = {
        name: project.name + ' (עותק)',
        description: project.description,
        location: project.location,
        type: project.type,
        client: project.client,
        deadline: project.deadline,
        notes: project.notes
    };
    
    const newProject = createProject(duplicatedProject);
    
    if (newProject) {
        closeModal(document.querySelector('.modal-overlay'));
        showNotification('הפרויקט שוכפל בהצלחה!', 'success');
        renderProjects();
    }
}

function exportProject(projectId) {
    const project = getProjectById(projectId);
    if (!project) return;
    
    try {
        const projectData = {
            project: project,
            photos: project.photos || [],
            exportDate: new Date().toISOString()
        };
        
        const dataStr = JSON.stringify(projectData, null, 2);
        const dataBlob = new Blob([dataStr], {type: 'application/json'});
        
        const link = document.createElement('a');
        link.href = URL.createObjectURL(dataBlob);
        link.download = `${project.name}-${new Date().toISOString().split('T')[0]}.json`;
        link.click();
        
        closeModal(document.querySelector('.modal-overlay'));
        showNotification('הפרויקט יוצא בהצלחה', 'success');
    } catch (error) {
        console.error('Export error:', error);
        showNotification('שגיאה ביצוא הפרויקט', 'error');
    }
}

function confirmDeleteProject(projectId) {
    const project = getProjectById(projectId);
    if (!project) return;
    
    const modal = createModal(
        'מחק פרויקט',
        `<p>האם אתה בטוח שברצונך למחוק את הפרויקט "<strong>${project.name}</strong>"?</p>
         <p class="text-danger">פעולה זו לא ניתנת לביטול!</p>`,
        [
            {
                text: 'ביטול',
                class: 'btn-secondary',
                action: 'closeModal(this.closest(\'.modal-overlay\'))'
            },
            {
                text: 'מחק',
                class: 'btn-danger',
                action: `handleDeleteProject('${projectId}')`
            }
        ]
    );

    showModal(modal);
}

function handleDeleteProject(projectId) {
    const success = deleteProject(projectId);
    
    if (success) {
        closeModal(document.querySelector('.modal-overlay'));
        showNotification('הפרויקט נמחק בהצלחה', 'success');
        renderProjects();
        updateUserStats();
    }
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
    
    const projectPhotos = getPhotosByProject(appState.currentProject.id);
    
    if (projectPhotos.length === 0) {
        photosGrid.innerHTML = `
            <div class="empty-state">
                <div class="empty-icon">📷</div>
                <h3>אין עדיין תמונות</h3>
                <p>צלם או העלה תמונות כדי להתחיל</p>
                <button class="btn btn-primary" onclick="capturePhoto()">
                    <span class="btn-icon">📸</span>
                    צלם תמונה
                </button>
                <button class="btn btn-secondary" onclick="uploadPhoto()">
                    <span class="btn-icon">📁</span>
                    העלה תמונות
                </button>
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
    
    const createdDate = new Date(photo.createdAt).toLocaleDateString('he-IL');
    const fileSize = formatFileSize(photo.size);
    
    card.innerHTML = `
        <div class="photo-actions-menu">
            <button class="photo-menu-btn" onclick="showPhotoMenu(event, '${photo.id}')">
                ⋮
            </button>
        </div>
        
        <div class="photo-image-container">
            <img src="${photo.url}" alt="${photo.name}" loading="lazy">
            ${photo.isAnnotated ? '<div class="photo-annotation-indicator">✏️</div>' : ''}
        </div>
        
        <div class="photo-info">
            <h4>${photo.name || 'ללא שם'}</h4>
            <div class="photo-meta">
                <span class="photo-date">📅 ${createdDate}</span>
                <span class="photo-size">📏 ${fileSize}</span>
            </div>
        </div>
    `;
    
    // Add click handler for the card (except for the menu button)
    card.addEventListener('click', (e) => {
        if (!e.target.closest('.photo-actions-menu')) {
            // Open photo annotation modal
            openPhotoAnnotation(photo);
        }
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
    const modalContent = `
        <form id="createProjectForm" class="project-form">
            <div class="form-group">
                <label for="projectName">שם הפרויקט *</label>
                <input type="text" id="projectName" name="projectName" required maxlength="100" 
                       placeholder="לדוגמה: בדיקת בטיחות בניין מספר 5">
            </div>
            
            <div class="form-group">
                <label for="projectDescription">תיאור הפרויקט</label>
                <textarea id="projectDescription" name="projectDescription" rows="4" maxlength="500"
                          placeholder="תיאור קצר של הפרויקט ומטרתו..."></textarea>
            </div>
            
            <div class="form-row">
                <div class="form-group">
                    <label for="projectLocation">מיקום</label>
                    <input type="text" id="projectLocation" name="projectLocation" maxlength="200"
                           placeholder="כתובת או מיקום הבדיקה">
                </div>
                
                <div class="form-group">
                    <label for="projectType">סוג בדיקה</label>
                    <select id="projectType" name="projectType">
                        <option value="">בחר סוג בדיקה</option>
                        <option value="safety">בדיקת בטיחות</option>
                        <option value="quality">בדיקת איכות</option>
                        <option value="maintenance">בדיקת תחזוקה</option>
                        <option value="compliance">בדיקת ציות</option>
                        <option value="inspection">בדיקה כללית</option>
                        <option value="other">אחר</option>
                    </select>
                </div>
            </div>
            
            <div class="form-row">
                <div class="form-group">
                    <label for="projectClient">לקוח</label>
                    <input type="text" id="projectClient" name="projectClient" maxlength="100"
                           placeholder="שם הלקוח או הארגון">
                </div>
                
                <div class="form-group">
                    <label for="projectDeadline">תאריך יעד</label>
                    <input type="date" id="projectDeadline" name="projectDeadline">
                </div>
            </div>
            
            <div class="form-group">
                <label for="projectNotes">הערות נוספות</label>
                <textarea id="projectNotes" name="projectNotes" rows="3" maxlength="300"
                          placeholder="הערות, דרישות מיוחדות או מידע נוסף..."></textarea>
            </div>
        </form>
    `;

    const modal = createModal(
        'צור פרויקט חדש',
        modalContent,
        [
            {
                text: 'ביטול',
                class: 'btn-secondary',
                action: 'closeModal(this.closest(\'.modal-overlay\'))'
            },
            {
                text: 'צור פרויקט',
                class: 'btn-primary',
                action: 'handleCreateProject()'
            }
        ]
    );

    showModal(modal);
    
    // Focus on project name field
    setTimeout(() => {
        const nameField = document.getElementById('projectName');
        if (nameField) nameField.focus();
    }, 100);
}

// Handle project creation from modal
function handleCreateProject() {
    const form = document.getElementById('createProjectForm');
    const formData = new FormData(form);
    
    // Validate required fields
    const projectName = formData.get('projectName').trim();
    if (!projectName) {
        showNotification('שם הפרויקט הוא שדה חובה', 'error');
        return;
    }
    
    // Create project object
    const projectData = {
        name: projectName,
        description: formData.get('projectDescription').trim(),
        location: formData.get('projectLocation').trim(),
        type: formData.get('projectType'),
        client: formData.get('projectClient').trim(),
        deadline: formData.get('projectDeadline'),
        notes: formData.get('projectNotes').trim()
    };
    
    // Create the project
    const newProject = createProject(projectData);
    
    if (newProject) {
        // Close modal and refresh dashboard
        closeModal(document.querySelector('.modal-overlay'));
        showNotification('הפרויקט נוצר בהצלחה!', 'success');
        renderProjects();
        
        // Update statistics
        updateUserStats();
    }
}

function createProject(projectData) {
    try {
        const currentUser = getCurrentUser();
        if (!currentUser) {
            throw new Error('משתמש לא מחובר');
        }

        const projectId = generateId();
        const now = new Date().toISOString();
        
        const project = {
            id: projectId,
            name: projectData.name,
            description: projectData.description || '',
            location: projectData.location || '',
            type: projectData.type || 'inspection',
            client: projectData.client || '',
            deadline: projectData.deadline || null,
            notes: projectData.notes || '',
            createdAt: now,
            updatedAt: now,
            createdBy: currentUser.id,
            status: 'active',
            photos: [],
            totalPhotos: 0,
            annotatedPhotos: 0,
            completionPercentage: 0
        };

        // Save project to storage
        const projects = getAllProjects();
        projects.push(project);
        localStorage.setItem('inspectort_projects', JSON.stringify(projects));

        // Update app state
        appState.projects.push(project);

        return project;
    } catch (error) {
        console.error('Error creating project:', error);
        showNotification('שגיאה ביצירת הפרויקט: ' + error.message, 'error');
        return null;
    }
}

function getAllProjects() {
    try {
        const projects = JSON.parse(localStorage.getItem('inspectort_projects') || '[]');
        const currentUser = getCurrentUser();
        
        if (!currentUser) {
            return [];
        }
        
        // Filter projects by current user
        return projects.filter(project => project.createdBy === currentUser.id);
    } catch (error) {
        console.error('Error getting projects:', error);
        return [];
    }
}

function getProjectById(projectId) {
    const projects = getAllProjects();
    return projects.find(project => project.id === projectId);
}

function updateProject(projectId, updates) {
    try {
        const allProjects = JSON.parse(localStorage.getItem('inspectort_projects') || '[]');
        const projectIndex = allProjects.findIndex(p => p.id === projectId);
        
        if (projectIndex === -1) {
            throw new Error('פרויקט לא נמצא');
        }

        // Update project data
        allProjects[projectIndex] = {
            ...allProjects[projectIndex],
            ...updates,
            updatedAt: new Date().toISOString()
        };

        localStorage.setItem('inspectort_projects', JSON.stringify(allProjects));
        
        // Update app state
        const appProjectIndex = appState.projects.findIndex(p => p.id === projectId);
        if (appProjectIndex !== -1) {
            appState.projects[appProjectIndex] = allProjects[projectIndex];
        }

        return allProjects[projectIndex];
    } catch (error) {
        console.error('Error updating project:', error);
        showNotification('שגיאה בעדכון הפרויקט: ' + error.message, 'error');
        return null;
    }
}

function deleteProject(projectId) {
    try {
        const allProjects = JSON.parse(localStorage.getItem('inspectort_projects') || '[]');
        const filteredProjects = allProjects.filter(p => p.id !== projectId);
        
        localStorage.setItem('inspectort_projects', JSON.stringify(filteredProjects));
        
        // Update app state
        appState.projects = appState.projects.filter(p => p.id !== projectId);
        
        return true;
    } catch (error) {
        console.error('Error deleting project:', error);
        showNotification('שגיאה במחיקת הפרויקט: ' + error.message, 'error');
        return false;
    }
}

function getCurrentUser() {
    return appState.currentUser;
}

function generateId() {
    return Date.now().toString(36) + Math.random().toString(36).substr(2);
}

function renderProjects() {
    const projects = getAllProjects();
    appState.projects = projects;
    
    if (appState.currentPage === 'dashboard') {
        updateDashboardContent();
    }
}

function updateUserStats() {
    const totalProjects = appState.projects.length;
    const totalPhotos = appState.projects.reduce((sum, p) => sum + p.totalPhotos, 0);
    
    // Update dashboard stats if visible
    if (appState.currentPage === 'dashboard') {
        updateDashboardContent();
    }
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
    try {
        if (!appState.currentProject) {
            showNotification('יש לבחור פרויקט תחילה', 'error');
            return;
        }
        
        // Check storage before starting capture
        const usage = getStorageUsage();
        if (usage.total > 4) {
            showNotification('אחסון מלא! מחק תמונות ישנות לפני צילום חדש', 'error');
            showStorageWarning();
            return;
        }
        
        console.log('Starting photo capture');
        
        // Create camera modal
        const modalContent = `
            <div class="camera-container">
                <div class="camera-view">
                    <video id="cameraVideo" autoplay playsinline></video>
                    <canvas id="cameraCanvas" style="display: none;"></canvas>
                </div>
                <div class="camera-controls">
                    <button id="takePictureBtn" class="btn btn-primary camera-btn">
                        <span class="btn-icon">📸</span>
                        צלם
                    </button>
                    <button id="switchCameraBtn" class="btn btn-secondary camera-btn">
                        <span class="btn-icon">🔄</span>
                        החלף מצלמה
                    </button>
                </div>
            </div>
        `;

        const modal = createModal(
            'צילום תמונה',
            modalContent,
            [
                {
                    text: 'ביטול',
                    class: 'btn-secondary',
                    action: 'stopCamera(); closeModal(this.closest(\'.modal-overlay\'))'
                }
            ]
        );

        showModal(modal);
        
        // Initialize camera
        initializeCamera();
    } catch (error) {
        console.error('Error in capturePhoto:', error);
        showNotification('שגיאה בפתיחת המצלמה', 'error');
    }
}

function uploadPhoto() {
    try {
        if (!appState.currentProject) {
            showNotification('יש לבחור פרויקט תחילה', 'error');
            return;
        }
        
        // Check storage before starting upload
        const usage = getStorageUsage();
        if (usage.total > 4) {
            showNotification('אחסון מלא! מחק תמונות ישנות לפני העלאת חדשות', 'error');
            showStorageWarning();
            return;
        }
        
        console.log('Starting photo upload');
        
        // Create file input
        const fileInput = document.createElement('input');
        fileInput.type = 'file';
        fileInput.accept = 'image/*';
        fileInput.multiple = true;
        fileInput.style.display = 'none';
        
        fileInput.addEventListener('change', handlePhotoUpload);
        
        document.body.appendChild(fileInput);
        fileInput.click();
        
        // Clean up
        setTimeout(() => {
            if (document.body.contains(fileInput)) {
                document.body.removeChild(fileInput);
            }
        }, 1000);
    } catch (error) {
        console.error('Error in uploadPhoto:', error);
        showNotification('שגיאה בפתיחת בוחר הקבצים', 'error');
    }
}

async function initializeCamera() {
    try {
        const video = document.getElementById('cameraVideo');
        const takePictureBtn = document.getElementById('takePictureBtn');
        const switchCameraBtn = document.getElementById('switchCameraBtn');
        
        if (!video) return;
        
        // Check if camera is available
        if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
            showNotification('המצלמה אינה נתמכת בדפדפן זה', 'error');
            return;
        }
        
        // Get available cameras
        const devices = await navigator.mediaDevices.enumerateDevices();
        const videoDevices = devices.filter(device => device.kind === 'videoinput');
        
        let currentDeviceIndex = 0;
        let stream = null;
        
        async function startCamera(deviceId = null) {
            try {
                // Stop previous stream
                if (stream) {
                    stream.getTracks().forEach(track => track.stop());
                }
                
                // Mobile-optimized camera constraints
                const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
                const constraints = {
                    video: {
                        facingMode: deviceId ? undefined : 'environment',
                        deviceId: deviceId ? { exact: deviceId } : undefined,
                        width: { ideal: isMobile ? 1280 : 1920 },
                        height: { ideal: isMobile ? 720 : 1080 }
                    }
                };
                
                console.log('Starting camera with constraints:', constraints);
                
                stream = await navigator.mediaDevices.getUserMedia(constraints);
                video.srcObject = stream;
                
                // Show/hide switch button based on available cameras
                if (switchCameraBtn) {
                    switchCameraBtn.style.display = videoDevices.length > 1 ? 'block' : 'none';
                }
                
                console.log('Camera started successfully');
                
            } catch (error) {
                console.error('Camera error:', error);
                
                // Try with fallback constraints for mobile
                if (isMobile && !deviceId) {
                    try {
                        console.log('Trying fallback camera constraints for mobile');
                        const fallbackConstraints = {
                            video: {
                                facingMode: 'environment',
                                width: { ideal: 640 },
                                height: { ideal: 480 }
                            }
                        };
                        
                        stream = await navigator.mediaDevices.getUserMedia(fallbackConstraints);
                        video.srcObject = stream;
                        
                        console.log('Fallback camera started');
                        return;
                    } catch (fallbackError) {
                        console.error('Fallback camera error:', fallbackError);
                    }
                }
                
                showNotification('שגיאה בגישה למצלמה: ' + error.message, 'error');
            }
        }
        
        // Start with default camera
        await startCamera();
        
        // Handle take picture
        if (takePictureBtn) {
            takePictureBtn.addEventListener('click', () => {
                takePicture(video);
            });
        }
        
        // Handle switch camera
        if (switchCameraBtn) {
            switchCameraBtn.addEventListener('click', async () => {
                currentDeviceIndex = (currentDeviceIndex + 1) % videoDevices.length;
                await startCamera(videoDevices[currentDeviceIndex].deviceId);
            });
        }
        
        // Store stream reference for cleanup
        window.currentCameraStream = stream;
        
    } catch (error) {
        console.error('Camera initialization error:', error);
        showNotification('שגיאה באתחול המצלמה', 'error');
    }
}

function takePicture(video) {
    try {
        const canvas = document.getElementById('cameraCanvas');
        const context = canvas.getContext('2d');
        
        // Determine optimal canvas size for mobile
        const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
        const maxWidth = isMobile ? 1200 : 1920;
        const maxHeight = isMobile ? 1200 : 1080;
        
        let canvasWidth = video.videoWidth;
        let canvasHeight = video.videoHeight;
        
        // Scale down for mobile if needed
        if (canvasWidth > maxWidth || canvasHeight > maxHeight) {
            const scale = Math.min(maxWidth / canvasWidth, maxHeight / canvasHeight);
            canvasWidth = Math.round(canvasWidth * scale);
            canvasHeight = Math.round(canvasHeight * scale);
        }
        
        // Set canvas size
        canvas.width = canvasWidth;
        canvas.height = canvasHeight;
        
        console.log('Taking picture:', canvasWidth + 'x' + canvasHeight);
        
        // Draw video frame to canvas
        context.drawImage(video, 0, 0, canvasWidth, canvasHeight);
        
        // Convert to blob with mobile-optimized quality
        const quality = isMobile ? 0.7 : 0.9;
        canvas.toBlob((blob) => {
            if (blob) {
                console.log('Picture captured, size:', Math.round(blob.size / 1024), 'KB');
                
                // Create file object with iOS compatibility
                const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
                const fileName = `photo-${timestamp}.jpg`; // Keep for technical purposes
                
                let file;
                try {
                    file = new File([blob], fileName, { type: 'image/jpeg' });
                } catch (error) {
                    // Fallback for older iOS versions
                    file = blob;
                    file.name = fileName;
                    file.lastModified = Date.now();
                }
                
                // Process the captured photo
                processPhoto(file);
                
                // Close camera modal
                stopCamera();
                closeModal(document.querySelector('.modal-overlay'));
            } else {
                console.error('Failed to create blob from canvas');
                showNotification('שגיאה בהמרת התמונה', 'error');
            }
        }, 'image/jpeg', quality);
        
    } catch (error) {
        console.error('Take picture error:', error);
        showNotification('שגיאה בצילום התמונה', 'error');
    }
}

function stopCamera() {
    if (window.currentCameraStream) {
        window.currentCameraStream.getTracks().forEach(track => track.stop());
        window.currentCameraStream = null;
    }
}

function handlePhotoUpload(event) {
    try {
        const files = Array.from(event.target.files);
        
        if (files.length === 0) return;
        
        console.log('Uploading files:', files.length);
        
        // Validate files
        const validFiles = files.filter(file => {
            if (!file.type.startsWith('image/')) {
                showNotification(`הקובץ ${file.name} אינו תמונה`, 'error');
                return false;
            }
            
            if (file.size > 10 * 1024 * 1024) { // 10MB limit
                showNotification(`הקובץ ${file.name} גדול מדי (מעל 10MB)`, 'error');
                return false;
            }
            
            return true;
        });
        
        if (validFiles.length === 0) return;
        
        console.log('Valid files:', validFiles.length);
        
        // Process each valid file
        validFiles.forEach(file => {
            processPhoto(file);
        });
        
        // Show success message only for multiple files
        if (validFiles.length > 1) {
            showNotification(`הועלו ${validFiles.length} תמונות בהצלחה`, 'success');
        }
    } catch (error) {
        console.error('Error handling photo upload:', error);
        showNotification('שגיאה בהעלאת התמונות', 'error');
    }
}

function processPhoto(file) {
    try {
        console.log('Processing photo:', file.name, 'Original size:', Math.round(file.size / 1024), 'KB');
        
        // Check if image needs compression for mobile
        const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
        const needsCompression = file.size > 1024 * 1024 || isMobile; // 1MB threshold or mobile
        
        if (needsCompression) {
            console.log('Compressing image for mobile/size optimization');
            compressImage(file, (compressedFile) => {
                processCompressedPhoto(compressedFile);
            });
        } else {
            processCompressedPhoto(file);
        }
        
    } catch (error) {
        console.error('Error in processPhoto:', error);
        showNotification('שגיאה בעיבוד התמונה', 'error');
    }
}

function compressImage(file, callback) {
    try {
        const canvas = document.createElement('canvas');
        const ctx = canvas.getContext('2d');
        const img = new Image();
        
        img.onload = function() {
            // Calculate new dimensions (max 1200px width/height for mobile)
            const maxSize = 1200;
            let { width, height } = img;
            
            if (width > height) {
                if (width > maxSize) {
                    height = height * (maxSize / width);
                    width = maxSize;
                }
            } else {
                if (height > maxSize) {
                    width = width * (maxSize / height);
                    height = maxSize;
                }
            }
            
            canvas.width = width;
            canvas.height = height;
            
            // Draw and compress
            ctx.drawImage(img, 0, 0, width, height);
            
            canvas.toBlob((blob) => {
                if (blob) {
                    // Create file-like object with iOS compatibility
                    let compressedFile;
                    try {
                        compressedFile = new File([blob], file.name, {
                            type: 'image/jpeg',
                            lastModified: Date.now()
                        });
                    } catch (error) {
                        // Fallback for older iOS versions
                        compressedFile = blob;
                        compressedFile.name = file.name;
                        compressedFile.lastModified = Date.now();
                    }
                    
                    console.log('Image compressed:', 
                        Math.round(file.size / 1024), 'KB →', 
                        Math.round(compressedFile.size / 1024), 'KB',
                        '(' + Math.round((1 - compressedFile.size / file.size) * 100) + '% reduction)'
                    );
                    
                    callback(compressedFile);
                } else {
                    console.error('Failed to compress image');
                    callback(file); // Fallback to original
                }
            }, 'image/jpeg', 0.8); // 80% quality
        };
        
        img.onerror = function() {
            console.error('Failed to load image for compression');
            callback(file); // Fallback to original
        };
        
        img.src = URL.createObjectURL(file);
        
    } catch (error) {
        console.error('Error compressing image:', error);
        callback(file); // Fallback to original
    }
}

function processCompressedPhoto(file) {
    try {
        const reader = new FileReader();
        
        reader.onload = function(e) {
            try {
                const photoData = {
                    id: generateId(),
                    name: '', // Default to blank name
                    originalName: file.name, // Keep technical name for reference
                    url: e.target.result,
                    type: file.type,
                    size: file.size,
                    projectId: appState.currentProject.id,
                    createdAt: new Date().toISOString(),
                    updatedAt: new Date().toISOString(),
                    description: '',
                    annotations: [],
                    isAnnotated: false
                };
                
                console.log('Photo data created:', photoData.name, 'Final size:', Math.round(photoData.size / 1024), 'KB');
                
                // Save photo
                const savedPhoto = savePhoto(photoData);
                
                if (savedPhoto) {
                    console.log('Photo saved successfully');
                    
                    // Update project statistics
                    updateProjectPhotoCount(appState.currentProject.id);
                    
                    // Refresh photos grid
                    updatePhotosGrid();
                    
                    // Update project stats
                    updateUserStats();
                    
                    showNotification('תמונה הועלתה בהצלחה!', 'success');
                } else {
                    console.error('Failed to save photo');
                    showNotification('שגיאה בשמירת התמונה', 'error');
                }
            } catch (error) {
                console.error('Error processing photo data:', error);
                showNotification('שגיאה בעיבוד התמונה', 'error');
            }
        };
        
        reader.onerror = function(error) {
            console.error('File reader error:', error);
            showNotification('שגיאה בקריאת קובץ התמונה', 'error');
        };
        
        reader.readAsDataURL(file);
    } catch (error) {
        console.error('Error in processCompressedPhoto:', error);
        showNotification('שגיאה בעיבוד התמונה', 'error');
    }
}

function savePhoto(photoData) {
    try {
        console.log('Attempting to save photo:', photoData.name, 'Size:', photoData.size);
        
        // Check localStorage availability and space
        if (!isStorageAvailable()) {
            throw new Error('localStorage is not available');
        }
        
        // Get current photos
        const allPhotos = JSON.parse(localStorage.getItem('inspectort_photos') || '[]');
        
        // Add new photo
        allPhotos.push(photoData);
        
        // Check if the data is too large for localStorage
        const dataString = JSON.stringify(allPhotos);
        const dataSize = new Blob([dataString]).size;
        
        console.log('Total data size:', Math.round(dataSize / 1024 / 1024 * 100) / 100, 'MB');
        
        if (dataSize > 4 * 1024 * 1024) { // 4MB limit for mobile safety
            throw new Error('Data too large for localStorage');
        }
        
        // Save to localStorage
        localStorage.setItem('inspectort_photos', dataString);
        
        // Update app state
        appState.photos.push(photoData);
        
        console.log('Photo saved successfully');
        return photoData;
    } catch (error) {
        console.error('Error saving photo:', error);
        
        // Handle specific errors
        if (error.name === 'QuotaExceededError' || error.message.includes('quota')) {
            showNotification('שגיאה: אחסון מלא. מחק תמונות ישנות כדי לפנות מקום', 'error');
            // Show storage management options
            setTimeout(() => {
                showStorageWarning();
            }, 2000);
        } else if (error.message.includes('too large')) {
            showNotification('שגיאה: יותר מדי תמונות. מחק תמונות ישנות כדי לפנות מקום', 'error');
            setTimeout(() => {
                showStorageWarning();
            }, 2000);
        } else {
            showNotification('שגיאה בשמירת התמונה: ' + error.message, 'error');
        }
        
        return null;
    }
}

function isStorageAvailable() {
    try {
        const test = '__storage_test__';
        localStorage.setItem(test, test);
        localStorage.removeItem(test);
        return true;
    } catch (e) {
        console.error('localStorage not available:', e.message);
        
        // Check for private browsing mode
        if (e.name === 'QuotaExceededError' && localStorage.length === 0) {
            showNotification('אנא צא ממצב גלישה פרטית כדי לשמור תמונות', 'error');
        } else {
            showNotification('שגיאה באחסון המכשיר', 'error');
        }
        
        return false;
    }
}

function getStorageUsage() {
    try {
        const photos = localStorage.getItem('inspectort_photos') || '[]';
        const projects = localStorage.getItem('inspectort_projects') || '[]';
        const users = localStorage.getItem('inspectort_users') || '[]';
        
        const photosSize = new Blob([photos]).size;
        const projectsSize = new Blob([projects]).size;
        const usersSize = new Blob([users]).size;
        
        const totalSize = photosSize + projectsSize + usersSize;
        
        return {
            photos: Math.round(photosSize / 1024 / 1024 * 100) / 100,
            projects: Math.round(projectsSize / 1024 / 1024 * 100) / 100,
            users: Math.round(usersSize / 1024 / 1024 * 100) / 100,
            total: Math.round(totalSize / 1024 / 1024 * 100) / 100
        };
    } catch (error) {
        console.error('Error calculating storage usage:', error);
        return { photos: 0, projects: 0, users: 0, total: 0 };
    }
}

function showStorageWarning() {
    const usage = getStorageUsage();
    
    if (usage.total > 3) { // Show warning at 3MB
        const modal = createModal(
            'אחסון מלא',
            `<p>השימוש באחסון: <strong>${usage.total} MB</strong></p>
             <p>תמונות: ${usage.photos} MB</p>
             <p>האחסון כמעט מלא. מומלץ למחוק תמונות ישנות לפני הוספת תמונות חדשות.</p>
             <p>האם ברצונך לעבור לניהול התמונות?</p>`,
            [
                {
                    text: 'ביטול',
                    class: 'btn-secondary',
                    action: 'closeModal(this.closest(\'.modal-overlay\'))'
                },
                {
                    text: 'נהל תמונות',
                    class: 'btn-primary',
                    action: 'navigateToPhotoManagement()'
                }
            ]
        );
        
        showModal(modal);
    }
}

function navigateToPhotoManagement() {
    closeModal(document.querySelector('.modal-overlay'));
    // This would navigate to a photo management page
    // For now, just show a message
    showNotification('גלול למטה לראות את כל התמונות ולמחוק ישנות', 'info', 5000);
}

function getAllPhotos() {
    try {
        const photos = JSON.parse(localStorage.getItem('inspectort_photos') || '[]');
        const currentUser = getCurrentUser();
        
        if (!currentUser) {
            return [];
        }
        
        // Filter photos by current user's projects
        const userProjects = getAllProjects();
        const userProjectIds = userProjects.map(p => p.id);
        
        return photos.filter(photo => userProjectIds.includes(photo.projectId));
    } catch (error) {
        console.error('Error getting photos:', error);
        return [];
    }
}

function getPhotosByProject(projectId) {
    const allPhotos = getAllPhotos();
    return allPhotos.filter(photo => photo.projectId === projectId);
}

function getPhotoById(photoId) {
    const allPhotos = getAllPhotos();
    return allPhotos.find(photo => photo.id === photoId);
}

function updatePhoto(photoId, updates) {
    try {
        const allPhotos = JSON.parse(localStorage.getItem('inspectort_photos') || '[]');
        const photoIndex = allPhotos.findIndex(p => p.id === photoId);
        
        if (photoIndex === -1) {
            throw new Error('תמונה לא נמצאה');
        }

        // Update photo data
        allPhotos[photoIndex] = {
            ...allPhotos[photoIndex],
            ...updates,
            updatedAt: new Date().toISOString()
        };

        localStorage.setItem('inspectort_photos', JSON.stringify(allPhotos));
        
        // Update app state
        const appPhotoIndex = appState.photos.findIndex(p => p.id === photoId);
        if (appPhotoIndex !== -1) {
            appState.photos[appPhotoIndex] = allPhotos[photoIndex];
        }

        return allPhotos[photoIndex];
    } catch (error) {
        console.error('Error updating photo:', error);
        showNotification('שגיאה בעדכון התמונה: ' + error.message, 'error');
        return null;
    }
}

function deletePhoto(photoId) {
    try {
        const allPhotos = JSON.parse(localStorage.getItem('inspectort_photos') || '[]');
        const filteredPhotos = allPhotos.filter(p => p.id !== photoId);
        
        localStorage.setItem('inspectort_photos', JSON.stringify(filteredPhotos));
        
        // Update app state
        appState.photos = appState.photos.filter(p => p.id !== photoId);
        
        return true;
    } catch (error) {
        console.error('Error deleting photo:', error);
        showNotification('שגיאה במחיקת התמונה: ' + error.message, 'error');
        return false;
    }
}

function updateProjectPhotoCount(projectId) {
    const projectPhotos = getPhotosByProject(projectId);
    const annotatedPhotos = projectPhotos.filter(p => p.isAnnotated).length;
    
    const updates = {
        totalPhotos: projectPhotos.length,
        annotatedPhotos: annotatedPhotos,
        completionPercentage: projectPhotos.length > 0 ? Math.round((annotatedPhotos / projectPhotos.length) * 100) : 0
    };
    
    updateProject(projectId, updates);
}

function showPhotoMenu(event, photoId) {
    event.stopPropagation();
    
    const photo = getPhotoById(photoId);
    if (!photo) return;
    
    const menuContent = `
        <div class="photo-menu-actions">
            <button class="menu-action" onclick="editPhotoInfo('${photoId}')">
                <span class="menu-icon">✏️</span>
                ערוך פרטים
            </button>
            <button class="menu-action" onclick="renamePhoto('${photoId}')">
                <span class="menu-icon">🏷️</span>
                שנה שם
            </button>
            <button class="menu-action" onclick="downloadPhoto('${photoId}')">
                <span class="menu-icon">📥</span>
                הורד תמונה
            </button>
            <button class="menu-action menu-action-danger" onclick="confirmDeletePhoto('${photoId}')">
                <span class="menu-icon">🗑️</span>
                מחק תמונה
            </button>
        </div>
    `;

    const modal = createModal(
        photo.name,
        menuContent,
        [
            {
                text: 'סגור',
                class: 'btn-secondary',
                action: 'closeModal(this.closest(\'.modal-overlay\'))'
            }
        ]
    );

    showModal(modal);
}

function editPhotoInfo(photoId) {
    const photo = getPhotoById(photoId);
    if (!photo) return;
    
    const modalContent = `
        <form id="editPhotoForm" class="photo-form">
            <div class="form-group">
                <label for="photoName">שם התמונה *</label>
                <input type="text" id="photoName" name="photoName" required maxlength="100" 
                       value="${photo.name}" placeholder="שם התמונה">
            </div>
            
            <div class="form-group">
                <label for="photoDescription">תיאור התמונה</label>
                <textarea id="photoDescription" name="photoDescription" rows="4" maxlength="500"
                          placeholder="תיאור מפורט של התמונה...">${photo.description || ''}</textarea>
            </div>
            
            <div class="photo-preview">
                <img src="${photo.url}" alt="${photo.name}" class="preview-image">
            </div>
            
            <div class="photo-info">
                <div class="info-item">
                    <span class="info-label">גודל:</span>
                    <span class="info-value">${formatFileSize(photo.size)}</span>
                </div>
                <div class="info-item">
                    <span class="info-label">תאריך:</span>
                    <span class="info-value">${new Date(photo.createdAt).toLocaleDateString('he-IL')}</span>
                </div>
                <div class="info-item">
                    <span class="info-label">סוג:</span>
                    <span class="info-value">${photo.type}</span>
                </div>
            </div>
        </form>
    `;

    const modal = createModal(
        'ערוך פרטי תמונה',
        modalContent,
        [
            {
                text: 'ביטול',
                class: 'btn-secondary',
                action: 'closeModal(this.closest(\'.modal-overlay\'))'
            },
            {
                text: 'שמור שינויים',
                class: 'btn-primary',
                action: `handleEditPhoto('${photoId}')`
            }
        ]
    );

    showModal(modal);
}

function handleEditPhoto(photoId) {
    const form = document.getElementById('editPhotoForm');
    const formData = new FormData(form);
    
    const photoName = formData.get('photoName').trim();
    if (!photoName) {
        showNotification('שם התמונה הוא שדה חובה', 'error');
        return;
    }
    
    const updates = {
        name: photoName,
        description: formData.get('photoDescription').trim()
    };
    
    const updatedPhoto = updatePhoto(photoId, updates);
    
    if (updatedPhoto) {
        closeModal(document.querySelector('.modal-overlay'));
        showNotification('פרטי התמונה עודכנו בהצלחה!', 'success');
        updatePhotosGrid();
    }
}

function renamePhoto(photoId) {
    const photo = getPhotoById(photoId);
    if (!photo) return;
    
    const newName = prompt('שם חדש לתמונה:', photo.name);
    if (newName && newName.trim() !== photo.name) {
        const updatedPhoto = updatePhoto(photoId, { name: newName.trim() });
        if (updatedPhoto) {
            closeModal(document.querySelector('.modal-overlay'));
            showNotification('שם התמונה שונה בהצלחה!', 'success');
            updatePhotosGrid();
        }
    }
}

function downloadPhoto(photoId) {
    const photo = getPhotoById(photoId);
    if (!photo) return;
    
    try {
        const link = document.createElement('a');
        link.href = photo.url;
        link.download = photo.name;
        link.click();
        
        closeModal(document.querySelector('.modal-overlay'));
        showNotification('התמונה הורדה בהצלחה', 'success');
    } catch (error) {
        console.error('Download error:', error);
        showNotification('שגיאה בהורדת התמונה', 'error');
    }
}

function confirmDeletePhoto(photoId) {
    const photo = getPhotoById(photoId);
    if (!photo) return;
    
    const modal = createModal(
        'מחק תמונה',
        `<p>האם אתה בטוח שברצונך למחוק את התמונה "<strong>${photo.name}</strong>"?</p>
         <p class="text-danger">פעולה זו לא ניתנת לביטול!</p>`,
        [
            {
                text: 'ביטול',
                class: 'btn-secondary',
                action: 'closeModal(this.closest(\'.modal-overlay\'))'
            },
            {
                text: 'מחק',
                class: 'btn-danger',
                action: `handleDeletePhoto('${photoId}')`
            }
        ]
    );

    showModal(modal);
}

function handleDeletePhoto(photoId) {
    const photo = getPhotoById(photoId);
    if (!photo) return;
    
    const success = deletePhoto(photoId);
    
    if (success) {
        closeModal(document.querySelector('.modal-overlay'));
        showNotification('התמונה נמחקה בהצלחה', 'success');
        updatePhotosGrid();
        updateProjectPhotoCount(photo.projectId);
        updateUserStats();
    }
}

function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

function exportReport() {
    // TODO: Implement report export
    console.log('Export report');
}

function openPhotoAnnotation(photo) {
    const displayName = photo.name || 'ללא שם';
    
    const modalContent = `
        <div class="photo-annotation-container">
            <!-- Photo First - Main Focus -->
            <div class="annotation-image-container">
                <img src="${photo.url}" alt="${displayName}" class="annotation-image" id="annotationImage">
                <canvas id="annotationCanvas" class="annotation-canvas"></canvas>
            </div>
            
            <!-- Photo Info -->
            <div class="annotation-info">
                <h4>${displayName}</h4>
                <div class="photo-meta">
                    <span>📅 ${new Date(photo.createdAt).toLocaleDateString('he-IL')}</span>
                    <span>📏 ${formatFileSize(photo.size)}</span>
                </div>
            </div>
            
            <!-- Annotation Tools Below - Organized and Clean -->
            <div class="annotation-toolbar">
                <div class="tool-section">
                    <div class="tool-group">
                        <label class="tool-label">כלי ציור:</label>
                        <div class="tools-row">
                            <button class="tool-btn active" data-tool="pen" title="עט">
                                <span class="tool-icon">✏️</span>
                            </button>
                            <button class="tool-btn" data-tool="arrow" title="חץ">
                                <span class="tool-icon">↗️</span>
                            </button>
                            <button class="tool-btn" data-tool="rectangle" title="מלבן">
                                <span class="tool-icon">▭</span>
                            </button>
                            <button class="tool-btn" data-tool="circle" title="עיגול">
                                <span class="tool-icon">⭕</span>
                            </button>
                            <button class="tool-btn" data-tool="text" title="טקסט">
                                <span class="tool-icon">📝</span>
                            </button>
                        </div>
                    </div>
                </div>
                
                <div class="tool-section">
                    <div class="tool-group">
                        <label class="tool-label">צבע:</label>
                        <div class="color-picker-container">
                            <input type="color" id="annotationColor" class="color-picker" value="#FF0000" title="בחר צבע">
                            <div class="color-presets">
                                <button class="color-preset" data-color="#FF0000" style="background: #FF0000" title="אדום"></button>
                                <button class="color-preset" data-color="#00FF00" style="background: #00FF00" title="ירוק"></button>
                                <button class="color-preset" data-color="#0000FF" style="background: #0000FF" title="כחול"></button>
                                <button class="color-preset" data-color="#FFFF00" style="background: #FFFF00" title="צהוב"></button>
                                <button class="color-preset" data-color="#FF8000" style="background: #FF8000" title="כתום"></button>
                            </div>
                        </div>
                    </div>
                    
                    <div class="tool-group">
                        <label class="tool-label">עובי:</label>
                        <div class="stroke-width-container">
                            <input type="range" id="strokeWidth" min="1" max="10" value="3" class="stroke-slider">
                            <span id="strokeWidthValue">3</span>
                        </div>
                    </div>
                </div>
                
                <div class="tool-section">
                    <div class="tool-group">
                        <label class="tool-label">פעולות:</label>
                        <div class="tools-row">
                            <button class="tool-btn" id="undoBtn" title="בטל">
                                <span class="tool-icon">↶</span>
                            </button>
                            <button class="tool-btn" id="redoBtn" title="חזור">
                                <span class="tool-icon">↷</span>
                            </button>
                            <button class="tool-btn" id="clearBtn" title="נקה הכל">
                                <span class="tool-icon">🗑️</span>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Description at Bottom -->
            <div class="annotation-description">
                <label for="annotationText">הוסף תיאור או הערה:</label>
                <textarea id="annotationText" rows="3" maxlength="300" 
                          placeholder="תאר את מה שנראה בתמונה או הוסף הערות...">${photo.description || ''}</textarea>
            </div>
        </div>
    `;

    const modal = createModal(
        'הוסף הערות לתמונה',
        modalContent,
        [
            {
                text: 'ביטול',
                class: 'btn-secondary',
                action: 'closeAnnotationModal()'
            },
            {
                text: 'שמור הערות',
                class: 'btn-primary',
                action: `savePhotoAnnotations('${photo.id}')`
            }
        ]
    );

    showModal(modal);
    
    // Initialize annotation system
    setTimeout(() => {
        initializeAnnotationSystem(photo);
    }, 100);
}

function initializeAnnotationSystem(photo) {
    try {
        const image = document.getElementById('annotationImage');
        const canvas = document.getElementById('annotationCanvas');
        
        if (!image || !canvas) {
            console.log('Annotation elements not found');
            return;
        }
        
        // Initialize annotation state
        window.annotationState = {
            currentTool: 'pen', // Start with pen tool instead of view
            currentColor: '#FF0000',
            currentStrokeWidth: 3,
            isDrawing: false,
            startPoint: null,
            annotations: [...(photo.annotations || [])],
            history: [],
            historyIndex: -1,
            canvas: canvas,
            ctx: canvas.getContext('2d'),
            image: image
        };
        
        // Setup canvas
        setupAnnotationCanvas();
        
        // Load existing annotations
        loadAnnotations(photo.annotations || []);
        
        // Setup event listeners
        setupAnnotationEventListeners();
        
        // Setup toolbar
        setupAnnotationToolbar();
    } catch (error) {
        console.error('Error initializing annotation system:', error);
    }
}

function setupAnnotationCanvas() {
    try {
        if (!window.annotationState) return;
        
        const { canvas, ctx, image } = window.annotationState;
        
        if (!canvas || !ctx || !image) {
            console.log('Canvas elements not available');
            return;
        }
        
        // Wait for image to load
        if (image.complete) {
            resizeCanvas();
        } else {
            image.addEventListener('load', resizeCanvas);
        }
        
        function resizeCanvas() {
            try {
                const rect = image.getBoundingClientRect();
                canvas.width = rect.width;
                canvas.height = rect.height;
                canvas.style.width = rect.width + 'px';
                canvas.style.height = rect.height + 'px';
                
                // Redraw annotations
                redrawAnnotations();
            } catch (error) {
                console.error('Error resizing canvas:', error);
            }
        }
        
        // Handle window resize
        window.addEventListener('resize', resizeCanvas);
    } catch (error) {
        console.error('Error setting up annotation canvas:', error);
    }
}

function setupAnnotationEventListeners() {
    const { canvas } = window.annotationState;
    
    // Mouse events
    canvas.addEventListener('mousedown', handleAnnotationStart);
    canvas.addEventListener('mousemove', handleAnnotationMove);
    canvas.addEventListener('mouseup', handleAnnotationEnd);
    canvas.addEventListener('mouseout', handleAnnotationEnd);
    
    // Touch events for mobile
    canvas.addEventListener('touchstart', handleTouchStart);
    canvas.addEventListener('touchmove', handleTouchMove);
    canvas.addEventListener('touchend', handleTouchEnd);
    
    // Prevent default touch behavior
    canvas.addEventListener('touchstart', (e) => e.preventDefault());
    canvas.addEventListener('touchmove', (e) => e.preventDefault());
}

function setupAnnotationToolbar() {
    try {
        // Tool buttons
        document.querySelectorAll('.tool-btn[data-tool]').forEach(btn => {
            btn.addEventListener('click', () => {
                selectTool(btn.dataset.tool);
            });
        });
        
        // Color picker
        const colorPicker = document.getElementById('annotationColor');
        if (colorPicker) {
            colorPicker.addEventListener('change', (e) => {
                window.annotationState.currentColor = e.target.value;
            });
        }
        
        // Color presets
        document.querySelectorAll('.color-preset').forEach(btn => {
            btn.addEventListener('click', () => {
                const color = btn.dataset.color;
                window.annotationState.currentColor = color;
                if (colorPicker) colorPicker.value = color;
            });
        });
        
        // Stroke width
        const strokeSlider = document.getElementById('strokeWidth');
        const strokeValue = document.getElementById('strokeWidthValue');
        if (strokeSlider && strokeValue) {
            strokeSlider.addEventListener('input', (e) => {
                window.annotationState.currentStrokeWidth = parseInt(e.target.value);
                strokeValue.textContent = e.target.value;
            });
        }
        
        // Action buttons
        const undoBtn = document.getElementById('undoBtn');
        const redoBtn = document.getElementById('redoBtn');
        const clearBtn = document.getElementById('clearBtn');
        
        if (undoBtn) undoBtn.addEventListener('click', undoAnnotation);
        if (redoBtn) redoBtn.addEventListener('click', redoAnnotation);
        if (clearBtn) clearBtn.addEventListener('click', clearAllAnnotations);
    } catch (error) {
        console.error('Error setting up annotation toolbar:', error);
    }
}

function selectTool(toolName) {
    window.annotationState.currentTool = toolName;
    
    // Update toolbar UI
    document.querySelectorAll('.tool-btn[data-tool]').forEach(btn => {
        btn.classList.remove('active');
    });
    
    const toolButton = document.querySelector(`[data-tool="${toolName}"]`);
    if (toolButton) {
        toolButton.classList.add('active');
    }
    
    // Update cursor - all tools are interactive now
    const canvas = window.annotationState.canvas;
    canvas.style.cursor = 'crosshair';
}

function getCanvasCoordinates(event) {
    const canvas = window.annotationState.canvas;
    const rect = canvas.getBoundingClientRect();
    const scaleX = canvas.width / rect.width;
    const scaleY = canvas.height / rect.height;
    
    return {
        x: (event.clientX - rect.left) * scaleX,
        y: (event.clientY - rect.top) * scaleY
    };
}

function handleAnnotationStart(event) {
    const { currentTool } = window.annotationState;
    
    if (currentTool === 'view') return;
    
    window.annotationState.isDrawing = true;
    window.annotationState.startPoint = getCanvasCoordinates(event);
    
    if (currentTool === 'pen') {
        startPenDrawing(window.annotationState.startPoint);
    } else if (currentTool === 'text') {
        addTextAnnotation(window.annotationState.startPoint);
    }
}

function handleAnnotationMove(event) {
    const { currentTool, isDrawing, startPoint } = window.annotationState;
    
    if (!isDrawing || currentTool === 'view' || currentTool === 'text') return;
    
    const currentPoint = getCanvasCoordinates(event);
    
    if (currentTool === 'pen') {
        continuePenDrawing(currentPoint);
    } else {
        // For shapes, show preview
        redrawAnnotations();
        drawPreviewShape(startPoint, currentPoint);
    }
}

function handleAnnotationEnd(event) {
    const { currentTool, isDrawing, startPoint } = window.annotationState;
    
    if (!isDrawing || currentTool === 'view' || currentTool === 'text') return;
    
    const endPoint = getCanvasCoordinates(event);
    
    if (currentTool === 'pen') {
        finishPenDrawing();
    } else if (currentTool === 'arrow') {
        addArrowAnnotation(startPoint, endPoint);
    } else if (currentTool === 'rectangle') {
        addRectangleAnnotation(startPoint, endPoint);
    } else if (currentTool === 'circle') {
        addCircleAnnotation(startPoint, endPoint);
    }
    
    window.annotationState.isDrawing = false;
    window.annotationState.startPoint = null;
    
    saveAnnotationState();
}

function handleTouchStart(event) {
    event.preventDefault();
    const touch = event.touches[0];
    handleAnnotationStart(touch);
}

function handleTouchMove(event) {
    event.preventDefault();
    const touch = event.touches[0];
    handleAnnotationMove(touch);
}

function handleTouchEnd(event) {
    event.preventDefault();
    handleAnnotationEnd(event.changedTouches[0] || event.touches[0]);
}

function startPenDrawing(point) {
    const { currentColor, currentStrokeWidth } = window.annotationState;
    
    window.annotationState.currentPath = {
        type: 'pen',
        points: [point],
        color: currentColor,
        strokeWidth: currentStrokeWidth,
        timestamp: Date.now()
    };
}

function continuePenDrawing(point) {
    if (!window.annotationState.currentPath) return;
    
    window.annotationState.currentPath.points.push(point);
    
    // Draw the line segment
    const { ctx } = window.annotationState;
    const path = window.annotationState.currentPath;
    const points = path.points;
    
    if (points.length >= 2) {
        const prevPoint = points[points.length - 2];
        
        ctx.strokeStyle = path.color;
        ctx.lineWidth = path.strokeWidth;
        ctx.lineCap = 'round';
        ctx.lineJoin = 'round';
        
        ctx.beginPath();
        ctx.moveTo(prevPoint.x, prevPoint.y);
        ctx.lineTo(point.x, point.y);
        ctx.stroke();
    }
}

function finishPenDrawing() {
    if (window.annotationState.currentPath) {
        window.annotationState.annotations.push(window.annotationState.currentPath);
        window.annotationState.currentPath = null;
    }
}

function addArrowAnnotation(start, end) {
    const { currentColor, currentStrokeWidth } = window.annotationState;
    
    const annotation = {
        type: 'arrow',
        start: start,
        end: end,
        color: currentColor,
        strokeWidth: currentStrokeWidth,
        timestamp: Date.now()
    };
    
    window.annotationState.annotations.push(annotation);
    redrawAnnotations();
}

function addRectangleAnnotation(start, end) {
    const { currentColor, currentStrokeWidth } = window.annotationState;
    
    const annotation = {
        type: 'rectangle',
        start: start,
        end: end,
        color: currentColor,
        strokeWidth: currentStrokeWidth,
        timestamp: Date.now()
    };
    
    window.annotationState.annotations.push(annotation);
    redrawAnnotations();
}

function addCircleAnnotation(start, end) {
    const { currentColor, currentStrokeWidth } = window.annotationState;
    
    const centerX = (start.x + end.x) / 2;
    const centerY = (start.y + end.y) / 2;
    const radius = Math.sqrt(Math.pow(end.x - start.x, 2) + Math.pow(end.y - start.y, 2)) / 2;
    
    const annotation = {
        type: 'circle',
        center: { x: centerX, y: centerY },
        radius: radius,
        color: currentColor,
        strokeWidth: currentStrokeWidth,
        timestamp: Date.now()
    };
    
    window.annotationState.annotations.push(annotation);
    redrawAnnotations();
}

function addTextAnnotation(point) {
    const text = prompt('הכנס טקסט:');
    if (!text || !text.trim()) return;
    
    const { currentColor, currentStrokeWidth } = window.annotationState;
    
    const annotation = {
        type: 'text',
        position: point,
        text: text.trim(),
        color: currentColor,
        fontSize: Math.max(16, currentStrokeWidth * 4),
        timestamp: Date.now()
    };
    
    window.annotationState.annotations.push(annotation);
    redrawAnnotations();
    saveAnnotationState();
}

function drawPreviewShape(start, end) {
    const { ctx, currentTool, currentColor, currentStrokeWidth } = window.annotationState;
    
    ctx.strokeStyle = currentColor;
    ctx.lineWidth = currentStrokeWidth;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.globalAlpha = 0.7;
    
    ctx.beginPath();
    
    if (currentTool === 'arrow') {
        drawArrow(ctx, start, end);
    } else if (currentTool === 'rectangle') {
        ctx.rect(start.x, start.y, end.x - start.x, end.y - start.y);
    } else if (currentTool === 'circle') {
        const centerX = (start.x + end.x) / 2;
        const centerY = (start.y + end.y) / 2;
        const radius = Math.sqrt(Math.pow(end.x - start.x, 2) + Math.pow(end.y - start.y, 2)) / 2;
        ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
    }
    
    ctx.stroke();
    ctx.globalAlpha = 1.0;
}

function drawArrow(ctx, start, end) {
    const headLength = 20;
    const headAngle = Math.PI / 6;
    
    // Draw line
    ctx.moveTo(start.x, start.y);
    ctx.lineTo(end.x, end.y);
    
    // Calculate arrow head
    const angle = Math.atan2(end.y - start.y, end.x - start.x);
    
    // Draw arrow head
    ctx.moveTo(end.x, end.y);
    ctx.lineTo(
        end.x - headLength * Math.cos(angle - headAngle),
        end.y - headLength * Math.sin(angle - headAngle)
    );
    
    ctx.moveTo(end.x, end.y);
    ctx.lineTo(
        end.x - headLength * Math.cos(angle + headAngle),
        end.y - headLength * Math.sin(angle + headAngle)
    );
}

function redrawAnnotations() {
    const { ctx, canvas } = window.annotationState;
    
    // Clear canvas
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    
    // Draw all annotations
    window.annotationState.annotations.forEach(annotation => {
        drawAnnotation(ctx, annotation);
    });
}

function drawAnnotation(ctx, annotation) {
    ctx.strokeStyle = annotation.color;
    ctx.fillStyle = annotation.color;
    ctx.lineWidth = annotation.strokeWidth || 3;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    
    ctx.beginPath();
    
    switch (annotation.type) {
        case 'pen':
            if (annotation.points && annotation.points.length > 1) {
                ctx.moveTo(annotation.points[0].x, annotation.points[0].y);
                for (let i = 1; i < annotation.points.length; i++) {
                    ctx.lineTo(annotation.points[i].x, annotation.points[i].y);
                }
                ctx.stroke();
            }
            break;
            
        case 'arrow':
            drawArrow(ctx, annotation.start, annotation.end);
            ctx.stroke();
            break;
            
        case 'rectangle':
            ctx.rect(
                annotation.start.x,
                annotation.start.y,
                annotation.end.x - annotation.start.x,
                annotation.end.y - annotation.start.y
            );
            ctx.stroke();
            break;
            
        case 'circle':
            ctx.arc(annotation.center.x, annotation.center.y, annotation.radius, 0, 2 * Math.PI);
            ctx.stroke();
            break;
            
        case 'text':
            ctx.font = `${annotation.fontSize || 16}px Arial`;
            ctx.fillText(annotation.text, annotation.position.x, annotation.position.y);
            break;
    }
}

function loadAnnotations(annotations) {
    window.annotationState.annotations = [...annotations];
    redrawAnnotations();
}

function saveAnnotationState() {
    const { annotations, history, historyIndex } = window.annotationState;
    
    // Add current state to history
    history.splice(historyIndex + 1);
    history.push([...annotations]);
    window.annotationState.historyIndex = history.length - 1;
    
    // Limit history size
    if (history.length > 50) {
        history.shift();
        window.annotationState.historyIndex--;
    }
}

function undoAnnotation() {
    const { history, historyIndex } = window.annotationState;
    
    if (historyIndex > 0) {
        window.annotationState.historyIndex--;
        window.annotationState.annotations = [...history[window.annotationState.historyIndex]];
        redrawAnnotations();
    }
}

function redoAnnotation() {
    const { history, historyIndex } = window.annotationState;
    
    if (historyIndex < history.length - 1) {
        window.annotationState.historyIndex++;
        window.annotationState.annotations = [...history[window.annotationState.historyIndex]];
        redrawAnnotations();
    }
}

function clearAllAnnotations() {
    if (confirm('האם אתה בטוח שברצונך למחוק את כל ההערות?')) {
        window.annotationState.annotations = [];
        redrawAnnotations();
        saveAnnotationState();
    }
}

function closeAnnotationModal() {
    // Clean up event listeners
    if (window.annotationState) {
        window.removeEventListener('resize', setupAnnotationCanvas);
        window.annotationState = null;
    }
    
    closeModal(document.querySelector('.modal-overlay'));
}

function savePhotoAnnotations(photoId) {
    const textArea = document.getElementById('annotationText');
    const description = textArea ? textArea.value.trim() : '';
    
    const annotations = window.annotationState ? window.annotationState.annotations : [];
    
    const updates = {
        description: description,
        annotations: annotations,
        isAnnotated: description.length > 0 || annotations.length > 0
    };
    
    const updatedPhoto = updatePhoto(photoId, updates);
    
    if (updatedPhoto) {
        closeAnnotationModal();
        showNotification('הערות התמונה נשמרו בהצלחה!', 'success');
        updatePhotosGrid();
        updateProjectPhotoCount(updatedPhoto.projectId);
    }
}

function savePhotoDescription(photoId) {
    const textArea = document.getElementById('annotationText');
    if (!textArea) return;
    
    const description = textArea.value.trim();
    
    const updates = {
        description: description,
        isAnnotated: description.length > 0
    };
    
    const updatedPhoto = updatePhoto(photoId, updates);
    
    if (updatedPhoto) {
        closeModal(document.querySelector('.modal-overlay'));
        showNotification('תיאור התמונה נשמר בהצלחה!', 'success');
        updatePhotosGrid();
        updateProjectPhotoCount(updatedPhoto.projectId);
    }
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
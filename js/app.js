/**
 * Inspectort Pro - Professional Inspection App
 * Main Application JavaScript
 * RTL Hebrew Support | Mobile-First Design
 */

// Add this test function at the top of the file for debugging
window.testDocxLibrary = function() {
    console.log('Testing docx library...');
    
    // Check if docx is available
    if (!window.docx) {
        console.error('❌ docx library not loaded');
        return false;
    }
    
    console.log('✅ docx library is loaded');
    console.log('docx object:', window.docx);
    console.log('Available exports:', Object.keys(window.docx));
    
    // Try to create a simple document
    try {
        const { Document, Packer, Paragraph, TextRun } = window.docx;
        
        if (!Document || !Packer || !Paragraph || !TextRun) {
            console.error('❌ Required docx components missing');
            return false;
        }
        
        console.log('✅ All required docx components available');
        
        // Create a test document
        const doc = new Document({
            sections: [{
                children: [
                    new Paragraph({
                        children: [
                            new TextRun({
                                text: "Test document",
                                bold: true
                            })
                        ]
                    })
                ]
            }]
        });
        
        console.log('✅ Test document created successfully');
        
        // Try to generate blob
        Packer.toBlob(doc).then(blob => {
            console.log('✅ Blob generation successful, size:', blob.size, 'bytes');
            console.log('✅ docx library is fully functional!');
        }).catch(error => {
            console.error('❌ Blob generation failed:', error);
        });
        
        return true;
    } catch (error) {
        console.error('❌ Error testing docx library:', error);
        return false;
    }
};

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
    photos: [],
    isOnline: navigator.onLine,
    lastSyncTime: null,
    isSyncing: false
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
    
    // Network status events
    window.addEventListener('online', handleOnlineStatus);
    window.addEventListener('offline', handleOfflineStatus);
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
        let userData = null;
        
        // Try cloud authentication first
        if (window.FirebaseSync && window.FirebaseSync.isEnabled()) {
            try {
                submitBtn.textContent = 'מתחבר לענן...';
                const cloudUser = await window.FirebaseSync.signIn(email, password);
                userData = {
                    id: cloudUser.uid,
                    email: cloudUser.email,
                    name: cloudUser.displayName || email.split('@')[0],
                    cloudSync: true,
                    createdAt: new Date().toISOString()
                };
                console.log('Logged in with cloud sync:', userData.email);
                
                // Sync data from cloud
                submitBtn.textContent = 'מסנכרן נתונים...';
                await performDataSync();
                
            } catch (cloudError) {
                console.log('Cloud login failed, trying offline:', cloudError.message);
                // Fall back to local authentication
                userData = await authenticateUser(email, password);
                if (userData) {
                    userData.cloudSync = false;
                }
            }
        } else {
            // Use local authentication only
            userData = await authenticateUser(email, password);
            if (userData) {
                userData.cloudSync = false;
            }
        }
        
        if (userData) {
            appState.currentUser = userData;
            appState.isAuthenticated = true;
            
            // Save user data
            setStorageItem(STORAGE_KEYS.user, userData);
            
            const syncStatus = userData.cloudSync ? ' (מסונכרן בענן ☁️)' : ' (אופליין 📱)';
            showNotification(`ברוך הבא, ${userData.name}!` + syncStatus, 'success');
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
        
        let userData = null;
        
        // Try cloud registration first
        if (window.FirebaseSync && window.FirebaseSync.isEnabled()) {
            try {
                submitBtn.textContent = 'נרשם בענן...';
                const cloudUser = await window.FirebaseSync.signUp(email, password, name);
                userData = {
                    id: cloudUser.uid,
                    email: cloudUser.email,
                    name: name,
                    cloudSync: true,
                    createdAt: new Date().toISOString()
                };
                console.log('Registered with cloud sync:', userData.email);
            } catch (cloudError) {
                console.log('Cloud registration failed, using offline:', cloudError.message);
                // Fall back to local registration
                userData = await registerUser(name, email, password);
                if (userData) {
                    userData.cloudSync = false;
                }
            }
        } else {
            // Use local registration only
            userData = await registerUser(name, email, password);
            if (userData) {
                userData.cloudSync = false;
            }
        }
        
        if (userData) {
            appState.currentUser = userData;
            appState.isAuthenticated = true;
            
            // Save user data
            setStorageItem(STORAGE_KEYS.user, userData);
            
            const syncStatus = userData.cloudSync ? ' (מסונכרן בענן ☁️)' : ' (אופליין 📱)';
            showNotification(`ברוך הבא, ${userData.name}! נרשמת בהצלחה.` + syncStatus, 'success');
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
    
    // Add sync status to dashboard header
    addSyncStatusToUI();
    
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
            ${photo.name ? `<h4>${photo.name}</h4>` : ''}
            ${photo.description ? `<p class="photo-description">${photo.description}</p>` : ''}
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

        // Auto-sync if cloud is enabled
        autoSyncData();

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
        
        // Check storage space before processing
        const usage = getStorageUsage();
        console.log('Storage check - Used:', usage.percentage + '%', 'Available:', usage.available + 'MB');
        
        if (usage.percentage > 90) { // If storage is over 90% full
            showNotification('אחסון מלא! לא ניתן להוסיף תמונות נוספות', 'error');
            showStorageManagementModal();
            return;
        } else if (usage.percentage > 75) { // If storage is over 75% full
            showNotification('אחסון כמעט מלא! מומלץ לנקות תמונות ישנות', 'warning');
        }
        
        // Show processing notification
        showNotification('מעבד תמונה...', 'info', 2000);
        
        // Check if image needs compression for mobile
        const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
        const needsCompression = file.size > 1024 * 1024 || isMobile; // 1MB threshold or mobile
        
        if (needsCompression) {
            console.log('Compressing image for mobile/size optimization');
            compressImage(file, (compressedFile) => {
                if (compressedFile) {
                    processCompressedPhoto(compressedFile);
                } else {
                    showNotification('שגיאה בדחיסת התמונה', 'error');
                }
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
            // Get current storage usage to determine compression level
            const usage = getStorageUsage();
            let maxSize, quality;
            
            // Adjust compression based on available storage
            if (usage.available < 2) { // Less than 2MB available
                maxSize = 600; // Very aggressive compression
                quality = 0.5; // 50% quality
            } else if (usage.available < 5) { // Less than 5MB available
                maxSize = 800; // Moderate compression
                quality = 0.6; // 60% quality
            } else {
                maxSize = 1000; // Standard compression
                quality = 0.7; // 70% quality
            }
            
            // Calculate new dimensions
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
                    // Check if compressed size is still too large
                    if (blob.size > 200 * 1024) { // If still over 200KB, compress more
                        compressImageAggressively(img, file.name, callback);
                        return;
                    }
                    
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
            }, 'image/jpeg', quality);
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

function compressImageAggressively(img, fileName, callback) {
    try {
        const canvas = document.createElement('canvas');
        const ctx = canvas.getContext('2d');
        
        // Very aggressive compression - max 500px, 40% quality
        const maxSize = 500;
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
        ctx.drawImage(img, 0, 0, width, height);
        
        canvas.toBlob((blob) => {
            if (blob) {
                let compressedFile;
                try {
                    compressedFile = new File([blob], fileName, {
                        type: 'image/jpeg',
                        lastModified: Date.now()
                    });
                } catch (error) {
                    compressedFile = blob;
                    compressedFile.name = fileName;
                    compressedFile.lastModified = Date.now();
                }
                
                console.log('Image compressed aggressively:', Math.round(blob.size / 1024), 'KB');
                callback(compressedFile);
            } else {
                console.error('Failed to compress image aggressively');
                callback(null);
            }
        }, 'image/jpeg', 0.4); // 40% quality
        
    } catch (error) {
        console.error('Error in aggressive compression:', error);
        callback(null);
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
        
        // Pre-check storage space
        const usage = getStorageUsage();
        console.log('Storage usage:', usage.total, 'MB /', usage.limit, 'MB');
        
        // Estimate photo size in storage (JSON overhead ~30%)
        const estimatedSize = photoData.url ? new Blob([photoData.url]).size * 1.3 : photoData.size * 1.3;
        const estimatedSizeMB = estimatedSize / 1024 / 1024;
        
        console.log('Estimated photo storage size:', Math.round(estimatedSizeMB * 100) / 100, 'MB');
        
        // Check if we have enough space
        if (estimatedSizeMB > usage.available) {
            console.log('Not enough storage space available');
            
            // Try to clean up old photos first
            const cleanupSuccess = attemptAutomaticCleanup();
            if (!cleanupSuccess) {
                throw new Error('Not enough storage space. Available: ' + Math.round(usage.available * 100) / 100 + 'MB, Needed: ' + Math.round(estimatedSizeMB * 100) / 100 + 'MB');
            }
        }
        
        // Get current photos
        const allPhotos = JSON.parse(localStorage.getItem('inspectort_photos') || '[]');
        
        // Add new photo
        allPhotos.push(photoData);
        
        // Try to save with error handling
        try {
            const dataString = JSON.stringify(allPhotos);
            localStorage.setItem('inspectort_photos', dataString);
            console.log('Photo saved successfully to localStorage');
        } catch (saveError) {
            if (saveError.name === 'QuotaExceededError') {
                console.log('Storage quota exceeded, attempting cleanup...');
                
                // Try aggressive cleanup
                const cleanupSuccess = attemptAutomaticCleanup(true);
                if (cleanupSuccess) {
                    // Try saving again after cleanup
                    const cleanedPhotos = JSON.parse(localStorage.getItem('inspectort_photos') || '[]');
                    cleanedPhotos.push(photoData);
                    localStorage.setItem('inspectort_photos', JSON.stringify(cleanedPhotos));
                    console.log('Photo saved after cleanup');
                } else {
                    throw saveError;
                }
            } else {
                throw saveError;
            }
        }
        
        // Update app state
        appState.photos.push(photoData);
        
        // Auto-sync if cloud is enabled
        autoSyncData();
        
        console.log('Photo saved successfully');
        
        // Log project storage info
        if (photoData.projectId) {
            const projectUsage = getProjectStorageUsage(photoData.projectId);
            console.log(`Project storage: ${projectUsage.photoCount} photos, ${projectUsage.sizeInMB} MB, avg ${projectUsage.averagePhotoSize} KB per photo`);
        }
        
        return photoData;
    } catch (error) {
        console.error('Error saving photo:', error);
        
        // Handle specific errors
        if (error.name === 'QuotaExceededError' || error.message.includes('quota') || error.message.includes('storage space')) {
            showNotification('אחסון מלא! מחק תמונות ישנות כדי לפנות מקום', 'error');
            // Show storage management options
            setTimeout(() => {
                showStorageManagementModal();
            }, 2000);
        } else if (error.message.includes('too large')) {
            showNotification('התמונה גדולה מדי. נסה תמונה קטנה יותר', 'error');
        } else {
            showNotification('שגיאה בשמירת התמונה: ' + error.message, 'error');
        }
        
        return null;
    }
}

function attemptAutomaticCleanup(aggressive = false) {
    try {
        const allPhotos = JSON.parse(localStorage.getItem('inspectort_photos') || '[]');
        const currentUser = getCurrentUser();
        
        if (!currentUser || allPhotos.length === 0) {
            return false;
        }
        
        // Find photos that can be cleaned up
        const userProjects = getAllProjects();
        const userProjectIds = userProjects.map(p => p.id);
        const userPhotos = allPhotos.filter(photo => userProjectIds.includes(photo.projectId));
        
        // Sort by date (oldest first)
        userPhotos.sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));
        
        // Calculate how many photos to remove
        const targetCleanup = aggressive ? Math.max(3, Math.floor(userPhotos.length * 0.2)) : Math.min(2, Math.floor(userPhotos.length * 0.1));
        
        if (targetCleanup === 0) {
            return false;
        }
        
        // Remove oldest photos
        const photosToRemove = userPhotos.slice(0, targetCleanup);
        const photoIdsToRemove = photosToRemove.map(p => p.id);
        
        // Filter out the photos to remove
        const remainingPhotos = allPhotos.filter(photo => !photoIdsToRemove.includes(photo.id));
        
        // Save the cleaned up photos
        localStorage.setItem('inspectort_photos', JSON.stringify(remainingPhotos));
        
        // Update app state
        appState.photos = appState.photos.filter(photo => !photoIdsToRemove.includes(photo.id));
        
        console.log(`Automatically cleaned up ${photosToRemove.length} old photos`);
        
        if (aggressive) {
            showNotification(`נוקו ${photosToRemove.length} תמונות ישנות אוטומטית`, 'info');
        }
        
        return true;
    } catch (error) {
        console.error('Error in automatic cleanup:', error);
        return false;
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
        // Get all localStorage items
        const photos = localStorage.getItem('inspectort_photos') || '[]';
        const projects = localStorage.getItem('inspectort_projects') || '[]';
        const users = localStorage.getItem('inspectort_users') || '[]';
        const currentUser = localStorage.getItem('inspectort_currentUser') || '{}';
        
        // Calculate sizes
        const photosSize = new Blob([photos]).size;
        const projectsSize = new Blob([projects]).size;
        const usersSize = new Blob([users]).size;
        const currentUserSize = new Blob([currentUser]).size;
        
        const totalSize = photosSize + projectsSize + usersSize + currentUserSize;
        
        // Use more conservative limit for mobile devices
        const storageLimit = 8 * 1024 * 1024; // 8MB limit for better mobile compatibility
        
        return {
            photos: Math.round(photosSize / 1024 / 1024 * 100) / 100,
            projects: Math.round(projectsSize / 1024 / 1024 * 100) / 100,
            users: Math.round(usersSize / 1024 / 1024 * 100) / 100,
            currentUser: Math.round(currentUserSize / 1024 / 1024 * 100) / 100,
            total: Math.round(totalSize / 1024 / 1024 * 100) / 100,
            limit: 8, // 8MB total limit for mobile compatibility
            available: Math.max(0, Math.round((storageLimit - totalSize) / 1024 / 1024 * 100) / 100),
            percentage: Math.round((totalSize / storageLimit) * 100)
        };
    } catch (error) {
        console.error('Error calculating storage usage:', error);
        return { photos: 0, projects: 0, users: 0, currentUser: 0, total: 0, limit: 8, available: 8, percentage: 0 };
    }
}

function getProjectStorageUsage(projectId) {
    try {
        const allPhotos = JSON.parse(localStorage.getItem('inspectort_photos') || '[]');
        const projectPhotos = allPhotos.filter(photo => photo.projectId === projectId);
        
        const projectData = JSON.stringify(projectPhotos);
        const projectSize = new Blob([projectData]).size;
        
        return {
            photoCount: projectPhotos.length,
            sizeInMB: Math.round(projectSize / 1024 / 1024 * 100) / 100,
            averagePhotoSize: projectPhotos.length > 0 ? Math.round(projectSize / projectPhotos.length / 1024) : 0, // KB per photo
            estimatedMaxPhotos: Math.round((15 * 1024 * 1024 * 0.8) / (projectSize / projectPhotos.length || 70000)) // Estimate max photos this project can hold (80% of total storage)
        };
    } catch (error) {
        console.error('Error calculating project storage usage:', error);
        return { photoCount: 0, sizeInMB: 0, averagePhotoSize: 0, estimatedMaxPhotos: 100 };
    }
}

function showStorageManagementModal() {
    const usage = getStorageUsage();
    const userPhotos = getAllPhotos();
    
    // Sort photos by date (oldest first)
    userPhotos.sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));
    
    const oldestPhotos = userPhotos.slice(0, 5); // Show 5 oldest photos
    
    let oldestPhotosHtml = '';
    if (oldestPhotos.length > 0) {
        oldestPhotosHtml = `
            <div class="storage-oldest-photos">
                <h4>תמונות הכי ישנות (מועמדות למחיקה):</h4>
                <div class="oldest-photos-list">
                    ${oldestPhotos.map(photo => `
                        <div class="oldest-photo-item" data-photo-id="${photo.id}">
                            <img src="${photo.url}" alt="${photo.name || 'תמונה'}" style="width: 50px; height: 50px; object-fit: cover; border-radius: 4px;">
                            <div class="photo-details">
                                <div class="photo-name">${photo.name || photo.originalName || 'ללא שם'}</div>
                                <div class="photo-date">${new Date(photo.createdAt).toLocaleDateString('he-IL')}</div>
                                <div class="photo-size">${Math.round(photo.size / 1024)} KB</div>
                            </div>
                            <button class="btn btn-sm btn-danger delete-old-photo" onclick="deletePhotoFromStorage('${photo.id}')">מחק</button>
                        </div>
                    `).join('')}
                </div>
            </div>
        `;
    }
    
    const modal = createModal(
        'ניהול אחסון - אחסון מלא!',
        `<div class="storage-management-content">
            <div class="storage-usage-details">
                <h3>שימוש באחסון: ${usage.total} MB / ${usage.limit} MB (${usage.percentage}%)</h3>
                <div class="storage-progress">
                    <div class="storage-bar">
                        <div class="storage-fill" style="width: ${Math.min(usage.percentage, 100)}%; background-color: ${usage.percentage > 90 ? '#dc3545' : usage.percentage > 70 ? '#ffc107' : '#28a745'}"></div>
                    </div>
                </div>
                <div class="storage-breakdown">
                    <div class="storage-item">📷 תמונות: ${usage.photos} MB</div>
                    <div class="storage-item">📁 פרויקטים: ${usage.projects} MB</div>
                    <div class="storage-item">👤 משתמשים: ${usage.users} MB</div>
                </div>
            </div>
            
            <div class="storage-actions">
                <h4>פעולות לניקוי אחסון:</h4>
                <div class="cleanup-options">
                    <button class="btn btn-warning" onclick="cleanupOldPhotos(5)">
                        🗑️ מחק 5 תמונות הכי ישנות
                    </button>
                    <button class="btn btn-warning" onclick="cleanupOldPhotos(10)">
                        🗑️ מחק 10 תמונות הכי ישנות
                    </button>
                    <button class="btn btn-outline" onclick="compressAllPhotos()">
                        🗜️ דחס את כל התמונות (איטי)
                    </button>
                </div>
            </div>
            
            ${oldestPhotosHtml}
            
            <div class="storage-tips">
                <h4>💡 טיפים לחיסכון באחסון:</h4>
                <ul>
                    <li>צלם תמונות באיכות נמוכה יותר במכשיר</li>
                    <li>מחק תמונות שלא רלוונטיות מיד אחרי הצילום</li>
                    <li>השתמש בייצוא לקבצי Word/PDF ואז מחק תמונות ישנות</li>
                    <li>נקה פרויקטים שהושלמו</li>
                </ul>
            </div>
        </div>`,
        [
            {
                text: 'סגור',
                class: 'btn-secondary',
                action: 'closeModal(this.closest(\'.modal-overlay\'))'
            },
            {
                text: 'רענן נתונים',
                class: 'btn-primary',
                action: 'refreshStorageData()'
            }
        ]
    );
    
    showModal(modal);
}

function cleanupOldPhotos(count) {
    const userPhotos = getAllPhotos();
    
    if (userPhotos.length === 0) {
        showNotification('אין תמונות למחיקה', 'info');
        return;
    }
    
    // Sort by date (oldest first)
    userPhotos.sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));
    
    const photosToDelete = userPhotos.slice(0, Math.min(count, userPhotos.length));
    
    if (photosToDelete.length === 0) {
        showNotification('אין תמונות למחיקה', 'info');
        return;
    }
    
    // Confirm deletion
    const confirmModal = createModal(
        'אישור מחיקה',
        `האם אתה בטוח שברצונך למחוק ${photosToDelete.length} תמונות הכי ישנות?<br>
         <small>פעולה זו לא ניתנת לביטול!</small>`,
        [
            {
                text: 'ביטול',
                class: 'btn-secondary',
                action: 'closeModal(this.closest(\'.modal-overlay\'))'
            },
            {
                text: 'מחק',
                class: 'btn-danger',
                action: `confirmCleanupOldPhotos(${count})`
            }
        ]
    );
    
    showModal(confirmModal);
}

function confirmCleanupOldPhotos(count) {
    try {
        const userPhotos = getAllPhotos();
        userPhotos.sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));
        const photosToDelete = userPhotos.slice(0, Math.min(count, userPhotos.length));
        
        // Delete each photo
        let deletedCount = 0;
        photosToDelete.forEach(photo => {
            const success = deletePhoto(photo.id);
            if (success) {
                deletedCount++;
            }
        });
        
        // Close modal and show result
        closeModal(document.querySelector('.modal-overlay'));
        
        if (deletedCount > 0) {
            showNotification(`נמחקו ${deletedCount} תמונות בהצלחה`, 'success');
            
            // Update photo counts for all projects
            const projects = getAllProjects();
            projects.forEach(project => {
                updateProjectPhotoCount(project.id);
            });
            
            // Refresh UI
            if (appState.currentPage === 'project') {
                updatePhotosGrid();
            }
            updateUserStats();
            
            // Show updated storage info
            setTimeout(() => {
                const usage = getStorageUsage();
                showNotification(`אחסון פנוי: ${usage.available} MB`, 'info');
            }, 1000);
        } else {
            showNotification('לא ניתן למחוק תמונות', 'error');
        }
    } catch (error) {
        console.error('Error cleaning up photos:', error);
        showNotification('שגיאה במחיקת תמונות', 'error');
    }
}

function deletePhotoFromStorage(photoId) {
    const success = deletePhoto(photoId);
    if (success) {
        // Remove the photo item from the modal
        const photoItem = document.querySelector(`[data-photo-id="${photoId}"]`);
        if (photoItem) {
            photoItem.remove();
        }
        
        showNotification('תמונה נמחקה', 'success');
        
        // Update storage display
        setTimeout(() => {
            refreshStorageData();
        }, 500);
    } else {
        showNotification('שגיאה במחיקת התמונה', 'error');
    }
}

function refreshStorageData() {
    // Close current modal and reopen with updated data
    closeModal(document.querySelector('.modal-overlay'));
    setTimeout(() => {
        showStorageManagementModal();
    }, 300);
}

async function compressAllPhotos() {
    const userPhotos = getAllPhotos();
    
    if (userPhotos.length === 0) {
        showNotification('אין תמונות לדחיסה', 'info');
        return;
    }
    
    showNotification('מתחיל דחיסה... זה יכול לקחת זמן', 'info');
    
    // Close modal during compression
    closeModal(document.querySelector('.modal-overlay'));
    
    let compressedCount = 0;
    const totalPhotos = userPhotos.length;
    
    for (let i = 0; i < totalPhotos; i++) {
        const photo = userPhotos[i];
        
        try {
            // Show progress
            showNotification(`דוחס תמונה ${i + 1}/${totalPhotos}...`, 'info', 1000);
            
            // Create a blob from the photo URL and compress it
            const response = await fetch(photo.url);
            const blob = await response.blob();
            
            // Create a file object
            const file = new File([blob], photo.originalName || 'photo.jpg', { type: 'image/jpeg' });
            
            // Compress the file
            const compressedFile = await new Promise((resolve) => {
                compressImageAggressively(new Image(), file.name, resolve);
            });
            
            if (compressedFile && compressedFile.size < file.size) {
                // Update the photo with compressed data
                const reader = new FileReader();
                reader.onload = function(e) {
                    updatePhoto(photo.id, {
                        url: e.target.result,
                        size: compressedFile.size
                    });
                };
                reader.readAsDataURL(compressedFile);
                
                compressedCount++;
            }
            
            // Small delay to prevent browser freezing
            await new Promise(resolve => setTimeout(resolve, 100));
            
        } catch (error) {
            console.error('Error compressing photo:', photo.id, error);
        }
    }
    
    showNotification(`דחיסה הושלמה! ${compressedCount}/${totalPhotos} תמונות נדחסו`, 'success');
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

function checkExportLibraries() {
    const libraries = {
        docx: window.docx,
        jsPDF: window.jspdf,
        html2canvas: window.html2canvas,
        saveAs: window.saveAs
    };
    
    console.log('Export libraries status:');
    for (const [name, lib] of Object.entries(libraries)) {
        console.log(`${name}:`, lib ? 'LOADED' : 'NOT LOADED');
        if (lib && typeof lib === 'object') {
            console.log(`${name} properties:`, Object.keys(lib));
        }
    }
    
    return libraries;
}

function exportReport() {
    if (!appState.currentProject) {
        showNotification('יש לבחור פרויקט תחילה', 'error');
        return;
    }

    const projectPhotos = getPhotosByProject(appState.currentProject.id);
    
    if (projectPhotos.length === 0) {
        showNotification('אין תמונות בפרויקט לייצוא', 'error');
        return;
    }

    // Check library status
    checkExportLibraries();

    // Show export configuration modal
    showExportConfigModal();
}

function showExportConfigModal() {
    const project = appState.currentProject;
    const projectPhotos = getPhotosByProject(project.id);
    
    const modalContent = `
        <div class="export-config-container">
            <div class="export-summary">
                <h3>סיכום הדוח</h3>
                <div class="export-summary-details">
                    <div class="summary-item">
                        <span class="summary-label">שם הפרויקט:</span>
                        <span class="summary-value">${project.name}</span>
                    </div>
                    <div class="summary-item">
                        <span class="summary-label">מספר תמונות:</span>
                        <span class="summary-value">${projectPhotos.length}</span>
                    </div>
                    <div class="summary-item">
                        <span class="summary-label">תמונות עם הערות:</span>
                        <span class="summary-value">${projectPhotos.filter(p => p.isAnnotated).length}</span>
                    </div>
                    <div class="summary-item">
                        <span class="summary-label">תאריך יצירה:</span>
                        <span class="summary-value">${new Date(project.createdAt).toLocaleDateString('he-IL')}</span>
                    </div>
                </div>
            </div>
            
            <div class="export-config-form">
                <h3>הגדרות הדוח</h3>
                
                <div class="form-section">
                    <h4>כותרת עליונה (תופיע בכל עמוד)</h4>
                    <div class="form-group">
                        <label for="headerCompany">שם החברה:</label>
                        <input type="text" id="headerCompany" class="form-input" 
                               placeholder="הכנס שם החברה" value="איליט הנדסה">
                    </div>
                    <div class="form-group">
                        <label for="headerTitle">כותרת נוספת:</label>
                        <input type="text" id="headerTitle" class="form-input" 
                               placeholder="למשל: דוח בדיקה מקצועי" value="דוח בדיקה מקצועי">
                    </div>
                </div>
                
                <div class="form-section">
                    <h4>כותרת תחתונה (תופיע בכל עמוד)</h4>
                    <div class="form-group">
                        <label for="footerContact">פרטי קשר:</label>
                        <input type="text" id="footerContact" class="form-input" 
                               placeholder="טלפון, אימייל, כתובת" value="📞 054-6222577 | ✉️ info@company.com">
                    </div>
                    <div class="form-group">
                        <label for="footerExtra">מידע נוסף:</label>
                        <input type="text" id="footerExtra" class="form-input" 
                               placeholder="מידע נוסף לתחתית הדף" value="הזדמנות לפתרונות הנדסיים">
                    </div>
                </div>
                
                <div class="form-section">
                    <h4>הגדרות נוספות</h4>
                    <div class="form-group">
                        <label for="includeAnnotations">
                            <input type="checkbox" id="includeAnnotations" checked>
                            <span class="checkbox-label">כלול הערות וציורים על התמונות</span>
                        </label>
                    </div>
                    <div class="form-group">
                        <label for="imageQuality">איכות תמונות:</label>
                        <select id="imageQuality" class="form-select">
                            <option value="high">גבוהה (קובץ גדול יותר)</option>
                            <option value="medium" selected>בינונית (מומלץ)</option>
                            <option value="low">נמוכה (קובץ קטן)</option>
                        </select>
                    </div>
                </div>
            </div>
        </div>
    `;

    const modal = createModal(
        'יצוא דוח - הגדרות',
        modalContent,
        [
            {
                text: 'ביטול',
                class: 'btn-secondary',
                action: 'closeModal(this.closest(\'.modal-overlay\'))'
            },
            {
                text: 'יצוא Word',
                class: 'btn-primary',
                action: 'exportToWord()'
            },
            {
                text: 'יצוא PDF',
                class: 'btn-primary',
                action: 'exportToPDF()'
            }
        ]
    );

    showModal(modal);
}

function getExportConfig() {
    return {
        headerCompany: document.getElementById('headerCompany')?.value || '',
        headerTitle: document.getElementById('headerTitle')?.value || '',
        footerContact: document.getElementById('footerContact')?.value || '',
        footerExtra: document.getElementById('footerExtra')?.value || '',
        includeAnnotations: document.getElementById('includeAnnotations')?.checked || false,
        imageQuality: document.getElementById('imageQuality')?.value || 'medium'
    };
}

async function exportToWord() {
    try {
        showNotification('מכין דוח Word...', 'info');
        
        // Check if docx library is loaded
        if (!window.docx) {
            console.warn('docx library not available, using RTF fallback');
            return exportToWordRTF();
        }
        
        const config = getExportConfig();
        const project = appState.currentProject;
        const projectPhotos = getPhotosByProject(project.id);
        
        if (projectPhotos.length === 0) {
            showNotification('אין תמונות לייצוא', 'error');
            return;
        }

        // Close the config modal
        closeModal(document.querySelector('.modal-overlay'));
        
        console.log('Starting Word export with', projectPhotos.length, 'photos');
        
        // Create Word document with simpler approach
        const { Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell, Header, Footer, AlignmentType, WidthType, ImageRun } = window.docx;
        
        // Create content first
        const content = await createWordContentSimple(projectPhotos, config);
        
        const doc = new Document({
            sections: [{
                properties: {
                    page: {
                        margin: {
                            top: 1440,
                            right: 1440,
                            bottom: 1440,
                            left: 1440,
                        },
                    },
                },
                headers: {
                    default: new Header({
                        children: [
                            new Paragraph({
                                children: [
                                    new TextRun({
                                        text: config.headerCompany || 'דוח בדיקה',
                                        bold: true,
                                        size: 28,
                                    }),
                                ],
                                alignment: AlignmentType.CENTER,
                            }),
                            new Paragraph({
                                children: [
                                    new TextRun({
                                        text: config.headerTitle || '',
                                        size: 24,
                                    }),
                                ],
                                alignment: AlignmentType.CENTER,
                            }),
                            new Paragraph({
                                children: [
                                    new TextRun({
                                        text: `פרויקט: ${project.name}`,
                                        size: 20,
                                    }),
                                ],
                                alignment: AlignmentType.CENTER,
                            }),
                        ],
                    }),
                },
                footers: {
                    default: new Footer({
                        children: [
                            new Paragraph({
                                children: [
                                    new TextRun({
                                        text: config.footerContact || '',
                                        size: 20,
                                    }),
                                ],
                                alignment: AlignmentType.CENTER,
                            }),
                            new Paragraph({
                                children: [
                                    new TextRun({
                                        text: config.footerExtra || '',
                                        size: 18,
                                    }),
                                ],
                                alignment: AlignmentType.CENTER,
                            }),
                        ],
                    }),
                },
                children: content,
            }],
        });

        console.log('Document created, generating blob...');
        
        // Generate and download
        const blob = await Packer.toBlob(doc);
        const fileName = `${project.name}_דוח_${new Date().toISOString().split('T')[0]}.docx`;
        
        console.log('Blob generated, saving file...');
        
        // Check if saveAs is available
        if (typeof saveAs !== 'function') {
            console.error('saveAs function not available');
            // Fallback download method
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = fileName;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
        } else {
            saveAs(blob, fileName);
        }
        
        showNotification('דוח Word נוצר בהצלחה!', 'success');
        
    } catch (error) {
        console.error('Error exporting to Word:', error);
        console.error('Error details:', error.message, error.stack);
        
        // Fallback to RTF export
        console.warn('Falling back to RTF export');
        return exportToWordRTF();
    }
}

// Backup method: Export as RTF (Rich Text Format) which Word can open
async function exportToWordRTF() {
    try {
        showNotification('מכין דוח Word (RTF)...', 'info');
        
        const config = getExportConfig();
        const project = appState.currentProject;
        const projectPhotos = getPhotosByProject(project.id);
        
        if (projectPhotos.length === 0) {
            showNotification('אין תמונות לייצוא', 'error');
            return;
        }
        
        // Create RTF content
        let rtfContent = `{\\rtf1\\ansi\\deff0 {\\fonttbl {\\f0 Times New Roman;}}`;
        
        // Add header
        rtfContent += `\\f0\\fs28\\qc\\b ${config.headerCompany || 'דוח בדיקה'}\\b0\\par`;
        rtfContent += `\\fs24\\qc ${config.headerTitle || ''}\\par`;
        rtfContent += `\\fs20\\qc פרויקט: ${project.name}\\par\\par`;
        
        // Add title
        rtfContent += `\\fs32\\qc\\b דוח בדיקה - ${project.name}\\b0\\par`;
        rtfContent += `\\fs24\\qc תאריך: ${new Date().toLocaleDateString('he-IL')}\\par\\par`;
        
        // Add photos information
        for (let i = 0; i < projectPhotos.length; i++) {
            const photo = projectPhotos[i];
            rtfContent += `\\fs24\\b ${i + 1}. ${photo.name || 'ללא שם'}\\b0\\par`;
            rtfContent += `\\fs20 ${photo.description || 'ללא תיאור'}\\par`;
            rtfContent += `\\fs18 תאריך: ${new Date(photo.createdAt).toLocaleDateString('he-IL')}\\par\\par`;
        }
        
        // Add footer
        rtfContent += `\\fs20\\qc ${config.footerContact || ''}\\par`;
        rtfContent += `\\fs18\\qc ${config.footerExtra || ''}\\par`;
        
        rtfContent += '}';
        
        // Create and download RTF file
        const blob = new Blob([rtfContent], { type: 'application/rtf' });
        const fileName = `${project.name}_דוח_${new Date().toISOString().split('T')[0]}.rtf`;
        
        // Download file
        if (typeof saveAs !== 'function') {
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = fileName;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
        } else {
            saveAs(blob, fileName);
        }
        
        showNotification('דוח Word נוצר בהצלחה! (פורמט RTF)', 'success');
        
    } catch (error) {
        console.error('Error exporting to RTF:', error);
        showNotification('שגיאה ביצירת דוח Word', 'error');
    }
}

async function createWordContentSimple(photos, config) {
    const content = [];
    const { Paragraph, TextRun, Table, TableRow, TableCell, AlignmentType, WidthType, ImageRun, PageBreak } = window.docx;
    
    try {
        // Title page
        content.push(
            new Paragraph({
                children: [
                    new TextRun({
                        text: `דוח בדיקה - ${appState.currentProject.name}`,
                        bold: true,
                        size: 32,
                    }),
                ],
                alignment: AlignmentType.CENTER,
                spacing: { after: 400 },
            })
        );
        
        content.push(
            new Paragraph({
                children: [
                    new TextRun({
                        text: `תאריך: ${new Date().toLocaleDateString('he-IL')}`,
                        size: 24,
                    }),
                ],
                alignment: AlignmentType.CENTER,
                spacing: { after: 800 },
            })
        );

        // Process photos in pairs (2 photos per page)
        for (let i = 0; i < photos.length; i += 2) {
            const photo1 = photos[i];
            const photo2 = photos[i + 1]; // May be undefined for odd number of photos
            
            console.log(`Processing photo pair ${Math.floor(i/2) + 1}: photos ${i + 1}${photo2 ? ` and ${i + 2}` : ''}`);
            
            // Create table rows for this page
            const tableRows = [];
            
            // Process first photo
            try {
                const photo1Row = await createPhotoRow(photo1, i + 1, config);
                tableRows.push(photo1Row);
            } catch (error) {
                console.error(`Error processing photo ${i + 1}:`, error);
                tableRows.push(createErrorRow(i + 1, photo1?.name || 'ללא שם'));
            }
            
            // Process second photo if exists
            if (photo2) {
                try {
                    const photo2Row = await createPhotoRow(photo2, i + 2, config);
                    tableRows.push(photo2Row);
                } catch (error) {
                    console.error(`Error processing photo ${i + 2}:`, error);
                    tableRows.push(createErrorRow(i + 2, photo2?.name || 'ללא שם'));
                }
            }
            
            // Create table for this page with 2 photos
            const pageTable = new Table({
                width: {
                    size: 100,
                    type: WidthType.PERCENTAGE,
                },
                rows: tableRows,
            });
            
            content.push(pageTable);
            
                         // Add page break after each pair (except the last one)
             if (i + 2 < photos.length) {
                 content.push(new PageBreak());
             }
        }
        
    } catch (contentError) {
        console.error('Error creating content:', contentError);
        // Add minimal content as fallback
        content.push(
            new Paragraph({
                children: [
                    new TextRun({
                        text: 'שגיאה ביצירת תוכן הדוח',
                        color: 'FF0000',
                    }),
                ],
            })
        );
    }
    
    return content;
}

// Helper function to create a photo row with improved layout
async function createPhotoRow(photo, photoNumber, config) {
    const { Paragraph, TextRun, TableRow, TableCell, AlignmentType, WidthType, ImageRun } = window.docx;
    
    // Try to create image data with higher quality
    let imageBuffer = null;
    try {
        let imageData;
        if (config.includeAnnotations && photo.annotations && photo.annotations.length > 0) {
            imageData = await renderPhotoWithAnnotations(photo, config.imageQuality);
        } else {
            imageData = photo.url;
        }
        
        // Convert base64 to buffer
        const base64Data = imageData.split(',')[1];
        imageBuffer = Uint8Array.from(atob(base64Data), c => c.charCodeAt(0));
    } catch (imageError) {
        console.error('Error processing image:', imageError);
        imageBuffer = null;
    }
    
    // Create image content with higher resolution
    const leftCellContent = [];
    if (imageBuffer) {
        leftCellContent.push(
            new Paragraph({
                children: [
                    new ImageRun({
                        data: imageBuffer,
                        transformation: {
                            width: 380,  // Increased from 300
                            height: 285, // Increased from 225
                        },
                    }),
                ],
                alignment: AlignmentType.CENTER,
            })
        );
    } else {
        leftCellContent.push(
            new Paragraph({
                children: [
                    new TextRun({
                        text: 'שגיאה בטעינת תמונה',
                        color: 'FF0000',
                        size: 20,
                    }),
                ],
                alignment: AlignmentType.CENTER,
            })
        );
    }
    
    // Create more compact text content
    const rightCellContent = [
        new Paragraph({
            children: [
                new TextRun({
                    text: `${photoNumber}. ${photo.name || 'ללא שם'}`,
                    bold: true,
                    size: 20, // Reduced from 24
                }),
            ],
            spacing: { after: 100 }, // Reduced from 200
        }),
        new Paragraph({
            children: [
                new TextRun({
                    text: photo.description || 'ללא תיאור',
                    size: 18, // Reduced from 22
                }),
            ],
            spacing: { after: 100 }, // Reduced from 200
        }),
        new Paragraph({
            children: [
                new TextRun({
                    text: `תאריך: ${new Date(photo.createdAt).toLocaleDateString('he-IL')}`,
                    size: 16, // Reduced from 18
                    color: '666666',
                }),
            ],
        }),
    ];
    
    // Create table row with 70% image, 30% text layout
    return new TableRow({
        children: [
            new TableCell({
                children: leftCellContent,
                width: {
                    size: 70, // Increased from 50% to give more space to image
                    type: WidthType.PERCENTAGE,
                },
            }),
            new TableCell({
                children: rightCellContent,
                width: {
                    size: 30, // Reduced from 50% to make text more compact
                    type: WidthType.PERCENTAGE,
                },
            }),
        ],
    });
}

// Helper function to create error row
function createErrorRow(photoNumber, photoName) {
    const { Paragraph, TextRun, TableRow, TableCell, AlignmentType, WidthType } = window.docx;
    
    return new TableRow({
        children: [
            new TableCell({
                children: [
                    new Paragraph({
                        children: [
                            new TextRun({
                                text: `${photoNumber}. שגיאה בעיבוד תמונה: ${photoName}`,
                                color: 'FF0000',
                                size: 18,
                            }),
                        ],
                        alignment: AlignmentType.CENTER,
                    })
                ],
                width: {
                    size: 100,
                    type: WidthType.PERCENTAGE,
                },
            }),
        ],
    });
}

async function renderPhotoWithAnnotations(photo, quality) {
    return new Promise((resolve, reject) => {
        try {
            const canvas = document.createElement('canvas');
            const ctx = canvas.getContext('2d');
            const img = new Image();
            
            img.onload = function() {
                // Set canvas size based on quality with higher resolution for Word export
                const qualityScale = quality === 'high' ? 1.2 : quality === 'medium' ? 1.0 : 0.8;
                canvas.width = img.width * qualityScale;
                canvas.height = img.height * qualityScale;
                
                // Draw image
                ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
                
                // Draw annotations with proper scaling
                if (photo.annotations && photo.annotations.length > 0) {
                    // Calculate proper scale based on annotation canvas vs export canvas
                    // Annotations are stored relative to the annotation canvas size
                    // We need to scale them to match the export canvas size
                    
                    // Get the original annotation canvas dimensions if available
                    const originalCanvasWidth = photo.annotationCanvasWidth || img.width;
                    const originalCanvasHeight = photo.annotationCanvasHeight || img.height;
                    
                    // Calculate the scale factor from annotation canvas to export canvas
                    const scaleX = canvas.width / originalCanvasWidth;
                    const scaleY = canvas.height / originalCanvasHeight;
                    
                    console.log('Annotation scaling:', {
                        originalCanvas: { width: originalCanvasWidth, height: originalCanvasHeight },
                        exportCanvas: { width: canvas.width, height: canvas.height },
                        scaleX, scaleY
                    });
                    
                    photo.annotations.forEach(annotation => {
                        drawAnnotationOnCanvas(ctx, annotation, scaleX, scaleY);
                    });
                }
                
                // Convert to data URL with higher quality
                const dataURL = canvas.toDataURL('image/jpeg', 0.92);
                resolve(dataURL);
            };
            
            img.onerror = function() {
                reject(new Error('Failed to load image'));
            };
            
            img.src = photo.url;
        } catch (error) {
            reject(error);
        }
    });
}

function drawAnnotationOnCanvas(ctx, annotation, scaleX, scaleY) {
    ctx.strokeStyle = annotation.color || '#FF0000';
    ctx.lineWidth = (annotation.strokeWidth || 3) * scaleX;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    
    switch (annotation.type) {
        case 'pen':
            if (annotation.points && annotation.points.length > 1) {
                ctx.beginPath();
                ctx.moveTo(annotation.points[0].x * scaleX, annotation.points[0].y * scaleY);
                for (let i = 1; i < annotation.points.length; i++) {
                    ctx.lineTo(annotation.points[i].x * scaleX, annotation.points[i].y * scaleY);
                }
                ctx.stroke();
            }
            break;
            
        case 'arrow':
            if (annotation.start && annotation.end) {
                drawArrowOnCanvas(ctx, 
                    { x: annotation.start.x * scaleX, y: annotation.start.y * scaleY },
                    { x: annotation.end.x * scaleX, y: annotation.end.y * scaleY }
                );
            }
            break;
            
        case 'rectangle':
            if (annotation.start && annotation.end) {
                const width = (annotation.end.x - annotation.start.x) * scaleX;
                const height = (annotation.end.y - annotation.start.y) * scaleY;
                ctx.strokeRect(annotation.start.x * scaleX, annotation.start.y * scaleY, width, height);
            }
            break;
            
        case 'circle':
            if (annotation.center && annotation.radius) {
                ctx.beginPath();
                ctx.arc(annotation.center.x * scaleX, annotation.center.y * scaleY, annotation.radius * scaleX, 0, 2 * Math.PI);
                ctx.stroke();
            }
            break;
            
        case 'text':
            if (annotation.text && annotation.position) {
                ctx.font = `${(annotation.fontSize || 16) * scaleX}px Arial`;
                ctx.fillStyle = annotation.color || '#FF0000';
                ctx.fillText(annotation.text, annotation.position.x * scaleX, annotation.position.y * scaleY);
            }
            break;
    }
}

function drawArrowOnCanvas(ctx, start, end) {
    const headlen = 15;
    const dx = end.x - start.x;
    const dy = end.y - start.y;
    const angle = Math.atan2(dy, dx);
    
    // Draw line
    ctx.beginPath();
    ctx.moveTo(start.x, start.y);
    ctx.lineTo(end.x, end.y);
    ctx.stroke();
    
    // Draw arrowhead
    ctx.beginPath();
    ctx.moveTo(end.x, end.y);
    ctx.lineTo(end.x - headlen * Math.cos(angle - Math.PI / 6), end.y - headlen * Math.sin(angle - Math.PI / 6));
    ctx.moveTo(end.x, end.y);
    ctx.lineTo(end.x - headlen * Math.cos(angle + Math.PI / 6), end.y - headlen * Math.sin(angle + Math.PI / 6));
    ctx.stroke();
}

async function exportToPDF() {
    try {
        showNotification('מכין דוח PDF...', 'info');
        
        const config = getExportConfig();
        const project = appState.currentProject;
        const projectPhotos = getPhotosByProject(project.id);
        
        if (projectPhotos.length === 0) {
            showNotification('אין תמונות לייצוא', 'error');
            return;
        }

        // Close the config modal
        closeModal(document.querySelector('.modal-overlay'));
        
        // Create HTML template for PDF
        const htmlContent = await createPDFHTMLContent(project, projectPhotos, config);
        
        // Create temporary div to hold the content
        const tempDiv = document.createElement('div');
        tempDiv.innerHTML = htmlContent;
        tempDiv.style.position = 'absolute';
        tempDiv.style.left = '-9999px';
        tempDiv.style.top = '-9999px';
        tempDiv.style.width = '210mm'; // A4 width
        tempDiv.style.background = 'white';
        tempDiv.style.fontFamily = 'Arial, sans-serif';
        tempDiv.style.direction = 'rtl';
        document.body.appendChild(tempDiv);
        
        // Wait for images to load
        const images = tempDiv.querySelectorAll('img');
        const imagePromises = Array.from(images).map(img => {
            return new Promise((resolve) => {
                if (img.complete) {
                    resolve();
                } else {
                    img.onload = resolve;
                    img.onerror = resolve;
                }
            });
        });
        
        await Promise.all(imagePromises);
        
        // Generate PDF using html2canvas + jsPDF
        const { jsPDF } = window.jspdf;
        const canvas = await html2canvas(tempDiv, {
            useCORS: true,
            scale: 2,
            scrollX: 0,
            scrollY: 0,
            backgroundColor: '#ffffff'
        });
        
        // Remove temporary div
        document.body.removeChild(tempDiv);
        
        // Create PDF
        const imgData = canvas.toDataURL('image/png');
        const pdf = new jsPDF('p', 'mm', 'a4');
        
        const pageWidth = pdf.internal.pageSize.getWidth();
        const pageHeight = pdf.internal.pageSize.getHeight();
        
        // Calculate dimensions to fit page
        const canvasWidth = canvas.width;
        const canvasHeight = canvas.height;
        const ratio = canvasWidth / canvasHeight;
        
        let imgWidth = pageWidth;
        let imgHeight = pageWidth / ratio;
        
        if (imgHeight > pageHeight) {
            imgHeight = pageHeight;
            imgWidth = pageHeight * ratio;
        }
        
        // Center the image on the page
        const x = (pageWidth - imgWidth) / 2;
        const y = (pageHeight - imgHeight) / 2;
        
        pdf.addImage(imgData, 'PNG', x, y, imgWidth, imgHeight);
        
        // Save PDF
        const fileName = `${project.name}_דוח_${new Date().toISOString().split('T')[0]}.pdf`;
        pdf.save(fileName);
        
        showNotification('דוח PDF נוצר בהצלחה!', 'success');
        
    } catch (error) {
        console.error('Error exporting to PDF:', error);
        showNotification('שגיאה ביצירת דוח PDF', 'error');
    }
}

async function createPDFHTMLContent(project, photos, config) {
    let htmlContent = `
        <div style="padding: 20px; font-family: Arial, sans-serif; direction: rtl; background: white;">
            <!-- Header -->
            <div style="text-align: center; margin-bottom: 30px; border-bottom: 2px solid #2563eb; padding-bottom: 20px;">
                <h1 style="color: #2563eb; margin: 0; font-size: 24px; font-weight: bold;">
                    ${config.headerCompany || 'דוח בדיקה מקצועי'}
                </h1>
                <h2 style="color: #64748b; margin: 5px 0; font-size: 18px;">
                    ${config.headerTitle || 'מסמך טכני'}
                </h2>
                <div style="margin: 15px 0; font-size: 16px; color: #374151;">
                    <strong>פרויקט:</strong> ${project.name}
                </div>
                <div style="font-size: 14px; color: #6b7280;">
                    <strong>תאריך:</strong> ${new Date().toLocaleDateString('he-IL')}
                </div>
            </div>
            
            <!-- Project Summary -->
            <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 20px; margin-bottom: 30px;">
                <h3 style="color: #374151; margin-top: 0; font-size: 18px; border-bottom: 1px solid #d1d5db; padding-bottom: 10px;">
                    סיכום הפרויקט
                </h3>
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px; font-size: 14px;">
                    <div><strong>מספר תמונות:</strong> ${photos.length}</div>
                    <div><strong>תמונות עם הערות:</strong> ${photos.filter(p => p.isAnnotated).length}</div>
                    <div><strong>תאריך יצירה:</strong> ${new Date(project.createdAt).toLocaleDateString('he-IL')}</div>
                    <div><strong>מיקום:</strong> ${project.location || 'לא צוין'}</div>
                </div>
                ${project.description ? `<div style="margin-top: 15px;"><strong>תיאור:</strong> ${project.description}</div>` : ''}
            </div>
            
            <!-- Photos Table -->
            <div style="overflow-x: auto;">
                <table style="width: 100%; border-collapse: collapse; font-size: 14px; background: white; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">
                    <thead>
                        <tr style="background: #2563eb; color: white;">
                            <th style="padding: 15px; text-align: center; border: 1px solid #1e40af; font-weight: bold;">מס'</th>
                            <th style="padding: 15px; text-align: center; border: 1px solid #1e40af; font-weight: bold;">תמונה</th>
                            <th style="padding: 15px; text-align: center; border: 1px solid #1e40af; font-weight: bold;">שם התמונה</th>
                            <th style="padding: 15px; text-align: center; border: 1px solid #1e40af; font-weight: bold;">תיאור</th>
                            <th style="padding: 15px; text-align: center; border: 1px solid #1e40af; font-weight: bold;">תאריך</th>
                        </tr>
                    </thead>
                    <tbody>`;
    
    for (let i = 0; i < photos.length; i++) {
        const photo = photos[i];
        const rowColor = i % 2 === 0 ? '#ffffff' : '#f8fafc';
        
        try {
            // Render photo with annotations
            let imageData;
            if (config.includeAnnotations && photo.annotations && photo.annotations.length > 0) {
                imageData = await renderPhotoWithAnnotations(photo, config.imageQuality);
            } else {
                imageData = photo.url;
            }
            
            htmlContent += `
                <tr style="background: ${rowColor}; border-bottom: 1px solid #e5e7eb;">
                    <td style="padding: 15px; text-align: center; border: 1px solid #d1d5db; font-weight: bold; font-size: 16px; color: #2563eb;">
                        ${i + 1}
                    </td>
                    <td style="padding: 10px; text-align: center; border: 1px solid #d1d5db;">
                        <img src="${imageData}" 
                             style="max-width: 200px; max-height: 150px; border-radius: 4px; box-shadow: 0 1px 3px rgba(0,0,0,0.1);"
                             alt="תמונה ${i + 1}">
                    </td>
                    <td style="padding: 15px; text-align: center; border: 1px solid #d1d5db; font-weight: bold; color: #374151;">
                        ${photo.name || 'ללא שם'}
                    </td>
                    <td style="padding: 15px; text-align: right; border: 1px solid #d1d5db; color: #4b5563; line-height: 1.5;">
                        ${photo.description || 'ללא תיאור'}
                    </td>
                    <td style="padding: 15px; text-align: center; border: 1px solid #d1d5db; color: #6b7280; font-size: 12px;">
                        ${new Date(photo.createdAt).toLocaleDateString('he-IL')}
                    </td>
                </tr>`;
        } catch (error) {
            console.error('Error processing photo for PDF:', error);
            htmlContent += `
                <tr style="background: ${rowColor}; border-bottom: 1px solid #e5e7eb;">
                    <td style="padding: 15px; text-align: center; border: 1px solid #d1d5db; font-weight: bold; color: #ef4444;">
                        ${i + 1}
                    </td>
                    <td style="padding: 15px; text-align: center; border: 1px solid #d1d5db; color: #ef4444;">
                        שגיאה בטעינת תמונה
                    </td>
                    <td style="padding: 15px; text-align: center; border: 1px solid #d1d5db; color: #ef4444;">
                        ${photo.name || 'ללא שם'}
                    </td>
                    <td style="padding: 15px; text-align: right; border: 1px solid #d1d5db; color: #ef4444;">
                        שגיאה בעיבוד התמונה
                    </td>
                    <td style="padding: 15px; text-align: center; border: 1px solid #d1d5db; color: #ef4444;">
                        ${new Date(photo.createdAt).toLocaleDateString('he-IL')}
                    </td>
                </tr>`;
        }
    }
    
    htmlContent += `
                    </tbody>
                </table>
            </div>
            
            <!-- Footer -->
            <div style="margin-top: 40px; text-align: center; border-top: 2px solid #2563eb; padding-top: 20px; color: #6b7280; font-size: 12px;">
                <div style="margin-bottom: 10px;">
                    <strong>${config.footerContact || 'פרטי קשר'}</strong>
                </div>
                <div>
                    ${config.footerExtra || 'מסמך זה נוצר באמצעות מערכת Inspectort Pro'}
                </div>
                <div style="margin-top: 10px; font-size: 10px; color: #9ca3af;">
                    תאריך יצירת הדוח: ${new Date().toLocaleString('he-IL')}
                </div>
            </div>
        </div>`;
    
    return htmlContent;
}

function openPhotoAnnotation(photo) {
    const modalContent = `
        <div class="photo-annotation-container">
            <!-- Photo First - Main Focus -->
            <div class="annotation-image-container">
                <img src="${photo.url}" alt="${photo.name || 'תמונה'}" class="annotation-image" id="annotationImage">
                <canvas id="annotationCanvas" class="annotation-canvas"></canvas>
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
            
            <!-- Photo Info and Editing Below Annotation -->
            <div class="photo-edit-section">
                <div class="photo-technical-info">
                    <div class="photo-meta">
                        <span>📅 ${new Date(photo.createdAt).toLocaleDateString('he-IL')}</span>
                        <span>📏 ${formatFileSize(photo.size)}</span>
                    </div>
                </div>
                
                <div class="photo-edit-form">
                    <div class="form-group">
                        <label for="photoNameEdit">שם התמונה:</label>
                        <input type="text" id="photoNameEdit" class="photo-name-input" 
                               value="${photo.name || ''}" placeholder="הכנס שם לתמונה (אופציונלי)">
                    </div>
                    
                    <div class="form-group">
                        <label for="photoDescriptionEdit">תיאור התמונה:</label>
                        <textarea id="photoDescriptionEdit" rows="3" class="photo-description-input"
                                  placeholder="תאר את מה שנראה בתמונה או הוסף הערות...">${photo.description || ''}</textarea>
                    </div>
                </div>
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
    const nameInput = document.getElementById('photoNameEdit');
    const descriptionInput = document.getElementById('photoDescriptionEdit');
    
    const name = nameInput ? nameInput.value.trim() : '';
    const description = descriptionInput ? descriptionInput.value.trim() : '';
    
    const annotations = window.annotationState ? window.annotationState.annotations : [];
    
    // Store the annotation canvas dimensions for proper scaling during export
    const canvasWidth = window.annotationState?.canvas?.width || 0;
    const canvasHeight = window.annotationState?.canvas?.height || 0;
    
    const updates = {
        name: name,
        description: description,
        annotations: annotations,
        annotationCanvasWidth: canvasWidth,
        annotationCanvasHeight: canvasHeight,
        isAnnotated: description.length > 0 || annotations.length > 0
    };
    
    console.log('Saving annotations with canvas dimensions:', {
        annotations: annotations.length,
        canvasWidth,
        canvasHeight
    });
    
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

async function confirmLogout() {
    // Sign out from Firebase if connected
    if (appState.currentUser?.cloudSync && window.FirebaseSync) {
        try {
            await window.FirebaseSync.signOut();
            console.log('Signed out from Firebase');
        } catch (error) {
            console.error('Firebase signout error:', error);
        }
    }
    
    // Clear user data
    appState.currentUser = null;
    appState.isAuthenticated = false;
    appState.currentProject = null;
    appState.lastSyncTime = null;
    
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

/**
 * Cloud Sync Functions
 */
async function performDataSync() {
    if (!window.FirebaseSync || !window.FirebaseSync.isEnabled()) {
        console.log('Firebase not available for sync');
        return { success: false, message: 'Cloud sync not available' };
    }
    
    if (appState.isSyncing) {
        console.log('Sync already in progress');
        return { success: false, message: 'Sync already in progress' };
    }
    
    try {
        appState.isSyncing = true;
        console.log('Starting data sync...');
        
        const syncResult = await window.FirebaseSync.performFullSync();
        
        if (syncResult.success) {
            appState.lastSyncTime = new Date().toISOString();
            
            // Reload data after sync
            await loadSavedData();
            
            // Update UI
            if (appState.currentPage === 'dashboard') {
                updateDashboardContent();
            } else if (appState.currentPage === 'project') {
                updateProjectContent();
            }
            
            console.log('Data sync completed successfully');
            showNotification(`סנכרון הושלם: ${syncResult.projects} פרויקטים, ${syncResult.photos} תמונות`, 'success');
        } else {
            showNotification('שגיאה בסנכרון: ' + syncResult.message, 'error');
        }
        
        return syncResult;
    } catch (error) {
        console.error('Data sync failed:', error);
        showNotification('שגיאה בסנכרון: ' + error.message, 'error');
        return { success: false, message: error.message };
    } finally {
        appState.isSyncing = false;
    }
}

/**
 * Auto-sync when projects or photos are created/updated
 */
async function autoSyncData() {
    if (!window.FirebaseSync || !window.FirebaseSync.isEnabled() || !appState.currentUser?.cloudSync) {
        return;
    }
    
    if (appState.isSyncing) {
        return;
    }
    
    try {
        console.log('Auto-syncing data...');
        await window.FirebaseSync.syncProjects(appState.projects);
        await window.FirebaseSync.syncPhotos(appState.photos);
        appState.lastSyncTime = new Date().toISOString();
        console.log('Auto-sync completed');
    } catch (error) {
        console.error('Auto-sync failed:', error);
    }
}

/**
 * Network status handlers
 */
function handleOnlineStatus() {
    appState.isOnline = true;
    console.log('Network: Online');
    showNotification('חזרת לאינטרנט ☁️', 'success', 2000);
    
    if (appState.currentUser?.cloudSync) {
        // Auto-sync when coming back online
        setTimeout(() => {
            performDataSync();
        }, 1000);
    }
}

function handleOfflineStatus() {
    appState.isOnline = false;
    console.log('Network: Offline');
    showNotification('עבדת אופליין 📱', 'info', 2000);
}

/**
 * Add sync status to dashboard UI
 */
function addSyncStatusToUI() {
    const dashboardHeader = document.querySelector('.dashboard-header');
    if (!dashboardHeader) return;
    
    // Remove existing sync status
    const existingSyncStatus = dashboardHeader.querySelector('.sync-status');
    if (existingSyncStatus) {
        existingSyncStatus.remove();
    }
    
    // Only show sync status if user is cloud-enabled
    if (!appState.currentUser?.cloudSync) {
        return;
    }
    
    const syncStatus = document.createElement('div');
    syncStatus.className = 'sync-status';
    
    const lastSync = appState.lastSyncTime ? 
        new Date(appState.lastSyncTime).toLocaleString('he-IL', {
            hour: '2-digit',
            minute: '2-digit',
            day: '2-digit',
            month: '2-digit'
        }) : 
        'מעולם לא';
    
    const status = appState.isSyncing ? 
        '🔄 מסנכרן...' : 
        appState.isOnline ? 
            `☁️ מסונכרן (${lastSync})` : 
            '📱 אופליין';
    
    syncStatus.innerHTML = `
        <div class="sync-indicator">
            <span class="sync-text">${status}</span>
            ${appState.currentUser?.cloudSync && !appState.isSyncing && appState.isOnline ? 
                '<button class="sync-btn" onclick="performDataSync()" title="סנכרן עכשיו">🔄</button>' : ''}
        </div>
    `;
    
    dashboardHeader.appendChild(syncStatus);
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
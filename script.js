// Inspectort Pro - JavaScript Functionality

class InspectortApp {
    constructor() {
        this.currentPage = 'authPage';
        this.currentUser = null;
        this.projects = [];
        this.currentProject = null;
        this.currentPhoto = null;
        this.annotationTool = 'arrow';
        this.annotationColor = '#FF3B30';
        this.isDrawing = false;
        this.lastX = 0;
        this.lastY = 0;

        this.initializeApp();
    }

    initializeApp() {
        this.loadDataFromStorage();
        this.setupEventListeners();
        this.updateNavigation();
        this.checkAuthStatus();
    }

    // Data Management
    loadDataFromStorage() {
        const userData = localStorage.getItem('inspectort_user');
        if (userData) {
            this.currentUser = JSON.parse(userData);
        }

        const projectsData = localStorage.getItem('inspectort_projects');
        if (projectsData) {
            this.projects = JSON.parse(projectsData);
        }
    }

    saveDataToStorage() {
        if (this.currentUser) {
            localStorage.setItem('inspectort_user', JSON.stringify(this.currentUser));
        }
        localStorage.setItem('inspectort_projects', JSON.stringify(this.projects));
    }

    // Authentication
    checkAuthStatus() {
        if (this.currentUser) {
            this.showPage('dashboardPage');
            this.updateUserInterface();
        } else {
            this.showPage('authPage');
        }
    }

    login(email, password) {
        // Simulate authentication
        if (email && password) {
            this.currentUser = {
                id: Date.now(),
                email: email,
                name: email.split('@')[0],
                createdAt: new Date().toISOString()
            };
            this.saveDataToStorage();
            this.updateUserInterface();
            this.showPage('dashboardPage');
            this.showSuccess('Welcome back!');
        } else {
            this.showError('Please enter valid credentials');
        }
    }

    register(name, email, password, confirmPassword) {
        if (password !== confirmPassword) {
            this.showError('Passwords do not match');
            return;
        }

        if (name && email && password) {
            this.currentUser = {
                id: Date.now(),
                name: name,
                email: email,
                createdAt: new Date().toISOString()
            };
            this.saveDataToStorage();
            this.updateUserInterface();
            this.showPage('dashboardPage');
            this.showSuccess('Account created successfully!');
        } else {
            this.showError('Please fill in all fields');
        }
    }

    logout() {
        this.currentUser = null;
        this.currentProject = null;
        this.projects = [];
        localStorage.removeItem('inspectort_user');
        localStorage.removeItem('inspectort_projects');
        this.showPage('authPage');
        this.showSuccess('Logged out successfully');
    }

    // Navigation
    showPage(pageId) {
        // Hide all pages
        document.querySelectorAll('.page').forEach(page => {
            page.classList.remove('active', 'slide-left');
        });

        // Show target page
        const targetPage = document.getElementById(pageId);
        if (targetPage) {
            targetPage.classList.add('active');
            this.currentPage = pageId;
            this.updateNavigation();
        }
    }

    updateNavigation() {
        const navBar = document.getElementById('navBar');
        const navTitle = document.getElementById('navTitle');
        const backBtn = document.getElementById('backBtn');
        const actionBtn = document.getElementById('actionBtn');

        // Reset action button
        actionBtn.innerHTML = '';
        actionBtn.className = 'nav-btn action-btn';

        switch (this.currentPage) {
            case 'authPage':
                navBar.style.display = 'none';
                break;
            case 'dashboardPage':
                navBar.style.display = 'block';
                navTitle.textContent = 'Projects';
                backBtn.classList.add('hidden');
                actionBtn.classList.add('hidden');
                break;
            case 'projectPage':
                navBar.style.display = 'block';
                navTitle.textContent = this.currentProject ? this.currentProject.name : 'Project';
                backBtn.classList.remove('hidden');
                actionBtn.classList.add('hidden');
                break;
            case 'exportPage':
                navBar.style.display = 'block';
                navTitle.textContent = 'Export Report';
                backBtn.classList.remove('hidden');
                actionBtn.classList.add('hidden');
                break;
        }
    }

    goBack() {
        switch (this.currentPage) {
            case 'projectPage':
                this.showPage('dashboardPage');
                break;
            case 'exportPage':
                this.showPage('projectPage');
                break;
            default:
                this.showPage('dashboardPage');
        }
    }

    // Project Management
    createProject(name) {
        if (!name) name = `Project ${this.projects.length + 1}`;
        
        const project = {
            id: Date.now(),
            name: name,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
            photos: [],
            userId: this.currentUser.id
        };

        this.projects.push(project);
        this.saveDataToStorage();
        this.updateProjectsList();
        this.showSuccess('Project created successfully!');
        return project;
    }

    openProject(projectId) {
        const project = this.projects.find(p => p.id === projectId);
        if (project) {
            this.currentProject = project;
            this.updateProjectInterface();
            this.showPage('projectPage');
        }
    }

    deleteProject(projectId) {
        if (confirm('Are you sure you want to delete this project?')) {
            this.projects = this.projects.filter(p => p.id !== projectId);
            this.saveDataToStorage();
            this.updateProjectsList();
            this.showSuccess('Project deleted successfully');
        }
    }

    updateProjectInterface() {
        if (!this.currentProject) return;

        document.getElementById('projectTitle').textContent = this.currentProject.name;
        document.getElementById('projectDate').textContent = 
            `Created ${this.formatDate(this.currentProject.createdAt)}`;
        
        this.updatePhotosList();
    }

    updateProjectsList() {
        const projectsGrid = document.getElementById('projectsGrid');
        const emptyState = document.getElementById('emptyState');
        const projectCount = document.getElementById('projectCount');

        if (this.projects.length === 0) {
            projectsGrid.style.display = 'none';
            emptyState.style.display = 'block';
            projectCount.textContent = '0 projects';
        } else {
            projectsGrid.style.display = 'grid';
            emptyState.style.display = 'none';
            projectCount.textContent = `${this.projects.length} project${this.projects.length !== 1 ? 's' : ''}`;

            projectsGrid.innerHTML = this.projects.map(project => `
                <div class="project-card" data-project-id="${project.id}">
                    <div class="project-card-header">
                        <div>
                            <h4 class="project-card-title">${project.name}</h4>
                            <p class="project-card-date">${this.formatDate(project.createdAt)}</p>
                        </div>
                        <div class="project-actions">
                            <button class="icon-btn delete-project" data-project-id="${project.id}">
                                <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                                    <path d="M2 4H14M5 4V2.5A1.5 1.5 0 016.5 1H9.5A1.5 1.5 0 0111 2.5V4M6 7V12M10 7V12M3 4L4 13H12L13 4" stroke="currentColor" stroke-width="1.5"/>
                                </svg>
                            </button>
                        </div>
                    </div>
                    <div class="project-card-stats">
                        <div class="stat-item">
                            <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                                <rect x="2" y="2" width="12" height="12" rx="2" stroke="currentColor" stroke-width="1.5"/>
                                <circle cx="6" cy="6" r="1" fill="currentColor"/>
                                <path d="M11 11L8 8L5 11" stroke="currentColor" stroke-width="1.5"/>
                            </svg>
                            ${project.photos.length} photos
                        </div>
                    </div>
                </div>
            `).join('');
        }
    }

    // Photo Management
    async capturePhoto() {
        try {
            const stream = await navigator.mediaDevices.getUserMedia({ 
                video: { facingMode: 'environment' } 
            });
            
            const video = document.getElementById('cameraVideo');
            const canvas = document.getElementById('cameraCanvas');
            const ctx = canvas.getContext('2d');

            video.srcObject = stream;
            video.classList.remove('hidden');
            
            await new Promise(resolve => {
                video.onloadedmetadata = () => {
                    video.play();
                    resolve();
                };
            });

            // Show capture button
            const captureBtn = document.getElementById('captureBtn');
            captureBtn.textContent = 'Capture';
            captureBtn.onclick = () => {
                canvas.width = video.videoWidth;
                canvas.height = video.videoHeight;
                ctx.drawImage(video, 0, 0);
                
                canvas.toBlob(blob => {
                    this.processPhoto(blob);
                    stream.getTracks().forEach(track => track.stop());
                    video.classList.add('hidden');
                    captureBtn.textContent = 'Take Photo';
                    captureBtn.onclick = () => this.capturePhoto();
                });
            };

        } catch (error) {
            console.error('Camera access denied:', error);
            this.showError('Camera access denied. Please use the upload option.');
        }
    }

    handleFileUpload(files) {
        Array.from(files).forEach(file => {
            if (file.type.startsWith('image/')) {
                this.processPhoto(file);
            }
        });
    }

    processPhoto(file) {
        const reader = new FileReader();
        reader.onload = (e) => {
            const photo = {
                id: Date.now() + Math.random(),
                url: e.target.result,
                name: `Photo ${this.currentProject.photos.length + 1}`,
                description: '',
                annotations: [],
                createdAt: new Date().toISOString()
            };

            this.currentProject.photos.push(photo);
            this.currentProject.updatedAt = new Date().toISOString();
            this.saveDataToStorage();
            this.updatePhotosList();
            this.showSuccess('Photo added successfully!');
        };
        reader.readAsDataURL(file);
    }

    updatePhotosList() {
        if (!this.currentProject) return;

        const photosGrid = document.getElementById('photosGrid');
        const photoCount = document.getElementById('photoCount');
        
        photoCount.textContent = `${this.currentProject.photos.length} photo${this.currentProject.photos.length !== 1 ? 's' : ''}`;

        if (this.currentProject.photos.length === 0) {
            photosGrid.innerHTML = '<p class="text-center" style="color: var(--text-tertiary); grid-column: 1 / -1;">No photos yet</p>';
        } else {
            photosGrid.innerHTML = this.currentProject.photos.map(photo => `
                <div class="photo-item" data-photo-id="${photo.id}">
                    <img src="${photo.url}" alt="${photo.name}">
                    <div class="photo-overlay">
                        <div class="photo-info">
                            <div>${photo.name}</div>
                            ${photo.description ? `<div style="font-size: 11px; opacity: 0.8;">${photo.description}</div>` : ''}
                        </div>
                    </div>
                </div>
            `).join('');
        }
    }

    // Annotation System
    openAnnotationModal(photoId) {
        const photo = this.currentProject.photos.find(p => p.id == photoId);
        if (!photo) return;

        this.currentPhoto = photo;
        const modal = document.getElementById('annotationModal');
        const canvas = document.getElementById('annotationCanvas');
        const ctx = canvas.getContext('2d');

        // Load image
        const img = new Image();
        img.onload = () => {
            canvas.width = img.width;
            canvas.height = img.height;
            ctx.drawImage(img, 0, 0);

            // Draw existing annotations
            this.redrawAnnotations(ctx);
        };
        img.src = photo.url;

        // Set description
        document.getElementById('photoDescription').value = photo.description || '';

        // Show modal
        modal.classList.add('visible');
    }

    closeAnnotationModal() {
        const modal = document.getElementById('annotationModal');
        modal.classList.remove('visible');
        this.currentPhoto = null;
    }

    setupAnnotationCanvas() {
        const canvas = document.getElementById('annotationCanvas');
        const ctx = canvas.getContext('2d');

        canvas.addEventListener('mousedown', (e) => this.startDrawing(e, ctx));
        canvas.addEventListener('mousemove', (e) => this.draw(e, ctx));
        canvas.addEventListener('mouseup', () => this.stopDrawing());
        canvas.addEventListener('mouseout', () => this.stopDrawing());

        // Touch events for mobile
        canvas.addEventListener('touchstart', (e) => {
            e.preventDefault();
            const touch = e.touches[0];
            const rect = canvas.getBoundingClientRect();
            const mouseEvent = new MouseEvent('mousedown', {
                clientX: touch.clientX,
                clientY: touch.clientY
            });
            canvas.dispatchEvent(mouseEvent);
        });

        canvas.addEventListener('touchmove', (e) => {
            e.preventDefault();
            const touch = e.touches[0];
            const mouseEvent = new MouseEvent('mousemove', {
                clientX: touch.clientX,
                clientY: touch.clientY
            });
            canvas.dispatchEvent(mouseEvent);
        });

        canvas.addEventListener('touchend', (e) => {
            e.preventDefault();
            const mouseEvent = new MouseEvent('mouseup', {});
            canvas.dispatchEvent(mouseEvent);
        });
    }

    startDrawing(e, ctx) {
        this.isDrawing = true;
        const rect = e.target.getBoundingClientRect();
        this.lastX = e.clientX - rect.left;
        this.lastY = e.clientY - rect.top;

        ctx.beginPath();
        ctx.moveTo(this.lastX, this.lastY);
    }

    draw(e, ctx) {
        if (!this.isDrawing) return;

        const rect = e.target.getBoundingClientRect();
        const currentX = e.clientX - rect.left;
        const currentY = e.clientY - rect.top;

        ctx.globalCompositeOperation = 'source-over';
        ctx.strokeStyle = this.annotationColor;
        ctx.lineWidth = 3;
        ctx.lineCap = 'round';
        ctx.lineJoin = 'round';

        if (this.annotationTool === 'arrow') {
            ctx.lineTo(currentX, currentY);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(currentX, currentY);
        }

        this.lastX = currentX;
        this.lastY = currentY;
    }

    stopDrawing() {
        this.isDrawing = false;
    }

    redrawAnnotations(ctx) {
        if (!this.currentPhoto || !this.currentPhoto.annotations) return;

        this.currentPhoto.annotations.forEach(annotation => {
            ctx.strokeStyle = annotation.color;
            ctx.lineWidth = annotation.width || 3;
            ctx.lineCap = 'round';
            ctx.lineJoin = 'round';

            ctx.beginPath();
            annotation.points.forEach((point, index) => {
                if (index === 0) {
                    ctx.moveTo(point.x, point.y);
                } else {
                    ctx.lineTo(point.x, point.y);
                }
            });
            ctx.stroke();
        });
    }

    saveAnnotation() {
        if (!this.currentPhoto) return;

        const canvas = document.getElementById('annotationCanvas');
        const description = document.getElementById('photoDescription').value;

        // Save annotated image
        this.currentPhoto.url = canvas.toDataURL();
        this.currentPhoto.description = description;
        this.currentProject.updatedAt = new Date().toISOString();

        this.saveDataToStorage();
        this.updatePhotosList();
        this.closeAnnotationModal();
        this.showSuccess('Annotation saved successfully!');
    }

    // Export Functionality
    generateReport() {
        if (!this.currentProject || this.currentProject.photos.length === 0) {
            this.showError('No photos to export');
            return;
        }

        this.showPage('exportPage');
        this.updateReportPreview();
    }

    updateReportPreview() {
        const previewContent = document.getElementById('previewContent');
        const previewTitle = document.getElementById('previewTitle');
        const currentDate = document.querySelector('.current-date');
        const inspectorName = document.querySelector('.inspector-name');

        previewTitle.textContent = this.currentProject.name;
        currentDate.textContent = this.formatDate(new Date().toISOString());
        inspectorName.textContent = this.currentUser.name;

        previewContent.innerHTML = this.currentProject.photos.map((photo, index) => `
            <div class="preview-photo" style="margin-bottom: 24px; page-break-inside: avoid;">
                <h5 style="font-size: 16px; font-weight: 600; margin-bottom: 8px;">Photo ${index + 1}</h5>
                <img src="${photo.url}" alt="${photo.name}" style="width: 100%; max-width: 300px; border-radius: 8px; margin-bottom: 8px;">
                ${photo.description ? `<p style="font-size: 14px; color: var(--text-secondary); margin-bottom: 16px;">${photo.description}</p>` : ''}
            </div>
        `).join('');
    }

    async exportAsWord() {
        this.showLoading('Generating Word document...');
        
        // Simulate export process
        await new Promise(resolve => setTimeout(resolve, 2000));
        
        const content = this.generateReportContent();
        const blob = new Blob([content], { type: 'text/html' });
        this.downloadFile(blob, `${this.currentProject.name}_report.html`);
        
        this.hideLoading();
        this.showSuccess('Report generated successfully!');
    }

    async exportAsPDF() {
        this.showLoading('Generating PDF...');
        
        // Simulate export process
        await new Promise(resolve => setTimeout(resolve, 2000));
        
        const content = this.generateReportContent();
        const blob = new Blob([content], { type: 'text/html' });
        this.downloadFile(blob, `${this.currentProject.name}_report.html`);
        
        this.hideLoading();
        this.showSuccess('Report generated successfully!');
    }

    generateReportContent() {
        // Generate HTML content for export
        return `
            <!DOCTYPE html>
            <html>
            <head>
                <title>${this.currentProject.name} - Inspection Report</title>
                <style>
                    body { font-family: Arial, sans-serif; margin: 40px; }
                    .header { text-align: center; margin-bottom: 40px; }
                    .photo-section { margin-bottom: 30px; page-break-inside: avoid; }
                    .photo-section img { max-width: 100%; height: auto; margin: 10px 0; }
                    .description { margin-top: 10px; padding: 10px; background: #f5f5f5; border-radius: 5px; }
                </style>
            </head>
            <body>
                <div class="header">
                    <h1>${this.currentProject.name}</h1>
                    <p>Inspector: ${this.currentUser.name}</p>
                    <p>Generated: ${this.formatDate(new Date().toISOString())}</p>
                </div>
                ${this.currentProject.photos.map((photo, index) => `
                    <div class="photo-section">
                        <h3>Photo ${index + 1}</h3>
                        <img src="${photo.url}" alt="${photo.name}">
                        ${photo.description ? `<div class="description">${photo.description}</div>` : ''}
                    </div>
                `).join('')}
            </body>
            </html>
        `;
    }

    downloadFile(blob, filename) {
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    }

    shareByEmail() {
        const subject = encodeURIComponent(`Inspection Report: ${this.currentProject.name}`);
        const body = encodeURIComponent(`Please find attached the inspection report for ${this.currentProject.name}.`);
        window.open(`mailto:?subject=${subject}&body=${body}`);
    }

    // UI Helpers
    updateUserInterface() {
        if (this.currentUser) {
            document.getElementById('userName').textContent = this.currentUser.name;
            this.updateProjectsList();
        }
    }

    showSuccess(message) {
        this.showNotification(message, 'success');
    }

    showError(message) {
        this.showNotification(message, 'error');
    }

    showNotification(message, type = 'info') {
        const notification = document.createElement('div');
        notification.className = `notification ${type}`;
        notification.textContent = message;
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            left: 50%;
            transform: translateX(-50%);
            background: ${type === 'success' ? '#34C759' : type === 'error' ? '#FF3B30' : '#007AFF'};
            color: white;
            padding: 12px 24px;
            border-radius: 12px;
            font-weight: 500;
            z-index: 4000;
            animation: slideInOut 3s ease-in-out;
        `;

        document.body.appendChild(notification);
        setTimeout(() => notification.remove(), 3000);
    }

    showLoading(message = 'Loading...') {
        const overlay = document.getElementById('loadingOverlay');
        const text = document.querySelector('.loading-text');
        text.textContent = message;
        overlay.classList.add('visible');
    }

    hideLoading() {
        const overlay = document.getElementById('loadingOverlay');
        overlay.classList.remove('visible');
    }

    formatDate(dateString) {
        const date = new Date(dateString);
        const now = new Date();
        const diffTime = Math.abs(now - date);
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

        if (diffDays === 1) return 'Today';
        if (diffDays === 2) return 'Yesterday';
        if (diffDays <= 7) return `${diffDays} days ago`;
        
        return date.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
        });
    }

    // Event Listeners
    setupEventListeners() {
        // Authentication
        document.getElementById('loginBtn').addEventListener('click', () => {
            const email = document.getElementById('loginEmail').value;
            const password = document.getElementById('loginPassword').value;
            this.login(email, password);
        });

        document.getElementById('registerBtn').addEventListener('click', () => {
            const name = document.getElementById('registerName').value;
            const email = document.getElementById('registerEmail').value;
            const password = document.getElementById('registerPassword').value;
            const confirmPassword = document.getElementById('confirmPassword').value;
            this.register(name, email, password, confirmPassword);
        });

        document.getElementById('showRegister').addEventListener('click', () => {
            document.getElementById('loginForm').classList.add('hidden');
            document.getElementById('registerForm').classList.remove('hidden');
        });

        document.getElementById('showLogin').addEventListener('click', () => {
            document.getElementById('registerForm').classList.add('hidden');
            document.getElementById('loginForm').classList.remove('hidden');
        });

        // Navigation
        document.getElementById('backBtn').addEventListener('click', () => this.goBack());

        // Project Management
        document.getElementById('newProjectBtn').addEventListener('click', () => {
            const name = prompt('Enter project name:');
            if (name) {
                const project = this.createProject(name);
                this.openProject(project.id);
            }
        });

        document.getElementById('createFirstProject').addEventListener('click', () => {
            const project = this.createProject();
            this.openProject(project.id);
        });

        // Delegate event listener for project cards
        document.addEventListener('click', (e) => {
            if (e.target.closest('.project-card') && !e.target.closest('.delete-project')) {
                const projectId = parseInt(e.target.closest('.project-card').dataset.projectId);
                this.openProject(projectId);
            }
            
            if (e.target.closest('.delete-project')) {
                const projectId = parseInt(e.target.closest('.delete-project').dataset.projectId);
                this.deleteProject(projectId);
            }

            if (e.target.closest('.photo-item')) {
                const photoId = e.target.closest('.photo-item').dataset.photoId;
                this.openAnnotationModal(photoId);
            }
        });

        // Photo Capture
        document.getElementById('captureBtn').addEventListener('click', () => this.capturePhoto());
        document.getElementById('uploadBtn').addEventListener('click', () => {
            document.getElementById('fileInput').click();
        });

        document.getElementById('fileInput').addEventListener('change', (e) => {
            this.handleFileUpload(e.target.files);
        });

        // Project Editing
        document.getElementById('editProjectBtn').addEventListener('click', () => {
            const titleElement = document.getElementById('projectTitle');
            const editElement = document.getElementById('projectTitleEdit');
            const btn = document.getElementById('editProjectBtn');

            if (btn.textContent === 'Edit') {
                titleElement.style.display = 'none';
                editElement.style.display = 'block';
                editElement.value = this.currentProject.name;
                editElement.focus();
                btn.textContent = 'Save';
            } else {
                const newName = editElement.value.trim();
                if (newName) {
                    this.currentProject.name = newName;
                    this.currentProject.updatedAt = new Date().toISOString();
                    this.saveDataToStorage();
                    titleElement.textContent = newName;
                    this.updateNavigation();
                    this.showSuccess('Project name updated');
                }
                titleElement.style.display = 'block';
                editElement.style.display = 'none';
                btn.textContent = 'Edit';
            }
        });

        // Annotation Modal
        document.getElementById('closeAnnotation').addEventListener('click', () => this.closeAnnotationModal());
        document.getElementById('cancelAnnotation').addEventListener('click', () => this.closeAnnotationModal());
        document.getElementById('saveAnnotation').addEventListener('click', () => this.saveAnnotation());

        // Annotation Tools
        document.querySelectorAll('.tool-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                document.querySelectorAll('.tool-btn').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                this.annotationTool = btn.dataset.tool;
            });
        });

        document.querySelectorAll('.color-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                document.querySelectorAll('.color-btn').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                this.annotationColor = btn.dataset.color;
            });
        });

        // Export
        document.getElementById('exportBtn').addEventListener('click', () => this.generateReport());
        document.getElementById('exportWordBtn').addEventListener('click', () => this.exportAsWord());
        document.getElementById('exportPdfBtn').addEventListener('click', () => this.exportAsPDF());
        document.getElementById('shareEmailBtn').addEventListener('click', () => this.shareByEmail());
        document.getElementById('shareDownloadBtn').addEventListener('click', () => this.exportAsPDF());

        // Setup annotation canvas
        this.setupAnnotationCanvas();

        // Close modal when clicking outside
        document.addEventListener('click', (e) => {
            if (e.target.classList.contains('modal')) {
                this.closeAnnotationModal();
            }
        });

        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                this.closeAnnotationModal();
            }
        });
    }
}

// Initialize the app
document.addEventListener('DOMContentLoaded', () => {
    new InspectortApp();
});

// Add CSS animation for notifications
const style = document.createElement('style');
style.textContent = `
    @keyframes slideInOut {
        0% { transform: translateX(-50%) translateY(-20px); opacity: 0; }
        10% { transform: translateX(-50%) translateY(0); opacity: 1; }
        90% { transform: translateX(-50%) translateY(0); opacity: 1; }
        100% { transform: translateX(-50%) translateY(-20px); opacity: 0; }
    }
`;
document.head.appendChild(style); 
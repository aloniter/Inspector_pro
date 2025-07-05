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
        this.cameraStream = null;

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
        // Clean up current page
        if (this.currentPage === 'projectPage') {
            this.closeCameraModal(); // Close camera modal if active when leaving project page
        }

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
            // Check if camera is available
            if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
                this.showError('Camera not supported on this device. Please use the upload option.');
                return;
            }
            
            this.showCameraModal();
        } catch (error) {
            console.error('Camera initialization error:', error);
            this.showCameraPermissionModal();
        }
    }

    async showCameraModal() {
        try {
            // Create camera modal
            const modal = document.createElement('div');
            modal.className = 'camera-modal';
            modal.innerHTML = `
                <div class="camera-modal-content">
                    <div class="camera-header">
                        <button class="camera-close-btn" id="closeCameraModal">
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                                <path d="M18 6L6 18M6 6L18 18" stroke="currentColor" stroke-width="2"/>
                            </svg>
                        </button>
                        <h3>Take Photo</h3>
                        <div style="width: 24px;"></div>
                    </div>
                    <div class="camera-preview">
                        <video id="cameraVideoModal" autoplay playsinline muted webkit-playsinline></video>
                        <canvas id="cameraCanvasModal" style="display: none;"></canvas>
                    </div>
                    <div class="camera-controls">
                        <button class="camera-capture-btn" id="cameraCaptureBtn">
                            <div class="capture-circle">
                                <div class="capture-inner"></div>
                            </div>
                        </button>
                    </div>
                </div>
            `;
            
            document.body.appendChild(modal);
            
            // iOS Safari specific camera stream settings
            const constraints = {
                video: {
                    facingMode: 'environment',
                    width: { ideal: 1920, max: 1920 },
                    height: { ideal: 1080, max: 1080 }
                },
                audio: false
            };
            
            // Get camera stream with iOS compatibility
            const stream = await navigator.mediaDevices.getUserMedia(constraints);
            
            this.cameraStream = stream;
            const video = document.getElementById('cameraVideoModal');
            video.srcObject = stream;
            
            // iOS Safari requires explicit play call
            video.setAttribute('autoplay', '');
            video.setAttribute('playsinline', '');
            video.setAttribute('webkit-playsinline', '');
            video.muted = true;
            
            // Wait for video to be ready with iOS-specific handling
            await new Promise((resolve, reject) => {
                video.onloadedmetadata = () => {
                    video.play().then(() => {
                        resolve();
                    }).catch(reject);
                };
                video.onerror = reject;
            });
            
            // Show modal with animation
            setTimeout(() => modal.classList.add('visible'), 10);
            
            // Setup event listeners with iOS-specific handling
            document.getElementById('closeCameraModal').addEventListener('click', () => this.closeCameraModal());
            document.getElementById('cameraCaptureBtn').addEventListener('click', () => this.capturePhotoFromModal());
            
            // Handle modal background click
            modal.addEventListener('click', (e) => {
                if (e.target === modal) {
                    this.closeCameraModal();
                }
            });
            
            // Prevent iOS zoom on double tap
            modal.addEventListener('touchstart', (e) => {
                e.preventDefault();
            });
            
        } catch (error) {
            console.error('Camera access denied:', error);
            this.closeCameraModal();
            this.showCameraPermissionModal();
        }
    }

    showCameraPermissionModal() {
        const modal = document.createElement('div');
        modal.className = 'camera-modal';
        modal.innerHTML = `
            <div class="camera-modal-content permission-modal">
                <div class="camera-header">
                    <button class="camera-close-btn" id="closePermissionModal">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                            <path d="M18 6L6 18M6 6L18 18" stroke="currentColor" stroke-width="2"/>
                        </svg>
                    </button>
                    <h3>Camera Access Required</h3>
                    <div style="width: 24px;"></div>
                </div>
                <div class="permission-content">
                    <div class="permission-icon">
                        <svg width="64" height="64" viewBox="0 0 24 24" fill="none">
                            <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z" stroke="currentColor" stroke-width="2"/>
                            <circle cx="12" cy="13" r="4" stroke="currentColor" stroke-width="2"/>
                        </svg>
                    </div>
                    <h4>Enable Camera Access</h4>
                    <p>To take photos, please allow camera access in your browser settings.</p>
                    
                    <div class="permission-instructions">
                        <strong>How to enable camera access:</strong>
                        <ol>
                            <li>Look for the camera icon in your browser's address bar</li>
                            <li>Click on it and select "Allow"</li>
                            <li>Or go to your browser settings and enable camera for this site</li>
                            <li>Refresh the page and try again</li>
                        </ol>
                    </div>
                    
                    <div class="permission-buttons">
                        <button class="btn btn-secondary" id="useUploadInstead">Use Upload Instead</button>
                        <button class="btn btn-primary" id="retryCamera">Try Again</button>
                    </div>
                </div>
            </div>
        `;
        
        document.body.appendChild(modal);
        
        // Show modal with animation
        setTimeout(() => modal.classList.add('visible'), 10);
        
        // Setup event listeners
        document.getElementById('closePermissionModal').onclick = () => this.closePermissionModal();
        document.getElementById('useUploadInstead').onclick = () => {
            this.closePermissionModal();
            document.getElementById('fileInput').click();
        };
        document.getElementById('retryCamera').onclick = () => {
            this.closePermissionModal();
            setTimeout(() => this.capturePhoto(), 100);
        };
        
        // Handle modal background click
        modal.onclick = (e) => {
            if (e.target === modal) {
                this.closePermissionModal();
            }
        };
    }

    closePermissionModal() {
        const modal = document.querySelector('.camera-modal');
        if (modal) {
            modal.classList.remove('visible');
            setTimeout(() => modal.remove(), 300);
        }
    }

    async capturePhotoFromModal() {
        try {
            const video = document.getElementById('cameraVideoModal');
            const canvas = document.getElementById('cameraCanvasModal');
            const ctx = canvas.getContext('2d');
            
            if (!video || video.videoWidth === 0 || video.videoHeight === 0) {
                this.showError('Camera not ready. Please try again.');
                return;
            }
            
            // Set canvas size to match video
            canvas.width = video.videoWidth;
            canvas.height = video.videoHeight;
            
            // Draw video frame to canvas
            ctx.drawImage(video, 0, 0);
            
            // Show capture feedback
            const captureBtn = document.getElementById('cameraCaptureBtn');
            captureBtn.style.transform = 'scale(0.9)';
            setTimeout(() => captureBtn.style.transform = 'scale(1)', 100);
            
            // Convert to blob and process
            canvas.toBlob(async (blob) => {
                if (blob) {
                    const reader = new FileReader();
                    reader.onload = (e) => {
                        // Generate unique ID
                        let photoId = Date.now();
                        while (this.currentProject.photos.find(p => p.id === photoId)) {
                            photoId++;
                        }
                        
                        const photo = {
                            id: photoId,
                            url: e.target.result,
                            name: `Photo ${this.currentProject.photos.length + 1}`,
                            description: '',
                            annotations: [],
                            createdAt: new Date().toISOString(),
                            type: 'captured'
                        };

                        this.currentProject.photos.push(photo);
                        this.currentProject.updatedAt = new Date().toISOString();
                        this.saveDataToStorage();
                        this.updatePhotosList();
                        this.closeCameraModal();
                        this.showSuccess('Photo captured successfully!');
                    };
                    reader.readAsDataURL(blob);
                } else {
                    this.showError('Failed to capture photo. Please try again.');
                }
            }, 'image/jpeg', 0.9);
            
        } catch (error) {
            console.error('Photo capture error:', error);
            this.showError('Failed to capture photo. Please try again.');
        }
    }

    closeCameraModal() {
        // Stop camera stream
        if (this.cameraStream) {
            this.cameraStream.getTracks().forEach(track => track.stop());
            this.cameraStream = null;
        }
        
        // Remove modal
        const modal = document.querySelector('.camera-modal');
        if (modal) {
            modal.classList.remove('visible');
            setTimeout(() => modal.remove(), 300);
        }
    }

    async handleFileUpload(files) {
        if (!files || files.length === 0) return;

        this.showLoading(`Processing ${files.length} photo${files.length > 1 ? 's' : ''}...`);

        try {
            const processedPhotos = [];
            
            for (let i = 0; i < files.length; i++) {
                const file = files[i];
                
                // Validate file type
                if (!file.type.startsWith('image/')) {
                    console.warn('Skipping non-image file:', file.name);
                    continue;
                }

                // iOS-specific file size check
                if (file.size > 50 * 1024 * 1024) { // 50MB limit for iOS
                    this.showError(`File ${file.name} is too large. Maximum size is 50MB.`);
                    continue;
                }

                try {
                    const processedPhoto = await this.processPhoto(file);
                    if (processedPhoto) {
                        processedPhotos.push(processedPhoto);
                    }
                } catch (error) {
                    console.error('Error processing photo:', error);
                    this.showError(`Failed to process ${file.name}`);
                }
            }

            if (processedPhotos.length > 0) {
                this.currentProject.photos.push(...processedPhotos);
                this.currentProject.updatedAt = new Date().toISOString();
                this.saveDataToStorage();
                this.updatePhotosList();
                this.showSuccess(`Successfully added ${processedPhotos.length} photo${processedPhotos.length > 1 ? 's' : ''}!`);
            } else {
                this.showError('No valid photos were processed');
            }
        } catch (error) {
            console.error('File upload error:', error);
            this.showError('Failed to upload photos. Please try again.');
        } finally {
            this.hideLoading();
        }
    }

    async processPhoto(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            
            reader.onload = (e) => {
                try {
                    // Generate unique ID with iOS compatibility
                    let photoId = Date.now() + Math.random();
                    while (this.currentProject.photos.find(p => p.id === photoId)) {
                        photoId = Date.now() + Math.random();
                    }
                    
                    // Create image element for iOS-specific processing
                    const img = new Image();
                    img.onload = () => {
                        try {
                            // Create canvas for iOS-specific image processing
                            const canvas = document.createElement('canvas');
                            const ctx = canvas.getContext('2d');
                            
                            // Set canvas size (iOS Safari has limits)
                            const maxWidth = 1920;
                            const maxHeight = 1080;
                            let { width, height } = img;
                            
                            if (width > maxWidth || height > maxHeight) {
                                const ratio = Math.min(maxWidth / width, maxHeight / height);
                                width *= ratio;
                                height *= ratio;
                            }
                            
                            canvas.width = width;
                            canvas.height = height;
                            
                            // Draw image with iOS-specific handling
                            ctx.drawImage(img, 0, 0, width, height);
                            
                            // Convert to data URL with iOS-optimized quality
                            const dataURL = canvas.toDataURL('image/jpeg', 0.8);
                            
                            const photo = {
                                id: parseInt(photoId),
                                url: dataURL,
                                name: file.name || `Photo ${this.currentProject.photos.length + 1}`,
                                description: '',
                                annotations: [],
                                createdAt: new Date().toISOString(),
                                type: 'uploaded',
                                fileSize: file.size,
                                originalName: file.name
                            };
                            
                            resolve(photo);
                        } catch (error) {
                            console.error('Canvas processing error:', error);
                            reject(error);
                        }
                    };
                    
                    img.onerror = () => {
                        reject(new Error('Failed to load image'));
                    };
                    
                    img.src = e.target.result;
                } catch (error) {
                    reject(error);
                }
            };
            
            reader.onerror = () => {
                reject(new Error('Failed to read file'));
            };
            
            // Start reading the file
            reader.readAsDataURL(file);
        });
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
        // Convert photoId to number for comparison since HTML data attributes are strings
        const numericPhotoId = typeof photoId === 'string' ? parseFloat(photoId) : photoId;
        const photo = this.currentProject.photos.find(p => p.id === numericPhotoId);
        
        if (!photo) {
            console.error('Photo not found:', photoId, 'Available photos:', this.currentProject.photos.map(p => p.id));
            this.showError('Photo not found. Please try again.');
            return;
        }

        this.currentPhoto = photo;
        const modal = document.getElementById('annotationModal');
        const canvas = document.getElementById('annotationCanvas');
        const ctx = canvas.getContext('2d');

        // Clear any existing canvas content
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        // Load image
        const img = new Image();
        img.onload = () => {
            // Set canvas dimensions to match image
            canvas.width = img.width;
            canvas.height = img.height;
            
            // Calculate display dimensions while maintaining aspect ratio
            const containerWidth = 350;
            const containerHeight = 250;
            const aspectRatio = img.width / img.height;
            
            let displayWidth = containerWidth;
            let displayHeight = containerWidth / aspectRatio;
            
            if (displayHeight > containerHeight) {
                displayHeight = containerHeight;
                displayWidth = containerHeight * aspectRatio;
            }
            
            // Set canvas display style
            canvas.style.width = displayWidth + 'px';
            canvas.style.height = displayHeight + 'px';
            
            // Draw image
            ctx.drawImage(img, 0, 0);

            // Draw existing annotations
            this.redrawAnnotations(ctx);
            
            console.log('Annotation modal opened for photo:', photo.id);
        };
        
        img.onerror = () => {
            console.error('Failed to load image:', photo.url);
            this.showError('Failed to load image. Please try again.');
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
        
        // Remove any existing event listeners to prevent duplicates
        const newCanvas = canvas.cloneNode(true);
        canvas.parentNode.replaceChild(newCanvas, canvas);
        
        const ctx = newCanvas.getContext('2d');

        // Mouse events for desktop
        newCanvas.addEventListener('mousedown', (e) => this.startDrawing(e, ctx));
        newCanvas.addEventListener('mousemove', (e) => this.draw(e, ctx));
        newCanvas.addEventListener('mouseup', () => this.stopDrawing());
        newCanvas.addEventListener('mouseout', () => this.stopDrawing());

        // Touch events for mobile with iOS-specific handling
        newCanvas.addEventListener('touchstart', (e) => {
            e.preventDefault();
            e.stopPropagation();
            if (e.touches.length === 1) {
                const touch = e.touches[0];
                this.startDrawing(touch, ctx);
            }
        }, { passive: false });

        newCanvas.addEventListener('touchmove', (e) => {
            e.preventDefault();
            e.stopPropagation();
            if (e.touches.length === 1) {
                const touch = e.touches[0];
                this.draw(touch, ctx);
            }
        }, { passive: false });

        newCanvas.addEventListener('touchend', (e) => {
            e.preventDefault();
            e.stopPropagation();
            this.stopDrawing();
        }, { passive: false });

        newCanvas.addEventListener('touchcancel', (e) => {
            e.preventDefault();
            e.stopPropagation();
            this.stopDrawing();
        }, { passive: false });

        // Prevent context menu and iOS-specific behaviors
        newCanvas.addEventListener('contextmenu', (e) => {
            e.preventDefault();
        });

        // Prevent iOS zoom and other gestures
        newCanvas.addEventListener('gesturestart', (e) => {
            e.preventDefault();
        });

        newCanvas.addEventListener('gesturechange', (e) => {
            e.preventDefault();
        });

        newCanvas.addEventListener('gestureend', (e) => {
            e.preventDefault();
        });

        // Prevent scroll on touch
        newCanvas.style.touchAction = 'none';
        newCanvas.style.msTouchAction = 'none';
    }

    getCanvasCoordinates(e, canvas) {
        const rect = canvas.getBoundingClientRect();
        const scaleX = canvas.width / rect.width;
        const scaleY = canvas.height / rect.height;
        
        let clientX, clientY;
        
        // Handle both mouse and touch events
        if (e.touches && e.touches.length > 0) {
            // Touch event
            clientX = e.touches[0].clientX;
            clientY = e.touches[0].clientY;
        } else if (e.clientX !== undefined) {
            // Mouse event
            clientX = e.clientX;
            clientY = e.clientY;
        } else {
            // Touch event passed as touch object
            clientX = e.clientX;
            clientY = e.clientY;
        }
        
        // Get viewport offset for iOS Safari
        const scrollX = window.pageXOffset || document.documentElement.scrollLeft;
        const scrollY = window.pageYOffset || document.documentElement.scrollTop;
        
        // Calculate coordinates with iOS-specific adjustments
        const x = (clientX - rect.left) * scaleX;
        const y = (clientY - rect.top) * scaleY;
        
        return {
            x: Math.max(0, Math.min(canvas.width, x)),
            y: Math.max(0, Math.min(canvas.height, y))
        };
    }

    startDrawing(e, ctx) {
        this.isDrawing = true;
        const canvas = ctx.canvas;
        const coords = this.getCanvasCoordinates(e, canvas);
        
        this.lastX = coords.x;
        this.lastY = coords.y;

        ctx.beginPath();
        ctx.moveTo(this.lastX, this.lastY);
    }

    draw(e, ctx) {
        if (!this.isDrawing) return;

        const canvas = ctx.canvas;
        const coords = this.getCanvasCoordinates(e, canvas);
        const currentX = coords.x;
        const currentY = coords.y;

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

        document.getElementById('fileInput').addEventListener('change', async (e) => {
            await this.handleFileUpload(e.target.files);
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
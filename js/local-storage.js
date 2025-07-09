/**
 * Local Storage Manager using IndexedDB
 * Replaces Firebase/Supabase with fully local browser storage
 */

class LocalStorageManager {
    constructor() {
        this.dbName = 'InspectortPro';
        this.dbVersion = 1;
        this.db = null;
        this.isInitialized = false;
    }

    /**
     * Initialize IndexedDB database
     */
    async initialize() {
        if (this.isInitialized) return;

        return new Promise((resolve, reject) => {
            const request = indexedDB.open(this.dbName, this.dbVersion);

            request.onerror = () => {
                console.error('IndexedDB initialization failed:', request.error);
                reject(request.error);
            };

            request.onsuccess = () => {
                this.db = request.result;
                this.isInitialized = true;
                console.log('IndexedDB initialized successfully');
                resolve();
            };

            request.onupgradeneeded = (event) => {
                const db = event.target.result;
                
                // Create users store
                if (!db.objectStoreNames.contains('users')) {
                    const usersStore = db.createObjectStore('users', { keyPath: 'id' });
                    usersStore.createIndex('email', 'email', { unique: true });
                    usersStore.createIndex('createdAt', 'createdAt');
                }

                // Create projects store
                if (!db.objectStoreNames.contains('projects')) {
                    const projectsStore = db.createObjectStore('projects', { keyPath: 'id' });
                    projectsStore.createIndex('userId', 'createdBy');
                    projectsStore.createIndex('name', 'name');
                    projectsStore.createIndex('createdAt', 'createdAt');
                    projectsStore.createIndex('updatedAt', 'updatedAt');
                    projectsStore.createIndex('type', 'type');
                    projectsStore.createIndex('status', 'status');
                }

                // Create photos store
                if (!db.objectStoreNames.contains('photos')) {
                    const photosStore = db.createObjectStore('photos', { keyPath: 'id' });
                    photosStore.createIndex('projectId', 'projectId');
                    photosStore.createIndex('userId', 'userId');
                    photosStore.createIndex('createdAt', 'createdAt');
                    photosStore.createIndex('name', 'name');
                    photosStore.createIndex('size', 'size');
                }

                // Create app settings store
                if (!db.objectStoreNames.contains('settings')) {
                    db.createObjectStore('settings', { keyPath: 'key' });
                }
            };
        });
    }

    /**
     * Generic method to add/update data in a store
     */
    async put(storeName, data) {
        if (!this.isInitialized) await this.initialize();
        
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([storeName], 'readwrite');
            const store = transaction.objectStore(storeName);
            const request = store.put(data);

            request.onerror = () => reject(request.error);
            request.onsuccess = () => resolve(request.result);
        });
    }

    /**
     * Generic method to get data from a store
     */
    async get(storeName, key) {
        if (!this.isInitialized) await this.initialize();
        
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([storeName], 'readonly');
            const store = transaction.objectStore(storeName);
            const request = store.get(key);

            request.onerror = () => reject(request.error);
            request.onsuccess = () => resolve(request.result);
        });
    }

    /**
     * Generic method to delete data from a store
     */
    async delete(storeName, key) {
        if (!this.isInitialized) await this.initialize();
        
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([storeName], 'readwrite');
            const store = transaction.objectStore(storeName);
            const request = store.delete(key);

            request.onerror = () => reject(request.error);
            request.onsuccess = () => resolve(request.result);
        });
    }

    /**
     * Generic method to get all data from a store
     */
    async getAll(storeName) {
        if (!this.isInitialized) await this.initialize();
        
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([storeName], 'readonly');
            const store = transaction.objectStore(storeName);
            const request = store.getAll();

            request.onerror = () => reject(request.error);
            request.onsuccess = () => resolve(request.result);
        });
    }

    /**
     * Get data by index
     */
    async getByIndex(storeName, indexName, value) {
        if (!this.isInitialized) await this.initialize();
        
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([storeName], 'readonly');
            const store = transaction.objectStore(storeName);
            const index = store.index(indexName);
            const request = index.getAll(value);

            request.onerror = () => reject(request.error);
            request.onsuccess = () => resolve(request.result);
        });
    }

    /**
     * Count records in a store
     */
    async count(storeName) {
        if (!this.isInitialized) await this.initialize();
        
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([storeName], 'readonly');
            const store = transaction.objectStore(storeName);
            const request = store.count();

            request.onerror = () => reject(request.error);
            request.onsuccess = () => resolve(request.result);
        });
    }

    /**
     * Clear all data from a store
     */
    async clear(storeName) {
        if (!this.isInitialized) await this.initialize();
        
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([storeName], 'readwrite');
            const store = transaction.objectStore(storeName);
            const request = store.clear();

            request.onerror = () => reject(request.error);
            request.onsuccess = () => resolve(request.result);
        });
    }

    // === USER MANAGEMENT ===

    /**
     * Create a new user
     */
    async createUser(userData) {
        const user = {
            id: this.generateId(),
            name: userData.name,
            email: userData.email,
            passwordHash: await this.hashPassword(userData.password),
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
            lastLogin: new Date().toISOString(),
            isActive: true
        };

        await this.put('users', user);
        return { ...user, password: undefined, passwordHash: undefined };
    }

    /**
     * Authenticate user with email and password
     */
    async authenticateUser(email, password) {
        const users = await this.getByIndex('users', 'email', email);
        if (users.length === 0) return null;

        const user = users[0];
        const isValid = await this.verifyPassword(password, user.passwordHash);
        
        if (isValid) {
            // Update last login
            await this.put('users', {
                ...user,
                lastLogin: new Date().toISOString(),
                updatedAt: new Date().toISOString()
            });
            
            return { ...user, password: undefined, passwordHash: undefined };
        }

        return null;
    }

    /**
     * Get user by ID
     */
    async getUserById(userId) {
        const user = await this.get('users', userId);
        if (user) {
            return { ...user, password: undefined, passwordHash: undefined };
        }
        return null;
    }

    /**
     * Check if email exists
     */
    async emailExists(email) {
        const users = await this.getByIndex('users', 'email', email);
        return users.length > 0;
    }

    // === PROJECT MANAGEMENT ===

    /**
     * Create a new project
     */
    async createProject(projectData, userId) {
        const project = {
            id: this.generateId(),
            name: projectData.name,
            description: projectData.description || '',
            location: projectData.location || '',
            type: projectData.type || 'inspection',
            client: projectData.client || '',
            deadline: projectData.deadline || null,
            notes: projectData.notes || '',
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
            createdBy: userId,
            status: 'active',
            totalPhotos: 0,
            annotatedPhotos: 0,
            completionPercentage: 0
        };

        await this.put('projects', project);
        return project;
    }

    /**
     * Get all projects for a user
     */
    async getUserProjects(userId) {
        return await this.getByIndex('projects', 'userId', userId);
    }

    /**
     * Get project by ID
     */
    async getProject(projectId) {
        return await this.get('projects', projectId);
    }

    /**
     * Update project
     */
    async updateProject(projectId, updates) {
        const project = await this.get('projects', projectId);
        if (!project) throw new Error('Project not found');

        const updatedProject = {
            ...project,
            ...updates,
            updatedAt: new Date().toISOString()
        };

        await this.put('projects', updatedProject);
        return updatedProject;
    }

    /**
     * Delete project and all its photos
     */
    async deleteProject(projectId) {
        // Delete all photos in this project
        const photos = await this.getByIndex('photos', 'projectId', projectId);
        for (const photo of photos) {
            await this.delete('photos', photo.id);
        }

        // Delete the project
        await this.delete('projects', projectId);
        return true;
    }

    // === PHOTO MANAGEMENT ===

    /**
     * Save a new photo
     */
    async savePhoto(photoData) {
        const photo = {
            id: this.generateId(),
            name: photoData.name || photoData.originalName || 'Untitled Photo',
            originalName: photoData.originalName || photoData.name,
            description: photoData.description || '',
            url: photoData.url, // Base64 data URL
            projectId: photoData.projectId,
            userId: photoData.userId,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
            size: photoData.size || 0,
            annotations: photoData.annotations || [],
            isAnnotated: photoData.isAnnotated || false,
            timestamp: photoData.timestamp || new Date().toISOString()
        };

        await this.put('photos', photo);
        
        // Update project photo count
        await this.updateProjectPhotoCount(photoData.projectId);
        
        return photo;
    }

    /**
     * Get all photos for a project
     */
    async getProjectPhotos(projectId) {
        return await this.getByIndex('photos', 'projectId', projectId);
    }

    /**
     * Get all photos for a user
     */
    async getUserPhotos(userId) {
        return await this.getByIndex('photos', 'userId', userId);
    }

    /**
     * Get photo by ID
     */
    async getPhoto(photoId) {
        return await this.get('photos', photoId);
    }

    /**
     * Update photo
     */
    async updatePhoto(photoId, updates) {
        const photo = await this.get('photos', photoId);
        if (!photo) throw new Error('Photo not found');

        const updatedPhoto = {
            ...photo,
            ...updates,
            updatedAt: new Date().toISOString()
        };

        await this.put('photos', updatedPhoto);
        return updatedPhoto;
    }

    /**
     * Delete photo
     */
    async deletePhoto(photoId) {
        const photo = await this.get('photos', photoId);
        if (!photo) return false;

        await this.delete('photos', photoId);
        
        // Update project photo count
        await this.updateProjectPhotoCount(photo.projectId);
        
        return true;
    }

    /**
     * Update project photo count
     */
    async updateProjectPhotoCount(projectId) {
        const photos = await this.getByIndex('photos', 'projectId', projectId);
        const annotatedPhotos = photos.filter(p => p.isAnnotated).length;
        
        await this.updateProject(projectId, {
            totalPhotos: photos.length,
            annotatedPhotos: annotatedPhotos,
            completionPercentage: photos.length > 0 ? Math.round((annotatedPhotos / photos.length) * 100) : 0
        });
    }

    // === STORAGE MANAGEMENT ===

    /**
     * Get storage usage statistics
     */
    async getStorageUsage() {
        try {
            const users = await this.getAll('users');
            const projects = await this.getAll('projects');
            const photos = await this.getAll('photos');
            
            const usersSize = new Blob([JSON.stringify(users)]).size;
            const projectsSize = new Blob([JSON.stringify(projects)]).size;
            const photosSize = new Blob([JSON.stringify(photos)]).size;
            
            const totalSize = usersSize + projectsSize + photosSize;
            
            // IndexedDB typically has higher limits than localStorage
            const storageLimit = 100 * 1024 * 1024; // 100MB conservative limit
            
            return {
                users: Math.round(usersSize / 1024 / 1024 * 100) / 100,
                projects: Math.round(projectsSize / 1024 / 1024 * 100) / 100,
                photos: Math.round(photosSize / 1024 / 1024 * 100) / 100,
                total: Math.round(totalSize / 1024 / 1024 * 100) / 100,
                limit: 100, // 100MB
                available: Math.max(0, Math.round((storageLimit - totalSize) / 1024 / 1024 * 100) / 100),
                percentage: Math.round((totalSize / storageLimit) * 100)
            };
        } catch (error) {
            console.error('Error calculating storage usage:', error);
            return { users: 0, projects: 0, photos: 0, total: 0, limit: 100, available: 100, percentage: 0 };
        }
    }

    /**
     * Clean up old photos
     */
    async cleanupOldPhotos(userId, count = 5) {
        const photos = await this.getUserPhotos(userId);
        if (photos.length === 0) return 0;

        // Sort by creation date (oldest first)
        photos.sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));
        
        const photosToDelete = photos.slice(0, Math.min(count, photos.length));
        let deletedCount = 0;
        
        for (const photo of photosToDelete) {
            const success = await this.deletePhoto(photo.id);
            if (success) deletedCount++;
        }
        
        return deletedCount;
    }

    // === MIGRATION FROM LOCALSTORAGE ===

    /**
     * Migrate data from localStorage to IndexedDB
     */
    async migrateFromLocalStorage() {
        try {
            console.log('Starting migration from localStorage to IndexedDB...');
            
            // Migrate current user
            const currentUserData = localStorage.getItem('inspectort_user_data');
            if (currentUserData) {
                const userData = JSON.parse(currentUserData);
                if (userData.id) {
                    // Check if user already exists
                    const existingUser = await this.getUserById(userData.id);
                    if (!existingUser) {
                        await this.put('users', {
                            ...userData,
                            passwordHash: 'migrated', // Placeholder - user will need to re-authenticate
                            updatedAt: new Date().toISOString()
                        });
                    }
                }
            }

            // Migrate projects
            const projectsData = localStorage.getItem('inspectort_projects');
            if (projectsData) {
                const projects = JSON.parse(projectsData);
                for (const project of projects) {
                    const existingProject = await this.getProject(project.id);
                    if (!existingProject) {
                        await this.put('projects', {
                            ...project,
                            updatedAt: new Date().toISOString()
                        });
                    }
                }
            }

            // Migrate photos
            const photosData = localStorage.getItem('inspectort_photos');
            if (photosData) {
                const photos = JSON.parse(photosData);
                for (const photo of photos) {
                    const existingPhoto = await this.getPhoto(photo.id);
                    if (!existingPhoto) {
                        await this.put('photos', {
                            ...photo,
                            updatedAt: new Date().toISOString()
                        });
                    }
                }
            }

            console.log('Migration completed successfully');
            return true;
        } catch (error) {
            console.error('Migration failed:', error);
            return false;
        }
    }

    // === UTILITY METHODS ===

    /**
     * Generate unique ID
     */
    generateId() {
        return Date.now().toString(36) + Math.random().toString(36).substr(2, 9);
    }

    /**
     * Hash password using Web Crypto API
     */
    async hashPassword(password) {
        const encoder = new TextEncoder();
        const data = encoder.encode(password);
        const hash = await crypto.subtle.digest('SHA-256', data);
        return Array.from(new Uint8Array(hash)).map(b => b.toString(16).padStart(2, '0')).join('');
    }

    /**
     * Verify password against hash
     */
    async verifyPassword(password, hash) {
        const computedHash = await this.hashPassword(password);
        return computedHash === hash;
    }

    /**
     * Export all user data
     */
    async exportUserData(userId) {
        const user = await this.getUserById(userId);
        const projects = await this.getUserProjects(userId);
        const photos = await this.getUserPhotos(userId);

        return {
            user,
            projects,
            photos,
            exportedAt: new Date().toISOString()
        };
    }

    /**
     * Get database info
     */
    async getDatabaseInfo() {
        const userCount = await this.count('users');
        const projectCount = await this.count('projects');
        const photoCount = await this.count('photos');
        const storageUsage = await this.getStorageUsage();

        return {
            userCount,
            projectCount,
            photoCount,
            storageUsage,
            databaseVersion: this.dbVersion
        };
    }
}

// Create global instance
const localStorageManager = new LocalStorageManager();

// Export for use in other modules
window.LocalStorageManager = localStorageManager;

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    localStorageManager.initialize().then(() => {
        // Perform migration if needed
        localStorageManager.migrateFromLocalStorage();
    }).catch(error => {
        console.error('Failed to initialize local storage:', error);
    });
});
/**
 * Firebase Configuration for Inspectort Pro
 * Cross-device data synchronization
 */

// Firebase configuration - Replace with your Firebase project config
const firebaseConfig = {
    apiKey: "YOUR_API_KEY_HERE",
    authDomain: "your-project.firebaseapp.com",
    projectId: "your-project-id",
    storageBucket: "your-project.appspot.com",
    messagingSenderId: "123456789012",
    appId: "1:123456789012:web:abcdef123456789"
};

// Initialize Firebase
let firebaseApp = null;
let auth = null;
let db = null;
let storage = null;
let isFirebaseEnabled = false;

function initializeFirebase() {
    try {
        // Check if Firebase is available
        if (typeof firebase === 'undefined') {
            console.log('Firebase SDK not loaded, using offline mode only');
            return false;
        }

        // Check if Firebase config is properly set up
        if (firebaseConfig.apiKey === "YOUR_API_KEY_HERE") {
            console.log('Firebase not configured - using offline mode only');
            console.log('To enable cloud sync, please configure Firebase in js/firebase-config.js');
            return false;
        }

        // Initialize Firebase with user config
        firebaseApp = firebase.initializeApp(firebaseConfig);
        auth = firebase.auth();
        db = firebase.firestore();
        storage = firebase.storage();
        
        // Enable offline persistence for Firestore
        db.enablePersistence({ synchronizeTabs: true })
            .then(() => {
                console.log('Firebase offline persistence enabled');
            })
            .catch((err) => {
                console.log('Firebase persistence error:', err.code);
                // This is expected if already enabled
                if (err.code !== 'failed-precondition') {
                    console.warn('Persistence failed, continuing without offline support');
                }
            });

        isFirebaseEnabled = true;
        console.log('Firebase initialized successfully');
        return true;
    } catch (error) {
        console.error('Firebase initialization failed:', error);
        console.log('App will continue in offline mode');
        isFirebaseEnabled = false;
        return false;
    }
}

// Firebase Authentication Methods
async function signUpWithEmail(email, password, displayName) {
    if (!isFirebaseEnabled) {
        throw new Error('Cloud sync not available - working offline');
    }

    try {
        const userCredential = await auth.createUserWithEmailAndPassword(email, password);
        const user = userCredential.user;

        // Update profile with display name
        await user.updateProfile({
            displayName: displayName
        });

        // Create user document in Firestore
        await db.collection('users').doc(user.uid).set({
            name: displayName,
            email: email,
            createdAt: firebase.firestore.FieldValue.serverTimestamp(),
            lastLogin: firebase.firestore.FieldValue.serverTimestamp()
        });

        console.log('User created successfully:', user.uid);
        return {
            uid: user.uid,
            email: user.email,
            displayName: displayName
        };
    } catch (error) {
        console.error('Sign up error:', error);
        throw error;
    }
}

async function signInWithEmail(email, password) {
    if (!isFirebaseEnabled) {
        throw new Error('Cloud sync not available - working offline');
    }

    try {
        const userCredential = await auth.signInWithEmailAndPassword(email, password);
        const user = userCredential.user;

        // Update last login time
        await db.collection('users').doc(user.uid).update({
            lastLogin: firebase.firestore.FieldValue.serverTimestamp()
        });

        console.log('User signed in successfully:', user.uid);
        return {
            uid: user.uid,
            email: user.email,
            displayName: user.displayName
        };
    } catch (error) {
        console.error('Sign in error:', error);
        throw error;
    }
}

async function signOut() {
    if (!isFirebaseEnabled) {
        return;
    }

    try {
        await auth.signOut();
        console.log('User signed out successfully');
    } catch (error) {
        console.error('Sign out error:', error);
        throw error;
    }
}

// Data Synchronization Methods
async function syncProjectsToCloud(projects) {
    if (!isFirebaseEnabled || !auth.currentUser) {
        console.log('Not syncing projects - offline mode or not authenticated');
        return false;
    }

    try {
        const batch = db.batch();
        const userProjectsRef = db.collection('users').doc(auth.currentUser.uid).collection('projects');

        for (const project of projects) {
            const projectRef = userProjectsRef.doc(project.id);
            batch.set(projectRef, {
                ...project,
                syncedAt: firebase.firestore.FieldValue.serverTimestamp()
            });
        }

        await batch.commit();
        console.log('Projects synced to cloud successfully');
        return true;
    } catch (error) {
        console.error('Error syncing projects to cloud:', error);
        return false;
    }
}

async function syncPhotosToCloud(photos) {
    if (!isFirebaseEnabled || !auth.currentUser) {
        console.log('Not syncing photos - offline mode or not authenticated');
        return false;
    }

    try {
        const batch = db.batch();
        const userPhotosRef = db.collection('users').doc(auth.currentUser.uid).collection('photos');

        for (const photo of photos) {
            const photoRef = userPhotosRef.doc(photo.id);
            batch.set(photoRef, {
                ...photo,
                syncedAt: firebase.firestore.FieldValue.serverTimestamp()
            });
        }

        await batch.commit();
        console.log('Photos synced to cloud successfully');
        return true;
    } catch (error) {
        console.error('Error syncing photos to cloud:', error);
        return false;
    }
}

async function loadProjectsFromCloud() {
    if (!isFirebaseEnabled || !auth.currentUser) {
        console.log('Not loading projects from cloud - offline mode or not authenticated');
        return [];
    }

    try {
        const userProjectsRef = db.collection('users').doc(auth.currentUser.uid).collection('projects');
        const snapshot = await userProjectsRef.orderBy('createdAt', 'desc').get();
        
        const projects = [];
        snapshot.forEach(doc => {
            const data = doc.data();
            // Remove Firebase timestamps before storing locally
            delete data.syncedAt;
            projects.push(data);
        });

        console.log('Loaded', projects.length, 'projects from cloud');
        return projects;
    } catch (error) {
        console.error('Error loading projects from cloud:', error);
        return [];
    }
}

async function loadPhotosFromCloud() {
    if (!isFirebaseEnabled || !auth.currentUser) {
        console.log('Not loading photos from cloud - offline mode or not authenticated');
        return [];
    }

    try {
        const userPhotosRef = db.collection('users').doc(auth.currentUser.uid).collection('photos');
        const snapshot = await userPhotosRef.orderBy('createdAt', 'desc').get();
        
        const photos = [];
        snapshot.forEach(doc => {
            const data = doc.data();
            // Remove Firebase timestamps before storing locally
            delete data.syncedAt;
            photos.push(data);
        });

        console.log('Loaded', photos.length, 'photos from cloud');
        return photos;
    } catch (error) {
        console.error('Error loading photos from cloud:', error);
        return [];
    }
}

// Auto-sync functionality
async function performFullSync() {
    if (!isFirebaseEnabled || !auth.currentUser) {
        console.log('Full sync skipped - offline mode or not authenticated');
        return { success: false, message: 'Working offline' };
    }

    try {
        console.log('Starting full data sync...');
        
        // Load data from cloud
        const [cloudProjects, cloudPhotos] = await Promise.all([
            loadProjectsFromCloud(),
            loadPhotosFromCloud()
        ]);

        // Get local data
        const localProjects = JSON.parse(localStorage.getItem('inspectort_projects') || '[]');
        const localPhotos = JSON.parse(localStorage.getItem('inspectort_photos') || '[]');

        // Merge data (cloud takes precedence for conflicts)
        const mergedProjects = mergeData(localProjects, cloudProjects, 'updatedAt');
        const mergedPhotos = mergeData(localPhotos, cloudPhotos, 'updatedAt');

        // Save merged data locally
        localStorage.setItem('inspectort_projects', JSON.stringify(mergedProjects));
        localStorage.setItem('inspectort_photos', JSON.stringify(mergedPhotos));

        // Sync any local changes back to cloud
        await syncProjectsToCloud(mergedProjects);
        await syncPhotosToCloud(mergedPhotos);

        console.log('Full sync completed successfully');
        return { 
            success: true, 
            message: `Synced ${mergedProjects.length} projects and ${mergedPhotos.length} photos`,
            projects: mergedProjects.length,
            photos: mergedPhotos.length
        };
    } catch (error) {
        console.error('Full sync failed:', error);
        return { success: false, message: error.message };
    }
}

// Helper function to merge local and cloud data
function mergeData(localData, cloudData, timestampField) {
    const merged = new Map();
    
    // Add local data first
    localData.forEach(item => {
        merged.set(item.id, item);
    });
    
    // Override with cloud data if it's newer
    cloudData.forEach(item => {
        const existing = merged.get(item.id);
        if (!existing || new Date(item[timestampField]) > new Date(existing[timestampField])) {
            merged.set(item.id, item);
        }
    });
    
    return Array.from(merged.values());
}

// Auth state observer
function setupAuthStateObserver(onAuthStateChanged) {
    if (!isFirebaseEnabled) {
        return;
    }

    auth.onAuthStateChanged((user) => {
        if (user) {
            console.log('User authenticated:', user.email);
            onAuthStateChanged(user);
        } else {
            console.log('User signed out');
            onAuthStateChanged(null);
        }
    });
}

// Initialize Firebase when script loads
document.addEventListener('DOMContentLoaded', () => {
    initializeFirebase();
});

// Export functions for use in main app
window.FirebaseSync = {
    isEnabled: () => isFirebaseEnabled,
    getCurrentUser: () => auth?.currentUser,
    signUp: signUpWithEmail,
    signIn: signInWithEmail,
    signOut: signOut,
    syncProjects: syncProjectsToCloud,
    syncPhotos: syncPhotosToCloud,
    loadProjects: loadProjectsFromCloud,
    loadPhotos: loadPhotosFromCloud,
    performFullSync: performFullSync,
    setupAuthObserver: setupAuthStateObserver
}; 
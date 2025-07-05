/**
 * Inspectort Pro - Service Worker
 * PWA Offline Support and Caching
 */

const CACHE_NAME = 'inspectort-pro-v1.0.0';
const OFFLINE_PAGE = '/Inspector_pro/offline.html';

// Files to cache for offline functionality
const CACHE_URLS = [
    '/Inspector_pro/',
    '/Inspector_pro/index.html',
    '/Inspector_pro/css/styles.css',
    '/Inspector_pro/js/app.js',
    '/Inspector_pro/manifest.json',
    '/Inspector_pro/assets/icons/favicon.svg',
    '/Inspector_pro/assets/icons/icon-192x192.svg',
    '/Inspector_pro/assets/icons/icon-512x512.svg',
    // Add more static assets as needed
];

// Install event - cache essential resources
self.addEventListener('install', event => {
    console.log('Service Worker: Installing...');
    
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then(cache => {
                console.log('Service Worker: Caching essential files');
                return cache.addAll(CACHE_URLS);
            })
            .then(() => {
                console.log('Service Worker: Installation complete');
                return self.skipWaiting();
            })
            .catch(error => {
                console.error('Service Worker: Installation failed', error);
            })
    );
});

// Activate event - clean up old caches
self.addEventListener('activate', event => {
    console.log('Service Worker: Activating...');
    
    event.waitUntil(
        caches.keys().then(cacheNames => {
            return Promise.all(
                cacheNames.map(cacheName => {
                    if (cacheName !== CACHE_NAME) {
                        console.log('Service Worker: Deleting old cache', cacheName);
                        return caches.delete(cacheName);
                    }
                })
            );
        }).then(() => {
            console.log('Service Worker: Activation complete');
            return self.clients.claim();
        })
    );
});

// Fetch event - serve cached content when offline
self.addEventListener('fetch', event => {
    // Skip non-GET requests
    if (event.request.method !== 'GET') {
        return;
    }
    
    // Skip external requests
    if (!event.request.url.startsWith(self.location.origin)) {
        return;
    }
    
    event.respondWith(
        caches.match(event.request)
            .then(response => {
                // Return cached version if available
                if (response) {
                    return response;
                }
                
                // Otherwise fetch from network
                return fetch(event.request).then(response => {
                    // Don't cache non-successful responses
                    if (!response || response.status !== 200 || response.type !== 'basic') {
                        return response;
                    }
                    
                    // Clone the response for caching
                    const responseToCache = response.clone();
                    
                    // Cache the response for future use
                    caches.open(CACHE_NAME)
                        .then(cache => {
                            cache.put(event.request, responseToCache);
                        });
                    
                    return response;
                });
            })
            .catch(() => {
                // If both cache and network fail, show offline page for navigation requests
                if (event.request.destination === 'document') {
                    return caches.match(OFFLINE_PAGE);
                }
                
                // For other requests, return a generic offline response
                return new Response('Offline', {
                    status: 503,
                    statusText: 'Service Unavailable',
                    headers: new Headers({
                        'Content-Type': 'text/plain; charset=utf-8'
                    })
                });
            })
    );
});

// Background sync for data synchronization
self.addEventListener('sync', event => {
    console.log('Service Worker: Background sync triggered', event.tag);
    
    if (event.tag === 'sync-projects') {
        event.waitUntil(syncProjects());
    }
    
    if (event.tag === 'sync-photos') {
        event.waitUntil(syncPhotos());
    }
});

// Push notification handling
self.addEventListener('push', event => {
    console.log('Service Worker: Push received', event);
    
    const options = {
        body: event.data ? event.data.text() : 'התקבלה הודעה חדשה',
        icon: '/Inspector_pro/assets/icons/icon-192x192.svg',
        badge: '/Inspector_pro/assets/icons/favicon.svg',
        tag: 'inspectort-notification',
        requireInteraction: true,
        actions: [
            {
                action: 'open',
                title: 'פתח אפליקציה',
                icon: '/Inspector_pro/assets/icons/icon-192x192.svg'
            },
            {
                action: 'close',
                title: 'סגור',
                icon: '/Inspector_pro/assets/icons/favicon.svg'
            }
        ]
    };
    
    event.waitUntil(
        self.registration.showNotification('Inspectort Pro', options)
    );
});

// Notification click handling
self.addEventListener('notificationclick', event => {
    console.log('Service Worker: Notification clicked', event);
    
    event.notification.close();
    
    if (event.action === 'open') {
        event.waitUntil(
            clients.openWindow('/Inspector_pro/')
        );
    }
});

// Message handling from main thread
self.addEventListener('message', event => {
    console.log('Service Worker: Message received', event.data);
    
    if (event.data && event.data.type === 'SKIP_WAITING') {
        self.skipWaiting();
    }
    
    if (event.data && event.data.type === 'CACHE_PHOTO') {
        cachePhoto(event.data.photoUrl);
    }
});

// Helper functions
async function syncProjects() {
    try {
        console.log('Service Worker: Syncing projects...');
        
        // Get offline projects from IndexedDB or localStorage
        const offlineProjects = await getOfflineProjects();
        
        if (offlineProjects.length > 0) {
            // Send projects to server
            const response = await fetch('/api/projects/sync', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(offlineProjects)
            });
            
            if (response.ok) {
                console.log('Service Worker: Projects synced successfully');
                await clearOfflineProjects();
            } else {
                throw new Error('Failed to sync projects');
            }
        }
    } catch (error) {
        console.error('Service Worker: Project sync failed', error);
        throw error;
    }
}

async function syncPhotos() {
    try {
        console.log('Service Worker: Syncing photos...');
        
        // Get offline photos from IndexedDB
        const offlinePhotos = await getOfflinePhotos();
        
        if (offlinePhotos.length > 0) {
            // Upload photos to server
            for (const photo of offlinePhotos) {
                const formData = new FormData();
                formData.append('photo', photo.file);
                formData.append('metadata', JSON.stringify(photo.metadata));
                
                const response = await fetch('/api/photos/upload', {
                    method: 'POST',
                    body: formData
                });
                
                if (response.ok) {
                    await removeOfflinePhoto(photo.id);
                } else {
                    throw new Error(`Failed to upload photo ${photo.id}`);
                }
            }
            
            console.log('Service Worker: Photos synced successfully');
        }
    } catch (error) {
        console.error('Service Worker: Photo sync failed', error);
        throw error;
    }
}

async function cachePhoto(photoUrl) {
    try {
        const cache = await caches.open(CACHE_NAME);
        await cache.add(photoUrl);
        console.log('Service Worker: Photo cached', photoUrl);
    } catch (error) {
        console.error('Service Worker: Failed to cache photo', error);
    }
}

// IndexedDB helpers (simplified - would need proper implementation)
async function getOfflineProjects() {
    // TODO: Implement IndexedDB retrieval
    return [];
}

async function clearOfflineProjects() {
    // TODO: Implement IndexedDB clearing
    console.log('Service Worker: Offline projects cleared');
}

async function getOfflinePhotos() {
    // TODO: Implement IndexedDB retrieval
    return [];
}

async function removeOfflinePhoto(photoId) {
    // TODO: Implement IndexedDB removal
    console.log('Service Worker: Offline photo removed', photoId);
}

// Utility functions
function isNavigationRequest(request) {
    return request.mode === 'navigate' || 
           (request.method === 'GET' && request.headers.get('accept').includes('text/html'));
}

function isImageRequest(request) {
    return request.destination === 'image';
}

function shouldCacheRequest(request) {
    const url = new URL(request.url);
    
    // Cache same-origin requests
    if (url.origin === self.location.origin) {
        return true;
    }
    
    // Cache specific external resources (like fonts)
    if (url.hostname === 'fonts.googleapis.com' || url.hostname === 'fonts.gstatic.com') {
        return true;
    }
    
    return false;
}

// Periodic background sync (if supported)
if ('periodicSync' in self.registration) {
    self.addEventListener('periodicsync', event => {
        console.log('Service Worker: Periodic sync triggered', event.tag);
        
        if (event.tag === 'sync-all-data') {
            event.waitUntil(
                Promise.all([
                    syncProjects(),
                    syncPhotos()
                ])
            );
        }
    });
}

console.log('Service Worker: Script loaded'); 
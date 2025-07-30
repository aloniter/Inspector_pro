/**
 * Inspectort Pro - Service Worker
 * PWA Offline Support and Caching
 */

const CACHE_NAME = 'inspectort-pro-v3.1.2';
const OFFLINE_PAGE = '/Inspector_pro/offline.html';

// Files to cache for offline functionality
const CACHE_URLS = [
    '/Inspector_pro/',
    '/Inspector_pro/index.html',
    '/Inspector_pro/css/styles.css',
    '/Inspector_pro/js/app.js',
    '/Inspector_pro/manifest.json',
    '/Inspector_pro/inspector_icon.png',
    // Essential library CDNs for export functionality
    'https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js',
    'https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js',
    'https://cdnjs.cloudflare.com/ajax/libs/FileSaver.js/2.0.5/FileSaver.min.js'
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

// Fetch event - smart caching strategy for instant updates
self.addEventListener('fetch', event => {
    // Skip non-GET requests
    if (event.request.method !== 'GET') {
        return;
    }
    
    const url = new URL(event.request.url);
    
    // Network First for critical app files (HTML, CSS, JS) to ensure instant updates
    if (isCriticalAppFile(event.request)) {
        event.respondWith(
            fetch(event.request)
                .then(response => {
                    // Cache successful responses
                    if (response && response.status === 200) {
                        const responseToCache = response.clone();
                        caches.open(CACHE_NAME)
                            .then(cache => {
                                cache.put(event.request, responseToCache);
                            });
                    }
                    return response;
                })
                .catch(() => {
                    // Fallback to cache if network fails
                    return caches.match(event.request)
                        .then(cachedResponse => {
                            if (cachedResponse) {
                                return cachedResponse;
                            }
                            // Return offline page for document requests
                            if (event.request.destination === 'document') {
                                return caches.match(OFFLINE_PAGE);
                            }
                            throw new Error('No cached version available');
                        });
                })
        );
        return;
    }
    
    // Cache First for static assets (images, icons, etc.)
    if (isStaticAsset(event.request)) {
        event.respondWith(
            caches.match(event.request)
                .then(response => {
                    if (response) {
                        return response;
                    }
                    
                    return fetch(event.request).then(response => {
                        if (response && response.status === 200) {
                            const responseToCache = response.clone();
                            caches.open(CACHE_NAME)
                                .then(cache => {
                                    cache.put(event.request, responseToCache);
                                });
                        }
                        return response;
                    });
                })
                .catch(() => {
                    return new Response('Asset not available offline', {
                        status: 503,
                        statusText: 'Service Unavailable'
                    });
                })
        );
        return;
    }
    
    // Network Only for external CDN requests to ensure latest versions
    if (isCDNRequest(event.request)) {
        event.respondWith(
            fetch(event.request)
                .catch(() => {
                    // Try to serve from cache as last resort
                    return caches.match(event.request);
                })
        );
        return;
    }
    
    // Default strategy for other requests
    event.respondWith(
        fetch(event.request)
            .catch(() => caches.match(event.request))
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

// Utility functions for cache strategy
function isCriticalAppFile(request) {
    const url = new URL(request.url);
    const pathname = url.pathname;
    
    // App files that need instant updates
    return pathname.endsWith('.html') || 
           pathname.endsWith('.css') || 
           pathname.endsWith('.js') ||
           pathname.includes('/js/app.js') ||
           pathname.includes('/css/styles.css') ||
           pathname === '/Inspector_pro/' ||
           pathname === '/Inspector_pro/index.html';
}

function isStaticAsset(request) {
    const url = new URL(request.url);
    const pathname = url.pathname;
    
    // Static assets that can be cached longer
    return pathname.endsWith('.png') || 
           pathname.endsWith('.jpg') || 
           pathname.endsWith('.jpeg') || 
           pathname.endsWith('.gif') || 
           pathname.endsWith('.svg') ||
           pathname.endsWith('.webp') ||
           pathname.endsWith('.ico') ||
           pathname.includes('inspector_icon.png') ||
           pathname.includes('/assets/');
}

function isCDNRequest(request) {
    const url = new URL(request.url);
    
    // External CDN requests that should always fetch fresh
    return url.hostname === 'cdnjs.cloudflare.com' ||
           url.hostname === 'cdn.jsdelivr.net' ||
           url.hostname === 'unpkg.com' ||
           url.hostname === 'fonts.googleapis.com' ||
           url.hostname === 'fonts.gstatic.com';
}

function isNavigationRequest(request) {
    return request.mode === 'navigate' || 
           (request.method === 'GET' && request.headers.get('accept').includes('text/html'));
}

function isImageRequest(request) {
    return request.destination === 'image';
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
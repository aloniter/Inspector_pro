import UIKit

actor ThumbnailService {
    static let shared = ThumbnailService()

    private var cache: [String: UIImage] = [:]
    private let cacheLimit = 300

    func thumbnail(for relativePath: String) async -> UIImage? {
        let path = relativePath

        if let cached = cache[path] {
            return cached
        }

        guard let image = await ImageStorageService.shared.loadImage(at: path) else {
            return nil
        }
        let thumbnail = image.thumbnail(maxSize: AppConstants.thumbnailMaxSize)

        if cache.count >= cacheLimit {
            let keysToRemove = Array(cache.keys.prefix(cacheLimit / 2))
            for key in keysToRemove {
                cache.removeValue(forKey: key)
            }
        }
        cache[path] = thumbnail

        return thumbnail
    }

    func invalidate(path: String) {
        cache.removeValue(forKey: path)
    }

    func clearCache() {
        cache.removeAll()
    }
}

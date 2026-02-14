import UIKit
import SwiftUI

actor ThumbnailService {
    static let shared = ThumbnailService()

    private var cache: [String: UIImage] = [:]
    private let cacheLimit = 200

    func thumbnail(for relativePath: String?) async -> UIImage? {
        guard let path = relativePath else { return nil }

        if let cached = cache[path] {
            return cached
        }

        let image = await ImageStorageService.shared.loadThumbnail(at: path)

        if let image = image {
            if cache.count >= cacheLimit {
                let keysToRemove = Array(cache.keys.prefix(cacheLimit / 2))
                for key in keysToRemove {
                    cache.removeValue(forKey: key)
                }
            }
            cache[path] = image
        }

        return image
    }

    func invalidate(path: String) {
        cache.removeValue(forKey: path)
    }

    func clearCache() {
        cache.removeAll()
    }
}

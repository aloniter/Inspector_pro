import Foundation
import CryptoKit

actor ExportCache {
    static let shared = ExportCache()

    private let cacheURL = AppConstants.exportCacheURL

    /// Get cached compressed image data, or compress and cache it.
    func compressedImageData(
        for photo: Photo,
        quality: ImageQuality
    ) async -> Data? {
        let key = cacheKey(for: photo, quality: quality)
        let qualityDir = cacheURL.appendingPathComponent(quality.rawValue)
        let cachedURL = qualityDir.appendingPathComponent("\(key).jpg")

        // Check cache
        if FileManagerService.shared.fileExists(at: cachedURL),
           let data = try? Data(contentsOf: cachedURL) {
            return data
        }

        // Load original image
        let imagePath = photo.exportImagePath
        let fullURL = AppConstants.imagesBaseURL.appendingPathComponent(imagePath)
        guard let imageData = try? Data(contentsOf: fullURL) else { return nil }

        // Compress
        guard let compressed = ImageCompressor.compressData(imageData, quality: quality) else {
            return nil
        }

        // Cache the result
        FileManagerService.shared.ensureDirectoryExists(at: qualityDir)
        try? compressed.write(to: cachedURL)

        return compressed
    }

    /// Invalidate cache for a specific photo (all quality levels)
    func invalidate(for photo: Photo) {
        for quality in ImageQuality.allCases {
            let key = cacheKey(for: photo, quality: quality)
            let cachedURL = cacheURL
                .appendingPathComponent(quality.rawValue)
                .appendingPathComponent("\(key).jpg")
            FileManagerService.shared.deleteItem(at: cachedURL)
        }
    }

    /// Clear all cached data
    func clearAll() {
        FileManagerService.shared.deleteItem(at: cacheURL)
        FileManagerService.shared.ensureDirectoryExists(at: cacheURL)
    }

    /// Cache key based on image path + file attributes
    private func cacheKey(for photo: Photo, quality: ImageQuality) -> String {
        let imagePath = photo.exportImagePath
        let fullURL = AppConstants.imagesBaseURL.appendingPathComponent(imagePath)

        var input = imagePath + quality.rawValue
        if let size = FileManagerService.shared.fileSize(at: fullURL) {
            input += "\(size)"
        }
        if let mdate = FileManagerService.shared.modificationDate(at: fullURL) {
            input += "\(mdate.timeIntervalSince1970)"
        }

        let hash = SHA256.hash(data: Data(input.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined().prefix(32).description
    }
}

import UIKit

actor ImageStorageService {
    static let shared = ImageStorageService()

    private let fm = FileManager.default
    private let baseURL = AppConstants.imagesBaseURL

    /// Save an image from camera/gallery. Returns (imagePath, thumbnailPath) relative to imagesBaseURL.
    func saveImage(
        _ image: UIImage,
        projectID: String,
        findingID: String
    ) throws -> (imagePath: String, thumbnailPath: String) {
        let dirRelative = "\(projectID)/\(findingID)"
        let dirURL = baseURL.appendingPathComponent(dirRelative)
        FileManagerService.shared.ensureDirectoryExists(at: dirURL)

        let uuid = UUID().uuidString

        // Save original (resized to max import width)
        let resized = image.resized(maxWidth: AppConstants.importMaxWidth)
        guard let imageData = resized.jpegDataStripped(quality: 0.85) else {
            throw ImageStorageError.compressionFailed
        }
        let imageName = "\(uuid).jpg"
        let imageRelPath = "\(dirRelative)/\(imageName)"
        let imageURL = baseURL.appendingPathComponent(imageRelPath)
        try imageData.write(to: imageURL)

        // Save thumbnail
        let thumb = image.thumbnail(maxSize: AppConstants.thumbnailMaxSize)
        guard let thumbData = thumb.jpegDataStripped(quality: AppConstants.thumbnailJPEGQuality) else {
            throw ImageStorageError.compressionFailed
        }
        let thumbName = "thumb_\(uuid).jpg"
        let thumbRelPath = "\(dirRelative)/\(thumbName)"
        let thumbURL = baseURL.appendingPathComponent(thumbRelPath)
        try thumbData.write(to: thumbURL)

        return (imageRelPath, thumbRelPath)
    }

    /// Save annotated composite image. Returns annotatedPath relative to imagesBaseURL.
    func saveAnnotatedImage(
        _ image: UIImage,
        projectID: String,
        findingID: String,
        originalUUID: String
    ) throws -> String {
        let dirRelative = "\(projectID)/\(findingID)"
        let dirURL = baseURL.appendingPathComponent(dirRelative)
        FileManagerService.shared.ensureDirectoryExists(at: dirURL)

        guard let data = image.pngData() else {
            throw ImageStorageError.compressionFailed
        }
        let annotatedName = "ann_\(originalUUID).png"
        let annotatedRelPath = "\(dirRelative)/\(annotatedName)"
        let annotatedURL = baseURL.appendingPathComponent(annotatedRelPath)
        try data.write(to: annotatedURL)

        return annotatedRelPath
    }

    /// Load full-resolution image from relative path
    func loadImage(at relativePath: String) -> UIImage? {
        let url = baseURL.appendingPathComponent(relativePath)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// Load thumbnail from relative path
    func loadThumbnail(at relativePath: String) -> UIImage? {
        let url = baseURL.appendingPathComponent(relativePath)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// Full URL for a relative image path
    func fullURL(for relativePath: String) -> URL {
        baseURL.appendingPathComponent(relativePath)
    }

    /// Delete all images for a list of photos
    func deletePhotos(_ photos: [Photo]) {
        for photo in photos {
            deleteFile(at: photo.imagePath)
            if let thumb = photo.thumbnailPath {
                deleteFile(at: thumb)
            }
            if let annotated = photo.annotatedPath {
                deleteFile(at: annotated)
            }
        }
    }

    /// Delete the entire directory for a project
    func deleteProjectDirectory(projectID: String) {
        let dirURL = baseURL.appendingPathComponent(projectID)
        FileManagerService.shared.deleteItem(at: dirURL)
    }

    private func deleteFile(at relativePath: String) {
        let url = baseURL.appendingPathComponent(relativePath)
        FileManagerService.shared.deleteItem(at: url)
    }
}

enum ImageStorageError: LocalizedError {
    case compressionFailed
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .compressionFailed: return "Failed to compress image"
        case .saveFailed: return "Failed to save image to disk"
        }
    }
}

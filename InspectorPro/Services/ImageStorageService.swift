import UIKit

actor ImageStorageService {
    static let shared = ImageStorageService()

    private let baseURL = AppConstants.imagesBaseURL

    /// Save an image from camera/gallery. Returns relative image path.
    func saveImage(
        _ image: UIImage,
        projectID: String
    ) throws -> String {
        let dirRelative = projectID
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
        try imageData.write(to: imageURL, options: .atomic)

        return imageRelPath
    }

    /// Save annotated composite image. Returns relative path.
    func saveAnnotatedImage(
        _ image: UIImage,
        projectID: String,
        originalUUID: String
    ) throws -> String {
        let dirRelative = projectID
        let dirURL = baseURL.appendingPathComponent(dirRelative)
        FileManagerService.shared.ensureDirectoryExists(at: dirURL)

        guard let data = image.jpegDataStripped(quality: 0.92) else {
            throw ImageStorageError.compressionFailed
        }
        let annotatedName = "ann_\(originalUUID).jpg"
        let annotatedRelPath = "\(dirRelative)/\(annotatedName)"
        let annotatedURL = baseURL.appendingPathComponent(annotatedRelPath)
        try data.write(to: annotatedURL, options: .atomic)

        return annotatedRelPath
    }

    /// Load full-resolution image from relative path
    func loadImage(at relativePath: String) -> UIImage? {
        let url = baseURL.appendingPathComponent(relativePath)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// Full URL for a relative image path
    func fullURL(for relativePath: String) -> URL {
        baseURL.appendingPathComponent(relativePath)
    }

    /// Delete original and optional annotated image files for one photo.
    func deletePhotoFiles(originalPath: String, annotatedPath: String?) {
        deleteFile(at: originalPath)
        if let annotatedPath {
            deleteFile(at: annotatedPath)
        }
    }

    /// Delete one image file by relative path.
    func deleteImage(at relativePath: String) {
        deleteFile(at: relativePath)
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

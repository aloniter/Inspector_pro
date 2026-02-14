import Foundation

final class FileManagerService: @unchecked Sendable {
    static let shared = FileManagerService()
    private let fm = FileManager.default

    private init() {}

    func ensureDirectoriesExist() {
        let dirs = [
            AppConstants.appBaseURL,
            AppConstants.imagesBaseURL,
            AppConstants.exportCacheURL,
        ]
        for dir in dirs {
            if !fm.fileExists(atPath: dir.path) {
                try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
            }
        }
    }

    func ensureDirectoryExists(at url: URL) {
        if !fm.fileExists(atPath: url.path) {
            try? fm.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    func deleteItem(at url: URL) {
        try? fm.removeItem(at: url)
    }

    func fileExists(at url: URL) -> Bool {
        fm.fileExists(atPath: url.path)
    }

    func fileSize(at url: URL) -> Int? {
        guard let attrs = try? fm.attributesOfItem(atPath: url.path) else { return nil }
        return attrs[.size] as? Int
    }

    func modificationDate(at url: URL) -> Date? {
        guard let attrs = try? fm.attributesOfItem(atPath: url.path) else { return nil }
        return attrs[.modificationDate] as? Date
    }
}

import Foundation

final class FileManagerService: @unchecked Sendable {
    static let shared = FileManagerService()
    private let fm = FileManager.default

    private init() {}

    func ensureDirectoriesExist() {
        let dirs = [
            AppConstants.appBaseURL,
            AppConstants.imagesBaseURL,
            AppConstants.brandingAssetsURL,
            AppConstants.exportsURL,
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

    /// Remove a directory only when it contains no entries. Safe no-op if the
    /// directory is missing or still holds files (e.g. a moved report's photos).
    func removeDirectoryIfEmpty(at url: URL) {
        guard let contents = try? fm.contentsOfDirectory(atPath: url.path) else { return }
        guard contents.isEmpty else { return }
        try? fm.removeItem(at: url)
    }

    /// Delete every file inside a directory, keeping the directory itself.
    func emptyDirectory(at url: URL) {
        guard let contents = try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else { return }
        for item in contents {
            try? fm.removeItem(at: item)
        }
    }

    /// Launch-time export hygiene. Exports are transient — each one is deleted
    /// after its share completes — so this clears any that survived an interrupted
    /// share or an older app version, and removes the directory left behind by the
    /// now-removed export image cache. The Exports directory itself is preserved so
    /// future exports can be written.
    func purgeExports() {
        emptyDirectory(at: AppConstants.exportsURL)
        deleteItem(at: AppConstants.appBaseURL.appendingPathComponent("ExportCache"))
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

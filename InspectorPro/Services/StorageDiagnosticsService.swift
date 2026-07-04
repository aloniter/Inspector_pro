import Foundation

struct StorageKnownPhotoReference: Hashable {
    let originalPath: String
    let annotatedPath: String?
}

struct StorageFileCategorySummary: Equatable {
    let count: Int
    let bytes: Int64
}

struct StorageDiagnosticsReport: Equatable {
    let documentsDirectoryBytes: Int64
    let inspectorProDirectoryBytes: Int64
    let imagesDirectoryBytes: Int64
    let exportsDirectoryBytes: Int64
    let legacyExportCacheDirectoryBytes: Int64
    let brandingDirectoryBytes: Int64
    let temporaryDirectoryBytes: Int64
    let libraryDirectoryBytes: Int64
    let cachesDirectoryBytes: Int64
    let applicationSupportDirectoryBytes: Int64
    let httpStoragesDirectoryBytes: Int64
    let otherLibraryDirectoryBytes: Int64
    let swiftDataDatabaseBytes: Int64
    let originalJPGFiles: StorageFileCategorySummary
    let annotatedJPGFiles: StorageFileCategorySummary
    let pdfFiles: StorageFileCategorySummary
    let docxFiles: StorageFileCategorySummary
    let temporaryFiles: StorageFileCategorySummary
    let orphanImageFiles: StorageFileCategorySummary
    let emptyImageFolders: [String]
    let potentialOrphanImagePaths: [String]
    let docxTemporaryPackageDirectories: StorageFileCategorySummary
    let swiftDataDatabasePaths: [String]
}

enum StorageDiagnosticsService {
    static func makeReport(
        knownPhotoReferences: [StorageKnownPhotoReference]? = nil,
        documentsURL: URL = AppConstants.documentsURL,
        inspectorProURL: URL = AppConstants.appBaseURL,
        imagesURL: URL = AppConstants.imagesBaseURL,
        exportsURL: URL = AppConstants.exportsURL,
        legacyExportCacheURL: URL = AppConstants.appBaseURL.appendingPathComponent("ExportCache"),
        brandingURL: URL = AppConstants.brandingAssetsURL,
        temporaryURL: URL = FileManager.default.temporaryDirectory,
        libraryURL: URL? = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first,
        cachesURL: URL? = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first,
        applicationSupportURL: URL? = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first,
        httpStoragesURL: URL? = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("HTTPStorages"),
        fileManager: FileManager = .default
    ) -> StorageDiagnosticsReport {
        let documentFiles = regularFiles(under: documentsURL, baseURL: documentsURL, fileManager: fileManager)
        let inspectorProFiles = regularFiles(under: inspectorProURL, baseURL: inspectorProURL, fileManager: fileManager)
        let imageFiles = regularFiles(under: imagesURL, baseURL: imagesURL, fileManager: fileManager)
        let exportFiles = regularFiles(under: exportsURL, baseURL: exportsURL, fileManager: fileManager)
        let legacyExportCacheFiles = regularFiles(under: legacyExportCacheURL, baseURL: legacyExportCacheURL, fileManager: fileManager)
        let brandingFiles = regularFiles(under: brandingURL, baseURL: brandingURL, fileManager: fileManager)
        let temporaryFiles = regularFiles(under: temporaryURL, baseURL: temporaryURL, fileManager: fileManager)
        let libraryFiles = libraryURL.map {
            regularFiles(under: $0, baseURL: $0, fileManager: fileManager)
        } ?? []
        let cacheFiles = cachesURL.map {
            regularFiles(under: $0, baseURL: $0, fileManager: fileManager)
        } ?? []
        let applicationSupportFiles = applicationSupportURL.map {
            regularFiles(under: $0, baseURL: $0, fileManager: fileManager)
        } ?? []
        let httpStorageFiles = httpStoragesURL.map {
            regularFiles(under: $0, baseURL: $0, fileManager: fileManager)
        } ?? []

        let knownImagePaths = knownPhotoReferences.map { references in
            Set(references.flatMap { reference in
                [reference.originalPath, reference.annotatedPath].compactMap { $0 }
            })
        }
        let orphanImageEntries = knownImagePaths.map { knownPaths in
            imageFiles.filter { isImagePath($0.relativePath) && !knownPaths.contains($0.relativePath) }
        } ?? []
        let docxTempDirectories = directories(
            under: temporaryURL,
            baseURL: temporaryURL,
            fileManager: fileManager
        ).filter { entry in
            URL(fileURLWithPath: entry.relativePath).lastPathComponent.hasPrefix("docx_export_")
        }
        let swiftDataFiles = applicationSupportFiles.filter { isLikelySwiftDataDatabasePath($0.relativePath) }
        let libraryBytes = totalBytes(libraryFiles)
        let cacheBytes = totalBytes(cacheFiles)
        let applicationSupportBytes = totalBytes(applicationSupportFiles)
        let httpStorageBytes = totalBytes(httpStorageFiles)

        return StorageDiagnosticsReport(
            documentsDirectoryBytes: totalBytes(documentFiles),
            inspectorProDirectoryBytes: totalBytes(inspectorProFiles),
            imagesDirectoryBytes: totalBytes(imageFiles),
            exportsDirectoryBytes: totalBytes(exportFiles),
            legacyExportCacheDirectoryBytes: totalBytes(legacyExportCacheFiles),
            brandingDirectoryBytes: totalBytes(brandingFiles),
            temporaryDirectoryBytes: totalBytes(temporaryFiles),
            libraryDirectoryBytes: libraryBytes,
            cachesDirectoryBytes: cacheBytes,
            applicationSupportDirectoryBytes: applicationSupportBytes,
            httpStoragesDirectoryBytes: httpStorageBytes,
            otherLibraryDirectoryBytes: max(libraryBytes - cacheBytes - applicationSupportBytes - httpStorageBytes, 0),
            swiftDataDatabaseBytes: totalBytes(swiftDataFiles),
            originalJPGFiles: summary(for: imageFiles.filter(isOriginalJPGFile)),
            annotatedJPGFiles: summary(for: imageFiles.filter(isAnnotatedJPGFile)),
            pdfFiles: summary(for: allContainerFiles(
                documentFiles: documentFiles,
                temporaryFiles: temporaryFiles,
                libraryFiles: libraryFiles
            ).filter { $0.pathExtension == "pdf" }),
            docxFiles: summary(for: allContainerFiles(
                documentFiles: documentFiles,
                temporaryFiles: temporaryFiles,
                libraryFiles: libraryFiles
            ).filter { $0.pathExtension == "docx" }),
            temporaryFiles: summary(for: temporaryFiles),
            orphanImageFiles: summary(for: orphanImageEntries),
            emptyImageFolders: emptyDirectories(under: imagesURL, baseURL: imagesURL, fileManager: fileManager),
            potentialOrphanImagePaths: orphanImageEntries.map(\.relativePath).sorted(),
            docxTemporaryPackageDirectories: StorageFileCategorySummary(
                count: docxTempDirectories.count,
                bytes: docxTempDirectories.reduce(0) { $0 + directorySize(at: $1.url, fileManager: fileManager) }
            ),
            swiftDataDatabasePaths: swiftDataFiles.map(\.relativePath).sorted()
        )
    }

    static func formattedReport(_ report: StorageDiagnosticsReport) -> String {
        let swiftDataFiles = report.swiftDataDatabasePaths.joined(separator: ", ")
        return [
            "Documents total: \(formatBytes(report.documentsDirectoryBytes))",
            "InspectorPro total: \(formatBytes(report.inspectorProDirectoryBytes))",
            "Images: \(formatBytes(report.imagesDirectoryBytes))",
            "Exports: \(formatBytes(report.exportsDirectoryBytes))",
            "Legacy ExportCache: \(formatBytes(report.legacyExportCacheDirectoryBytes))",
            "Branding: \(formatBytes(report.brandingDirectoryBytes))",
            "Temp: \(formatBytes(report.temporaryDirectoryBytes))",
            "Library total: \(formatBytes(report.libraryDirectoryBytes))",
            "Caches: \(formatBytes(report.cachesDirectoryBytes))",
            "Application Support: \(formatBytes(report.applicationSupportDirectoryBytes))",
            "HTTPStorages: \(formatBytes(report.httpStoragesDirectoryBytes))",
            "Other Library: \(formatBytes(report.otherLibraryDirectoryBytes))",
            "SwiftData: \(formatBytes(report.swiftDataDatabaseBytes))",
            "Original images: \(report.originalJPGFiles.count) files, \(formatBytes(report.originalJPGFiles.bytes))",
            "Annotated images: \(report.annotatedJPGFiles.count) files, \(formatBytes(report.annotatedJPGFiles.bytes))",
            "PDF exports: \(report.pdfFiles.count) files, \(formatBytes(report.pdfFiles.bytes))",
            "DOCX exports: \(report.docxFiles.count) files, \(formatBytes(report.docxFiles.bytes))",
            "Temporary files: \(report.temporaryFiles.count) files, \(formatBytes(report.temporaryFiles.bytes))",
            "DOCX temp packages: \(report.docxTemporaryPackageDirectories.count) dirs, \(formatBytes(report.docxTemporaryPackageDirectories.bytes))",
            "Orphans: \(report.orphanImageFiles.count) files, \(formatBytes(report.orphanImageFiles.bytes))",
            "Empty image folders: \(report.emptyImageFolders.count)",
            "SwiftData files: \(swiftDataFiles)",
        ].joined(separator: "\n")
    }

    #if DEBUG
    static func debugPrintReport(label: String? = nil, _ report: StorageDiagnosticsReport? = nil) {
        let report = report ?? makeReport()
        let prefix = label.map { "[StorageDiagnostics][\($0)]" } ?? "[StorageDiagnostics]"
        print("\(prefix)\n\(formattedReport(report))")
    }
    #endif

    private struct FileEntry {
        let url: URL
        let relativePath: String
        let size: Int64

        var pathExtension: String {
            url.pathExtension.lowercased()
        }
    }

    private struct DirectoryEntry {
        let url: URL
        let relativePath: String
    }

    private static func allContainerFiles(
        documentFiles: [FileEntry],
        temporaryFiles: [FileEntry],
        libraryFiles: [FileEntry]
    ) -> [FileEntry] {
        documentFiles + temporaryFiles + libraryFiles
    }

    private static func regularFiles(
        under rootURL: URL,
        baseURL: URL,
        fileManager: FileManager
    ) -> [FileEntry] {
        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var entries: [FileEntry] = []
        for case let url as URL in enumerator {
            guard let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                  values.isRegularFile == true else {
                continue
            }

            entries.append(FileEntry(
                url: url,
                relativePath: relativePath(for: url, baseURL: baseURL),
                size: Int64(values.fileSize ?? 0)
            ))
        }
        return entries
    }

    private static func directories(
        under rootURL: URL,
        baseURL: URL,
        fileManager: FileManager
    ) -> [DirectoryEntry] {
        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var entries: [DirectoryEntry] = []
        for case let url as URL in enumerator {
            guard let values = try? url.resourceValues(forKeys: [.isDirectoryKey]),
                  values.isDirectory == true else {
                continue
            }

            entries.append(DirectoryEntry(
                url: url,
                relativePath: relativePath(for: url, baseURL: baseURL)
            ))
        }
        return entries
    }

    private static func emptyDirectories(
        under rootURL: URL,
        baseURL: URL,
        fileManager: FileManager
    ) -> [String] {
        directories(under: rootURL, baseURL: baseURL, fileManager: fileManager)
            .filter { entry in
                (try? fileManager.contentsOfDirectory(atPath: entry.url.path).isEmpty) == true
            }
            .map(\.relativePath)
            .filter { !$0.isEmpty }
            .sorted()
    }

    private static func directorySize(at url: URL, fileManager: FileManager) -> Int64 {
        totalBytes(regularFiles(under: url, baseURL: url, fileManager: fileManager))
    }

    private static func totalBytes(_ entries: [FileEntry]) -> Int64 {
        entries.reduce(0) { $0 + $1.size }
    }

    private static func summary(for entries: [FileEntry]) -> StorageFileCategorySummary {
        StorageFileCategorySummary(count: entries.count, bytes: totalBytes(entries))
    }

    private static func isOriginalJPGFile(_ entry: FileEntry) -> Bool {
        entry.pathExtension == "jpg" && !URL(fileURLWithPath: entry.relativePath).lastPathComponent.hasPrefix("ann_")
    }

    private static func isAnnotatedJPGFile(_ entry: FileEntry) -> Bool {
        entry.pathExtension == "jpg" && URL(fileURLWithPath: entry.relativePath).lastPathComponent.hasPrefix("ann_")
    }

    private static func isImagePath(_ path: String) -> Bool {
        switch URL(fileURLWithPath: path).pathExtension.lowercased() {
        case "jpg", "jpeg", "png", "heic":
            return true
        default:
            return false
        }
    }

    private static func isLikelySwiftDataDatabasePath(_ path: String) -> Bool {
        let name = URL(fileURLWithPath: path).lastPathComponent.lowercased()
        return name.hasSuffix(".store")
            || name.hasSuffix(".store-shm")
            || name.hasSuffix(".store-wal")
            || name.hasSuffix(".sqlite")
            || name.hasSuffix(".sqlite-shm")
            || name.hasSuffix(".sqlite-wal")
    }

    private static func relativePath(for url: URL, baseURL: URL) -> String {
        let basePath = baseURL.standardizedFileURL.path
        let path = url.standardizedFileURL.path
        guard path.hasPrefix(basePath) else { return url.lastPathComponent }

        let startIndex = path.index(path.startIndex, offsetBy: basePath.count)
        let suffix = path[startIndex...].trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return String(suffix)
    }

    private static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

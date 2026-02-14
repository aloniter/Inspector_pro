import Foundation

enum AppConstants {
    static let appDirectoryName = "InspectorPro"
    static let imagesDirectoryName = "Images"
    static let exportCacheDirectoryName = "ExportCache"
    static let thumbnailMaxSize: CGFloat = 200
    static let thumbnailJPEGQuality: CGFloat = 0.6
    static let importMaxWidth: CGFloat = 2000

    static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static var appBaseURL: URL {
        documentsURL.appendingPathComponent(appDirectoryName)
    }

    static var imagesBaseURL: URL {
        appBaseURL.appendingPathComponent(imagesDirectoryName)
    }

    static var exportCacheURL: URL {
        appBaseURL.appendingPathComponent(exportCacheDirectoryName)
    }
}

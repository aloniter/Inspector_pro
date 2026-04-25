import Foundation
import SwiftData

typealias PhotoRecord = InspectorProSchemaV9.PhotoRecord

extension InspectorProSchemaV9.PhotoRecord {
    var displayImagePath: String {
        guard let annotatedImagePath else { return imagePath }

        if imageFileExists(at: annotatedImagePath) {
            return annotatedImagePath
        }

        if imageFileExists(at: imagePath) {
            return imagePath
        }

        return annotatedImagePath
    }

    private func imageFileExists(at relativePath: String) -> Bool {
        let url = AppConstants.imagesBaseURL.appendingPathComponent(relativePath)
        return FileManager.default.fileExists(atPath: url.path)
    }
}

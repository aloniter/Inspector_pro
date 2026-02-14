import Foundation
import SwiftData

@Model
final class Photo {
    var imagePath: String
    var thumbnailPath: String?
    var annotatedPath: String?
    var annotationData: Data?
    var order: Int
    var caption: String
    var createdAt: Date

    var finding: Finding?

    /// The path to use for export: annotated version if available, otherwise original
    var exportImagePath: String {
        annotatedPath ?? imagePath
    }

    init(
        imagePath: String,
        order: Int = 0,
        caption: String = ""
    ) {
        self.imagePath = imagePath
        self.order = order
        self.caption = caption
        self.createdAt = .now
    }
}

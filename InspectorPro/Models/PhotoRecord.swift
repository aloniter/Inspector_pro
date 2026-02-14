import Foundation
import SwiftData

@Model
final class PhotoRecord {
    @Attribute(.unique) var id: UUID
    var imagePath: String
    var annotatedImagePath: String?
    var freeText: String
    var position: Int
    var createdAt: Date

    var project: Project?

    var displayImagePath: String {
        annotatedImagePath ?? imagePath
    }

    init(
        id: UUID = UUID(),
        imagePath: String,
        annotatedImagePath: String? = nil,
        freeText: String = "",
        position: Int = 0,
        createdAt: Date = .now
    ) {
        self.id = id
        self.imagePath = imagePath
        self.annotatedImagePath = annotatedImagePath
        self.freeText = freeText
        self.position = position
        self.createdAt = createdAt
    }
}

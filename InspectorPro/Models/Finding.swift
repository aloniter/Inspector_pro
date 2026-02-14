import Foundation
import SwiftData

@Model
final class Finding {
    var number: Int
    var room: String
    var title: String
    var findingDescription: String
    var recommendation: String
    var severity: Severity
    var order: Int
    var createdAt: Date

    var project: Project?

    @Relationship(deleteRule: .cascade, inverse: \Photo.finding)
    var photos: [Photo] = []

    var sortedPhotos: [Photo] {
        photos.sorted { $0.order < $1.order }
    }

    init(
        number: Int,
        room: String = "",
        title: String = "",
        findingDescription: String = "",
        recommendation: String = "",
        severity: Severity = .medium,
        order: Int = 0
    ) {
        self.number = number
        self.room = room
        self.title = title
        self.findingDescription = findingDescription
        self.recommendation = recommendation
        self.severity = severity
        self.order = order
        self.createdAt = .now
    }
}

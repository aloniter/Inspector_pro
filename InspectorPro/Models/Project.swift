import Foundation
import SwiftData

@Model
final class Project {
    @Attribute(.unique) var id: UUID
    var name: String
    var address: String?
    var date: Date
    var notes: String?

    @Relationship(deleteRule: .cascade, inverse: \PhotoRecord.project)
    var photos: [PhotoRecord] = []

    var sortedPhotos: [PhotoRecord] {
        photos.sorted { lhs, rhs in
            if lhs.position != rhs.position {
                return lhs.position < rhs.position
            }

            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt < rhs.createdAt
            }

            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    init(
        id: UUID = UUID(),
        name: String = "",
        address: String? = nil,
        date: Date = .now,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.date = date
        self.notes = notes
    }
}

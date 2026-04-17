import Foundation
import SwiftData

typealias Project = InspectorProSchemaV5.Project

extension InspectorProSchemaV5.Project {
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
}

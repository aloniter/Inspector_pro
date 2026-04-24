import Foundation
import SwiftData

typealias Project = InspectorProSchemaV9.Project
typealias Report = InspectorProSchemaV9.Report

extension InspectorProSchemaV9.Project {
    var sortedReports: [Report] {
        reports.sorted { lhs, rhs in
            if lhs.date != rhs.date {
                return lhs.date > rhs.date
            }

            return lhs.id.uuidString < rhs.id.uuidString
        }
    }
}

extension InspectorProSchemaV9.Report {
    var reportAddress: String? {
        if let address, !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return address
        }

        return project?.address
    }

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

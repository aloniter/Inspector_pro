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

    var photoFileReferencesForDeletion: [(originalPath: String, annotatedPath: String?)] {
        reports.flatMap { report in
            report.photos.map { photo in
                (originalPath: photo.imagePath, annotatedPath: photo.annotatedImagePath)
            }
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

    /// Number of open defects in the report, derived from the count of logical
    /// report photos. Each `PhotoRecord` is one defect; an annotated copy lives on
    /// the same record (`annotatedImagePath`) and is never counted separately.
    var openDefectCount: Int {
        photos.count
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

    @discardableResult
    func move(to destinationProject: Project) -> Bool {
        guard project?.id != destinationProject.id else {
            return false
        }

        project = destinationProject
        return true
    }
}

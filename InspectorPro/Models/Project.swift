import Foundation
import SwiftData

@Model
final class Project {
    var title: String
    var address: String
    var inspectorName: String
    var date: Date
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Finding.project)
    var findings: [Finding] = []

    var sortedFindings: [Finding] {
        findings.sorted { $0.order < $1.order }
    }

    var nextFindingNumber: Int {
        (findings.map(\.number).max() ?? 0) + 1
    }

    init(
        title: String = "",
        address: String = "",
        inspectorName: String = "",
        date: Date = .now,
        notes: String = ""
    ) {
        self.title = title
        self.address = address
        self.inspectorName = inspectorName
        self.date = date
        self.notes = notes
        self.createdAt = .now
        self.updatedAt = .now
    }
}

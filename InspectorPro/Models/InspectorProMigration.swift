import Foundation
import SwiftData

enum InspectorProSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Project.self, Finding.self, Photo.self]
    }

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

    @Model
    final class Finding {
        enum LegacySeverity: String, Codable {
            case low
            case medium
            case high
        }

        var number: Int
        var room: String
        var title: String
        var findingDescription: String
        var recommendation: String
        var severity: LegacySeverity
        var order: Int
        var createdAt: Date

        var project: Project?

        @Relationship(deleteRule: .cascade, inverse: \Photo.finding)
        var photos: [Photo] = []

        init(
            number: Int = 0,
            room: String = "",
            title: String = "",
            findingDescription: String = "",
            recommendation: String = "",
            severity: LegacySeverity = .medium,
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

        init(
            imagePath: String = "",
            thumbnailPath: String? = nil,
            annotatedPath: String? = nil,
            annotationData: Data? = nil,
            order: Int = 0,
            caption: String = "",
            createdAt: Date = .now
        ) {
            self.imagePath = imagePath
            self.thumbnailPath = thumbnailPath
            self.annotatedPath = annotatedPath
            self.annotationData = annotationData
            self.order = order
            self.caption = caption
            self.createdAt = createdAt
        }
    }
}

enum InspectorProSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Project.self, PhotoRecord.self]
    }

    @Model
    final class Project {
        @Attribute(.unique) var id: UUID
        var name: String
        var address: String?
        var date: Date
        var notes: String?

        @Relationship(deleteRule: .cascade, inverse: \PhotoRecord.project)
        var photos: [PhotoRecord] = []

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

    @Model
    final class PhotoRecord {
        @Attribute(.unique) var id: UUID
        var imagePath: String
        var annotatedImagePath: String?
        var freeText: String
        var createdAt: Date

        var project: Project?

        init(
            id: UUID = UUID(),
            imagePath: String,
            annotatedImagePath: String? = nil,
            freeText: String = "",
            createdAt: Date = .now
        ) {
            self.id = id
            self.imagePath = imagePath
            self.annotatedImagePath = annotatedImagePath
            self.freeText = freeText
            self.createdAt = createdAt
        }
    }
}

enum InspectorProSchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Project.self, PhotoRecord.self]
    }
}

enum InspectorProMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [InspectorProSchemaV1.self, InspectorProSchemaV2.self, InspectorProSchemaV3.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1ToV2, migrateV2ToV3]
    }

    static let migrateV1ToV2 = MigrationStage.custom(
        fromVersion: InspectorProSchemaV1.self,
        toVersion: InspectorProSchemaV2.self,
        willMigrate: { context in
            let fetchDescriptor = FetchDescriptor<InspectorProSchemaV1.Project>()
            let legacyProjects = try context.fetch(fetchDescriptor)
            let payload = legacyProjects.map { MigrationProjectPayload(legacyProject: $0) }

            let data = try JSONEncoder().encode(payload)
            try data.write(to: migrationPayloadV1ToV2URL, options: .atomic)

            // Remove legacy records so destination only contains migrated entities.
            for project in legacyProjects {
                context.delete(project)
            }
            try context.save()
        },
        didMigrate: { context in
            guard FileManager.default.fileExists(atPath: migrationPayloadV1ToV2URL.path) else { return }

            defer { try? FileManager.default.removeItem(at: migrationPayloadV1ToV2URL) }

            let data = try Data(contentsOf: migrationPayloadV1ToV2URL)
            let legacyProjects = try JSONDecoder().decode([MigrationProjectPayload].self, from: data)

            for legacyProject in legacyProjects {
                let project = InspectorProSchemaV2.Project(
                    id: UUID(),
                    name: legacyProject.name,
                    address: legacyProject.address,
                    date: legacyProject.date,
                    notes: legacyProject.notes
                )
                context.insert(project)

                for legacyPhoto in legacyProject.photos {
                    let photoRecord = InspectorProSchemaV2.PhotoRecord(
                        id: UUID(),
                        imagePath: legacyPhoto.imagePath,
                        annotatedImagePath: legacyPhoto.annotatedImagePath,
                        freeText: legacyPhoto.freeText,
                        createdAt: legacyPhoto.createdAt
                    )
                    photoRecord.project = project
                    context.insert(photoRecord)
                }
            }

            try context.save()
        }
    )

    static let migrateV2ToV3 = MigrationStage.custom(
        fromVersion: InspectorProSchemaV2.self,
        toVersion: InspectorProSchemaV3.self,
        willMigrate: { context in
            let fetchDescriptor = FetchDescriptor<InspectorProSchemaV2.Project>()
            let legacyProjects = try context.fetch(fetchDescriptor)
            let payload = legacyProjects.map(MigrationProjectV2Payload.init)

            let data = try JSONEncoder().encode(payload)
            try data.write(to: migrationPayloadV2ToV3URL, options: .atomic)

            for project in legacyProjects {
                context.delete(project)
            }
            try context.save()
        },
        didMigrate: { context in
            guard FileManager.default.fileExists(atPath: migrationPayloadV2ToV3URL.path) else { return }

            defer { try? FileManager.default.removeItem(at: migrationPayloadV2ToV3URL) }

            let data = try Data(contentsOf: migrationPayloadV2ToV3URL)
            let legacyProjects = try JSONDecoder().decode([MigrationProjectV2Payload].self, from: data)

            for legacyProject in legacyProjects {
                let project = Project(
                    id: legacyProject.id,
                    name: legacyProject.name,
                    address: legacyProject.address,
                    date: legacyProject.date,
                    notes: legacyProject.notes
                )
                context.insert(project)

                for (index, legacyPhoto) in legacyProject.photos.enumerated() {
                    let photoRecord = PhotoRecord(
                        id: legacyPhoto.id,
                        imagePath: legacyPhoto.imagePath,
                        annotatedImagePath: legacyPhoto.annotatedImagePath,
                        freeText: legacyPhoto.freeText,
                        position: index,
                        createdAt: legacyPhoto.createdAt
                    )
                    photoRecord.project = project
                    context.insert(photoRecord)
                }
            }

            try context.save()
        }
    )
}

private let migrationPayloadV1ToV2URL = FileManager.default.temporaryDirectory
    .appendingPathComponent("inspectorpro-v1-v2-migration.json")

private let migrationPayloadV2ToV3URL = FileManager.default.temporaryDirectory
    .appendingPathComponent("inspectorpro-v2-v3-migration.json")

private struct MigrationProjectPayload: Codable {
    let name: String
    let address: String?
    let date: Date
    let notes: String?
    let photos: [MigrationPhotoPayload]

    init(legacyProject: InspectorProSchemaV1.Project) {
        name = legacyProject.title
        address = legacyProject.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : legacyProject.address
        date = legacyProject.date
        notes = legacyProject.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : legacyProject.notes

        let orderedFindings = legacyProject.findings.sorted { $0.order < $1.order }
        photos = orderedFindings.flatMap { finding in
            finding.photos
                .sorted { $0.order < $1.order }
                .map(MigrationPhotoPayload.init)
        }
    }
}

private struct MigrationPhotoPayload: Codable {
    let imagePath: String
    let annotatedImagePath: String?
    let freeText: String
    let createdAt: Date

    init(legacyPhoto: InspectorProSchemaV1.Photo) {
        imagePath = legacyPhoto.imagePath
        annotatedImagePath = legacyPhoto.annotatedPath
        freeText = legacyPhoto.caption
        createdAt = legacyPhoto.createdAt
    }
}

private struct MigrationProjectV2Payload: Codable {
    let id: UUID
    let name: String
    let address: String?
    let date: Date
    let notes: String?
    let photos: [MigrationPhotoV2Payload]

    init(legacyProject: InspectorProSchemaV2.Project) {
        id = legacyProject.id
        name = legacyProject.name
        address = legacyProject.address
        date = legacyProject.date
        notes = legacyProject.notes
        photos = legacyProject.photos
            .sorted {
                if $0.createdAt != $1.createdAt {
                    return $0.createdAt < $1.createdAt
                }
                return $0.id.uuidString < $1.id.uuidString
            }
            .map(MigrationPhotoV2Payload.init)
    }
}

private struct MigrationPhotoV2Payload: Codable {
    let id: UUID
    let imagePath: String
    let annotatedImagePath: String?
    let freeText: String
    let createdAt: Date

    init(legacyPhoto: InspectorProSchemaV2.PhotoRecord) {
        id = legacyPhoto.id
        imagePath = legacyPhoto.imagePath
        annotatedImagePath = legacyPhoto.annotatedImagePath
        freeText = legacyPhoto.freeText
        createdAt = legacyPhoto.createdAt
    }
}

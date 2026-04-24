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
        var position: Int
        var createdAt: Date

        var project: Project?

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
}

enum InspectorProSchemaV4: VersionedSchema {
    static var versionIdentifier = Schema.Version(4, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Project.self, PhotoRecord.self]
    }

    @Model
    final class Project {
        @Attribute(.unique) var id: UUID
        var name: String
        var address: String?
        var date: Date
        var attendees: String?
        var notes: String?

        @Relationship(deleteRule: .cascade, inverse: \PhotoRecord.project)
        var photos: [PhotoRecord] = []

        init(
            id: UUID = UUID(),
            name: String = "",
            address: String? = nil,
            date: Date = .now,
            attendees: String? = nil,
            notes: String? = nil
        ) {
            self.id = id
            self.name = name
            self.address = address
            self.date = date
            self.attendees = attendees
            self.notes = notes
        }
    }

    @Model
    final class PhotoRecord {
        @Attribute(.unique) var id: UUID
        var imagePath: String
        var annotatedImagePath: String?
        var freeText: String
        var position: Int
        var createdAt: Date

        var project: Project?

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
}

enum InspectorProSchemaV5: VersionedSchema {
    static var versionIdentifier = Schema.Version(5, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Project.self, PhotoRecord.self]
    }

    @Model
    final class Project {
        @Attribute(.unique) var id: UUID
        var name: String
        var address: String?
        var date: Date
        var attendees: String?
        var notes: String?
        var showsNumberedImagesInReport: Bool

        @Relationship(deleteRule: .cascade, inverse: \PhotoRecord.project)
        var photos: [PhotoRecord] = []

        init(
            id: UUID = UUID(),
            name: String = "",
            address: String? = nil,
            date: Date = .now,
            attendees: String? = nil,
            notes: String? = nil,
            showsNumberedImagesInReport: Bool = false
        ) {
            self.id = id
            self.name = name
            self.address = address
            self.date = date
            self.attendees = attendees
            self.notes = notes
            self.showsNumberedImagesInReport = showsNumberedImagesInReport
        }
    }

    @Model
    final class PhotoRecord {
        @Attribute(.unique) var id: UUID
        var imagePath: String
        var annotatedImagePath: String?
        var freeText: String
        var position: Int
        var createdAt: Date

        var project: Project?

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
}

enum InspectorProSchemaV6: VersionedSchema {
    static var versionIdentifier = Schema.Version(6, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Project.self, PhotoRecord.self, BrandingProfile.self]
    }

    @Model
    final class BrandingProfile {
        @Attribute(.unique) var id: UUID
        var name: String
        var isDefault: Bool
        var usesBundledDefaultLogo: Bool
        var footerAddressLine: String
        var primaryFooterLinePDF: String
        var primaryFooterLineDOCX: String
        var secondaryFooterLine: String

        @Relationship(deleteRule: .nullify, inverse: \Project.brandingProfile)
        var projects: [Project] = []

        init(
            id: UUID = UUID(),
            name: String,
            isDefault: Bool = false,
            usesBundledDefaultLogo: Bool = true,
            footerAddressLine: String,
            primaryFooterLinePDF: String,
            primaryFooterLineDOCX: String,
            secondaryFooterLine: String
        ) {
            self.id = id
            self.name = name
            self.isDefault = isDefault
            self.usesBundledDefaultLogo = usesBundledDefaultLogo
            self.footerAddressLine = footerAddressLine
            self.primaryFooterLinePDF = primaryFooterLinePDF
            self.primaryFooterLineDOCX = primaryFooterLineDOCX
            self.secondaryFooterLine = secondaryFooterLine
        }
    }

    @Model
    final class Project {
        @Attribute(.unique) var id: UUID
        var name: String
        var address: String?
        var date: Date
        var attendees: String?
        var notes: String?
        var showsNumberedImagesInReport: Bool

        @Relationship(deleteRule: .cascade, inverse: \PhotoRecord.project)
        var photos: [PhotoRecord] = []

        var brandingProfile: BrandingProfile?

        init(
            id: UUID = UUID(),
            name: String = "",
            address: String? = nil,
            date: Date = .now,
            attendees: String? = nil,
            notes: String? = nil,
            showsNumberedImagesInReport: Bool = false,
            brandingProfile: BrandingProfile? = nil
        ) {
            self.id = id
            self.name = name
            self.address = address
            self.date = date
            self.attendees = attendees
            self.notes = notes
            self.showsNumberedImagesInReport = showsNumberedImagesInReport
            self.brandingProfile = brandingProfile
        }
    }

    @Model
    final class PhotoRecord {
        @Attribute(.unique) var id: UUID
        var imagePath: String
        var annotatedImagePath: String?
        var freeText: String
        var position: Int
        var createdAt: Date

        var project: Project?

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
}

enum InspectorProSchemaV7: VersionedSchema {
    static var versionIdentifier = Schema.Version(7, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Project.self, PhotoRecord.self, BrandingProfile.self]
    }

    @Model
    final class BrandingProfile {
        @Attribute(.unique) var id: UUID
        var name: String
        var isDefault: Bool
        var usesBundledDefaultLogo: Bool
        var showLogoInReport: Bool
        var showFooterInReport: Bool
        var footerAddressLine: String
        var primaryFooterLinePDF: String
        var primaryFooterLineDOCX: String
        var secondaryFooterLine: String

        @Relationship(deleteRule: .nullify, inverse: \Project.brandingProfile)
        var projects: [Project] = []

        init(
            id: UUID = UUID(),
            name: String,
            isDefault: Bool = false,
            usesBundledDefaultLogo: Bool = true,
            showLogoInReport: Bool = true,
            showFooterInReport: Bool = true,
            footerAddressLine: String,
            primaryFooterLinePDF: String,
            primaryFooterLineDOCX: String,
            secondaryFooterLine: String
        ) {
            self.id = id
            self.name = name
            self.isDefault = isDefault
            self.usesBundledDefaultLogo = usesBundledDefaultLogo
            self.showLogoInReport = showLogoInReport
            self.showFooterInReport = showFooterInReport
            self.footerAddressLine = footerAddressLine
            self.primaryFooterLinePDF = primaryFooterLinePDF
            self.primaryFooterLineDOCX = primaryFooterLineDOCX
            self.secondaryFooterLine = secondaryFooterLine
        }
    }

    @Model
    final class Project {
        @Attribute(.unique) var id: UUID
        var name: String
        var address: String?
        var date: Date
        var attendees: String?
        var notes: String?
        var showsNumberedImagesInReport: Bool

        @Relationship(deleteRule: .cascade, inverse: \PhotoRecord.project)
        var photos: [PhotoRecord] = []

        var brandingProfile: BrandingProfile?

        init(
            id: UUID = UUID(),
            name: String = "",
            address: String? = nil,
            date: Date = .now,
            attendees: String? = nil,
            notes: String? = nil,
            showsNumberedImagesInReport: Bool = false,
            brandingProfile: BrandingProfile? = nil
        ) {
            self.id = id
            self.name = name
            self.address = address
            self.date = date
            self.attendees = attendees
            self.notes = notes
            self.showsNumberedImagesInReport = showsNumberedImagesInReport
            self.brandingProfile = brandingProfile
        }
    }

    @Model
    final class PhotoRecord {
        @Attribute(.unique) var id: UUID
        var imagePath: String
        var annotatedImagePath: String?
        var freeText: String
        var position: Int
        var createdAt: Date

        var project: Project?

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
}

enum InspectorProSchemaV8: VersionedSchema {
    static var versionIdentifier = Schema.Version(8, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Project.self, Report.self, PhotoRecord.self, BrandingProfile.self]
    }

    @Model
    final class BrandingProfile {
        @Attribute(.unique) var id: UUID
        var name: String
        var isDefault: Bool
        var usesBundledDefaultLogo: Bool
        var showLogoInReport: Bool
        var showFooterInReport: Bool
        var footerAddressLine: String
        var primaryFooterLinePDF: String
        var primaryFooterLineDOCX: String
        var secondaryFooterLine: String

        @Relationship(deleteRule: .nullify, inverse: \Report.brandingProfile)
        var reports: [Report] = []

        init(
            id: UUID = UUID(),
            name: String,
            isDefault: Bool = false,
            usesBundledDefaultLogo: Bool = true,
            showLogoInReport: Bool = true,
            showFooterInReport: Bool = true,
            footerAddressLine: String,
            primaryFooterLinePDF: String,
            primaryFooterLineDOCX: String,
            secondaryFooterLine: String
        ) {
            self.id = id
            self.name = name
            self.isDefault = isDefault
            self.usesBundledDefaultLogo = usesBundledDefaultLogo
            self.showLogoInReport = showLogoInReport
            self.showFooterInReport = showFooterInReport
            self.footerAddressLine = footerAddressLine
            self.primaryFooterLinePDF = primaryFooterLinePDF
            self.primaryFooterLineDOCX = primaryFooterLineDOCX
            self.secondaryFooterLine = secondaryFooterLine
        }
    }

    @Model
    final class Project {
        @Attribute(.unique) var id: UUID
        var name: String
        var address: String?

        @Relationship(deleteRule: .cascade, inverse: \Report.project)
        var reports: [Report] = []

        init(
            id: UUID = UUID(),
            name: String = "",
            address: String? = nil
        ) {
            self.id = id
            self.name = name
            self.address = address
        }
    }

    @Model
    final class Report {
        @Attribute(.unique) var id: UUID
        var name: String
        var date: Date
        var attendees: String?
        var notes: String?
        var showsNumberedImagesInReport: Bool

        @Relationship(deleteRule: .cascade, inverse: \PhotoRecord.report)
        var photos: [PhotoRecord] = []

        var project: Project?
        var brandingProfile: BrandingProfile?

        init(
            id: UUID = UUID(),
            name: String = "",
            date: Date = .now,
            attendees: String? = nil,
            notes: String? = nil,
            showsNumberedImagesInReport: Bool = false,
            project: Project? = nil,
            brandingProfile: BrandingProfile? = nil
        ) {
            self.id = id
            self.name = name
            self.date = date
            self.attendees = attendees
            self.notes = notes
            self.showsNumberedImagesInReport = showsNumberedImagesInReport
            self.project = project
            self.brandingProfile = brandingProfile
        }
    }

    @Model
    final class PhotoRecord {
        @Attribute(.unique) var id: UUID
        var imagePath: String
        var annotatedImagePath: String?
        var freeText: String
        var position: Int
        var createdAt: Date

        var report: Report?

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
}

enum InspectorProSchemaV9: VersionedSchema {
    static var versionIdentifier = Schema.Version(9, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Project.self, Report.self, PhotoRecord.self, BrandingProfile.self]
    }

    @Model
    final class BrandingProfile {
        @Attribute(.unique) var id: UUID
        var name: String
        var isDefault: Bool
        var usesBundledDefaultLogo: Bool
        var showLogoInReport: Bool
        var showFooterInReport: Bool
        var footerAddressLine: String
        var primaryFooterLinePDF: String
        var primaryFooterLineDOCX: String
        var secondaryFooterLine: String

        @Relationship(deleteRule: .nullify, inverse: \Report.brandingProfile)
        var reports: [Report] = []

        init(
            id: UUID = UUID(),
            name: String,
            isDefault: Bool = false,
            usesBundledDefaultLogo: Bool = true,
            showLogoInReport: Bool = true,
            showFooterInReport: Bool = true,
            footerAddressLine: String,
            primaryFooterLinePDF: String,
            primaryFooterLineDOCX: String,
            secondaryFooterLine: String
        ) {
            self.id = id
            self.name = name
            self.isDefault = isDefault
            self.usesBundledDefaultLogo = usesBundledDefaultLogo
            self.showLogoInReport = showLogoInReport
            self.showFooterInReport = showFooterInReport
            self.footerAddressLine = footerAddressLine
            self.primaryFooterLinePDF = primaryFooterLinePDF
            self.primaryFooterLineDOCX = primaryFooterLineDOCX
            self.secondaryFooterLine = secondaryFooterLine
        }
    }

    @Model
    final class Project {
        @Attribute(.unique) var id: UUID
        var name: String
        var address: String?

        @Relationship(deleteRule: .cascade, inverse: \Report.project)
        var reports: [Report] = []

        init(
            id: UUID = UUID(),
            name: String = "",
            address: String? = nil
        ) {
            self.id = id
            self.name = name
            self.address = address
        }
    }

    @Model
    final class Report {
        @Attribute(.unique) var id: UUID
        var name: String
        var address: String?
        var date: Date
        var attendees: String?
        var notes: String?
        var showsNumberedImagesInReport: Bool

        @Relationship(deleteRule: .cascade, inverse: \PhotoRecord.report)
        var photos: [PhotoRecord] = []

        var project: Project?
        var brandingProfile: BrandingProfile?

        init(
            id: UUID = UUID(),
            name: String = "",
            address: String? = nil,
            date: Date = .now,
            attendees: String? = nil,
            notes: String? = nil,
            showsNumberedImagesInReport: Bool = false,
            project: Project? = nil,
            brandingProfile: BrandingProfile? = nil
        ) {
            self.id = id
            self.name = name
            self.address = address
            self.date = date
            self.attendees = attendees
            self.notes = notes
            self.showsNumberedImagesInReport = showsNumberedImagesInReport
            self.project = project
            self.brandingProfile = brandingProfile
        }
    }

    @Model
    final class PhotoRecord {
        @Attribute(.unique) var id: UUID
        var imagePath: String
        var annotatedImagePath: String?
        var freeText: String
        var position: Int
        var createdAt: Date

        var report: Report?

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
}

enum InspectorProMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [InspectorProSchemaV1.self, InspectorProSchemaV2.self, InspectorProSchemaV3.self, InspectorProSchemaV4.self, InspectorProSchemaV5.self, InspectorProSchemaV6.self, InspectorProSchemaV7.self, InspectorProSchemaV8.self, InspectorProSchemaV9.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1ToV2, migrateV2ToV3, migrateV3ToV4, migrateV4ToV5, migrateV5ToV6, migrateV6ToV7, migrateV7ToV8, migrateV8ToV9]
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
                let project = InspectorProSchemaV3.Project(
                    id: legacyProject.id,
                    name: legacyProject.name,
                    address: legacyProject.address,
                    date: legacyProject.date,
                    notes: legacyProject.notes
                )
                context.insert(project)

                for (index, legacyPhoto) in legacyProject.photos.enumerated() {
                    let photoRecord = InspectorProSchemaV3.PhotoRecord(
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

    static let migrateV3ToV4 = MigrationStage.custom(
        fromVersion: InspectorProSchemaV3.self,
        toVersion: InspectorProSchemaV4.self,
        willMigrate: { context in
            let fetchDescriptor = FetchDescriptor<InspectorProSchemaV3.Project>()
            let legacyProjects = try context.fetch(fetchDescriptor)
            let payload = legacyProjects.map(MigrationProjectV3Payload.init)

            let data = try JSONEncoder().encode(payload)
            try data.write(to: migrationPayloadV3ToV4URL, options: .atomic)

            for project in legacyProjects {
                context.delete(project)
            }
            try context.save()
        },
        didMigrate: { context in
            guard FileManager.default.fileExists(atPath: migrationPayloadV3ToV4URL.path) else { return }

            defer { try? FileManager.default.removeItem(at: migrationPayloadV3ToV4URL) }

            let data = try Data(contentsOf: migrationPayloadV3ToV4URL)
            let legacyProjects = try JSONDecoder().decode([MigrationProjectV3Payload].self, from: data)

            for legacyProject in legacyProjects {
                let project = InspectorProSchemaV4.Project(
                    id: legacyProject.id,
                    name: legacyProject.name,
                    address: legacyProject.address,
                    date: legacyProject.date,
                    attendees: nil,
                    notes: legacyProject.notes
                )
                context.insert(project)

                for legacyPhoto in legacyProject.photos {
                    let photoRecord = InspectorProSchemaV4.PhotoRecord(
                        id: legacyPhoto.id,
                        imagePath: legacyPhoto.imagePath,
                        annotatedImagePath: legacyPhoto.annotatedImagePath,
                        freeText: legacyPhoto.freeText,
                        position: legacyPhoto.position,
                        createdAt: legacyPhoto.createdAt
                    )
                    photoRecord.project = project
                    context.insert(photoRecord)
                }
            }

            try context.save()
        }
    )

    static let migrateV4ToV5 = MigrationStage.custom(
        fromVersion: InspectorProSchemaV4.self,
        toVersion: InspectorProSchemaV5.self,
        willMigrate: { context in
            let fetchDescriptor = FetchDescriptor<InspectorProSchemaV4.Project>()
            let legacyProjects = try context.fetch(fetchDescriptor)
            let payload = legacyProjects.map(MigrationProjectV4Payload.init)

            let data = try JSONEncoder().encode(payload)
            try data.write(to: migrationPayloadV4ToV5URL, options: .atomic)

            for project in legacyProjects {
                context.delete(project)
            }
            try context.save()
        },
        didMigrate: { context in
            guard FileManager.default.fileExists(atPath: migrationPayloadV4ToV5URL.path) else { return }

            defer { try? FileManager.default.removeItem(at: migrationPayloadV4ToV5URL) }

            let data = try Data(contentsOf: migrationPayloadV4ToV5URL)
            let legacyProjects = try JSONDecoder().decode([MigrationProjectV4Payload].self, from: data)

            for legacyProject in legacyProjects {
                let project = InspectorProSchemaV5.Project(
                    id: legacyProject.id,
                    name: legacyProject.name,
                    address: legacyProject.address,
                    date: legacyProject.date,
                    attendees: legacyProject.attendees,
                    notes: legacyProject.notes,
                    showsNumberedImagesInReport: false
                )
                context.insert(project)

                for legacyPhoto in legacyProject.photos {
                    let photoRecord = InspectorProSchemaV5.PhotoRecord(
                        id: legacyPhoto.id,
                        imagePath: legacyPhoto.imagePath,
                        annotatedImagePath: legacyPhoto.annotatedImagePath,
                        freeText: legacyPhoto.freeText,
                        position: legacyPhoto.position,
                        createdAt: legacyPhoto.createdAt
                    )
                    photoRecord.project = project
                    context.insert(photoRecord)
                }
            }

            try context.save()
        }
    )

    static let migrateV5ToV6 = MigrationStage.lightweight(
        fromVersion: InspectorProSchemaV5.self,
        toVersion: InspectorProSchemaV6.self
    )

    static let migrateV6ToV7 = MigrationStage.custom(
        fromVersion: InspectorProSchemaV6.self,
        toVersion: InspectorProSchemaV7.self,
        willMigrate: migrateV6ToV7WillMigrate,
        didMigrate: migrateV6ToV7DidMigrate
    )

    static let migrateV7ToV8 = MigrationStage.custom(
        fromVersion: InspectorProSchemaV7.self,
        toVersion: InspectorProSchemaV8.self,
        willMigrate: migrateV7ToV8WillMigrate,
        didMigrate: migrateV7ToV8DidMigrate
    )

    static let migrateV8ToV9 = MigrationStage.lightweight(
        fromVersion: InspectorProSchemaV8.self,
        toVersion: InspectorProSchemaV9.self
    )

    private static func migrateV6ToV7WillMigrate(context: ModelContext) throws {
        let brandingProfiles = try context.fetch(FetchDescriptor<InspectorProSchemaV6.BrandingProfile>())
        let projects = try context.fetch(FetchDescriptor<InspectorProSchemaV6.Project>())
        let brandingPayloads: [MigrationBrandingProfileV6Payload] = brandingProfiles.map { brandingProfile in
            MigrationBrandingProfileV6Payload(legacyBrandingProfile: brandingProfile)
        }
        let projectPayloads: [MigrationProjectV6Payload] = projects.map { project in
            MigrationProjectV6Payload(legacyProject: project)
        }
        let payload = MigrationPayloadV6ToV7(
            brandingProfiles: brandingPayloads,
            projects: projectPayloads
        )

        let data = try JSONEncoder().encode(payload)
        try data.write(to: migrationPayloadV6ToV7URL, options: .atomic)

        for project in projects {
            context.delete(project)
        }
        for brandingProfile in brandingProfiles {
            context.delete(brandingProfile)
        }
        try context.save()
    }

    private static func migrateV6ToV7DidMigrate(context: ModelContext) throws {
        guard FileManager.default.fileExists(atPath: migrationPayloadV6ToV7URL.path) else { return }

        defer { try? FileManager.default.removeItem(at: migrationPayloadV6ToV7URL) }

        let data = try Data(contentsOf: migrationPayloadV6ToV7URL)
        let payload = try JSONDecoder().decode(MigrationPayloadV6ToV7.self, from: data)

        var brandingProfilesByID: [UUID: InspectorProSchemaV7.BrandingProfile] = [:]

        for legacyBrandingProfile in payload.brandingProfiles {
            let brandingProfile = InspectorProSchemaV7.BrandingProfile(
                id: legacyBrandingProfile.id,
                name: legacyBrandingProfile.name,
                isDefault: legacyBrandingProfile.isDefault,
                usesBundledDefaultLogo: legacyBrandingProfile.usesBundledDefaultLogo,
                showLogoInReport: true,
                showFooterInReport: true,
                footerAddressLine: legacyBrandingProfile.footerAddressLine,
                primaryFooterLinePDF: legacyBrandingProfile.primaryFooterLinePDF,
                primaryFooterLineDOCX: legacyBrandingProfile.primaryFooterLineDOCX,
                secondaryFooterLine: legacyBrandingProfile.secondaryFooterLine
            )
            context.insert(brandingProfile)
            brandingProfilesByID[brandingProfile.id] = brandingProfile
        }

        for legacyProject in payload.projects {
            let linkedBrandingProfile: InspectorProSchemaV7.BrandingProfile?
            if let brandingProfileID = legacyProject.brandingProfileID {
                linkedBrandingProfile = brandingProfilesByID[brandingProfileID]
            } else {
                linkedBrandingProfile = nil
            }

            let project = InspectorProSchemaV7.Project(
                id: legacyProject.id,
                name: legacyProject.name,
                address: legacyProject.address,
                date: legacyProject.date,
                attendees: legacyProject.attendees,
                notes: legacyProject.notes,
                showsNumberedImagesInReport: legacyProject.showsNumberedImagesInReport,
                brandingProfile: linkedBrandingProfile
            )
            context.insert(project)

            for legacyPhoto in legacyProject.photos {
                let photoRecord = InspectorProSchemaV7.PhotoRecord(
                    id: legacyPhoto.id,
                    imagePath: legacyPhoto.imagePath,
                    annotatedImagePath: legacyPhoto.annotatedImagePath,
                    freeText: legacyPhoto.freeText,
                    position: legacyPhoto.position,
                    createdAt: legacyPhoto.createdAt
                )
                photoRecord.project = project
                context.insert(photoRecord)
            }
        }

        try context.save()
    }

    private static func migrateV7ToV8WillMigrate(context: ModelContext) throws {
        let brandingProfiles = try context.fetch(FetchDescriptor<InspectorProSchemaV7.BrandingProfile>())
        let projects = try context.fetch(FetchDescriptor<InspectorProSchemaV7.Project>())
        let payload = MigrationPayloadV7ToV8(
            brandingProfiles: brandingProfiles.map(MigrationBrandingProfileV7Payload.init),
            projects: projects.map(MigrationProjectV7Payload.init)
        )

        let data = try JSONEncoder().encode(payload)
        try data.write(to: migrationPayloadV7ToV8URL, options: .atomic)

        for project in projects {
            context.delete(project)
        }
        for brandingProfile in brandingProfiles {
            context.delete(brandingProfile)
        }
        try context.save()
    }

    private static func migrateV7ToV8DidMigrate(context: ModelContext) throws {
        guard FileManager.default.fileExists(atPath: migrationPayloadV7ToV8URL.path) else { return }

        defer { try? FileManager.default.removeItem(at: migrationPayloadV7ToV8URL) }

        let data = try Data(contentsOf: migrationPayloadV7ToV8URL)
        let payload = try JSONDecoder().decode(MigrationPayloadV7ToV8.self, from: data)

        var brandingProfilesByID: [UUID: InspectorProSchemaV8.BrandingProfile] = [:]

        for legacyBrandingProfile in payload.brandingProfiles {
            let brandingProfile = InspectorProSchemaV8.BrandingProfile(
                id: legacyBrandingProfile.id,
                name: legacyBrandingProfile.name,
                isDefault: legacyBrandingProfile.isDefault,
                usesBundledDefaultLogo: legacyBrandingProfile.usesBundledDefaultLogo,
                showLogoInReport: legacyBrandingProfile.showLogoInReport,
                showFooterInReport: legacyBrandingProfile.showFooterInReport,
                footerAddressLine: legacyBrandingProfile.footerAddressLine,
                primaryFooterLinePDF: legacyBrandingProfile.primaryFooterLinePDF,
                primaryFooterLineDOCX: legacyBrandingProfile.primaryFooterLineDOCX,
                secondaryFooterLine: legacyBrandingProfile.secondaryFooterLine
            )
            context.insert(brandingProfile)
            brandingProfilesByID[brandingProfile.id] = brandingProfile
        }

        for legacyProject in payload.projects {
            let project = InspectorProSchemaV8.Project(
                id: legacyProject.id,
                name: legacyProject.name,
                address: legacyProject.address
            )
            context.insert(project)

            let linkedBrandingProfile = legacyProject.brandingProfileID.flatMap { brandingProfilesByID[$0] }
            let report = InspectorProSchemaV8.Report(
                name: legacyProject.name,
                date: legacyProject.date,
                attendees: legacyProject.attendees,
                notes: legacyProject.notes,
                showsNumberedImagesInReport: legacyProject.showsNumberedImagesInReport,
                project: project,
                brandingProfile: linkedBrandingProfile
            )
            context.insert(report)

            for legacyPhoto in legacyProject.photos {
                let photoRecord = InspectorProSchemaV8.PhotoRecord(
                    id: legacyPhoto.id,
                    imagePath: legacyPhoto.imagePath,
                    annotatedImagePath: legacyPhoto.annotatedImagePath,
                    freeText: legacyPhoto.freeText,
                    position: legacyPhoto.position,
                    createdAt: legacyPhoto.createdAt
                )
                photoRecord.report = report
                context.insert(photoRecord)
            }
        }

        try context.save()
    }
}

private let migrationPayloadV1ToV2URL = FileManager.default.temporaryDirectory
    .appendingPathComponent("inspectorpro-v1-v2-migration.json")

private let migrationPayloadV2ToV3URL = FileManager.default.temporaryDirectory
    .appendingPathComponent("inspectorpro-v2-v3-migration.json")

private let migrationPayloadV3ToV4URL = FileManager.default.temporaryDirectory
    .appendingPathComponent("inspectorpro-v3-v4-migration.json")

private let migrationPayloadV4ToV5URL = FileManager.default.temporaryDirectory
    .appendingPathComponent("inspectorpro-v4-v5-migration.json")

private let migrationPayloadV6ToV7URL = FileManager.default.temporaryDirectory
    .appendingPathComponent("inspectorpro-v6-v7-migration.json")

private let migrationPayloadV7ToV8URL = FileManager.default.temporaryDirectory
    .appendingPathComponent("inspectorpro-v7-v8-migration.json")

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

private struct MigrationProjectV3Payload: Codable {
    let id: UUID
    let name: String
    let address: String?
    let date: Date
    let notes: String?
    let photos: [MigrationPhotoV3Payload]

    init(legacyProject: InspectorProSchemaV3.Project) {
        id = legacyProject.id
        name = legacyProject.name
        address = legacyProject.address
        date = legacyProject.date
        notes = legacyProject.notes
        photos = legacyProject.photos
            .sorted {
                if $0.position != $1.position {
                    return $0.position < $1.position
                }
                if $0.createdAt != $1.createdAt {
                    return $0.createdAt < $1.createdAt
                }
                return $0.id.uuidString < $1.id.uuidString
            }
            .map(MigrationPhotoV3Payload.init)
    }
}

private struct MigrationPhotoV3Payload: Codable {
    let id: UUID
    let imagePath: String
    let annotatedImagePath: String?
    let freeText: String
    let position: Int
    let createdAt: Date

    init(
        id: UUID,
        imagePath: String,
        annotatedImagePath: String?,
        freeText: String,
        position: Int,
        createdAt: Date
    ) {
        self.id = id
        self.imagePath = imagePath
        self.annotatedImagePath = annotatedImagePath
        self.freeText = freeText
        self.position = position
        self.createdAt = createdAt
    }

    init(legacyPhoto: InspectorProSchemaV3.PhotoRecord) {
        id = legacyPhoto.id
        imagePath = legacyPhoto.imagePath
        annotatedImagePath = legacyPhoto.annotatedImagePath
        freeText = legacyPhoto.freeText
        position = legacyPhoto.position
        createdAt = legacyPhoto.createdAt
    }

    init(legacyPhoto: InspectorProSchemaV4.PhotoRecord) {
        id = legacyPhoto.id
        imagePath = legacyPhoto.imagePath
        annotatedImagePath = legacyPhoto.annotatedImagePath
        freeText = legacyPhoto.freeText
        position = legacyPhoto.position
        createdAt = legacyPhoto.createdAt
    }
}

private struct MigrationProjectV4Payload: Codable {
    let id: UUID
    let name: String
    let address: String?
    let date: Date
    let attendees: String?
    let notes: String?
    let photos: [MigrationPhotoV3Payload]

    init(legacyProject: InspectorProSchemaV4.Project) {
        id = legacyProject.id
        name = legacyProject.name
        address = legacyProject.address
        date = legacyProject.date
        attendees = legacyProject.attendees
        notes = legacyProject.notes
        photos = legacyProject.photos
            .sorted {
                if $0.position != $1.position {
                    return $0.position < $1.position
                }
                if $0.createdAt != $1.createdAt {
                    return $0.createdAt < $1.createdAt
                }
                return $0.id.uuidString < $1.id.uuidString
            }
            .map(MigrationPhotoV3Payload.init)
    }
}

private struct MigrationPayloadV6ToV7: Codable {
    let brandingProfiles: [MigrationBrandingProfileV6Payload]
    let projects: [MigrationProjectV6Payload]
}

private struct MigrationPayloadV7ToV8: Codable {
    let brandingProfiles: [MigrationBrandingProfileV7Payload]
    let projects: [MigrationProjectV7Payload]
}

private struct MigrationBrandingProfileV6Payload: Codable {
    let id: UUID
    let name: String
    let isDefault: Bool
    let usesBundledDefaultLogo: Bool
    let footerAddressLine: String
    let primaryFooterLinePDF: String
    let primaryFooterLineDOCX: String
    let secondaryFooterLine: String

    init(legacyBrandingProfile: InspectorProSchemaV6.BrandingProfile) {
        id = legacyBrandingProfile.id
        name = legacyBrandingProfile.name
        isDefault = legacyBrandingProfile.isDefault
        usesBundledDefaultLogo = legacyBrandingProfile.usesBundledDefaultLogo
        footerAddressLine = legacyBrandingProfile.footerAddressLine
        primaryFooterLinePDF = legacyBrandingProfile.primaryFooterLinePDF
        primaryFooterLineDOCX = legacyBrandingProfile.primaryFooterLineDOCX
        secondaryFooterLine = legacyBrandingProfile.secondaryFooterLine
    }
}

private struct MigrationBrandingProfileV7Payload: Codable {
    let id: UUID
    let name: String
    let isDefault: Bool
    let usesBundledDefaultLogo: Bool
    let showLogoInReport: Bool
    let showFooterInReport: Bool
    let footerAddressLine: String
    let primaryFooterLinePDF: String
    let primaryFooterLineDOCX: String
    let secondaryFooterLine: String

    init(legacyBrandingProfile: InspectorProSchemaV7.BrandingProfile) {
        id = legacyBrandingProfile.id
        name = legacyBrandingProfile.name
        isDefault = legacyBrandingProfile.isDefault
        usesBundledDefaultLogo = legacyBrandingProfile.usesBundledDefaultLogo
        showLogoInReport = legacyBrandingProfile.showLogoInReport
        showFooterInReport = legacyBrandingProfile.showFooterInReport
        footerAddressLine = legacyBrandingProfile.footerAddressLine
        primaryFooterLinePDF = legacyBrandingProfile.primaryFooterLinePDF
        primaryFooterLineDOCX = legacyBrandingProfile.primaryFooterLineDOCX
        secondaryFooterLine = legacyBrandingProfile.secondaryFooterLine
    }
}

private struct MigrationProjectV6Payload: Codable {
    let id: UUID
    let name: String
    let address: String?
    let date: Date
    let attendees: String?
    let notes: String?
    let showsNumberedImagesInReport: Bool
    let brandingProfileID: UUID?
    let photos: [MigrationPhotoV3Payload]

    init(legacyProject: InspectorProSchemaV6.Project) {
        id = legacyProject.id
        name = legacyProject.name
        address = legacyProject.address
        date = legacyProject.date
        attendees = legacyProject.attendees
        notes = legacyProject.notes
        showsNumberedImagesInReport = legacyProject.showsNumberedImagesInReport
        brandingProfileID = legacyProject.brandingProfile?.id
        let sortedPhotos = legacyProject.photos.sorted { lhs, rhs in
            if lhs.position != rhs.position {
                return lhs.position < rhs.position
            }
            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt < rhs.createdAt
            }
            return lhs.id.uuidString < rhs.id.uuidString
        }
        photos = sortedPhotos.map { photo in
            MigrationPhotoV3Payload(
                id: photo.id,
                imagePath: photo.imagePath,
                annotatedImagePath: photo.annotatedImagePath,
                freeText: photo.freeText,
                position: photo.position,
                createdAt: photo.createdAt
            )
        }
    }
}

private struct MigrationProjectV7Payload: Codable {
    let id: UUID
    let name: String
    let address: String?
    let date: Date
    let attendees: String?
    let notes: String?
    let showsNumberedImagesInReport: Bool
    let brandingProfileID: UUID?
    let photos: [MigrationPhotoV3Payload]

    init(legacyProject: InspectorProSchemaV7.Project) {
        id = legacyProject.id
        name = legacyProject.name
        address = legacyProject.address
        date = legacyProject.date
        attendees = legacyProject.attendees
        notes = legacyProject.notes
        showsNumberedImagesInReport = legacyProject.showsNumberedImagesInReport
        brandingProfileID = legacyProject.brandingProfile?.id
        let sortedPhotos = legacyProject.photos.sorted { lhs, rhs in
            if lhs.position != rhs.position {
                return lhs.position < rhs.position
            }
            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt < rhs.createdAt
            }
            return lhs.id.uuidString < rhs.id.uuidString
        }
        photos = sortedPhotos.map { photo in
            MigrationPhotoV3Payload(
                id: photo.id,
                imagePath: photo.imagePath,
                annotatedImagePath: photo.annotatedImagePath,
                freeText: photo.freeText,
                position: photo.position,
                createdAt: photo.createdAt
            )
        }
    }
}

import Foundation
import SwiftData

enum BrandingBootstrapper {
    static func scheduleBootstrap(modelContainer: ModelContainer) {
        Task { @MainActor in
            do {
                try bootstrap(modelContainer: modelContainer)
            } catch {
                print("Branding bootstrap failed: \(error)")
            }
        }
    }

    @MainActor
    static func fetchDefaultBrandingProfile(in modelContext: ModelContext) throws -> BrandingProfile? {
        let fetchDescriptor = FetchDescriptor<BrandingProfile>()
        let profiles = try modelContext.fetch(fetchDescriptor)
        return profiles.first(where: \.isDefault)
            ?? profiles.first(where: { $0.name == DefaultBrandingProfile.name })
    }

    @MainActor
    static func fetchOrCreateDefaultBrandingProfile(in modelContext: ModelContext) throws -> BrandingProfile {
        if let existing = try fetchDefaultBrandingProfile(in: modelContext) {
            return existing
        }

        let defaultBrandingProfile = DefaultBrandingProfile.makeBrandingProfile()
        modelContext.insert(defaultBrandingProfile)
        try modelContext.save()
        return defaultBrandingProfile
    }

    @MainActor
    private static func bootstrap(modelContainer: ModelContainer) throws {
        let modelContext = ModelContext(modelContainer)
        let defaultBrandingProfile = try fetchOrCreateDefaultBrandingProfile(in: modelContext)
        let projects = try modelContext.fetch(FetchDescriptor<Project>())

        var didChange = false
        for project in projects where project.brandingProfile == nil {
            project.brandingProfile = defaultBrandingProfile
            didChange = true
        }

        if didChange {
            try modelContext.save()
        }
    }
}

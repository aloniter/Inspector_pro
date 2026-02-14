import SwiftUI
import SwiftData

@main
struct InspectorProApp: App {
    @AppStorage(AppPreferenceKeys.darkModeEnabled) private var darkModeEnabled = false
    @AppStorage(AppPreferenceKeys.languageCode) private var languageCode = AppLanguage.hebrew.rawValue

    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([Project.self, PhotoRecord.self])
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: InspectorProMigrationPlan.self,
                configurations: [config]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        FileManagerService.shared.ensureDirectoriesExist()
    }

    var body: some Scene {
        let appLanguage = AppLanguage(rawValue: languageCode) ?? .hebrew

        WindowGroup {
            ProjectListView()
                .environment(\.layoutDirection, appLanguage.layoutDirection)
                .environment(\.locale, appLanguage.locale)
                .preferredColorScheme(darkModeEnabled ? .dark : .light)
        }
        .modelContainer(modelContainer)
    }
}

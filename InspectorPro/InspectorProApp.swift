import SwiftUI
import SwiftData

@main
struct InspectorProApp: App {
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
        WindowGroup {
            ProjectListView()
            .environment(\.layoutDirection, .rightToLeft)
            .environment(\.locale, Locale(identifier: "he"))
        }
        .modelContainer(modelContainer)
    }
}

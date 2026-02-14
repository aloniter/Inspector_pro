import SwiftUI
import SwiftData

@main
struct InspectorProApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([Project.self, Finding.self, Photo.self])
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        FileManagerService.shared.ensureDirectoriesExist()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ProjectListView()
            }
            .environment(\.layoutDirection, .rightToLeft)
            .environment(\.locale, Locale(identifier: "he"))
        }
        .modelContainer(modelContainer)
    }
}

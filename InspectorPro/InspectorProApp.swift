import SwiftUI
import SwiftData

@main
struct InspectorProApp: App {
    @AppStorage(AppPreferenceKeys.darkModeEnabled) private var darkModeEnabled = false
    @AppStorage(AppPreferenceKeys.languageCode) private var languageCode = AppLanguage.hebrew.rawValue

    private let modelContainer: ModelContainer
    private let didFailToLaunch: Bool

    init() {
        FileManagerService.shared.ensureDirectoriesExist()

        let schema = Schema(versionedSchema: InspectorProSchemaV7.self)

        do {
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            let container = try ModelContainer(
                for: schema,
                migrationPlan: InspectorProMigrationPlan.self,
                configurations: [config]
            )
            modelContainer = container
            didFailToLaunch = false
            BrandingBootstrapper.scheduleBootstrap(modelContainer: container)
        } catch {
            let fallbackConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            modelContainer = try! ModelContainer(
                for: schema,
                migrationPlan: InspectorProMigrationPlan.self,
                configurations: [fallbackConfig]
            )
            didFailToLaunch = true
        }
    }

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: languageCode) ?? .hebrew
    }

    private func configuredRootView<Content: View>(_ content: Content) -> some View {
        content
            .environment(\.layoutDirection, appLanguage.layoutDirection)
            .environment(\.locale, appLanguage.locale)
            .preferredColorScheme(darkModeEnabled ? .dark : .light)
    }

    var body: some Scene {
        WindowGroup {
            configuredRootView(
                Group {
                    if didFailToLaunch {
                        AppLaunchFailureView()
                    } else {
                        ProjectListView()
                    }
                }
            )
        }
        .modelContainer(modelContainer)
    }
}

private struct AppLaunchFailureView: View {
    var body: some View {
        ContentUnavailableView {
            Label(AppStrings.text("לא ניתן לפתוח את האפליקציה"), systemImage: "exclamationmark.triangle")
        } description: {
            Text(AppStrings.text("נתוני האפליקציה לא נטענו"))
        }
    }
}

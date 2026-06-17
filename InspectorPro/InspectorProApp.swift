import SwiftUI
import SwiftData

@main
struct InspectorProApp: App {
    @AppStorage(AppPreferenceKeys.darkModeEnabled) private var darkModeEnabled = false
    @AppStorage(AppPreferenceKeys.languageCode) private var languageCode = AppLanguage.hebrew.rawValue
    @Environment(\.scenePhase) private var scenePhase

    private let modelContainer: ModelContainer
    private let didFailToLaunch: Bool
    private let authService = AuthService()

    init() {
        FileManagerService.shared.ensureDirectoriesExist()
        // Exports are transient: clear any leftover export files from a previous
        // session before showing the UI.
        FileManagerService.shared.purgeExports()

        let schema = Schema(versionedSchema: InspectorProSchemaV9.self)

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
            #if DEBUG
            _ = SupabaseManager.client
            #endif
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
                    } else if authService.isCheckingSession {
                        ProgressView()
                    } else if authService.isAuthenticated {
                        ProjectListView()
                    } else {
                        LoginView()
                    }
                }
            )
            .environment(authService)
            .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    Task { await CompanyBrandingService.shared.syncForced() }
                } else {
                    Task { await CompanyBrandingService.shared.clearCache() }
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active, authService.isAuthenticated {
                    Task { await CompanyBrandingService.shared.syncIfNeeded() }
                }
            }
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

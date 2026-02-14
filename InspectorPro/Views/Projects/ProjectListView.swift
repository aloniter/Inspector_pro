import SwiftUI
import SwiftData

struct ProjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.date, order: .reverse) private var projects: [Project]
    @AppStorage(AppPreferenceKeys.darkModeEnabled) private var darkModeEnabled = false
    @AppStorage(AppPreferenceKeys.languageCode) private var languageCode = AppLanguage.hebrew.rawValue

    @State private var path = NavigationPath()
    @State private var showingNewProject = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if projects.isEmpty {
                    EmptyStateView(
                        icon: "building.2",
                        title: AppStrings.text("אין פרויקטים"),
                        subtitle: AppStrings.text("לחץ + להוספת פרויקט חדש")
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(projects) { project in
                        NavigationLink(value: project) {
                            ProjectRowView(project: project)
                        }
                    }
                    .onDelete(perform: deleteProjects)
                }
            }
            .navigationTitle(AppStrings.text("פרויקטים"))
            .navigationDestination(for: Project.self) { project in
                ProjectDetailView(project: project)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingNewProject = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingNewProject) {
                NavigationStack {
                    ProjectFormView(mode: .create) { createdProject in
                        path.append(createdProject)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    AppSettingsView(
                        darkModeEnabled: $darkModeEnabled,
                        languageCode: $languageCode
                    )
                }
            }
        }
    }

    private func deleteProjects(at offsets: IndexSet) {
        for index in offsets {
            let project = projects[index]
            // Clean up images from disk
            Task {
                await ImageStorageService.shared.deleteProjectDirectory(projectID: project.id.uuidString)
            }
            modelContext.delete(project)
        }
    }
}

struct ProjectRowView: View {
    @Environment(\.layoutDirection) private var layoutDirection
    let project: Project

    private var rowHorizontalAlignment: HorizontalAlignment {
        AppTextDirection.horizontalAlignment(for: layoutDirection)
    }

    private var rowTextAlignment: TextAlignment {
        AppTextDirection.textAlignment(for: layoutDirection)
    }

    var body: some View {
        VStack(alignment: rowHorizontalAlignment, spacing: 4) {
            Text(project.name)
                .font(.headline)
                .multilineTextAlignment(rowTextAlignment)

            HStack {
                Text(AppStrings.format("%d תמונות", project.photos.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(project.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let address = project.address, !address.isEmpty {
                Text(address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(rowTextAlignment)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct AppSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var darkModeEnabled: Bool
    @Binding var languageCode: String

    private var selectedLanguage: Binding<AppLanguage> {
        Binding(
            get: { AppLanguage(rawValue: languageCode) ?? .hebrew },
            set: { languageCode = $0.rawValue }
        )
    }

    var body: some View {
        Form {
            Section(AppStrings.text("מראה")) {
                Toggle(isOn: $darkModeEnabled) {
                    Label(AppStrings.text("מצב לילה"), systemImage: "moon.stars.fill")
                }
            }

            Section(AppStrings.text("שפה")) {
                Picker(AppStrings.text("שפה"), selection: selectedLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayTitle).tag(language)
                    }
                }
                .pickerStyle(.segmented)

                Text(AppStrings.text("השינויים מוחלים מיידית בכל האפליקציה."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(AppStrings.text("אפליקציה")) {
                HStack {
                    Label(AppStrings.text("גרסה"), systemImage: "info.circle")
                    Spacer()
                    Text(versionText)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Text("created by Alon Iter")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 6)
            }
        }
        .navigationTitle(AppStrings.text("הגדרות"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(AppStrings.text("סגור")) {
                    dismiss()
                }
            }
        }
    }

    private var versionText: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "v\(shortVersion) (\(buildVersion))"
    }
}

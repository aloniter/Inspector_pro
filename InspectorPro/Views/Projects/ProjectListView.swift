import SwiftUI
import SwiftData

struct ProjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.name) private var projects: [Project]
    @AppStorage(AppPreferenceKeys.darkModeEnabled) private var darkModeEnabled = false
    @AppStorage(AppPreferenceKeys.languageCode) private var languageCode = AppLanguage.hebrew.rawValue

    @State private var path = NavigationPath()
    @State private var showingNewProject = false
    @State private var showingSettings = false
    @State private var errorMessage: String?

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
            .alert(AppStrings.text("מחיקה נכשלה"), isPresented: errorAlertPresented) {
                Button(AppStrings.text("אישור"), role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? AppStrings.text("אירעה שגיאה בשמירה"))
            }
        }
    }

    private func deleteProjects(at offsets: IndexSet) {
        let deletedProjects = offsets.map { projects[$0] }

        for project in deletedProjects {
            modelContext.delete(project)
        }

        do {
            try modelContext.save()

            Task {
                for project in deletedProjects {
                    await ImageStorageService.shared.deleteProjectDirectory(projectID: project.id.uuidString)
                }
            }
        } catch {
            for project in deletedProjects {
                modelContext.insert(project)
            }
            errorMessage = userFacingErrorMessage(for: error)
        }
    }

    private var errorAlertPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    private func userFacingErrorMessage(for error: Error) -> String {
        let description = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        return description.isEmpty ? AppStrings.text("אירעה שגיאה בשמירה") : description
    }
}

struct ProjectRowView: View {
    let project: Project

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(AppStrings.format("%d דוחות", project.reports.count))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 4) {
                Text(project.name.directionallyIsolated)
                    .font(.headline)
                    .multilineTextAlignment(.trailing)

                if let address = project.address, !address.isEmpty {
                    Text(address.directionallyIsolated)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 2)
        // Keep visual positions stable: photos count on the left, project name on the right.
        .environment(\.layoutDirection, .leftToRight)
    }
}

extension String {
    var directionallyIsolated: String {
        guard !isEmpty else { return self }
        if containsHebrewCharacters {
            return "\u{2067}\(self)\u{2069}"
        }
        return "\u{2066}\(self)\u{2069}"
    }

    private var containsHebrewCharacters: Bool {
        unicodeScalars.contains { scalar in
            (0x0590...0x05FF).contains(scalar.value)
        }
    }
}

private struct AppSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BrandingProfile.name) private var brandingProfiles: [BrandingProfile]
    @Environment(\.dismiss) private var dismiss
    @Binding var darkModeEnabled: Bool
    @Binding var languageCode: String

    private var defaultBrandingProfile: BrandingProfile? {
        brandingProfiles.first(where: \.isDefault) ?? brandingProfiles.first
    }

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

            Section(AppStrings.text("מיתוג חברה")) {
                NavigationLink {
                    BrandingSettingsContainerView()
                } label: {
                    HStack(spacing: 12) {
                        BrandingLogoThumbnail(brandingProfile: defaultBrandingProfile)

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(defaultBrandingProfile?.name ?? AppStrings.text("טוען..."))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.trailing)

                            Text(AppStrings.text("ברירת מחדל"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .environment(\.layoutDirection, .leftToRight)
                }
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
        .task {
            _ = try? BrandingBootstrapper.fetchOrCreateDefaultBrandingProfile(in: modelContext)
        }
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

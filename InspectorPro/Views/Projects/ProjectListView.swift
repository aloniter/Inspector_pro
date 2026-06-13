import SwiftUI
import SwiftData

struct ProjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthService.self) private var authService
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
            .id("projects-\(languageCode)")
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
                .environment(authService)
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
        let deletedPhotoPaths = deletedProjects.flatMap(\.photoFileReferencesForDeletion)

        for project in deletedProjects {
            modelContext.delete(project)
        }

        do {
            try modelContext.save()

            Task {
                for photoPath in deletedPhotoPaths {
                    await ImageStorageService.shared.deletePhotoFiles(
                        originalPath: photoPath.originalPath,
                        annotatedPath: photoPath.annotatedPath
                    )
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
    @Environment(AuthService.self) private var authService
    @Query(sort: \BrandingProfile.name) private var brandingProfiles: [BrandingProfile]
    @Environment(\.dismiss) private var dismiss
    @Binding var darkModeEnabled: Bool
    @Binding var languageCode: String

    // Account status state
    @State private var accountEmail: String?
    @State private var accountCompany: String?
    @State private var exportPermission: ExportPermissionResult?
    @State private var trialEndDateString: String?
    @State private var isRefreshing = false
    @State private var refreshErrorMessage: String?

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
            // Account info section — shown only when logged in
            if authService.isAuthenticated {
                Section(AppStrings.text("חשבון")) {
                    if let email = accountEmail {
                        HStack {
                            Text(AppStrings.text("משתמש"))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(email)
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.primary)
                                .environment(\.layoutDirection, .leftToRight)
                        }
                    }

                    if let company = accountCompany {
                        HStack {
                            Text(AppStrings.text("חברה"))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(company)
                                .multilineTextAlignment(.trailing)
                        }
                    }

                    HStack {
                        Text(AppStrings.text("סטטוס ייצוא"))
                            .foregroundStyle(.secondary)
                        Spacer()
                        exportStatusBadge
                    }

                    if let trialEnd = trialEndDateString {
                        HStack {
                            Text(AppStrings.text("תוקף ניסיון עד"))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(trialEnd)
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Button {
                        refresh()
                    } label: {
                        HStack {
                            if isRefreshing {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .padding(.trailing, 4)
                            }
                            Label(AppStrings.text("רענון פרטי חברה"), systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .disabled(isRefreshing)

                    if let error = refreshErrorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }

                Section {
                    Link(destination: accountDeletionMailtoURL) {
                        Label(AppStrings.text("בקשת מחיקת חשבון"), systemImage: "trash")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                } footer: {
                    Text(AppStrings.text("נשלח אימייל לתמיכה לטיפול במחיקת החשבון והנתונים."))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }

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
                            Text(accountCompany ?? defaultBrandingProfile?.name ?? AppStrings.text("טוען..."))
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

            if authService.isAuthenticated {
                Section {
                    Button(role: .destructive) {
                        Task {
                            await authService.signOut()
                            dismiss()
                        }
                    } label: {
                        Label(AppStrings.text("יציאה מהחשבון"), systemImage: "rectangle.portrait.and.arrow.right")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }

            Section {
                Text(AppStrings.text("Created By Iter Engineering"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

        }
        .navigationTitle(AppStrings.text("הגדרות"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            _ = try? BrandingBootstrapper.fetchOrCreateDefaultBrandingProfile(in: modelContext)
            await loadAccountStatus()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(AppStrings.text("סגור")) {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Export status badge

    @ViewBuilder
    private var exportStatusBadge: some View {
        switch exportPermission {
        case .allowed:
            Label(AppStrings.text("פעיל"), systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.subheadline)
        case .deniedTrialExpired, .deniedSuspended, .deniedExportDisabled:
            Label(AppStrings.text("לא פעיל"), systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
                .font(.subheadline)
        case .cannotVerifyOffline:
            Label(AppStrings.text("לא ידוע"), systemImage: "wifi.slash")
                .foregroundStyle(.orange)
                .font(.subheadline)
        case .notLoggedIn:
            Label(AppStrings.text("לא מחובר"), systemImage: "person.crop.circle.badge.exclamationmark")
                .foregroundStyle(.orange)
                .font(.subheadline)
        case .backendError:
            Label(AppStrings.text("שגיאה"), systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.subheadline)
        case nil:
            Text("—")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Data loading

    private func loadAccountStatus() async {
        let userID = authService.currentUserID
        accountEmail = authService.currentUserEmail

        // Company name from branding cache
        accountCompany = CompanyBrandingService.shared.loadCached()?.name

        // Export permission from cache (instant display), then live
        exportPermission = ExportPermissionService.shared.cachedResult(
            forUserID: userID
        )
        trialEndDateString = ExportPermissionService.shared.cachedTrialEndDateString()

        // Fetch live permission (uses network if available, cache if offline)
        let live = await ExportPermissionService.shared.checkExportAllowed()
        exportPermission = live
        trialEndDateString = ExportPermissionService.shared.cachedTrialEndDateString()
        accountCompany = CompanyBrandingService.shared.loadCached()?.name
    }

    private func refresh() {
        isRefreshing = true
        refreshErrorMessage = nil

        Task {
            // Force fresh branding sync
            await CompanyBrandingService.shared.syncForced()

            // Force fresh permission check (always hits network when online)
            let result = await ExportPermissionService.shared.checkExportAllowed()

            await MainActor.run {
                exportPermission = result
                trialEndDateString = ExportPermissionService.shared.cachedTrialEndDateString()
                accountCompany = CompanyBrandingService.shared.loadCached()?.name
                isRefreshing = false

                if case .cannotVerifyOffline = result {
                    refreshErrorMessage = AppStrings.text("לא ניתן להתחבר לשרת. נסה שוב כשיש חיבור לאינטרנט.")
                } else if case .backendError = result {
                    refreshErrorMessage = AppStrings.text("שגיאה בעת קבלת נתוני החברה. נסה שוב מאוחר יותר.")
                }
            }
        }
    }

    private var accountDeletionMailtoURL: URL {
        let body: String
        if let email = authService.currentUserEmail {
            body = "Account email: \(email)\n\nPlease delete my Inspectley account and all associated data."
        } else {
            body = "Please delete my Inspectley account and all associated data."
        }
        return AppSupport.mailtoURL(subject: "Account Deletion Request", body: body)
    }

    private var versionText: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "v\(shortVersion) (\(buildVersion))"
    }
}

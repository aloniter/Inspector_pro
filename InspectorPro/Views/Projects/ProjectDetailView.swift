import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: Project
    @State private var showingNewReport = false
    @State private var showingEditProject = false
    @State private var reportToMove: Report?
    @State private var errorMessage: String?

    var body: some View {
        let sortedReports = project.sortedReports

        List {
            if sortedReports.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    title: AppStrings.text("אין דוחות"),
                    subtitle: AppStrings.text("לחץ + להוספת דוח חדש")
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(sortedReports) { report in
                    NavigationLink(value: report) {
                        ProjectReportRowView(report: report)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            reportToMove = report
                        } label: {
                            Label(AppStrings.text("Move to Project"), systemImage: "folder")
                        }
                        .tint(.blue)
                    }
                    .contextMenu {
                        Button {
                            reportToMove = report
                        } label: {
                            Label(AppStrings.text("Move to Project"), systemImage: "folder")
                        }
                    }
                }
                .onDelete(perform: deleteReports)
            }
        }
        .navigationTitle(project.name)
        .navigationDestination(for: Report.self) { report in
            ReportDetailView(report: report)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showingNewReport = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEditProject = true
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $showingNewReport) {
            NavigationStack {
                ReportFormView(mode: .create, project: project)
            }
        }
        .sheet(isPresented: $showingEditProject) {
            NavigationStack {
                ProjectFormView(mode: .edit, project: project)
            }
        }
        .sheet(item: $reportToMove) { report in
            NavigationStack {
                MoveReportToProjectView(report: report)
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

    private func deleteReports(at offsets: IndexSet) {
        let sorted = project.sortedReports
        let deletedReports = offsets.map { sorted[$0] }
        let deletedPhotoPaths = deletedReports.flatMap { report in
            report.photos.map { photo in
                (originalPath: photo.imagePath, annotatedPath: photo.annotatedImagePath)
            }
        }

        for report in deletedReports {
            modelContext.delete(report)
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
            for report in deletedReports {
                modelContext.insert(report)
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

private struct ProjectReportRowView: View {
    let report: Report

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(AppStrings.format("%d תמונות", report.photos.count))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 4) {
                Text(report.name.directionallyIsolated)
                    .font(.headline)
                    .multilineTextAlignment(.trailing)

                Text(report.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 2)
        .environment(\.layoutDirection, .leftToRight)
    }
}

struct ReportDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var report: Report
    @State private var showingEditReport = false
    @State private var showingExportOptions = false
    @State private var showingMoveReport = false
    @State private var activePicker: PickerSource?
    @State private var isSavingPhotos = false
    @State private var importProgress: ImportProgress?
    @State private var showingImportSummary = false
    @State private var importSummaryMessage = ""
    @State private var editMode: EditMode = .inactive
    @State private var errorMessage: String?

    var body: some View {
        let sortedPhotos = report.sortedPhotos

        List {
            Section {
                if sortedPhotos.isEmpty {
                    EmptyStateView(
                        icon: "photo.on.rectangle",
                        title: AppStrings.text("אין תמונות"),
                        subtitle: AppStrings.text("לחץ + כדי להוסיף תמונות")
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(Array(sortedPhotos.enumerated()), id: \.element.id) { index, photo in
                        if isReorderingPhotos {
                            ProjectPhotoRowView(photo: photo, number: index + 1)
                        } else {
                            NavigationLink(value: photo) {
                                ProjectPhotoRowView(photo: photo, number: index + 1)
                            }
                        }
                    }
                    .onDelete(perform: deletePhotos)
                    .onMove(perform: movePhotos)
                }
            } header: {
                HStack {
                    Text(AppStrings.format("תמונות (%d)", report.photos.count))
                    Spacer()
                }
            }

            if isSavingPhotos {
                Section {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text(importStatusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(report.name)
        .navigationDestination(for: PhotoRecord.self) { photo in
            PhotoDetailView(photo: photo, report: report)
        }
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button {
                        activePicker = .photoLibrary
                    } label: {
                        Label(AppStrings.text("מהגלריה"), systemImage: "photo.on.rectangle")
                    }

                    Button {
                        activePicker = .camera
                    } label: {
                        Label(AppStrings.text("מהמצלמה"), systemImage: "camera")
                    }
                    .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(isSavingPhotos || isReorderingPhotos)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        togglePhotoReordering()
                    } label: {
                        Label(
                            isReorderingPhotos
                                ? AppStrings.text("סיום סידור תמונות")
                                : AppStrings.text("סידור תמונות"),
                            systemImage: isReorderingPhotos ? "checkmark.circle" : "line.3.horizontal"
                        )
                    }
                    .disabled(report.photos.count < 2 || isSavingPhotos)

                    Button {
                        showingEditReport = true
                    } label: {
                        Label(AppStrings.text("ערוך דוח"), systemImage: "pencil")
                    }
                    .disabled(isReorderingPhotos)

                    Button {
                        showingMoveReport = true
                    } label: {
                        Label(AppStrings.text("Move to Project"), systemImage: "folder")
                    }
                    .disabled(isReorderingPhotos)

                    Button {
                        showingExportOptions = true
                    } label: {
                        Label(AppStrings.text("ייצוא דוח"), systemImage: "square.and.arrow.up")
                    }
                    .disabled(isReorderingPhotos)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditReport) {
            NavigationStack {
                if let project = report.project {
                    ReportFormView(mode: .edit, project: project, report: report)
                }
            }
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsSheet(report: report)
        }
        .sheet(isPresented: $showingMoveReport) {
            NavigationStack {
                MoveReportToProjectView(report: report)
            }
        }
        .sheet(item: $activePicker) { source in
            switch source {
            case .photoLibrary:
                PhotoLibraryPickerView(selectionLimit: AppConstants.gallerySelectionLimit) { results in
                    activePicker = nil
                    guard !results.isEmpty else { return }

                    Task {
                        await Task.yield()
                        await addPhotos(from: results)
                    }
                }
            case .camera:
                CameraImagePickerView { image in
                    activePicker = nil
                    guard let image else { return }

                    Task {
                        await addPhoto(image)
                    }
                }
            }
        }
        .alert(AppStrings.text("ייבוא תמונות"), isPresented: $showingImportSummary) {
            Button(AppStrings.text("אישור"), role: .cancel) {}
        } message: {
            Text(importSummaryMessage)
        }
        .alert(AppStrings.text("הפעולה נכשלה"), isPresented: errorAlertPresented) {
            Button(AppStrings.text("אישור"), role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? AppStrings.text("אירעה שגיאה בשמירה"))
        }
    }

    @MainActor
    private func addPhoto(_ image: UIImage) async {
        isSavingPhotos = true
        importProgress = ImportProgress(processed: 0, total: 1)
        defer {
            isSavingPhotos = false
            importProgress = nil
        }

        var importedPhoto: PhotoRecord?

        do {
            let photo = try await savePhotoRecord(from: image)
            importedPhoto = photo
            try saveModelContext()
            importProgress = ImportProgress(processed: 1, total: 1)
        } catch {
            if let importedPhoto {
                rollbackImportedPhotos([importedPhoto])
                await deleteImportedFiles(for: [importedPhoto])
            }
            errorMessage = userFacingErrorMessage(for: error)
        }
    }

    @MainActor
    private func addPhotos(from results: [PHPickerResult]) async {
        guard !results.isEmpty else { return }

        isSavingPhotos = true
        importProgress = ImportProgress(processed: 0, total: results.count)

        var successCount = 0
        var failedCount = 0
        var pendingImportedPhotos: [PhotoRecord] = []
        defer {
            isSavingPhotos = false
            importProgress = nil
            if errorMessage == nil {
                presentImportSummary(successCount: successCount, failedCount: failedCount)
            }
        }

        for (index, result) in results.enumerated() {
            do {
                let image = try await result.itemProvider.loadUIImage()
                let photo = try await savePhotoRecord(from: image)
                pendingImportedPhotos.append(photo)

                if pendingImportedPhotos.count >= AppConstants.importSaveCheckpoint {
                    let persistedCount = try await persistImportedPhotos(pendingImportedPhotos)
                    successCount += persistedCount
                    pendingImportedPhotos.removeAll(keepingCapacity: true)
                }
            } catch {
                failedCount += 1
                let errorMessage = userFacingErrorMessage(for: error)
                if shouldAbortImport(for: error) {
                    rollbackImportedPhotos(pendingImportedPhotos)
                    await deleteImportedFiles(for: pendingImportedPhotos)
                    pendingImportedPhotos.removeAll(keepingCapacity: true)
                    self.errorMessage = errorMessage
                    return
                }
            }

            importProgress = ImportProgress(processed: index + 1, total: results.count)
            if index % 2 == 1 {
                await Task.yield()
            }
        }

        do {
            let persistedCount = try await persistImportedPhotos(pendingImportedPhotos)
            successCount += persistedCount
        } catch {
            errorMessage = userFacingErrorMessage(for: error)
        }
    }

    @MainActor
    private func savePhotoRecord(from image: UIImage) async throws -> PhotoRecord {
        let imagePath = try await ImageStorageService.shared.saveImage(
            image,
            projectID: report.project?.id.uuidString ?? report.id.uuidString
        )
        let photo = PhotoRecord(
            imagePath: imagePath,
            position: nextPhotoPosition()
        )
        photo.report = report
        modelContext.insert(photo)
        return photo
    }

    @MainActor
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

    @MainActor
    private func saveModelContext() throws {
        try modelContext.save()
    }

    @MainActor
    private func persistImportedPhotos(_ photos: [PhotoRecord]) async throws -> Int {
        guard !photos.isEmpty else { return 0 }

        do {
            try saveModelContext()
            return photos.count
        } catch {
            rollbackImportedPhotos(photos)
            await deleteImportedFiles(for: photos)
            throw error
        }
    }

    @MainActor
    private func rollbackImportedPhotos(_ photos: [PhotoRecord]) {
        for photo in photos {
            modelContext.delete(photo)
        }
    }

    private func deleteImportedFiles(for photos: [PhotoRecord]) async {
        for photo in photos {
            await ImageStorageService.shared.deletePhotoFiles(
                originalPath: photo.imagePath,
                annotatedPath: photo.annotatedImagePath
            )
        }
    }

    private func presentImportSummary(successCount: Int, failedCount: Int) {
        guard failedCount > 0 else { return }

        importSummaryMessage = AppStrings.format(
            "נשמרו %d תמונות. %d תמונות לא יובאו.",
            successCount,
            failedCount
        )
        showingImportSummary = true
    }

    private var importStatusText: String {
        guard let importProgress else {
            return AppStrings.text("שומר תמונות...")
        }

        if importProgress.total == 1 {
            return AppStrings.text("שומר תמונה...")
        }

        return AppStrings.format("שומר תמונות %d/%d...", importProgress.processed, importProgress.total)
    }

    private func deletePhotos(at offsets: IndexSet) {
        let sorted = report.sortedPhotos
        let deletedPhotos = offsets.map { sorted[$0] }
        let originalPositions = Dictionary(uniqueKeysWithValues: sorted.map { ($0.id, $0.position) })

        for photo in deletedPhotos {
            modelContext.delete(photo)
        }

        var remainingPhotos = sorted
        remainingPhotos.remove(atOffsets: offsets)
        normalizePhotoPositions(using: remainingPhotos)

        do {
            try saveModelContext()

            Task {
                for photo in deletedPhotos {
                    await ImageStorageService.shared.deletePhotoFiles(
                        originalPath: photo.imagePath,
                        annotatedPath: photo.annotatedImagePath
                    )
                }
            }

            if remainingPhotos.count < 2 {
                editMode = .inactive
            }
        } catch {
            for photo in deletedPhotos {
                modelContext.insert(photo)
            }
            restorePhotoPositions(from: originalPositions, photos: sorted)
            errorMessage = userFacingErrorMessage(for: error)
        }
    }

    private func movePhotos(from source: IndexSet, to destination: Int) {
        var reorderedPhotos = report.sortedPhotos
        let originalPositions = Dictionary(uniqueKeysWithValues: reorderedPhotos.map { ($0.id, $0.position) })
        reorderedPhotos.move(fromOffsets: source, toOffset: destination)
        normalizePhotoPositions(using: reorderedPhotos)

        do {
            try saveModelContext()
        } catch {
            restorePhotoPositions(from: originalPositions, photos: report.sortedPhotos)
            errorMessage = userFacingErrorMessage(for: error)
        }
    }

    private func nextPhotoPosition() -> Int {
        (report.photos.map(\.position).max() ?? -1) + 1
    }

    private func normalizePhotoPositions(using orderedPhotos: [PhotoRecord]) {
        for (index, photo) in orderedPhotos.enumerated() {
            photo.position = index
        }
    }

    private func restorePhotoPositions(from positions: [UUID: Int], photos: [PhotoRecord]) {
        for photo in photos {
            if let originalPosition = positions[photo.id] {
                photo.position = originalPosition
            }
        }
    }

    private func togglePhotoReordering() {
        withAnimation {
            editMode = isReorderingPhotos ? .inactive : .active
        }
    }

    private var isReorderingPhotos: Bool {
        editMode == .active || editMode == .transient
    }

    private func shouldAbortImport(for error: Error) -> Bool {
        ![
            PhotoImportError.unsupportedContent,
            PhotoImportError.loadFailed,
        ].contains { candidate in
            (error as? PhotoImportError) == candidate
        }
    }

    private func userFacingErrorMessage(for error: Error) -> String {
        let description = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        return description.isEmpty ? AppStrings.text("אירעה שגיאה בשמירה") : description
    }
}

private struct ImportProgress {
    let processed: Int
    let total: Int
}

private struct MoveReportToProjectView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Project.name) private var projects: [Project]

    let report: Report

    @State private var errorMessage: String?

    private var currentProjectID: UUID? {
        report.project?.id
    }

    private var hasOtherProjects: Bool {
        projects.contains { $0.id != currentProjectID }
    }

    var body: some View {
        List {
            if !hasOtherProjects {
                EmptyStateView(
                    icon: "folder",
                    title: AppStrings.text("No other projects"),
                    subtitle: AppStrings.text("Create another project before moving this report.")
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Section {
                ForEach(projects) { project in
                    Button {
                        moveReport(to: project)
                    } label: {
                        ProjectMoveRowView(
                            project: project,
                            isCurrentProject: project.id == currentProjectID
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(project.id == currentProjectID)
                }
            }
        }
        .navigationTitle(AppStrings.text("Move to Project"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(AppStrings.text("ביטול")) {
                    dismiss()
                }
            }
        }
        .alert(AppStrings.text("Move failed"), isPresented: errorAlertPresented) {
            Button(AppStrings.text("אישור"), role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? AppStrings.text("אירעה שגיאה בשמירה"))
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

    private func moveReport(to destinationProject: Project) {
        let originalProject = report.project
        guard report.move(to: destinationProject) else {
            dismiss()
            return
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            report.project = originalProject
            try? modelContext.save()
            errorMessage = userFacingErrorMessage(for: error)
        }
    }

    private func userFacingErrorMessage(for error: Error) -> String {
        let description = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        return description.isEmpty ? AppStrings.text("אירעה שגיאה בשמירה") : description
    }
}

private struct ProjectMoveRowView: View {
    let project: Project
    let isCurrentProject: Bool

    var body: some View {
        HStack(spacing: 12) {
            if isCurrentProject {
                Label(AppStrings.text("Current project"), systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .labelStyle(.titleAndIcon)
            } else {
                Image(systemName: "chevron.left")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            VStack(alignment: .trailing, spacing: 4) {
                Text(project.name.directionallyIsolated)
                    .font(.headline)
                    .foregroundStyle(isCurrentProject ? .secondary : .primary)
                    .multilineTextAlignment(.trailing)

                if let address = project.address, !address.isEmpty {
                    Text(address.directionallyIsolated)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .contentShape(Rectangle())
        .environment(\.layoutDirection, .leftToRight)
    }
}

private enum PhotoImportError: Error, Equatable {
    case unsupportedContent
    case loadFailed
}

private extension NSItemProvider {
    func loadUIImage() async throws -> UIImage {
        if canLoadObject(ofClass: UIImage.self) {
            do {
                return try await loadUIImageObject()
            } catch {
                // Fall back to raw image data when direct UIImage loading fails.
            }
        }

        guard hasItemConformingToTypeIdentifier(UTType.image.identifier) else {
            throw PhotoImportError.unsupportedContent
        }

        let data: Data = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
            loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let data else {
                    continuation.resume(throwing: PhotoImportError.loadFailed)
                    return
                }

                continuation.resume(returning: data)
            }
        }

        guard let image = UIImage(data: data) else {
            throw PhotoImportError.loadFailed
        }
        return image
    }

    private func loadUIImageObject() async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            loadObject(ofClass: UIImage.self) { object, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let image = object as? UIImage else {
                    continuation.resume(throwing: PhotoImportError.loadFailed)
                    return
                }

                continuation.resume(returning: image)
            }
        }
    }
}

struct ProjectPhotoRowView: View {
    @Environment(\.layoutDirection) private var layoutDirection
    let photo: PhotoRecord
    let number: Int

    private var contentAlignment: HorizontalAlignment {
        AppTextDirection.horizontalAlignment(for: layoutDirection)
    }

    private var textAlignment: TextAlignment {
        AppTextDirection.textAlignment(for: layoutDirection)
    }

    private var badgeAlignment: Alignment {
        layoutDirection == .rightToLeft ? .topTrailing : .topLeading
    }

    var body: some View {
        HStack(spacing: 12) {
            ThumbnailView(imagePath: photo.displayImagePath)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(alignment: badgeAlignment) {
                    Text("\(number)")
                        .font(.caption2.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.75), in: Capsule())
                        .padding(6)
                }

            VStack(alignment: contentAlignment, spacing: 4) {
                Text(photo.freeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppStrings.text("ללא הערה") : photo.freeText)
                    .font(.body)
                    .lineLimit(2)
                    .multilineTextAlignment(textAlignment)

                Text(photo.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: Project
    @State private var showingEditProject = false
    @State private var showingExportOptions = false
    @State private var activePicker: PickerSource?
    @State private var isSavingPhotos = false
    @State private var importProgress: ImportProgress?
    @State private var showingImportSummary = false
    @State private var importSummaryMessage = ""

    var body: some View {
        List {
            Section {
                if project.sortedPhotos.isEmpty {
                    EmptyStateView(
                        icon: "photo.on.rectangle",
                        title: "אין תמונות",
                        subtitle: "לחץ + כדי להוסיף תמונות"
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(project.sortedPhotos) { photo in
                        NavigationLink(value: photo) {
                            ProjectPhotoRowView(photo: photo)
                        }
                    }
                    .onDelete(perform: deletePhotos)
                }
            } header: {
                HStack {
                    Text("תמונות (\(project.photos.count))")
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
        .navigationTitle(project.name)
        .navigationDestination(for: PhotoRecord.self) { photo in
            PhotoDetailView(photo: photo, project: project)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button {
                        activePicker = .photoLibrary
                    } label: {
                        Label("מהגלריה", systemImage: "photo.on.rectangle")
                    }

                    Button {
                        activePicker = .camera
                    } label: {
                        Label("מהמצלמה", systemImage: "camera")
                    }
                    .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(isSavingPhotos)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEditProject = true
                    } label: {
                        Label("ערוך פרויקט", systemImage: "pencil")
                    }

                    Button {
                        showingExportOptions = true
                    } label: {
                        Label("ייצוא דוח", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditProject) {
            NavigationStack {
                ProjectFormView(mode: .edit, project: project)
            }
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsSheet(project: project)
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
        .alert("ייבוא תמונות", isPresented: $showingImportSummary) {
            Button("אישור", role: .cancel) {}
        } message: {
            Text(importSummaryMessage)
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

        do {
            try await savePhotoRecord(from: image)
            importProgress = ImportProgress(processed: 1, total: 1)
            saveModelContext()
        } catch {
            print("Failed to save photo: \(error)")
            presentImportSummary(successCount: 0, failedCount: 1)
        }
    }

    @MainActor
    private func addPhotos(from results: [PHPickerResult]) async {
        guard !results.isEmpty else { return }

        isSavingPhotos = true
        importProgress = ImportProgress(processed: 0, total: results.count)

        var successCount = 0
        var failedCount = 0
        defer {
            isSavingPhotos = false
            importProgress = nil
            presentImportSummary(successCount: successCount, failedCount: failedCount)
        }

        for (index, result) in results.enumerated() {
            do {
                let image = try await result.itemProvider.loadUIImage()
                try await savePhotoRecord(from: image)
                successCount += 1

                if successCount % AppConstants.importSaveCheckpoint == 0 {
                    saveModelContext()
                }
            } catch {
                failedCount += 1
                print("Failed to import selected image: \(error)")
            }

            importProgress = ImportProgress(processed: index + 1, total: results.count)
            if index % 4 == 3 {
                await Task.yield()
            }
        }

        saveModelContext()
    }

    @MainActor
    private func savePhotoRecord(from image: UIImage) async throws {
        let imagePath = try await ImageStorageService.shared.saveImage(
            image,
            projectID: project.id.uuidString
        )
        let photo = PhotoRecord(imagePath: imagePath)
        photo.project = project
        modelContext.insert(photo)
    }

    @MainActor
    private func saveModelContext() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save model context: \(error)")
        }
    }

    private func presentImportSummary(successCount: Int, failedCount: Int) {
        guard failedCount > 0 else { return }

        importSummaryMessage = "נשמרו \(successCount) תמונות. \(failedCount) תמונות לא יובאו."
        showingImportSummary = true
    }

    private var importStatusText: String {
        guard let importProgress else {
            return "שומר תמונות..."
        }

        if importProgress.total == 1 {
            return "שומר תמונה..."
        }

        return "שומר תמונות \(importProgress.processed)/\(importProgress.total)..."
    }

    private func deletePhotos(at offsets: IndexSet) {
        let sorted = project.sortedPhotos
        for index in offsets {
            let photo = sorted[index]
            let imagePath = photo.imagePath
            let annotatedPath = photo.annotatedImagePath
            Task {
                await ImageStorageService.shared.deletePhotoFiles(
                    originalPath: imagePath,
                    annotatedPath: annotatedPath
                )
            }
            modelContext.delete(photo)
        }
    }
}

private struct ImportProgress {
    let processed: Int
    let total: Int
}

private enum PhotoImportError: Error {
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
    let photo: PhotoRecord

    var body: some View {
        HStack(spacing: 12) {
            ThumbnailView(imagePath: photo.displayImagePath)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .trailing, spacing: 4) {
                Text(photo.freeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "ללא הערה" : photo.freeText)
                    .font(.body)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)

                Text(photo.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

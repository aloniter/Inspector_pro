import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: Project
    @State private var showingEditProject = false
    @State private var showingExportOptions = false
    @State private var activePicker: PickerSource?
    @State private var isSavingPhoto = false

    var body: some View {
        List {
            Section {
                if project.sortedPhotos.isEmpty {
                    EmptyStateView(
                        icon: "photo.on.rectangle",
                        title: "אין תמונות",
                        subtitle: "לחץ + כדי להוסיף תמונה"
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

            if isSavingPhoto {
                Section {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("שומר תמונה...")
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
            ImagePickerView(sourceType: source.uiSourceType) { image in
                Task {
                    await addPhoto(image)
                }
            }
        }
    }

    @MainActor
    private func addPhoto(_ image: UIImage) async {
        isSavingPhoto = true
        defer { isSavingPhoto = false }

        do {
            let imagePath = try await ImageStorageService.shared.saveImage(
                image,
                projectID: project.id.uuidString
            )
            let photo = PhotoRecord(imagePath: imagePath)
            photo.project = project
            modelContext.insert(photo)
        } catch {
            print("Failed to save photo: \(error)")
        }
    }

    private func deletePhotos(at offsets: IndexSet) {
        let sorted = project.sortedPhotos
        for index in offsets {
            let photo = sorted[index]
            Task {
                await ImageStorageService.shared.deletePhotos([photo])
            }
            modelContext.delete(photo)
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

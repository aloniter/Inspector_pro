import SwiftUI
import PhotosUI

struct FindingEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var finding: Finding
    let project: Project

    @State private var showingCamera = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var isLoadingPhotos = false

    var body: some View {
        Form {
            Section("פרטי ממצא") {
                HStack {
                    Text("ממצא מספר")
                    Spacer()
                    Text("\(finding.number)")
                        .fontWeight(.bold)
                }

                TextField("חדר / אזור", text: $finding.room)
                    .multilineTextAlignment(.trailing)

                TextField("כותרת", text: $finding.title)
                    .multilineTextAlignment(.trailing)

                Picker("חומרה", selection: $finding.severity) {
                    ForEach(Severity.allCases) { severity in
                        Text(severity.hebrewLabel).tag(severity)
                    }
                }
            }

            Section("תיאור") {
                TextEditor(text: $finding.findingDescription)
                    .frame(minHeight: 60)
                    .multilineTextAlignment(.trailing)
            }

            Section("המלצה") {
                TextEditor(text: $finding.recommendation)
                    .frame(minHeight: 60)
                    .multilineTextAlignment(.trailing)
            }

            Section {
                PhotoGridView(finding: finding, project: project)

                HStack {
                    PhotosPicker(selection: $selectedPhotos, matching: .images) {
                        Label("מהגלריה", systemImage: "photo.on.rectangle")
                    }

                    Spacer()

                    Button {
                        showingCamera = true
                    } label: {
                        Label("מהמצלמה", systemImage: "camera")
                    }
                }

                if isLoadingPhotos {
                    ProgressView("מייבא תמונות...")
                }
            } header: {
                Text("תמונות (\(finding.photos.count))")
            }
        }
        .navigationTitle("ממצא \(finding.number)")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedPhotos) { _, newItems in
            Task {
                await loadPhotos(from: newItems)
                selectedPhotos = []
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView { image in
                Task {
                    await savePhoto(image)
                }
            }
        }
    }

    private func loadPhotos(from items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        isLoadingPhotos = true
        defer { isLoadingPhotos = false }

        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else { continue }
            await savePhoto(image)
        }
    }

    @MainActor
    private func savePhoto(_ image: UIImage) async {
        let projectID = project.persistentModelID.hashValue.description
        let findingID = finding.persistentModelID.hashValue.description

        do {
            let paths = try await ImageStorageService.shared.saveImage(
                image,
                projectID: projectID,
                findingID: findingID
            )

            let order = finding.photos.count
            let photo = Photo(
                imagePath: paths.imagePath,
                order: order
            )
            photo.thumbnailPath = paths.thumbnailPath
            photo.finding = finding
            modelContext.insert(photo)
            project.updatedAt = .now
        } catch {
            print("Failed to save photo: \(error)")
        }
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

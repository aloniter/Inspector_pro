import SwiftUI

struct PhotoDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var photo: PhotoRecord
    let project: Project

    @State private var displayedImage: UIImage?
    @State private var originalImage: UIImage?
    @State private var showingAnnotation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Group {
                    if let image = displayedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.12))
                            .overlay { ProgressView() }
                    }
                }
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .trailing, spacing: 8) {
                    Text("הערות")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    TextEditor(text: $photo.freeText)
                        .frame(minHeight: 140)
                        .padding(8)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                        .multilineTextAlignment(.trailing)
                }
            }
            .padding()
        }
        .navigationTitle("תמונה")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    showingAnnotation = true
                } label: {
                    Label("צייר / סמן", systemImage: "pencil.tip.crop.circle")
                }

                Spacer()

                Button(role: .destructive) {
                    deletePhoto()
                } label: {
                    Label("מחק", systemImage: "trash")
                }
            }
        }
        .task(id: photo.displayImagePath) {
            let preferredImage = await ImageStorageService.shared.loadImage(at: photo.displayImagePath)
            let loadedOriginal = await ImageStorageService.shared.loadImage(at: photo.imagePath)

            if preferredImage == nil, photo.annotatedImagePath != nil {
                // Recover from a stale/missing annotation file path.
                photo.annotatedImagePath = nil
                try? modelContext.save()
            }

            displayedImage = preferredImage ?? loadedOriginal
            originalImage = loadedOriginal ?? preferredImage
        }
        .fullScreenCover(isPresented: $showingAnnotation) {
            if let image = originalImage ?? displayedImage {
                AnnotationView(
                    image: image,
                    photo: photo,
                    project: project
                )
            }
        }
    }

    private func deletePhoto() {
        let imagePath = photo.imagePath
        let annotatedPath = photo.annotatedImagePath
        Task {
            await ImageStorageService.shared.deletePhotoFiles(
                originalPath: imagePath,
                annotatedPath: annotatedPath
            )
        }
        modelContext.delete(photo)
        dismiss()
    }
}

import SwiftUI

struct PhotoDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let photo: Photo
    let finding: Finding
    let project: Project

    @State private var image: UIImage?
    @State private var showingAnnotation = false

    var body: some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("תמונה")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("סגור") {
                    dismiss()
                }
            }

            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    showingAnnotation = true
                } label: {
                    Label("סימון", systemImage: "pencil.tip.crop.circle")
                }

                Spacer()

                Button(role: .destructive) {
                    deletePhoto()
                } label: {
                    Label("מחק", systemImage: "trash")
                }
            }
        }
        .task {
            image = await ImageStorageService.shared.loadImage(at: photo.exportImagePath)
        }
        .fullScreenCover(isPresented: $showingAnnotation) {
            if let image = image {
                AnnotationView(
                    image: image,
                    existingDrawingData: photo.annotationData,
                    photo: photo,
                    project: project,
                    finding: finding
                )
            }
        }
    }

    private func deletePhoto() {
        Task {
            await ImageStorageService.shared.deletePhotos([photo])
        }
        modelContext.delete(photo)
        dismiss()
    }
}

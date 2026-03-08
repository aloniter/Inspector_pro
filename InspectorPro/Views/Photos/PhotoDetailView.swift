import SwiftUI

struct PhotoDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.layoutDirection) private var layoutDirection
    @Bindable var photo: PhotoRecord
    let project: Project

    @State private var displayedImage: UIImage?
    @State private var originalImage: UIImage?
    @State private var showingAnnotation = false
    @State private var showingDeleteConfirmation = false
    @FocusState private var isEditingNotes: Bool

    private var contentHorizontalAlignment: HorizontalAlignment {
        AppTextDirection.horizontalAlignment(for: layoutDirection)
    }

    private var contentTextAlignment: TextAlignment {
        AppTextDirection.textAlignment(for: layoutDirection)
    }

    private var frameAlignment: Alignment {
        AppTextDirection.frameAlignment(for: layoutDirection)
    }

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

                VStack(alignment: contentHorizontalAlignment, spacing: 8) {
                    Text(AppStrings.text("הערות"))
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: frameAlignment)

                    TextEditor(text: $photo.freeText)
                        .frame(minHeight: 140)
                        .padding(8)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                        .multilineTextAlignment(contentTextAlignment)
                        .focused($isEditingNotes)
                }
            }
            .padding()
        }
        .navigationTitle(AppStrings.text("תמונה"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    showingAnnotation = true
                } label: {
                    Label(AppStrings.text("צייר / סמן"), systemImage: "pencil.tip.crop.circle")
                }

                Spacer()

                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label(AppStrings.text("מחק"), systemImage: "trash")
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button(AppStrings.text("סיום")) {
                    isEditingNotes = false
                }
            }
        }
        .onChange(of: isEditingNotes) { _, isFocused in
            if !isFocused {
                saveChanges()
            }
        }
        .alert(AppStrings.text("למחוק את התמונה?"), isPresented: $showingDeleteConfirmation) {
            Button(AppStrings.text("ביטול"), role: .cancel) {}
            Button(AppStrings.text("מחק"), role: .destructive) {
                deletePhoto()
            }
        } message: {
            Text(AppStrings.text("האם אתה בטוח שברצונך למחוק את התמונה? לא ניתן לבטל פעולה זו."))
        }
        .task(id: photo.displayImagePath) {
            await reloadImages()
        }
        .fullScreenCover(
            isPresented: $showingAnnotation,
            onDismiss: { Task { await reloadImages() } }
        ) {
            if let baseImage = displayedImage {
                AnnotationView(
                    image: baseImage,
                    originalImage: originalImage ?? baseImage,
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

    private func saveChanges() {
        try? modelContext.save()
    }

    @MainActor
    private func reloadImages() async {
        let loadedOriginal = await ImageStorageService.shared.loadImage(at: photo.imagePath)
        let loadedAnnotated: UIImage?

        if let annotatedPath = photo.annotatedImagePath {
            loadedAnnotated = await ImageStorageService.shared.loadImage(at: annotatedPath)
            if loadedAnnotated == nil {
                // Recover from a stale/missing annotation file path.
                photo.annotatedImagePath = nil
                try? modelContext.save()
            }
        } else {
            loadedAnnotated = nil
        }

        displayedImage = loadedAnnotated ?? loadedOriginal
        originalImage = loadedOriginal ?? loadedAnnotated
    }
}

import SwiftUI

struct PhotoDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.layoutDirection) private var layoutDirection
    @Bindable var photo: PhotoRecord
    let report: Report

    @State private var displayedImage: UIImage?
    @State private var originalImage: UIImage?
    @State private var showingAnnotation = false
    @State private var showingDeleteConfirmation = false
    @State private var isEditingNotes = false
    @State private var noteText = ""
    @State private var errorMessage: String?

    private var hasUnsavedNoteChanges: Bool {
        noteText != photo.freeText
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

                VStack(alignment: .leading, spacing: 8) {
                    Text(AppStrings.text("הערות"))
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    DirectionalTextEditor(
                        text: $noteText,
                        isFocused: $isEditingNotes,
                        layoutDirection: layoutDirection
                    )
                        .frame(minHeight: 140)
                        .padding(8)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))

                    Button {
                        finishNotesEditing()
                    } label: {
                        Label(AppStrings.text("סיום ושמירת הערות"), systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isEditingNotes && !hasUnsavedNoteChanges)
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
                    finishNotesEditing()
                }
            }
        }
        .onChange(of: isEditingNotes) { _, isFocused in
            if !isFocused {
                commitNoteChanges()
            }
        }
        .onAppear {
            noteText = photo.freeText
        }
        .alert(AppStrings.text("למחוק את התמונה?"), isPresented: $showingDeleteConfirmation) {
            Button(AppStrings.text("ביטול"), role: .cancel) {}
            Button(AppStrings.text("מחק"), role: .destructive) {
                deletePhoto()
            }
        } message: {
            Text(AppStrings.text("האם אתה בטוח שברצונך למחוק את התמונה? לא ניתן לבטל פעולה זו."))
        }
        .alert(AppStrings.text("הפעולה נכשלה"), isPresented: errorAlertPresented) {
            Button(AppStrings.text("אישור"), role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? AppStrings.text("אירעה שגיאה בשמירה"))
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
                    report: report
                )
            }
        }
    }

    private func deletePhoto() {
        let imagePath = photo.imagePath
        let annotatedPath = photo.annotatedImagePath

        modelContext.delete(photo)

        do {
            try modelContext.save()
            Task {
                await ImageStorageService.shared.deletePhotoFiles(
                    originalPath: imagePath,
                    annotatedPath: annotatedPath
                )
            }
            dismiss()
        } catch {
            modelContext.insert(photo)
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

    private func saveChanges() throws {
        try modelContext.save()
    }

    private func finishNotesEditing() {
        if commitNoteChanges() {
            isEditingNotes = false
        }
    }

    @discardableResult
    private func commitNoteChanges() -> Bool {
        guard hasUnsavedNoteChanges else { return true }

        let originalText = photo.freeText
        photo.freeText = noteText

        do {
            try saveChanges()
            return true
        } catch {
            photo.freeText = originalText
            errorMessage = userFacingErrorMessage(for: error)
            return false
        }
    }

    @MainActor
    private func reloadImages() async {
        let loadedOriginal = await ImageStorageService.shared.loadImage(at: photo.imagePath)
        let loadedAnnotated: UIImage?

        if let annotatedPath = photo.annotatedImagePath {
            loadedAnnotated = await ImageStorageService.shared.loadImage(at: annotatedPath)
            if loadedAnnotated == nil {
                // Recover from a stale/missing annotation file path.
                let originalAnnotatedPath = photo.annotatedImagePath
                photo.annotatedImagePath = nil
                do {
                    try modelContext.save()
                } catch {
                    photo.annotatedImagePath = originalAnnotatedPath
                    errorMessage = userFacingErrorMessage(for: error)
                }
            }
        } else {
            loadedAnnotated = nil
        }

        displayedImage = loadedAnnotated ?? loadedOriginal
        originalImage = loadedOriginal ?? loadedAnnotated
    }

    private func userFacingErrorMessage(for error: Error) -> String {
        let description = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        return description.isEmpty ? AppStrings.text("אירעה שגיאה בשמירה") : description
    }
}

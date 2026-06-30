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
        VStack(spacing: 0) {
            PhotoDetailImagePreview(image: displayedImage)
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)

            PhotoDetailBottomPanel(
                noteText: $noteText,
                isEditingNotes: $isEditingNotes,
                layoutDirection: layoutDirection,
                hasUnsavedNoteChanges: hasUnsavedNoteChanges,
                canAnnotate: displayedImage != nil,
                onFinishNotes: finishNotesEditing,
                onAnnotate: {
                    guard displayedImage != nil else { return }
                    showingAnnotation = true
                },
                onDelete: {
                    showingDeleteConfirmation = true
                }
            )
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(AppStrings.text("תמונה"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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

private struct PhotoDetailImagePreview: View {
    let image: UIImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))

            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(uiColor: .tertiarySystemGroupedBackground),
                            Color(uiColor: .secondarySystemGroupedBackground),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(6)

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(2)
            } else {
                ProgressView()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

private struct PhotoDetailBottomPanel: View {
    @Binding var noteText: String
    @Binding var isEditingNotes: Bool
    let layoutDirection: LayoutDirection
    let hasUnsavedNoteChanges: Bool
    let canAnnotate: Bool
    let onFinishNotes: () -> Void
    let onAnnotate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    Button {
                        onFinishNotes()
                    } label: {
                        Label(AppStrings.text("סיום"), systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(.bordered)
                    .disabled(!isEditingNotes && !hasUnsavedNoteChanges)

                    Spacer(minLength: 8)

                    Text(AppStrings.text("הערות"))
                        .font(.headline)
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))

                    DirectionalTextEditor(
                        text: $noteText,
                        isFocused: $isEditingNotes,
                        layoutDirection: layoutDirection
                    )
                    .padding(8)
                }
                .frame(height: 104)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.05), lineWidth: 1)
                }
            }

            HStack(spacing: 12) {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label(AppStrings.text("מחק"), systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    onAnnotate()
                } label: {
                    Label(AppStrings.text("צייר / סמן"), systemImage: "pencil.tip.crop.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!canAnnotate)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 14)
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: 20,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 20,
                style: .continuous
            )
            .fill(Color(uiColor: .systemBackground))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: -3)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.black.opacity(0.06))
                .frame(height: 1)
        }
    }
}

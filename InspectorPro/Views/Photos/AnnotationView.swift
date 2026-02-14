import SwiftUI
import PencilKit

struct AnnotationView: View {
    @Environment(\.dismiss) private var dismiss

    let image: UIImage
    let photo: PhotoRecord
    let project: Project

    @State private var canvasView = PKCanvasView()
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            AnnotationCanvasRepresentable(
                image: image,
                canvasView: $canvasView
            )
            .ignoresSafeArea()
            .navigationTitle("סימון")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ביטול") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("נקה") {
                        canvasView.drawing = PKDrawing()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("שמור") {
                        Task { await saveAnnotation() }
                    }
                    .disabled(isSaving)
                }
            }
            .overlay {
                if isSaving {
                    ProgressView("שומר...")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    @MainActor
    private func saveAnnotation() async {
        isSaving = true
        defer { isSaving = false }

        if canvasView.drawing.strokes.isEmpty {
            await ImageStorageService.shared.clearAnnotatedImage(for: photo)
            await ExportCache.shared.invalidate(for: photo)
            dismiss()
            return
        }

        let compositeImage = renderComposite()
        let projectID = project.id.uuidString
        let uuid = URL(fileURLWithPath: photo.imagePath).deletingPathExtension().lastPathComponent

        do {
            let annotatedPath = try await ImageStorageService.shared.saveAnnotatedImage(
                compositeImage,
                projectID: projectID,
                originalUUID: uuid
            )
            photo.annotatedImagePath = annotatedPath
            await ExportCache.shared.invalidate(for: photo)
        } catch {
            print("Failed to save annotated image: \(error)")
        }

        dismiss()
    }

    @MainActor
    private func renderComposite() -> UIImage {
        let imageSize = image.size
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: imageSize))

            let canvasSize = canvasView.bounds.size
            guard canvasSize.width > 0, canvasSize.height > 0 else { return }

            let scale = UIScreen.main.scale
            let drawingImage = canvasView.drawing.image(
                from: canvasView.bounds,
                scale: scale
            )
            drawingImage.draw(in: CGRect(origin: .zero, size: imageSize))
        }
    }
}

// MARK: - Canvas UIViewRepresentable

struct AnnotationCanvasRepresentable: UIViewRepresentable {
    let image: UIImage
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> UIView {
        let container = UIView()

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(imageView)

        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .red, width: 5)
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(canvasView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            canvasView.topAnchor.constraint(equalTo: container.topAnchor),
            canvasView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            canvasView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

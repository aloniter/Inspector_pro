import SwiftUI
import PencilKit

struct AnnotationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let image: UIImage
    let existingDrawingData: Data?
    let photo: Photo
    let project: Project
    let finding: Finding

    @State private var canvasView = PKCanvasView()
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            AnnotationCanvasRepresentable(
                image: image,
                canvasView: $canvasView,
                existingDrawingData: existingDrawingData
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

        // Save PKDrawing data
        let drawingData = canvasView.drawing.dataRepresentation()
        photo.annotationData = drawingData

        // Create composite image
        let compositeImage = renderComposite()

        // Save annotated image to disk
        let projectID = project.persistentModelID.hashValue.description
        let findingID = finding.persistentModelID.hashValue.description
        let uuid = URL(fileURLWithPath: photo.imagePath).deletingPathExtension().lastPathComponent

        do {
            let annotatedPath = try await ImageStorageService.shared.saveAnnotatedImage(
                compositeImage,
                projectID: projectID,
                findingID: findingID,
                originalUUID: uuid
            )
            photo.annotatedPath = annotatedPath
        } catch {
            print("Failed to save annotated image: \(error)")
        }

        dismiss()
    }

    @MainActor
    private func renderComposite() -> UIImage {
        let imageSize = image.size
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        return renderer.image { ctx in
            image.draw(in: CGRect(origin: .zero, size: imageSize))

            // Scale the drawing to match the image size
            let canvasSize = canvasView.bounds.size
            guard canvasSize.width > 0, canvasSize.height > 0 else { return }

            let scaleX = imageSize.width / canvasSize.width
            let scaleY = imageSize.height / canvasSize.height

            ctx.cgContext.scaleBy(x: scaleX, y: scaleY)

            let drawingImage = canvasView.drawing.image(from: canvasView.bounds, scale: 1.0)
            drawingImage.draw(in: canvasView.bounds)
        }
    }
}

// MARK: - Canvas UIViewRepresentable

struct AnnotationCanvasRepresentable: UIViewRepresentable {
    let image: UIImage
    @Binding var canvasView: PKCanvasView
    let existingDrawingData: Data?

    func makeUIView(context: Context) -> UIView {
        let container = UIView()

        // Background image
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(imageView)

        // Canvas overlay
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

        // Restore existing drawing
        if let data = existingDrawingData,
           let drawing = try? PKDrawing(data: data) {
            canvasView.drawing = drawing
        }

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

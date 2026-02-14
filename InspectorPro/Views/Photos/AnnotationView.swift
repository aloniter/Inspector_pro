import SwiftUI

struct AnnotationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let image: UIImage
    let photo: PhotoRecord
    let project: Project

    @State private var selectedTool: AnnotationTool = .freehand
    @State private var selectedColor: UIColor = .systemRed
    @State private var strokeWidth: CGFloat = 5
    @State private var annotations: [AnnotationElement] = []
    @State private var draftAnnotation: AnnotationElement?
    @State private var dragStartPoint: CGPoint?
    @State private var isSaving = false
    @State private var saveErrorMessage: String?

    private let colorPalette: [UIColor] = [
        .systemRed,
        .systemOrange,
        .systemYellow,
        .systemGreen,
        .systemBlue,
        .systemPink,
        .white,
        .black,
    ]

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let imageFrame = aspectFitRect(
                    for: image.size,
                    in: geometry.size
                )

                ZStack {
                    Color(uiColor: .systemBackground)
                        .ignoresSafeArea()

                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: imageFrame.width, height: imageFrame.height)
                        .position(x: imageFrame.midX, y: imageFrame.midY)

                    Canvas { context, _ in
                        for annotation in annotations {
                            draw(annotation, in: imageFrame, context: &context)
                        }

                        if let draftAnnotation {
                            draw(draftAnnotation, in: imageFrame, context: &context)
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .local)
                            .onChanged { value in
                                updateDraft(for: value, imageFrame: imageFrame)
                            }
                            .onEnded { _ in
                                commitDraft()
                            }
                    )
                }
            }
            .navigationTitle("סימון")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ביטול") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button("נקה") {
                        annotations.removeAll()
                        draftAnnotation = nil
                        dragStartPoint = nil
                    }
                    .disabled(isSaving || (annotations.isEmpty && draftAnnotation == nil))
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("שמור") {
                        Task { await saveAnnotation() }
                    }
                    .disabled(isSaving)
                }
            }
            .safeAreaInset(edge: .bottom) {
                AnnotationControlsBar(
                    selectedTool: $selectedTool,
                    selectedColor: $selectedColor,
                    strokeWidth: $strokeWidth,
                    annotationsCount: annotations.count,
                    onUndo: {
                        guard !annotations.isEmpty else { return }
                        _ = annotations.removeLast()
                    },
                    colorPalette: colorPalette
                )
            }
            .overlay {
                if isSaving {
                    ProgressView("שומר...")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .alert("שמירה נכשלה", isPresented: saveErrorBinding) {
            Button("סגור", role: .cancel) {}
        } message: {
            Text(saveErrorMessage ?? "אירעה שגיאה בשמירה")
        }
    }

    private var saveErrorBinding: Binding<Bool> {
        Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )
    }

    @MainActor
    private func saveAnnotation() async {
        isSaving = true
        defer { isSaving = false }

        do {
            if annotations.isEmpty {
                if let currentPath = photo.annotatedImagePath {
                    await ImageStorageService.shared.deleteImage(at: currentPath)
                    photo.annotatedImagePath = nil
                }
                try modelContext.save()
                await ExportCache.shared.invalidate(for: photo)
                dismiss()
                return
            }

            let compositeImage = renderComposite()
            let projectID = project.id.uuidString
            let uuid = URL(fileURLWithPath: photo.imagePath)
                .deletingPathExtension()
                .lastPathComponent

            let annotatedPath = try await ImageStorageService.shared.saveAnnotatedImage(
                compositeImage,
                projectID: projectID,
                originalUUID: uuid
            )
            photo.annotatedImagePath = annotatedPath
            try modelContext.save()
            await ExportCache.shared.invalidate(for: photo)
            dismiss()
        } catch {
            saveErrorMessage = error.localizedDescription
            print("Failed to save annotated image: \(error)")
        }
    }

    @MainActor
    private func renderComposite() -> UIImage {
        let imageSize = image.size
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = image.scale > 0 ? image.scale : 1
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: imageSize, format: format)
        return renderer.image { rendererContext in
            image.draw(in: CGRect(origin: .zero, size: imageSize))

            let destinationFrame = CGRect(origin: .zero, size: imageSize)
            for annotation in annotations {
                draw(annotation, in: destinationFrame, cgContext: rendererContext.cgContext)
            }
        }
    }

    private func updateDraft(for value: DragGesture.Value, imageFrame: CGRect) {
        guard imageFrame.width > 0, imageFrame.height > 0 else { return }

        if dragStartPoint == nil {
            guard imageFrame.contains(value.startLocation) else { return }
            dragStartPoint = normalize(point: value.startLocation, in: imageFrame)

            if selectedTool == .freehand, let start = dragStartPoint {
                draftAnnotation = AnnotationElement(
                    tool: .freehand,
                    color: selectedColor,
                    lineWidthRatio: normalizedLineWidth(in: imageFrame),
                    points: [start]
                )
            }
        }

        guard let start = dragStartPoint else { return }
        let current = normalize(point: value.location, in: imageFrame)

        switch selectedTool {
        case .freehand:
            guard var draft = draftAnnotation else { return }
            draft.points.append(current)
            draftAnnotation = draft

        case .arrow, .circle:
            draftAnnotation = AnnotationElement(
                tool: selectedTool,
                color: selectedColor,
                lineWidthRatio: normalizedLineWidth(in: imageFrame),
                points: [start, current]
            )
        }
    }

    private func commitDraft() {
        defer {
            draftAnnotation = nil
            dragStartPoint = nil
        }

        guard let draftAnnotation, draftAnnotation.isMeaningful else { return }
        annotations.append(draftAnnotation)
    }

    private func normalizedLineWidth(in frame: CGRect) -> CGFloat {
        let maxDimension = max(frame.width, frame.height)
        guard maxDimension > 0 else { return 0.008 }
        return strokeWidth / maxDimension
    }

    private func draw(_ annotation: AnnotationElement, in frame: CGRect, context: inout GraphicsContext) {
        let path = annotation.path(in: frame)
        context.stroke(
            path,
            with: .color(Color(uiColor: annotation.color)),
            style: StrokeStyle(
                lineWidth: annotation.lineWidth(in: frame),
                lineCap: .round,
                lineJoin: .round
            )
        )
    }

    private func draw(_ annotation: AnnotationElement, in frame: CGRect, cgContext: CGContext) {
        let color = annotation.color.cgColor
        let lineWidth = annotation.lineWidth(in: frame)
        cgContext.saveGState()
        cgContext.setStrokeColor(color)
        cgContext.setLineWidth(lineWidth)
        cgContext.setLineCap(.round)
        cgContext.setLineJoin(.round)

        switch annotation.tool {
        case .freehand:
            guard annotation.points.count > 1 else {
                cgContext.restoreGState()
                return
            }
            let points = annotation.points.map { denormalize(point: $0, in: frame) }
            cgContext.beginPath()
            cgContext.move(to: points[0])
            for point in points.dropFirst() {
                cgContext.addLine(to: point)
            }
            cgContext.strokePath()

        case .arrow:
            guard annotation.points.count == 2 else {
                cgContext.restoreGState()
                return
            }
            let start = denormalize(point: annotation.points[0], in: frame)
            let end = denormalize(point: annotation.points[1], in: frame)
            let arrowHeadLength = max(lineWidth * 3, min(frame.width, frame.height) * 0.025)
            let angle = atan2(end.y - start.y, end.x - start.x)
            let spread = CGFloat.pi / 7
            let left = CGPoint(
                x: end.x - arrowHeadLength * cos(angle - spread),
                y: end.y - arrowHeadLength * sin(angle - spread)
            )
            let right = CGPoint(
                x: end.x - arrowHeadLength * cos(angle + spread),
                y: end.y - arrowHeadLength * sin(angle + spread)
            )

            cgContext.beginPath()
            cgContext.move(to: start)
            cgContext.addLine(to: end)
            cgContext.strokePath()

            cgContext.beginPath()
            cgContext.move(to: end)
            cgContext.addLine(to: left)
            cgContext.move(to: end)
            cgContext.addLine(to: right)
            cgContext.strokePath()

        case .circle:
            guard annotation.points.count == 2 else {
                cgContext.restoreGState()
                return
            }
            let rect = denormalize(
                rect: CGRect.normalizedBetween(annotation.points[0], annotation.points[1]),
                in: frame
            )
            cgContext.strokeEllipse(in: rect)
        }

        cgContext.restoreGState()
    }

    private func aspectFitRect(for imageSize: CGSize, in containerSize: CGSize) -> CGRect {
        guard imageSize.width > 0,
              imageSize.height > 0,
              containerSize.width > 0,
              containerSize.height > 0 else {
            return .zero
        }

        let scale = min(
            containerSize.width / imageSize.width,
            containerSize.height / imageSize.height
        )
        let size = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )

        return CGRect(
            x: (containerSize.width - size.width) / 2,
            y: (containerSize.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
    }

    private func normalize(point: CGPoint, in frame: CGRect) -> CGPoint {
        let x = ((point.x - frame.minX) / frame.width).clamped(to: 0...1)
        let y = ((point.y - frame.minY) / frame.height).clamped(to: 0...1)
        return CGPoint(x: x, y: y)
    }

    private func denormalize(point: CGPoint, in frame: CGRect) -> CGPoint {
        CGPoint(
            x: frame.minX + (point.x * frame.width),
            y: frame.minY + (point.y * frame.height)
        )
    }

    private func denormalize(rect: CGRect, in frame: CGRect) -> CGRect {
        CGRect(
            x: frame.minX + (rect.minX * frame.width),
            y: frame.minY + (rect.minY * frame.height),
            width: rect.width * frame.width,
            height: rect.height * frame.height
        )
    }
}

private struct AnnotationControlsBar: View {
    @Binding var selectedTool: AnnotationTool
    @Binding var selectedColor: UIColor
    @Binding var strokeWidth: CGFloat
    let annotationsCount: Int
    let onUndo: () -> Void
    let colorPalette: [UIColor]

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                ForEach(AnnotationTool.allCases) { tool in
                    Button {
                        selectedTool = tool
                    } label: {
                        Label(tool.title, systemImage: tool.icon)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                selectedTool == tool
                                ? Color.accentColor.opacity(0.18)
                                : Color(uiColor: .secondarySystemBackground)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 10) {
                ForEach(colorPalette, id: \.self) { color in
                    Button {
                        selectedColor = color
                    } label: {
                        Circle()
                            .fill(Color(uiColor: color))
                            .frame(width: 26, height: 26)
                            .overlay {
                                Circle()
                                    .strokeBorder(.white.opacity(0.8), lineWidth: 1.2)
                            }
                            .overlay {
                                if selectedColor.isEqual(color) {
                                    Circle()
                                        .strokeBorder(.primary, lineWidth: 2)
                                        .padding(-4)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 8)

                Button {
                    onUndo()
                } label: {
                    Label("בטל", systemImage: "arrow.uturn.backward")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .disabled(annotationsCount == 0)
            }

            HStack(spacing: 8) {
                Image(systemName: "scribble")
                    .foregroundStyle(.secondary)
                Slider(value: $strokeWidth, in: 2...12, step: 0.5)
                Text("\(Int(strokeWidth))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 24, alignment: .leading)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
    }
}

private enum AnnotationTool: CaseIterable, Identifiable {
    case freehand
    case arrow
    case circle

    var id: String { title }

    var title: String {
        switch self {
        case .freehand: return "חופשי"
        case .arrow: return "חץ"
        case .circle: return "עיגול"
        }
    }

    var icon: String {
        switch self {
        case .freehand: return "pencil"
        case .arrow: return "arrow.up.right"
        case .circle: return "circle"
        }
    }
}

private struct AnnotationElement: Identifiable {
    let id = UUID()
    let tool: AnnotationTool
    let color: UIColor
    let lineWidthRatio: CGFloat
    var points: [CGPoint]

    var isMeaningful: Bool {
        switch tool {
        case .freehand:
            return points.count > 1
        case .arrow, .circle:
            guard points.count == 2 else { return false }
            let dx = points[1].x - points[0].x
            let dy = points[1].y - points[0].y
            return (dx * dx + dy * dy) > 0.00004
        }
    }

    func lineWidth(in frame: CGRect) -> CGFloat {
        max(1.2, lineWidthRatio * max(frame.width, frame.height))
    }

    func path(in frame: CGRect) -> Path {
        switch tool {
        case .freehand:
            return freehandPath(in: frame)
        case .arrow:
            return arrowPath(in: frame)
        case .circle:
            return circlePath(in: frame)
        }
    }

    private func freehandPath(in frame: CGRect) -> Path {
        guard let first = points.first else { return Path() }
        var path = Path()
        path.move(to: denormalize(point: first, in: frame))
        for point in points.dropFirst() {
            path.addLine(to: denormalize(point: point, in: frame))
        }
        return path
    }

    private func arrowPath(in frame: CGRect) -> Path {
        guard points.count == 2 else { return Path() }
        let start = denormalize(point: points[0], in: frame)
        let end = denormalize(point: points[1], in: frame)
        let lineWidth = lineWidth(in: frame)
        let arrowHeadLength = max(lineWidth * 3, min(frame.width, frame.height) * 0.025)
        let angle = atan2(end.y - start.y, end.x - start.x)
        let spread = CGFloat.pi / 7
        let left = CGPoint(
            x: end.x - arrowHeadLength * cos(angle - spread),
            y: end.y - arrowHeadLength * sin(angle - spread)
        )
        let right = CGPoint(
            x: end.x - arrowHeadLength * cos(angle + spread),
            y: end.y - arrowHeadLength * sin(angle + spread)
        )

        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        path.move(to: end)
        path.addLine(to: left)
        path.move(to: end)
        path.addLine(to: right)
        return path
    }

    private func circlePath(in frame: CGRect) -> Path {
        guard points.count == 2 else { return Path() }
        let rect = denormalize(
            rect: CGRect.normalizedBetween(points[0], points[1]),
            in: frame
        )
        return Path(ellipseIn: rect)
    }

    private func denormalize(point: CGPoint, in frame: CGRect) -> CGPoint {
        CGPoint(
            x: frame.minX + (point.x * frame.width),
            y: frame.minY + (point.y * frame.height)
        )
    }

    private func denormalize(rect: CGRect, in frame: CGRect) -> CGRect {
        CGRect(
            x: frame.minX + (rect.minX * frame.width),
            y: frame.minY + (rect.minY * frame.height),
            width: rect.width * frame.width,
            height: rect.height * frame.height
        )
    }
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

private extension CGRect {
    static func normalizedBetween(_ a: CGPoint, _ b: CGPoint) -> CGRect {
        let minX = min(a.x, b.x)
        let minY = min(a.y, b.y)
        let maxX = max(a.x, b.x)
        let maxY = max(a.y, b.y)
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}

import UIKit

final class PdfExporter {
    static func export(
        project: Project,
        photos: [PhotoRecord],
        options: ExportOptions,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(project.name)_\(dateString(project.date)).pdf")

        let totalPhotos = photos.count
        var processedPhotos = 0

        let pageRect = CGRect(x: 0, y: 0, width: options.pageWidth, height: options.pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { context in
            context.beginPage()
            drawCoverPage(context: context, project: project, options: options)

            var photosOnPage = 0
            var currentY = options.marginTop

            for (index, photo) in photos.enumerated() {
                if photosOnPage >= options.photosPerPage {
                    context.beginPage()
                    photosOnPage = 0
                    currentY = options.marginTop
                }

                let image = loadCompressedImage(photo: photo, quality: options.quality)
                let blockHeight = estimatedBlockHeight(for: image, options: options)

                if currentY + blockHeight > options.pageHeight - options.marginBottom {
                    context.beginPage()
                    photosOnPage = 0
                    currentY = options.marginTop
                }

                let usedHeight = drawPhotoBlock(
                    context: context,
                    photo: photo,
                    image: image,
                    index: index + 1,
                    options: options,
                    y: currentY
                )

                currentY += usedHeight + 18
                photosOnPage += 1
                processedPhotos += 1
                onProgress(Double(processedPhotos) / Double(max(totalPhotos, 1)))
            }
        }

        do {
            try data.write(to: outputURL)
        } catch {
            throw ExportError.pdfGenerationFailed
        }

        return outputURL
    }

    // MARK: - Cover Page

    private static func drawCoverPage(
        context: UIGraphicsPDFRendererContext,
        project: Project,
        options: ExportOptions
    ) {
        var y: CGFloat = options.pageHeight * 0.30

        drawRTLText(
            project.name,
            in: CGRect(x: options.marginLeft, y: y, width: options.contentWidth, height: 40),
            fontSize: 28,
            bold: true,
            alignment: .center
        )
        y += 50

        if let address = project.address, !address.isEmpty {
            drawRTLText(
                "כתובת: \(address)",
                in: CGRect(x: options.marginLeft, y: y, width: options.contentWidth, height: 24),
                fontSize: 16,
                alignment: .center
            )
            y += 30
        }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "he")
        dateFormatter.dateStyle = .long
        drawRTLText(
            "תאריך: \(dateFormatter.string(from: project.date))",
            in: CGRect(x: options.marginLeft, y: y, width: options.contentWidth, height: 24),
            fontSize: 16,
            alignment: .center
        )
        y += 30

        if let notes = project.notes, !notes.isEmpty {
            drawRTLText(
                "הערות: \(notes)",
                in: CGRect(x: options.marginLeft, y: y, width: options.contentWidth, height: 120),
                fontSize: 13,
                alignment: .right
            )
        }
    }

    // MARK: - Photo Blocks

    private static func estimatedBlockHeight(for image: UIImage?, options: ExportOptions) -> CGFloat {
        guard let image else { return 210 }
        let maxWidth = options.contentWidth
        let maxHeight: CGFloat = 300
        let scale = min(maxWidth / image.size.width, maxHeight / image.size.height, 1.0)
        let imageHeight = image.size.height * scale
        return imageHeight + 130
    }

    private static func drawPhotoBlock(
        context: UIGraphicsPDFRendererContext,
        photo: PhotoRecord,
        image: UIImage?,
        index: Int,
        options: ExportOptions,
        y: CGFloat
    ) -> CGFloat {
        var currentY = y

        drawRTLText(
            "תמונה \(index)",
            in: CGRect(x: options.marginLeft, y: currentY, width: options.contentWidth, height: 22),
            fontSize: 13,
            bold: true,
            alignment: .right
        )
        currentY += 24

        if let image {
            let maxWidth = options.contentWidth
            let maxHeight: CGFloat = 300
            let scale = min(maxWidth / image.size.width, maxHeight / image.size.height, 1.0)
            let drawWidth = image.size.width * scale
            let drawHeight = image.size.height * scale
            let imageX = options.marginLeft + (options.contentWidth - drawWidth) / 2
            let imageRect = CGRect(x: imageX, y: currentY, width: drawWidth, height: drawHeight)
            image.draw(in: imageRect)
            currentY += drawHeight + 10
        } else {
            drawRTLText(
                "לא ניתן לטעון תמונה",
                in: CGRect(x: options.marginLeft, y: currentY, width: options.contentWidth, height: 26),
                fontSize: 12,
                alignment: .center,
                color: .systemRed
            )
            currentY += 34
        }

        let text = normalizedText(photo.freeText)
        drawRTLText(
            text,
            in: CGRect(x: options.marginLeft, y: currentY, width: options.contentWidth, height: 90),
            fontSize: 12,
            alignment: .right,
            color: .darkGray
        )
        currentY += 92

        UIColor.systemGray4.setStroke()
        let separator = UIBezierPath()
        separator.move(to: CGPoint(x: options.marginLeft, y: currentY))
        separator.addLine(to: CGPoint(x: options.marginLeft + options.contentWidth, y: currentY))
        separator.lineWidth = 0.8
        separator.stroke()

        return currentY - y
    }

    // MARK: - Text Helpers

    private static func drawRTLText(
        _ text: String,
        in rect: CGRect,
        fontSize: CGFloat,
        bold: Bool = false,
        alignment: NSTextAlignment = .right,
        color: UIColor = .black
    ) {
        let font = bold ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.baseWritingDirection = .rightToLeft
        paragraphStyle.lineBreakMode = .byWordWrapping

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle,
        ]

        NSAttributedString(string: text, attributes: attributes).draw(in: rect)
    }

    // MARK: - Helpers

    private static func normalizedText(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "ללא הערה" : trimmed
    }

    private static func loadCompressedImage(photo: PhotoRecord, quality: ImageQuality) -> UIImage? {
        let imagePath = photo.displayImagePath
        let fullURL = AppConstants.imagesBaseURL.appendingPathComponent(imagePath)
        guard let data = try? Data(contentsOf: fullURL),
              let image = UIImage(data: data) else { return nil }
        return image.resized(maxWidth: quality.maxWidth)
    }

    private static func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

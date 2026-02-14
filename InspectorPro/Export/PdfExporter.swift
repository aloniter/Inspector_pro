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

        let pageRect = CGRect(x: 0, y: 0, width: options.pageWidth, height: options.pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let totalPhotos = photos.count
        var processedPhotos = 0

        let data = renderer.pdfData { context in
            context.beginPage()
            drawCoverPage(project: project, options: options)

            context.beginPage()
            var currentY = options.marginTop
            let pageBottom = options.pageHeight - options.marginBottom

            currentY += drawTableHeader(options: options, y: currentY)

            for (index, photo) in photos.enumerated() {
                let image = loadCompressedImage(photo: photo, options: options)
                let description = descriptionText(photo: photo, index: index + 1)
                let rowHeight = estimatedRowHeight(
                    for: image,
                    descriptionText: description,
                    options: options
                )

                if currentY + rowHeight > pageBottom {
                    context.beginPage()
                    currentY = options.marginTop
                    currentY += drawTableHeader(options: options, y: currentY)
                }

                drawPhotoRow(
                    image: image,
                    descriptionText: description,
                    options: options,
                    y: currentY,
                    rowHeight: rowHeight
                )

                currentY += rowHeight
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
        project: Project,
        options: ExportOptions
    ) {
        var y: CGFloat = options.pageHeight * 0.28

        drawRTLText(
            project.name,
            in: CGRect(x: options.marginLeft, y: y, width: options.contentWidth, height: 46),
            fontSize: 28,
            bold: true,
            alignment: .center
        )
        y += 56

        if let address = project.address, !address.isEmpty {
            drawRTLText(
                "כתובת: \(address)",
                in: CGRect(x: options.marginLeft, y: y, width: options.contentWidth, height: 26),
                fontSize: 16,
                alignment: .center
            )
            y += 32
        }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "he")
        dateFormatter.dateStyle = .long
        drawRTLText(
            "תאריך: \(dateFormatter.string(from: project.date))",
            in: CGRect(x: options.marginLeft, y: y, width: options.contentWidth, height: 26),
            fontSize: 16,
            alignment: .center
        )
        y += 34

        if let notes = project.notes, !notes.isEmpty {
            drawRTLText(
                "הערות: \(notes)",
                in: CGRect(x: options.marginLeft, y: y, width: options.contentWidth, height: 130),
                fontSize: 13,
                alignment: .right,
                color: .darkGray
            )
        }
    }

    // MARK: - Table

    private static func drawTableHeader(
        options: ExportOptions,
        y: CGFloat
    ) -> CGFloat {
        let tableRect = CGRect(
            x: options.marginLeft,
            y: y,
            width: options.contentWidth,
            height: options.tableHeaderHeight
        )
        let imageCellRect = CGRect(
            x: tableRect.minX,
            y: tableRect.minY,
            width: options.imageColumnWidth,
            height: tableRect.height
        )
        let textCellRect = CGRect(
            x: imageCellRect.maxX,
            y: tableRect.minY,
            width: options.textColumnWidth,
            height: tableRect.height
        )

        UIColor(red: 0.59, green: 0.72, blue: 0.84, alpha: 1).setFill()
        UIBezierPath(rect: tableRect).fill()

        UIColor.black.setStroke()
        let borderPath = UIBezierPath(rect: tableRect)
        borderPath.lineWidth = 1
        borderPath.stroke()

        let divider = UIBezierPath()
        divider.move(to: CGPoint(x: imageCellRect.maxX, y: tableRect.minY))
        divider.addLine(to: CGPoint(x: imageCellRect.maxX, y: tableRect.maxY))
        divider.lineWidth = 1
        divider.stroke()

        drawRTLText(
            "תמונה",
            in: imageCellRect.insetBy(dx: options.tableCellPadding, dy: 6),
            fontSize: 20,
            bold: true,
            alignment: .center
        )
        drawRTLText(
            "תיאור",
            in: textCellRect.insetBy(dx: options.tableCellPadding, dy: 6),
            fontSize: 20,
            bold: true,
            alignment: .center
        )

        return tableRect.height
    }

    private static func estimatedRowHeight(
        for image: UIImage?,
        descriptionText: String,
        options: ExportOptions
    ) -> CGFloat {
        let textFont = UIFont.systemFont(ofSize: 12)
        let textHeight = measureRTLTextHeight(
            descriptionText,
            width: options.textContentWidth,
            font: textFont,
            lineSpacing: 2
        )

        let textCellHeight = textHeight + (options.tableCellPadding * 2)
        let imageCellHeight: CGFloat
        if let image {
            let maxImageSize = CGSize(
                width: options.imageContentWidth,
                height: options.pageHeight * 0.45
            )
            imageCellHeight = scaledImageSize(for: image, maxSize: maxImageSize).height
                + (options.tableCellPadding * 2)
        } else {
            imageCellHeight = 90
        }

        return max(options.minimumPhotoRowHeight, textCellHeight, imageCellHeight)
    }

    private static func drawPhotoRow(
        image: UIImage?,
        descriptionText: String,
        options: ExportOptions,
        y: CGFloat,
        rowHeight: CGFloat
    ) {
        let rowRect = CGRect(
            x: options.marginLeft,
            y: y,
            width: options.contentWidth,
            height: rowHeight
        )
        let imageCellRect = CGRect(
            x: rowRect.minX,
            y: rowRect.minY,
            width: options.imageColumnWidth,
            height: rowRect.height
        )
        let textCellRect = CGRect(
            x: imageCellRect.maxX,
            y: rowRect.minY,
            width: options.textColumnWidth,
            height: rowRect.height
        )

        UIColor(white: 0.94, alpha: 1).setFill()
        UIBezierPath(rect: textCellRect).fill()

        UIColor.black.setStroke()
        let borderPath = UIBezierPath(rect: rowRect)
        borderPath.lineWidth = 1
        borderPath.stroke()

        let divider = UIBezierPath()
        divider.move(to: CGPoint(x: imageCellRect.maxX, y: rowRect.minY))
        divider.addLine(to: CGPoint(x: imageCellRect.maxX, y: rowRect.maxY))
        divider.lineWidth = 1
        divider.stroke()

        if let image {
            let maxImageSize = CGSize(
                width: options.imageContentWidth,
                height: max(rowHeight - (options.tableCellPadding * 2), 40)
            )
            let drawSize = scaledImageSize(for: image, maxSize: maxImageSize)
            let imageX = imageCellRect.minX + (imageCellRect.width - drawSize.width) / 2
            let imageY = imageCellRect.minY + (imageCellRect.height - drawSize.height) / 2
            image.draw(in: CGRect(x: imageX, y: imageY, width: drawSize.width, height: drawSize.height))
        } else {
            drawRTLText(
                "לא ניתן לטעון תמונה",
                in: imageCellRect.insetBy(dx: options.tableCellPadding, dy: options.tableCellPadding),
                fontSize: 12,
                alignment: .center,
                color: .systemRed
            )
        }

        drawRTLText(
            descriptionText,
            in: textCellRect.insetBy(dx: options.tableCellPadding, dy: options.tableCellPadding),
            fontSize: 12,
            alignment: .right,
            color: .black,
            lineSpacing: 2
        )
    }

    // MARK: - Text Helpers

    private static func drawRTLText(
        _ text: String,
        in rect: CGRect,
        fontSize: CGFloat,
        bold: Bool = false,
        alignment: NSTextAlignment = .right,
        color: UIColor = .black,
        lineSpacing: CGFloat = 0
    ) {
        let font = bold ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.baseWritingDirection = .rightToLeft
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.lineSpacing = lineSpacing

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle,
        ]

        NSAttributedString(string: text, attributes: attributes).draw(in: rect)
    }

    private static func measureRTLTextHeight(
        _ text: String,
        width: CGFloat,
        font: UIFont,
        lineSpacing: CGFloat
    ) -> CGFloat {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        paragraphStyle.baseWritingDirection = .rightToLeft
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.lineSpacing = lineSpacing

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle,
        ]

        let bounding = NSString(string: text).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        return ceil(bounding.height)
    }

    // MARK: - Helpers

    private static func descriptionText(photo: PhotoRecord, index: Int) -> String {
        let normalized = normalizedText(photo.freeText)
        let lines = normalized
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let bulletLines = (lines.isEmpty ? [normalized] : lines)
            .map { line in
                line.hasPrefix("•") ? line : "• \(line)"
            }
            .joined(separator: "\n")

        return "\(index). תיאור:\n\(bulletLines)"
    }

    private static func scaledImageSize(for image: UIImage, maxSize: CGSize) -> CGSize {
        let widthScale = maxSize.width / image.size.width
        let heightScale = maxSize.height / image.size.height
        let scale = min(widthScale, heightScale, 1.0)

        return CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
    }

    private static func normalizedText(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "ללא הערה" : trimmed
    }

    private static func loadCompressedImage(photo: PhotoRecord, options: ExportOptions) -> UIImage? {
        let imagePath = photo.displayImagePath
        let fullURL = AppConstants.imagesBaseURL.appendingPathComponent(imagePath)

        guard let imageData = try? Data(contentsOf: fullURL),
              let compressed = ImageCompressor.compressData(
                  imageData,
                  quality: options.quality,
                  maxWidthOverride: options.exportImageMaxRenderWidth,
                  maxBytes: options.exportImageMaxBytes
              ),
              let image = UIImage(data: compressed) else {
            return nil
        }

        return image
    }

    private static func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

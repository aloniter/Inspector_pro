import UIKit

final class PdfExporter {
    static func export(
        project: Project,
        photos: [PhotoRecord],
        options: ExportOptions,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        let outputURL = outputFileURL(projectName: project.name, date: project.date, fileExtension: "pdf")

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
                let rowHeight = options.targetPhotoRowHeight

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
            try data.write(to: outputURL, options: .atomic)
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
                AppStrings.format("כתובת: %@", address),
                in: CGRect(x: options.marginLeft, y: y, width: options.contentWidth, height: 26),
                fontSize: 16,
                alignment: .center
            )
            y += 32
        }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = AppLanguage.current.locale
        dateFormatter.dateStyle = .long
        drawRTLText(
            AppStrings.format("תאריך: %@", dateFormatter.string(from: project.date)),
            in: CGRect(x: options.marginLeft, y: y, width: options.contentWidth, height: 26),
            fontSize: 16,
            alignment: .center
        )
        y += 34

        if let notes = project.notes, !notes.isEmpty {
            drawRTLText(
                AppStrings.format("הערות: %@", notes),
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
            AppStrings.text("תמונה"),
            in: imageCellRect.insetBy(dx: options.tableCellPadding, dy: 6),
            fontSize: 20,
            bold: true,
            alignment: .center
        )
        drawRTLText(
            AppStrings.text("תיאור"),
            in: textCellRect.insetBy(dx: options.tableCellPadding, dy: 6),
            fontSize: 20,
            bold: true,
            alignment: .center
        )

        return tableRect.height
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
                height: min(
                    max(rowHeight - (options.tableCellPadding * 2), 40),
                    options.targetPhotoImageHeight
                )
            )
            let drawSize = scaledImageSize(for: image, maxSize: maxImageSize)
            let imageX = imageCellRect.minX + (imageCellRect.width - drawSize.width) / 2
            let imageY = imageCellRect.minY + (imageCellRect.height - drawSize.height) / 2
            image.draw(in: CGRect(x: imageX, y: imageY, width: drawSize.width, height: drawSize.height))
        } else {
            drawRTLText(
                AppStrings.text("לא ניתן לטעון תמונה"),
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
        let isHebrew = AppLanguage.current == .hebrew
        let resolvedAlignment: NSTextAlignment = (!isHebrew && alignment == .right) ? .left : alignment

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = resolvedAlignment
        paragraphStyle.baseWritingDirection = isHebrew ? .rightToLeft : .leftToRight
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.lineSpacing = lineSpacing

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle,
        ]

        NSAttributedString(string: text, attributes: attributes).draw(in: rect)
    }

    // MARK: - Helpers

    private static func descriptionText(photo: PhotoRecord, index: Int) -> String {
        let lines = photo.freeText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let bulletLines = lines
            .map { line in
                line.hasPrefix("•") ? line : "• \(line)"
            }

        guard !bulletLines.isEmpty else { return "\(index)." }
        return "\(index).\n\(bulletLines.joined(separator: "\n"))"
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

    private static func outputFileURL(projectName: String, date: Date, fileExtension: String) -> URL {
        let baseName = "\(safeFilename(projectName))_\(dateString(date))"
        let outputDir = AppConstants.exportsURL
        FileManagerService.shared.ensureDirectoryExists(at: outputDir)

        var outputURL = outputDir.appendingPathComponent("\(baseName).\(fileExtension)")
        var suffix = 1
        while FileManager.default.fileExists(atPath: outputURL.path) {
            outputURL = outputDir.appendingPathComponent("\(baseName)_\(suffix).\(fileExtension)")
            suffix += 1
        }
        return outputURL
    }

    private static func safeFilename(_ value: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        let cleaned = value
            .components(separatedBy: invalid)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "Report" : cleaned
    }
}

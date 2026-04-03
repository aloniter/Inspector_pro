import UIKit

final class PdfExporter {
    static func export(
        project: Project,
        photos: [PhotoRecord],
        options: ExportOptions,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        let outputURL = outputFileURL(projectName: project.name, date: project.date, fileExtension: "pdf")

        // Load the logo from the bundled template for header branding.
        let templateAssets = try TemplateExtractor.extract()
        let logoImage = UIImage(data: templateAssets.logoImageData)

        let pageRect = CGRect(x: 0, y: 0, width: options.pageWidth, height: options.pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let totalPhotos = photos.count
        var processedPhotos = 0

        let data = renderer.pdfData { context in
            context.beginPage()
            drawBranding(logoImage: logoImage, options: options)
            drawCoverPage(project: project, options: options)

            context.beginPage()
            drawBranding(logoImage: logoImage, options: options)
            var currentY = options.effectiveTopMargin
            let pageBottom = options.pageHeight - options.effectiveBottomMargin

            currentY += drawTableHeader(options: options, y: currentY)

            for photo in photos {
                let image = loadCompressedImage(photo: photo, options: options)
                let descriptionLines = descriptionLines(photo: photo)
                let rowHeight = options.targetPhotoRowHeight

                if currentY + rowHeight > pageBottom {
                    context.beginPage()
                    drawBranding(logoImage: logoImage, options: options)
                    currentY = options.effectiveTopMargin
                    currentY += drawTableHeader(options: options, y: currentY)
                }

                drawPhotoRow(
                    image: image,
                    descriptionLines: descriptionLines,
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
        let mutedLabelColor = UIColor(red: 0x64 / 255.0, green: 0x74 / 255.0, blue: 0x8B / 255.0, alpha: 1)
        let accentBlue = UIColor(red: 0x1D / 255.0, green: 0x4E / 255.0, blue: 0xD8 / 255.0, alpha: 1)
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
            y += drawCoverFieldSection(
                label: AppStrings.text("כתובת"),
                value: address,
                originY: y,
                width: options.contentWidth,
                x: options.marginLeft,
                labelFontSize: 10,
                valueFontSize: 10,
                valueBold: true,
                labelColor: mutedLabelColor
            )
        }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = AppLanguage.current.locale
        dateFormatter.dateStyle = .long
        y += drawCoverFieldSection(
            label: AppStrings.text("תאריך"),
            value: dateFormatter.string(from: project.date),
            originY: y,
            width: options.contentWidth,
            x: options.marginLeft,
            labelFontSize: 10,
            valueFontSize: 10,
            valueBold: true,
            labelColor: mutedLabelColor
        )

        if let attendees = normalizedOptionalCoverText(project.attendees) {
            y += drawCoverFieldSection(
                label: ExportTextFormatter.rtlHeadingText("\(AppStrings.text("נוכחים")):"),
                value: attendees,
                originY: y,
                width: options.contentWidth,
                x: options.marginLeft,
                labelFontSize: 14,
                valueFontSize: 12,
                valueBold: false,
                labelColor: accentBlue,
                valueColor: accentBlue
            )
        }

        if let notes = project.notes, !notes.isEmpty {
            drawRTLText(
                ExportTextFormatter.coverPageFieldText(
                    label: AppStrings.text("הערות"),
                    value: notes
                ),
                in: CGRect(x: options.marginLeft, y: y, width: options.contentWidth, height: 130),
                fontSize: 13,
                alignment: .right,
                color: .darkGray
            )
        }
    }

    private static func normalizedOptionalCoverText(_ value: String?) -> String? {
        guard let value else { return nil }

        let lines = value
            .split(separator: "\n", omittingEmptySubsequences: false)
            .compactMap { segment -> String? in
                let trimmedLine = String(segment).trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmedLine.isEmpty ? nil : trimmedLine
            }

        guard !lines.isEmpty else { return nil }
        return lines.joined(separator: "\n")
    }

    private static func drawCoverFieldSection(
        label: String,
        value: String,
        originY: CGFloat,
        width: CGFloat,
        x: CGFloat,
        labelFontSize: CGFloat,
        valueFontSize: CGFloat,
        valueBold: Bool,
        labelColor: UIColor,
        valueColor: UIColor = .black,
        alignment: NSTextAlignment = .center
    ) -> CGFloat {
        let valueLines = value.components(separatedBy: "\n")
        let labelHeight = labelFontSize + 8
        let valueLineHeight = valueFontSize + 8
        let valuesHeight = max(CGFloat(valueLines.count) * valueLineHeight, valueLineHeight)

        drawRTLText(
            label,
            in: CGRect(x: x, y: originY, width: width, height: labelHeight),
            fontSize: labelFontSize,
            bold: false,
            alignment: alignment,
            color: labelColor
        )

        drawRTLText(
            value,
            in: CGRect(x: x, y: originY + labelHeight, width: width, height: valuesHeight),
            fontSize: valueFontSize,
            bold: valueBold,
            alignment: alignment,
            color: valueColor,
            lineSpacing: 4
        )

        return labelHeight + valuesHeight + 12
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
        descriptionLines: [ExportTextFormatter.DescriptionLine],
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
            let pad = ExportImageConstants.imageCellPaddingPoints
            let maxW = options.imageColumnWidth - pad * 2
            let maxH = min(max(rowHeight - pad * 2, 40), options.targetPhotoImageHeight)

            // Cover scaling: fill the target area, cropping overflow from center.
            let widthScale = maxW / image.size.width
            let heightScale = maxH / image.size.height
            let coverScale = max(widthScale, heightScale)
            let drawW = image.size.width * coverScale
            let drawH = image.size.height * coverScale

            // Center the (possibly oversized) image in the clip rect.
            let clipRect = CGRect(
                x: imageCellRect.minX + (imageCellRect.width - maxW) / 2,
                y: imageCellRect.minY + (imageCellRect.height - maxH) / 2,
                width: maxW,
                height: maxH
            )
            let drawX = clipRect.midX - drawW / 2
            let drawY = clipRect.midY - drawH / 2

            if let ctx = UIGraphicsGetCurrentContext() {
                ctx.saveGState()
                ctx.clip(to: clipRect)
                image.draw(in: CGRect(x: drawX, y: drawY, width: drawW, height: drawH))
                ctx.restoreGState()
            }
        } else {
            drawRTLText(
                AppStrings.text("לא ניתן לטעון תמונה"),
                in: imageCellRect.insetBy(dx: options.tableCellPadding, dy: options.tableCellPadding),
                fontSize: 12,
                alignment: .center,
                color: .systemRed
            )
        }

        drawDescriptionText(
            descriptionLines,
            in: textCellRect.insetBy(dx: options.tableCellPadding, dy: options.tableCellPadding),
            fontSize: 12,
            color: .black,
            lineSpacing: 2
        )
    }

    // MARK: - Header / Footer Branding

    private static func drawBranding(
        logoImage: UIImage?,
        options: ExportOptions
    ) {
        drawHeader(logoImage: logoImage, options: options)
        drawFooter(options: options)
    }

    private static func drawHeader(
        logoImage: UIImage?,
        options: ExportOptions
    ) {
        guard let logo = logoImage else { return }

        let maxDimension: CGFloat = 75
        let scale = min(maxDimension / logo.size.width, maxDimension / logo.size.height)
        let drawSize = CGSize(width: logo.size.width * scale, height: logo.size.height * scale)

        // Left-aligned logo.
        let x = options.marginLeft
        let y = options.brandedHeaderDistancePt

        logo.draw(in: CGRect(x: x, y: y, width: drawSize.width, height: drawSize.height))
    }

    private static func drawFooter(options: ExportOptions) {
        let footerX = options.marginLeft
        let footerWidth = options.pageWidth - options.marginLeft - options.marginRight
        let footerStartY = options.pageHeight - options.brandedBottomMarginPt + options.brandedFooterDistancePt

        // Top border line matching template footer style.
        UIColor.black.setStroke()
        let borderPath = UIBezierPath()
        borderPath.move(to: CGPoint(x: footerX, y: footerStartY))
        borderPath.addLine(to: CGPoint(x: footerX + footerWidth, y: footerStartY))
        borderPath.lineWidth = 0.5
        borderPath.stroke()

        let darkBlue = UIColor(red: 0, green: 0x20 / 255.0, blue: 0x60 / 255.0, alpha: 1) // #002060
        let lineHeight: CGFloat = 11
        var y = footerStartY + 3

        drawRTLText(
            "כפר ויתקין, ת\"ד 635 מיקוד 4020000",
            in: CGRect(x: footerX, y: y, width: footerWidth, height: lineHeight),
            fontSize: 8,
            alignment: .center,
            color: darkBlue
        )
        y += lineHeight

        drawRTLText(
            "אבישי 054-6222577 דוא\"ל iter@iter.co.il",
            in: CGRect(x: footerX, y: y, width: footerWidth, height: lineHeight),
            fontSize: 8,
            alignment: .center,
            color: darkBlue
        )
        y += lineHeight

        drawRTLText(
            "דפנה 054-6222575 משרד 09-8665885",
            in: CGRect(x: footerX, y: y, width: footerWidth, height: lineHeight),
            fontSize: 8,
            alignment: .center,
            color: darkBlue
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

    private static func drawDescriptionText(
        _ lines: [ExportTextFormatter.DescriptionLine],
        in rect: CGRect,
        fontSize: CGFloat,
        color: UIColor = .black,
        lineSpacing: CGFloat = 0
    ) {
        guard !lines.isEmpty else { return }

        let isHebrew = AppLanguage.current == .hebrew
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = isHebrew ? .right : .left
        paragraphStyle.baseWritingDirection = isHebrew ? .rightToLeft : .leftToRight
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.lineSpacing = lineSpacing

        let attributedText = NSMutableAttributedString()

        for (index, line) in lines.enumerated() {
            let font = line.isBold ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraphStyle,
            ]

            attributedText.append(NSAttributedString(string: line.exportText, attributes: attributes))

            if index < lines.count - 1 {
                attributedText.append(NSAttributedString(string: "\n", attributes: attributes))
            }
        }

        attributedText.draw(in: rect)
    }

    // MARK: - Helpers

    private static func descriptionLines(photo: PhotoRecord) -> [ExportTextFormatter.DescriptionLine] {
        ExportTextFormatter.descriptionLines(from: photo.freeText)
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

import UIKit

final class PdfExporter {
    static func export(
        project: Project,
        photos: [PhotoRecord],
        options: ExportOptions,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        let outputURL = outputFileURL(projectName: project.name, date: project.date, fileExtension: "pdf")
        let branding = ResolvedExportBranding.resolve(for: project)

        let logoImage = branding.logoImageData.flatMap(UIImage.init(data:))

        let pageRect = CGRect(x: 0, y: 0, width: options.pageWidth, height: options.pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let totalPhotos = photos.count
        var processedPhotos = 0

        let data = renderer.pdfData { context in
            context.beginPage()
            drawBranding(logoImage: logoImage, branding: branding, options: options)
            drawCoverPage(project: project, branding: branding, options: options)

            context.beginPage()
            drawBranding(logoImage: logoImage, branding: branding, options: options)
            var currentY = options.effectiveTopMargin
            let pageBottom = options.pageHeight - options.effectiveBottomMargin

            currentY += drawTableHeader(options: options, y: currentY)

            for (index, photo) in photos.enumerated() {
                let image = loadCompressedImage(photo: photo, options: options)
                let itemNumber = project.showsNumberedImagesInReport ? index + 1 : nil
                let descriptionLines = descriptionLines(
                    photo: photo,
                    itemNumber: itemNumber,
                    showsNumberedImagesInReport: project.showsNumberedImagesInReport
                )
                let rowHeight = options.targetPhotoRowHeight

                if currentY + rowHeight > pageBottom {
                    context.beginPage()
                    drawBranding(logoImage: logoImage, branding: branding, options: options)
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
        branding: ResolvedExportBranding,
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
            y += drawCoverFieldSection(
                label: AppStrings.text("כתובת"),
                value: address,
                originY: y,
                width: options.contentWidth,
                x: options.marginLeft,
                labelFontSize: 10,
                valueFontSize: 10,
                valueBold: true,
                labelColor: branding.coverMutedLabelColor
            )
        }

        y += drawCoverFieldSection(
            label: AppStrings.text("תאריך"),
            value: ExportTextFormatter.reportCoverDateString(from: project.date),
            originY: y,
            width: options.contentWidth,
            x: options.marginLeft,
            labelFontSize: 10,
            valueFontSize: 10,
            valueBold: true,
            labelColor: branding.coverMutedLabelColor
        )

        if let attendees = numberedAttendeeLines(project.attendees) {
            y += drawAttendeesCoverFieldSection(
                label: ExportTextFormatter.rtlHeadingText("\(AppStrings.text("נוכחים")):"),
                attendees: attendees,
                originY: y,
                width: options.contentWidth,
                x: options.marginLeft,
                labelColor: branding.attendeesAccentColor,
                valueColor: branding.attendeesAccentColor
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

    private static func numberedAttendeeLines(_ value: String?) -> [String]? {
        guard let normalizedValue = normalizedOptionalCoverText(value) else { return nil }

        let attendees = ExportTextFormatter.numberedAttendeeLines(from: normalizedValue)
        return attendees.isEmpty ? nil : attendees
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

    private static func drawAttendeesCoverFieldSection(
        label: String,
        attendees: [String],
        originY: CGFloat,
        width: CGFloat,
        x: CGFloat,
        labelColor: UIColor,
        valueColor: UIColor
    ) -> CGFloat {
        let labelFontSize: CGFloat = 12
        let attendeeFontSize: CGFloat = 12
        let labelHeight = labelFontSize + 8
        let attendeeLineHeight = attendeeFontSize + 10
        let attendeesHeight = max(CGFloat(attendees.count) * attendeeLineHeight, attendeeLineHeight)

        drawRTLText(
            label,
            in: CGRect(x: x, y: originY, width: width, height: labelHeight),
            fontSize: labelFontSize,
            bold: true,
            alignment: .center,
            color: labelColor
        )

        drawRTLText(
            attendees.joined(separator: "\n"),
            in: CGRect(x: x, y: originY + labelHeight, width: width, height: attendeesHeight),
            fontSize: attendeeFontSize,
            bold: false,
            alignment: .center,
            color: valueColor,
            lineSpacing: 4
        )

        return labelHeight + attendeesHeight + 12
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
        branding: ResolvedExportBranding,
        options: ExportOptions
    ) {
        drawHeader(logoImage: logoImage, options: options)
        drawFooter(branding: branding, options: options)
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

    private static func drawFooter(branding: ResolvedExportBranding, options: ExportOptions) {
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

        let lineHeight: CGFloat = 11
        var y = footerStartY + 3

        drawRTLText(
            branding.footerAddressLine,
            in: CGRect(x: footerX, y: y, width: footerWidth, height: lineHeight),
            fontSize: 8,
            alignment: .center,
            color: branding.footerTextColor
        )
        y += lineHeight

        drawFooterDisplayRuns(
            branding.primaryFooterDisplayRuns,
            in: CGRect(x: footerX, y: y, width: footerWidth, height: lineHeight),
            fontSize: 8,
            color: branding.footerTextColor
        )
        y += lineHeight

        drawFooterDisplayRuns(
            branding.secondaryFooterDisplayRuns,
            in: CGRect(x: footerX, y: y, width: footerWidth, height: lineHeight),
            fontSize: 8,
            color: branding.footerTextColor
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

    private static func drawFooterDisplayRuns(
        _ runs: [BrandingFooterFormatter.FooterRun],
        in rect: CGRect,
        fontSize: CGFloat,
        color: UIColor
    ) {
        guard !runs.isEmpty else { return }
        let font = UIFont.systemFont(ofSize: fontSize)

        let spaceWidth = (" " as NSString).size(withAttributes: [.font: font]).width
        let tokenWidths = runs.map { run in
            (run.text as NSString).size(withAttributes: [.font: font]).width
        }
        let totalWidth = tokenWidths.reduce(0, +) + (CGFloat(max(runs.count - 1, 0)) * spaceWidth)
        var currentX = rect.minX + max((rect.width - totalWidth) / 2, 0)
        let baselineY = rect.minY + max((rect.height - font.lineHeight) / 2, 0)

        for (index, run) in runs.enumerated() {
            let tokenRect = CGRect(
                x: currentX,
                y: baselineY,
                width: tokenWidths[index],
                height: font.lineHeight
            )

            drawRTLText(
                run.text,
                in: tokenRect,
                fontSize: fontSize,
                alignment: .left,
                color: color
            )

            currentX += tokenWidths[index]
            if index < runs.count - 1 {
                currentX += spaceWidth
            }
        }
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
            for run in line.runs {
                let font = run.isBold ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color,
                    .paragraphStyle: paragraphStyle,
                ]

                attributedText.append(NSAttributedString(string: run.text, attributes: attributes))
            }

            if index < lines.count - 1 {
                attributedText.append(NSAttributedString(
                    string: "\n",
                    attributes: [
                        .font: UIFont.systemFont(ofSize: fontSize),
                        .foregroundColor: color,
                        .paragraphStyle: paragraphStyle,
                    ]
                ))
            }
        }

        attributedText.draw(in: rect)
    }

    // MARK: - Helpers

    private static func descriptionLines(
        photo: PhotoRecord,
        itemNumber: Int?,
        showsNumberedImagesInReport: Bool
    ) -> [ExportTextFormatter.DescriptionLine] {
        ExportTextFormatter.descriptionLines(
            from: photo.freeText,
            itemNumber: itemNumber,
            showsNumberedImagesInReport: showsNumberedImagesInReport
        )
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

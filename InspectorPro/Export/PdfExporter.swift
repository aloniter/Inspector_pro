import UIKit

final class PdfExporter {
    static func export(
        report: Report,
        photos: [PhotoRecord],
        options: ExportOptions,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        let outputURL = outputFileURL(projectName: report.name, date: report.date, fileExtension: "pdf")
        let branding = ResolvedExportBranding.resolve(for: report)

        let logoImage = branding.logoImageData.flatMap(UIImage.init(data:))

        // Prepare final flattened export images once so PDF and DOCX share the same
        // source selection, compression, orientation normalization, and dimensions.
        // Yield between images so queued MainActor UI updates can animate progress.
        var exportImages: [FlattenedExportImage] = []
        for (index, photo) in photos.enumerated() {
            let image = try FlattenedExportImageRenderer.render(photo: photo, options: options)
            exportImages.append(image)
            onProgress(Double(index + 1) / Double(max(photos.count, 1)) * 0.9)
            await Task.yield()
        }

        let pageRect = CGRect(x: 0, y: 0, width: options.pageWidth, height: options.pageHeight)
        let rendererFormat = UIGraphicsPDFRendererFormat()
        rendererFormat.documentInfo = [
            kCGPDFContextCreator as String: AppBranding.createdByText,
        ]
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: rendererFormat)

        let data = renderer.pdfData { context in
            context.beginPage()
            drawBranding(logoImage: logoImage, branding: branding, options: options)
            drawCoverPage(report: report, branding: branding, options: options)

            context.beginPage()
            drawBranding(logoImage: logoImage, branding: branding, options: options)
            var currentY = options.effectiveTopMargin
            let pageBottom = options.pageHeight - options.effectiveBottomMargin
            let rowHeightBudget = options.targetPhotoRowHeight

            currentY += drawTableHeader(options: options, y: currentY)

            for (index, photo) in photos.enumerated() {
                let exportImage = exportImages[index]
                let itemNumber = report.showsNumberedImagesInReport ? index + 1 : nil
                let descriptionLines = descriptionLines(
                    photo: photo,
                    itemNumber: itemNumber,
                    showsNumberedImagesInReport: report.showsNumberedImagesInReport
                )
                let rowHeight = min(
                    photoRowHeight(
                        image: exportImage.image,
                        descriptionLines: descriptionLines,
                        options: options
                    ),
                    rowHeightBudget
                )

                if currentY + rowHeight > pageBottom {
                    context.beginPage()
                    drawBranding(logoImage: logoImage, branding: branding, options: options)
                    currentY = options.effectiveTopMargin
                    currentY += drawTableHeader(options: options, y: currentY)
                }

                drawPhotoRow(
                    image: exportImage.image,
                    descriptionLines: descriptionLines,
                    options: options,
                    y: currentY,
                    rowHeight: rowHeight
                )

                currentY += rowHeight
            }
        }

        do {
            try data.write(to: outputURL, options: .atomic)
        } catch {
            throw ExportError.pdfGenerationFailed
        }

        onProgress(1.0)
        return outputURL
    }

    // MARK: - Cover Page

    private static func drawCoverPage(
        report: Report,
        branding: ResolvedExportBranding,
        options: ExportOptions
    ) {
        var y: CGFloat = options.pageHeight * 0.28

        drawRTLText(
            report.name,
            in: CGRect(x: options.marginLeft, y: y, width: options.contentWidth, height: 46),
            fontSize: 28,
            bold: true,
            alignment: .center
        )
        y += 56

        if let address = report.reportAddress, !address.isEmpty {
            y += drawCoverFieldSection(
                label: AppStrings.text("כתובת"),
                value: address,
                originY: y,
                width: options.contentWidth,
                x: options.marginLeft,
                labelFontSize: ExportTypography.Cover.metadataPointSize,
                valueFontSize: ExportTypography.Cover.metadataPointSize,
                valueBold: false,
                labelColor: branding.coverMutedLabelColor
            )
        }

        y += drawCoverFieldSection(
            label: AppStrings.text("תאריך"),
            value: ExportTextFormatter.reportCoverDateString(from: report.date),
            originY: y,
            width: options.contentWidth,
            x: options.marginLeft,
            labelFontSize: ExportTypography.Cover.metadataPointSize,
            valueFontSize: ExportTypography.Cover.metadataPointSize,
            valueBold: false,
            labelColor: branding.coverMutedLabelColor
        )

        y += drawCoverSummaryLine(
            text: ExportTextFormatter.rtlHeadingText(
                "\(AppStrings.text("מספר ליקויים פתוחים")): \(report.openDefectCount)"
            ),
            originY: y,
            width: options.contentWidth,
            x: options.marginLeft
        )

        if let attendees = numberedAttendees(report.attendees) {
            y += drawAttendeesCoverFieldSection(
                label: ExportTextFormatter.rtlHeadingText("\(AppStrings.text("נוכחים")):"),
                attendees: attendees,
                originY: y,
                width: options.contentWidth,
                x: options.marginLeft,
                labelColor: branding.coverMutedLabelColor,
                valueColor: .black
            )
        }

        if let notes = normalizedOptionalCoverText(report.notes) {
            _ = drawCoverFieldSection(
                label: AppStrings.text("הערות"),
                value: notes,
                originY: y,
                width: options.contentWidth,
                x: options.marginLeft,
                labelFontSize: ExportTypography.Cover.metadataPointSize,
                valueFontSize: ExportTypography.Cover.notesContentPointSize,
                valueBold: false,
                labelColor: branding.coverMutedLabelColor,
                valueColor: .darkGray,
                alignment: .center
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

    private static func numberedAttendees(_ value: String?) -> [ExportTextFormatter.NumberedAttendee]? {
        guard let normalizedValue = normalizedOptionalCoverText(value) else { return nil }

        let attendees = ExportTextFormatter.numberedAttendees(from: normalizedValue)
        return attendees.isEmpty ? nil : attendees
    }

    /// Red, non-bold open-defects cover line, e.g. "מספר ליקויים פתוחים: 109".
    private static let coverDefectColor = UIColor(
        red: 211.0 / 255.0, green: 47.0 / 255.0, blue: 47.0 / 255.0, alpha: 1
    )
    private static func drawCoverSummaryLine(
        text: String,
        originY: CGFloat,
        width: CGFloat,
        x: CGFloat
    ) -> CGFloat {
        let fontSize = ExportTypography.Cover.metadataPointSize
        let lineHeight = fontSize + 8

        drawRTLText(
            text,
            in: CGRect(x: x, y: originY, width: width, height: lineHeight),
            fontSize: fontSize,
            bold: false,
            alignment: .center,
            color: coverDefectColor
        )

        return lineHeight + 12
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
            bold: true,
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

    /// Draws the "נוכחים:" heading and the attendees list as a compact,
    /// centered two-column block: the name column on the visual (RTL) left and
    /// the narrow "N." marker column on the visual right. The marker is drawn
    /// with a right-to-left base direction so bidi renders it as digit-flush-
    /// right / period-toward-the-name, exactly matching the DOCX table cell.
    /// All markers share one fixed column and all names share another, so a
    /// name's length never shifts the numbers.
    private static func drawAttendeesCoverFieldSection(
        label: String,
        attendees: [ExportTextFormatter.NumberedAttendee],
        originY: CGFloat,
        width: CGFloat,
        x: CGFloat,
        labelColor: UIColor,
        valueColor: UIColor
    ) -> CGFloat {
        let labelFontSize = ExportTypography.Cover.attendeesHeadingPointSize
        let attendeeFontSize = ExportTypography.Cover.attendeeItemPointSize
        let labelHeight = labelFontSize + 8
        let rowHeight = attendeeFontSize + 10
        let listHeight = max(CGFloat(attendees.count) * rowHeight, rowHeight)
        let font = UIFont.systemFont(ofSize: attendeeFontSize)
        let isRTL = AppLanguage.current == .hebrew

        drawRTLText(
            label,
            in: CGRect(x: x, y: originY, width: width, height: labelHeight),
            fontSize: labelFontSize,
            bold: true,
            alignment: .center,
            color: labelColor
        )

        let columns = AttendeeCoverLayout.columns(for: attendees, font: font, maxTotalWidth: width)
        let blockX = x + max((width - columns.totalWidth) / 2, 0)
        let listTop = originY + labelHeight

        // Name column on the RTL left, marker column on the RTL right (mirrored
        // for LTR locales).
        let nameX = isRTL ? blockX : blockX + columns.markerColumnWidth
        let markerX = isRTL ? blockX + columns.nameColumnWidth : blockX
        let writingDirection: NSWritingDirection = isRTL ? .rightToLeft : .leftToRight
        let alignment: NSTextAlignment = isRTL ? .right : .left

        for (index, attendee) in attendees.enumerated() {
            let rowY = listTop + CGFloat(index) * rowHeight

            drawPlainText(
                attendee.markerText,
                in: CGRect(x: markerX, y: rowY, width: columns.markerColumnWidth, height: rowHeight),
                font: font,
                baseWritingDirection: writingDirection,
                alignment: alignment,
                color: valueColor
            )
            drawPlainText(
                attendee.name,
                in: CGRect(x: nameX, y: rowY, width: columns.nameColumnWidth, height: rowHeight),
                font: font,
                baseWritingDirection: writingDirection,
                alignment: alignment,
                color: valueColor
            )
        }

        return labelHeight + listHeight + 12
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
        image: UIImage,
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

        let pad = ExportImageConstants.imageCellPaddingPoints
        let imageContentRect = imageCellRect.insetBy(dx: pad, dy: pad)
        image.draw(in: imageContentRect)

        drawDescriptionText(
            descriptionLines,
            in: textCellRect.insetBy(dx: options.tableCellPadding, dy: options.tableCellPadding),
            fontSize: 12,
            color: .black,
            lineSpacing: 2
        )
    }

    private static func photoRowHeight(
        image: UIImage,
        descriptionLines: [ExportTextFormatter.DescriptionLine],
        options: ExportOptions
    ) -> CGFloat {
        let imageDrivenHeight = options.targetPhotoRowHeight

        let textHeight = descriptionTextHeight(
            descriptionLines,
            width: options.textColumnWidth - (options.tableCellPadding * 2),
            fontSize: 12,
            lineSpacing: 2
        )
        let textDrivenHeight = textHeight + (options.tableCellPadding * 2)

        return max(
            ceil(imageDrivenHeight),
            ceil(textDrivenHeight),
            options.minimumPhotoRowHeight
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
        guard branding.hasVisibleFooterContent else { return }

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

        if !branding.footerAddressLine.isEmpty {
            drawRTLText(
                branding.footerAddressLine,
                in: CGRect(x: footerX, y: y, width: footerWidth, height: lineHeight),
                fontSize: 8,
                alignment: .center,
                color: branding.footerTextColor
            )
            y += lineHeight
        }

        if !branding.primaryFooterDisplayRuns.isEmpty {
            drawFooterDisplayRuns(
                branding.primaryFooterDisplayRuns,
                in: CGRect(x: footerX, y: y, width: footerWidth, height: lineHeight),
                fontSize: 8,
                color: branding.footerTextColor
            )
            y += lineHeight
        }

        if !branding.secondaryFooterDisplayRuns.isEmpty {
            drawFooterDisplayRuns(
                branding.secondaryFooterDisplayRuns,
                in: CGRect(x: footerX, y: y, width: footerWidth, height: lineHeight),
                fontSize: 8,
                color: branding.footerTextColor
            )
        }
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

    private static func drawPlainText(
        _ text: String,
        in rect: CGRect,
        font: UIFont,
        baseWritingDirection: NSWritingDirection,
        alignment: NSTextAlignment,
        color: UIColor
    ) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.baseWritingDirection = baseWritingDirection
        paragraphStyle.lineBreakMode = .byWordWrapping

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle,
        ]

        NSAttributedString(string: text, attributes: attributes).draw(in: rect)
    }

    private static func textWidth(_ text: String, font: UIFont) -> CGFloat {
        ceil((text as NSString).size(withAttributes: [.font: font]).width)
    }

    private static func drawFooterDisplayRuns(
        _ runs: [BrandingFooterFormatter.FooterRun],
        in rect: CGRect,
        fontSize: CGFloat,
        color: UIColor
    ) {
        guard !runs.isEmpty else { return }
        let font = UIFont.systemFont(ofSize: fontSize)

        let spaceWidth = max((" " as NSString).size(withAttributes: [.font: font]).width, 4)
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

        let attributedText = descriptionAttributedString(
            lines,
            fontSize: fontSize,
            color: color,
            lineSpacing: lineSpacing
        )

        attributedText.draw(in: rect)
    }

    private static func descriptionTextHeight(
        _ lines: [ExportTextFormatter.DescriptionLine],
        width: CGFloat,
        fontSize: CGFloat,
        lineSpacing: CGFloat
    ) -> CGFloat {
        guard !lines.isEmpty, width > 0 else { return 0 }

        let attributedText = descriptionAttributedString(
            lines,
            fontSize: fontSize,
            color: .black,
            lineSpacing: lineSpacing
        )
        let size = attributedText.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).size
        return ceil(size.height)
    }

    private static func descriptionAttributedString(
        _ lines: [ExportTextFormatter.DescriptionLine],
        fontSize: CGFloat,
        color: UIColor,
        lineSpacing: CGFloat
    ) -> NSAttributedString {
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

        return attributedText
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

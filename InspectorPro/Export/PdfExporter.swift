import UIKit

final class PdfExporter {
    static func export(
        project: Project,
        findings: [Finding],
        options: ExportOptions,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(project.title)_\(dateString(project.date)).pdf")

        // Count total photos for progress
        let totalPhotos = findings.flatMap(\.photos).count
        var processedPhotos = 0

        let pageRect = CGRect(x: 0, y: 0, width: options.pageWidth, height: options.pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { context in
            // Cover page
            context.beginPage()
            drawCoverPage(context: context, project: project, options: options)

            var findingsOnPage = 0
            var currentY = options.marginTop

            for finding in findings {
                // Start new page if needed (after every 2 findings)
                if findingsOnPage >= options.findingsPerPage {
                    context.beginPage()
                    currentY = options.marginTop
                    findingsOnPage = 0
                }

                // If this is the first finding on page and we're not at the top
                if findingsOnPage == 0 && currentY != options.marginTop {
                    context.beginPage()
                    currentY = options.marginTop
                }

                // Draw finding table
                let sortedPhotos = finding.sortedPhotos
                let mainPhoto = sortedPhotos.first

                // Load main image
                var mainImage: UIImage?
                if let mainPhoto = mainPhoto {
                    mainImage = loadCompressedImage(photo: mainPhoto, quality: options.quality)
                    processedPhotos += 1
                    onProgress(Double(processedPhotos) / Double(max(totalPhotos, 1)))
                }

                let tableHeight = drawFindingTable(
                    context: context,
                    finding: finding,
                    mainImage: mainImage,
                    options: options,
                    y: currentY
                )
                currentY += tableHeight + 10

                findingsOnPage += 1

                // Draw additional images (below the table)
                if sortedPhotos.count > 1 {
                    for (photoIndex, photo) in sortedPhotos.dropFirst().enumerated() {
                        autoreleasepool {
                            guard let image = loadCompressedImage(photo: photo, quality: options.quality) else { return }

                            let maxImageWidth = options.contentWidth
                            let scale = min(maxImageWidth / image.size.width, 1.0)
                            let imageWidth = image.size.width * scale
                            let imageHeight = image.size.height * scale
                            let captionHeight: CGFloat = 20

                            let totalBlockHeight = imageHeight + captionHeight + 10

                            // Check if fits on current page
                            if currentY + totalBlockHeight > options.pageHeight - options.marginBottom {
                                context.beginPage()
                                currentY = options.marginTop
                            }

                            // Draw image centered
                            let imageX = options.marginLeft + (options.contentWidth - imageWidth) / 2
                            let imageRect = CGRect(x: imageX, y: currentY, width: imageWidth, height: imageHeight)
                            image.draw(in: imageRect)

                            // Draw caption
                            let captionY = currentY + imageHeight + 2
                            let caption = "ממצא \(finding.number) – תמונה \(photoIndex + 2) מתוך \(sortedPhotos.count)"
                            drawRTLText(
                                caption,
                                in: CGRect(x: options.marginLeft, y: captionY, width: options.contentWidth, height: captionHeight),
                                fontSize: 10,
                                alignment: .center,
                                color: .gray
                            )

                            currentY += totalBlockHeight + 10
                        }
                        processedPhotos += 1
                        onProgress(Double(processedPhotos) / Double(max(totalPhotos, 1)))
                    }
                }

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
        var y: CGFloat = options.pageHeight * 0.3

        // Title
        drawRTLText(
            project.title,
            in: CGRect(x: options.marginLeft, y: y, width: options.contentWidth, height: 40),
            fontSize: 28,
            bold: true,
            alignment: .center
        )
        y += 50

        // Address
        if !project.address.isEmpty {
            drawRTLText(
                "כתובת: \(project.address)",
                in: CGRect(x: options.marginLeft, y: y, width: options.contentWidth, height: 24),
                fontSize: 16,
                alignment: .center
            )
            y += 30
        }

        // Date
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

        // Inspector
        if !project.inspectorName.isEmpty {
            drawRTLText(
                "בודק: \(project.inspectorName)",
                in: CGRect(x: options.marginLeft, y: y, width: options.contentWidth, height: 24),
                fontSize: 16,
                alignment: .center
            )
        }
    }

    // MARK: - Finding Table

    /// Draws a 2-column finding table. Returns the total height used.
    private static func drawFindingTable(
        context: UIGraphicsPDFRendererContext,
        finding: Finding,
        mainImage: UIImage?,
        options: ExportOptions,
        y: CGFloat
    ) -> CGFloat {
        let tableWidth = options.contentWidth
        let imageColWidth = tableWidth * options.imageColumnRatio
        let textColWidth = tableWidth * options.textColumnRatio
        let padding: CGFloat = 6

        // Calculate image dimensions (fit within column)
        var imageHeight: CGFloat = 200
        if let image = mainImage {
            let maxImageWidth = imageColWidth - padding * 2
            let scale = min(maxImageWidth / image.size.width, 1.0)
            imageHeight = image.size.height * scale
        }

        // Calculate text block height
        let textLines = buildFindingTextLines(finding)
        let textBlockHeight = CGFloat(textLines.count) * 18 + padding * 2
        let rowHeight = max(imageHeight + padding * 2, textBlockHeight)

        // Draw table border
        let tableRect = CGRect(x: options.marginLeft, y: y, width: tableWidth, height: rowHeight)
        UIColor.lightGray.setStroke()
        let path = UIBezierPath(rect: tableRect)
        path.lineWidth = 0.5
        path.stroke()

        // Draw column divider
        // RTL: image is on the LEFT, text on the RIGHT
        let dividerX = options.marginLeft + imageColWidth
        let dividerPath = UIBezierPath()
        dividerPath.move(to: CGPoint(x: dividerX, y: y))
        dividerPath.addLine(to: CGPoint(x: dividerX, y: y + rowHeight))
        dividerPath.lineWidth = 0.5
        dividerPath.stroke()

        // Draw image in left column
        if let image = mainImage {
            let maxImageWidth = imageColWidth - padding * 2
            let scale = min(maxImageWidth / image.size.width, 1.0)
            let drawWidth = image.size.width * scale
            let drawHeight = image.size.height * scale
            let imageX = options.marginLeft + padding + (maxImageWidth - drawWidth) / 2
            let imageY = y + padding
            image.draw(in: CGRect(x: imageX, y: imageY, width: drawWidth, height: drawHeight))
        }

        // Draw text in right column (RTL)
        var textY = y + padding
        let textX = dividerX + padding
        let textWidth = textColWidth - padding * 2

        for line in textLines {
            drawRTLText(
                line.text,
                in: CGRect(x: textX, y: textY, width: textWidth, height: 16),
                fontSize: line.fontSize,
                bold: line.bold,
                alignment: .right,
                color: line.color
            )
            textY += 18
        }

        return rowHeight
    }

    // MARK: - Text Helpers

    private struct TextLine {
        let text: String
        let fontSize: CGFloat
        let bold: Bool
        let color: UIColor

        init(_ text: String, fontSize: CGFloat = 11, bold: Bool = false, color: UIColor = .black) {
            self.text = text
            self.fontSize = fontSize
            self.bold = bold
            self.color = color
        }
    }

    private static func buildFindingTextLines(_ finding: Finding) -> [TextLine] {
        var lines: [TextLine] = []

        lines.append(TextLine("\(finding.number). חדר: \(finding.room)", fontSize: 12, bold: true))
        lines.append(TextLine(finding.title, fontSize: 12, bold: true))

        if !finding.findingDescription.isEmpty {
            lines.append(TextLine("• \(finding.findingDescription)"))
        }
        if !finding.recommendation.isEmpty {
            lines.append(TextLine("• \(finding.recommendation)"))
        }
        lines.append(TextLine("• חומרה: \(finding.severity.hebrewLabel)", color: severityUIColor(finding.severity)))

        return lines
    }

    private static func severityUIColor(_ severity: Severity) -> UIColor {
        switch severity {
        case .low: return .systemGreen
        case .medium: return .systemOrange
        case .high: return .systemRed
        }
    }

    private static func drawRTLText(
        _ text: String,
        in rect: CGRect,
        fontSize: CGFloat,
        bold: Bool = false,
        alignment: NSTextAlignment = .right,
        color: UIColor = .black
    ) {
        let font = bold
            ? UIFont.boldSystemFont(ofSize: fontSize)
            : UIFont.systemFont(ofSize: fontSize)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.baseWritingDirection = .rightToLeft
        paragraphStyle.lineBreakMode = .byTruncatingTail

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle,
        ]

        let attrString = NSAttributedString(string: text, attributes: attributes)
        attrString.draw(in: rect)
    }

    // MARK: - Helpers

    private static func loadCompressedImage(photo: Photo, quality: ImageQuality) -> UIImage? {
        let imagePath = photo.exportImagePath
        let fullURL = AppConstants.imagesBaseURL.appendingPathComponent(imagePath)
        guard let data = try? Data(contentsOf: fullURL),
              let image = UIImage(data: data) else { return nil }
        let resized = image.resized(maxWidth: quality.maxWidth)
        return resized
    }

    private static func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

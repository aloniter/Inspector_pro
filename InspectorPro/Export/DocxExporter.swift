import Foundation
import UIKit
import ZIPFoundation

final class DocxExporter {
    static func export(
        project: Project,
        findings: [Finding],
        options: ExportOptions,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory
            .appendingPathComponent("docx_export_\(UUID().uuidString)")
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer { try? fm.removeItem(at: tempDir) }

        // Create DOCX directory structure
        let wordDir = tempDir.appendingPathComponent("word")
        let relsDir = tempDir.appendingPathComponent("_rels")
        let wordRelsDir = wordDir.appendingPathComponent("_rels")
        let mediaDir = wordDir.appendingPathComponent("media")

        for dir in [wordDir, relsDir, wordRelsDir, mediaDir] {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        // Count total photos for progress
        let totalPhotos = findings.flatMap(\.photos).count
        var processedPhotos = 0
        var imageRelId = 10  // Start relationship IDs at rId10 to avoid conflicts
        var imageId = 1
        var imageRelationships: [String] = []
        var findingsXML = ""

        var findingsOnPage = 0

        for (findingIndex, finding) in findings.enumerated() {
            let sortedPhotos = finding.sortedPhotos

            // Main image
            var mainImageRelIdStr = ""
            var mainWidthEMU = 0
            var mainHeightEMU = 0

            if let mainPhoto = sortedPhotos.first {
                let result = try await processImage(
                    photo: mainPhoto,
                    quality: options.quality,
                    mediaDir: mediaDir,
                    relId: imageRelId,
                    maxWidthEMU: options.imageColumnWidthEMU - 100000 // padding
                )
                mainImageRelIdStr = "rId\(imageRelId)"
                mainWidthEMU = result.widthEMU
                mainHeightEMU = result.heightEMU
                imageRelationships.append(
                    """
                    <Relationship Id="rId\(imageRelId)" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/\(result.filename)"/>
                    """
                )
                imageRelId += 1
                processedPhotos += 1
                onProgress(Double(processedPhotos) / Double(max(totalPhotos, 1)))
            }

            // Build finding table
            if !mainImageRelIdStr.isEmpty {
                findingsXML += OpenXMLBuilder.buildFindingTable(
                    finding: finding,
                    mainImageRelId: mainImageRelIdStr,
                    imageWidthEMU: mainWidthEMU,
                    imageHeightEMU: mainHeightEMU,
                    imageId: imageId,
                    options: options
                )
                imageId += 1
            } else {
                // Finding with no photos - just text
                findingsXML += OpenXMLBuilder.rtlParagraph(
                    text: "\(finding.number). \(finding.title)",
                    bold: true,
                    fontSize: 24
                )
                if !finding.findingDescription.isEmpty {
                    findingsXML += OpenXMLBuilder.rtlParagraph(text: "• \(finding.findingDescription)")
                }
                if !finding.recommendation.isEmpty {
                    findingsXML += OpenXMLBuilder.rtlParagraph(text: "• \(finding.recommendation)")
                }
            }

            findingsOnPage += 1

            // Additional images
            if sortedPhotos.count > 1 {
                findingsXML += OpenXMLBuilder.buildSpacing()

                for (photoIndex, photo) in sortedPhotos.dropFirst().enumerated() {
                    let result = try await processImage(
                        photo: photo,
                        quality: options.quality,
                        mediaDir: mediaDir,
                        relId: imageRelId,
                        maxWidthEMU: options.contentWidthEMU
                    )

                    let caption = "ממצא \(finding.number) – תמונה \(photoIndex + 2) מתוך \(sortedPhotos.count)"

                    findingsXML += OpenXMLBuilder.buildAdditionalImage(
                        relId: "rId\(imageRelId)",
                        widthEMU: result.widthEMU,
                        heightEMU: result.heightEMU,
                        imageId: imageId,
                        caption: caption
                    )

                    imageRelationships.append(
                        """
                        <Relationship Id="rId\(imageRelId)" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/\(result.filename)"/>
                        """
                    )

                    imageRelId += 1
                    imageId += 1
                    processedPhotos += 1
                    onProgress(Double(processedPhotos) / Double(max(totalPhotos, 1)))
                }
            }

            // Page break after every 2 finding tables
            if findingsOnPage >= options.findingsPerPage && findingIndex < findings.count - 1 {
                findingsXML += OpenXMLBuilder.buildPageBreak()
                findingsOnPage = 0
            }
        }

        // Build document.xml with replaced placeholders
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "he")
        dateFormatter.dateStyle = .long

        var documentXML = DocxTemplateBuilder.documentXML()
        documentXML = documentXML.replacingOccurrences(of: "{{PROJECT_TITLE}}", with: OpenXMLBuilder.escapeXML(project.title))
        documentXML = documentXML.replacingOccurrences(of: "{{ADDRESS}}", with: OpenXMLBuilder.escapeXML(project.address))
        documentXML = documentXML.replacingOccurrences(of: "{{DATE}}", with: OpenXMLBuilder.escapeXML(dateFormatter.string(from: project.date)))
        documentXML = documentXML.replacingOccurrences(of: "{{INSPECTOR}}", with: OpenXMLBuilder.escapeXML(project.inspectorName))
        documentXML = documentXML.replacingOccurrences(of: "{{FINDINGS_BLOCK}}", with: findingsXML)

        // Write all XML files (using DocxTemplateBuilder as single source)
        try DocxTemplateBuilder.contentTypesXML().write(to: tempDir.appendingPathComponent("[Content_Types].xml"), atomically: true, encoding: .utf8)
        try DocxTemplateBuilder.rootRelsXML().write(to: relsDir.appendingPathComponent(".rels"), atomically: true, encoding: .utf8)
        try documentXML.write(to: wordDir.appendingPathComponent("document.xml"), atomically: true, encoding: .utf8)
        try DocxTemplateBuilder.documentRelsXML(imageRelationships: imageRelationships).write(to: wordRelsDir.appendingPathComponent("document.xml.rels"), atomically: true, encoding: .utf8)
        try DocxTemplateBuilder.stylesXML().write(to: wordDir.appendingPathComponent("styles.xml"), atomically: true, encoding: .utf8)
        try DocxTemplateBuilder.settingsXML().write(to: wordDir.appendingPathComponent("settings.xml"), atomically: true, encoding: .utf8)

        // Zip to .docx
        let outputURL = fm.temporaryDirectory
            .appendingPathComponent("\(project.title)_\(dateString(project.date)).docx")

        // Remove existing file if any
        try? fm.removeItem(at: outputURL)

        try fm.zipItem(at: tempDir, to: outputURL, shouldKeepParent: false)

        return outputURL
    }

    // MARK: - Image Processing

    private struct ImageResult {
        let filename: String
        let widthEMU: Int
        let heightEMU: Int
    }

    private static func processImage(
        photo: Photo,
        quality: ImageQuality,
        mediaDir: URL,
        relId: Int,
        maxWidthEMU: Int
    ) async throws -> ImageResult {
        // Load and compress image
        guard let imageData = await ExportCache.shared.compressedImageData(
            for: photo,
            quality: quality
        ) else {
            throw ExportError.imageLoadFailed(photo.exportImagePath)
        }

        // Get image dimensions
        guard let image = UIImage(data: imageData) else {
            throw ExportError.imageLoadFailed(photo.exportImagePath)
        }

        // Calculate EMU dimensions (1 inch = 914400 EMU, 1 point = 12700 EMU)
        // Assume 96 DPI for screen images
        let pixelToEMU = 914400.0 / 96.0
        var widthEMU = Int(image.size.width * pixelToEMU)
        var heightEMU = Int(image.size.height * pixelToEMU)

        // Scale to fit max width
        if widthEMU > maxWidthEMU {
            let scale = Double(maxWidthEMU) / Double(widthEMU)
            widthEMU = maxWidthEMU
            heightEMU = Int(Double(heightEMU) * scale)
        }

        // Save to media directory
        let filename = "image\(relId).jpg"
        let imageURL = mediaDir.appendingPathComponent(filename)
        try imageData.write(to: imageURL)

        return ImageResult(filename: filename, widthEMU: widthEMU, heightEMU: heightEMU)
    }

    // XML templates are provided by DocxTemplateBuilder (single source of truth)

    // MARK: - Helpers

    private static func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

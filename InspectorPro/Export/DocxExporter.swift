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

        var documentXML = buildDocumentXML()
        documentXML = documentXML.replacingOccurrences(of: "{{PROJECT_TITLE}}", with: OpenXMLBuilder.escapeXML(project.title))
        documentXML = documentXML.replacingOccurrences(of: "{{ADDRESS}}", with: OpenXMLBuilder.escapeXML(project.address))
        documentXML = documentXML.replacingOccurrences(of: "{{DATE}}", with: OpenXMLBuilder.escapeXML(dateFormatter.string(from: project.date)))
        documentXML = documentXML.replacingOccurrences(of: "{{INSPECTOR}}", with: OpenXMLBuilder.escapeXML(project.inspectorName))
        documentXML = documentXML.replacingOccurrences(of: "{{FINDINGS_BLOCK}}", with: findingsXML)

        // Write all XML files
        try buildContentTypesXML().write(to: tempDir.appendingPathComponent("[Content_Types].xml"), atomically: true, encoding: .utf8)
        try buildRootRelsXML().write(to: relsDir.appendingPathComponent(".rels"), atomically: true, encoding: .utf8)
        try documentXML.write(to: wordDir.appendingPathComponent("document.xml"), atomically: true, encoding: .utf8)
        try buildDocumentRelsXML(imageRelationships: imageRelationships).write(to: wordRelsDir.appendingPathComponent("document.xml.rels"), atomically: true, encoding: .utf8)
        try buildStylesXML().write(to: wordDir.appendingPathComponent("styles.xml"), atomically: true, encoding: .utf8)
        try buildSettingsXML().write(to: wordDir.appendingPathComponent("settings.xml"), atomically: true, encoding: .utf8)

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

    // MARK: - XML Templates

    private static func buildDocumentXML() -> String {
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
                    xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
                    xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
                    xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
                    xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
          <w:body>
            <w:p>
              <w:pPr><w:bidi/><w:jc w:val="center"/></w:pPr>
              <w:r>
                <w:rPr><w:b/><w:bCs/><w:rtl/><w:sz w:val="48"/><w:szCs w:val="48"/><w:rFonts w:cs="Arial"/></w:rPr>
                <w:t>{{PROJECT_TITLE}}</w:t>
              </w:r>
            </w:p>
            <w:p>
              <w:pPr><w:bidi/><w:jc w:val="center"/><w:spacing w:after="100"/></w:pPr>
              <w:r>
                <w:rPr><w:rtl/><w:sz w:val="24"/><w:szCs w:val="24"/><w:rFonts w:cs="Arial"/></w:rPr>
                <w:t xml:space="preserve">כתובת: {{ADDRESS}}</w:t>
              </w:r>
            </w:p>
            <w:p>
              <w:pPr><w:bidi/><w:jc w:val="center"/><w:spacing w:after="100"/></w:pPr>
              <w:r>
                <w:rPr><w:rtl/><w:sz w:val="24"/><w:szCs w:val="24"/><w:rFonts w:cs="Arial"/></w:rPr>
                <w:t xml:space="preserve">תאריך: {{DATE}}</w:t>
              </w:r>
            </w:p>
            <w:p>
              <w:pPr><w:bidi/><w:jc w:val="center"/><w:spacing w:after="100"/></w:pPr>
              <w:r>
                <w:rPr><w:rtl/><w:sz w:val="24"/><w:szCs w:val="24"/><w:rFonts w:cs="Arial"/></w:rPr>
                <w:t xml:space="preserve">בודק: {{INSPECTOR}}</w:t>
              </w:r>
            </w:p>
            <w:p><w:r><w:br w:type="page"/></w:r></w:p>
            {{FINDINGS_BLOCK}}
          </w:body>
        </w:document>
        """
    }

    private static func buildContentTypesXML() -> String {
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
          <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
          <Default Extension="xml" ContentType="application/xml"/>
          <Default Extension="jpeg" ContentType="image/jpeg"/>
          <Default Extension="jpg" ContentType="image/jpeg"/>
          <Default Extension="png" ContentType="image/png"/>
          <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
          <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
          <Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/>
        </Types>
        """
    }

    private static func buildRootRelsXML() -> String {
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
        </Relationships>
        """
    }

    private static func buildDocumentRelsXML(imageRelationships: [String]) -> String {
        let imageRels = imageRelationships.joined(separator: "\n  ")
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
          <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/>
          \(imageRels)
        </Relationships>
        """
    }

    private static func buildStylesXML() -> String {
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
          <w:docDefaults>
            <w:rPrDefault>
              <w:rPr>
                <w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:cs="Arial"/>
                <w:sz w:val="20"/>
                <w:szCs w:val="20"/>
                <w:lang w:bidi="he-IL"/>
              </w:rPr>
            </w:rPrDefault>
            <w:pPrDefault>
              <w:pPr>
                <w:bidi/>
                <w:spacing w:after="40" w:line="276" w:lineRule="auto"/>
              </w:pPr>
            </w:pPrDefault>
          </w:docDefaults>
          <w:style w:type="paragraph" w:styleId="Normal" w:default="1">
            <w:name w:val="Normal"/>
            <w:pPr><w:bidi/></w:pPr>
            <w:rPr><w:rtl/></w:rPr>
          </w:style>
        </w:styles>
        """
    }

    private static func buildSettingsXML() -> String {
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
          <w:bidi/>
          <w:defaultTabStop w:val="720"/>
        </w:settings>
        """
    }

    // MARK: - Helpers

    private static func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

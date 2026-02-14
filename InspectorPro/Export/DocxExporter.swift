import Foundation
import UIKit
import ZIPFoundation

final class DocxExporter {
    static func export(
        project: Project,
        photos: [PhotoRecord],
        options: ExportOptions,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory
            .appendingPathComponent("docx_export_\(UUID().uuidString)")
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer { try? fm.removeItem(at: tempDir) }

        let wordDir = tempDir.appendingPathComponent("word")
        let relsDir = tempDir.appendingPathComponent("_rels")
        let wordRelsDir = wordDir.appendingPathComponent("_rels")
        let mediaDir = wordDir.appendingPathComponent("media")

        for dir in [wordDir, relsDir, wordRelsDir, mediaDir] {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        let totalPhotos = photos.count
        var processedPhotos = 0
        var imageRelId = 10
        var imageId = 1
        var imageRelationships: [String] = []
        var photosXML = ""

        for (index, photo) in photos.enumerated() {
            let result = try await processImage(
                photo: photo,
                quality: options.quality,
                mediaDir: mediaDir,
                relId: imageRelId,
                maxWidthEMU: options.contentWidthEMU
            )

            imageRelationships.append(
                """
                <Relationship Id="rId\(imageRelId)" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/\(result.filename)"/>
                """
            )

            photosXML += OpenXMLBuilder.buildPhotoBlock(
                photoNumber: index + 1,
                freeText: photo.freeText,
                imageRelId: "rId\(imageRelId)",
                imageWidthEMU: result.widthEMU,
                imageHeightEMU: result.heightEMU,
                imageId: imageId
            )

            if (index + 1) % options.photosPerPage == 0 && index < photos.count - 1 {
                photosXML += OpenXMLBuilder.buildPageBreak()
            }

            imageRelId += 1
            imageId += 1
            processedPhotos += 1
            onProgress(Double(processedPhotos) / Double(max(totalPhotos, 1)))
        }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "he")
        dateFormatter.dateStyle = .long

        let address = normalizedText(project.address)
        let notes = normalizedText(project.notes)

        var documentXML = DocxTemplateBuilder.documentXML()
        documentXML = documentXML.replacingOccurrences(of: "{{PROJECT_TITLE}}", with: OpenXMLBuilder.escapeXML(project.name))
        documentXML = documentXML.replacingOccurrences(of: "{{ADDRESS}}", with: OpenXMLBuilder.escapeXML(address))
        documentXML = documentXML.replacingOccurrences(of: "{{DATE}}", with: OpenXMLBuilder.escapeXML(dateFormatter.string(from: project.date)))
        documentXML = documentXML.replacingOccurrences(of: "{{NOTES}}", with: OpenXMLBuilder.escapeXML(notes))
        documentXML = documentXML.replacingOccurrences(of: "{{PHOTOS_BLOCK}}", with: photosXML)

        try DocxTemplateBuilder.contentTypesXML().write(to: tempDir.appendingPathComponent("[Content_Types].xml"), atomically: true, encoding: .utf8)
        try DocxTemplateBuilder.rootRelsXML().write(to: relsDir.appendingPathComponent(".rels"), atomically: true, encoding: .utf8)
        try documentXML.write(to: wordDir.appendingPathComponent("document.xml"), atomically: true, encoding: .utf8)
        try DocxTemplateBuilder.documentRelsXML(imageRelationships: imageRelationships).write(to: wordRelsDir.appendingPathComponent("document.xml.rels"), atomically: true, encoding: .utf8)
        try DocxTemplateBuilder.stylesXML().write(to: wordDir.appendingPathComponent("styles.xml"), atomically: true, encoding: .utf8)
        try DocxTemplateBuilder.settingsXML().write(to: wordDir.appendingPathComponent("settings.xml"), atomically: true, encoding: .utf8)

        let outputURL = fm.temporaryDirectory
            .appendingPathComponent("\(project.name)_\(dateString(project.date)).docx")

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
        photo: PhotoRecord,
        quality: ImageQuality,
        mediaDir: URL,
        relId: Int,
        maxWidthEMU: Int
    ) async throws -> ImageResult {
        guard let imageData = await ExportCache.shared.compressedImageData(
            for: photo,
            quality: quality
        ) else {
            throw ExportError.imageLoadFailed(photo.displayImagePath)
        }

        guard let image = UIImage(data: imageData) else {
            throw ExportError.imageLoadFailed(photo.displayImagePath)
        }

        let pixelToEMU = 914400.0 / 96.0
        var widthEMU = Int(image.size.width * pixelToEMU)
        var heightEMU = Int(image.size.height * pixelToEMU)

        if widthEMU > maxWidthEMU {
            let scale = Double(maxWidthEMU) / Double(widthEMU)
            widthEMU = maxWidthEMU
            heightEMU = Int(Double(heightEMU) * scale)
        }

        let filename = "image\(relId).jpg"
        let imageURL = mediaDir.appendingPathComponent(filename)
        try imageData.write(to: imageURL)

        return ImageResult(filename: filename, widthEMU: widthEMU, heightEMU: heightEMU)
    }

    private static func normalizedText(_ value: String?) -> String {
        guard let value else { return "—" }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "—" : trimmed
    }

    private static func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

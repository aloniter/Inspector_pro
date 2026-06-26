import Foundation
import UIKit
import ZIPFoundation

final class DocxExporter {
    static func export(
        report: Report,
        photos: [PhotoRecord],
        options: ExportOptions,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        try await export(
            report: report,
            photos: photos,
            options: options,
            branding: ResolvedExportBranding.resolve(for: report),
            onProgress: onProgress
        )
    }

    static func export(
        report: Report,
        photos: [PhotoRecord],
        options: ExportOptions,
        branding: ResolvedExportBranding,
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
        let docPropsDir = tempDir.appendingPathComponent("docProps")

        for dir in [wordDir, relsDir, wordRelsDir, mediaDir, docPropsDir] {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        #if DEBUG
        print("[DocxExport] mode=\(options.quality.rawValue) photos=\(photos.count) perImageBudget=\(options.exportImageMaxBytes)B maxRenderWidth=\(Int(options.exportImageMaxRenderWidth))px")
        #endif

        var logoWidthEMU = 952500
        var logoHeightEMU = 952500

        if let logoImageData = branding.logoImageData {
            let compressedLogo = compressLogo(logoImageData)
            try compressedLogo.write(to: mediaDir.appendingPathComponent("image1.jpeg"))
            if let logoImage = UIImage(data: compressedLogo) {
                let size = logoExtentEMU(for: logoImage)
                logoWidthEMU = size.width
                logoHeightEMU = size.height
            }
            #if DEBUG
            print("[DocxExport] logo raw=\(logoImageData.count)B → compressed=\(compressedLogo.count)B")
            #endif
        }

        let includesLogo = branding.logoImageData != nil
        try DocxTemplateBuilder.headerXML(
            includesLogo: includesLogo,
            logoWidthEMU: logoWidthEMU,
            logoHeightEMU: logoHeightEMU
        ).write(
            to: wordDir.appendingPathComponent("header1.xml"),
            atomically: true,
            encoding: .utf8
        )
        try DocxTemplateBuilder.footerXML(branding: branding).write(to: wordDir.appendingPathComponent("footer1.xml"), atomically: true, encoding: .utf8)
        try DocxTemplateBuilder.headerRelsXML(includesLogo: includesLogo).write(
            to: wordRelsDir.appendingPathComponent("header1.xml.rels"),
            atomically: true,
            encoding: .utf8
        )

        let totalPhotos = photos.count
        var processedPhotos = 0
        var imageRelId = 10
        var imageId = 1
        var imageRelationships: [String] = []
        var photoRowsXML = ""
        #if DEBUG
        var totalImagePayloadBytes = 0
        #endif

        for (index, photo) in photos.enumerated() {
            let itemNumber = report.showsNumberedImagesInReport ? index + 1 : nil

            let result = try processImage(
                photo: photo,
                options: options,
                mediaDir: mediaDir,
                relId: imageRelId
            )
            #if DEBUG
            totalImagePayloadBytes += result.compressedBytes
            if index < 3 || index == totalPhotos - 1 {
                print("[DocxExport] photo[\(index)] compressed=\(result.compressedBytes)B out=\(result.widthEMU / 9144)×\(result.heightEMU / 9144)pt")
            }
            #endif

            imageRelationships.append(
                """
                <Relationship Id="rId\(imageRelId)" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/\(result.filename)"/>
                """
            )

            photoRowsXML += OpenXMLBuilder.buildPhotoRow(
                freeText: photo.freeText,
                imageRelId: "rId\(imageRelId)",
                imageWidthEMU: result.widthEMU,
                imageHeightEMU: result.heightEMU,
                imageId: imageId,
                imageCrop: result.crop,
                itemNumber: itemNumber,
                showsNumberedImagesInReport: report.showsNumberedImagesInReport,
                imageColumnWidthTwips: options.imageColumnWidthTwips,
                textColumnWidthTwips: options.textColumnWidthTwips
            )

            imageRelId += 1
            imageId += 1
            processedPhotos += 1
            onProgress(Double(processedPhotos) / Double(max(totalPhotos, 1)))
        }

        let photosContentXML = OpenXMLBuilder.buildPhotosTable(
            rowsXML: photoRowsXML,
            tableWidthTwips: options.contentWidthTwips,
            imageColumnWidthTwips: options.imageColumnWidthTwips,
            textColumnWidthTwips: options.textColumnWidthTwips
        )

        let address = normalizedText(report.reportAddress)
        let attendees = normalizedOptionalText(report.attendees)
        let notes = normalizedOptionalText(report.notes)
        let date = ExportTextFormatter.reportCoverDateString(from: report.date)
        var documentXML = DocxTemplateBuilder.documentXML(options: options)
        documentXML = documentXML.replacingOccurrences(of: "{{PROJECT_TITLE}}", with: OpenXMLBuilder.escapeXML(report.name))
        documentXML = documentXML.replacingOccurrences(
            of: "{{COVER_DETAILS}}",
            with: DocxTemplateBuilder.coverDetailsXML(
                address: address,
                date: date,
                defectCount: report.openDefectCount,
                attendees: attendees,
                notes: notes
            )
        )
        documentXML = documentXML.replacingOccurrences(of: "{{PHOTOS_TABLE}}", with: photosContentXML)

        try DocxTemplateBuilder.contentTypesXML().write(to: tempDir.appendingPathComponent("[Content_Types].xml"), atomically: true, encoding: .utf8)
        try DocxTemplateBuilder.rootRelsXML().write(to: relsDir.appendingPathComponent(".rels"), atomically: true, encoding: .utf8)
        try DocxTemplateBuilder.corePropertiesXML().write(to: docPropsDir.appendingPathComponent("core.xml"), atomically: true, encoding: .utf8)
        try DocxTemplateBuilder.appPropertiesXML().write(to: docPropsDir.appendingPathComponent("app.xml"), atomically: true, encoding: .utf8)
        try documentXML.write(to: wordDir.appendingPathComponent("document.xml"), atomically: true, encoding: .utf8)
        try DocxTemplateBuilder.documentRelsXML(imageRelationships: imageRelationships).write(to: wordRelsDir.appendingPathComponent("document.xml.rels"), atomically: true, encoding: .utf8)
        try DocxTemplateBuilder.stylesXML().write(to: wordDir.appendingPathComponent("styles.xml"), atomically: true, encoding: .utf8)
        try DocxTemplateBuilder.numberingXML().write(to: wordDir.appendingPathComponent("numbering.xml"), atomically: true, encoding: .utf8)
        try DocxTemplateBuilder.settingsXML().write(to: wordDir.appendingPathComponent("settings.xml"), atomically: true, encoding: .utf8)
        try DocxTemplateBuilder.webSettingsXML().write(to: wordDir.appendingPathComponent("webSettings.xml"), atomically: true, encoding: .utf8)
        try DocxTemplateBuilder.footnotesXML().write(to: wordDir.appendingPathComponent("footnotes.xml"), atomically: true, encoding: .utf8)
        try DocxTemplateBuilder.endnotesXML().write(to: wordDir.appendingPathComponent("endnotes.xml"), atomically: true, encoding: .utf8)
        try DocxTemplateBuilder.fontTableXML().write(to: wordDir.appendingPathComponent("fontTable.xml"), atomically: true, encoding: .utf8)

        let outputURL = outputFileURL(
            projectName: report.name,
            date: report.date,
            fileExtension: "docx",
            fileManager: fm
        )

        #if DEBUG
        print("[DocxExport] totalImagePayload=\(totalImagePayloadBytes / 1024)KB estimatedDocxSize≈\((totalImagePayloadBytes + 200_000) / 1024)KB")
        #endif

        try? fm.removeItem(at: outputURL)
        try fm.zipItem(at: tempDir, to: outputURL, shouldKeepParent: false)
        try? fm.setAttributes([.posixPermissions: 0o644], ofItemAtPath: outputURL.path)

        #if DEBUG
        let finalBytes = (try? fm.attributesOfItem(atPath: outputURL.path)[.size] as? Int) ?? 0
        print("[DocxExport] finalDocxSize=\(finalBytes / 1024)KB (\(String(format: "%.1f", Double(finalBytes) / 1_000_000))MB)")
        #endif

        return outputURL
    }

    // MARK: - Image Processing

    private struct ImageResult {
        let filename: String
        let widthEMU: Int
        let heightEMU: Int
        let crop: OpenXMLBuilder.ImageCrop
        let compressedBytes: Int
    }

    private static func compressLogo(_ data: Data) -> Data {
        guard let image = UIImage(data: data) else { return data }
        let maxLogoWidth: CGFloat = 500
        let resized = image.resized(maxWidth: maxLogoWidth)
        return resized.jpegDataStripped(quality: 0.75) ?? data
    }

    private static func logoExtentEMU(for image: UIImage) -> (width: Int, height: Int) {
        let maxDimensionEMU = 952500.0 // 75pt
        let width = max(Double(image.size.width), 1)
        let height = max(Double(image.size.height), 1)
        let scale = min(maxDimensionEMU / width, maxDimensionEMU / height)
        return (Int(width * scale), Int(height * scale))
    }

    private static func processImage(
        photo: PhotoRecord,
        options: ExportOptions,
        mediaDir: URL,
        relId: Int
    ) throws -> ImageResult {
        let exportImage = try FlattenedExportImageRenderer.render(photo: photo, options: options)
        let displaySize = (
            width: options.imageContentWidthEMU,
            height: options.targetPhotoImageHeightEMU
        )
        let crop = OpenXMLBuilder.ImageCrop.none

        let filename = "image\(relId).jpg"
        let imageURL = mediaDir.appendingPathComponent(filename)
        try exportImage.data.write(to: imageURL)

        return ImageResult(
            filename: filename,
            widthEMU: displaySize.width,
            heightEMU: displaySize.height,
            crop: crop,
            compressedBytes: exportImage.data.count
        )
    }

    private static func normalizedText(_ value: String?) -> String {
        guard let value else { return "—" }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "—" : trimmed
    }

    private static func normalizedOptionalText(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func outputFileURL(
        projectName: String,
        date: Date,
        fileExtension: String,
        fileManager: FileManager
    ) -> URL {
        let baseName = "\(safeFilename(projectName))_\(dateString(date))"
        let outputDir = AppConstants.exportsURL
        FileManagerService.shared.ensureDirectoryExists(at: outputDir)

        var suffix = 0
        while true {
            let candidateName = suffix == 0 ? baseName : "\(baseName)_\(suffix)"
            let outputURL = outputDir.appendingPathComponent("\(candidateName).\(fileExtension)")

            if fileManager.fileExists(atPath: outputURL.path) {
                suffix += 1
                continue
            }

            removeStaleWordLockFile(for: outputURL, fileManager: fileManager)
            return outputURL
        }
    }

    private static func removeStaleWordLockFile(for outputURL: URL, fileManager: FileManager) {
        guard outputURL.pathExtension.lowercased() == "docx" else { return }
        let lockFileURL = outputURL
            .deletingLastPathComponent()
            .appendingPathComponent("~$\(outputURL.lastPathComponent)")

        if fileManager.fileExists(atPath: lockFileURL.path) {
            try? fileManager.removeItem(at: lockFileURL)
        }
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

import Testing
import UIKit
import ZIPFoundation
@testable import InspectorPro

@Test func imageQualityPresets() {
    #expect(ImageQuality.economical.maxWidth == 900)
    #expect(ImageQuality.economical.jpegQuality == 0.45)
    #expect(ImageQuality.economical.targetExportBytesPerImage == 170_000)
    #expect(ImageQuality.balanced.maxWidth == 1400)
    #expect(ImageQuality.balanced.jpegQuality == 0.60)
    #expect(ImageQuality.balanced.targetExportBytesPerImage == 280_000)
    #expect(ImageQuality.high.maxWidth == 2000)
    #expect(ImageQuality.high.jpegQuality == 0.75)
    #expect(ImageQuality.high.targetExportBytesPerImage == 420_000)
}

@Test func photoRecordDisplayPath() {
    let photo = PhotoRecord(
        imagePath: "base/image.jpg",
        annotatedImagePath: nil
    )
    #expect(photo.displayImagePath == "base/image.jpg")

    photo.annotatedImagePath = "base/annotated.png"
    #expect(photo.displayImagePath == "base/annotated.png")
}

@Test func projectSortedPhotosUsesManualPosition() {
    let earlyDate = Date(timeIntervalSince1970: 1_000)
    let lateDate = Date(timeIntervalSince1970: 2_000)

    let project = Project(name: "Project")
    let first = PhotoRecord(imagePath: "a.jpg", position: 1, createdAt: earlyDate)
    let second = PhotoRecord(imagePath: "b.jpg", position: 0, createdAt: lateDate)
    let tieBreaker = PhotoRecord(imagePath: "c.jpg", position: 0, createdAt: earlyDate)

    first.project = project
    second.project = project
    tieBreaker.project = project
    project.photos = [first, second, tieBreaker]

    #expect(project.sortedPhotos.map(\.imagePath) == ["c.jpg", "b.jpg", "a.jpg"])
}

@Test func xmlEscaping() {
    let input = "Test & <value> \"quoted\" 'apos'"
    let escaped = OpenXMLBuilder.escapeXML(input)
    #expect(escaped == "Test &amp; &lt;value&gt; &quot;quoted&quot; &apos;apos&apos;")
}

@Test func xmlEscapingRemovesInvalidControlCharacters() {
    let input = "Valid\u{0000}Text\u{0001}\u{0008}"
    let escaped = OpenXMLBuilder.escapeXML(input)
    #expect(escaped == "ValidText")
}

@Test func openXMLTableStructure() {
    let row = OpenXMLBuilder.buildPhotoRow(
        freeText: "בדיקה",
        imageRelId: "rId10",
        imageWidthEMU: 1_500_000,
        imageHeightEMU: 1_000_000,
        imageId: 1,
        rowHeightTwips: 7200,
        imageColumnWidthTwips: 5000,
        textColumnWidthTwips: 3300
    )
    let table = OpenXMLBuilder.buildPhotosTable(
        rowsXML: row,
        tableWidthTwips: 8300,
        imageColumnWidthTwips: 5000,
        textColumnWidthTwips: 3300
    )

    #expect(table.contains("<w:tbl>"))
    #expect(table.contains("תמונה"))
    #expect(table.contains("תיאור"))
    #expect(table.contains("rId10"))
    #expect(table.contains("<w:jc w:val=\"right\"/>"))
    #expect(!table.contains("<w:t xml:space=\"preserve\">1.</w:t>"))
    #expect(!table.contains("<w:bidi/>"))
    #expect(!table.contains("<w:rtl/>"))
}

@Test func openXMLRowWithEmptyDescriptionStillContainsParagraphInTextCell() {
    let row = OpenXMLBuilder.buildPhotoRow(
        freeText: "   \n",
        imageRelId: "rId10",
        imageWidthEMU: 1_500_000,
        imageHeightEMU: 1_000_000,
        imageId: 1,
        rowHeightTwips: 7200,
        imageColumnWidthTwips: 5000,
        textColumnWidthTwips: 3300
    )

    let paragraphCount = row.components(separatedBy: "<w:p>").count - 1
    #expect(paragraphCount >= 2)
}

@Test func docxTemplateContainsTablePlaceholder() {
    let xml = DocxTemplateBuilder.documentXML()
    #expect(xml.contains("{{PHOTOS_TABLE}}"))
}

@Test func docxFooterPutsEmailBeforeInspectorName() {
    let footer = DocxTemplateBuilder.footerXML()
    #expect(footer.contains("מייל ‎iter@iter.co.il‎ אבישי ‎054-6222577‎"))
}

@Test func docxTemplateReservesHeaderAndFooterSpace() {
    let options = ExportOptions(
        format: .docx,
        quality: .balanced,
        photoCount: 8
    )
    let xml = DocxTemplateBuilder.documentXML()

    #expect(xml.contains("w:top=\"1840\""))
    #expect(xml.contains("w:bottom=\"1440\""))
    #expect(xml.contains("w:header=\"170\""))
    #expect(xml.contains("w:footer=\"227\""))
    #expect(xml.contains("headerReference"))
    #expect(xml.contains("footerReference"))
    #expect(options.docxTopMarginTwips == 1840)
    #expect(options.docxBottomMarginTwips == 1440)
    #expect(options.docxHeaderDistanceTwips == 170)
    #expect(options.docxFooterDistanceTwips == 227)
}

@Test func docxKeepsTwoPhotosPerPageWithReservedHeaderFooterSpace() {
    let docxOptions = ExportOptions(
        format: .docx,
        quality: .balanced,
        photoCount: 20
    )

    #expect(docxOptions.targetPhotoRowHeight > docxOptions.minimumPhotoRowHeight)
    #expect(docxOptions.docxTableLayoutSafetyPaddingTwips == 240)

    let docxContentHeightTwips = Int(docxOptions.contentHeight * 20.0)
    let headerHeightTwips = Int(docxOptions.tableHeaderHeight * 20.0)
    let rowsHeightTwips = docxOptions.targetPhotoRowHeightTwips * docxOptions.photosPerPage
    let tableUsedHeightTwips = headerHeightTwips + rowsHeightTwips

    #expect(tableUsedHeightTwips <= (docxContentHeightTwips - docxOptions.docxTableLayoutSafetyPaddingTwips))
}

@Test func compressorRespectsMaxBytes() {
    let size = CGSize(width: 2400, height: 1800)
    let image = UIGraphicsImageRenderer(size: size).image { context in
        UIColor.systemOrange.setFill()
        context.fill(CGRect(origin: .zero, size: size))
    }
    guard let sourceData = image.pngData() else {
        Issue.record("Failed to create source image data")
        return
    }

    let maxBytes = 120_000
    let compressed = ImageCompressor.compressData(
        sourceData,
        quality: .high,
        maxWidthOverride: 1200,
        maxBytes: maxBytes
    )

    #expect(compressed != nil)
    #expect((compressed?.count ?? .max) <= maxBytes)
}

@Test func exportBudgetStaysAdaptiveForLargePhotoSets() {
    let options = ExportOptions(
        format: .pdf,
        quality: .economical,
        photoCount: 126
    )

    #expect(options.exportImageMaxBytes == 150_793)
    #expect(options.exportImageMaxBytes < ImageQuality.economical.targetExportBytesPerImage)

    let baseRenderWidth = min(ImageQuality.economical.maxWidth, options.imageContentWidth * 2.2)
    #expect(options.exportImageMaxRenderWidth < baseRenderWidth)
    #expect(options.exportImageMaxRenderWidth >= ImageQuality.economical.minimumAdaptiveRenderWidth)
}

@Test func exportBudgetUsesPresetForSmallProjects() {
    let options = ExportOptions(
        format: .docx,
        quality: .economical,
        photoCount: 12
    )

    #expect(options.exportImageMaxBytes == ImageQuality.economical.targetExportBytesPerImage)
}

@Test func docxExporterProducesWellFormedXMLParts() async throws {
    FileManagerService.shared.ensureDirectoriesExist()

    let image = UIGraphicsImageRenderer(size: CGSize(width: 1200, height: 900)).image { context in
        UIColor.systemBlue.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 1200, height: 900))
    }
    guard let jpeg = image.jpegData(compressionQuality: 0.8) else {
        Issue.record("Failed creating fixture image")
        return
    }

    let imagePath = "tests/export-fixture.jpg"
    let imageURL = AppConstants.imagesBaseURL.appendingPathComponent(imagePath)
    try FileManager.default.createDirectory(
        at: imageURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try jpeg.write(to: imageURL)
    defer { try? FileManager.default.removeItem(at: imageURL) }

    let project = Project(
        name: "בדיקת יצוא",
        address: "כפר ויתקין",
        date: Date(timeIntervalSince1970: 1_700_000_000),
        notes: "תקין"
    )
    let photo = PhotoRecord(
        imagePath: imagePath,
        freeText: "שורת בדיקה",
        position: 0
    )
    photo.project = project
    project.photos = [photo]

    let options = ExportOptions(
        format: .docx,
        quality: .balanced,
        photoCount: 1
    )

    let outputURL = try await DocxExporter.export(
        project: project,
        photos: [photo],
        options: options,
        onProgress: { _ in }
    )
    defer { try? FileManager.default.removeItem(at: outputURL) }

    let archive: Archive
    do {
        archive = try Archive(url: outputURL, accessMode: .read)
    } catch {
        let exists = FileManager.default.fileExists(atPath: outputURL.path)
        let size = (try? FileManager.default.attributesOfItem(atPath: outputURL.path)[.size] as? NSNumber)?.intValue ?? -1
        Issue.record("Failed to open exported DOCX archive at \(outputURL.path) (exists=\(exists), size=\(size)): \(error.localizedDescription)")
        return
    }

    var xmlEntries: [String: Data] = [:]
    for entry in archive where entry.path.hasSuffix(".xml") || entry.path.hasSuffix(".rels") {
        var data = Data()
        _ = try archive.extract(entry) { chunk in data.append(chunk) }
        xmlEntries[entry.path] = data
    }

    #expect(!xmlEntries.isEmpty)

    for (path, data) in xmlEntries {
        let parser = XMLParser(data: data)
        #expect(parser.parse(), "XML parse failed for \(path): \(parser.parserError?.localizedDescription ?? "Unknown error")")
    }

    #expect(xmlEntries["word/document.xml"] != nil)
    #expect(xmlEntries["word/_rels/document.xml.rels"] != nil)
    #expect(xmlEntries["word/header1.xml"] != nil)
    #expect(xmlEntries["word/footer1.xml"] != nil)
    #expect(xmlEntries["word/_rels/header1.xml.rels"] != nil)

    let documentRelsText = xmlEntries["word/_rels/document.xml.rels"]
        .flatMap { String(data: $0, encoding: .utf8) } ?? ""
    #expect(documentRelsText.contains("relationships/header"))
    #expect(documentRelsText.contains("relationships/footer"))
    #expect(documentRelsText.contains("relationships/image"))
    #expect(documentRelsText.contains("Target=\"media/image10.jpg\""))

    let headerRelsText = xmlEntries["word/_rels/header1.xml.rels"]
        .flatMap { String(data: $0, encoding: .utf8) } ?? ""
    #expect(headerRelsText.contains("Target=\"media/image1.jpeg\""))

    let footerData = xmlEntries["word/footer1.xml"]
    let footerText = footerData.flatMap { String(data: $0, encoding: .utf8) } ?? ""
    #expect(footerText.contains("מייל ‎iter@iter.co.il‎ אבישי ‎054-6222577‎"))
}

@Test func docxExporterRemovesStaleWordLockFile() async throws {
    FileManagerService.shared.ensureDirectoriesExist()

    let outputDir = AppConstants.exportsURL
    try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
    let uniqueTag = String(UUID().uuidString.prefix(8))
    let projectName = "Lock Test \(uniqueTag)"

    let project = Project(
        name: projectName,
        address: "Address",
        date: Date(timeIntervalSince1970: 1_700_000_000),
        notes: "Notes"
    )
    let options = ExportOptions(
        format: .docx,
        quality: .balanced,
        photoCount: 0
    )

    let expectedBaseName = "\(projectName)_2023-11-14.docx"
    let expectedPrefix = "\(projectName)_2023-11-14"
    let staleLockURL = outputDir.appendingPathComponent("~$\(expectedBaseName)")

    let existing = (try? FileManager.default.contentsOfDirectory(at: outputDir, includingPropertiesForKeys: nil)) ?? []
    for fileURL in existing where fileURL.lastPathComponent.hasPrefix(expectedPrefix) || fileURL.lastPathComponent.hasPrefix("~$\(expectedPrefix)") {
        try? FileManager.default.removeItem(at: fileURL)
    }

    try "stale-lock".write(to: staleLockURL, atomically: true, encoding: .utf8)

    let outputURL = try await DocxExporter.export(
        project: project,
        photos: [],
        options: options,
        onProgress: { _ in }
    )
    defer {
        try? FileManager.default.removeItem(at: outputURL)
        let generatedLockURL = outputURL
            .deletingLastPathComponent()
            .appendingPathComponent("~$\(outputURL.lastPathComponent)")
        try? FileManager.default.removeItem(at: generatedLockURL)
        try? FileManager.default.removeItem(at: staleLockURL)
    }

    let generatedLockURL = outputURL
        .deletingLastPathComponent()
        .appendingPathComponent("~$\(outputURL.lastPathComponent)")
    #expect(!FileManager.default.fileExists(atPath: generatedLockURL.path))
    #expect(FileManager.default.fileExists(atPath: outputURL.path))
}

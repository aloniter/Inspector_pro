import Testing
import UIKit
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

@Test func openXMLTableStructure() {
    let row = OpenXMLBuilder.buildPhotoRow(
        photoNumber: 1,
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
}

@Test func docxTemplateContainsTablePlaceholder() {
    let xml = DocxTemplateBuilder.documentXML()
    #expect(xml.contains("{{PHOTOS_TABLE}}"))
}

@Test func docxTemplateReservesHeaderAndFooterSpace() {
    let options = ExportOptions(
        format: .docx,
        quality: .balanced,
        photoCount: 8
    )
    let xml = DocxTemplateBuilder.documentXML()

    #expect(xml.contains("w:top=\"1440\""))
    #expect(xml.contains("w:bottom=\"1440\""))
    #expect(xml.contains("w:header=\"720\""))
    #expect(xml.contains("w:footer=\"720\""))
    #expect(options.docxTopMarginTwips == 1440)
    #expect(options.docxBottomMarginTwips == 1440)
    #expect(options.docxHeaderDistanceTwips == 720)
    #expect(options.docxFooterDistanceTwips == 720)
}

@Test func docxKeepsTwoPhotosPerPageWithReservedHeaderFooterSpace() {
    let docxOptions = ExportOptions(
        format: .docx,
        quality: .balanced,
        photoCount: 20
    )
    let pdfOptions = ExportOptions(
        format: .pdf,
        quality: .balanced,
        photoCount: 20
    )

    #expect(docxOptions.targetPhotoRowHeight > docxOptions.minimumPhotoRowHeight)
    #expect(docxOptions.targetPhotoRowHeight < pdfOptions.targetPhotoRowHeight)
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

    #expect(options.exportImageMaxBytes == 67_460)
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

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

@Test func projectDefaultsToDisabledNumberedImageExport() {
    let project = Project(name: "Project")
    #expect(project.showsNumberedImagesInReport == false)
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
    #expect(table.contains(ExportTextFormatter.bulletedDescriptionText(from: "בדיקה")))
    #expect(!table.contains("<w:t xml:space=\"preserve\">1.</w:t>"))
    #expect(!table.contains("<w:bidi/>"))
    #expect(!table.contains("<w:rtl/>"))
}

@Test func exportFormatterPlacesRTLBulletAtLogicalStartOfEachLine() {
    let formatted = ExportTextFormatter.bulletedDescriptionText(from: "סכום לא מסודר\n• הערה נוספת")
    let lines = formatted.components(separatedBy: "\n")

    #expect(lines.count == 2)
    #expect(lines[0] == "\u{202B}•\u{00A0}סכום לא מסודר\u{202C}")
    #expect(lines[1] == "\u{202B}•\u{00A0}הערה נוספת\u{202C}")
}

@Test func exportFormatterTurnsNumberedLinesIntoBoldHeadingsWithoutDots() {
    let lines = ExportTextFormatter.descriptionLines(from: "1. כיסאות:\nשחור תקול")

    #expect(lines.count == 2)
    #expect(lines[0].text == "1 כיסאות:")
    #expect(lines[0].isBold)
    #expect(!lines[0].usesBullet)
    #expect(lines[0].exportText == "\u{202B}1 כיסאות:\u{202C}")
    #expect(lines[1].text == "שחור תקול")
    #expect(!lines[1].isBold)
    #expect(lines[1].usesBullet)
    #expect(lines[1].exportText == "\u{202B}•\u{00A0}שחור תקול\u{202C}")
}

@Test func exportFormatterPrependsBuiltInItemNumberWhenEnabled() {
    let lines = ExportTextFormatter.descriptionLines(
        from: "כללי:\nבסלון נראים ברגים לבנים",
        itemNumber: 3,
        showsNumberedImagesInReport: true
    )

    #expect(lines.count == 2)
    #expect(lines[0].text == "3. כללי:")
    #expect(lines[0].isBold)
    #expect(lines[0].exportText == "\u{202B}3. כללי:\u{202C}")
    #expect(lines[0].runs == [
        .init(text: "\u{202B}3. כללי:\u{202C}", isBold: true),
    ])
    #expect(lines[1].text == "בסלון נראים ברגים לבנים")
    #expect(!lines[1].isBold)
    #expect(lines[1].runs == [
        .init(text: "\u{202B}•\u{00A0}בסלון נראים ברגים לבנים\u{202C}", isBold: false),
    ])
}

@Test func exportFormatterBuildsNumberedAttendeeLinesForRTL() {
    let lines = ExportTextFormatter.numberedAttendeeLines(from: "אלון\nדפנה\n אבישי ")

    #expect(lines == [
        "\u{202B}1.\u{00A0}אלון\u{202C}",
        "\u{202B}2.\u{00A0}דפנה\u{202C}",
        "\u{202B}3.\u{00A0}אבישי\u{202C}",
    ])
}

@Test func exportFormatterUsesNumericCoverDate() {
    let date = DateComponents(
        calendar: Calendar(identifier: .gregorian),
        year: 2026,
        month: 4,
        day: 6
    ).date!

    #expect(ExportTextFormatter.reportCoverDateString(from: date) == "6.4.2026")
}

@Test func coverPageFieldFormatterKeepsHebrewLabelAndColonTogether() {
    let formatted = ExportTextFormatter.coverPageFieldText(label: "כתובת", value: "—")

    #expect(formatted == "\u{2067}כתובת:\u{2069} \u{2066}—\u{2069}")
}

@Test func rtlHeadingFormatterKeepsColonAtEndOfHebrewWord() {
    let formatted = ExportTextFormatter.rtlHeadingText("נוכחים:")
    #expect(formatted == "\u{202B}נוכחים:\u{202C}")
}

@Test func openXMLBuilderBoldsNumberedHeadingsAndRemovesTrailingDot() {
    let row = OpenXMLBuilder.buildPhotoRow(
        freeText: "1. כיסאות:\nשחור תקול",
        imageRelId: "rId10",
        imageWidthEMU: 1_500_000,
        imageHeightEMU: 1_000_000,
        imageId: 1,
        rowHeightTwips: 7200,
        imageColumnWidthTwips: 5000,
        textColumnWidthTwips: 3300
    )

    #expect(row.contains("<w:b/><w:bCs/>"))
    #expect(row.contains(OpenXMLBuilder.escapeXML("\u{202B}1 כיסאות:\u{202C}")))
    #expect(!row.contains("1. כיסאות:"))
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

@Test func docxCoverDetailsAvoidsDirectionalIsolatesAndUsesSeparateLabelValueParagraphs() {
    let xml = DocxTemplateBuilder.coverDetailsXML(
        address: "כפר ויתקין",
        date: "6.4.2026",
        attendees: "אלון\nדפנה",
        notes: "נדרש תיקון"
    )

    #expect(!xml.contains("\u{2066}"))
    #expect(!xml.contains("\u{2067}"))
    #expect(!xml.contains("\u{2069}"))
    #expect(xml.contains(">כתובת<"))
    #expect(xml.contains(">כפר ויתקין<"))
    #expect(xml.contains(">תאריך<"))
    #expect(xml.contains(">6.4.2026<"))
    #expect(xml.contains(OpenXMLBuilder.escapeXML(ExportTextFormatter.rtlHeadingText("נוכחים:"))))
    #expect(xml.contains("w:color w:val=\"1F4E79\""))
    #expect(xml.contains("w:jc w:val=\"center\""))
    #expect(!xml.contains("w:jc w:val=\"right\""))
    #expect(xml.contains("w:sz w:val=\"24\""))
    #expect(xml.contains("w:sz w:val=\"20\""))
    #expect(xml.contains(OpenXMLBuilder.escapeXML("\u{202B}1.\u{00A0}אלון\u{202C}")))
    #expect(xml.contains(OpenXMLBuilder.escapeXML("\u{202B}2.\u{00A0}דפנה\u{202C}")))
    #expect(xml.contains(">הערות<"))
    #expect(xml.contains(">נדרש תיקון<"))
}

@Test func docxCoverDetailsOmitsAttendeesSectionWhenValueIsMissing() {
    let xml = DocxTemplateBuilder.coverDetailsXML(
        address: "כפר ויתקין",
        date: "6.4.2026",
        attendees: nil,
        notes: "נדרש תיקון"
    )

    #expect(!xml.contains(">נוכחים:<"))
    #expect(!xml.contains("1F4E79"))
}

@Test func openXMLBuilderKeepsNumberOnlyInDescriptionSideForNumberedReportRows() {
    let row = OpenXMLBuilder.buildPhotoRow(
        freeText: "כללי:\nבסלון נראים ברגים לבנים",
        imageRelId: "rId10",
        imageWidthEMU: 1_500_000,
        imageHeightEMU: 1_000_000,
        imageId: 1,
        itemNumber: 1,
        showsNumberedImagesInReport: true,
        rowHeightTwips: 7200,
        imageColumnWidthTwips: 5000,
        textColumnWidthTwips: 3300
    )

    #expect(row.contains("w:color w:val=\"1F4E79\"") == false)
    #expect(row.contains("<w:t xml:space=\"preserve\">1</w:t>") == false)
    #expect(row.contains(OpenXMLBuilder.escapeXML("\u{202B}1. כללי:\u{202C}")))
    #expect(row.contains(OpenXMLBuilder.escapeXML("\u{202B}•\u{00A0}בסלון נראים ברגים לבנים\u{202C}")))
}

@Test func docxFooterUsesSeparateRunsForPrimaryLine() {
    let footer = DocxTemplateBuilder.footerXML(branding: .legacyDefault)
    #expect(footer.contains("<w:bidi/>"))
    #expect(footer.contains(">iter@iter.co.il </w:t>"))
    #expect(footer.contains(">מייל <") || footer.contains(">דוא&quot;ל <"))
    #expect(footer.contains(">054-6222577 <"))
    #expect(footer.contains(">אבישי</w:t>") || footer.contains(">אבישי </w:t>"))
    #expect(footer.contains(">09-8665885 <"))
    #expect(footer.contains(">משרד <"))
    #expect(footer.contains(">054-6222575 <"))
    #expect(footer.contains(">דפנה</w:t>") || footer.contains(">דפנה </w:t>"))
    #expect(!footer.contains("אבישי 054-6222577 מייל iter@iter.co.il"))
    #expect(footer.firstRange(of: "iter@iter.co.il")!.lowerBound < footer.firstRange(of: "054-6222577")!.lowerBound)
    #expect(footer.firstRange(of: "09-8665885")!.lowerBound < footer.firstRange(of: "054-6222575")!.lowerBound)
}

@Test func brandingFooterFormatterNormalizesAddressNumbersForRTL() {
    let normalized = BrandingFooterFormatter.normalizeAddressLine("תל אביב, ת\"ד 635 מיקוד 4020000")
    #expect(normalized == "תל אביב, ת\"ד ‎635‎ מיקוד ‎4020000‎")
}

@Test func brandingFooterFormatterParsesLegacyPrimaryFooterLines() {
    let parsed = BrandingPrimaryFooterFields.fromStoredLines(
        pdf: DefaultBrandingProfile.primaryFooterLinePDF,
        docx: DefaultBrandingProfile.primaryFooterLineDOCX
    )

    #expect(parsed.contactName == "אבישי")
    #expect(parsed.phoneNumber == "054-6222577")
    #expect(parsed.roleLabel == "דוא\"ל")
    #expect(parsed.emailAddress == "iter@iter.co.il")
}

@Test func brandingFooterFormatterComposesStableStructuredFooterLines() {
    let primary = BrandingPrimaryFooterFields(
        contactName: "אלון",
        roleLabel: "מייל",
        phoneNumber: "0544288272",
        emailAddress: "aloniter99@gmail.com"
    )
    let secondary = BrandingSecondaryFooterFields(
        firstLabel: "שקד",
        firstNumber: "054-6222575",
        secondLabel: "משרד",
        secondNumber: "09-8665885"
    )

    #expect(BrandingFooterFormatter.composePrimaryLine(primary) == "אלון ‎0544288272‎ מייל ‎aloniter99@gmail.com‎")
    #expect(BrandingFooterFormatter.composeSecondaryLine(secondary) == "שקד ‎054-6222575‎ משרד ‎09-8665885‎")
}

@Test func brandingFooterFormatterAllowsSecondaryLineWithoutSecondLabel() {
    let secondary = BrandingSecondaryFooterFields(
        firstLabel: "תמיכה",
        firstNumber: "09-8881111",
        secondLabel: "",
        secondNumber: "052-9994444"
    )

    #expect(BrandingFooterFormatter.composeSecondaryLine(secondary) == "תמיכה ‎09-8881111‎ ‎052-9994444‎")
}

@Test func brandingFooterFormatterBuildsPrimaryRunsInNaturalHebrewOrder() {
    let primary = BrandingPrimaryFooterFields(
        contactName: "אבישי",
        roleLabel: "מייל",
        phoneNumber: "054-6222577",
        emailAddress: "iter@iter.co.il"
    )

    let runs = BrandingFooterFormatter.primaryRuns(primary)

    #expect(runs.map(\.text) == ["אבישי", "054-6222577", "מייל", "iter@iter.co.il"])
    #expect(runs.map(\.direction) == [.rightToLeft, .leftToRight, .rightToLeft, .leftToRight])
}

@Test func brandingFooterFormatterBuildsPrimaryDisplayRunsInStableVisualOrder() {
    let primary = BrandingPrimaryFooterFields(
        contactName: "אבישי",
        roleLabel: "מייל",
        phoneNumber: "054-6222577",
        emailAddress: "iter@iter.co.il"
    )

    let runs = BrandingFooterFormatter.primaryDisplayRuns(primary)

    #expect(runs.map(\.text) == ["iter@iter.co.il", "מייל", "054-6222577", "אבישי"])
    #expect(runs.map(\.direction) == [.leftToRight, .rightToLeft, .leftToRight, .rightToLeft])
}

@Test func brandingFooterFormatterBuildsSecondaryRunsInNaturalHebrewOrder() {
    let secondary = BrandingSecondaryFooterFields(
        firstLabel: "דפנה",
        firstNumber: "054-6222575",
        secondLabel: "משרד",
        secondNumber: "09-8665885"
    )

    let runs = BrandingFooterFormatter.secondaryRuns(secondary)

    #expect(runs.map(\.text) == ["דפנה", "054-6222575", "משרד", "09-8665885"])
    #expect(runs.map(\.direction) == [.rightToLeft, .leftToRight, .rightToLeft, .leftToRight])
}

@Test func brandingFooterFormatterBuildsSecondaryDisplayRunsInStableVisualOrder() {
    let secondary = BrandingSecondaryFooterFields(
        firstLabel: "דפנה",
        firstNumber: "054-6222575",
        secondLabel: "משרד",
        secondNumber: "09-8665885"
    )

    let runs = BrandingFooterFormatter.secondaryDisplayRuns(secondary)

    #expect(runs.map(\.text) == ["09-8665885", "משרד", "054-6222575", "דפנה"])
    #expect(runs.map(\.direction) == [.leftToRight, .rightToLeft, .leftToRight, .rightToLeft])
}

@Test func resolvedExportBrandingFallsBackToLegacyDefaultsWithoutProfile() {
    let project = Project(name: "Fallback")

    let branding = ResolvedExportBranding.resolve(for: project)

    #expect(branding.footerAddressLine == "כפר ויתקין, ת\"ד ‎635‎ מיקוד ‎4020000‎")
    #expect(branding.primaryFooterLinePDF == "אבישי ‎054-6222577‎ דוא\"ל ‎iter@iter.co.il‎")
    #expect(branding.primaryFooterLineDOCX == "‎iter@iter.co.il‎ מייל ‎054-6222577‎ אבישי")
    #expect(branding.secondaryFooterLine == "דפנה ‎054-6222575‎ משרד ‎09-8665885‎")
    #expect(branding.logoImageData != nil)
}

@Test func resolvedExportBrandingUsesLinkedProfileValues() {
    let brandingProfile = BrandingProfile(
        name: "Client",
        isDefault: false,
        usesBundledDefaultLogo: true,
        footerAddressLine: "Custom address",
        primaryFooterLinePDF: "Custom pdf line",
        primaryFooterLineDOCX: "Custom docx line",
        secondaryFooterLine: "Custom secondary line"
    )
    let project = Project(name: "Branded", brandingProfile: brandingProfile)

    let branding = ResolvedExportBranding.resolve(for: project)

    #expect(branding.footerAddressLine == "Custom address")
    #expect(branding.primaryFooterLinePDF == "Custom pdf line")
    #expect(branding.primaryFooterLineDOCX == "Custom docx line")
    #expect(branding.secondaryFooterLine == "Custom secondary line")
    #expect(branding.logoImageData != nil)
}

@Test func resolvedExportBrandingFallsBackToBundledLogoWhenCustomLogoIsMissing() {
    let brandingProfile = BrandingProfile(
        name: "Client",
        isDefault: false,
        usesBundledDefaultLogo: false,
        footerAddressLine: "Address",
        primaryFooterLinePDF: "Primary",
        primaryFooterLineDOCX: "Primary",
        secondaryFooterLine: "Secondary"
    )
    BrandingAssetStorage.deleteCustomLogo(for: brandingProfile)
    let project = Project(name: "Branded", brandingProfile: brandingProfile)

    let branding = ResolvedExportBranding.resolve(for: project)

    #expect(branding.logoImageData == ResolvedExportBranding.legacyDefault.logoImageData)
}

@Test func resolvedExportBrandingUsesStoredCustomLogoWhenAvailable() throws {
    let brandingProfile = BrandingProfile(
        name: "Client",
        isDefault: false,
        usesBundledDefaultLogo: false,
        footerAddressLine: "Address",
        primaryFooterLinePDF: "Primary",
        primaryFooterLineDOCX: "Primary",
        secondaryFooterLine: "Secondary"
    )

    let customImage = UIGraphicsImageRenderer(size: CGSize(width: 240, height: 120)).image { context in
        UIColor.systemRed.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 240, height: 120))
    }

    try BrandingAssetStorage.saveCustomLogo(customImage, for: brandingProfile)
    defer { BrandingAssetStorage.deleteCustomLogo(for: brandingProfile) }

    let project = Project(name: "Branded", brandingProfile: brandingProfile)
    let branding = ResolvedExportBranding.resolve(for: project)

    #expect(branding.logoImageData != nil)
    #expect(branding.logoImageData != ResolvedExportBranding.legacyDefault.logoImageData)
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
    #expect(footerText.contains(">iter@iter.co.il </w:t>"))
    #expect(footerText.contains(">דוא&quot;ל </w:t>"))
    #expect(footerText.contains(">054-6222577 </w:t>"))
    #expect(footerText.contains(">אבישי</w:t>"))

    let documentText = xmlEntries["word/document.xml"]
        .flatMap { String(data: $0, encoding: .utf8) } ?? ""
    #expect(!documentText.contains("\u{2066}"))
    #expect(!documentText.contains("\u{2067}"))
    #expect(!documentText.contains("\u{2069}"))
    #expect(documentText.contains(">כתובת<"))
    #expect(documentText.contains(">כפר ויתקין<"))
    #expect(documentText.contains(">\(ExportTextFormatter.reportCoverDateString(from: project.date))<"))
    #expect(!documentText.contains(">נוכחים:<"))
    #expect(documentText.contains(">הערות<"))
    #expect(documentText.contains(">תקין<"))
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

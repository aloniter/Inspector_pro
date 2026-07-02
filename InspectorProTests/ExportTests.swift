import Testing
import UIKit
import Supabase
import ZIPFoundation
@testable import InspectorPro

private func makeAuthSession(expiresAt: TimeInterval, email: String? = "inspector@example.com") -> Session {
    let now = Date()
    let user = User(
        id: UUID(),
        appMetadata: [:],
        userMetadata: [:],
        aud: "authenticated",
        email: email,
        createdAt: now,
        updatedAt: now
    )

    return Session(
        accessToken: "access-token",
        tokenType: "bearer",
        expiresIn: expiresAt - now.timeIntervalSince1970,
        expiresAt: expiresAt,
        refreshToken: "refresh-token",
        user: user
    )
}

private func docxXMLEntries(from archiveURL: URL) throws -> [String: Data] {
    let archive = try Archive(url: archiveURL, accessMode: .read)
    var xmlEntries: [String: Data] = [:]

    for entry in archive where entry.path.hasSuffix(".xml") || entry.path.hasSuffix(".rels") {
        var data = Data()
        _ = try archive.extract(entry) { chunk in data.append(chunk) }
        xmlEntries[entry.path] = data
    }

    return xmlEntries
}

private func docxEntryData(from archiveURL: URL, path: String) throws -> Data? {
    let archive = try Archive(url: archiveURL, accessMode: .read)
    guard let entry = archive.first(where: { $0.path == path }) else { return nil }

    var data = Data()
    _ = try archive.extract(entry) { chunk in data.append(chunk) }
    return data
}

private func occurrenceCount(of needle: String, in haystack: String) -> Int {
    haystack.components(separatedBy: needle).count - 1
}

private let variedAttendeesText = [
    "א",
    "ישראל ישראלי",
    "משה כהן לוי ארוך מאוד",
    "דני",
    "נועה",
    "אביגיל בר",
    "רן",
    "יוסף כהן",
    "מיכל",
    "שם עשירי",
    "שם אחד עשר",
    "שם שנים עשר",
].joined(separator: "\n")

private func pixelRGBA(in image: UIImage, at point: CGPoint) -> (red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8)? {
    guard let cgImage = image.cgImage, cgImage.width > 0, cgImage.height > 0 else {
        return nil
    }

    let scale = image.scale > 0 ? image.scale : 1
    let x = min(max(Int((point.x * scale).rounded(.down)), 0), cgImage.width - 1)
    let y = min(max(Int((point.y * scale).rounded(.down)), 0), cgImage.height - 1)
    guard let cropped = cgImage.cropping(to: CGRect(x: x, y: y, width: 1, height: 1)) else {
        return nil
    }

    var pixel = [UInt8](repeating: 0, count: 4)
    return pixel.withUnsafeMutableBytes { buffer -> (red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8)? in
        guard let baseAddress = buffer.baseAddress,
              let context = CGContext(
                data: baseAddress,
                width: 1,
                height: 1,
                bitsPerComponent: 8,
                bytesPerRow: 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return nil
        }

        context.draw(cropped, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        let bytes = buffer.bindMemory(to: UInt8.self)
        return (bytes[0], bytes[1], bytes[2], bytes[3])
    }
}

@Test func authServiceDoesNotAuthenticateNilOrExpiredSessions() {
    let expiredSession = makeAuthSession(expiresAt: Date().addingTimeInterval(-60).timeIntervalSince1970)

    #expect(AuthService.sessionUsableForAuthentication(nil) == nil)
    #expect(AuthService.sessionUsableForAuthentication(expiredSession) == nil)
}

@Test func authServiceAuthenticatesOnlyValidUnexpiredSessions() throws {
    let validSession = makeAuthSession(expiresAt: Date().addingTimeInterval(3_600).timeIntervalSince1970)

    let authenticatedSession = try #require(AuthService.sessionUsableForAuthentication(validSession))
    #expect(authenticatedSession.user.email == "inspector@example.com")
}

@Test func imageQualityPresets() {
    #expect(ImageQuality.economical.maxWidth == 1200)
    #expect(ImageQuality.economical.jpegQuality == 0.65)
    #expect(ImageQuality.economical.targetExportBytesPerImage == 100_000)
    #expect(ImageQuality.balanced.maxWidth == 1600)
    #expect(ImageQuality.balanced.jpegQuality == 0.78)
    #expect(ImageQuality.balanced.targetExportBytesPerImage == 200_000)
    #expect(ImageQuality.high.maxWidth == 2200)
    #expect(ImageQuality.high.jpegQuality == 0.85)
    #expect(ImageQuality.high.targetExportBytesPerImage == 350_000)
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

@Test func photoRecordDisplayPathFallsBackWhenAnnotatedFileIsMissing() throws {
    let relativeDirectory = "tests/\(UUID().uuidString)"
    let originalRelativePath = "\(relativeDirectory)/image.jpg"
    let annotatedRelativePath = "\(relativeDirectory)/annotated.jpg"
    let directoryURL = AppConstants.imagesBaseURL.appendingPathComponent(relativeDirectory)
    try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directoryURL) }

    let imageURL = AppConstants.imagesBaseURL.appendingPathComponent(originalRelativePath)
    let image = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 20)).image { context in
        UIColor.systemBlue.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 20, height: 20))
    }
    try #require(image.jpegData(compressionQuality: 0.8)).write(to: imageURL)

    let photo = PhotoRecord(
        imagePath: originalRelativePath,
        annotatedImagePath: annotatedRelativePath
    )

    #expect(photo.displayImagePath == originalRelativePath)
}

@Test func flattenedExportImageRendererPrefersAnnotatedSourceAndIsDeterministic() throws {
    FileManagerService.shared.ensureDirectoriesExist()
    let relativeDirectory = "tests/\(UUID().uuidString)"
    let originalPath = "\(relativeDirectory)/original.jpg"
    let annotatedPath = "\(relativeDirectory)/annotated.jpg"
    let directoryURL = AppConstants.imagesBaseURL.appendingPathComponent(relativeDirectory)
    try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directoryURL) }

    let original = UIGraphicsImageRenderer(size: CGSize(width: 80, height: 60)).image { context in
        UIColor.systemBlue.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 80, height: 60))
    }
    let annotated = UIGraphicsImageRenderer(size: CGSize(width: 80, height: 60)).image { context in
        UIColor.systemRed.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 80, height: 60))
    }
    try #require(original.jpegData(compressionQuality: 0.8))
        .write(to: AppConstants.imagesBaseURL.appendingPathComponent(originalPath))
    try #require(annotated.jpegData(compressionQuality: 0.8))
        .write(to: AppConstants.imagesBaseURL.appendingPathComponent(annotatedPath))

    let photo = PhotoRecord(imagePath: originalPath, annotatedImagePath: annotatedPath)
    let options = ExportOptions(format: .pdf, quality: .balanced, photoCount: 1)

    let first = try FlattenedExportImageRenderer.render(photo: photo, options: options)
    let second = try FlattenedExportImageRenderer.render(photo: photo, options: options)

    #expect(first.sourcePath == annotatedPath)
    #expect(first.sourceKind == .annotated)
    #expect(first.pixelSize == second.pixelSize)
    #expect(first.data == second.data)
}

@Test func reportSortedPhotosUsesManualPosition() {
    let earlyDate = Date(timeIntervalSince1970: 1_000)
    let lateDate = Date(timeIntervalSince1970: 2_000)

    let report = Report(name: "Report")
    let first = PhotoRecord(imagePath: "a.jpg", position: 1, createdAt: earlyDate)
    let second = PhotoRecord(imagePath: "b.jpg", position: 0, createdAt: lateDate)
    let tieBreaker = PhotoRecord(imagePath: "c.jpg", position: 0, createdAt: earlyDate)

    first.report = report
    second.report = report
    tieBreaker.report = report
    report.photos = [first, second, tieBreaker]

    #expect(report.sortedPhotos.map(\.imagePath) == ["c.jpg", "b.jpg", "a.jpg"])
}

@Test func reportOpenDefectCountMatchesLogicalPhotoCountIgnoringAnnotations() {
    let report = Report(name: "Report")
    let plainPhoto = PhotoRecord(imagePath: "a.jpg")
    let annotatedPhoto = PhotoRecord(imagePath: "b.jpg", annotatedImagePath: "b-annotated.jpg")
    plainPhoto.report = report
    annotatedPhoto.report = report
    report.photos = [plainPhoto, annotatedPhoto]

    // Two logical photos => two open defects, even though one carries an annotated copy.
    #expect(report.openDefectCount == 2)
    #expect(report.openDefectCount == report.photos.count)

    // Deleting one logical photo lowers the count.
    report.photos = [plainPhoto]
    #expect(report.openDefectCount == 1)
}

@Test func reportDefaultsToDisabledNumberedImageExport() {
    let report = Report(name: "Report")
    #expect(report.showsNumberedImagesInReport == false)
}

@Test func projectSortsReportsNewestFirst() {
    let project = Project(name: "Project")
    let older = Report(name: "Older", date: Date(timeIntervalSince1970: 1_000))
    let newer = Report(name: "Newer", date: Date(timeIntervalSince1970: 2_000))
    older.project = project
    newer.project = project
    project.reports = [older, newer]

    #expect(project.sortedReports.map(\.name) == ["Newer", "Older"])
}

@Test func reportAddressOverridesProjectAddressWhenPresent() {
    let project = Project(name: "Project", address: "Project address")
    let report = Report(name: "Report", address: "Report address", project: project)

    #expect(report.reportAddress == "Report address")

    report.address = nil
    #expect(report.reportAddress == "Project address")
}

@Test func reportMoveChangesOnlyParentProjectRelationship() {
    let oldProject = Project(name: "Old project", address: "Old address")
    let newProject = Project(name: "New project", address: "New address")
    let brandingProfile = BrandingProfile(
        name: "Client",
        footerAddressLine: "Footer address",
        primaryFooterLinePDF: "PDF footer",
        primaryFooterLineDOCX: "DOCX footer",
        secondaryFooterLine: "Secondary footer"
    )
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let report = Report(
        name: "Inspection report",
        address: "Report address",
        date: date,
        attendees: "Attendee",
        notes: "Finding notes",
        showsNumberedImagesInReport: true,
        project: oldProject,
        brandingProfile: brandingProfile
    )
    let photo = PhotoRecord(
        imagePath: "old-project/photo.jpg",
        annotatedImagePath: "old-project/ann_photo.jpg",
        freeText: "Annotation notes",
        position: 4,
        createdAt: Date(timeIntervalSince1970: 1_700_000_100)
    )
    photo.report = report
    report.photos = [photo]

    let didMove = report.move(to: newProject)

    #expect(didMove)
    #expect(report.project?.id == newProject.id)
    #expect(report.name == "Inspection report")
    #expect(report.address == "Report address")
    #expect(report.date == date)
    #expect(report.attendees == "Attendee")
    #expect(report.notes == "Finding notes")
    #expect(report.showsNumberedImagesInReport)
    #expect(report.brandingProfile?.id == brandingProfile.id)
    #expect(report.photos.count == 1)
    #expect(report.photos.first?.imagePath == "old-project/photo.jpg")
    #expect(report.photos.first?.annotatedImagePath == "old-project/ann_photo.jpg")
    #expect(report.photos.first?.freeText == "Annotation notes")
    #expect(report.photos.first?.position == 4)
}

@Test func reportMoveIgnoresCurrentProjectSelection() {
    let project = Project(name: "Project")
    let report = Report(name: "Report", project: project)

    let didMove = report.move(to: project)

    #expect(!didMove)
    #expect(report.project?.id == project.id)
}

@Test func projectDeletionPhotoReferencesUseCurrentReportsOnly() {
    let project = Project(name: "Project")
    let keptProject = Project(name: "Kept project")
    let deletedReport = Report(name: "Deleted", project: project)
    let movedReport = Report(name: "Moved", project: keptProject)
    let photo = PhotoRecord(
        imagePath: "project/photo.jpg",
        annotatedImagePath: "project/ann_photo.jpg"
    )
    let movedPhoto = PhotoRecord(
        imagePath: "project/moved.jpg",
        annotatedImagePath: "project/ann_moved.jpg"
    )
    photo.report = deletedReport
    movedPhoto.report = movedReport
    project.reports = [deletedReport]
    keptProject.reports = [movedReport]

    let references = project.photoFileReferencesForDeletion

    #expect(references.count == 1)
    #expect(references.first?.originalPath == "project/photo.jpg")
    #expect(references.first?.annotatedPath == "project/ann_photo.jpg")
}

@Test func removeDirectoryIfEmptyRemovesEmptyButPreservesMovedReportPhotos() async throws {
    FileManagerService.shared.ensureDirectoriesExist()
    let base = AppConstants.imagesBaseURL

    // An empty project image folder (e.g. left behind after deleting a project) is removed.
    let emptyRelative = "tests/\(UUID().uuidString)"
    let emptyURL = base.appendingPathComponent(emptyRelative)
    try FileManager.default.createDirectory(at: emptyURL, withIntermediateDirectories: true)

    await ImageStorageService.shared.removeDirectoryIfEmpty(at: emptyRelative)
    #expect(!FileManager.default.fileExists(atPath: emptyURL.path))

    // A folder that still holds a moved report's photo must be preserved.
    let occupiedRelative = "tests/\(UUID().uuidString)"
    let occupiedURL = base.appendingPathComponent(occupiedRelative)
    try FileManager.default.createDirectory(at: occupiedURL, withIntermediateDirectories: true)
    let survivorURL = occupiedURL.appendingPathComponent("moved.jpg")
    try Data([0x01, 0x02, 0x03]).write(to: survivorURL)
    defer { try? FileManager.default.removeItem(at: occupiedURL) }

    await ImageStorageService.shared.removeDirectoryIfEmpty(at: occupiedRelative)
    #expect(FileManager.default.fileExists(atPath: occupiedURL.path))
    #expect(FileManager.default.fileExists(atPath: survivorURL.path))
}

@Test func purgeExportsClearsLeftoverFilesButKeepsExportsDirectory() throws {
    FileManagerService.shared.ensureDirectoriesExist()
    let exportsURL = AppConstants.exportsURL

    let leftoverPDF = exportsURL.appendingPathComponent("leftover-\(UUID().uuidString).pdf")
    let leftoverDOCX = exportsURL.appendingPathComponent("leftover-\(UUID().uuidString).docx")
    try Data([0x01, 0x02]).write(to: leftoverPDF)
    try Data([0x03, 0x04]).write(to: leftoverDOCX)
    #expect(FileManager.default.fileExists(atPath: leftoverPDF.path))
    #expect(FileManager.default.fileExists(atPath: leftoverDOCX.path))

    FileManagerService.shared.purgeExports()

    #expect(!FileManager.default.fileExists(atPath: leftoverPDF.path))
    #expect(!FileManager.default.fileExists(atPath: leftoverDOCX.path))
    // The directory itself must survive so future exports can be written.
    #expect(FileManager.default.fileExists(atPath: exportsURL.path))
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

@Test func creatorBrandingTextUsesIterEngineering() {
    let legacyPersonalName = "Alon" + " Iter"

    #expect(AppBranding.createdByText == "Created by Iter Engineering")
    #expect(!AppBranding.createdByText.contains(legacyPersonalName))
}

@Test func docxCorePropertiesUseCreatorBrandingText() {
    let legacyPersonalCreator = ["Created by", "Alon" + " Iter"].joined(separator: " ")
    let xml = DocxTemplateBuilder.corePropertiesXML()

    #expect(xml.contains("<dc:creator>Created by Iter Engineering</dc:creator>"))
    #expect(!xml.contains(legacyPersonalCreator))
}

@Test func openXMLTableStructure() {
    let row = OpenXMLBuilder.buildPhotoRow(
        freeText: "בדיקה",
        imageRelId: "rId10",
        imageWidthEMU: 1_500_000,
        imageHeightEMU: 1_000_000,
        imageId: 1,
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
    #expect(!table.contains("<w:bidiVisual/>"))
    #expect(table.contains("תמונה"))
    #expect(table.contains("תיאור"))
    #expect(table.contains("rId10"))
    #expect(table.contains("<w:jc w:val=\"start\"/>"))
    #expect(table.contains("<w:pStyle w:val=\"InspectorDescriptionBullet\"/>"))
    #expect(table.contains("<w:numPr>"))
    #expect(table.contains("<w:ilvl w:val=\"0\"/>"))
    #expect(table.contains("<w:numId w:val=\"1\"/>"))
    #expect(table.contains("<w:bidi/>"))
    #expect(table.contains("<w:rtl/>"))
    #expect(table.contains("<w:ind w:start=\"540\" w:hanging=\"360\"/>"))
    #expect(table.contains("<w:jc w:val=\"start\"/>"))
    #expect(!table.contains("<w:ind w:left="))
    #expect(!table.contains("<w:ind w:right="))
    #expect(!table.contains("<w:tab w:val=\"num\""))
    #expect(table.contains(">בדיקה</w:t>"))
    #expect(!table.contains(ExportTextFormatter.bulletedDescriptionText(from: "בדיקה")))
    #expect(!table.contains("<w:t xml:space=\"preserve\">1.</w:t>"))
    #expect(!table.contains("<w:t xml:space=\"preserve\">•"))
}

@Test func openXMLBuilderExportsDescriptionBulletsAsRTLWordListParagraphs() {
    let row = OpenXMLBuilder.buildPhotoRow(
        freeText: "בדיקה\n• הערה נוספת",
        imageRelId: "rId10",
        imageWidthEMU: 1_500_000,
        imageHeightEMU: 1_000_000,
        imageId: 1,
        imageColumnWidthTwips: 5000,
        textColumnWidthTwips: 3300
    )

    #expect(occurrenceCount(of: "<w:pStyle w:val=\"InspectorDescriptionBullet\"/>", in: row) == 2)
    #expect(occurrenceCount(of: "<w:numPr>", in: row) == 2)
    #expect(occurrenceCount(of: "<w:ilvl w:val=\"0\"/>", in: row) == 2)
    #expect(occurrenceCount(of: "<w:numId w:val=\"1\"/>", in: row) == 2)
    #expect(occurrenceCount(of: "<w:bidi/>", in: row) == 2)
    #expect(occurrenceCount(of: "<w:rtl/>", in: row) == 2)
    #expect(occurrenceCount(of: "<w:ind w:start=\"540\" w:hanging=\"360\"/>", in: row) == 2)
    #expect(occurrenceCount(of: "<w:jc w:val=\"start\"/>", in: row) == 2)
    #expect(!row.contains("<w:ind w:left="))
    #expect(!row.contains("<w:ind w:right="))
    #expect(!row.contains("<w:tab w:val=\"num\""))
    #expect(row.contains(">בדיקה</w:t>"))
    #expect(row.contains(">הערה נוספת</w:t>"))
    #expect(!row.contains("<w:t xml:space=\"preserve\">•"))
    #expect(!row.contains(OpenXMLBuilder.escapeXML("\u{202B}•\u{00A0}בדיקה\u{202C}")))
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
    let attendees = ExportTextFormatter.numberedAttendees(from: "אלון\nדפנה\n אבישי ")

    #expect(lines == [
        "1.\u{00A0}אלון",
        "2.\u{00A0}דפנה",
        "3.\u{00A0}אבישי",
    ])
    #expect(attendees == [
        .init(number: 1, name: "אלון"),
        .init(number: 2, name: "דפנה"),
        .init(number: 3, name: "אבישי"),
    ])
    #expect(attendees[0].ltrMarkerText == "1.")
    #expect(attendees[0].rtlMarkerText == "1.")
    #expect(attendees[0].rtlEditableMarkerText == "1.")
}

@Test func pdfAttendeeCoverRowsCenterCompactRTLBlockUnderHeading() {
    let attendees = ExportTextFormatter.numberedAttendees(from: "שלום\nמה\nקורה")
    let rows = PdfExporter.attendeeCoverRowLayouts(
        for: attendees,
        x: 50,
        y: 120,
        width: 360,
        lineHeight: 22,
        font: .systemFont(ofSize: 12),
        isRTL: true
    )

    #expect(rows.count == 3)
    for row in rows {
        #expect(row.nameRect.minX == rows[0].nameRect.minX)
        #expect(row.markerRect.minX == rows[0].markerRect.minX)
        #expect(row.markerRect.minX > row.nameRect.maxX)
    }
    let blockMinX = rows[0].nameRect.minX
    let blockMaxX = rows[0].markerRect.maxX
    #expect(abs(((blockMinX + blockMaxX) / 2) - 216) < 1)
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
        imageColumnWidthTwips: 5000,
        textColumnWidthTwips: 3300
    )

    #expect(row.contains("<w:b/><w:bCs/>"))
    #expect(row.contains(OpenXMLBuilder.escapeXML("\u{202B}1 כיסאות:\u{202C}")))
    #expect(!row.contains("1. כיסאות:"))
    #expect(occurrenceCount(of: "<w:numPr>", in: row) == 1)
    #expect(row.contains(">שחור תקול</w:t>"))
    #expect(!row.contains(OpenXMLBuilder.escapeXML("\u{202B}•\u{00A0}שחור תקול\u{202C}")))
}

@Test func openXMLRowWithEmptyDescriptionStillContainsParagraphInTextCell() {
    let row = OpenXMLBuilder.buildPhotoRow(
        freeText: "   \n",
        imageRelId: "rId10",
        imageWidthEMU: 1_500_000,
        imageHeightEMU: 1_000_000,
        imageId: 1,
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

@Test func docxTemplateDefinesRTLNumberingPartRelationshipAndBulletStyle() {
    let contentTypes = DocxTemplateBuilder.contentTypesXML()
    let relationships = DocxTemplateBuilder.documentRelsXML(imageRelationships: [])
    let numbering = DocxTemplateBuilder.numberingXML()
    let styles = DocxTemplateBuilder.stylesXML()

    #expect(contentTypes.contains("PartName=\"/word/numbering.xml\""))
    #expect(contentTypes.contains("wordprocessingml.numbering+xml"))
    #expect(relationships.contains("Id=\"rId7\""))
    #expect(relationships.contains("relationships/numbering"))
    #expect(relationships.contains("Target=\"numbering.xml\""))
    #expect(numbering.contains("<w:abstractNum w:abstractNumId=\"1\">"))
    #expect(numbering.contains("<w:numFmt w:val=\"bullet\"/>"))
    #expect(numbering.contains("<w:suff w:val=\"space\"/>"))
    #expect(numbering.contains("<w:lvlText w:val=\"•\"/>"))
    #expect(numbering.contains("<w:lvlJc w:val=\"right\"/>"))
    #expect(numbering.contains("<w:ind w:start=\"540\" w:hanging=\"360\"/>"))
    #expect(numbering.contains("<w:jc w:val=\"start\"/>"))
    #expect(!numbering.contains("<w:ind w:left="))
    #expect(!numbering.contains("<w:ind w:right="))
    #expect(!numbering.contains("<w:tab w:val=\"num\""))
    #expect(numbering.contains("<w:num w:numId=\"1\">"))
    #expect(numbering.contains("<w:abstractNum w:abstractNumId=\"2\">"))
    #expect(numbering.contains("<w:numFmt w:val=\"decimal\"/>"))
    #expect(numbering.contains("<w:lvlText w:val=\"%1.\"/>"))
    #expect(numbering.contains("<w:ind w:start=\"900\" w:hanging=\"480\"/>"))
    #expect(numbering.contains("<w:num w:numId=\"2\">"))
    #expect(styles.contains("w:styleId=\"InspectorDescriptionBullet\""))
    #expect(styles.contains("<w:numId w:val=\"1\"/>"))
    #expect(styles.contains("w:styleId=\"InspectorCoverAttendeeNumber\""))
    #expect(styles.contains("<w:numId w:val=\"2\"/>"))
    #expect(styles.contains("<w:bidi/>"))
    #expect(styles.contains("<w:ind w:start=\"540\" w:hanging=\"360\"/>"))
    #expect(styles.contains("<w:ind w:start=\"900\" w:hanging=\"480\"/>"))
    #expect(styles.contains("<w:jc w:val=\"start\"/>"))
    #expect(!styles.contains("<w:ind w:left="))
    #expect(!styles.contains("<w:ind w:right="))
}

@Test func docxCoverDetailsAvoidsDirectionalIsolatesAndUsesSeparateLabelValueParagraphs() throws {
    let xml = DocxTemplateBuilder.coverDetailsXML(
        address: "כפר ויתקין",
        date: "6.4.2026",
        defectCount: 5,
        attendees: "אלון\nדפנה",
        notes: "נדרש תיקון"
    )

    #expect(!xml.contains("\u{2066}"))
    #expect(!xml.contains("\u{2067}"))
    #expect(!xml.contains("\u{2069}"))
    #expect(xml.contains("<w:bidi/>"))
    #expect(xml.contains("<w:rtl/>"))
    #expect(xml.contains(">כתובת<"))
    #expect(xml.contains(">כפר ויתקין<"))
    #expect(xml.contains(">תאריך<"))
    #expect(xml.contains(">6.4.2026<"))
    let addressLabelParagraph = try #require(xml.components(separatedBy: "<w:p>").first { $0.contains(">כתובת<") })
    let addressValueParagraph = try #require(xml.components(separatedBy: "<w:p>").first { $0.contains(">כפר ויתקין<") })
    let dateLabelParagraph = try #require(xml.components(separatedBy: "<w:p>").first { $0.contains(">תאריך<") })
    let dateValueParagraph = try #require(xml.components(separatedBy: "<w:p>").first { $0.contains(">6.4.2026<") })
    let attendeesHeadingText = OpenXMLBuilder.escapeXML(ExportTextFormatter.rtlHeadingText("נוכחים:"))
    let attendeesHeadingParagraph = try #require(xml.components(separatedBy: "<w:p>").first { $0.contains(attendeesHeadingText) })
    let firstAttendeeParagraph = try #require(xml.components(separatedBy: "<w:p>").first { $0.contains(">אלון<") })
    let secondAttendeeParagraph = try #require(xml.components(separatedBy: "<w:p>").first { $0.contains(">דפנה<") })
    let notesLabelParagraph = try #require(xml.components(separatedBy: "<w:p>").first { $0.contains(">הערות<") })
    let notesContentParagraph = try #require(xml.components(separatedBy: "<w:p>").first { $0.contains(">נדרש תיקון<") })

    #expect(xml.contains(attendeesHeadingText))
    #expect(xml.contains("<w:tbl>"))
    #expect(xml.contains("<w:tblW w:w=\"2800\" w:type=\"dxa\"/>"))
    #expect(xml.contains("<w:jc w:val=\"center\"/>"))
    #expect(xml.contains("<w:gridCol w:w=\"2800\"/>"))
    #expect(xml.contains("<w:left w:w=\"0\" w:type=\"dxa\"/>"))
    #expect(xml.contains("<w:right w:w=\"320\" w:type=\"dxa\"/>"))
    #expect(!xml.contains("<w:gridCol w:w=\"2760\"/>"))
    #expect(!xml.contains("<w:gridCol w:w=\"480\"/>"))
    #expect(!xml.contains("<w:tblpPr"))
    #expect(!xml.contains("<w:tab"))
    #expect(!xml.contains("<w:bidiVisual/>"))
    #expect(!xml.contains("w:color w:val=\"1F4E79\""))
    #expect(xml.contains("w:jc w:val=\"center\""))
    #expect(!xml.contains("w:sz w:val=\"20\""))
    #expect(xml.contains("w:sz w:val=\"24\""))
    for labelParagraph in [addressLabelParagraph, dateLabelParagraph, attendeesHeadingParagraph, notesLabelParagraph] {
        #expect(labelParagraph.contains("<w:b/>"))
        #expect(labelParagraph.contains("<w:bCs/>"))
        #expect(labelParagraph.contains("<w:sz w:val=\"24\"/>"))
        #expect(labelParagraph.contains("<w:szCs w:val=\"24\"/>"))
    }
    for valueParagraph in [addressValueParagraph, dateValueParagraph, notesContentParagraph] {
        #expect(!valueParagraph.contains("<w:b/>"))
        #expect(!valueParagraph.contains("<w:bCs/>"))
        #expect(valueParagraph.contains("<w:sz w:val=\"24\"/>"))
        #expect(valueParagraph.contains("<w:szCs w:val=\"24\"/>"))
    }
    #expect(attendeesHeadingParagraph.contains("w:jc w:val=\"center\""))
    #expect(attendeesHeadingParagraph.contains("w:color w:val=\"64748B\""))
    #expect(firstAttendeeParagraph.contains("w:jc w:val=\"start\""))
    #expect(firstAttendeeParagraph.contains("<w:bidi/>"))
    #expect(firstAttendeeParagraph.contains("<w:rtl/>"))
    #expect(firstAttendeeParagraph.contains("<w:pStyle w:val=\"InspectorCoverAttendeeNumber\"/>"))
    #expect(firstAttendeeParagraph.contains("<w:numId w:val=\"2\"/>"))
    #expect(firstAttendeeParagraph.contains("<w:ind w:start=\"900\" w:hanging=\"480\"/>"))
    #expect(secondAttendeeParagraph.contains("<w:numId w:val=\"2\"/>"))
    #expect(firstAttendeeParagraph.contains("w:color w:val=\"111827\""))
    #expect(xml.contains(">אלון<"))
    #expect(xml.contains(">דפנה<"))
    #expect(!xml.contains(OpenXMLBuilder.escapeXML("1.\u{00A0}אלון")))
    #expect(!xml.contains(OpenXMLBuilder.escapeXML("2.\u{00A0}דפנה")))
    #expect(xml.contains(">הערות<"))
    #expect(xml.contains(">נדרש תיקון<"))
    #expect(notesContentParagraph.contains("w:jc w:val=\"center\""))
}

@Test func docxCoverDetailsOmitsAttendeesSectionWhenValueIsMissing() {
    let xml = DocxTemplateBuilder.coverDetailsXML(
        address: "כפר ויתקין",
        date: "6.4.2026",
        defectCount: 5,
        attendees: nil,
        notes: "נדרש תיקון"
    )

    #expect(!xml.contains(">נוכחים:<"))
    #expect(!xml.contains("1F4E79"))
}

@Test func docxCoverDetailsOmitsNotesSectionWhenValueIsMissing() {
    let xml = DocxTemplateBuilder.coverDetailsXML(
        address: "כפר ויתקין",
        date: "6.4.2026",
        defectCount: 5,
        attendees: nil,
        notes: nil
    )

    #expect(xml.contains(">כתובת<"))
    #expect(xml.contains(">תאריך<"))
    #expect(!xml.contains(">הערות<"))
    #expect(!xml.contains(">—<"))
}

@Test func docxCoverDetailsIncludesOpenDefectCountAsSingleCombinedLine() throws {
    let xml = DocxTemplateBuilder.coverDetailsXML(
        address: "כפר ויתקין",
        date: "6.4.2026",
        defectCount: 109,
        attendees: nil,
        notes: nil
    )

    let defectText = OpenXMLBuilder.escapeXML(
        ExportTextFormatter.rtlHeadingText("\(AppStrings.text("מספר ליקויים פתוחים")): 109")
    )
    #expect(xml.contains(defectText))

    // The summary is one combined, centered paragraph carrying the count.
    let defectParagraph = try #require(
        xml.components(separatedBy: "<w:p>").first { $0.contains(defectText) }
    )
    #expect(defectParagraph.contains("w:jc w:val=\"center\""))
    #expect(defectParagraph.contains("<w:sz w:val=\"24\"/>"))
    // Rendered red and not bold.
    #expect(defectParagraph.contains("w:color w:val=\"D32F2F\""))
    #expect(!defectParagraph.contains("<w:b/>"))

    // Cover deliberately avoids directional isolate characters.
    #expect(!xml.contains("\u{2066}"))
    #expect(!xml.contains("\u{2067}"))
    #expect(!xml.contains("\u{2069}"))
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
        imageColumnWidthTwips: 5000,
        textColumnWidthTwips: 3300
    )

    #expect(row.contains("w:color w:val=\"1F4E79\"") == false)
    #expect(row.contains("<w:t xml:space=\"preserve\">1</w:t>") == false)
    #expect(row.contains(OpenXMLBuilder.escapeXML("\u{202B}1. כללי:\u{202C}")))
    #expect(row.contains("<w:pStyle w:val=\"InspectorDescriptionBullet\"/>"))
    #expect(row.contains("<w:numPr>"))
    #expect(row.contains(">בסלון נראים ברגים לבנים</w:t>"))
    #expect(!row.contains(OpenXMLBuilder.escapeXML("\u{202B}•\u{00A0}בסלון נראים ברגים לבנים\u{202C}")))
}

@Test func docxFooterUsesSeparateRunsForPrimaryLine() {
    let fields = BrandingPrimaryFooterFields(
        contactName: "אבישי",
        roleLabel: "דוא\"ל",
        phoneNumber: "054-6222577",
        emailAddress: "iter@iter.co.il"
    )
    let branding = ResolvedExportBranding(
        companyName: "",
        logoImageData: nil,
        footerAddressLine: BrandingFooterFormatter.normalizeAddressLine("כפר ויתקין, ת\"ד 635"),
        primaryFooterLinePDF: BrandingFooterFormatter.normalizeFreeformLine(BrandingFooterFormatter.composePrimaryLine(fields)),
        primaryFooterLineDOCX: BrandingFooterFormatter.normalizeFreeformLine(BrandingFooterFormatter.composePrimaryLine(fields)),
        secondaryFooterLine: "",
        footerAddressRuns: BrandingFooterFormatter.addressRuns(from: "כפר ויתקין, ת\"ד 635"),
        primaryFooterRuns: BrandingFooterFormatter.primaryRuns(fields),
        secondaryFooterRuns: [],
        primaryFooterDisplayRuns: BrandingFooterFormatter.primaryDisplayRuns(fields),
        secondaryFooterDisplayRuns: []
    )
    let footer = DocxTemplateBuilder.footerXML(branding: branding)
    #expect(footer.contains("<w:bidi/>"))
    #expect(footer.contains(">iter@iter.co.il</w:t>"))
    #expect(footer.contains(">מייל</w:t>") || footer.contains(">דוא&quot;ל</w:t>"))
    #expect(footer.contains(">054-6222577</w:t>"))
    #expect(footer.contains(">אבישי</w:t>"))
    #expect(!footer.contains("אבישי 054-6222577 מייל iter@iter.co.il"))
    #expect(footer.firstRange(of: "iter@iter.co.il")!.lowerBound < footer.firstRange(of: "054-6222577")!.lowerBound)
}

@Test func docxHeaderXMLDoesNotRenderCompanyName() {
    let xmlWithoutLogo = DocxTemplateBuilder.headerXML(includesLogo: false)
    let xmlWithLogo = DocxTemplateBuilder.headerXML(includesLogo: true)

    #expect(!xmlWithoutLogo.contains("Acme Ltd"))
    #expect(!xmlWithoutLogo.contains("<w:bidi/>"))
    #expect(!xmlWithoutLogo.contains("<w:rtl/>"))
    #expect(!xmlWithLogo.contains("<w:bidi/>"))
    #expect(!xmlWithLogo.contains("<w:rtl/>"))
}

@Test func docxHeaderXMLPreservesLogoAspectRatio() {
    let xml = DocxTemplateBuilder.headerXML(
        includesLogo: true,
        logoWidthEMU: 952500,
        logoHeightEMU: 476250
    )

    #expect(xml.contains("<wp:extent cx=\"952500\" cy=\"476250\"/>"))
    #expect(xml.contains("<a:ext cx=\"952500\" cy=\"476250\"/>"))
}

@Test func docxFooterOmitsEmptySecondaryLine() {
    let branding = ResolvedExportBranding(
        companyName: "Test Company",
        logoImageData: ResolvedExportBranding.legacyDefault.logoImageData,
        footerAddressLine: "Address",
        primaryFooterLinePDF: "Primary",
        primaryFooterLineDOCX: "Primary",
        secondaryFooterLine: "",
        footerAddressRuns: BrandingFooterFormatter.addressRuns(from: "Address"),
        primaryFooterRuns: BrandingFooterFormatter.primaryRuns(
            BrandingPrimaryFooterFields(contactName: "אבישי", phoneNumber: "054-6222577")
        ),
        secondaryFooterRuns: [],
        primaryFooterDisplayRuns: BrandingFooterFormatter.primaryDisplayRuns(
            BrandingPrimaryFooterFields(contactName: "אבישי", phoneNumber: "054-6222577")
        ),
        secondaryFooterDisplayRuns: []
    )

    let footer = DocxTemplateBuilder.footerXML(branding: branding)

    #expect(footer.contains(">Address<"))
    #expect(footer.contains(">054-6222577</w:t>"))
    #expect(footer.contains(">אבישי</w:t>"))
    #expect(!footer.contains("09-8665885"))
    #expect(footer.components(separatedBy: "<w:p>").count - 1 == 2)
}

@Test func brandingFooterFormatterNormalizesAddressNumbersForRTL() {
    let normalized = BrandingFooterFormatter.normalizeAddressLine("תל אביב, ת\"ד 635 מיקוד 4020000")
    #expect(normalized == "תל אביב, ת\"ד ‎635‎ מיקוד ‎4020000‎")
}

@Test func brandingFooterFormatterParsesLegacyPrimaryFooterLines() {
    // Logical order: name phone role email
    let pdfLine = "אבישי 054-6222577 דוא\"ל iter@iter.co.il"
    // Reversed order (DOCX RTL): email role phone name
    let docxLine = "‎iter@iter.co.il‎ מייל ‎054-6222577‎ אבישי"

    let fromPDF = BrandingFooterFormatter.parsePrimaryLogicalLine(pdfLine)
    let fromDOCX = BrandingFooterFormatter.parsePrimaryReversedLine(docxLine)

    #expect(fromPDF != nil)
    #expect(fromDOCX != nil)
    #expect(fromPDF?.contactName == "אבישי")
    #expect(fromPDF?.phoneNumber == "054-6222577")
    #expect(fromDOCX?.contactName == "אבישי")
    #expect(fromDOCX?.phoneNumber == "054-6222577")
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

@Test func resolvedExportBrandingReturnsEmptyWithoutProfile() {
    let report = Report(name: "Fallback")

    let branding = ResolvedExportBranding.resolve(for: report)

    #expect(branding.companyName == "")
    #expect(branding.footerAddressLine == "")
    #expect(branding.primaryFooterLinePDF == "")
    #expect(branding.primaryFooterLineDOCX == "")
    #expect(branding.secondaryFooterLine == "")
    #expect(branding.logoImageData == nil)
    #expect(!branding.hasVisibleFooterContent)
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
    let report = Report(name: "Branded", brandingProfile: brandingProfile)

    let branding = ResolvedExportBranding.resolve(for: report)

    #expect(branding.companyName == "Client")
    #expect(branding.footerAddressLine == "Custom address")
    #expect(branding.primaryFooterLinePDF == "Custom pdf line")
    #expect(branding.primaryFooterLineDOCX == "Custom docx line")
    #expect(branding.secondaryFooterLine == "Custom secondary line")
    #expect(branding.logoImageData != nil)
}

@Test func resolvedExportBrandingTreatsEmptyDefaultProfileAsUnbranded() {
    let brandingProfile = DefaultBrandingProfile.makeBrandingProfile()
    let report = Report(name: "Default", brandingProfile: brandingProfile)

    let branding = ResolvedExportBranding.resolve(for: report)

    #expect(branding.logoImageData == nil)
    #expect(branding.footerAddressLine.isEmpty)
    #expect(branding.primaryFooterLinePDF.isEmpty)
    #expect(branding.primaryFooterLineDOCX.isEmpty)
    #expect(branding.secondaryFooterLine.isEmpty)
    #expect(branding.hasVisibleFooterContent == false)
}

@Test func brandingProfileDefaultsToVisibleLogoAndFooter() {
    let brandingProfile = BrandingProfile(
        name: "Client",
        footerAddressLine: "Address",
        primaryFooterLinePDF: "Primary",
        primaryFooterLineDOCX: "Primary",
        secondaryFooterLine: "Secondary"
    )

    #expect(brandingProfile.showLogoInReport == true)
    #expect(brandingProfile.showFooterInReport == true)
}

@Test func resolvedExportBrandingHidesLogoAndFooterWhenDisabled() {
    let brandingProfile = BrandingProfile(
        name: "Client",
        isDefault: false,
        usesBundledDefaultLogo: true,
        showLogoInReport: false,
        showFooterInReport: false,
        footerAddressLine: "Address",
        primaryFooterLinePDF: "Primary",
        primaryFooterLineDOCX: "Primary",
        secondaryFooterLine: "Secondary"
    )
    let report = Report(name: "Branded", brandingProfile: brandingProfile)

    let branding = ResolvedExportBranding.resolve(for: report)

    #expect(branding.logoImageData == nil)
    #expect(branding.footerAddressLine.isEmpty)
    #expect(branding.primaryFooterLinePDF.isEmpty)
    #expect(branding.primaryFooterLineDOCX.isEmpty)
    #expect(branding.secondaryFooterLine.isEmpty)
    #expect(branding.primaryFooterDisplayRuns.isEmpty)
    #expect(branding.secondaryFooterDisplayRuns.isEmpty)
    #expect(branding.hasVisibleFooterContent == false)
}

@Test func resolvedExportBrandingOmitsLogoWhenCustomLogoIsMissing() {
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
    let report = Report(name: "Branded", brandingProfile: brandingProfile)

    let branding = ResolvedExportBranding.resolve(for: report)

    #expect(branding.logoImageData == nil)
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

    let report = Report(name: "Branded", brandingProfile: brandingProfile)
    let branding = ResolvedExportBranding.resolve(for: report)

    #expect(branding.logoImageData != nil)
    #expect(branding.logoImageData != ResolvedExportBranding.legacyDefault.logoImageData)
}

@Test func exportErrorsUseStableUserFacingMessages() {
    #expect(ExportError.noPhotos.errorDescription == AppStrings.text("אין תמונות לייצוא"))
    #expect(ExportError.imageLoadFailed("tests/missing.jpg").errorDescription == AppStrings.text("אחת מתמונות הדוח לא נטענה"))
    #expect(ExportError.pdfGenerationFailed.errorDescription == AppStrings.text("ייצוא PDF נכשל. נסה שוב."))
    #expect(ExportError.docxGenerationFailed("missing template part").errorDescription == AppStrings.text("ייצוא DOCX נכשל. נסה שוב."))
    #expect(ExportError.templateMissing.errorDescription == AppStrings.text("ייצוא DOCX נכשל. נסה שוב."))
}

@Test func pdfExporterFailsWhenPhotoImageIsMissing() async throws {
    let report = Report(name: "Missing image")
    let photo = PhotoRecord(imagePath: "tests/missing-\(UUID().uuidString).jpg")
    photo.report = report
    report.photos = [photo]

    do {
        _ = try await PdfExporter.export(
            report: report,
            photos: [photo],
            options: ExportOptions(format: .pdf, quality: .economical, photoCount: 1),
            onProgress: { _ in }
        )
        Issue.record("Expected missing PDF image export to fail")
    } catch let error as ExportError {
        if case .imageLoadFailed(let path) = error {
            #expect(path == photo.imagePath)
        } else {
            Issue.record("Expected imageLoadFailed, got \(error)")
        }
    }
}

@Test func pdfExporterGeneratesCoverWithShortSecondAttendeeName() async throws {
    let date = DateComponents(
        calendar: Calendar(identifier: .gregorian),
        year: 2026,
        month: 6,
        day: 30
    ).date!
    let report = Report(
        name: "Attendee Alignment",
        address: "גרציאני",
        date: date,
        attendees: variedAttendeesText
    )
    let url = try await PdfExporter.export(
        report: report,
        photos: [],
        options: ExportOptions(format: .pdf, quality: .economical, photoCount: 0),
        onProgress: { _ in }
    )
    let environment = ProcessInfo.processInfo.environment
    let keepSample = environment["KEEP_ATTENDEE_ALIGNMENT_PDF"] == "1"
        || environment["TEST_RUNNER_KEEP_ATTENDEE_ALIGNMENT_PDF"] == "1"
    defer {
        if !keepSample {
            try? FileManager.default.removeItem(at: url)
        }
    }

    #expect(FileManager.default.fileExists(atPath: url.path))
    #expect(url.pathExtension == "pdf")
}

@Test func docxExporterGeneratesCoverWithRTLAttendeeMarkers() async throws {
    let date = DateComponents(
        calendar: Calendar(identifier: .gregorian),
        year: 2026,
        month: 6,
        day: 30
    ).date!
    let report = Report(
        name: "Attendee Alignment",
        address: "גרציאני",
        date: date,
        attendees: variedAttendeesText
    )
    let url = try await DocxExporter.export(
        report: report,
        photos: [],
        options: ExportOptions(format: .docx, quality: .economical, photoCount: 0),
        onProgress: { _ in }
    )
    let environment = ProcessInfo.processInfo.environment
    let keepSample = environment["KEEP_ATTENDEE_ALIGNMENT_DOCX"] == "1"
        || environment["TEST_RUNNER_KEEP_ATTENDEE_ALIGNMENT_DOCX"] == "1"
    defer {
        if !keepSample {
            try? FileManager.default.removeItem(at: url)
        }
    }

    let xmlEntries = try docxXMLEntries(from: url)
    let documentXMLData = try #require(xmlEntries["word/document.xml"])
    let documentText = try #require(String(data: documentXMLData, encoding: .utf8))
    #expect(!documentText.contains("<w:bidiVisual/>"))
    #expect(!documentText.contains("<w:tblpPr"))
    #expect(documentText.contains("<w:tblW w:w=\"2800\" w:type=\"dxa\"/>"))
    #expect(documentText.contains("<w:gridCol w:w=\"2800\"/>"))
    #expect(documentText.contains("<w:right w:w=\"320\" w:type=\"dxa\"/>"))
    #expect(!documentText.contains("<w:gridCol w:w=\"2760\"/>"))
    #expect(!documentText.contains("<w:gridCol w:w=\"480\"/>"))
    #expect(!documentText.contains("<w:tab"))
    #expect(documentText.contains("<w:pStyle w:val=\"InspectorCoverAttendeeNumber\"/>"))
    #expect(documentText.contains("<w:numId w:val=\"2\"/>"))
    #expect(documentText.contains("<w:ind w:start=\"900\" w:hanging=\"480\"/>"))
    #expect(documentText.contains(">א<"))
    #expect(documentText.contains(">שם עשירי<"))
    #expect(documentText.contains(">משה כהן לוי ארוך מאוד<"))
    #expect(!documentText.contains(OpenXMLBuilder.escapeXML("1.\u{00A0}א")))
    #expect(url.pathExtension == "docx")
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
    #expect(docxOptions.targetPhotoImageHeight == docxOptions.targetPhotoRowHeight - (ExportImageConstants.imageCellPaddingPoints * 2))
    #expect(docxOptions.docxTableLayoutSafetyPaddingTwips == 360)

    let docxContentHeightTwips = Int(docxOptions.contentHeight * 20.0)
    let headerHeightTwips = Int(docxOptions.tableHeaderHeight * 20.0)
    let rowsHeightTwips = docxOptions.targetPhotoRowHeightTwips * docxOptions.photosPerPage
    let tableUsedHeightTwips = headerHeightTwips + rowsHeightTwips

    #expect(tableUsedHeightTwips <= (docxContentHeightTwips - docxOptions.docxTableLayoutSafetyPaddingTwips))
    #expect(docxOptions.maximumImageContentHeight == docxOptions.targetPhotoImageHeight)
}

@Test func pdfKeepsTwoPhotosPerPageWithReservedHeaderFooterSpace() {
    let pdfOptions = ExportOptions(
        format: .pdf,
        quality: .balanced,
        photoCount: 20
    )

    let rowsHeight = pdfOptions.targetPhotoRowHeight * pdfOptions.photoRowsPerPage
    let tableUsedHeight = pdfOptions.tableHeaderHeight + rowsHeight

    #expect(pdfOptions.tableLayoutSafetyPadding == 0)
    #expect(tableUsedHeight <= pdfOptions.contentHeight)
    #expect(pdfOptions.targetPhotoImageHeight == pdfOptions.targetPhotoRowHeight - (ExportImageConstants.imageCellPaddingPoints * 2))
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

    #expect(options.exportImageMaxBytes == 63_492)
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
        address: "כפר ויתקין"
    )
    let report = Report(
        name: "בדיקת יצוא",
        date: Date(timeIntervalSince1970: 1_700_000_000),
        attendees: "אלון\nדפנה",
        notes: "תקין",
        project: project
    )
    let photo = PhotoRecord(
        imagePath: imagePath,
        freeText: "שורת בדיקה",
        position: 0
    )
    photo.report = report
    report.photos = [photo]

    let options = ExportOptions(
        format: .docx,
        quality: .balanced,
        photoCount: 1
    )

    let outputURL = try await DocxExporter.export(
        report: report,
        photos: [photo],
        options: options,
        branding: .legacyDefault,
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
    #expect(xmlEntries["word/numbering.xml"] != nil)
    #expect(xmlEntries["word/header1.xml"] != nil)
    #expect(xmlEntries["word/footer1.xml"] != nil)
    #expect(xmlEntries["word/_rels/header1.xml.rels"] != nil)

    let contentTypesText = xmlEntries["[Content_Types].xml"]
        .flatMap { String(data: $0, encoding: .utf8) } ?? ""
    #expect(contentTypesText.contains("PartName=\"/word/numbering.xml\""))

    let documentRelsText = xmlEntries["word/_rels/document.xml.rels"]
        .flatMap { String(data: $0, encoding: .utf8) } ?? ""
    #expect(documentRelsText.contains("relationships/numbering"))
    #expect(documentRelsText.contains("Target=\"numbering.xml\""))
    #expect(documentRelsText.contains("relationships/header"))
    #expect(documentRelsText.contains("relationships/footer"))
    #expect(documentRelsText.contains("relationships/image"))
    #expect(documentRelsText.contains("Target=\"media/image10.jpg\""))

    let numberingText = xmlEntries["word/numbering.xml"]
        .flatMap { String(data: $0, encoding: .utf8) } ?? ""
    #expect(numberingText.contains("<w:abstractNum w:abstractNumId=\"1\">"))
    #expect(numberingText.contains("<w:numFmt w:val=\"bullet\"/>"))
    #expect(numberingText.contains("<w:suff w:val=\"space\"/>"))
    #expect(numberingText.contains("<w:lvlText w:val=\"•\"/>"))
    #expect(numberingText.contains("<w:ind w:start=\"540\" w:hanging=\"360\"/>"))
    #expect(numberingText.contains("<w:jc w:val=\"start\"/>"))
    #expect(!numberingText.contains("<w:ind w:left="))
    #expect(!numberingText.contains("<w:ind w:right="))
    #expect(!numberingText.contains("<w:tab w:val=\"num\""))
    #expect(numberingText.contains("<w:num w:numId=\"1\">"))

    let headerRelsText = xmlEntries["word/_rels/header1.xml.rels"]
        .flatMap { String(data: $0, encoding: .utf8) } ?? ""
    #expect(headerRelsText.contains("Target=\"media/image1.jpeg\""))

    #expect(xmlEntries["word/footer1.xml"] != nil)

    let documentText = xmlEntries["word/document.xml"]
        .flatMap { String(data: $0, encoding: .utf8) } ?? ""
    #expect(!documentText.contains("\u{2066}"))
    #expect(!documentText.contains("\u{2067}"))
    #expect(!documentText.contains("\u{2069}"))
    #expect(documentText.contains("<w:pStyle w:val=\"InspectorDescriptionBullet\"/>"))
    #expect(documentText.contains("<w:numPr>"))
    #expect(documentText.contains("<w:numId w:val=\"1\"/>"))
    #expect(documentText.contains("<w:bidi/>"))
    #expect(documentText.contains("<w:rtl/>"))
    #expect(documentText.contains("<w:ind w:start=\"540\" w:hanging=\"360\"/>"))
    #expect(documentText.contains("<w:jc w:val=\"start\"/>"))
    #expect(!documentText.contains("<w:ind w:left="))
    #expect(!documentText.contains("<w:ind w:right="))
    #expect(!documentText.contains("<w:tab w:val=\"num\""))
    #expect(documentText.contains(">כתובת<"))
    #expect(documentText.contains(">כפר ויתקין<"))
    #expect(documentText.contains(">\(ExportTextFormatter.reportCoverDateString(from: report.date))<"))
    #expect(documentText.contains(OpenXMLBuilder.escapeXML(ExportTextFormatter.rtlHeadingText("נוכחים:"))))
    #expect(!documentText.contains("<w:bidiVisual/>"))
    #expect(!documentText.contains("<w:tblpPr"))
    #expect(documentText.contains("<w:tblW w:w=\"2800\" w:type=\"dxa\"/>"))
    #expect(documentText.contains("<w:gridCol w:w=\"2800\"/>"))
    #expect(documentText.contains("<w:right w:w=\"320\" w:type=\"dxa\"/>"))
    #expect(!documentText.contains("<w:gridCol w:w=\"2760\"/>"))
    #expect(!documentText.contains("<w:gridCol w:w=\"480\"/>"))
    #expect(documentText.contains("<w:pStyle w:val=\"InspectorCoverAttendeeNumber\"/>"))
    #expect(documentText.contains("<w:numId w:val=\"2\"/>"))
    #expect(documentText.contains("<w:ind w:start=\"900\" w:hanging=\"480\"/>"))
    #expect(documentText.contains(">אלון<"))
    #expect(documentText.contains(">דפנה<"))
    #expect(!documentText.contains(OpenXMLBuilder.escapeXML("1.\u{00A0}אלון")))
    #expect(documentText.contains(">הערות<"))
    #expect(documentText.contains(">תקין<"))
    #expect(documentText.contains(">שורת בדיקה</w:t>"))
    #expect(!documentText.contains("<w:t xml:space=\"preserve\">•"))
    // Framed report placement must not use DOCX crop metadata.
    #expect(!documentText.contains("<a:srcRect"))

    let expectedExportImage = try FlattenedExportImageRenderer.render(photo: photo, options: options)
    let embeddedImageData = try docxEntryData(from: outputURL, path: "word/media/image10.jpg")
    #expect(embeddedImageData == expectedExportImage.data)
}

@Test func docxExporterProducesWellFormedXMLPartsWithoutLogo() async throws {
    FileManagerService.shared.ensureDirectoriesExist()

    let image = UIGraphicsImageRenderer(size: CGSize(width: 1200, height: 900)).image { context in
        UIColor.systemIndigo.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 1200, height: 900))
    }
    guard let jpeg = image.jpegData(compressionQuality: 0.8) else {
        Issue.record("Failed creating no-logo fixture image")
        return
    }

    let imagePath = "tests/export-fixture-no-logo.jpg"
    let imageURL = AppConstants.imagesBaseURL.appendingPathComponent(imagePath)
    try FileManager.default.createDirectory(
        at: imageURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try jpeg.write(to: imageURL)
    defer { try? FileManager.default.removeItem(at: imageURL) }

    let project = Project(
        name: "בדיקת יצוא ללא לוגו",
        address: "כפר ויתקין"
    )
    let report = Report(
        name: "בדיקת יצוא ללא לוגו",
        date: Date(timeIntervalSince1970: 1_700_000_000),
        notes: "תקין",
        project: project
    )
    let photo = PhotoRecord(
        imagePath: imagePath,
        freeText: "שורת בדיקה",
        position: 0
    )
    photo.report = report
    report.photos = [photo]

    let branding = ResolvedExportBranding(
        companyName: ResolvedExportBranding.legacyDefault.companyName,
        logoImageData: nil,
        footerAddressLine: ResolvedExportBranding.legacyDefault.footerAddressLine,
        primaryFooterLinePDF: ResolvedExportBranding.legacyDefault.primaryFooterLinePDF,
        primaryFooterLineDOCX: ResolvedExportBranding.legacyDefault.primaryFooterLineDOCX,
        secondaryFooterLine: ResolvedExportBranding.legacyDefault.secondaryFooterLine,
        footerAddressRuns: ResolvedExportBranding.legacyDefault.footerAddressRuns,
        primaryFooterRuns: ResolvedExportBranding.legacyDefault.primaryFooterRuns,
        secondaryFooterRuns: ResolvedExportBranding.legacyDefault.secondaryFooterRuns,
        primaryFooterDisplayRuns: ResolvedExportBranding.legacyDefault.primaryFooterDisplayRuns,
        secondaryFooterDisplayRuns: ResolvedExportBranding.legacyDefault.secondaryFooterDisplayRuns
    )
    let options = ExportOptions(
        format: .docx,
        quality: .balanced,
        photoCount: 1
    )

    let outputURL = try await DocxExporter.export(
        report: report,
        photos: [photo],
        options: options,
        branding: branding,
        onProgress: { _ in }
    )
    defer { try? FileManager.default.removeItem(at: outputURL) }

    let xmlEntries = try docxXMLEntries(from: outputURL)

    for (path, data) in xmlEntries {
        let parser = XMLParser(data: data)
        #expect(parser.parse(), "XML parse failed for \(path): \(parser.parserError?.localizedDescription ?? "Unknown error")")
    }

    let headerText = xmlEntries["word/header1.xml"]
        .flatMap { String(data: $0, encoding: .utf8) } ?? ""
    #expect(!headerText.contains("<w:drawing>"))
    #expect(!headerText.contains("r:embed=\"rId1\""))
    #expect(!headerText.contains(ResolvedExportBranding.legacyDefault.companyName))

    let headerRelsText = xmlEntries["word/_rels/header1.xml.rels"]
        .flatMap { String(data: $0, encoding: .utf8) } ?? ""
    #expect(!headerRelsText.contains("Target=\"media/image1.jpeg\""))
}

@Test func brandingResolvesLocalProfileFirst() {
    let profile = BrandingProfile(
        name: "Test Company",
        isDefault: true,
        usesBundledDefaultLogo: true,
        showLogoInReport: true,
        showFooterInReport: true,
        footerAddressLine: "123 Test St",
        primaryFooterLinePDF: "",
        primaryFooterLineDOCX: "",
        secondaryFooterLine: ""
    )
    let report = Report(name: "Test Report")
    report.brandingProfile = profile

    let resolved = ResolvedExportBranding.resolve(for: report)
    #expect(resolved.companyName == "Test Company")
}

@Test func brandingResolvesEmptyWhenNoProfile() {
    let report = Report(name: "No Branding Report")
    // brandingProfile intentionally nil

    let resolved = ResolvedExportBranding.resolve(for: report)
    #expect(resolved.companyName == "")
    #expect(resolved.logoImageData == nil)
    #expect(!resolved.hasVisibleFooterContent)
}

@Test func docxExporterRemovesStaleWordLockFile() async throws {
    FileManagerService.shared.ensureDirectoriesExist()

    let outputDir = AppConstants.exportsURL
    try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
    let uniqueTag = String(UUID().uuidString.prefix(8))
    let projectName = "Lock Test \(uniqueTag)"

    let project = Project(
        name: projectName,
        address: "Address"
    )
    let report = Report(
        name: projectName,
        date: Date(timeIntervalSince1970: 1_700_000_000),
        notes: "Notes",
        project: project
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
        report: report,
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

@Test func exportOptionsUseBalancedReportColumnRatio() {
    let options = ExportOptions(format: .docx, quality: .balanced, photoCount: 1)

    #expect(options.imageColumnRatio == 0.60)
    #expect(options.textColumnRatio == 0.40)
    #expect(options.imageColumnWidth == options.contentWidth * 0.60)
    #expect(options.textColumnWidth == options.contentWidth * 0.40)
    #expect(options.imageColumnWidthTwips == Int(options.contentWidth * 0.60 * 20.0))
    #expect(options.textColumnWidthTwips == Int(options.contentWidth * 0.40 * 20.0))
    #expect(options.imageColumnWidthEMU == Int(Double(options.contentWidthEMU) * 0.60))
    #expect(options.textColumnWidthEMU == Int(Double(options.contentWidthEMU) * 0.40))
    #expect(ExportImageConstants.imageCellPaddingPoints == 4)
    #expect(ExportImageConstants.imageCellPaddingTwips == 80)
    #expect(ExportImageConstants.imageCellPaddingEMU == 50_800)
}

@Test func exportImageGeometrySupportsAspectFitPlacementAndCoordinateMapping() {
    let boundingRect = CGRect(x: 10, y: 20, width: 300, height: 200)

    let landscape = ExportImageGeometry.centeredAspectFitRect(
        sourceSize: CGSize(width: 1200, height: 900),
        in: boundingRect
    )
    #expect(abs(landscape.width - 266.67) < 0.01)
    #expect(landscape.height == 200)
    #expect(abs(landscape.minX - 26.67) < 0.01)
    #expect(landscape.minY == 20)

    let portrait = ExportImageGeometry.centeredAspectFitRect(
        sourceSize: CGSize(width: 900, height: 1200),
        in: boundingRect
    )
    #expect(portrait.width == 150)
    #expect(portrait.height == 200)
    #expect(portrait.minX == 85)
    #expect(portrait.minY == 20)

    let square = ExportImageGeometry.centeredAspectFitRect(
        sourceSize: CGSize(width: 1000, height: 1000),
        in: boundingRect
    )
    #expect(square.width == 200)
    #expect(square.height == 200)
    #expect(square.minX == 60)
    #expect(square.minY == 20)

    let invalid = ExportImageGeometry.centeredAspectFitRect(
        sourceSize: .zero,
        in: boundingRect
    )
    #expect(invalid == .zero)

    let normalized = ExportImageGeometry.normalizedPoint(CGPoint(x: 160, y: 120), in: boundingRect)
    #expect(abs(normalized.x - 0.5) < 0.001)
    #expect(abs(normalized.y - 0.5) < 0.001)

    let denormalized = ExportImageGeometry.denormalizedPoint(normalized, in: boundingRect)
    #expect(abs(denormalized.x - 160) < 0.001)
    #expect(abs(denormalized.y - 120) < 0.001)

    let clamped = ExportImageGeometry.normalizedPoint(CGPoint(x: -10, y: 500), in: boundingRect)
    #expect(clamped.x == 0)
    #expect(clamped.y == 1)

    let tallBoundingRect = CGRect(x: 10, y: 20, width: 300, height: 400)
    let widthFilledLandscape = ExportImageGeometry.centeredWidthFillRect(
        sourceSize: CGSize(width: 1200, height: 900),
        in: tallBoundingRect
    )
    #expect(widthFilledLandscape.width == 300)
    #expect(widthFilledLandscape.height == 225)

    let widthFilledPortrait = ExportImageGeometry.centeredWidthFillRect(
        sourceSize: CGSize(width: 900, height: 1200),
        in: tallBoundingRect
    )
    #expect(widthFilledPortrait.width == 300)
    #expect(widthFilledPortrait.height == 400)

    let heightLimitedPortrait = ExportImageGeometry.centeredWidthFillRect(
        sourceSize: CGSize(width: 900, height: 1200),
        in: boundingRect
    )
    #expect(heightLimitedPortrait.width == 150)
    #expect(heightLimitedPortrait.height == 200)
}

@Test func annotationGeometryFitsPortraitLandscapeAndTallImagesInsideFixedViewport() {
    let containerSize = CGSize(width: 360, height: 310)
    let cases = [
        CGSize(width: 1200, height: 900),
        CGSize(width: 900, height: 1200),
        CGSize(width: 600, height: 2400),
    ]

    for imageSize in cases {
        let frame = AnnotationGeometry.aspectFitFrame(for: imageSize, in: containerSize)
        let expectedAspectRatio = imageSize.width / imageSize.height
        let actualAspectRatio = frame.width / frame.height

        #expect(frame.minX >= -0.001)
        #expect(frame.minY >= -0.001)
        #expect(frame.maxX <= containerSize.width + 0.001)
        #expect(frame.maxY <= containerSize.height + 0.001)
        #expect(abs(actualAspectRatio - expectedAspectRatio) < 0.001)
        #expect(abs(frame.midX - (containerSize.width / 2)) < 0.001)
        #expect(abs(frame.midY - (containerSize.height / 2)) < 0.001)
    }
}

@Test func annotationGeometryRoundTripsCoordinatesThroughLetterboxedEditorFrame() {
    let imageSize = CGSize(width: 1200, height: 600)
    let containerSize = CGSize(width: 300, height: 500)
    let displayFrame = AnnotationGeometry.aspectFitFrame(for: imageSize, in: containerSize)
    let visiblePoint = AnnotationGeometry.denormalizedPoint(
        CGPoint(x: 0.75, y: 0.25),
        in: displayFrame
    )

    #expect(displayFrame.width == 300)
    #expect(displayFrame.height == 150)
    #expect(displayFrame.minY == 175)

    let normalizedPoint = AnnotationGeometry.normalizedPoint(visiblePoint, in: displayFrame)
    #expect(abs(normalizedPoint.x - 0.75) < 0.001)
    #expect(abs(normalizedPoint.y - 0.25) < 0.001)

    let originalImagePoint = AnnotationGeometry.denormalizedPoint(
        normalizedPoint,
        in: CGRect(origin: .zero, size: imageSize)
    )
    #expect(abs(originalImagePoint.x - 900) < 0.001)
    #expect(abs(originalImagePoint.y - 150) < 0.001)

    let clampedPoint = AnnotationGeometry.normalizedPoint(
        CGPoint(x: displayFrame.minX - 40, y: displayFrame.maxY + 40),
        in: displayFrame
    )
    #expect(clampedPoint.x == 0)
    #expect(clampedPoint.y == 1)
}

@Test func annotationGeometryIsStableForHebrewRTLLayoutMode() {
    let imageSize = CGSize(width: 900, height: 1200)
    let containerSize = CGSize(width: 330, height: 260)
    let ltrFrame = AnnotationGeometry.aspectFitFrame(for: imageSize, in: containerSize)
    let rtlFrame = AnnotationGeometry.aspectFitFrame(for: imageSize, in: containerSize)

    #expect(ltrFrame == rtlFrame)
    #expect(AppStrings.text("סימון").isEmpty == false)
}

@Test func annotationRendererPlacesSavedMarkupAtThePreviewCoordinate() throws {
    let baseImage = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 100)).image { context in
        UIColor.white.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 200, height: 100))
    }
    let annotation = AnnotationElement(
        tool: .freehand,
        color: .red,
        lineWidthRatio: 0.08,
        points: [
            CGPoint(x: 0.35, y: 0.5),
            CGPoint(x: 0.65, y: 0.5),
        ]
    )

    let renderedImage = AnnotationImageRenderer.render(
        baseImage: baseImage,
        annotations: [annotation]
    )

    #expect(renderedImage.size == baseImage.size)

    let centerPixel = try #require(pixelRGBA(in: renderedImage, at: CGPoint(x: 100, y: 50)))
    #expect(centerPixel.red > 180)
    #expect(centerPixel.green < 90)
    #expect(centerPixel.blue < 90)

    let untouchedPixel = try #require(pixelRGBA(in: renderedImage, at: CGPoint(x: 100, y: 12)))
    #expect(untouchedPixel.red > 230)
    #expect(untouchedPixel.green > 230)
    #expect(untouchedPixel.blue > 230)
}

@Test func annotatedExportUsesFullSavedCompositeWithoutCroppingOrOffsettingMarkup() throws {
    FileManagerService.shared.ensureDirectoriesExist()
    let relativeDirectory = "tests/annotation-export-\(UUID().uuidString)"
    let originalPath = "\(relativeDirectory)/original.jpg"
    let annotatedPath = "\(relativeDirectory)/ann_original.jpg"
    let directoryURL = AppConstants.imagesBaseURL.appendingPathComponent(relativeDirectory)
    try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directoryURL) }

    let originalImage = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 100)).image { context in
        UIColor.white.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 200, height: 100))
    }
    let annotation = AnnotationElement(
        tool: .freehand,
        color: .red,
        lineWidthRatio: 0.08,
        points: [
            CGPoint(x: 0.35, y: 0.5),
            CGPoint(x: 0.65, y: 0.5),
        ]
    )
    let annotatedImage = AnnotationImageRenderer.render(
        baseImage: originalImage,
        annotations: [annotation]
    )

    try #require(originalImage.jpegData(compressionQuality: 0.95))
        .write(to: AppConstants.imagesBaseURL.appendingPathComponent(originalPath))
    try #require(annotatedImage.jpegData(compressionQuality: 0.95))
        .write(to: AppConstants.imagesBaseURL.appendingPathComponent(annotatedPath))

    let photo = PhotoRecord(imagePath: originalPath, annotatedImagePath: annotatedPath)
    let exportImage = try FlattenedExportImageRenderer.render(
        photo: photo,
        options: ExportOptions(format: .pdf, quality: .high, photoCount: 1)
    )

    #expect(exportImage.sourcePath == annotatedPath)
    #expect(exportImage.sourceKind == .annotated)
    #expect(abs((exportImage.image.size.width / exportImage.image.size.height) - 2.0) < 0.01)

    let centerPixel = try #require(
        pixelRGBA(
            in: exportImage.image,
            at: CGPoint(x: exportImage.image.size.width / 2, y: exportImage.image.size.height / 2)
        )
    )
    #expect(centerPixel.red > 160)
    #expect(centerPixel.green < 120)
    #expect(centerPixel.blue < 120)
}

@Test func docxExporterStretchesAllImageOrientationsToFullCellWithoutCropMetadata() async throws {
    FileManagerService.shared.ensureDirectoriesExist()

    func runExport(imageSize: CGSize, imagePath: String) async throws -> String {
        let image = UIGraphicsImageRenderer(size: imageSize).image { context in
            UIColor.systemGreen.setFill()
            context.fill(CGRect(origin: .zero, size: imageSize))
        }
        guard let jpeg = image.jpegData(compressionQuality: 0.8) else {
            Issue.record("Failed creating fixture image \(imagePath)")
            return ""
        }
        let imageURL = AppConstants.imagesBaseURL.appendingPathComponent(imagePath)
        try FileManager.default.createDirectory(
            at: imageURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try jpeg.write(to: imageURL)

        let project = Project(name: "Fit Test", address: "Test")
        let report = Report(name: "Fit Test", project: project)
        let photo = PhotoRecord(imagePath: imagePath, freeText: "", position: 0)
        photo.report = report
        report.photos = [photo]

        let options = ExportOptions(format: .docx, quality: .balanced, photoCount: 1)
        let outputURL = try await DocxExporter.export(
            report: report,
            photos: [photo],
            options: options,
            onProgress: { _ in }
        )
        let archive = try Archive(url: outputURL, accessMode: .read)
        var documentData = Data()
        for entry in archive where entry.path == "word/document.xml" {
            _ = try archive.extract(entry) { chunk in documentData.append(chunk) }
        }
        try? FileManager.default.removeItem(at: imageURL)
        try? FileManager.default.removeItem(at: outputURL)
        return String(data: documentData, encoding: .utf8) ?? ""
    }

    let landscapeDir = "tests/fit-landscape-\(UUID().uuidString)"
    let portraitDir = "tests/fit-portrait-\(UUID().uuidString)"
    let squareDir = "tests/fit-square-\(UUID().uuidString)"
    defer {
        try? FileManager.default.removeItem(at: AppConstants.imagesBaseURL.appendingPathComponent(landscapeDir))
        try? FileManager.default.removeItem(at: AppConstants.imagesBaseURL.appendingPathComponent(portraitDir))
        try? FileManager.default.removeItem(at: AppConstants.imagesBaseURL.appendingPathComponent(squareDir))
    }

    let options = ExportOptions(format: .docx, quality: .balanced, photoCount: 1)
    let landscapeXML = try await runExport(
        imageSize: CGSize(width: 1200, height: 900),
        imagePath: "\(landscapeDir)/landscape.jpg"
    )
    let portraitXML = try await runExport(
        imageSize: CGSize(width: 900, height: 1200),
        imagePath: "\(portraitDir)/portrait.jpg"
    )
    let squareXML = try await runExport(
        imageSize: CGSize(width: 1000, height: 1000),
        imagePath: "\(squareDir)/square.jpg"
    )

    // Report table images are stretched to the full cell without DOCX crop metadata.
    #expect(!landscapeXML.contains("<a:srcRect"))
    #expect(!portraitXML.contains("<a:srcRect"))
    #expect(!squareXML.contains("<a:srcRect"))

    // Rows shrink to content instead of reserving a fixed half-page block.
    #expect(!landscapeXML.contains("w:hRule=\"exact\""))
    #expect(!portraitXML.contains("w:hRule=\"exact\""))
    #expect(!squareXML.contains("w:hRule=\"exact\""))
    #expect(!landscapeXML.contains("<w:trHeight"))
    #expect(!portraitXML.contains("<w:trHeight"))
    #expect(!squareXML.contains("<w:trHeight"))

    // DOCX table column widths follow the same balanced 60/40 layout as PDF.
    #expect(landscapeXML.contains("<w:gridCol w:w=\"\(options.imageColumnWidthTwips)\"/>"))
    #expect(landscapeXML.contains("<w:gridCol w:w=\"\(options.textColumnWidthTwips)\"/>"))
    #expect(!landscapeXML.contains("<w:bidiVisual/>"))
    #expect(!portraitXML.contains("<w:bidiVisual/>"))
    #expect(!squareXML.contains("<w:bidiVisual/>"))

    func extractExtent(from xml: String) -> (cx: Double, cy: Double)? {
        guard let range = xml.range(of: #"<wp:extent cx="(\d+)" cy="(\d+)""#, options: .regularExpression),
              let cxRange = xml.range(of: #"(?<=cx=")\d+"#, options: .regularExpression, range: range),
              let cyRange = xml.range(of: #"(?<=cy=")\d+"#, options: .regularExpression, range: range),
              let cx = Double(xml[cxRange]),
              let cy = Double(xml[cyRange]) else { return nil }
        return (cx, cy)
    }

    func expectFullCellExtent(
        _ extent: (cx: Double, cy: Double)?,
        orientationName: String
    ) {
        guard let extent else {
            Issue.record("Missing DOCX image extent for \(orientationName)")
            return
        }

        let expected = (
            width: options.imageContentWidthEMU,
            height: options.targetPhotoImageHeightEMU
        )
        #expect(abs(extent.cx - Double(expected.width)) < 12_000, "\(orientationName) should occupy the full export width")
        #expect(abs(extent.cy - Double(expected.height)) < 12_000, "\(orientationName) should occupy the full export height")
    }

    expectFullCellExtent(
        extractExtent(from: landscapeXML),
        orientationName: "landscape"
    )
    expectFullCellExtent(
        extractExtent(from: portraitXML),
        orientationName: "portrait"
    )
    expectFullCellExtent(
        extractExtent(from: squareXML),
        orientationName: "square"
    )

    let portraitExtent = try #require(extractExtent(from: portraitXML))
    #expect(portraitExtent.cy <= Double(options.maximumImageContentHeightEMU) + 1_000)
    #expect(abs(portraitExtent.cx - Double(options.imageContentWidthEMU)) < 12_000, "portrait should occupy the full table image-cell width after export stretching")
}

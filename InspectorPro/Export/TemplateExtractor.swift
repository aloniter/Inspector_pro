import Foundation
import ZIPFoundation

/// Assets extracted from the bundled template.docx.
struct TemplateAssets {
    let logoImageData: Data
}

/// Extracts the logo image from the bundled template.docx.
final class TemplateExtractor {
    static func extract() throws -> TemplateAssets {
        guard let templateURL = Bundle.main.url(forResource: "template", withExtension: "docx") else {
            throw ExportError.templateMissing
        }

        guard let archive = Archive(url: templateURL, accessMode: .read) else {
            throw ExportError.templateMissing
        }

        return TemplateAssets(
            logoImageData: try extractEntry("word/media/image1.jpeg", from: archive)
        )
    }

    private static func extractEntry(_ path: String, from archive: Archive) throws -> Data {
        guard let entry = archive[path] else {
            throw ExportError.docxGenerationFailed("Missing template part: \(path)")
        }
        var data = Data()
        _ = try archive.extract(entry) { chunk in data.append(chunk) }
        return data
    }
}

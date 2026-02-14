import Foundation
import UIKit

enum ExportError: LocalizedError {
    case noPhotos
    case imageLoadFailed(String)
    case pdfGenerationFailed
    case docxGenerationFailed(String)
    case templateMissing

    var errorDescription: String? {
        switch self {
        case .noPhotos: return "No photos to export"
        case .imageLoadFailed(let path): return "Failed to load image: \(path)"
        case .pdfGenerationFailed: return "Failed to generate PDF"
        case .docxGenerationFailed(let reason): return "DOCX generation failed: \(reason)"
        case .templateMissing: return "DOCX template not found"
        }
    }
}

final class ExportEngine {
    /// Export a project report.
    /// - Parameters:
    ///   - project: The project to export
    ///   - photos: Sorted photos for the project
    ///   - options: Export options (format, quality)
    ///   - onProgress: Progress callback (0.0 to 1.0)
    /// - Returns: URL of the exported file
    static func exportReport(
        project: Project,
        photos: [PhotoRecord],
        options: ExportOptions,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        guard !photos.isEmpty else {
            throw ExportError.noPhotos
        }

        switch options.format {
        case .pdf:
            return try await PdfExporter.export(
                project: project,
                photos: photos,
                options: options,
                onProgress: onProgress
            )
        case .docx:
            return try await DocxExporter.export(
                project: project,
                photos: photos,
                options: options,
                onProgress: onProgress
            )
        }
    }
}

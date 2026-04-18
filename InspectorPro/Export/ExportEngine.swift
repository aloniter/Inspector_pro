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
        case .noPhotos:
            return AppStrings.text("אין תמונות לייצוא")
        case .imageLoadFailed:
            return AppStrings.text("אחת מתמונות הדוח לא נטענה")
        case .pdfGenerationFailed:
            return AppStrings.text("ייצוא PDF נכשל. נסה שוב.")
        case .docxGenerationFailed, .templateMissing:
            return AppStrings.text("ייצוא DOCX נכשל. נסה שוב.")
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
            do {
                return try await PdfExporter.export(
                    project: project,
                    photos: photos,
                    options: options,
                    onProgress: onProgress
                )
            } catch let error as ExportError {
                throw error
            } catch {
                throw ExportError.pdfGenerationFailed
            }
        case .docx:
            do {
                return try await DocxExporter.export(
                    project: project,
                    photos: photos,
                    options: options,
                    onProgress: onProgress
                )
            } catch let error as ExportError {
                throw error
            } catch {
                throw ExportError.docxGenerationFailed("")
            }
        }
    }
}

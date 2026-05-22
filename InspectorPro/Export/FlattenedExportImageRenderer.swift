import Foundation
import UIKit

struct FlattenedExportImage {
    enum SourceKind: Equatable {
        case original
        case annotated
    }

    let sourcePath: String
    let sourceKind: SourceKind
    let data: Data
    let image: UIImage

    var pixelSize: CGSize {
        image.size
    }
}

enum FlattenedExportImageRenderer {
    static func render(
        photo: PhotoRecord,
        options: ExportOptions
    ) throws -> FlattenedExportImage {
        let imagePath = photo.displayImagePath
        let sourceKind: FlattenedExportImage.SourceKind = imagePath == photo.annotatedImagePath ? .annotated : .original
        let fullURL = AppConstants.imagesBaseURL.appendingPathComponent(imagePath)

        guard let sourceData = try? Data(contentsOf: fullURL) else {
            throw ExportError.imageLoadFailed(imagePath)
        }

        return try render(
            sourceData: sourceData,
            sourcePath: imagePath,
            sourceKind: sourceKind,
            options: options
        )
    }

    static func render(
        sourceData: Data,
        sourcePath: String,
        sourceKind: FlattenedExportImage.SourceKind,
        options: ExportOptions
    ) throws -> FlattenedExportImage {
        guard let imageData = ImageCompressor.compressData(
                  sourceData,
                  quality: options.quality,
                  maxWidthOverride: options.exportImageMaxRenderWidth,
                  maxBytes: options.exportImageMaxBytes
              ),
              let image = UIImage(data: imageData) else {
            throw ExportError.imageLoadFailed(sourcePath)
        }

        return FlattenedExportImage(
            sourcePath: sourcePath,
            sourceKind: sourceKind,
            data: imageData,
            image: image
        )
    }
}

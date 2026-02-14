import UIKit

final class ImageCompressor {
    /// Compress a single image according to the quality preset.
    /// Returns JPEG data. Never call on multiple images simultaneously.
    static func compress(
        _ image: UIImage,
        quality: ImageQuality,
        maxWidthOverride: CGFloat? = nil,
        maxBytes: Int? = nil
    ) -> Data? {
        autoreleasepool {
            let maxWidth = min(maxWidthOverride ?? quality.maxWidth, quality.maxWidth)
            let resized = image.resized(maxWidth: maxWidth)
            return compressedJPEGData(
                from: resized,
                initialQuality: quality.jpegQuality,
                maxBytes: maxBytes
            )
        }
    }

    /// Compress image data (loaded from disk) according to quality preset.
    /// Returns JPEG data.
    static func compressData(
        _ imageData: Data,
        quality: ImageQuality,
        maxWidthOverride: CGFloat? = nil,
        maxBytes: Int? = nil
    ) -> Data? {
        autoreleasepool {
            guard let image = UIImage(data: imageData) else { return nil }
            let maxWidth = min(maxWidthOverride ?? quality.maxWidth, quality.maxWidth)
            let resized = image.resized(maxWidth: maxWidth)
            return compressedJPEGData(
                from: resized,
                initialQuality: quality.jpegQuality,
                maxBytes: maxBytes
            )
        }
    }

    /// Get image dimensions after compression (without actually compressing)
    static func compressedSize(of image: UIImage, quality: ImageQuality) -> CGSize {
        let currentWidth = image.size.width
        if currentWidth <= quality.maxWidth {
            return image.size
        }
        let scale = quality.maxWidth / currentWidth
        return CGSize(
            width: currentWidth * scale,
            height: image.size.height * scale
        )
    }

    private static func compressedJPEGData(
        from image: UIImage,
        initialQuality: CGFloat,
        maxBytes: Int?
    ) -> Data? {
        guard let maxBytes else {
            return image.jpegDataStripped(quality: initialQuality)
        }

        let minQuality: CGFloat = 0.18
        let minWidth: CGFloat = 320
        let resizeStep: CGFloat = 0.88

        var quality = initialQuality
        var data = image.jpegDataStripped(quality: quality)

        while let encoded = data,
              encoded.count > maxBytes,
              quality > minQuality {
            quality = max(quality - 0.08, minQuality)
            data = image.jpegDataStripped(quality: quality)
        }

        guard var encoded = data else { return nil }
        if encoded.count <= maxBytes {
            return encoded
        }

        var workingImage = image
        while encoded.count > maxBytes, workingImage.size.width > minWidth {
            let nextWidth = max(workingImage.size.width * resizeStep, minWidth)
            if nextWidth >= workingImage.size.width {
                break
            }

            workingImage = workingImage.resized(maxWidth: nextWidth)
            guard let resizedData = workingImage.jpegDataStripped(quality: quality) else {
                break
            }
            encoded = resizedData
        }

        while encoded.count > maxBytes, quality > 0.12 {
            quality -= 0.08
            guard let tighter = workingImage.jpegDataStripped(quality: quality) else {
                break
            }
            encoded = tighter
        }

        return encoded
    }
}

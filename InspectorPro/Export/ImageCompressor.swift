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

        let hardMinQuality: CGFloat = 0.12
        let softQualityFloor: CGFloat = max(initialQuality * 0.65, 0.24)
        let minWidth: CGFloat = 320
        let resizeStep: CGFloat = 0.90
        let qualityStep: CGFloat = 0.06

        var quality = initialQuality
        guard var encoded = image.jpegDataStripped(quality: quality) else { return nil }
        if encoded.count <= maxBytes {
            return encoded
        }

        // Keep quality reasonably high first, then prefer downscaling for better visual sharpness.
        while encoded.count > maxBytes, quality > softQualityFloor {
            quality = max(quality - qualityStep, softQualityFloor)
            guard let tighter = image.jpegDataStripped(quality: quality) else {
                break
            }
            encoded = tighter
        }

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

        while encoded.count > maxBytes, quality > hardMinQuality {
            quality = max(quality - qualityStep, hardMinQuality)
            guard let tighter = workingImage.jpegDataStripped(quality: quality) else {
                break
            }
            encoded = tighter
        }

        return encoded
    }
}

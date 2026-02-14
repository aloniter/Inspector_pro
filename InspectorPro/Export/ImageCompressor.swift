import UIKit

final class ImageCompressor {
    /// Compress a single image according to the quality preset.
    /// Returns JPEG data. Never call on multiple images simultaneously.
    static func compress(_ image: UIImage, quality: ImageQuality) -> Data? {
        autoreleasepool {
            let resized = image.resized(maxWidth: quality.maxWidth)
            return resized.jpegDataStripped(quality: quality.jpegQuality)
        }
    }

    /// Compress image data (loaded from disk) according to quality preset.
    /// Returns JPEG data.
    static func compressData(_ imageData: Data, quality: ImageQuality) -> Data? {
        autoreleasepool {
            guard let image = UIImage(data: imageData) else { return nil }
            let resized = image.resized(maxWidth: quality.maxWidth)
            return resized.jpegDataStripped(quality: quality.jpegQuality)
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
}

import UIKit

extension UIImage {
    /// Resize image to fit within maxWidth while preserving aspect ratio.
    /// Renders at scale 1 so maxWidth is an exact pixel cap; the default
    /// renderer format uses the screen scale, which tripled stored pixels.
    func resized(maxWidth: CGFloat) -> UIImage {
        let currentWidth = size.width
        guard currentWidth > maxWidth else { return self }

        let scale = maxWidth / currentWidth
        let newSize = CGSize(
            width: currentWidth * scale,
            height: size.height * scale
        )

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    /// Convert to JPEG data with specified quality, stripping metadata
    func jpegDataStripped(quality: CGFloat) -> Data? {
        guard let cgImage = self.cgImage else { return nil }
        let stripped = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
        return stripped.jpegData(compressionQuality: quality)
    }

    /// Create a thumbnail of the image
    func thumbnail(maxSize: CGFloat) -> UIImage {
        let maxDimension = max(size.width, size.height)
        guard maxDimension > maxSize else { return self }

        let scale = maxSize / maxDimension
        let newSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

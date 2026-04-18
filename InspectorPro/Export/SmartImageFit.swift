import CoreGraphics

enum SmartImageFit {
    static let defaultMaxCropPerSide = 2_000

    enum Mode: Equatable {
        case fit
        case limitedCover
    }

    struct Crop: Equatable {
        let left: Int
        let top: Int
        let right: Int
        let bottom: Int

        static let none = Crop(left: 0, top: 0, right: 0, bottom: 0)

        var maxSide: Int {
            max(left, top, right, bottom)
        }

        var openXMLCrop: OpenXMLBuilder.ImageCrop {
            OpenXMLBuilder.ImageCrop(left: left, top: top, right: right, bottom: bottom)
        }
    }

    struct Result: Equatable {
        let mode: Mode
        let displaySize: CGSize
        let drawSize: CGSize
        let crop: Crop
    }

    static func resolve(
        sourceSize: CGSize,
        targetSize: CGSize,
        hasAnnotations: Bool,
        maxCropPerSide: Int = defaultMaxCropPerSide
    ) -> Result {
        guard sourceSize.width > 0,
              sourceSize.height > 0,
              targetSize.width > 0,
              targetSize.height > 0 else {
            return Result(mode: .fit, displaySize: .zero, drawSize: .zero, crop: .none)
        }

        let fittedSize = aspectFitSize(sourceSize: sourceSize, targetSize: targetSize)
        if hasAnnotations {
            return Result(mode: .fit, displaySize: fittedSize, drawSize: fittedSize, crop: .none)
        }

        let widthScale = targetSize.width / sourceSize.width
        let heightScale = targetSize.height / sourceSize.height
        let coverScale = max(widthScale, heightScale)
        let coverSize = CGSize(
            width: sourceSize.width * coverScale,
            height: sourceSize.height * coverScale
        )

        let horizontalCrop = cropPerSide(
            excess: max(coverSize.width - targetSize.width, 0),
            scaledSize: coverSize.width
        )
        let verticalCrop = cropPerSide(
            excess: max(coverSize.height - targetSize.height, 0),
            scaledSize: coverSize.height
        )
        let crop = Crop(
            left: horizontalCrop,
            top: verticalCrop,
            right: horizontalCrop,
            bottom: verticalCrop
        )

        guard crop.maxSide > 0, crop.maxSide <= maxCropPerSide else {
            return Result(mode: .fit, displaySize: fittedSize, drawSize: fittedSize, crop: .none)
        }

        return Result(mode: .limitedCover, displaySize: targetSize, drawSize: coverSize, crop: crop)
    }

    private static func aspectFitSize(sourceSize: CGSize, targetSize: CGSize) -> CGSize {
        let scale = min(targetSize.width / sourceSize.width, targetSize.height / sourceSize.height)
        return CGSize(
            width: sourceSize.width * scale,
            height: sourceSize.height * scale
        )
    }

    private static func cropPerSide(excess: CGFloat, scaledSize: CGFloat) -> Int {
        guard excess > 0, scaledSize > 0 else { return 0 }
        return Int(((excess / scaledSize) * 50_000.0).rounded())
    }
}

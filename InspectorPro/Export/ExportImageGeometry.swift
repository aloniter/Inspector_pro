import CoreGraphics
import Foundation

struct ExportImageGeometry {
    static let emuPerPoint: CGFloat = 12_700

    static func aspectFitSize(
        sourceSize: CGSize,
        boundingSize: CGSize
    ) -> CGSize {
        guard sourceSize.width > 0,
              sourceSize.height > 0,
              boundingSize.width > 0,
              boundingSize.height > 0 else {
            return .zero
        }

        let scale = min(
            boundingSize.width / sourceSize.width,
            boundingSize.height / sourceSize.height
        )

        return CGSize(
            width: sourceSize.width * scale,
            height: sourceSize.height * scale
        )
    }

    static func centeredAspectFitRect(
        sourceSize: CGSize,
        in boundingRect: CGRect
    ) -> CGRect {
        let fittedSize = aspectFitSize(sourceSize: sourceSize, boundingSize: boundingRect.size)
        guard fittedSize.width > 0, fittedSize.height > 0 else {
            return .zero
        }

        return CGRect(
            x: boundingRect.midX - fittedSize.width / 2,
            y: boundingRect.midY - fittedSize.height / 2,
            width: fittedSize.width,
            height: fittedSize.height
        )
    }

    static func aspectFitSizeFillingWidth(
        sourceSize: CGSize,
        targetWidth: CGFloat,
        maximumHeight: CGFloat
    ) -> CGSize {
        guard sourceSize.width > 0,
              sourceSize.height > 0,
              targetWidth > 0,
              maximumHeight > 0 else {
            return .zero
        }

        let widthFilledHeight = targetWidth * (sourceSize.height / sourceSize.width)
        if widthFilledHeight <= maximumHeight {
            return CGSize(width: targetWidth, height: widthFilledHeight)
        }

        return aspectFitSize(
            sourceSize: sourceSize,
            boundingSize: CGSize(width: targetWidth, height: maximumHeight)
        )
    }

    static func centeredWidthFillRect(
        sourceSize: CGSize,
        in boundingRect: CGRect
    ) -> CGRect {
        let fittedSize = aspectFitSizeFillingWidth(
            sourceSize: sourceSize,
            targetWidth: boundingRect.width,
            maximumHeight: boundingRect.height
        )
        guard fittedSize.width > 0, fittedSize.height > 0 else {
            return .zero
        }

        return CGRect(
            x: boundingRect.midX - fittedSize.width / 2,
            y: boundingRect.midY - fittedSize.height / 2,
            width: fittedSize.width,
            height: fittedSize.height
        )
    }

    static func normalizedPoint(_ point: CGPoint, in frame: CGRect) -> CGPoint {
        guard frame.width > 0, frame.height > 0 else { return .zero }
        return CGPoint(
            x: ((point.x - frame.minX) / frame.width).clamped(to: 0...1),
            y: ((point.y - frame.minY) / frame.height).clamped(to: 0...1)
        )
    }

    static func denormalizedPoint(_ point: CGPoint, in frame: CGRect) -> CGPoint {
        CGPoint(
            x: frame.minX + (point.x * frame.width),
            y: frame.minY + (point.y * frame.height)
        )
    }

    static func denormalizedRect(_ rect: CGRect, in frame: CGRect) -> CGRect {
        CGRect(
            x: frame.minX + (rect.minX * frame.width),
            y: frame.minY + (rect.minY * frame.height),
            width: rect.width * frame.width,
            height: rect.height * frame.height
        )
    }

    static func emuSize(
        for sourceSize: CGSize,
        boundingWidthEMU: Int,
        boundingHeightEMU: Int
    ) -> (width: Int, height: Int) {
        let boundingSize = CGSize(
            width: CGFloat(max(boundingWidthEMU, 0)),
            height: CGFloat(max(boundingHeightEMU, 0))
        )
        let fittedSize = aspectFitSize(sourceSize: sourceSize, boundingSize: boundingSize)
        guard fittedSize.width > 0, fittedSize.height > 0 else {
            return (max(boundingWidthEMU, 1), max(boundingHeightEMU, 1))
        }

        return (
            max(Int(fittedSize.width.rounded()), 1),
            max(Int(fittedSize.height.rounded()), 1)
        )
    }

    static func emuSizeFillingWidth(
        for sourceSize: CGSize,
        targetWidthEMU: Int,
        maximumHeightEMU: Int
    ) -> (width: Int, height: Int) {
        let fittedSize = aspectFitSizeFillingWidth(
            sourceSize: sourceSize,
            targetWidth: CGFloat(max(targetWidthEMU, 0)),
            maximumHeight: CGFloat(max(maximumHeightEMU, 0))
        )
        guard fittedSize.width > 0, fittedSize.height > 0 else {
            return (max(targetWidthEMU, 1), max(maximumHeightEMU, 1))
        }

        return (
            max(Int(fittedSize.width.rounded()), 1),
            max(Int(fittedSize.height.rounded()), 1)
        )
    }

    static func points(fromEMU emu: Int) -> CGFloat {
        CGFloat(emu) / emuPerPoint
    }

    static func emu(fromPoints points: CGFloat) -> Int {
        max(Int((points * emuPerPoint).rounded()), 1)
    }
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

import Foundation

struct ExportOptions {
    let format: ExportFormat
    let quality: ImageQuality
    let photosPerPage: Int = 2

    // A4 page dimensions in points (72 DPI)
    let pageWidth: CGFloat = 595.28
    let pageHeight: CGFloat = 841.89
    let marginTop: CGFloat = 40
    let marginBottom: CGFloat = 40
    let marginLeft: CGFloat = 40
    let marginRight: CGFloat = 40

    let imageColumnRatio: CGFloat = 0.60
    let textColumnRatio: CGFloat = 0.40

    var contentWidth: CGFloat {
        pageWidth - marginLeft - marginRight
    }

    var contentHeight: CGFloat {
        pageHeight - marginTop - marginBottom
    }

    // A4 in EMUs (English Metric Units) for DOCX: 1 inch = 914400 EMUs
    // A4 = 8.27 x 11.69 inches
    let pageWidthEMU: Int = 7560310   // 8.27 * 914400
    let pageHeightEMU: Int = 10692130 // 11.69 * 914400

    var contentWidthEMU: Int {
        // Content area = page - margins (margins ~0.55 inches each side)
        pageWidthEMU - 2 * 502920 // ~0.55 inch margins
    }

    var imageColumnWidthEMU: Int {
        Int(Double(contentWidthEMU) * 0.60)
    }

    var textColumnWidthEMU: Int {
        Int(Double(contentWidthEMU) * 0.40)
    }
}

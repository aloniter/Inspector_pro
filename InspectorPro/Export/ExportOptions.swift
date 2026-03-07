import Foundation

struct ExportOptions {
    let format: ExportFormat
    let quality: ImageQuality
    let photoCount: Int
    let photosPerPage: Int = 2

    // A4 page dimensions in points (72 DPI)
    let pageWidth: CGFloat = 595.28
    let pageHeight: CGFloat = 841.89
    let marginTop: CGFloat = 40
    let marginBottom: CGFloat = 40
    let marginLeft: CGFloat = 40
    let marginRight: CGFloat = 40
    /// Top margin to accommodate the header logo.
    let brandedTopMarginPt: CGFloat = 92.0     // 1840 twips
    /// Bottom margin matching template.docx to accommodate the footer.
    let brandedBottomMarginPt: CGFloat = 72.0  // 1440 twips
    /// Distance from page top to header content start.
    let brandedHeaderDistancePt: CGFloat = 8.5  // 170 twips
    /// Distance from page bottom to footer content start.
    let brandedFooterDistancePt: CGFloat = 11.35 // 227 twips

    let docxTableLayoutSafetyPadding: CGFloat = 12

    let imageColumnRatio: CGFloat = 0.60
    let textColumnRatio: CGFloat = 0.40
    let tableHeaderHeight: CGFloat = 40
    let tableCellPadding: CGFloat = 10
    let minimumPhotoRowHeight: CGFloat = 170

    var contentWidth: CGFloat {
        pageWidth - marginLeft - marginRight
    }

    var contentHeight: CGFloat {
        pageHeight - effectiveTopMargin - effectiveBottomMargin
    }

    var effectiveTopMargin: CGFloat {
        brandedTopMarginPt
    }

    var effectiveBottomMargin: CGFloat {
        brandedBottomMarginPt
    }

    /// Available height for the header content (logo) between header distance and top margin.
    var headerZoneHeight: CGFloat {
        brandedTopMarginPt - brandedHeaderDistancePt
    }

    /// Available height for the footer content between footer distance and bottom margin.
    var footerZoneHeight: CGFloat {
        brandedBottomMarginPt - brandedFooterDistancePt
    }

    var imageColumnWidth: CGFloat {
        contentWidth * imageColumnRatio
    }

    var textColumnWidth: CGFloat {
        contentWidth * textColumnRatio
    }

    var imageContentWidth: CGFloat {
        max(imageColumnWidth - (ExportImageConstants.imageCellPaddingPoints * 2), 120)
    }

    var textContentWidth: CGFloat {
        max(textColumnWidth - (tableCellPadding * 2), 120)
    }

    var photoRowsPerPage: CGFloat {
        CGFloat(max(photosPerPage, 1))
    }

    /// Target row height that guarantees the configured photos-per-page density.
    var targetPhotoRowHeight: CGFloat {
        let availableHeight = max(contentHeight - tableHeaderHeight - tableLayoutSafetyPadding, 0)
        return max(availableHeight / photoRowsPerPage, minimumPhotoRowHeight)
    }

    var targetPhotoImageHeight: CGFloat {
        max(targetPhotoRowHeight - (ExportImageConstants.imageCellPaddingPoints * 2), 80)
    }

    /// Render width used during compression to keep quality while reducing file size.
    var exportImageMaxRenderWidth: CGFloat {
        let baseWidth = min(quality.maxWidth, imageContentWidth * 2.2)
        let adaptiveWidth = baseWidth * quality.adaptiveRenderWidthScale(photoCount: safePhotoCount)
        let floorWidth = min(quality.minimumAdaptiveRenderWidth, baseWidth)
        return max(min(baseWidth, adaptiveWidth), floorWidth)
    }

    var exportImageMaxBytes: Int {
        let budgetForImages = max(
            quality.targetTotalExportBytes - quality.targetContainerOverheadBytes,
            quality.minimumExportBytesPerImage
        )
        let adaptiveBytes = budgetForImages / safePhotoCount
        return min(
            quality.targetExportBytesPerImage,
            max(quality.minimumExportBytesPerImage, adaptiveBytes)
        )
    }

    private var safePhotoCount: Int {
        max(photoCount, 1)
    }

    var contentWidthTwips: Int {
        Int(contentWidth * 20.0)
    }

    var imageColumnWidthTwips: Int {
        Int(imageColumnWidth * 20.0)
    }

    var textColumnWidthTwips: Int {
        Int(textColumnWidth * 20.0)
    }

    var targetPhotoRowHeightTwips: Int {
        Int(targetPhotoRowHeight * 20.0)
    }

    var tableLayoutSafetyPadding: CGFloat {
        format == .docx ? docxTableLayoutSafetyPadding : 0
    }

    var docxTableLayoutSafetyPaddingTwips: Int {
        Int(docxTableLayoutSafetyPadding * 20.0)
    }

    var docxTopMarginTwips: Int { 1840 }
    var docxBottomMarginTwips: Int { 1440 }
    var docxLeftMarginTwips: Int { Int(marginLeft * 20.0) }
    var docxRightMarginTwips: Int { Int(marginRight * 20.0) }
    var docxHeaderDistanceTwips: Int { 170 }
    var docxFooterDistanceTwips: Int { 227 }

    // A4 in EMUs (English Metric Units) for DOCX: 1 inch = 914400 EMUs
    // A4 = 8.27 x 11.69 inches
    let pageWidthEMU: Int = 7560310   // 8.27 * 914400
    let pageHeightEMU: Int = 10692130 // 11.69 * 914400

    var contentWidthEMU: Int {
        // Content area = page - margins (margins ~0.55 inches each side)
        pageWidthEMU - 2 * 502920 // ~0.55 inch margins
    }

    var imageColumnWidthEMU: Int {
        Int(Double(contentWidthEMU) * Double(imageColumnRatio))
    }

    var textColumnWidthEMU: Int {
        Int(Double(contentWidthEMU) * Double(textColumnRatio))
    }

    var imageContentWidthEMU: Int {
        imageColumnWidthEMU - 2 * ExportImageConstants.imageCellPaddingEMU
    }

    var targetPhotoImageHeightEMU: Int {
        Int(targetPhotoImageHeight * 12700.0)
    }

    init(format: ExportFormat, quality: ImageQuality, photoCount: Int = 1) {
        self.format = format
        self.quality = quality
        self.photoCount = max(photoCount, 1)
    }
}

import UIKit

/// Shared geometry for the cover-page attendees block so the PDF and DOCX
/// exporters render the same two-column structure:
///
///     name column (visual left) | marker column "N." (visual right)
///
/// Both columns are right-to-left. The marker column is narrow and holds the
/// full "N." string (number + period); a small gap is folded into the marker
/// column so short names sit directly beside the number without a dead space.
/// Widths are measured from the actual attendee text so the whole block hugs
/// its content and can be centered as a compact block — matching a hand-made
/// Word list rather than a wide reserved slab.
///
/// This is the single source of truth for the layout intent; each renderer
/// converts the point widths into its own units (PDF points, DOCX twips).
enum AttendeeCoverLayout {
    /// Space between the number and the name, folded into the marker column so
    /// the number stays in a fixed column regardless of name length.
    static let markerNameGap: CGFloat = 8

    struct Columns: Equatable {
        /// Width of the marker column, including `markerNameGap`.
        let markerColumnWidth: CGFloat
        let nameColumnWidth: CGFloat

        var totalWidth: CGFloat { markerColumnWidth + nameColumnWidth }
    }

    /// Computes the marker and name column widths (in points) for the given
    /// attendees at `font`, clamped so the block never exceeds `maxTotalWidth`.
    static func columns(
        for attendees: [ExportTextFormatter.NumberedAttendee],
        font: UIFont,
        maxTotalWidth: CGFloat
    ) -> Columns {
        guard !attendees.isEmpty, maxTotalWidth > 0 else {
            return Columns(markerColumnWidth: 0, nameColumnWidth: 0)
        }

        let markerTextWidth = attendees
            .map { textWidth($0.markerText, font: font) }
            .max() ?? 0
        let markerColumnWidth = min(markerTextWidth + markerNameGap, maxTotalWidth)

        let preferredNameWidth = attendees
            .map { textWidth($0.name, font: font) }
            .max() ?? 0
        let availableNameWidth = max(maxTotalWidth - markerColumnWidth, 1)
        let nameColumnWidth = max(min(preferredNameWidth, availableNameWidth), 1)

        return Columns(markerColumnWidth: markerColumnWidth, nameColumnWidth: nameColumnWidth)
    }

    static func textWidth(_ text: String, font: UIFont) -> CGFloat {
        guard !text.isEmpty else { return 0 }
        return ceil((text as NSString).size(withAttributes: [.font: font]).width)
    }
}

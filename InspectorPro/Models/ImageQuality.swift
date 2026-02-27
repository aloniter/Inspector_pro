import Foundation

enum ImageQuality: String, CaseIterable, Identifiable, Codable {
    case economical
    case balanced
    case high

    var id: String { rawValue }

    var maxWidth: CGFloat {
        switch self {
        case .economical: return 900
        case .balanced: return 1400
        case .high: return 2000
        }
    }

    var jpegQuality: CGFloat {
        switch self {
        case .economical: return 0.45
        case .balanced: return 0.60
        case .high: return 0.75
        }
    }

    /// Hard cap per exported image to keep DOCX/PDF lightweight.
    var targetExportBytesPerImage: Int {
        switch self {
        case .economical: return 170_000
        case .balanced: return 280_000
        case .high: return 420_000
        }
    }

    /// Minimum bytes per image used by adaptive export budgeting.
    var minimumExportBytesPerImage: Int {
        switch self {
        case .economical: return 55_000
        case .balanced: return 90_000
        case .high: return 130_000
        }
    }

    /// Target total export payload budget (images + container overhead).
    var targetTotalExportBytes: Int {
        switch self {
        case .economical: return 20_000_000
        case .balanced: return 40_000_000
        case .high: return 65_000_000
        }
    }

    /// Reserved bytes for PDF/DOCX structure and metadata.
    var targetContainerOverheadBytes: Int {
        switch self {
        case .economical: return 1_000_000
        case .balanced: return 1_500_000
        case .high: return 2_500_000
        }
    }

    /// Limits how aggressively render width can be reduced for large photo sets.
    var minimumAdaptiveRenderWidth: CGFloat {
        switch self {
        case .economical: return 500
        case .balanced: return 540
        case .high: return 580
        }
    }

    /// Scale applied to export render width for large projects.
    func adaptiveRenderWidthScale(photoCount: Int) -> CGFloat {
        let count = max(photoCount, 1)
        switch self {
        case .economical:
            switch count {
            case 301...: return 0.75
            case 201...300: return 0.80
            case 121...200: return 0.85
            case 81...120: return 0.90
            case 41...80: return 0.95
            default: return 1.0
            }
        case .balanced:
            switch count {
            case 351...: return 0.78
            case 221...350: return 0.83
            case 141...220: return 0.88
            case 91...140: return 0.93
            case 51...90: return 0.97
            default: return 1.0
            }
        case .high:
            switch count {
            case 401...: return 0.80
            case 251...400: return 0.85
            case 161...250: return 0.90
            case 111...160: return 0.95
            case 71...110: return 0.98
            default: return 1.0
            }
        }
    }

    var hebrewLabel: String {
        switch self {
        case .economical: return AppStrings.text("חסכוני")
        case .balanced: return AppStrings.text("מאוזן")
        case .high: return AppStrings.text("איכותי")
        }
    }

    var hebrewDescription: String {
        switch self {
        case .economical: return AppStrings.text("900px • קובץ קטן")
        case .balanced: return AppStrings.text("1400px • איזון טוב")
        case .high: return AppStrings.text("2000px • איכות מקסימלית")
        }
    }
}

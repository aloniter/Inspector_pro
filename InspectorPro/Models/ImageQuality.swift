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

    var hebrewLabel: String {
        switch self {
        case .economical: return "חסכוני"
        case .balanced: return "מאוזן"
        case .high: return "איכותי"
        }
    }

    var hebrewDescription: String {
        switch self {
        case .economical: return "900px • קובץ קטן"
        case .balanced: return "1400px • איזון טוב"
        case .high: return "2000px • איכות מקסימלית"
        }
    }
}

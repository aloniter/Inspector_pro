import Foundation

enum ExportFormat: String, CaseIterable, Identifiable {
    case pdf
    case docx

    var id: String { rawValue }

    var hebrewLabel: String {
        switch self {
        case .pdf: return "PDF"
        case .docx: return "Word (DOCX)"
        }
    }

    var fileExtension: String {
        rawValue
    }

    var mimeType: String {
        switch self {
        case .pdf: return "application/pdf"
        case .docx: return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        }
    }
}

import Foundation
import SwiftUI

enum Severity: String, Codable, CaseIterable, Identifiable {
    case low
    case medium
    case high

    var id: String { rawValue }

    var hebrewLabel: String {
        switch self {
        case .low: return "נמוכה"
        case .medium: return "בינונית"
        case .high: return "גבוהה"
        }
    }

    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

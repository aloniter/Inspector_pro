import SwiftUI

struct SeverityBadge: View {
    let severity: Severity

    var body: some View {
        Text(severity.hebrewLabel)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(severity.color.opacity(0.15))
            .foregroundStyle(severity.color)
            .clipShape(Capsule())
    }
}

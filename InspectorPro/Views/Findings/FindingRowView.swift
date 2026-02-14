import SwiftUI

struct FindingRowView: View {
    let finding: Finding

    var body: some View {
        HStack(spacing: 12) {
            // Finding number circle
            Text("\(finding.number)")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(finding.severity.color)
                .clipShape(Circle())

            VStack(alignment: .trailing, spacing: 3) {
                HStack {
                    SeverityBadge(severity: finding.severity)
                    Spacer()
                    Text(finding.title.isEmpty ? "ממצא \(finding.number)" : finding.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("\(finding.photos.count) תמונות")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if !finding.room.isEmpty {
                        Text(finding.room)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}

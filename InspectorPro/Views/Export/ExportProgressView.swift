import SwiftUI

struct ExportProgressView: View {
    let progress: Double
    let format: ExportFormat

    var body: some View {
        VStack(spacing: 16) {
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .padding(.horizontal)

            Text("מייצא \(format.hebrewLabel)...")
                .font(.headline)

            Text("\(Int(progress * 100))%")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.blue)
                .contentTransition(.numericText())
        }
        .padding()
    }
}

import SwiftUI

struct ExportOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let project: Project

    @State private var selectedFormat: ExportFormat = .pdf
    @State private var selectedQuality: ImageQuality = .balanced
    @State private var isExporting = false
    @State private var exportProgress: Double = 0
    @State private var exportedURL: URL?
    @State private var errorMessage: String?
    @State private var showingShareSheet = false

    var body: some View {
        NavigationStack {
            Form {
                Section("פורמט") {
                    Picker("פורמט יצוא", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases) { format in
                            Text(format.hebrewLabel).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("איכות תמונות") {
                    ForEach(ImageQuality.allCases) { quality in
                        Button {
                            selectedQuality = quality
                        } label: {
                            HStack {
                                VStack(alignment: .trailing) {
                                    Text(quality.hebrewLabel)
                                        .font(.body)
                                    Text(quality.hebrewDescription)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if selectedQuality == quality {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }

                Section {
                    HStack {
                        Text("תמונות")
                        Spacer()
                        Text("\(project.photos.count)")
                    }
                } header: {
                    Text("סיכום")
                }

                if isExporting {
                    Section {
                        VStack(spacing: 8) {
                            ProgressView(value: exportProgress)
                            Text("מייצא... \(Int(exportProgress * 100))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("ייצוא דוח")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("ייצא") {
                        startExport()
                    }
                    .disabled(isExporting || project.photos.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("ביטול") {
                        dismiss()
                    }
                    .disabled(isExporting)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportedURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private func startExport() {
        isExporting = true
        errorMessage = nil
        exportProgress = 0

        Task {
            do {
                let options = ExportOptions(
                    format: selectedFormat,
                    quality: selectedQuality
                )

                let url = try await ExportEngine.exportReport(
                    project: project,
                    photos: project.sortedPhotos,
                    options: options,
                    onProgress: { progress in
                        Task { @MainActor in
                            exportProgress = progress
                        }
                    }
                )

                await MainActor.run {
                    exportedURL = url
                    isExporting = false
                    showingShareSheet = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isExporting = false
                }
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

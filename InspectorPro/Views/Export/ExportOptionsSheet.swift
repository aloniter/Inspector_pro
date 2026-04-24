import SwiftUI
import UniformTypeIdentifiers

struct ExportOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let report: Report

    @State private var selectedFormat: ExportFormat = .docx
    @State private var isExporting = false
    @State private var exportProgress: Double = 0
    @State private var exportedURL: URL?
    @State private var errorMessage: String?
    @State private var showingShareSheet = false
    @State private var exportBlockedMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section(AppStrings.text("פורמט")) {
                    Picker(AppStrings.text("פורמט יצוא"), selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases) { format in
                            Text(format.hebrewLabel).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    HStack {
                        Text(AppStrings.text("תמונות"))
                        Spacer()
                        Text("\(report.photos.count)")
                    }
                } header: {
                    Text(AppStrings.text("סיכום"))
                }

                if isExporting {
                    Section {
                        VStack(spacing: 8) {
                            ProgressView(value: exportProgress)
                            Text(AppStrings.format("מייצא... %d%%", Int(exportProgress * 100)))
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
            .navigationTitle(AppStrings.text("ייצוא דוח"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.text("ייצא")) {
                        startExport()
                    }
                    .disabled(isExporting || report.photos.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.text("ביטול")) {
                        dismiss()
                    }
                    .disabled(isExporting)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportedURL {
                    ShareSheet(fileURL: url)
                }
            }
            .alert(AppStrings.text("ייצוא אינו זמין"), isPresented: exportBlockedAlertPresented) {
                Button(AppStrings.text("אישור"), role: .cancel) {
                    exportBlockedMessage = nil
                }
            } message: {
                Text(exportBlockedMessage ?? "")
            }
        }
    }

    private var exportBlockedAlertPresented: Binding<Bool> {
        Binding(
            get: { exportBlockedMessage != nil },
            set: { if !$0 { exportBlockedMessage = nil } }
        )
    }

    private func startExport() {
        isExporting = true
        errorMessage = nil
        exportProgress = 0

        Task {
            // Permission gate — must pass before any export work begins
            let permission = await ExportPermissionService.shared.checkExportAllowed()
            if !permission.isAllowed {
                await MainActor.run {
                    isExporting = false
                    exportBlockedMessage = permission.hebrewDenialMessage
                }
                return
            }

            do {
                let options = ExportOptions(
                    format: selectedFormat,
                    quality: .economical,
                    photoCount: report.sortedPhotos.count
                )

                let url = try await ExportEngine.exportReport(
                    report: report,
                    photos: report.sortedPhotos,
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
    let fileURL: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let itemSource = ExportShareItemSource(fileURL: fileURL)
        return UIActivityViewController(activityItems: [itemSource], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private final class ExportShareItemSource: NSObject, UIActivityItemSource {
    private let fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        fileURL
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        // Some Word flows open file URLs as read-only and force "Save a copy".
        // Returning raw data for these activity types prompts editable import.
        if shouldForceDataTransfer(for: activityType),
           let data = try? Data(contentsOf: fileURL) {
            return data
        }
        return fileURL
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        UTType(filenameExtension: fileURL.pathExtension)?.identifier ?? UTType.data.identifier
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        subjectForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        fileURL.deletingPathExtension().lastPathComponent
    }

    private func shouldForceDataTransfer(for activityType: UIActivity.ActivityType?) -> Bool {
        guard let rawType = activityType?.rawValue.lowercased() else { return false }
        return rawType.contains("microsoft") || rawType.contains("word") || rawType.contains("office")
    }
}

import SwiftUI
import UIKit

enum FormMode {
    case create
    case edit
}

struct ProjectFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.layoutDirection) private var layoutDirection

    let mode: FormMode
    var project: Project?
    var onProjectSaved: ((Project) -> Void)?

    @State private var name = ""
    @State private var address = ""
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                DirectionalTextField(
                    text: $name,
                    placeholder: AppStrings.text("שם הפרויקט"),
                    layoutDirection: layoutDirection
                )
                DirectionalTextField(
                    text: $address,
                    placeholder: AppStrings.text("כתובת"),
                    layoutDirection: layoutDirection
                )
            } header: {
                RTLSectionHeader(title: AppStrings.text("פרטי פרויקט"))
            }
        }
        .navigationTitle(
            mode == .create
                ? AppStrings.text("פרויקט חדש")
                : AppStrings.text("עריכת פרויקט")
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(AppStrings.text("שמור")) {
                    save()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button(AppStrings.text("ביטול")) {
                    dismiss()
                }
            }
        }
        .alert(AppStrings.text("שמירה נכשלה"), isPresented: errorAlertPresented) {
            Button(AppStrings.text("אישור"), role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? AppStrings.text("אירעה שגיאה בשמירה"))
        }
        .onAppear {
            if let project {
                name = project.name
                address = project.address ?? ""
            }
        }
    }

    private var errorAlertPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    private func save() {
        do {
            if let project {
                let originalName = project.name
                let originalAddress = project.address

                project.name = name
                project.address = normalizedOptional(address)

                do {
                    try modelContext.save()
                } catch {
                    project.name = originalName
                    project.address = originalAddress
                    throw error
                }

                onProjectSaved?(project)
            } else {
                let newProject = Project(
                    name: name,
                    address: normalizedOptional(address)
                )
                modelContext.insert(newProject)

                do {
                    try modelContext.save()
                } catch {
                    modelContext.delete(newProject)
                    throw error
                }

                onProjectSaved?(newProject)
            }

            dismiss()
        } catch {
            errorMessage = userFacingErrorMessage(for: error)
        }
    }

    private func normalizedOptional(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func userFacingErrorMessage(for error: Error) -> String {
        let description = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        return description.isEmpty ? AppStrings.text("אירעה שגיאה בשמירה") : description
    }
}

struct ReportFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.layoutDirection) private var layoutDirection

    let mode: FormMode
    let project: Project
    var report: Report?
    var onReportSaved: ((Report) -> Void)?

    @State private var name = ""
    @State private var address = ""
    @State private var date = Date()
    @State private var attendees = ""
    @State private var showsNumberedImagesInReport = false
    @State private var notes = ""
    @State private var isEditingNotes = false
    @State private var errorMessage: String?

    private var textAlignment: TextAlignment {
        AppTextDirection.textAlignment(for: layoutDirection)
    }

    var body: some View {
        Form {
            Section {
                DirectionalTextField(
                    text: $name,
                    placeholder: AppStrings.text("שם הדוח"),
                    layoutDirection: layoutDirection
                )
                RTLDateField(label: AppStrings.text("תאריך"), date: $date)
                DirectionalTextField(
                    text: $address,
                    placeholder: AppStrings.text("כתובת"),
                    layoutDirection: layoutDirection
                )
            } header: {
                RTLSectionHeader(title: AppStrings.text("פרטי דוח"))
            }

            Section {
                TextField(AppStrings.text("נוכחים"), text: $attendees, axis: .vertical)
                    .multilineTextAlignment(textAlignment)
                    .lineLimit(1...3)
            } header: {
                RTLSectionHeader(title: ExportTextFormatter.rtlHeadingText("\(AppStrings.text("נוכחים")):"))
            }

            Section {
                RTLToggleRow(
                    title: AppStrings.text("מספור תמונות בדוח"),
                    isOn: $showsNumberedImagesInReport
                )
            }

            Section {
                DirectionalTextEditor(
                    text: $notes,
                    isFocused: $isEditingNotes,
                    layoutDirection: layoutDirection
                )
                    .frame(minHeight: 80)
            } header: {
                RTLSectionHeader(title: AppStrings.text("הערות"))
            }
        }
        .navigationTitle(
            mode == .create
                ? AppStrings.text("דוח חדש")
                : AppStrings.text("עריכת דוח")
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(AppStrings.text("שמור")) {
                    save()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button(AppStrings.text("ביטול")) {
                    dismiss()
                }
            }
        }
        .alert(AppStrings.text("שמירה נכשלה"), isPresented: errorAlertPresented) {
            Button(AppStrings.text("אישור"), role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? AppStrings.text("אירעה שגיאה בשמירה"))
        }
        .onAppear {
            if let report {
                name = report.name
                address = report.address ?? report.project?.address ?? ""
                date = report.date
                attendees = report.attendees ?? ""
                showsNumberedImagesInReport = report.showsNumberedImagesInReport
                notes = report.notes ?? ""
            } else {
                address = project.address ?? ""
            }
        }
    }

    private var errorAlertPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    private func save() {
        do {
            if let report {
                let originalName = report.name
                let originalAddress = report.address
                let originalDate = report.date
                let originalAttendees = report.attendees
                let originalShowsNumberedImagesInReport = report.showsNumberedImagesInReport
                let originalNotes = report.notes

                report.name = name
                report.address = normalizedOptional(address)
                report.date = date
                report.attendees = normalizedOptional(attendees)
                report.showsNumberedImagesInReport = showsNumberedImagesInReport
                report.notes = normalizedOptional(notes)

                do {
                    try modelContext.save()
                } catch {
                    report.name = originalName
                    report.address = originalAddress
                    report.date = originalDate
                    report.attendees = originalAttendees
                    report.showsNumberedImagesInReport = originalShowsNumberedImagesInReport
                    report.notes = originalNotes
                    throw error
                }

                onReportSaved?(report)
            } else {
                let defaultBrandingProfile = try BrandingBootstrapper.fetchDefaultBrandingProfile(in: modelContext)
                let newReport = Report(
                    name: name,
                    address: normalizedOptional(address),
                    date: date,
                    attendees: normalizedOptional(attendees),
                    notes: normalizedOptional(notes),
                    showsNumberedImagesInReport: showsNumberedImagesInReport,
                    project: project,
                    brandingProfile: defaultBrandingProfile
                )
                modelContext.insert(newReport)

                do {
                    try modelContext.save()
                } catch {
                    modelContext.delete(newReport)
                    throw error
                }

                onReportSaved?(newReport)
            }

            dismiss()
        } catch {
            errorMessage = userFacingErrorMessage(for: error)
        }
    }

    private func normalizedOptional(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func userFacingErrorMessage(for error: Error) -> String {
        let description = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        return description.isEmpty ? AppStrings.text("אירעה שגיאה בשמירה") : description
    }
}

private struct RTLSectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Spacer(minLength: 0)
            Text(title)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .environment(\.layoutDirection, .leftToRight)
    }
}

private struct RTLDateField: View {
    let label: String
    @Binding var date: Date

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .labelsHidden()
                    .environment(\.locale, AppLanguage.current.locale)

                Spacer(minLength: 0)

                Text(label)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(maxWidth: .infinity)
        }
        .environment(\.layoutDirection, .leftToRight)
    }
}

private struct RTLToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: $isOn)
                .labelsHidden()

            Spacer(minLength: 0)

            Text(title)
                .multilineTextAlignment(.trailing)
        }
        .frame(maxWidth: .infinity)
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityElement(children: .combine)
    }
}

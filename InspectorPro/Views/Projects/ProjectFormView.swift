import SwiftUI

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
    @State private var date = Date()
    @State private var attendees = ""
    @State private var showsNumberedImagesInReport = false
    @State private var notes = ""
    @State private var isEditingNotes = false

    private var textAlignment: TextAlignment {
        AppTextDirection.textAlignment(for: layoutDirection)
    }

    var body: some View {
        Form {
            Section(AppStrings.text("פרטי פרויקט")) {
                TextField(AppStrings.text("שם הפרויקט"), text: $name)
                    .multilineTextAlignment(textAlignment)
                TextField(AppStrings.text("כתובת"), text: $address)
                    .multilineTextAlignment(textAlignment)
                DatePicker(AppStrings.text("תאריך"), selection: $date, displayedComponents: .date)
                    .environment(\.locale, AppLanguage.current.locale)
            }

            Section {
                TextField(AppStrings.text("נוכחים"), text: $attendees, axis: .vertical)
                    .multilineTextAlignment(textAlignment)
                    .lineLimit(1...3)
            } header: {
                HStack {
                    Spacer(minLength: 0)
                    Text(ExportTextFormatter.rtlHeadingText("\(AppStrings.text("נוכחים")):"))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
                .frame(maxWidth: .infinity)
                .environment(\.layoutDirection, .leftToRight)
            }

            Section {
                Toggle(AppStrings.text("מספור תמונות בדוח"), isOn: $showsNumberedImagesInReport)
            }

            Section(AppStrings.text("הערות")) {
                DirectionalTextEditor(
                    text: $notes,
                    isFocused: $isEditingNotes,
                    layoutDirection: layoutDirection
                )
                    .frame(minHeight: 80)
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
        .onAppear {
            if let project = project {
                name = project.name
                address = project.address ?? ""
                date = project.date
                attendees = project.attendees ?? ""
                showsNumberedImagesInReport = project.showsNumberedImagesInReport
                notes = project.notes ?? ""
            }
        }
    }

    private func save() {
        if let project = project {
            project.name = name
            project.address = normalizedOptional(address)
            project.date = date
            project.attendees = normalizedOptional(attendees)
            project.showsNumberedImagesInReport = showsNumberedImagesInReport
            project.notes = normalizedOptional(notes)
            try? modelContext.save()
            onProjectSaved?(project)
        } else {
            let newProject = Project(
                name: name,
                address: normalizedOptional(address),
                date: date,
                attendees: normalizedOptional(attendees),
                notes: normalizedOptional(notes),
                showsNumberedImagesInReport: showsNumberedImagesInReport
            )
            modelContext.insert(newProject)
            try? modelContext.save()
            onProjectSaved?(newProject)
        }
        dismiss()
    }

    private func normalizedOptional(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

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
    @State private var notes = ""

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

            Section(AppStrings.text("הערות")) {
                TextEditor(text: $notes)
                    .frame(minHeight: 80)
                    .multilineTextAlignment(textAlignment)
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
                notes = project.notes ?? ""
            }
        }
    }

    private func save() {
        if let project = project {
            project.name = name
            project.address = normalizedOptional(address)
            project.date = date
            project.notes = normalizedOptional(notes)
            try? modelContext.save()
            onProjectSaved?(project)
        } else {
            let newProject = Project(
                name: name,
                address: normalizedOptional(address),
                date: date,
                notes: normalizedOptional(notes)
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

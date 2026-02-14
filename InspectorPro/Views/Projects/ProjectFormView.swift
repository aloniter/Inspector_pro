import SwiftUI

enum FormMode {
    case create
    case edit
}

struct ProjectFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let mode: FormMode
    var project: Project?

    @State private var title = ""
    @State private var address = ""
    @State private var inspectorName = ""
    @State private var date = Date()
    @State private var notes = ""

    var body: some View {
        Form {
            Section("פרטי פרויקט") {
                TextField("שם הפרויקט", text: $title)
                    .multilineTextAlignment(.trailing)
                TextField("כתובת", text: $address)
                    .multilineTextAlignment(.trailing)
                TextField("שם הבודק", text: $inspectorName)
                    .multilineTextAlignment(.trailing)
                DatePicker("תאריך", selection: $date, displayedComponents: .date)
                    .environment(\.locale, Locale(identifier: "he"))
            }

            Section("הערות") {
                TextEditor(text: $notes)
                    .frame(minHeight: 80)
                    .multilineTextAlignment(.trailing)
            }
        }
        .navigationTitle(mode == .create ? "פרויקט חדש" : "עריכת פרויקט")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("שמור") {
                    save()
                }
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("ביטול") {
                    dismiss()
                }
            }
        }
        .onAppear {
            if let project = project {
                title = project.title
                address = project.address
                inspectorName = project.inspectorName
                date = project.date
                notes = project.notes
            }
        }
    }

    private func save() {
        if let project = project {
            project.title = title
            project.address = address
            project.inspectorName = inspectorName
            project.date = date
            project.notes = notes
            project.updatedAt = .now
        } else {
            let newProject = Project(
                title: title,
                address: address,
                inspectorName: inspectorName,
                date: date,
                notes: notes
            )
            modelContext.insert(newProject)
        }
        dismiss()
    }
}

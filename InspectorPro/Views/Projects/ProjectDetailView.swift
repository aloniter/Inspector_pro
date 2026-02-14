import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: Project
    @State private var showingEditProject = false
    @State private var showingExportOptions = false

    var body: some View {
        List {
            Section("פרטי פרויקט") {
                LabeledContent("כתובת", value: project.address.isEmpty ? "—" : project.address)
                LabeledContent("בודק", value: project.inspectorName.isEmpty ? "—" : project.inspectorName)
                LabeledContent("תאריך") {
                    Text(project.date, style: .date)
                }
                if !project.notes.isEmpty {
                    Text(project.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                if project.sortedFindings.isEmpty {
                    EmptyStateView(
                        icon: "doc.text.magnifyingglass",
                        title: "אין ממצאים",
                        subtitle: "לחץ + להוספת ממצא"
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(project.sortedFindings) { finding in
                        NavigationLink(value: finding) {
                            FindingRowView(finding: finding)
                        }
                    }
                    .onDelete(perform: deleteFindings)
                    .onMove(perform: moveFindings)
                }
            } header: {
                HStack {
                    Text("ממצאים (\(project.findings.count))")
                    Spacer()
                }
            }
        }
        .navigationTitle(project.title)
        .navigationDestination(for: Finding.self) { finding in
            FindingEditorView(finding: finding, project: project)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button {
                        addFinding()
                    } label: {
                        Label("הוסף ממצא", systemImage: "plus")
                    }

                    Button {
                        showingEditProject = true
                    } label: {
                        Label("ערוך פרויקט", systemImage: "pencil")
                    }

                    Button {
                        showingExportOptions = true
                    } label: {
                        Label("ייצוא דוח", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }

            ToolbarItem(placement: .topBarLeading) {
                Button {
                    addFinding()
                } label: {
                    Image(systemName: "plus")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingEditProject) {
            NavigationStack {
                ProjectFormView(mode: .edit, project: project)
            }
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsSheet(project: project)
        }
    }

    private func addFinding() {
        let number = project.nextFindingNumber
        let order = project.findings.count
        let finding = Finding(number: number, order: order)
        finding.project = project
        modelContext.insert(finding)
        project.updatedAt = .now
    }

    private func deleteFindings(at offsets: IndexSet) {
        let sorted = project.sortedFindings
        for index in offsets {
            let finding = sorted[index]
            // Clean up photos from disk
            Task {
                await ImageStorageService.shared.deletePhotos(finding.photos)
            }
            modelContext.delete(finding)
        }
        project.updatedAt = .now
    }

    private func moveFindings(from source: IndexSet, to destination: Int) {
        var sorted = project.sortedFindings
        sorted.move(fromOffsets: source, toOffset: destination)
        for (index, finding) in sorted.enumerated() {
            finding.order = index
        }
        project.updatedAt = .now
    }
}

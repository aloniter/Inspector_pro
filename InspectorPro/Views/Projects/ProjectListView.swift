import SwiftUI
import SwiftData

struct ProjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @State private var showingNewProject = false

    var body: some View {
        List {
            if projects.isEmpty {
                EmptyStateView(
                    icon: "building.2",
                    title: "אין פרויקטים",
                    subtitle: "לחץ + להוספת פרויקט חדש"
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(projects) { project in
                    NavigationLink(value: project) {
                        ProjectRowView(project: project)
                    }
                }
                .onDelete(perform: deleteProjects)
            }
        }
        .navigationTitle("פרויקטים")
        .navigationDestination(for: Project.self) { project in
            ProjectDetailView(project: project)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showingNewProject = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewProject) {
            NavigationStack {
                ProjectFormView(mode: .create)
            }
        }
    }

    private func deleteProjects(at offsets: IndexSet) {
        for index in offsets {
            let project = projects[index]
            // Clean up images from disk
            let projectID = project.persistentModelID.hashValue.description
            Task {
                await ImageStorageService.shared.deleteProjectDirectory(projectID: projectID)
            }
            modelContext.delete(project)
        }
    }
}

struct ProjectRowView: View {
    let project: Project

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(project.title)
                .font(.headline)
                .multilineTextAlignment(.trailing)

            HStack {
                Text("\(project.findings.count) ממצאים")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(project.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !project.address.isEmpty {
                Text(project.address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.vertical, 2)
    }
}

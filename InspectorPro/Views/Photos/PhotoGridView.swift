import SwiftUI

struct PhotoGridView: View {
    @Environment(\.modelContext) private var modelContext
    let finding: Finding
    let project: Project

    @State private var selectedPhoto: Photo?

    private let columns = [
        GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 4)
    ]

    var body: some View {
        if finding.sortedPhotos.isEmpty {
            Text("אין תמונות")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        } else {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(finding.sortedPhotos) { photo in
                    ThumbnailView(thumbnailPath: photo.thumbnailPath)
                        .frame(height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(alignment: .topTrailing) {
                            if photo.annotatedPath != nil {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                                    .padding(2)
                            }
                        }
                        .onTapGesture {
                            selectedPhoto = photo
                        }
                }
            }
            .sheet(item: $selectedPhoto) { photo in
                NavigationStack {
                    PhotoDetailView(photo: photo, finding: finding, project: project)
                }
            }
        }
    }
}

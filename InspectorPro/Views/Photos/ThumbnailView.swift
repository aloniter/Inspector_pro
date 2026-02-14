import SwiftUI

struct ThumbnailView: View {
    let imagePath: String
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .task(id: imagePath) {
            image = await ThumbnailService.shared.thumbnail(for: imagePath)
        }
    }
}

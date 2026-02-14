import SwiftUI

struct ThumbnailView: View {
    let thumbnailPath: String?
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
                        ProgressView()
                    }
            }
        }
        .task(id: thumbnailPath) {
            image = await ThumbnailService.shared.thumbnail(for: thumbnailPath)
        }
    }
}

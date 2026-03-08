import SwiftUI

struct ThumbnailView: View {
    let imagePath: String
    @State private var image: UIImage?
    @State private var refreshToken = UUID()

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
        .task(id: "\(imagePath)|\(refreshToken.uuidString)") {
            image = await ThumbnailService.shared.thumbnail(for: imagePath)
        }
        .onAppear {
            refreshToken = UUID()
        }
        .onChange(of: imagePath) { _, _ in
            refreshToken = UUID()
        }
        .onReceive(NotificationCenter.default.publisher(for: .thumbnailsDidInvalidate)) { notification in
            guard let paths = notification.userInfo?[ThumbnailNotificationUserInfoKey.paths] as? [String] else {
                return
            }

            if paths.contains(imagePath) {
                refreshToken = UUID()
            }
        }
    }
}

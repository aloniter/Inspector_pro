#if DEBUG
import SwiftUI
import SwiftData

/// Generates a stress-test project with many photos.
struct StressTestButton: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isGenerating = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        Button {
            Task { await generateStressTest() }
        } label: {
            if isGenerating {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: "flame")
            }
        }
        .disabled(isGenerating)
        .accessibilityLabel("יצירת מבדק לחץ")
        .alert("מבדק לחץ", isPresented: $showAlert) {
            Button("אישור", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    @MainActor
    private func generateStressTest() async {
        isGenerating = true
        defer { isGenerating = false }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "he")
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"

        let project = Project(
            name: "מבדק לחץ – \(dateFormatter.string(from: .now))",
            address: "רחוב הבדיקה 42, תל אביב",
            date: .now,
            notes: "פרויקט מבחן אוטומטי"
        )
        modelContext.insert(project)

        let texts = [
            "נדרש תיקון נקודתי באזור המצולם.",
            "לבדוק מחדש לאחר השלמת עבודה.",
            "ליקוי קוסמטי לתיעוד.",
            "הנושא עשוי להחמיר ללא טיפול.",
            "נדרשת בדיקה נוספת בשטח.",
        ]

        let totalPhotos = 120
        let projectID = project.id.uuidString

        do {
            for i in 0..<totalPhotos {
                let testImage = Self.generateTestImage(photoNumber: i + 1)
                let imagePath = try await ImageStorageService.shared.saveImage(
                    testImage,
                    projectID: projectID
                )

                let photo = PhotoRecord(
                    imagePath: imagePath,
                    freeText: texts[i % texts.count]
                )
                photo.project = project
                modelContext.insert(photo)
            }

            try modelContext.save()
            alertMessage = "נוצר פרויקט עם \(totalPhotos) תמונות."
        } catch {
            alertMessage = "שגיאה: \(error.localizedDescription)"
        }

        showAlert = true
    }

    /// Generate a small colored test image with text overlay.
    private static func generateTestImage(photoNumber: Int) -> UIImage {
        let size = CGSize(width: 400, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { ctx in
            let colors: [UIColor] = [
                .systemOrange.withAlphaComponent(0.3),
                .systemBlue.withAlphaComponent(0.3),
                .systemGreen.withAlphaComponent(0.3),
                .systemPink.withAlphaComponent(0.3),
            ]
            colors[photoNumber % colors.count].setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            UIColor.white.withAlphaComponent(0.3).setStroke()
            let gridPath = UIBezierPath()
            for x in stride(from: CGFloat(0), to: size.width, by: 40) {
                gridPath.move(to: CGPoint(x: x, y: 0))
                gridPath.addLine(to: CGPoint(x: x, y: size.height))
            }
            for y in stride(from: CGFloat(0), to: size.height, by: 40) {
                gridPath.move(to: CGPoint(x: 0, y: y))
                gridPath.addLine(to: CGPoint(x: size.width, y: y))
            }
            gridPath.lineWidth = 1
            gridPath.stroke()

            let label = "P\(photoNumber)"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 36),
                .foregroundColor: UIColor.darkGray,
            ]
            let attrStr = NSAttributedString(string: label, attributes: attrs)
            let textSize = attrStr.size()
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            attrStr.draw(in: textRect)
        }
    }
}
#endif

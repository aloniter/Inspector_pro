#if DEBUG
import SwiftUI
import SwiftData

/// Generates a stress-test project with 25 findings and ~120 photos.
/// Available only in DEBUG builds, shown in ProjectListView toolbar.
struct StressTestButton: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isGenerating = false
    @State private var progress: Double = 0
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
            title: "מבדק לחץ – \(dateFormatter.string(from: .now))",
            address: "רחוב הבדיקה 42, תל אביב",
            inspectorName: "בודק אוטומטי"
        )
        modelContext.insert(project)

        let rooms = [
            "סלון", "מטבח", "חדר שינה ראשי", "חדר שינה ילדים",
            "חדר רחצה", "מרפסת", "מרתף", "חדר כביסה",
            "חדר עבודה", "פרוזדור", "חדר אורחים", "גג",
            "חניה", "מחסן", "לובי",
        ]

        let titles = [
            "סדק ברצפה", "רטיבות בתקרה", "עובש בפינה",
            "אריח שבור", "נזילה מהצנרת", "חלון תקוע",
            "דלת לא נסגרת", "סדק בקיר", "צבע מתקלף",
            "שקע חשמל פגום", "מעקה רופף", "מדרגה שבורה",
            "גמר ריצוף לקוי", "בידוד חסר", "איטום פגום",
            "ברז דולף", "וילון חשמלי תקול", "תריס שבור",
            "פנל תקרה נפול", "ניקוז לקוי", "חיפוי חסר",
            "ספי חלון סדוק", "אינסטלציה חשופה", "כבל חשמל חשוף",
            "מזגן רועש",
        ]

        let descriptions = [
            "נמצא ליקוי משמעותי הדורש טיפול מיידי.",
            "הממצא עלול להחמיר ללא טיפול.",
            "נדרשת בדיקה נוספת ע\"י מומחה.",
            "ליקוי קוסמטי שאינו מהווה סכנה.",
            "חורג מתקן הבנייה הישראלי.",
        ]

        let recommendations = [
            "לתקן בהקדם האפשרי.",
            "להזמין בעל מקצוע מוסמך.",
            "לבצע איטום מחדש.",
            "להחליף את האלמנט הפגום.",
            "לבצע מעקב בעוד 3 חודשים.",
        ]

        let totalFindings = 25
        // 5 photos each × 25 findings = 125 total (≈120 target)
        let photosPerFinding = 5
        let totalPhotos = totalFindings * photosPerFinding
        var processedPhotos = 0

        let projectID = project.persistentModelID.hashValue.description

        do {
            for i in 0..<totalFindings {
                let severity: Severity = [.low, .medium, .high][i % 3]
                let finding = Finding(
                    number: i + 1,
                    room: rooms[i % rooms.count],
                    title: titles[i % titles.count],
                    findingDescription: descriptions[i % descriptions.count],
                    recommendation: recommendations[i % recommendations.count],
                    severity: severity,
                    order: i
                )
                finding.project = project
                modelContext.insert(finding)

                let findingID = finding.persistentModelID.hashValue.description

                for j in 0..<photosPerFinding {
                    let testImage = Self.generateTestImage(
                        findingNumber: i + 1,
                        photoNumber: j + 1,
                        severity: severity
                    )

                    let result = try await ImageStorageService.shared.saveImage(
                        testImage,
                        projectID: projectID,
                        findingID: findingID
                    )

                    let photo = Photo(imagePath: result.imagePath, order: j)
                    photo.thumbnailPath = result.thumbnailPath
                    photo.finding = finding
                    modelContext.insert(photo)

                    processedPhotos += 1
                    progress = Double(processedPhotos) / Double(totalPhotos)
                }
            }

            try modelContext.save()
            alertMessage = "נוצר פרויקט עם \(totalFindings) ממצאים ו-\(totalPhotos) תמונות."
        } catch {
            alertMessage = "שגיאה: \(error.localizedDescription)"
        }

        showAlert = true
    }

    /// Generate a small colored test image with text overlay.
    private static func generateTestImage(
        findingNumber: Int,
        photoNumber: Int,
        severity: Severity
    ) -> UIImage {
        let size = CGSize(width: 400, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { ctx in
            // Background color based on severity
            let bgColor: UIColor
            switch severity {
            case .low: bgColor = .systemGreen.withAlphaComponent(0.3)
            case .medium: bgColor = .systemOrange.withAlphaComponent(0.3)
            case .high: bgColor = .systemRed.withAlphaComponent(0.3)
            }
            bgColor.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            // Draw a grid pattern for visual interest
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

            // Draw label
            let label = "F\(findingNumber) / P\(photoNumber)"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 32),
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

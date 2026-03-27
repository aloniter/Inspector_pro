import Foundation

enum ExportTextFormatter {
    struct DescriptionLine: Equatable {
        enum Style: Equatable {
            case bullet
            case numberedHeading
        }

        let text: String
        let style: Style

        var isBold: Bool {
            style == .numberedHeading
        }

        var usesBullet: Bool {
            style == .bullet
        }

        var exportText: String {
            let prefix = usesBullet ? "\(ExportTextFormatter.bullet)\(ExportTextFormatter.bulletSeparator)" : ""
            return "\(ExportTextFormatter.rtlEmbeddingStart)\(prefix)\(text)\(ExportTextFormatter.rtlEmbeddingEnd)"
        }
    }

    private static let rtlEmbeddingStart = "\u{202B}"
    private static let rtlEmbeddingEnd = "\u{202C}"
    private static let bullet = "•"
    private static let bulletSeparator = "\u{00A0}"
    private static let numberedHeadingPattern = try! NSRegularExpression(
        pattern: #"^(\d+)\.(?:\s+(.*))?$"#
    )

    static func bulletedDescriptionText(from text: String) -> String {
        descriptionLines(from: text)
            .map(\.exportText)
            .joined(separator: "\n")
    }

    static func bulletedDescriptionLines(from text: String) -> [String] {
        descriptionLines(from: text).map(\.exportText)
    }

    static func descriptionLines(from text: String) -> [DescriptionLine] {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .compactMap(parsedDescriptionLine)
    }

    private static func normalizedBulletContent(from line: String) -> String {
        var normalized = line.trimmingCharacters(in: .whitespacesAndNewlines)

        if normalized.hasPrefix(bullet) || normalized.hasPrefix("-") {
            normalized.removeFirst()
            normalized = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return normalized
    }

    private static func parsedDescriptionLine(_ line: String) -> DescriptionLine? {
        let normalizedLine = normalizedBulletContent(from: line)
        guard !normalizedLine.isEmpty else { return nil }

        if let numberedHeading = normalizedNumberedHeading(from: normalizedLine) {
            return DescriptionLine(text: numberedHeading, style: .numberedHeading)
        }

        return DescriptionLine(text: normalizedLine, style: .bullet)
    }

    private static func normalizedNumberedHeading(from line: String) -> String? {
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = numberedHeadingPattern.firstMatch(in: line, options: [], range: range),
              let numberRange = Range(match.range(at: 1), in: line) else {
            return nil
        }

        let number = String(line[numberRange])
        let body: String
        if let bodyRange = Range(match.range(at: 2), in: line) {
            body = String(line[bodyRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            body = ""
        }

        return body.isEmpty ? number : "\(number) \(body)"
    }
}

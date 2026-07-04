import Foundation

enum ExportTextFormatter {
    /// One cover-page attendee row: a 1-based `number` and its trimmed `name`.
    /// `markerText` is the single canonical "N." string used by both the PDF
    /// and DOCX exporters; each renderer applies RTL bidi so it reads correctly
    /// next to Hebrew names (digit flush to the outer edge, period toward the
    /// name). There is deliberately no LTR/RTL/"editable" marker variant — the
    /// direction is a rendering concern, not a data concern.
    struct NumberedAttendee: Equatable {
        let number: Int
        let name: String

        var markerText: String {
            "\(number)."
        }
    }

    struct DescriptionLine: Equatable {
        struct TextRun: Equatable {
            let text: String
            let isBold: Bool
        }

        enum Style: Equatable {
            case bullet
            case numberedHeading
        }

        let bodyText: String
        let style: Style
        let number: String?
        let emphasizesNumberPrefixOnly: Bool

        init(
            bodyText: String,
            style: Style,
            number: String? = nil,
            emphasizesNumberPrefixOnly: Bool = false
        ) {
            self.bodyText = bodyText
            self.style = style
            self.number = number
            self.emphasizesNumberPrefixOnly = emphasizesNumberPrefixOnly
        }

        var text: String {
            guard let number else { return bodyText }
            return bodyText.isEmpty ? number : "\(number) \(bodyText)"
        }

        var isBold: Bool {
            style == .numberedHeading && !emphasizesNumberPrefixOnly
        }

        var usesBullet: Bool {
            style == .bullet
        }

        var runs: [TextRun] {
            if usesBullet {
                return [TextRun(
                    text: "\(ExportTextFormatter.rtlEmbeddingStart)\(ExportTextFormatter.bullet)\(ExportTextFormatter.bulletSeparator)\(bodyText)\(ExportTextFormatter.rtlEmbeddingEnd)",
                    isBold: false
                )]
            }

            guard let number else {
                return [TextRun(
                    text: "\(ExportTextFormatter.rtlEmbeddingStart)\(bodyText)\(ExportTextFormatter.rtlEmbeddingEnd)",
                    isBold: isBold
                )]
            }

            if emphasizesNumberPrefixOnly {
                let prefix = bodyText.isEmpty
                    ? "\(ExportTextFormatter.rtlEmbeddingStart)\(number)\(ExportTextFormatter.rtlEmbeddingEnd)"
                    : "\(ExportTextFormatter.rtlEmbeddingStart)\(number) "
                var runs = [TextRun(text: prefix, isBold: true)]
                if !bodyText.isEmpty {
                    runs.append(TextRun(text: "\(bodyText)\(ExportTextFormatter.rtlEmbeddingEnd)", isBold: false))
                }
                return runs
            }

            return [TextRun(
                text: "\(ExportTextFormatter.rtlEmbeddingStart)\(text)\(ExportTextFormatter.rtlEmbeddingEnd)",
                isBold: true
            )]
        }

        var exportText: String {
            let prefix = usesBullet ? "\(ExportTextFormatter.bullet)\(ExportTextFormatter.bulletSeparator)" : ""
            return "\(ExportTextFormatter.rtlEmbeddingStart)\(prefix)\(text)\(ExportTextFormatter.rtlEmbeddingEnd)"
        }
    }

    private static let rtlEmbeddingStart = "\u{202B}"
    private static let rtlEmbeddingEnd = "\u{202C}"
    private static let leftToRightIsolateStart = "\u{2066}"
    private static let rightToLeftIsolateStart = "\u{2067}"
    private static let isolateEnd = "\u{2069}"
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

    static func numberedAttendees(from text: String) -> [NumberedAttendee] {
        normalizedNonEmptyLines(from: text)
            .enumerated()
            .map { index, line in
                NumberedAttendee(number: index + 1, name: line)
            }
    }

    static func reportCoverDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d.M.yyyy"
        return formatter.string(from: date)
    }

    static func descriptionLines(
        from text: String,
        itemNumber: Int? = nil,
        showsNumberedImagesInReport: Bool = false
    ) -> [DescriptionLine] {
        let parsedLines = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .compactMap(parsedDescriptionLine)

        guard showsNumberedImagesInReport, let itemNumber else {
            return parsedLines
        }

        return applyingBuiltInItemNumber("\(itemNumber).", to: parsedLines)
    }

    static func coverPageFieldText(label: String, value: String) -> String {
        let isolatedLabel = directionallyIsolated("\(label):")
        let isolatedValue = value
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { directionallyIsolated(String($0)) }
            .joined(separator: "\n")

        return "\(isolatedLabel) \(isolatedValue)"
    }

    static func rtlHeadingText(_ text: String) -> String {
        "\(rtlEmbeddingStart)\(text)\(rtlEmbeddingEnd)"
    }

    private static func normalizedBulletContent(from line: String) -> String {
        var normalized = line.trimmingCharacters(in: .whitespacesAndNewlines)

        if normalized.hasPrefix(bullet) || normalized.hasPrefix("-") {
            normalized.removeFirst()
            normalized = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return normalized
    }

    private static func normalizedNonEmptyLines(from text: String) -> [String] {
        text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .compactMap { segment -> String? in
                let line = String(segment).trimmingCharacters(in: .whitespacesAndNewlines)
                return line.isEmpty ? nil : line
            }
    }

    private static func parsedDescriptionLine(_ line: String) -> DescriptionLine? {
        let normalizedLine = normalizedBulletContent(from: line)
        guard !normalizedLine.isEmpty else { return nil }

        if let numberedHeading = normalizedNumberedHeading(from: normalizedLine) {
            return DescriptionLine(
                bodyText: numberedHeading.bodyText,
                style: .numberedHeading,
                number: numberedHeading.number
            )
        }

        return DescriptionLine(bodyText: normalizedLine, style: .bullet)
    }

    private static func normalizedNumberedHeading(from line: String) -> (number: String, bodyText: String)? {
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

        return (number: number, bodyText: body)
    }

    private static func applyingBuiltInItemNumber(
        _ itemNumber: String,
        to lines: [DescriptionLine]
    ) -> [DescriptionLine] {
        guard let firstLine = lines.first else {
            return [
                DescriptionLine(
                    bodyText: "",
                    style: .numberedHeading,
                    number: itemNumber,
                    emphasizesNumberPrefixOnly: true
                )
            ]
        }

        var updatedLines = lines
        updatedLines[0] = DescriptionLine(
            bodyText: firstLine.bodyText,
            style: .numberedHeading,
            number: itemNumber,
            emphasizesNumberPrefixOnly: false
        )
        return updatedLines
    }

    private static func directionallyIsolated(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        let isolateStart = containsHebrewCharacters(text) ? rightToLeftIsolateStart : leftToRightIsolateStart
        return "\(isolateStart)\(text)\(isolateEnd)"
    }

    private static func containsHebrewCharacters(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            (0x0590...0x05FF).contains(scalar.value)
        }
    }
}

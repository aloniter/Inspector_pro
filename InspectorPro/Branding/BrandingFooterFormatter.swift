import Foundation

struct BrandingPrimaryFooterFields: Equatable {
    var contactName: String = ""
    var roleLabel: String = ""
    var phoneNumber: String = ""
    var emailAddress: String = ""

    var isComplete: Bool {
        !contactName.isEmpty && !phoneNumber.isEmpty
    }

    static func fromStoredLines(pdf: String, docx: String) -> BrandingPrimaryFooterFields {
        if let parsed = BrandingFooterFormatter.parsePrimaryLogicalLine(pdf) {
            return parsed
        }

        if let parsed = BrandingFooterFormatter.parsePrimaryLogicalLine(docx) {
            return parsed
        }

        if let parsed = BrandingFooterFormatter.parsePrimaryReversedLine(docx) {
            return parsed
        }

        let fallback = BrandingFooterFormatter.strippingDirectionalMarks(from: pdf.isEmpty ? docx : pdf)
        return BrandingPrimaryFooterFields(contactName: fallback)
    }
}

struct BrandingSecondaryFooterFields: Equatable {
    var firstLabel: String = ""
    var firstNumber: String = ""
    var secondLabel: String = ""
    var secondNumber: String = ""

    var hasAnyValue: Bool {
        !firstLabel.isEmpty ||
        !firstNumber.isEmpty ||
        !secondLabel.isEmpty ||
        !secondNumber.isEmpty
    }

    var isComplete: Bool {
        !firstLabel.isEmpty && !firstNumber.isEmpty
    }

    static func fromStoredLine(_ line: String) -> BrandingSecondaryFooterFields {
        if let parsed = BrandingFooterFormatter.parseSecondaryLogicalLine(line) {
            return parsed
        }

        let fallback = BrandingFooterFormatter.strippingDirectionalMarks(from: line)
        return BrandingSecondaryFooterFields(firstLabel: fallback)
    }
}

enum BrandingFooterFormatter {
    enum RunDirection {
        case rightToLeft
        case leftToRight
    }

    struct FooterRun: Equatable {
        let text: String
        let direction: RunDirection
    }

    private static let leftToRightMark = "\u{200E}"
    private static let directionalControlScalars = CharacterSet(charactersIn: "\u{200E}\u{200F}\u{202A}\u{202B}\u{202C}\u{202D}\u{202E}\u{2066}\u{2067}\u{2068}\u{2069}")

    static func strippingDirectionalMarks(from value: String) -> String {
        let filteredScalars = value.unicodeScalars.filter { !directionalControlScalars.contains($0) }
        return String(String.UnicodeScalarView(filteredScalars))
    }

    static func normalizeAddressLine(_ value: String) -> String {
        normalizeFreeformLine(value)
    }

    static func addressRuns(from value: String) -> [FooterRun] {
        tokenize(strippingDirectionalMarks(from: value)).map(runForToken)
    }

    static func normalizeFreeformLine(_ value: String) -> String {
        let cleaned = strippingDirectionalMarks(from: value)
        let tokens = tokenize(cleaned)
        guard containsHebrew(cleaned) else {
            return tokens.joined(separator: " ")
        }
        return tokens.map(wrapTokenIfNeeded).joined(separator: " ")
    }

    static func composePrimaryLine(_ fields: BrandingPrimaryFooterFields) -> String {
        composeStructuredLine([
            fields.contactName,
            fields.phoneNumber,
            fields.roleLabel,
            fields.emailAddress,
        ])
    }

    static func primaryRuns(_ fields: BrandingPrimaryFooterFields) -> [FooterRun] {
        structuredRuns([
            fields.contactName,
            fields.phoneNumber,
            fields.roleLabel,
            fields.emailAddress,
        ])
    }

    static func primaryDisplayRuns(_ fields: BrandingPrimaryFooterFields) -> [FooterRun] {
        visualDisplayRuns(from: primaryRuns(fields))
    }

    static func composeSecondaryLine(_ fields: BrandingSecondaryFooterFields) -> String {
        var components = [fields.firstLabel, fields.firstNumber]

        if !fields.secondLabel.isEmpty && !fields.secondNumber.isEmpty {
            components.append(fields.secondLabel)
            components.append(fields.secondNumber)
        } else if !fields.secondNumber.isEmpty {
            components.append(fields.secondNumber)
        } else if !fields.secondLabel.isEmpty {
            components.append(fields.secondLabel)
        }

        return composeStructuredLine(components)
    }

    static func secondaryRuns(_ fields: BrandingSecondaryFooterFields) -> [FooterRun] {
        var components = [fields.firstLabel, fields.firstNumber]

        if !fields.secondLabel.isEmpty && !fields.secondNumber.isEmpty {
            components.append(fields.secondLabel)
            components.append(fields.secondNumber)
        } else if !fields.secondNumber.isEmpty {
            components.append(fields.secondNumber)
        } else if !fields.secondLabel.isEmpty {
            components.append(fields.secondLabel)
        }

        return structuredRuns(components)
    }

    static func secondaryDisplayRuns(_ fields: BrandingSecondaryFooterFields) -> [FooterRun] {
        visualDisplayRuns(from: secondaryRuns(fields))
    }

    static func visualDisplayRuns(from runs: [FooterRun]) -> [FooterRun] {
        runs.reversed()
    }

    static func plainText(from runs: [FooterRun]) -> String {
        runs.map(\.text).joined(separator: " ")
    }

    static func parsePrimaryLogicalLine(_ line: String) -> BrandingPrimaryFooterFields? {
        let tokens = tokenize(strippingDirectionalMarks(from: line))
        guard let emailIndex = tokens.firstIndex(where: isEmailToken),
              let phoneIndex = tokens[..<emailIndex].firstIndex(where: isPhoneToken),
              phoneIndex > tokens.startIndex else {
            return nil
        }

        let name = tokens[..<phoneIndex].joined(separator: " ")
        let phone = tokens[phoneIndex]
        let roleRangeStart = tokens.index(after: phoneIndex)
        let role = tokens[roleRangeStart..<emailIndex].joined(separator: " ")
        let email = tokens[emailIndex...].joined(separator: " ")

        guard !name.isEmpty, !phone.isEmpty else { return nil }

        return BrandingPrimaryFooterFields(
            contactName: name,
            roleLabel: role,
            phoneNumber: phone,
            emailAddress: email
        )
    }

    static func parsePrimaryReversedLine(_ line: String) -> BrandingPrimaryFooterFields? {
        let tokens = tokenize(strippingDirectionalMarks(from: line))
        guard let emailIndex = tokens.firstIndex(where: isEmailToken),
              let phoneIndex = tokens.lastIndex(where: isPhoneToken),
              emailIndex < phoneIndex,
              phoneIndex < tokens.index(before: tokens.endIndex) else {
            return nil
        }

        let email = tokens[emailIndex]
        let roleStart = tokens.index(after: emailIndex)
        let role = tokens[roleStart..<phoneIndex].joined(separator: " ")
        let phone = tokens[phoneIndex]
        let nameStart = tokens.index(after: phoneIndex)
        let name = tokens[nameStart...].joined(separator: " ")

        guard !name.isEmpty, !phone.isEmpty else { return nil }

        return BrandingPrimaryFooterFields(
            contactName: name,
            roleLabel: role,
            phoneNumber: phone,
            emailAddress: email
        )
    }

    static func parseSecondaryLogicalLine(_ line: String) -> BrandingSecondaryFooterFields? {
        let tokens = tokenize(strippingDirectionalMarks(from: line))
        let phoneIndices = tokens.indices.filter { isPhoneToken(tokens[$0]) }
        guard let firstPhoneIndex = phoneIndices.first, firstPhoneIndex > tokens.startIndex else {
            return nil
        }

        let firstLabel = tokens[..<firstPhoneIndex].joined(separator: " ")
        let firstNumber = tokens[firstPhoneIndex]

        let trailingTokens = tokens[tokens.index(after: firstPhoneIndex)...]
        if let secondPhoneRelativeIndex = trailingTokens.indices.first(where: { isPhoneToken(trailingTokens[$0]) }) {
            let secondLabel = trailingTokens[..<secondPhoneRelativeIndex].joined(separator: " ")
            let secondNumber = trailingTokens[secondPhoneRelativeIndex...].joined(separator: " ")
            return BrandingSecondaryFooterFields(
                firstLabel: firstLabel,
                firstNumber: firstNumber,
                secondLabel: secondLabel,
                secondNumber: secondNumber
            )
        }

        let trailing = trailingTokens.joined(separator: " ")
        if trailing.isEmpty {
            return BrandingSecondaryFooterFields(firstLabel: firstLabel, firstNumber: firstNumber)
        }

        return BrandingSecondaryFooterFields(
            firstLabel: firstLabel,
            firstNumber: firstNumber,
            secondLabel: trailing,
            secondNumber: ""
        )
    }

    private static func composeStructuredLine(_ components: [String]) -> String {
        components
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map(wrapTokenIfNeeded)
            .joined(separator: " ")
    }

    private static func structuredRuns(_ components: [String]) -> [FooterRun] {
        components
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map(runForToken)
    }

    private static func tokenize(_ value: String) -> [String] {
        value
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
    }

    private static func wrapTokenIfNeeded(_ token: String) -> String {
        let cleaned = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, isLTRLike(cleaned) else { return cleaned }
        return leftToRightMark + cleaned + leftToRightMark
    }

    private static func runForToken(_ token: String) -> FooterRun {
        let cleaned = token.trimmingCharacters(in: .whitespacesAndNewlines)
        if isLTRLike(cleaned) {
            return FooterRun(text: cleaned, direction: .leftToRight)
        }
        return FooterRun(text: cleaned, direction: .rightToLeft)
    }

    private static func isLTRLike(_ token: String) -> Bool {
        token.contains("@") ||
        token.unicodeScalars.contains(where: { CharacterSet.decimalDigits.contains($0) }) ||
        token.unicodeScalars.contains(where: isLatinLetter)
    }

    private static func isEmailToken(_ token: String) -> Bool {
        token.contains("@")
    }

    private static func isPhoneToken(_ token: String) -> Bool {
        let trimmed = token.trimmingCharacters(in: .punctuationCharacters)
        let digits = trimmed.filter(\.isNumber)
        guard digits.count >= 5 else { return false }

        return trimmed.unicodeScalars.allSatisfy { scalar in
            CharacterSet.decimalDigits.contains(scalar) ||
            CharacterSet(charactersIn: "+-()").contains(scalar)
        }
    }

    private static func isLatinLetter(_ scalar: UnicodeScalar) -> Bool {
        (0x0041...0x005A).contains(scalar.value) || (0x0061...0x007A).contains(scalar.value)
    }

    private static func containsHebrew(_ value: String) -> Bool {
        value.unicodeScalars.contains { (0x0590...0x05FF).contains($0.value) }
    }
}

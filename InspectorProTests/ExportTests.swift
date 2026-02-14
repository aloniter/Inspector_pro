import Testing
@testable import InspectorPro

@Test func imageQualityPresets() {
    #expect(ImageQuality.economical.maxWidth == 900)
    #expect(ImageQuality.economical.jpegQuality == 0.45)
    #expect(ImageQuality.balanced.maxWidth == 1400)
    #expect(ImageQuality.balanced.jpegQuality == 0.60)
    #expect(ImageQuality.high.maxWidth == 2000)
    #expect(ImageQuality.high.jpegQuality == 0.75)
}

@Test func severityLabels() {
    #expect(Severity.low.hebrewLabel == "נמוכה")
    #expect(Severity.medium.hebrewLabel == "בינונית")
    #expect(Severity.high.hebrewLabel == "גבוהה")
}

@Test func xmlEscaping() {
    let input = "Test & <value> \"quoted\" 'apos'"
    let escaped = OpenXMLBuilder.escapeXML(input)
    #expect(escaped == "Test &amp; &lt;value&gt; &quot;quoted&quot; &apos;apos&apos;")
}

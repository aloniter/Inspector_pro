import Foundation

/// Creates a minimal valid .docx template programmatically.
/// The template is a ZIP file containing OpenXML files with placeholders.
final class DocxTemplateBuilder {

    /// Create the template .docx file at the given URL
    static func createTemplate(at url: URL) throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("docx_template_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Create required directories
        let wordDir = tempDir.appendingPathComponent("word")
        let relsDir = tempDir.appendingPathComponent("_rels")
        let wordRelsDir = wordDir.appendingPathComponent("_rels")
        let mediaDir = wordDir.appendingPathComponent("media")

        for dir in [wordDir, relsDir, wordRelsDir, mediaDir] {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        // Write all required files
        try contentTypesXML().write(to: tempDir.appendingPathComponent("[Content_Types].xml"), atomically: true, encoding: .utf8)
        try rootRelsXML().write(to: relsDir.appendingPathComponent(".rels"), atomically: true, encoding: .utf8)
        try documentXML().write(to: wordDir.appendingPathComponent("document.xml"), atomically: true, encoding: .utf8)
        try documentRelsXML().write(to: wordRelsDir.appendingPathComponent("document.xml.rels"), atomically: true, encoding: .utf8)
        try stylesXML().write(to: wordDir.appendingPathComponent("styles.xml"), atomically: true, encoding: .utf8)
        try settingsXML().write(to: wordDir.appendingPathComponent("settings.xml"), atomically: true, encoding: .utf8)

        // Zip to .docx
        try zipDirectory(tempDir, to: url)
    }

    // MARK: - Content Types

    private static func contentTypesXML() -> String {
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
          <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
          <Default Extension="xml" ContentType="application/xml"/>
          <Default Extension="jpeg" ContentType="image/jpeg"/>
          <Default Extension="jpg" ContentType="image/jpeg"/>
          <Default Extension="png" ContentType="image/png"/>
          <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
          <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
          <Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/>
        </Types>
        """
    }

    // MARK: - Root Relationships

    private static func rootRelsXML() -> String {
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
        </Relationships>
        """
    }

    // MARK: - Document XML with Placeholders

    private static func documentXML() -> String {
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
                    xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
                    xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
                    xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
                    xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
          <w:body>
            <w:p>
              <w:pPr><w:bidi/><w:jc w:val="center"/></w:pPr>
              <w:r>
                <w:rPr><w:b/><w:bCs/><w:rtl/><w:sz w:val="48"/><w:szCs w:val="48"/></w:rPr>
                <w:t>{{PROJECT_TITLE}}</w:t>
              </w:r>
            </w:p>
            <w:p>
              <w:pPr><w:bidi/><w:jc w:val="center"/><w:spacing w:after="100"/></w:pPr>
              <w:r>
                <w:rPr><w:rtl/><w:sz w:val="24"/><w:szCs w:val="24"/></w:rPr>
                <w:t xml:space="preserve">כתובת: {{ADDRESS}}</w:t>
              </w:r>
            </w:p>
            <w:p>
              <w:pPr><w:bidi/><w:jc w:val="center"/><w:spacing w:after="100"/></w:pPr>
              <w:r>
                <w:rPr><w:rtl/><w:sz w:val="24"/><w:szCs w:val="24"/></w:rPr>
                <w:t xml:space="preserve">תאריך: {{DATE}}</w:t>
              </w:r>
            </w:p>
            <w:p>
              <w:pPr><w:bidi/><w:jc w:val="center"/><w:spacing w:after="100"/></w:pPr>
              <w:r>
                <w:rPr><w:rtl/><w:sz w:val="24"/><w:szCs w:val="24"/></w:rPr>
                <w:t xml:space="preserve">בודק: {{INSPECTOR}}</w:t>
              </w:r>
            </w:p>
            <w:p><w:r><w:br w:type="page"/></w:r></w:p>
            {{FINDINGS_BLOCK}}
          </w:body>
        </w:document>
        """
    }

    // MARK: - Document Relationships

    private static func documentRelsXML() -> String {
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
          <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/>
        </Relationships>
        """
    }

    // MARK: - Styles (RTL-aware)

    private static func stylesXML() -> String {
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
          <w:docDefaults>
            <w:rPrDefault>
              <w:rPr>
                <w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:cs="Arial"/>
                <w:sz w:val="20"/>
                <w:szCs w:val="20"/>
                <w:lang w:bidi="he-IL"/>
              </w:rPr>
            </w:rPrDefault>
            <w:pPrDefault>
              <w:pPr>
                <w:bidi/>
                <w:spacing w:after="40" w:line="276" w:lineRule="auto"/>
              </w:pPr>
            </w:pPrDefault>
          </w:docDefaults>
          <w:style w:type="paragraph" w:styleId="Normal" w:default="1">
            <w:name w:val="Normal"/>
            <w:pPr><w:bidi/></w:pPr>
            <w:rPr><w:rtl/></w:rPr>
          </w:style>
        </w:styles>
        """
    }

    // MARK: - Settings (RTL document)

    private static func settingsXML() -> String {
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
          <w:bidi/>
          <w:defaultTabStop w:val="720"/>
        </w:settings>
        """
    }

    // MARK: - ZIP Helper

    private static func zipDirectory(_ sourceDir: URL, to destURL: URL) throws {
        // Use Foundation's built-in zip approach
        let coordinator = NSFileCoordinator()
        var error: NSError?

        // Simple approach: use the command line zip or ZIPFoundation
        // We'll import ZIPFoundation in DocxExporter which calls this
        // For now, we prepare the files and DocxExporter handles zipping
        // This method is called from DocxExporter which has ZIPFoundation access

        // Actually, let's just write the files and let DocxExporter handle zip
        // This is a preparation-only method
        throw DocxTemplateError.zipNotAvailable
    }

    enum DocxTemplateError: Error {
        case zipNotAvailable
    }
}

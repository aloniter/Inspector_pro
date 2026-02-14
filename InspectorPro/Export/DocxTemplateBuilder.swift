import Foundation

/// Provides XML template strings for DOCX document generation.
/// Used by DocxExporter to build the OpenXML structure.
final class DocxTemplateBuilder {

    // MARK: - Content Types

    static func contentTypesXML() -> String {
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

    static func rootRelsXML() -> String {
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
        </Relationships>
        """
    }

    // MARK: - Document XML with Placeholders

    static func documentXML() -> String {
        let isHebrew = AppLanguage.current == .hebrew
        let addressLabel = AppStrings.text("כתובת")
        let dateLabel = AppStrings.text("תאריך")
        let notesLabel = AppStrings.text("הערות")
        let paragraphDirectionTag = isHebrew ? "<w:bidi/>" : ""
        let runDirectionTag = isHebrew ? "<w:rtl/>" : ""

        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
                    xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
                    xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
                    xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
                    xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
          <w:body>
            <w:p>
              <w:pPr>\(paragraphDirectionTag)<w:jc w:val="center"/></w:pPr>
              <w:r>
                <w:rPr><w:b/><w:bCs/>\(runDirectionTag)<w:sz w:val="48"/><w:szCs w:val="48"/><w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:cs="Arial"/></w:rPr>
                <w:t>{{PROJECT_TITLE}}</w:t>
              </w:r>
            </w:p>
            <w:p>
              <w:pPr>\(paragraphDirectionTag)<w:jc w:val="center"/><w:spacing w:after="100"/></w:pPr>
              <w:r>
                <w:rPr>\(runDirectionTag)<w:sz w:val="24"/><w:szCs w:val="24"/><w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:cs="Arial"/></w:rPr>
                <w:t xml:space="preserve">\(addressLabel): {{ADDRESS}}</w:t>
              </w:r>
            </w:p>
            <w:p>
              <w:pPr>\(paragraphDirectionTag)<w:jc w:val="center"/><w:spacing w:after="100"/></w:pPr>
              <w:r>
                <w:rPr>\(runDirectionTag)<w:sz w:val="24"/><w:szCs w:val="24"/><w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:cs="Arial"/></w:rPr>
                <w:t xml:space="preserve">\(dateLabel): {{DATE}}</w:t>
              </w:r>
            </w:p>
            <w:p>
              <w:pPr>\(paragraphDirectionTag)<w:jc w:val="center"/><w:spacing w:after="100"/></w:pPr>
              <w:r>
                <w:rPr>\(runDirectionTag)<w:sz w:val="24"/><w:szCs w:val="24"/><w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:cs="Arial"/></w:rPr>
                <w:t xml:space="preserve">\(notesLabel): {{NOTES}}</w:t>
              </w:r>
            </w:p>
            <w:p><w:r><w:br w:type="page"/></w:r></w:p>
            {{PHOTOS_TABLE}}
            <w:sectPr>
              <w:pgSz w:w="11906" w:h="16838"/>
              <w:pgMar w:top="720" w:right="720" w:bottom="720" w:left="720" w:header="708" w:footer="708" w:gutter="0"/>
            </w:sectPr>
          </w:body>
        </w:document>
        """
    }

    // MARK: - Document Relationships

    static func documentRelsXML(imageRelationships: [String]) -> String {
        let imageRels = imageRelationships.joined(separator: "\n  ")
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
          <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/>
          \(imageRels)
        </Relationships>
        """
    }

    // MARK: - Styles

    static func stylesXML() -> String {
        let isHebrew = AppLanguage.current == .hebrew
        let languageTag = isHebrew ? "<w:lang w:bidi=\"he-IL\"/>" : "<w:lang w:val=\"en-US\"/>"
        let paragraphDirectionTag = isHebrew ? "<w:bidi/>" : ""
        let runDirectionTag = isHebrew ? "<w:rtl/>" : ""

        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
          <w:docDefaults>
            <w:rPrDefault>
              <w:rPr>
                <w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:cs="Arial"/>
                <w:sz w:val="20"/>
                <w:szCs w:val="20"/>
                \(languageTag)
              </w:rPr>
            </w:rPrDefault>
            <w:pPrDefault>
              <w:pPr>
                \(paragraphDirectionTag)
                <w:spacing w:after="40" w:line="276" w:lineRule="auto"/>
              </w:pPr>
            </w:pPrDefault>
          </w:docDefaults>
          <w:style w:type="paragraph" w:styleId="Normal" w:default="1">
            <w:name w:val="Normal"/>
            <w:pPr>\(paragraphDirectionTag)</w:pPr>
            <w:rPr>\(runDirectionTag)</w:rPr>
          </w:style>
        </w:styles>
        """
    }

    // MARK: - Settings

    static func settingsXML() -> String {
        let documentDirectionTag = AppLanguage.current == .hebrew ? "<w:bidi/>" : ""
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
          \(documentDirectionTag)
          <w:defaultTabStop w:val="720"/>
        </w:settings>
        """
    }
}

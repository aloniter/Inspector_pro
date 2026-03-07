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
          <Override PartName="/word/header1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml"/>
          <Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/>
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
        documentXML(options: ExportOptions(format: .docx, quality: .balanced))
    }

    static func documentXML(options: ExportOptions) -> String {
        let addressLabel = AppStrings.text("כתובת")
        let dateLabel = AppStrings.text("תאריך")
        let notesLabel = AppStrings.text("הערות")
        let bidiTag = AppLanguage.current == .hebrew ? "<w:bidi/><w:rtlGutter/>" : ""

        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
                    xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
                    xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
                    xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
                    xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
          <w:body>
            <w:p>
              <w:pPr><w:jc w:val="center"/></w:pPr>
              <w:r>
                <w:rPr><w:b/><w:bCs/><w:sz w:val="48"/><w:szCs w:val="48"/><w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:cs="Arial"/></w:rPr>
                <w:t>{{PROJECT_TITLE}}</w:t>
              </w:r>
            </w:p>
            <w:p>
              <w:pPr><w:spacing w:after="100"/><w:jc w:val="center"/></w:pPr>
              <w:r>
                <w:rPr><w:sz w:val="24"/><w:szCs w:val="24"/><w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:cs="Arial"/></w:rPr>
                <w:t xml:space="preserve">\(addressLabel): {{ADDRESS}}</w:t>
              </w:r>
            </w:p>
            <w:p>
              <w:pPr><w:spacing w:after="100"/><w:jc w:val="center"/></w:pPr>
              <w:r>
                <w:rPr><w:sz w:val="24"/><w:szCs w:val="24"/><w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:cs="Arial"/></w:rPr>
                <w:t xml:space="preserve">\(dateLabel): {{DATE}}</w:t>
              </w:r>
            </w:p>
            <w:p>
              <w:pPr><w:spacing w:after="100"/><w:jc w:val="center"/></w:pPr>
              <w:r>
                <w:rPr><w:sz w:val="24"/><w:szCs w:val="24"/><w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:cs="Arial"/></w:rPr>
                <w:t xml:space="preserve">\(notesLabel): {{NOTES}}</w:t>
              </w:r>
            </w:p>
            <w:p><w:r><w:br w:type="page"/></w:r></w:p>
            {{PHOTOS_TABLE}}
            <w:sectPr>
              <w:headerReference w:type="default" r:id="rId8"/>
              <w:footerReference w:type="default" r:id="rId9"/>
              <w:pgSz w:w="11906" w:h="16838"/>
              <w:pgMar w:top="\(options.docxTopMarginTwips)" w:right="\(options.docxRightMarginTwips)" w:bottom="\(options.docxBottomMarginTwips)" w:left="\(options.docxLeftMarginTwips)" w:header="\(options.docxHeaderDistanceTwips)" w:footer="\(options.docxFooterDistanceTwips)" w:gutter="0"/>
              \(bidiTag)
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
          <Relationship Id="rId8" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/header" Target="header1.xml"/>
          <Relationship Id="rId9" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer" Target="footer1.xml"/>
          \(imageRels)
        </Relationships>
        """
    }

    // MARK: - Header / Footer

    static func headerXML() -> String {
        let logoSizeEMU = 952500 // 75pt
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <w:hdr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
               xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
               xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
               xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
               xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
          <w:p>
            <w:pPr><w:jc w:val="left"/><w:spacing w:after="0" w:line="240" w:lineRule="auto"/></w:pPr>
            <w:r>
              <w:drawing>
                <wp:inline distT="0" distB="0" distL="0" distR="0">
                  <wp:extent cx="\(logoSizeEMU)" cy="\(logoSizeEMU)"/>
                  <wp:effectExtent l="0" t="0" r="0" b="0"/>
                  <wp:docPr id="1" name="Logo"/>
                  <a:graphic>
                    <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
                      <pic:pic>
                        <pic:nvPicPr>
                          <pic:cNvPr id="1" name="image1.jpeg"/>
                          <pic:cNvPicPr/>
                        </pic:nvPicPr>
                        <pic:blipFill>
                          <a:blip r:embed="rId1"/>
                          <a:stretch><a:fillRect/></a:stretch>
                        </pic:blipFill>
                        <pic:spPr>
                          <a:xfrm>
                            <a:off x="0" y="0"/>
                            <a:ext cx="\(logoSizeEMU)" cy="\(logoSizeEMU)"/>
                          </a:xfrm>
                          <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
                        </pic:spPr>
                      </pic:pic>
                    </a:graphicData>
                  </a:graphic>
                </wp:inline>
              </w:drawing>
            </w:r>
          </w:p>
        </w:hdr>
        """
    }

    static func footerXML() -> String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
          <w:p>
            <w:pPr>
              <w:jc w:val="center"/>
              <w:spacing w:after="0" w:line="240" w:lineRule="auto"/>
              <w:pBdr><w:top w:val="single" w:sz="4" w:space="1" w:color="000000"/></w:pBdr>
            </w:pPr>
            <w:r>
              <w:rPr>
                <w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:cs="Arial"/>
                <w:sz w:val="16"/><w:szCs w:val="16"/>
                <w:color w:val="002060"/>
              </w:rPr>
              <w:t xml:space="preserve">כפר ויתקין, ת"ד 635 מיקוד 4020000</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:jc w:val="center"/>
              <w:spacing w:after="0" w:line="240" w:lineRule="auto"/>
            </w:pPr>
            <w:r>
              <w:rPr>
                <w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:cs="Arial"/>
                <w:sz w:val="16"/><w:szCs w:val="16"/>
                <w:color w:val="002060"/>
              </w:rPr>
              <w:t xml:space="preserve">אבישי 054-6222577 דוא"ל iter@iter.co.il</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:jc w:val="center"/>
              <w:spacing w:after="0" w:line="240" w:lineRule="auto"/>
            </w:pPr>
            <w:r>
              <w:rPr>
                <w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:cs="Arial"/>
                <w:sz w:val="16"/><w:szCs w:val="16"/>
                <w:color w:val="002060"/>
              </w:rPr>
              <w:t xml:space="preserve">דפנה 054-6222575 משרד 09-8665885</w:t>
            </w:r>
          </w:p>
        </w:ftr>
        """
    }

    static func headerRelsXML() -> String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/image1.jpeg"/>
        </Relationships>
        """
    }

    // MARK: - Styles

    static func stylesXML() -> String {
        let isHebrew = AppLanguage.current == .hebrew
        let languageTag = isHebrew
            ? "<w:lang w:val=\"he-IL\" w:bidi=\"he-IL\"/>"
            : "<w:lang w:val=\"en-US\"/>"

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
                <w:spacing w:after="40" w:line="276" w:lineRule="auto"/>
              </w:pPr>
            </w:pPrDefault>
          </w:docDefaults>
          <w:style w:type="paragraph" w:styleId="Normal" w:default="1">
            <w:name w:val="Normal"/>
            <w:pPr/>
            <w:rPr/>
          </w:style>
        </w:styles>
        """
    }

    // MARK: - Settings

    static func settingsXML() -> String {
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
          <w:compat>
            <w:compatSetting w:name="compatibilityMode" w:uri="http://schemas.microsoft.com/office/word" w:val="15"/>
          </w:compat>
          <w:defaultTabStop w:val="720"/>
        </w:settings>
        """
    }
}

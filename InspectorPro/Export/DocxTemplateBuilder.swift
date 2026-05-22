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
  <Override PartName="/word/numbering.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml"/>
  <Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/>
  <Override PartName="/word/webSettings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.webSettings+xml"/>
  <Override PartName="/word/footnotes.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footnotes+xml"/>
  <Override PartName="/word/endnotes.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.endnotes+xml"/>
  <Override PartName="/word/header1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml"/>
  <Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/>
  <Override PartName="/word/fontTable.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.fontTable+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>
"""
    }

    // MARK: - Root Relationships

    static func rootRelsXML() -> String {
        return """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>
"""
    }

    // MARK: - Document XML with Placeholders

    static func documentXML() -> String {
        documentXML(options: ExportOptions(format: .docx, quality: .balanced))
    }

    static func documentXML(options: ExportOptions) -> String {
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
      <w:pPr><w:spacing w:before="1520" w:after="180"/><w:jc w:val="center"/>\(AppLanguage.current == .hebrew ? "<w:bidi/>" : "")</w:pPr>
      <w:r>
        <w:rPr><w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:cs="Arial"/><w:b/><w:bCs/>\(AppLanguage.current == .hebrew ? "<w:rtl/>" : "")<w:color w:val="0F172A"/><w:sz w:val="52"/><w:szCs w:val="52"/></w:rPr>
        <w:t>{{PROJECT_TITLE}}</w:t>
      </w:r>
    </w:p>
    <w:p>
      <w:pPr>
        <w:pBdr><w:bottom w:val="single" w:sz="6" w:space="8" w:color="D6DEE8"/></w:pBdr>
        <w:spacing w:after="340"/>
        <w:jc w:val="center"/>
      </w:pPr>
      <w:r>
        <w:t xml:space="preserve"> </w:t>
      </w:r>
    </w:p>
    {{COVER_DETAILS}}
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

    static func coverDetailsXML(
        address: String,
        date: String,
        attendees: String?,
        notes: String?
    ) -> String {
        var sections = [
            coverFieldSectionXML(label: AppStrings.text("כתובת"), value: address),
            coverFieldSectionXML(label: AppStrings.text("תאריך"), value: date),
        ]

        if let attendees {
            sections.append(attendeesCoverFieldSectionXML(label: AppStrings.text("נוכחים"), value: attendees))
        }

        if let notes {
            sections.append(
                coverFieldSectionXML(
                    label: AppStrings.text("הערות"),
                    value: notes,
                    valueFontSize: ExportTypography.Cover.notesContentDocxSize,
                    valueAlignment: "center",
                    isLast: true
                )
            )
        }
        return sections.joined()
    }

    // MARK: - Document Relationships

    private static func coverFieldSectionXML(
        label: String,
        value: String,
        labelFontSize: Int = ExportTypography.Cover.metadataDocxSize,
        valueFontSize: Int = ExportTypography.Cover.metadataDocxSize,
        valueBold: Bool = false,
        valueAlignment: String = "center",
        isLast: Bool = false
    ) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let valueLines = trimmedValue.isEmpty
            ? ["—"]
            : trimmedValue
                .split(separator: "\n", omittingEmptySubsequences: false)
                .map { segment in
                    let line = String(segment).trimmingCharacters(in: .whitespacesAndNewlines)
                    return line.isEmpty ? "—" : line
                }

        let labelParagraph = coverParagraphXML(
            text: label,
            fontSize: labelFontSize,
            bold: true,
            color: "64748B",
            spacingBefore: 0,
            spacingAfter: 50
        )

        let valueParagraphs = valueLines.enumerated().map { index, line in
            coverParagraphXML(
                text: line,
                fontSize: valueFontSize,
                bold: valueBold,
                color: "111827",
                spacingBefore: 0,
                spacingAfter: index == valueLines.count - 1 ? (isLast ? 120 : 260) : 40,
                alignment: valueAlignment
            )
        }.joined()

        return labelParagraph + valueParagraphs
    }

    private static func attendeesCoverFieldSectionXML(
        label: String,
        value: String
    ) -> String {
        let valueLines = ExportTextFormatter.numberedAttendeeLines(from: value)

        let labelParagraph = coverParagraphXML(
            text: ExportTextFormatter.rtlHeadingText("\(label):"),
            fontSize: ExportTypography.Cover.attendeesHeadingDocxSize,
            bold: true,
            color: "64748B",
            spacingBefore: 0,
            spacingAfter: 70,
            alignment: "center"
        )

        let valueParagraphs = valueLines.enumerated().map { index, line in
            coverParagraphXML(
                text: line,
                fontSize: ExportTypography.Cover.attendeeItemDocxSize,
                color: "111827",
                spacingBefore: 0,
                spacingAfter: index == valueLines.count - 1 ? 260 : 40,
                alignment: "center"
            )
        }.joined()

        return labelParagraph + valueParagraphs
    }

    private static func coverParagraphXML(
        text: String,
        fontSize: Int,
        bold: Bool = false,
        color: String,
        spacingBefore: Int,
        spacingAfter: Int,
        alignment: String = "center"
    ) -> String {
        let boldTag = bold ? "<w:b/><w:bCs/>" : ""
        let bidiTag = AppLanguage.current == .hebrew ? "<w:bidi/>" : ""
        let rtlTag = AppLanguage.current == .hebrew ? "<w:rtl/>" : ""
        let escapedText = OpenXMLBuilder.escapeXML(text)

        return """
    <w:p>
      <w:pPr><w:spacing w:before="\(spacingBefore)" w:after="\(spacingAfter)"/><w:jc w:val="\(alignment)"/>\(bidiTag)</w:pPr>
      <w:r>
        <w:rPr><w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:cs="Arial"/>\(boldTag)\(rtlTag)<w:color w:val="\(color)"/><w:sz w:val="\(fontSize)"/><w:szCs w:val="\(fontSize)"/></w:rPr>
        <w:t xml:space="preserve">\(escapedText)</w:t>
      </w:r>
    </w:p>
"""
    }

    static func documentRelsXML(imageRelationships: [String]) -> String {
        let imageRels = imageRelationships.joined(separator: "\n  ")
        return """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/webSettings" Target="webSettings.xml"/>
  <Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footnotes" Target="footnotes.xml"/>
  <Relationship Id="rId5" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/endnotes" Target="endnotes.xml"/>
  <Relationship Id="rId6" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/fontTable" Target="fontTable.xml"/>
  <Relationship Id="rId7" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/numbering" Target="numbering.xml"/>
  <Relationship Id="rId8" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/header" Target="header1.xml"/>
  <Relationship Id="rId9" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer" Target="footer1.xml"/>
  \(imageRels)
</Relationships>
"""
    }

    // MARK: - Header / Footer

    static func headerXML(
        includesLogo: Bool = true,
        logoWidthEMU: Int = 952500,
        logoHeightEMU: Int = 952500
    ) -> String {
        guard includesLogo else {
            return """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:hdr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:p>
    <w:pPr><w:spacing w:after="0" w:line="240" w:lineRule="auto"/><w:jc w:val="left"/></w:pPr>
  </w:p>
</w:hdr>
"""
        }

        return """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:hdr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
       xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
       xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
       xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
       xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
  <w:p>
    <w:pPr><w:spacing w:after="0" w:line="240" w:lineRule="auto"/><w:jc w:val="left"/></w:pPr>
    <w:r>
      <w:drawing>
        <wp:inline distT="0" distB="0" distL="0" distR="0">
          <wp:extent cx="\(logoWidthEMU)" cy="\(logoHeightEMU)"/>
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
                    <a:ext cx="\(logoWidthEMU)" cy="\(logoHeightEMU)"/>
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

    static func footerXML(branding: ResolvedExportBranding) -> String {
        guard branding.hasVisibleFooterContent else {
            return """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:p/>
</w:ftr>
"""
        }

        var paragraphs: [String] = []

        if !branding.footerAddressLine.isEmpty {
            paragraphs.append(
                OpenXMLBuilder.footerParagraph(
                    text: branding.footerAddressLine,
                    fontSize: 16,
                    color: branding.footerTextColorHex,
                    topBorder: paragraphs.isEmpty
                )
            )
        }

        if !branding.primaryFooterDisplayRuns.isEmpty {
            paragraphs.append(
                OpenXMLBuilder.footerParagraph(
                    runs: branding.primaryFooterDisplayRuns,
                    fontSize: 16,
                    color: branding.footerTextColorHex,
                    topBorder: paragraphs.isEmpty,
                    enforcesVisualOrder: true
                )
            )
        }

        if !branding.secondaryFooterDisplayRuns.isEmpty {
            paragraphs.append(
                OpenXMLBuilder.footerParagraph(
                    runs: branding.secondaryFooterDisplayRuns,
                    fontSize: 16,
                    color: branding.footerTextColorHex,
                    topBorder: paragraphs.isEmpty,
                    enforcesVisualOrder: true
                )
            )
        }

        return """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  \(paragraphs.joined(separator: "\n  "))
</w:ftr>
"""
    }

    static func headerRelsXML(includesLogo: Bool = true) -> String {
        guard includesLogo else {
            return """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
</Relationships>
"""
        }

        return """
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
  <w:style w:type="paragraph" w:styleId="InspectorDescriptionBullet">
    <w:name w:val="Inspector Description Bullet"/>
    <w:basedOn w:val="Normal"/>
    <w:pPr>
      <w:numPr>
        <w:ilvl w:val="0"/>
        <w:numId w:val="1"/>
      </w:numPr>
      <w:bidi/>
      <w:spacing w:after="60" w:line="240" w:lineRule="auto"/>
      <w:ind w:start="540" w:hanging="360"/>
      <w:jc w:val="start"/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:cs="Arial"/>
      <w:color w:val="222222"/>
      <w:sz w:val="22"/>
      <w:szCs w:val="22"/>
      <w:rtl/>
      <w:lang w:val="he-IL" w:bidi="he-IL"/>
    </w:rPr>
  </w:style>
</w:styles>
"""
    }

    static func numberingXML() -> String {
        return """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:numbering xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:abstractNum w:abstractNumId="1">
    <w:multiLevelType w:val="singleLevel"/>
    <w:lvl w:ilvl="0">
      <w:start w:val="1"/>
      <w:numFmt w:val="bullet"/>
      <w:suff w:val="space"/>
      <w:lvlText w:val="•"/>
      <w:lvlJc w:val="right"/>
      <w:pPr>
        <w:bidi/>
        <w:spacing w:after="60" w:line="240" w:lineRule="auto"/>
        <w:ind w:start="540" w:hanging="360"/>
        <w:jc w:val="start"/>
      </w:pPr>
      <w:rPr>
        <w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:cs="Arial"/>
        <w:color w:val="222222"/>
        <w:sz w:val="22"/>
        <w:szCs w:val="22"/>
        <w:rtl/>
        <w:lang w:val="he-IL" w:bidi="he-IL"/>
      </w:rPr>
    </w:lvl>
  </w:abstractNum>
  <w:num w:numId="1">
    <w:abstractNumId w:val="1"/>
  </w:num>
</w:numbering>
"""
    }

    // MARK: - Document Properties

    static func corePropertiesXML() -> String {
        let iso8601 = ISO8601DateFormatter()
        iso8601.formatOptions = [.withInternetDateTime]
        let now = iso8601.string(from: Date())
        return """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
                   xmlns:dc="http://purl.org/dc/elements/1.1/"
                   xmlns:dcterms="http://purl.org/dc/terms/"
                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:creator>\(OpenXMLBuilder.escapeXML(AppBranding.createdByText))</dc:creator>
  <dcterms:created xsi:type="dcterms:W3CDTF">\(now)</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">\(now)</dcterms:modified>
  <cp:revision>1</cp:revision>
</cp:coreProperties>
"""
    }

    static func appPropertiesXML() -> String {
        return """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties">
  <Application>InspectorPro</Application>
  <AppVersion>1.0</AppVersion>
</Properties>
"""
    }

    // MARK: - Supporting Parts

    static func webSettingsXML() -> String {
        return """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:webSettings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:optimizeForBrowser/>
</w:webSettings>
"""
    }

    static func footnotesXML() -> String {
        return """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:footnotes xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
             xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:footnote w:type="separator" w:id="-1">
    <w:p><w:r><w:separator/></w:r></w:p>
  </w:footnote>
  <w:footnote w:type="continuationSeparator" w:id="0">
    <w:p><w:r><w:continuationSeparator/></w:r></w:p>
  </w:footnote>
</w:footnotes>
"""
    }

    static func endnotesXML() -> String {
        return """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:endnotes xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
            xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:endnote w:type="separator" w:id="-1">
    <w:p><w:r><w:separator/></w:r></w:p>
  </w:endnote>
  <w:endnote w:type="continuationSeparator" w:id="0">
    <w:p><w:r><w:continuationSeparator/></w:r></w:p>
  </w:endnote>
</w:endnotes>
"""
    }

    static func fontTableXML() -> String {
        return """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:fonts xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:font w:name="Arial">
    <w:panose1 w:val="020B0604020202020204"/>
    <w:charset w:val="00"/>
    <w:family w:val="swiss"/>
    <w:pitch w:val="variable"/>
  </w:font>
  <w:font w:name="Times New Roman">
    <w:panose1 w:val="02020603050405020304"/>
    <w:charset w:val="00"/>
    <w:family w:val="roman"/>
    <w:pitch w:val="variable"/>
  </w:font>
  <w:font w:name="Calibri">
    <w:panose1 w:val="020F0502020204030204"/>
    <w:charset w:val="00"/>
    <w:family w:val="swiss"/>
    <w:pitch w:val="variable"/>
  </w:font>
</w:fonts>
"""
    }

    // MARK: - Settings

    static func settingsXML() -> String {
        return """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:defaultTabStop w:val="720"/>
  <w:compat>
    <w:compatSetting w:name="compatibilityMode" w:uri="http://schemas.microsoft.com/office/word" w:val="15"/>
  </w:compat>
</w:settings>
"""
    }
}

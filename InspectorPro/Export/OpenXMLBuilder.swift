import Foundation
import UIKit

/// Generates OpenXML fragments for DOCX document content
final class OpenXMLBuilder {

    // MARK: - Finding Table

    /// Build a 2-column finding table: LEFT=image, RIGHT=RTL text
    static func buildFindingTable(
        finding: Finding,
        mainImageRelId: String,
        imageWidthEMU: Int,
        imageHeightEMU: Int,
        imageId: Int,
        options: ExportOptions
    ) -> String {
        let textContent = buildFindingTextContent(finding)

        return """
        <w:tbl>
          <w:tblPr>
            <w:bidiVisual/>
            <w:tblW w:w="5000" w:type="pct"/>
            <w:tblBorders>
              <w:top w:val="single" w:sz="4" w:space="0" w:color="999999"/>
              <w:left w:val="single" w:sz="4" w:space="0" w:color="999999"/>
              <w:bottom w:val="single" w:sz="4" w:space="0" w:color="999999"/>
              <w:right w:val="single" w:sz="4" w:space="0" w:color="999999"/>
              <w:insideH w:val="single" w:sz="4" w:space="0" w:color="999999"/>
              <w:insideV w:val="single" w:sz="4" w:space="0" w:color="999999"/>
            </w:tblBorders>
            <w:tblCellMar>
              <w:top w:w="72" w:type="dxa"/>
              <w:left w:w="72" w:type="dxa"/>
              <w:bottom w:w="72" w:type="dxa"/>
              <w:right w:w="72" w:type="dxa"/>
            </w:tblCellMar>
          </w:tblPr>
          <w:tblGrid>
            <w:gridCol w:w="6000"/>
            <w:gridCol w:w="4000"/>
          </w:tblGrid>
          <w:tr>
            <w:tc>
              <w:tcPr><w:tcW w:w="6000" w:type="dxa"/></w:tcPr>
              <w:p>
                <w:pPr><w:jc w:val="center"/></w:pPr>
                <w:r>
                  \(buildInlineImage(relId: mainImageRelId, widthEMU: imageWidthEMU, heightEMU: imageHeightEMU, imageId: imageId))
                </w:r>
              </w:p>
            </w:tc>
            <w:tc>
              <w:tcPr><w:tcW w:w="4000" w:type="dxa"/></w:tcPr>
              \(textContent)
            </w:tc>
          </w:tr>
        </w:tbl>
        """
    }

    // MARK: - Finding Text Content

    private static func buildFindingTextContent(_ finding: Finding) -> String {
        var xml = ""

        // Header: number + room
        xml += rtlParagraph(
            text: "\(finding.number). חדר: \(finding.room)",
            bold: true,
            fontSize: 24
        )

        // Title
        xml += rtlParagraph(
            text: finding.title,
            bold: true,
            fontSize: 22
        )

        // Description bullet
        if !finding.findingDescription.isEmpty {
            xml += rtlParagraph(text: "• \(finding.findingDescription)")
        }

        // Recommendation bullet
        if !finding.recommendation.isEmpty {
            xml += rtlParagraph(text: "• \(finding.recommendation)")
        }

        // Severity
        xml += rtlParagraph(text: "• חומרה: \(finding.severity.hebrewLabel)")

        return xml
    }

    // MARK: - Additional Image

    /// Build a full-width image block with caption for additional photos
    static func buildAdditionalImage(
        relId: String,
        widthEMU: Int,
        heightEMU: Int,
        imageId: Int,
        caption: String
    ) -> String {
        return """
        <w:p>
          <w:pPr><w:jc w:val="center"/></w:pPr>
          <w:r>
            \(buildInlineImage(relId: relId, widthEMU: widthEMU, heightEMU: heightEMU, imageId: imageId))
          </w:r>
        </w:p>
        \(rtlParagraph(text: caption, fontSize: 18, alignment: "center", color: "888888"))
        """
    }

    // MARK: - Page Break

    static func buildPageBreak() -> String {
        return """
        <w:p><w:r><w:br w:type="page"/></w:r></w:p>
        """
    }

    // MARK: - Spacing Paragraph

    static func buildSpacing(points: Int = 200) -> String {
        return """
        <w:p>
          <w:pPr>
            <w:spacing w:after="\(points)"/>
          </w:pPr>
        </w:p>
        """
    }

    // MARK: - RTL Paragraph Helper

    static func rtlParagraph(
        text: String,
        bold: Bool = false,
        fontSize: Int = 20,
        alignment: String = "right",
        color: String? = nil
    ) -> String {
        let boldTag = bold ? "<w:b/><w:bCs/>" : ""
        let colorTag = color != nil ? "<w:color w:val=\"\(color!)\"/>" : ""

        return """
        <w:p>
          <w:pPr>
            <w:bidi/>
            <w:jc w:val="\(alignment)"/>
          </w:pPr>
          <w:r>
            <w:rPr>
              <w:rtl/>
              <w:rFonts w:cs="Arial"/>
              <w:sz w:val="\(fontSize)"/>
              <w:szCs w:val="\(fontSize)"/>
              \(boldTag)
              \(colorTag)
            </w:rPr>
            <w:t xml:space="preserve">\(escapeXML(text))</w:t>
          </w:r>
        </w:p>
        """
    }

    // MARK: - DrawingML Inline Image

    private static func buildInlineImage(
        relId: String,
        widthEMU: Int,
        heightEMU: Int,
        imageId: Int
    ) -> String {
        return """
        <w:drawing>
          <wp:inline distT="0" distB="0" distL="0" distR="0">
            <wp:extent cx="\(widthEMU)" cy="\(heightEMU)"/>
            <wp:docPr id="\(imageId)" name="Image\(imageId)"/>
            <a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
              <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
                <pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
                  <pic:nvPicPr>
                    <pic:cNvPr id="\(imageId)" name="Image\(imageId)"/>
                    <pic:cNvPicPr/>
                  </pic:nvPicPr>
                  <pic:blipFill>
                    <a:blip r:embed="\(relId)"/>
                    <a:stretch><a:fillRect/></a:stretch>
                  </pic:blipFill>
                  <pic:spPr>
                    <a:xfrm>
                      <a:off x="0" y="0"/>
                      <a:ext cx="\(widthEMU)" cy="\(heightEMU)"/>
                    </a:xfrm>
                    <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
                  </pic:spPr>
                </pic:pic>
              </a:graphicData>
            </a:graphic>
          </wp:inline>
        </w:drawing>
        """
    }

    // MARK: - XML Escaping

    static func escapeXML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}

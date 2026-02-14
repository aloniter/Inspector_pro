import Foundation

/// Generates OpenXML fragments for DOCX document content.
final class OpenXMLBuilder {
    static func buildPhotosTable(
        rowsXML: String,
        tableWidthTwips: Int,
        imageColumnWidthTwips: Int,
        textColumnWidthTwips: Int
    ) -> String {
        """
        <w:tbl>
          <w:tblPr>
            <w:tblW w:w="\(tableWidthTwips)" w:type="dxa"/>
            <w:tblLayout w:type="fixed"/>
            <w:tblBorders>
              <w:top w:val="single" w:sz="8" w:space="0" w:color="000000"/>
              <w:left w:val="single" w:sz="8" w:space="0" w:color="000000"/>
              <w:bottom w:val="single" w:sz="8" w:space="0" w:color="000000"/>
              <w:right w:val="single" w:sz="8" w:space="0" w:color="000000"/>
              <w:insideH w:val="single" w:sz="8" w:space="0" w:color="000000"/>
              <w:insideV w:val="single" w:sz="8" w:space="0" w:color="000000"/>
            </w:tblBorders>
            <w:tblCellMar>
              <w:top w:w="100" w:type="dxa"/>
              <w:left w:w="100" w:type="dxa"/>
              <w:bottom w:w="100" w:type="dxa"/>
              <w:right w:w="100" w:type="dxa"/>
            </w:tblCellMar>
          </w:tblPr>
          <w:tblGrid>
            <w:gridCol w:w="\(imageColumnWidthTwips)"/>
            <w:gridCol w:w="\(textColumnWidthTwips)"/>
          </w:tblGrid>
          \(buildHeaderRow(imageColumnWidthTwips: imageColumnWidthTwips, textColumnWidthTwips: textColumnWidthTwips))
          \(rowsXML)
        </w:tbl>
        """
    }

    static func buildPhotoRow(
        photoNumber: Int,
        freeText: String,
        imageRelId: String,
        imageWidthEMU: Int,
        imageHeightEMU: Int,
        imageId: Int,
        rowHeightTwips: Int,
        imageColumnWidthTwips: Int,
        textColumnWidthTwips: Int
    ) -> String {
        """
        <w:tr>
          <w:trPr>
            <w:cantSplit/>
            <w:trHeight w:val="\(rowHeightTwips)" w:hRule="exact"/>
          </w:trPr>
          <w:tc>
            <w:tcPr>
              <w:tcW w:w="\(imageColumnWidthTwips)" w:type="dxa"/>
              <w:vAlign w:val="center"/>
            </w:tcPr>
            <w:p>
              <w:pPr><w:jc w:val="center"/></w:pPr>
              <w:r>
                \(buildInlineImage(relId: imageRelId, widthEMU: imageWidthEMU, heightEMU: imageHeightEMU, imageId: imageId))
              </w:r>
            </w:p>
          </w:tc>
          <w:tc>
            <w:tcPr>
              <w:tcW w:w="\(textColumnWidthTwips)" w:type="dxa"/>
              <w:vAlign w:val="top"/>
              <w:shd w:val="clear" w:color="auto" w:fill="F2F2F2"/>
            </w:tcPr>
            \(buildDescriptionCell(photoNumber: photoNumber, freeText: freeText))
          </w:tc>
        </w:tr>
        """
    }

    static func buildPageBreak() -> String {
        """
        <w:p><w:r><w:br w:type="page"/></w:r></w:p>
        """
    }

    static func rtlParagraph(
        text: String,
        bold: Bool = false,
        fontSize: Int = 20,
        alignment: String = "right",
        color: String? = nil,
        spacingAfter: Int? = nil
    ) -> String {
        let isHebrew = AppLanguage.current == .hebrew
        let boldTag = bold ? "<w:b/><w:bCs/>" : ""
        let colorTag = color != nil ? "<w:color w:val=\"\(color!)\"/>" : ""
        let spacingTag = spacingAfter != nil ? "<w:spacing w:after=\"\(spacingAfter!)\"/>" : ""
        let paragraphDirectionTag = isHebrew ? "<w:bidi/>" : ""
        let runDirectionTag = isHebrew ? "<w:rtl/>" : ""
        let resolvedAlignment = (!isHebrew && alignment == "right") ? "left" : alignment

        return """
        <w:p>
          <w:pPr>
            \(paragraphDirectionTag)
            <w:jc w:val="\(resolvedAlignment)"/>
            \(spacingTag)
          </w:pPr>
          <w:r>
            <w:rPr>
              \(runDirectionTag)
              <w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:cs="Arial"/>
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

    static func escapeXML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    private static func buildHeaderRow(
        imageColumnWidthTwips: Int,
        textColumnWidthTwips: Int
    ) -> String {
        """
        <w:tr>
          <w:trPr><w:tblHeader/></w:trPr>
          <w:tc>
            <w:tcPr>
              <w:tcW w:w="\(imageColumnWidthTwips)" w:type="dxa"/>
              <w:shd w:val="clear" w:color="auto" w:fill="95B3D7"/>
            </w:tcPr>
            \(rtlParagraph(text: AppStrings.text("תמונה"), bold: true, fontSize: 32, alignment: "center", spacingAfter: 0))
          </w:tc>
          <w:tc>
            <w:tcPr>
              <w:tcW w:w="\(textColumnWidthTwips)" w:type="dxa"/>
              <w:shd w:val="clear" w:color="auto" w:fill="95B3D7"/>
            </w:tcPr>
            \(rtlParagraph(text: AppStrings.text("תיאור"), bold: true, fontSize: 32, alignment: "center", spacingAfter: 0))
          </w:tc>
        </w:tr>
        """
    }

    private static func buildDescriptionCell(photoNumber: Int, freeText: String) -> String {
        let lines = freeText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let bulletLines = lines.map {
            $0.hasPrefix("•") ? $0 : "• \($0)"
        }

        var xml = rtlParagraph(
            text: "\(photoNumber).",
            bold: true,
            fontSize: 24,
            alignment: "right",
            spacingAfter: 80
        )
        for line in bulletLines {
            xml += rtlParagraph(
                text: line,
                bold: false,
                fontSize: 22,
                alignment: "right",
                color: "222222",
                spacingAfter: 60
            )
        }
        return xml
    }

    private static func buildInlineImage(
        relId: String,
        widthEMU: Int,
        heightEMU: Int,
        imageId: Int
    ) -> String {
        """
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

}

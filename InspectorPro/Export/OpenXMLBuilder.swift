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
              <w:top w:w="\(ExportImageConstants.imageCellPaddingTwips)" w:type="dxa"/>
              <w:left w:w="\(ExportImageConstants.imageCellPaddingTwips)" w:type="dxa"/>
              <w:bottom w:w="\(ExportImageConstants.imageCellPaddingTwips)" w:type="dxa"/>
              <w:right w:w="\(ExportImageConstants.imageCellPaddingTwips)" w:type="dxa"/>
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
        freeText: String,
        imageRelId: String,
        imageWidthEMU: Int,
        imageHeightEMU: Int,
        imageId: Int,
        imageCrop: ImageCrop = .none,
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
              <w:pPr><w:jc w:val="center"/><w:spacing w:before="0" w:after="0" w:line="240" w:lineRule="auto"/></w:pPr>
              <w:r>
                \(buildInlineImage(relId: imageRelId, widthEMU: imageWidthEMU, heightEMU: imageHeightEMU, imageId: imageId, crop: imageCrop))
              </w:r>
            </w:p>
          </w:tc>
          <w:tc>
            <w:tcPr>
              <w:tcW w:w="\(textColumnWidthTwips)" w:type="dxa"/>
              <w:vAlign w:val="top"/>
              <w:shd w:val="clear" w:color="auto" w:fill="F2F2F2"/>
            </w:tcPr>
            \(buildDescriptionCell(freeText: freeText))
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
        let boldTag = bold ? "<w:b/><w:bCs/>" : ""
        let colorTag = color != nil ? "<w:color w:val=\"\(color!)\"/>" : ""
        let spacingTag = spacingAfter != nil ? "<w:spacing w:after=\"\(spacingAfter!)\"/>" : ""

        return """
        <w:p>
          <w:pPr>
            \(spacingTag)
            <w:jc w:val="\(alignment)"/>
          </w:pPr>
          <w:r>
            <w:rPr>
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

    private static func buildDescriptionCell(freeText: String) -> String {
        let lines = freeText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let bulletLines = lines.map {
            $0.hasPrefix("•") ? $0 : "• \($0)"
        }

        var xml = ""
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

    /// Crop offsets in 1/1000th of a percent (0–100000) for center-crop behavior.
    struct ImageCrop {
        let left: Int
        let top: Int
        let right: Int
        let bottom: Int

        static let none = ImageCrop(left: 0, top: 0, right: 0, bottom: 0)
    }

    private static func buildInlineImage(
        relId: String,
        widthEMU: Int,
        heightEMU: Int,
        imageId: Int,
        crop: ImageCrop = .none
    ) -> String {
        let srcRectTag: String
        if crop.left != 0 || crop.top != 0 || crop.right != 0 || crop.bottom != 0 {
            srcRectTag = "<a:srcRect l=\"\(crop.left)\" t=\"\(crop.top)\" r=\"\(crop.right)\" b=\"\(crop.bottom)\"/>"
        } else {
            srcRectTag = ""
        }

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
                    \(srcRectTag)
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

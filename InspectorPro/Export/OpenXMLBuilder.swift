import Foundation

/// Generates OpenXML fragments for DOCX document content.
final class OpenXMLBuilder {
    static func buildPhotoBlock(
        photoNumber: Int,
        freeText: String,
        imageRelId: String,
        imageWidthEMU: Int,
        imageHeightEMU: Int,
        imageId: Int
    ) -> String {
        return """
        \(rtlParagraph(text: "תמונה \(photoNumber)", bold: true, fontSize: 24))
        <w:p>
          <w:pPr><w:jc w:val="center"/></w:pPr>
          <w:r>
            \(buildInlineImage(relId: imageRelId, widthEMU: imageWidthEMU, heightEMU: imageHeightEMU, imageId: imageId))
          </w:r>
        </w:p>
        \(rtlParagraph(text: normalizedText(freeText), fontSize: 20, color: "444444"))
        \(buildSpacing(points: 220))
        """
    }

    static func buildPageBreak() -> String {
        """
        <w:p><w:r><w:br w:type="page"/></w:r></w:p>
        """
    }

    static func buildSpacing(points: Int = 200) -> String {
        """
        <w:p>
          <w:pPr>
            <w:spacing w:after="\(points)"/>
          </w:pPr>
        </w:p>
        """
    }

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

    static func escapeXML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

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

    private static func normalizedText(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "ללא הערה" : trimmed
    }
}

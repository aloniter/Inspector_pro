# Lessons Learned

## DOCX XML edits must preserve namespace prefixes and compatibility metadata
- Do not rewrite OpenXML parts with `xml.etree.ElementTree` when the part includes `mc:Ignorable` and many namespace-prefixed attributes.
- Reason: serializer can rename/drop prefixes, leaving `mc:Ignorable` tokens unresolved and causing Word "unreadable content" recovery dialogs.
- Preferred approach: edit specific nodes with a namespace-preserving DOM approach, or do targeted string replacements on the original XML while keeping root namespace declarations intact.

## OpenXML child-element order must match schema sequence
- Word can flag "unreadable content" even when XML is well-formed if child elements are out of schema order (for example in `w:rPr`, `w:pPr`, `w:tblPr`, `w:tcPr`, `w:settings`).
- Verification rule: for DOCX generation changes, run an OpenXML SDK validation pass (`DocumentFormat.OpenXml`) and require zero validation errors, not only XML parse success.

## RTL-heavy features need behavior verification, not only a successful build
- For Hebrew-first flows, a passing build is not enough to claim the app is usable; verify input direction and exported punctuation/bullets in the real UI/export path.
- Verification rule: after changing note editors or export text formatting, run simulator launch verification and add at least one focused automated test for the RTL formatter/output.

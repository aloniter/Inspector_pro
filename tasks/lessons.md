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

## Cover-page `label: value` export fields need explicit bidi isolation
- Do not concatenate Hebrew labels and dynamic values directly in DOCX/PDF cover-page strings such as `כתובת: value` or `הערות: value`.
- Reason: Word/Core Text can attach the neutral colon to the wrong side when the following value is empty, numeric, or opposite-direction text.
- Preferred approach: isolate the `label:` segment and the value segment separately in a shared export formatter, then reuse that formatter across PDF and DOCX cover-page generation.

## App-form styling and export styling can diverge for the same field
- Do not assume a field label should share the same visual treatment inside the app and in exported PDF/DOCX output.
- Verification rule: when a user requests styling changes for metadata fields, confirm the behavior separately for in-app forms and for exported documents, and suppress optional export sections entirely when their value is empty.

## Hebrew punctuation placement in export headings needs explicit review
- For standalone Hebrew headings in export output, users may want the colon on the opposite visual side from inline `label:` fields.
- Verification rule: after changing standalone Hebrew headings like `נוכחים`, verify both the color tone and the visual side of the colon in DOCX/PDF output instead of assuming the default RTL punctuation behavior is acceptable.

## Export typography requests are usually point-size specific
- When a user specifies sizes like 10 or 14 for exported report metadata, map them explicitly in both PDF points and DOCX half-points instead of reusing nearby defaults.
- Verification rule: for DOCX cover-page typography changes, add or update string-based tests that assert the generated font-size tokens and alignment markers.

## SwiftUI section headers may ignore intended RTL placement unless layout is forced
- In `Form`/`Section` headers, a simple `.frame(..., alignment: .trailing)` is not always enough to keep Hebrew labels on the visual right.
- Preferred approach: wrap the header in an explicit container and force the container layout direction when the system header styling fights the intended RTL position.

## Follow-up export tweaks often need identical intent across PDF and DOCX
- When a user refines report presentation after an initial pass, do not assume the first acceptable implementation is semantically complete.
- Verification rule: if a feature exists in both PDF and DOCX, mirror the exact user-facing behavior in both builders for list numbering, heading emphasis, and cover-page date formatting, and add tests for the shared formatter rules that drive both outputs.

## Cover-page stacked fields need alignment parity between heading and value
- For dedicated stacked cover sections like `נוכחים`, do not mix a centered heading with right-aligned value lines unless the user explicitly wants that asymmetry.
- Verification rule: when a user requests that names/details sit "under" a heading, align the value block to the same visual anchor in both PDF and DOCX and update string-based export tests to lock that layout in.

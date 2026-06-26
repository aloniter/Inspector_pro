# Lessons Learned

## Authenticated UI QA should use the provided test account
- When simulator visual verification is blocked by the login screen, use the user-provided app test account from the current chat/session instead of stopping at unauthenticated launch.
- Do not write credentials, passwords, emails, or tokens into tracked repo files, task notes, screenshots, or logs.
- Verification rule: for changes behind authentication, log in on the simulator and inspect the actual screen whenever credentials are available in the session.

## Latest visual correction overrides earlier alignment briefs
- When the user provides a newer screenshot and says a field is on the wrong side, treat that as the current source of truth even if an earlier pasted brief said the opposite.
- For the New Project/Edit Project Hebrew fields in this app, placeholders and entered values should be visually right-aligned unless the user explicitly reverses that again.
- Verification rule: after changing form alignment, inspect the actual simulator screen or a user-provided screenshot against the specific side requested, not only the original written checklist.

## Report table image layout can prioritize full-cell presentation over aspect ratio
- When the user asks for manual Word-resize behavior, do not preserve aspect ratio if that leaves visible empty space around annotated report photos.
- Reason: annotations are baked into the final exported image, so controlled non-uniform scaling keeps annotations attached while making the report table look professionally filled.
- Preferred approach: for report-table images, use a named full-cell no-crop placement mode that sets the image extent to the cell drawable width and height, emits no DOCX crop metadata, and draws the PDF image directly into the drawable rect.
- Verification rule: assert DOCX `<wp:extent>` uses the table image content width and target image height for landscape, portrait, and square fixtures, assert no `<a:srcRect>`, and keep PDF drawing on the same full-cell placement helper.

## Centered cover-page sections must stay centered in actual export alignment
- When a user asks for typography-only changes on a stacked cover-page section, do not reinterpret alignment even if the text is RTL.
- Reason: changing `w:jc` or PDF paragraph alignment from `center` to `right` can move the whole Hebrew block to the visual side in Word/PDF, even when the text direction itself remains correct.
- Verification rule: for `נוכחים` cover-page changes, assert the generated DOCX paragraph uses `w:jc w:val="center"` for both the heading and numbered attendee lines, and visually compare against the user-provided Word screenshot when available.

## SwiftData versioned schemas are immutable once used
- Do not add or remove fields inside an existing versioned schema after it has been used to create a store, even during the same feature branch.
- Reason: SwiftData/CoreData identifies model versions by checksum, so changing `InspectorProSchemaV8` after it exists can make staged migration report an unknown model version.
- Preferred approach: restore the prior schema shape exactly, add the model change in the next schema version, and connect it with a lightweight or custom migration stage.

## DOCX RTL list fixes need Word visual confirmation
- OpenXML-valid list semantics can still render badly in Microsoft Word for Hebrew RTL inside table cells.
- Preferred approach: compare generated DOCX against a user-approved Word-authored sample or screenshot before preserving list/indentation changes.
- Verification rule: for Hebrew DOCX list layout changes, inspect the actual `document.xml` and `numbering.xml`, then perform a Word visual/editing check that includes pressing Enter and typing another list item instead of relying only on XML parse or OpenXML SDK validation.
- Do not assume `w:right` indentation means visual-right for Word RTL lists; in the report table cell it moved bullets to the visual left, while the rendered test variant with `w:left` kept the bullet on the Hebrew right side.
- Physical `w:left`/`w:right` indents are still the wrong abstraction for Word RTL lists. Prefer logical `w:start` indentation and `w:jc w:val="start"` with paragraph `w:bidi`, because start resolves to the right edge for RTL paragraphs.
- For RTL list paragraphs inside narrow report table cells, `w:start` must be greater than `w:hanging`; `start=360` with `hanging=360` puts the bullet on the cell edge and can clip it. Use extra start room such as `start=540`, `hanging=360`.

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

## Hebrew form text fields should use the UIKit-backed directional wrapper
- Do not rely on SwiftUI `TextField` plus `.multilineTextAlignment(.trailing)` for Hebrew-first editable fields that must visually start on the right.
- Reason: SwiftUI can still render the placeholder or value from the visual left in `Form` rows, especially after focus or when wrapped by system row styling.
- Preferred approach: use `DirectionalTextField` with `alignment: .right` for Hebrew/right-aligned fields such as report attendees and company name, while keeping emails, phone numbers, version values, and technical identifiers explicitly LTR.
- Verification rule: inspect both the placeholder and an entered value on simulator/device for every RTL field fix.

## Settings toggles need explicit visual order in RTL forms
- Do not use native `Toggle(title, isOn:)` in Hebrew Settings/Form rows when the required visual order is label on the right and switch on the left.
- Preferred approach: build an explicit HStack row with the switch first, spacer, text last, and force the row environment to left-to-right so the visual positions remain stable.
- Verification rule: inspect the actual simulator row, because the AX/browser overlay can select the row while hiding whether SwiftUI reversed the control placement correctly.

## Icon action rows in Hebrew settings need explicit RTL ordering
- Do not rely on SwiftUI `Label(title, systemImage:)` for Hebrew action rows when the visual order matters.
- Preferred approach: build a dedicated row with explicit `Text` and `Image` placement, then force the row environment to left-to-right so the intended visual order does not get reinterpreted by surrounding `Form` layout.
- Verification rule: inspect the actual row in the simulator, including icon side and text side, before calling RTL action-row work complete.

## Follow-up export tweaks often need identical intent across PDF and DOCX
- When a user refines report presentation after an initial pass, do not assume the first acceptable implementation is semantically complete.
- Verification rule: if a feature exists in both PDF and DOCX, mirror the exact user-facing behavior in both builders for list numbering, heading emphasis, and cover-page date formatting, and add tests for the shared formatter rules that drive both outputs.

## Cover-page stacked fields need alignment parity between heading and value
- For dedicated stacked cover sections like `נוכחים`, do not mix a centered heading with right-aligned value lines unless the user explicitly wants that asymmetry.
- Verification rule: when a user requests that names/details sit "under" a heading, align the value block to the same visual anchor in both PDF and DOCX and update string-based export tests to lock that layout in.

## Mixed RTL/LTR footer content must not stay as one editable free-text line
- A single raw string for Hebrew names plus phones/email makes SwiftUI editing and export rendering unstable because neutral characters and LTR tokens reorder differently across UITextInput, Core Text, and Word.
- Preferred approach: edit contact lines as structured fields, normalize stored output with explicit LTR marks around email/phone/numeric tokens, and keep the export layout fixed while only changing text composition.

## Footer editing for Hebrew exports should use compact grouped inputs, not over-fragmented rows or visible separators
- Even when the data is structured, a footer editor becomes harder to scan if every token is presented as its own stacked row, and pipe-delimited export output looks mechanical in Hebrew.
- Preferred approach: keep structured fields internally, group them into compact 2-field rows per contact block, and generate the final footer line in a natural Hebrew order without exposing mixed-direction composition to the user.

## Mixed RTL/LTR export lines should be rendered as positioned runs, not left to bidi resolution of one combined string
- For footer lines that mix Hebrew words with phone numbers and email addresses, even structured data is not enough if PDF or DOCX still receives one mixed-direction string or a paragraph whose final visual order is delegated to the text engine.
- Preferred approach: keep semantic structured fields, derive explicit run sequences, and render the export line in fixed visual order per token/run so Core Text and Word do not get to reinterpret the intended sequence.

## Export image fit fixes must include row sizing, not only draw scaling
- No-crop aspect-fit can still produce unprofessional reports if every finding row reserves a fixed half-page block.
- Preferred approach: make PDF rows content-sized from fitted image height and measured text height, and make DOCX rows auto-sized by omitting exact `w:trHeight`.
- Verification rule: for report-table image changes, assert there is no DOCX `<a:srcRect>` and no exact row-height rule, then visually review short-description landscape/portrait rows for excessive blank description space.

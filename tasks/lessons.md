# Lessons Learned

## OOXML w:jc "left"/"right" are VISUALLY SWAPPED inside `<w:bidi/>` paragraphs — in both real Word and LibreOffice
- On-device DOCX verification (2026-07-04) showed attendee names stranded at the visual LEFT of their cell (far from the marker) even though the paragraph had `w:jc w:val="right"`. Building a variant DOCX with rows split across `jc="start"` / `jc="left"` / `jc="right"` and rendering it through real Word-for-Mac (AppleScript `save as ... format PDF`) and LibreOffice proved both renderers agree: in a `<w:bidi/>` paragraph, `"right"` renders at the visual left and `"left"` at the visual right ("start" == "left" in both). An earlier session's "right-align the name paragraph so names hug the marker" change therefore did the visual opposite in every real renderer.
- Fix: attendee marker and name paragraphs use `w:jc="left"` to land at the visual right. `"start"` renders identically but is ISO-strict-only vocabulary; `"left"` is valid in every OOXML edition and can't trigger a repair prompt in old Word.
- Verification rule: never trust a `w:jc` value by name in RTL paragraphs — render through real Word (scriptable via AppleScript: `open` + `save as active document ... file format format PDF`, then `pdftoppm` + pixel clusters) and measure which side the text landed on.

## Never size a fixed DOCX table cell exactly to measured text — real Word clips it
- The DOCX attendee name column was sized to the CoreText-measured widest name + 4pt. In real Word the widest name rendered touching both cell edges and clipped on the user's device (Word's Hebrew Arial shaping runs slightly wider than CoreText's measurement of the same string), and typing ANY longer name into the exported fixed-layout cell clipped immediately — killing the "editable DOCX" promise.
- Fix: headroom must scale with the measurement (drift is proportional) and have an absolute floor for editing room: `slack = max(12% of measured, 300 twips)`, clamped to the page content width. The marker column stays measurement-exact so numbers keep fixed alignment; because names hug the marker at the visual right, the slack is invisible dead space on the block's outer-left side.
- Verification rule: after any attendee/cover-table change, render the generated DOCX through BOTH LibreOffice and real Word (LibreOffice did NOT reproduce this clip — only real Word shows Word's text metrics; the AppleScript loop makes real-Word rendering scriptable).

## Stop using Word auto-numbering and bidi tricks for the attendees marker
- Real Word rendering (via LibreOffice headless conversion + pdftoppm, and the user's own Word/Preview checks) showed the `w:suff="tab"` + `w:numPr` auto-numbering fix from the previous session was still fragile: the first list item rendered with different indentation than the rest, and PDF markers drawn with an RTL base writing direction rendered inconsistently row-to-row (some as `.1`, others dropping the dot entirely — a bidi-ambiguity artifact of applying RTL direction to a digit-only string with no strong-direction anchor character).
- Fix: stop using `w:numPr`/auto-numbering entirely for attendees. Build a fixed borderless 3-column DOCX table per row (name cell, thin spacer cell, marker cell) with the marker as literal `"N."` text and no `<w:bidi/>`/`<w:rtl/>` on the marker paragraph — plain Western digits need no bidi help and rendering them with any bidi flag is what caused the inconsistency. For PDF, always draw the marker with LTR base direction regardless of app language, for the same reason.
- Verification rule: for `נוכחים` marker issues, render the actual generated DOCX through LibreOffice headless (`soffice --convert-to pdf`) and `pdftoppm`, not just XML string assertions — the numbering/indentation bugs were only visible in rendered output, not in the XML structure itself (the XML looked "correct" with `w:numPr` present).

## LibreOffice's table `w:jc="center"` support is unreliable — don't chase it further than the standard property
- A fixed multi-column DOCX table's `w:jc="center"` rendered visibly left-of-center in LibreOffice's headless PDF conversion (measured ~30-75px off true center depending on table width), and neither adding an explicit `w:tblInd` (computed from page/margin twips) nor nesting the table inside a single-cell `w:jc="center"` outer wrapper changed the rendered position at all — LibreOffice appears to ignore `w:tblInd` for this table shape entirely, and the outer-wrapper pattern that looked "centered" for a narrower single-column list turned out to have the same absolute-pixel offset, just less visually obvious at that width.
- `w:jc="center"` on the table's own `w:tblPr` is still the correct, standard, Word-supported way to center a table — it is not a "bidi trick" and should not be abandoned just because LibreOffice's headless renderer doesn't compute it perfectly. Don't add `w:tblInd`/nesting complexity to work around a LibreOffice-specific quirk without being able to verify it actually helps in real Word.
- Verification rule: if attendees/cover-table centering is revisited, the authoritative check is real Microsoft Word (or Preview via a real user), not LibreOffice — LibreOffice is a useful stand-in for numbering/marker/indentation bugs (which reproduced faithfully there) but has known limitations for table auto-centering specifically. Flag this caveat explicitly when only LibreOffice was available for verification.

## RTL numbered lists need suff="tab", not suff="space"
- `w:suff="space"` makes each item's text start right after the marker, so name alignment breaks the moment "10." appears, and Word renders it less predictably than its own default list machinery. `w:suff="tab"` lands the text at the hanging-indent position (`w:ind w:start`) for every item — names align in one clean column regardless of marker width.
- Do not put `w:numPr` in BOTH the paragraph style and each paragraph; keep it on the paragraphs only. Style+paragraph double numbering is an exotic combination real Word can render inconsistently (reported as the first list item having different indentation).
- The attendee container width must fit the longest realistic name after the `w:ind w:start` gutter, or names wrap; 3600 twips fits typical multi-word Hebrew names.
- Superseded below ("Attendee marker digit/period must be positioned as separate pieces"): an RTL base writing direction on a "1." string is bidi-ambiguous and rendered inconsistently row-to-row in real testing.
- Verification rule: render generated DOCX through LibreOffice headless (`soffice --convert-to pdf`) plus `pdftoppm`, with 12+ attendees including one-char and very long names, and check: numbers share a right edge, names share a column, dot sits between digit and name.

## Attendee marker digit/period must be positioned as separate pieces, not one "N." string
- Drawing "1." as one string — with any single base writing direction (LTR or RTL) — right-aligned in its cell/rect puts the string's LAST LTR character (the period) at the outer/margin edge and the digit inward toward the name. That is backwards: the real user, testing the actual PDF and Word output, reported "the . is the other way." The professional Hebrew convention is digit flush at the outer margin, period between the digit and the name.
- Fix (PDF): draw the digit and the period as two separately-positioned draws — digit right-aligned in a rect flush against the marker column's outer edge, period right-aligned in a rect immediately to the digit's left. Both pieces use LTR base direction (they're plain Western characters; no bidi needed for either individually).
- Fix (DOCX): use four fixed table columns per attendee row — digit, period, spacer, name — with an explicit `<w:bidiVisual/>` on the table so column 1 (digit) renders as the visual-rightmost column deterministically. Do not rely on the *absence* of `w:bidiVisual` and hope the renderer's implicit RTL-section default puts columns in the right order — that worked for the earlier 3-column table but silently reversed (name became rightmost, digits leftmost) once a 4th column was added, in the same renderer, with no other change. Declare the order explicitly.
- Fix (gap): the name paragraph must be right-aligned (`w:jc="right"`) inside its column, not left-aligned — a wide fixed-width name column with left-aligned text leaves a large dead gap between a short name and the marker, which is exactly the "not such a big gap" / cheap-looking layout the user flagged in their Word screenshot.
- Verification rule: pixel-measure the rendered marker, don't eyeball it — crop the row region from a rendered PNG (`pdftoppm` for PDF; LibreOffice `--convert-to pdf` then `pdftoppm` for DOCX), find dark-pixel column clusters with PIL/numpy, and confirm the digit cluster's rightmost edge is closer to the true page margin than the period cluster's.

## xcodebuild test can install a stale app binary onto the simulator despite reporting BUILD SUCCEEDED
- After editing source and getting a fresh "BUILD SUCCEEDED" + "TEST SUCCEEDED", the actual exported PDF/DOCX kept reflecting pre-edit behavior. `nm`/`grep -a` on the simulator-installed `InspectorPro.debug.dylib` confirmed the new function's symbol was completely absent, even though the default DerivedData build product (built standalone, same command) DID contain it — the xcodebuild `test` action's *install step* onto the simulator silently skipped updating the app bundle.
- Fix/workaround: build and test with an explicit, freshly-created `-derivedDataPath` (e.g., a scratch directory) rather than the default DerivedData location. This forced a real reinstall and the new symbol appeared in the simulator's installed binary immediately.
- Verification rule: when a code change doesn't seem to affect exported output despite a passing test run, don't trust "BUILD SUCCEEDED" alone — confirm the new symbol exists in the simulator-installed binary (`xcrun simctl get_app_container <device> <bundle-id> bundle`, then `nm`/`grep -a` the dylib for a distinctive function name) before concluding the code itself is wrong.

## Never run two xcodebuild test invocations concurrently on one project
- Parallel xcodebuild runs racing on the same DerivedData can leave an UNSIGNED app product; every later incremental build reuses it and the simulator fails with "Launchd job spawn failed" / RequestDenied even after sim reboots and CoreSimulator resets.
- Recovery: delete the project's own DerivedData directory (verify via `PlistBuddy -c "Print :WorkspacePath" <dir>/info.plist` — several checkouts named InspectorPro exist on this machine), resolve packages, rebuild.
- `TEST_RUNNER_X=1` must be set as a shell environment variable before xcodebuild, not passed as a command-line argument (arguments become build-setting overrides).

## UIGraphicsImageRenderer defaults to screen scale — pixel caps silently triple
- `UIGraphicsImageRenderer(size:)` with the default format renders at the main screen scale (3× on modern iPhones). Any "resize to N px" helper built on it actually produces 3N-pixel bitmaps, so imports were storing up to 6000px JPEGs (upscaled from 4032px camera photos) and annotated composites ballooned storage by 10MB+ per photo.
- When a renderer output feeds `jpegData`/disk storage or a pixel budget, always set `format.scale = 1` explicitly (`AnnotationImageRenderer` already did this via `baseImage.scale`).
- Derived images (annotated composites) must never be stored heavier than their source: cap them to `importMaxWidth` and use a JPEG quality ≤ the original's, since they are regenerated on every save.
- Verification rule: assert `resized(maxWidth:)` output `cgImage.width` equals the requested pixel width exactly, and that a saved annotated composite of an oversized source decodes at `importMaxWidth`.

## Attendees app input and report export intentionally differ
- In the app report editor, keep `נוכחים` as plain newline-separated Hebrew names, visually right-aligned, with no visible generated numbers. The user explicitly preferred removing in-app numbers because the editor numbering kept creating visual and editing problems.
- In exported PDF/DOCX, keep numbering, but the numbered block must sit under the centered `נוכחים:` heading rather than at the page edge.
- DOCX attendees must use real Word numbering (`w:numPr`) so pressing Enter while editing continues the numbering automatically. Do not type manual `1.`/`2.` text into the attendee runs, and do not use tabs, giant spacing, positioned tables, or marker/name split columns.
- A one-cell borderless DOCX table is acceptable only as a local container to center the editable numbered list under the heading; the attendee paragraphs inside it still need real Word list semantics.
- Word can clip RTL decimal list markers when `w:start - w:hanging` is too small; this renders as dots without digits even though `w:numPr` is present. Reserve enough marker gutter for visible values like `1.`, `10.`, etc.
- After the marker gutter is wide enough, the numbered block may still sit a little too far visual-right under the centered `נוכחים:` heading. Use a small internal right margin/visual-left offset to place the list professionally under the heading without changing the numbering semantics.
- Verification rule: assert DOCX attendee XML has the attendee names as editable text, has `w:numId` for the cover attendee list, reserves a wide enough list marker indent, has the small right cell margin that nudges content left, has no manual numbered attendee strings, no `w:tab`, no `w:tblpPr`, and no old two-column attendee grid.

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
- Verification rule: for simple paragraph-based cover sections, assert centered paragraph alignment and visually compare against the user-provided Word/PDF screenshot when available. For `נוכחים`, keep the list block visually centered under its heading while preserving compact RTL list semantics.

## Fixed-column attendees were rejected for this flow
- Do not reintroduce the old fixed marker/name column layout for report attendees in the app or on the cover page. The user rejected it because it still looked visually detached from the `נוכחים:` heading and made app editing feel strange.
- The current intended behavior is: app editor shows names only; PDF uses a compact centered numbered block; DOCX uses editable auto-numbered paragraphs in a centered one-cell container.
- Verification rule: if a later fix touches attendees again, compare against the latest correction first, not the earlier fixed-column attempts.

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

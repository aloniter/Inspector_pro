# TODO

> **Current status:**
>
> - User-facing app name: Inspectley
> - Internal project/target name: InspectorPro
> - Current App Store version: 1.0.2 (build 3)
> - App Store Connect confirmed: iOS App Version 1.0.2 is Ready for Distribution.
> - App Store category: Business
> - Older entries below are historical work-log notes and may mention old versions/builds/categories.

---

## PDF export memory fix (2026-07-04, branch fix/pdf-export-memory)

- [x] Root cause: `PdfExporter` retained every photo's `FlattenedExportImage` (compressed Data + UIImage) for the whole render; once drawn, each decoded bitmap (~1–2MB) stayed resident — O(N) peak, ~200–400MB for 150–200 photo reports
- [x] Fix: prep loop stores only compressed JPEG `Data`; each row decodes just-in-time inside `autoreleasepool` and releases the bitmap after drawing — decoded-image residency now O(1)
- [x] Removed dead `image:` parameter from `photoRowHeight` (was never used; row height comes from options + text)
- [x] New test `pdfExporterPaginatesTwoPhotosPerPageWithRealPhotos` (5 real photos, asserts cover + ceil(5/2) pages via CGPDFDocument) with `KEEP_PDF_PAGINATION_SAMPLE` hook
- [x] 88/88 tests pass with fresh DerivedData, before AND after the change
- [x] Visual proof: before/after sample PDFs from identical inputs rasterized at 150dpi — 4 pages each, **0 differing pixel values** on every page; file sizes byte-count identical (85,132B)
- [x] Scope: git diff touches only PdfExporter.swift + ExportTests.swift — DOCX/RTL/storage/compression untouched

## Review

- Same bytes, same draw rects, same progress and error behavior — only the lifetime of decoded bitmaps changed. Prep-time validation still throws `imageLoadFailed` exactly as before; the render-loop decode is from already-validated data.

---

## Fix DOCX attendee name clipping in real Word (on-device verification feedback, 2026-07-04)

- [x] Reproduce: pulled the user's failing on-device export (name column 640 twips; widest name "אבישי" touching both cell edges) and rendered it through real Word via AppleScript PDF export
- [x] Root cause 1: name column sized to CoreText measurement + only 4pt — zero headroom for Word's wider Hebrew Arial shaping or for post-export editing
- [x] Root cause 2: `w:jc="right"` inside `<w:bidi/>` paragraphs renders at the visual LEFT in both real Word and LibreOffice (empirically proven with a 3-way jc variant DOCX) — names sat far from markers in mixed-length lists
- [x] Fix (DOCX only): `w:jc="left"` on marker + name paragraphs (visual right); name column slack = max(12%, 300 twips) clamped to content width; marker column unchanged
- [x] New regression test `docxAttendeeNameColumnKeepsWordHeadroomForVariedNames` (12 attendees: one-char, typical, long multi-word); updated jc assertions
- [x] 87/87 tests pass with fresh DerivedData; pixel-verified real-Word render: 12/12 marker right edges within 3px, uniform gaps, no clipping
- [x] PDF and photo pages untouched (git diff: DocxExporter, DocxTemplateBuilder, ExportTests only)

## Review

- The two defects compounded: exact-fit cells clipped the widest name in Word, and the swapped-jc alignment meant any added headroom would have pushed names away from markers. Fixing both together keeps the accepted visual design (names hugging markers, digits flush at the outer edge) while making clipping impossible at export time and leaving ~15pt of typing room.
- Real Word is now scriptable in the verification loop (AppleScript open → save-as-PDF → pdftoppm → pixel clusters) — LibreOffice alone would NOT have caught this bug.

---

## Fix attendee marker dot orientation and name/marker gap (real Word + PDF feedback)

- [x] PDF: split marker into separately-positioned digit (outer/margin edge) and period (toward name) draws — a single right-aligned "N." string put the period at the margin, backwards
- [x] DOCX: rebuild attendee row as 4 fixed columns (digit, period, spacer, name) with explicit `<w:bidiVisual/>` so column order is deterministic — omitting it caused a silent full column reversal once a 4th column was added
- [x] DOCX: right-align the name paragraph (was left-aligned) so short names hug the marker instead of leaving a large dead gap
- [x] Diagnosed and fixed an unrelated infra issue: `xcodebuild test` silently installed a stale binary onto the simulator despite reporting success; fixed by using an explicit `-derivedDataPath`
- [x] Verify via pixel measurement (not eyeballing) on rendered PDF and LibreOffice-converted DOCX
- [x] Run full test suite, commit

## Review

- Root cause (both PDF and DOCX): a marker rendered as one "N." string, right-aligned, puts its LAST character (the period, since digits+period are inherently LTR) at the outer edge and the digit inward — backwards for a Hebrew reader. Confirmed by the user's own real PDF and Word screenshot.
- PDF: digit and period are now drawn as two separate rects, digit flush at the marker column's outer edge, period immediately to its left.
- DOCX: attendee rows now use 4 fixed columns (digit/period/spacer/name) with `<w:bidiVisual/>` explicitly declaring RTL column order — verified necessary after discovering the 3-column table's implicit column order silently reversed once a 4th column was added in the same renderer.
- Gap fix: name paragraph alignment changed from left to right, so short names sit adjacent to the marker instead of floating at the far side of a wide fixed column.
- Verified via pixel-level cluster analysis (PIL/numpy) on rendered PNGs, not visual inspection alone, after an initial round of debugging showed a false negative caused by a stale simulator-installed binary (xcodebuild reported success but skipped reinstalling the updated app — traced via `nm` on the installed dylib, fixed with an explicit `-derivedDataPath`).
- Tests: 84 passed, 0 failed on iPhone 16e / iOS 18.6, clean derived-data build.
- LibreOffice's DOCX render still shows a visible gap between name and marker that I could not conclusively attribute to the XML vs. a LibreOffice-specific rendering quirk (LibreOffice has shown multiple quirks this session unrelated to the actual XML — stale left-anchoring, full column reversal). The underlying alignment/column XML is verified correct by direct inspection; real Word confirmation is needed for final sign-off.

## Fix attendee marker consistency: replace Word auto-numbering and bidi tricks

- [x] DOCX: replace `w:numPr` auto-numbering with a fixed 3-column table (name/spacer/marker), marker as literal text, no bidi/rtl tag on the marker
- [x] PDF: draw the marker with plain LTR base direction always (the RTL toggle from the previous fix caused inconsistent rendering — some rows `.1`, others missing the dot)
- [x] Remove now-dead `InspectorCoverAttendeeNumber` style and numId=2/abstractNumId=2 from styles.xml/numbering.xml
- [x] Update tests for the new structure; verify via LibreOffice headless render + pdftoppm with 11-12 attendees including the user's exact requested list
- [x] Investigate DOCX table centering (LibreOffice showed left-of-center offset); tried explicit `w:tblInd` and single-cell nesting — neither changed LibreOffice's rendered position; reverted to plain `w:jc="center"` (standard, Word-supported) and documented the LibreOffice-specific caveat
- [x] Run full test suite, commit

## Review

- Root cause of the reported bug: the previous session's DOCX fix (`w:suff="tab"` + `w:numPr`) still let Word auto-number/indent the first item differently, and the PDF fix that drew the marker with RTL base direction was bidi-ambiguous for a digit-only string, rendering inconsistently row to row (`.1` vs missing dot) — exactly the "fragile bidi trick" the user flagged.
- DOCX now uses a fixed borderless 3-column table per attendees block (name cell, thin spacer, marker cell with literal `"N."` text), no `w:numPr`, no bidi/rtl tag on the marker paragraph. PDF now always draws the marker with LTR base direction. Verified via LibreOffice headless conversion + pdftoppm with the user's exact 6-name list extended past 10, and with the 12-name mixed-length fixture: numbers align in one right column, names align in one left column, markers read `1.`/`2.`/`10.` consistently on every row, first row indentation matches all others.
- Caveat found and documented: LibreOffice's headless PDF conversion renders the DOCX attendee table slightly left-of-center regardless of `w:jc="center"`, explicit `w:tblInd`, or single-cell-wrapper nesting (none changed the rendered position). `w:jc="center"` is the correct, standard, Word-supported property, so it was kept; real Microsoft Word must be checked directly, which this environment cannot do.
- Tests: 84 passed, 0 failed on iPhone 16e / iOS 18.6 after a clean build.

## Attendee list Word consistency + photo editor polish

- [x] DOCX: switch attendee numbering `w:suff` from space to tab so names align in one column at any marker width (10+, long names)
- [x] DOCX: remove duplicated `w:numPr` from the paragraph style (kept on paragraphs) to eliminate the first-item indentation anomaly in real Word
- [x] DOCX: widen the centered attendee container 2800 → 3600 twips so long Hebrew names stay on one line
- [x] PDF: draw attendee markers with RTL base direction so "1." renders digit-rightmost with the dot toward the name; marker/name gap 6 → 9pt
- [x] Photo detail screen: single clean image card (removed the nested gradient ring), unified paddings/radii, quieter notes field — styling only, no behavior/export/annotation changes
- [x] Verification

## Review

- Verified with the app-generated samples (12 attendees incl. one-char and very long names): PDF rendered via pdftoppm and DOCX rendered via LibreOffice both show one clean number column (digits share the right edge, dot between digit and name), one clean name column, the block centered under `נוכחים:`, and long names on one line. PDF and DOCX are visually consistent.
- Export photo behavior untouched: photo-table tests (full-cell extents, no `a:srcRect`, annotated composite fidelity) all still pass unchanged.
- Tests: 84 passed, 0 failed on iPhone 16e / iOS 18.6 after a clean rebuild (a corrupted-unsigned DerivedData product from concurrent xcodebuild runs caused transient launch failures; wiped and rebuilt).

## Release hardening: export RTL, photo storage, regression protection

Plan (branch `fable/release-hardening-export-rtl-storage`):

- [x] Commit the already-verified attendees fixed-alignment export work as the baseline commit (it implements the attendees/numbering priority; 81 tests passed in its verification run)
- [x] Fix `UIImage.resized(maxWidth:)` rendering at screen scale (3× on device): imports save up to 6000px JPEGs instead of ≤2000px, which is the root cause of oversized originals and 10MB+ annotated copies
- [x] Cap annotated composite saves at `importMaxWidth` and save them at the same JPEG quality as originals (0.85 instead of 0.92)
- [x] Add regression tests: `resized` produces exact pixel widths, annotation renderer preserves pixel size, annotated saves never exceed the import width cap
- [x] Audit findings (no code change needed): export photo full-cell stretch is intentional per lessons; exports purged at launch; account deletion via support mailto exists; DOCX temp dirs cleaned via defer
- [x] Run full test suite + build; document results

## Review

- Root cause of storage growth: `UIGraphicsImageRenderer(size:)` defaults to screen scale, so `resized(maxWidth: 2000)` produced 6000px bitmaps on 3× devices. Imports were *upscaling* 4032px camera photos to 6000px JPEGs, and annotating one photo re-encoded those inflated pixels at quality 0.92, producing 10MB+ derived files. Fixed by rendering `resized` at `format.scale = 1`.
- Annotated composites now cap at `importMaxWidth` (2000px) and save at `annotatedImageJPEGQuality` (0.85, same as originals), so annotating a legacy oversized original also shrinks rather than balloons. Original files are never touched; composites are regenerated on each save, so no data loss is possible.
- Export behavior unchanged by design: the byte-budget loop in `ImageCompressor` already clamped export payloads, and no test pins absolute pixel dimensions. Full-cell no-crop stretch in report tables kept as-is (explicit user preference per lessons).
- New regression tests: exact pixel width from `resized` (catches screen-scale inflation), annotation renderer preserving base pixel size, and an `ImageStorageService` round-trip asserting annotated saves decode at ≤2000px.
- Verification: `xcodebuild test` on iPhone 16 / iOS 18.6 — 84 tests, 0 failures (81 baseline + 3 new).

## Fine tune attendees under heading

- [x] Keep app attendees editor unchanged
- [x] Nudge DOCX attendee list content slightly left under `נוכחים:`
- [x] Apply matching PDF attendee block nudge
- [x] Update focused tests and lessons
- [x] Run verification

## Review

- App editor: unchanged.
- DOCX: kept the centered attendee container and real Word numbering, but added a small right cell margin (`320` twips) so the list content moves slightly visual-left and sits better under `נוכחים:`.
- PDF: added the same visual intent with a `14pt` left nudge for the measured attendee block.
- Tests: XcodeBuildMCP `test_sim` passed on iPhone 16 / iOS 18.6 with 81 passed, 0 failed, 0 skipped.

## Fix visible report attendee numbering

- [x] Keep the app attendees editor unchanged as plain right-aligned names
- [x] Fix exported DOCX attendees so Word visibly shows `1. שם`, not clipped dots
- [x] Keep exported PDF attendee markers visually as `1. שם`
- [x] Update tests/lessons for Word RTL list marker clipping
- [x] Run verification

## Review

- App editor: unchanged from the previous fix; it remains plain right-aligned attendee names with no visible numbering.
- DOCX: kept real Word numbering, but widened the centered attendee list container from 2200 to 2800 twips and increased the RTL numbering gutter to `w:start="900"` / `w:hanging="480"` so Word has room to render the digit plus dot instead of clipping the digit and showing only dots.
- PDF: unchanged; it already draws an explicit visible marker such as `1.` next to the attendee name inside the compact centered block.
- Tests: XcodeBuildMCP `test_sim` passed on iPhone 16 / iOS 18.6 with 81 passed, 0 failed, 0 skipped.

## Attendees under heading with DOCX auto-numbering

- [x] Remove visual numbering from the in-app attendees editor
- [x] Keep app attendees as simple right-aligned newline-separated names
- [x] Export DOCX attendees as a real Word numbered list so Enter continues numbering
- [x] Position DOCX/PDF attendee list under the `נוכחים:` heading, not at the page edge
- [x] Update tests, lessons, and run verification

## Review

- App editor: removed the custom visual numbering overlay. The report attendees field now uses a plain right-aligned RTL multiline editor, so the app shows only names line-by-line.
- PDF: cover attendees still render numbered, but the measured marker/name rows are centered as one compact block under `נוכחים:` instead of being pushed to the page edge.
- DOCX: cover attendees export as editable Word numbered paragraphs using `w:numPr`/`numId=2`; the attendee text runs contain only names, not manual `1.` strings. The numbered paragraphs sit inside a borderless one-cell centered container, with no tabs, no positioned table, and no old two-column grid.
- Tests: XcodeBuildMCP `test_sim` passed on iPhone 16 / iOS 18.6 with 81 passed, 0 failed, 0 skipped.

## Force attendees visual-right anchoring

- [x] Force the report attendees editor to use local RTL/right anchoring regardless of environment layout direction
- [x] Keep the attendee number and name compact in one visual row
- [x] Anchor PDF attendees to the right side of the cover content area
- [x] Anchor DOCX attendees to the right side as editable text, without two marker/name columns
- [x] Update tests, lessons, and run verification

## Review

- App editor: forced the attendees editor to local RTL/right anchoring and changed marker drawing so the marker is measured next to the right-aligned name, not drawn from the left side of the card.
- PDF: attendees are drawn row-by-row, with each name anchored to the right edge and its number placed immediately beside it.
- DOCX: attendees now export in a borderless one-column right-aligned table. Each row remains one editable text line such as `1. שלום`; there are no marker/name columns, no tabs, and no positioned table.
- Tests: XcodeBuildMCP `test_sim` passed on iPhone 16 / iOS 18.6 with 81 passed, 0 failed, 0 skipped.

## Compact RTL attendees across app, PDF, and DOCX

- [x] Replace the report attendees editor split-column layout with a compact RTL list
- [x] Keep attendee storage newline-based and avoid persisting generated numbers
- [x] Render PDF attendees as right-aligned single-line list items, not separate marker/name rectangles
- [x] Render DOCX attendees as editable RTL paragraphs, not a positioned marker/name table or tabs
- [x] Update focused tests for compact attendees and no split-column DOCX XML
- [x] Build/run tests and document review results

## Review

- App editor: replaced the wide fixed marker/name column view with a compact numbered gutter inside the same multiline text editor. The saved `report.attendees` value remains newline-separated names only; generated numbers are still visual-only.
- PDF: cover attendees now render as one right-aligned text block where each attendee line is one compact string such as `1. אלון`, not separate marker/name rectangles.
- DOCX: cover attendees now export as normal editable RTL paragraphs, one attendee per paragraph, with no attendee positioned table, fixed grid columns, tabs, or image conversion.
- Tests: XcodeBuildMCP `test_sim` passed on iPhone 16 / iOS 18.6 with 80 passed, 0 failed, 0 skipped.

## Fixed-column attendees across app, PDF, and DOCX

- [x] Replace the report attendees editor display with fixed visual columns for marker and name
- [x] Keep Return/newline storage behavior unchanged
- [x] Keep PDF cover attendees on fixed marker/name columns, including 10+ attendee markers
- [x] Change DOCX cover attendees to a borderless fixed-width table instead of centered text lines
- [x] Verify app, PDF render, DOCX render/XML, and update lessons

## Review

- App editor: replaced the attendees editor rendering with a fixed two-column UIKit-backed view. The stored text is still only newline-separated attendee names; the visual markers are drawn in a separate right-side marker column, and the name text view sits in a fixed column to its left. Return still adds a new attendee row.
- App visual verification: on iPhone 16 / iOS 18.6, typed short and longer Hebrew names through the on-screen Hebrew keyboard and captured `/var/folders/xf/8h1_qd0x159_l7v8kj6dxpk40000gn/T/screenshot_optimized_2315a2fa-dac1-4215-af41-a35d99aeefcd.jpg`. The number column stays on the visual right and the names start in the left column.
- PDF: cover-page attendees now render row-by-row with measured fixed rectangles: one marker rect and one name rect. The list remains centered as a block, but individual name length no longer changes the marker x-position. The test data covers 12 attendees, including `.10`, `.11`, and `.12`.
- PDF visual verification: rendered `/Users/aloniter/Projects/InspectorPro/tmp/pdfs/generated/attendees-fixed-columns-sample.pdf` to `/Users/aloniter/Projects/InspectorPro/tmp/pdfs/generated/attendees-fixed-columns-sample-page1.png`; markers `.1` through `.12` align in one visual-right column with names in a separate fixed column.
- DOCX: cover-page attendees now export as a real borderless fixed-width Word table. The grid is a wide editable name column plus a narrow marker column on the visual right, with no visible borders and no image conversion.
- DOCX visual/XML verification: rendered `/Users/aloniter/Projects/InspectorPro/tmp/docs/generated/attendees-fixed-columns-sample.docx` with Quick Look to `/Users/aloniter/Projects/InspectorPro/tmp/docs/generated/attendees-fixed-columns-sample.docx.png` and inspected `/Users/aloniter/Projects/InspectorPro/tmp/docs/generated/attendees-fixed-columns-documentxml-snippet.txt`; the snippet has fixed `w:tblGrid` widths `2760` and `480`, positioned table x `3532`, separate editable name/marker cells, and marker rows including `.1` and `.10`.
- Tests: XcodeBuildMCP `test_sim` passed on iPhone 16 / iOS 18.6 with 81 passed, 0 failed, 0 skipped.

## PDF cover attendee number column alignment

- [x] Draw PDF cover attendees with a fixed number column and fixed name column
- [x] Keep the attendees block centered under the `נוכחים:` heading
- [x] Verify DOCX cover attendee markers stay editable and render with RTL dot placement
- [x] Run tests and visually verify the rendered PDF cover page
- [x] Document review results

## Review

- Reworked PDF cover attendee rendering so the list is centered as a block, but each row uses a fixed number column and a fixed attendee-name column. Short names such as `היי` no longer shift `2.` horizontally.
- Corrected the fixed-column order back to Hebrew RTL: the number column is on the visual right and the attendee-name column is to its left.
- Added structured `ExportTextFormatter.NumberedAttendee` data while preserving `numberedAttendeeLines(from:)` for DOCX/current text-based callers, with the DOCX marker emitted as an editable text run that renders visually as `.1`, `.2`, etc. in RTL.
- Added focused tests for structured attendee formatting, fixed RTL PDF row column geometry, generating a cover PDF with `שלום\nהיי\nאלון\nיובל`, and generating a DOCX cover whose XML contains editable RTL attendee markers.
- Captured the correction in `tasks/lessons.md` so future centered numbered lists do not rely on per-line centering.
- Verification: XcodeBuildMCP `test_sim` passed on iPhone 16 / iOS 18.6 with 81 passed, 0 failed, 0 skipped. Re-ran with `KEEP_ATTENDEE_ALIGNMENT_PDF=1` and `KEEP_ATTENDEE_ALIGNMENT_DOCX=1` to retain visual samples.
- Visual verification: rendered `tmp/pdfs/generated/attendees-alignment-sample.pdf` to `tmp/pdfs/generated/attendees-alignment-sample-page1.png` with `pdftoppm`; the rendered PNG shows `.1`, `.2`, `.3`, and `.4` in one aligned visual-right number column.
- DOCX verification: generated `tmp/docs/generated/attendees-alignment-sample.docx`, rendered a Quick Look thumbnail at `tmp/docs/generated/attendees-alignment-sample.docx.png`, and inspected `word/document.xml`; attendee lines are editable text values such as `‫1‬. שלום`, which render visually as `שלום .1`.

## Report attendees multiline input

- [x] Replace the single-line report attendees field with a multiline RTL input
- [x] Preserve visual-right placeholder/value alignment in Hebrew
- [x] Keep export storage as newline-separated attendees so PDF/DOCX numbering stays unchanged
- [x] Build, run tests, and inspect the Hebrew edit-report screen
- [x] Document review results

## Review

- Replaced the report attendees `DirectionalTextField` with a dedicated multiline `ReportAttendeesEditor` backed by `DirectionalTextEditor`, so Return creates a new attendee line instead of behaving like a single-line field.
- Added explicit alignment support to `DirectionalTextEditor` and used `.right` for attendees, preserving Hebrew visual-right text/placeholder alignment and keeping the clear button on the visual left.
- Export storage remains the same newline-separated `report.attendees` string; PDF/DOCX numbering behavior was not changed.
- Verification: XcodeBuildMCP `test_sim` passed on iPhone 16 / iOS 18.6 with 78 passed, 0 failed, 0 skipped.
- Runtime: XcodeBuildMCP build/run succeeded on iPhone 16 / iOS 18.6. Edit-report screenshot confirmed existing attendee text is visually right-aligned with clear button on the left: `/var/folders/xf/8h1_qd0x159_l7v8kj6dxpk40000gn/T/screenshot_optimized_5cc4e378-d9ca-4cf5-b1eb-d7a9c7caa27b.jpg`.
- Runtime: after clearing the field, typing one character, pressing Return, and typing another character, screenshot confirmed two separate visual-right lines: `/var/folders/xf/8h1_qd0x159_l7v8kj6dxpk40000gn/T/screenshot_optimized_9f7ce51b-9842-45d2-babf-21b9dd653d7f.jpg`. The test edit was canceled without saving.

## Photo editor preview visual polish

- [x] Polish photo detail preview card without changing fit, scroll, annotation, save, or export behavior
- [x] Polish the notes/action panel so it feels connected to the editor
- [x] Verify no export files or annotation geometry changed
- [x] Run tests and `git diff --check`
- [x] Capture simulator visual confirmation

## Review

- Updated only the photo detail presentation: the preview now sits in a rounded neutral stage with a subtle border/shadow, while the image remains `scaledToFit`.
- Polished the fixed notes/action panel with a connected surface, bordered notes field, and larger controls. No `ScrollView` was added.
- Did not change `AnnotationView.swift`, annotation geometry/rendering, saved annotated image rendering, or PDF/DOCX export behavior.
- Verification: XcodeBuildMCP `test_sim` passed on iPhone 16 / iOS 18.6 with 78 passed, 0 failed. XcodeBuildMCP `test_sim` also passed on iPhone 16e / iOS 18.6 with 78 passed, 0 failed.
- Runtime: photo detail UI snapshot had no scroll targets and visible delete/annotation buttons. Screenshot captured at `/var/folders/xf/8h1_qd0x159_l7v8kj6dxpk40000gn/T/screenshot_optimized_9bdfb99c-215e-4e3f-b68e-1d98d5b02fcc.jpg`.

## Photo edit annotation viewport fit

- [x] Audit current photo detail, annotation, save, and export image paths
- [x] Refactor annotation editor into a fixed viewport with visible bottom controls
- [x] Keep annotation hit testing, preview drawing, and saved rendering on the same aspect-fit image bounds
- [x] Add focused geometry/rendering tests for portrait, landscape, tall images, and normalized alignment
- [x] Build/run tests and verify on small and current iPhone simulators in Hebrew/RTL
- [x] Document review results

## Review

- Replaced the photo detail `ScrollView` with a fixed editor layout: flexible aspect-fit image preview above a compact fixed bottom notes/action panel. Delete and annotation actions are visible immediately.
- Refactored `AnnotationView` into a fixed vertical layout. The controls bar is no longer inserted after the canvas; the canvas gets only the remaining height.
- Added shared `AnnotationGeometry` and `AnnotationImageRenderer` helpers so visible preview math, gesture normalization, saved composite rendering, and tests use the same aspect-fit image bounds.
- Export audit/fix: PDF/DOCX consume `photo.displayImagePath`, so saved annotated composites are the exported source. Report export image placement was restored to the previous fill-cell behavior: PDF draws into the full image cell rectangle, and DOCX emits the full image-cell extent with no crop metadata.
- Tests: XcodeBuildMCP `test_sim` passed after restoring export fill-cell behavior on iPhone 16 / iOS 18.6 with 78 passed, 0 failed. XcodeBuildMCP `test_sim` also passed on iPhone 16e / iOS 18.6 with 78 passed, 0 failed.
- Sample export confirmation: generated `tmp/pdfs/generated/export-fill-cell-sample.pdf` and `tmp/pdfs/generated/export-fill-cell-sample.docx`. Rendered PDF page `tmp/pdfs/generated/export-fill-cell-sample-2.png` shows the image filling the image cell with no centered inner margins; DOCX `word/document.xml` has no `<a:srcRect>` and full-cell image extent `3831082 x 3834701` EMU.
- Runtime: XcodeBuildMCP build/run succeeded on iPhone 16 / iOS 18.6. Visual photo detail screenshot showed no scroll targets and visible image, notes, delete, and annotation controls: `/var/folders/xf/8h1_qd0x159_l7v8kj6dxpk40000gn/T/screenshot_optimized_eb81d9b6-35c7-4bad-b9b6-a89185d78a1b.jpg`.
- Runtime: annotation screen screenshot showed full-width aspect-fit image, no scroll targets, and all drawing controls visible: `/var/folders/xf/8h1_qd0x159_l7v8kj6dxpk40000gn/T/screenshot_optimized_9a39634f-614b-480a-97f9-05ac61cb226d.jpg`.
- Runtime: iPhone 16e build/run succeeded but opened to login with no accessible seeded photo data; screenshot captured at `/var/folders/xf/8h1_qd0x159_l7v8kj6dxpk40000gn/T/screenshot_optimized_b67f9d8e-bf4d-4ee4-a76e-ad1c9d1dfd7e.jpg`.

## Export sheet RTL layout polish

- [x] Move the `פורמט` and `סיכום` section headers to the visual right
- [x] Keep `מספר ליקויים פתוחים` on the visual right and the count on the visual left
- [x] Build and run the Swift Testing suite
- [x] Document verification results

## Review

- Added explicit `ExportSectionHeader` rendering in `ExportOptionsSheet` so `פורמט` and `סיכום` are pinned to the visual right inside the export sheet form.
- Added `ExportSummaryRow` with fixed left-to-right row layout: the count is pinned to the visual left and `מספר ליקויים פתוחים` is pinned to the visual right.
- Verification: XcodeBuildMCP build/run succeeded on iPhone 16 Pro / iOS 18.6 with no warnings or errors.
- Tests: XcodeBuildMCP `test_sim` passed with 73 passed, 0 failed, 0 skipped.
- Visual export-modal capture was not completed in this simulator session because the app launched to the unauthenticated login screen.

---

## Export shows open defects count (screen + PDF + DOCX)

- [x] Add a shared `Report.openDefectCount` helper (logical photo count; annotated copies not counted separately)
- [x] Export screen `סיכום` row: replace `תמונות X` with `מספר ליקויים פתוחים X`, same RTL row style
- [x] PDF cover/first page: add combined line `מספר ליקויים פתוחים: X`
- [x] DOCX cover/first page: add the same combined line
- [x] Localize `מספר ליקויים פתוחים` (he + en `Open defects`)
- [x] Tests + full suite green

## Review

- Added `Report.openDefectCount` in `Models/Project.swift`; it returns `photos.count`. Each `PhotoRecord` is one logical defect and an annotated copy lives on the same record, so annotating never inflates the count and deleting a photo lowers it.
- `ExportOptionsSheet` summary row now uses the helper and the new label; layout (label right, number left) is unchanged.
- PDF: new `drawCoverSummaryLine` renders one centered, RTL-embedded line after the date section in `PdfExporter.drawCoverPage`.
- DOCX: `coverDetailsXML` gained a required `defectCount:` parameter and a new `defectSummaryXML` paragraph (centered, bold, muted) placed after the date section; `DocxExporter` passes `report.openDefectCount`.
- Localization added to both `he.lproj`/`en.lproj` `Localizable.strings`; `plutil -lint` clean.
- Verification: `xcodebuild ... test` on iPhone 16 / iOS 18.6 — **73 tests passed, 0 failed**. New tests: `reportOpenDefectCountMatchesLogicalPhotoCountIgnoringAnnotations`, `docxCoverDetailsIncludesOpenDefectCountAsSingleCombinedLine`. Updated 3 existing `coverDetailsXML` call sites for the new parameter.
- PDF first-page text cannot be unit-asserted in this environment (consistent with prior export tasks); covered by build + shared helper. Manual on-device spot-check noted in the 1.0.2 draft follow-ups.

---

## App icon on splash and login

- [x] Confirm current splash/login image wiring
- [x] Replace the `AppLogo` image asset with the App Store app icon artwork
- [x] Build the app and verify the login/launch branding path
- [x] Document the result and any verification limits

## Review

- Replaced `InspectorPro/Resources/Assets.xcassets/AppLogo.imageset/inspectley-icon.png` with the App Store icon artwork from `AppIcon.appiconset/ItunesArtwork@2x.png`.
- `LoginView` and `LaunchScreen.storyboard` already reference `AppLogo`, so both login and splash now use the same app icon artwork without additional view/storyboard wiring changes.
- Verification: AppLogo is now `1024 x 1024`, RGB PNG, no alpha, and byte-identical to the App Store icon file.
- Verification: XcodeBuildMCP build/run succeeded on iPhone 16 Pro / iOS 18.6; login screenshot showed the App Store icon. Screenshot captured at `/var/folders/xf/8h1_qd0x159_l7v8kj6dxpk40000gn/T/screenshot_optimized_aa220456-bec5-4149-bc5c-7b8f124e2bb6.jpg`.
- Tests: XcodeBuildMCP `test_sim` passed with 71 passed, 0 failed, 0 skipped.

## Codex iOS build/test workflow verification

- [x] Configure XcodeBuildMCP defaults for `InspectorPro.xcodeproj`, scheme `InspectorPro`, on an iPhone simulator
- [x] Build, install, and launch Inspectley from Codex
- [x] Run the Swift Testing suite from Codex
- [x] Capture simulator proof or explain any tooling blocker

## Review

- Build/run succeeded on iPhone 16 Pro / iOS 18.6 through XcodeBuildMCP. App bundle: `com.aloniter.inspectorpro`.
- Tests succeeded through XcodeBuildMCP: 71 passed, 0 failed, 0 skipped.
- Simulator screenshot captured at `/var/folders/xf/8h1_qd0x159_l7v8kj6dxpk40000gn/T/screenshot_optimized_d423e052-beab-469e-aa1a-7cb432383a76.jpg`.
- Live simulator mirror started with `serve-sim` at `http://localhost:3200/` and opened in the Codex browser. Browser verification found visible simulator canvases on the `Simulator Preview` page.
- Browser screenshot capture timed out, so visual proof is the simulator screenshot plus the verified live mirror state.

---

## Settings company refresh row placement

- [x] Move the `רענון פרטי חברה` action lower in Settings, near company branding
- [x] Preserve authenticated-only behavior and refresh error display
- [x] Build and verify the Settings screen still launches

## Review

- Moved the refresh-company-details action out of the top account area and into the company branding section, below the branding row.
- The action still appears only for authenticated users and still shows the same loading/error state.
- Verification: XcodeBuildMCP build/run succeeded on iPhone 16 Pro / iOS 18.6; Settings UI snapshot showed `רענון פרטי חברה` after the branding row; final restored Settings screenshot captured at `/var/folders/xf/8h1_qd0x159_l7v8kj6dxpk40000gn/T/screenshot_optimized_d18b7dc1-e59b-458e-a206-efd248cbcd29.jpg`.
- Tests: XcodeBuildMCP `test_sim` passed with 71 passed, 0 failed, 0 skipped.

---

## Settings account deletion row placement

- [x] Move `בקשת מחיקת חשבון` below `רענון פרטי חברה`
- [x] Keep account deletion authenticated-only and preserve the footer text
- [x] Build, inspect Settings ordering, and run tests

## Review

- Moved the account deletion section from the top account area to immediately after the company branding section, so it appears below `רענון פרטי חברה`.
- The deletion request remains authenticated-only and keeps its support-email footer text.
- Verification: XcodeBuildMCP build/run succeeded on iPhone 16 Pro / iOS 18.6; Settings UI snapshot showed `רענון פרטי חברה` before `בקשת מחיקת חשבון`; screenshot captured at `/var/folders/xf/8h1_qd0x159_l7v8kj6dxpk40000gn/T/screenshot_optimized_e6e61725-cb47-44f0-a563-697a324e3941.jpg`.
- Tests: XcodeBuildMCP `test_sim` passed with 71 passed, 0 failed, 0 skipped.

---

## Report attendees RTL field alignment

- [x] Move the `נוכחים` field placeholder/input to the visual right in the report form
- [x] Build and inspect the Hebrew new-report screen on simulator
- [x] Run the Swift Testing suite

## Review

- Replaced the SwiftUI vertical `TextField` for report attendees with the existing UIKit-backed `DirectionalTextField`, forced to `.right`, so placeholder/text use RTL alignment like the other report fields.
- Verification: XcodeBuildMCP build/run succeeded on iPhone 16 Pro / iOS 18.6; opened a new report form and visually confirmed the `נוכחים` placeholder appears on the visual right. Screenshot captured at `/var/folders/xf/8h1_qd0x159_l7v8kj6dxpk40000gn/T/screenshot_optimized_6e019fae-f368-4dd4-943e-af3dcd5603e4.jpg`.
- Note: AXe UI automation could not type Hebrew characters for entered-text verification because it only supports US keyboard characters.
- Tests: XcodeBuildMCP `test_sim` passed with 71 passed, 0 failed, 0 skipped.

---

## Branding company name RTL field alignment

- [x] Move the company name field value/placeholder to the visual right in Branding Settings
- [x] Build and inspect the Hebrew Branding Settings screen on simulator
- [x] Run the Swift Testing suite
- [x] Update v1.0.2 draft notes

## Review

- Replaced the SwiftUI `TextField` for company name in Branding Settings with the existing UIKit-backed `DirectionalTextField`, forced to `.right`.
- Removed the now-unused local `textAlignment` helper from `BrandingSettingsView`.
- Verification: XcodeBuildMCP build/run succeeded on iPhone 16 Pro / iOS 18.6; opened `מיתוג חברה` and visually confirmed the company name value appears on the visual right. Screenshot captured at `/var/folders/xf/8h1_qd0x159_l7v8kj6dxpk40000gn/T/screenshot_optimized_fb9e0707-c480-4564-87ea-023a03918a63.jpg`.
- Tests: XcodeBuildMCP `test_sim` passed with 71 passed, 0 failed, 0 skipped.
- Updated `tasks/appstore-submission/version-1.0.2-draft-notes.md` with this branding RTL fix.

---

## Branding settings RTL toggle row placement

- [x] Put `הצג לוגו בדוח` label on the visual right and its switch on the visual left
- [x] Apply the same RTL row treatment to `הצג כותרת בדוח` for consistency
- [x] Build and inspect Branding Settings on simulator
- [x] Run the Swift Testing suite
- [x] Update v1.0.2 draft notes

## Review

- Added `BrandingSettingsToggleRow`, an explicit RTL settings row with switch on the visual left and label on the visual right.
- Replaced the native SwiftUI toggles for `הצג לוגו בדוח` and `הצג כותרת בדוח`.
- Verification: XcodeBuildMCP build/run succeeded on iPhone 16 Pro / iOS 18.6; opened `מיתוג חברה` and visually confirmed the logo/header toggles now place switches on the left and labels on the right. Screenshot captured at `/var/folders/xf/8h1_qd0x159_l7v8kj6dxpk40000gn/T/screenshot_optimized_96b89ba5-1ad3-417b-938f-2cf957ded700.jpg`.
- Tests: XcodeBuildMCP `test_sim` passed with 71 passed, 0 failed, 0 skipped.
- Updated `tasks/appstore-submission/version-1.0.2-draft-notes.md` with this branding toggle RTL fix.

---

## Branding logo picker RTL action row

- [x] Make `בחר לוגו מהספריה` use explicit RTL visual order
- [x] Build and inspect Branding Settings on simulator
- [x] Run the Swift Testing suite
- [x] Update v1.0.2 draft notes

## Review

- Added `BrandingSettingsActionRow`, an explicit icon/text action row for Branding Settings.
- Replaced the native SwiftUI `Label` in the logo picker with the explicit row so `בחר לוגו מהספריה` uses RTL visual order with the icon on the right.
- Verification: XcodeBuildMCP build/run succeeded on iPhone 16 Pro / iOS 18.6; opened `מיתוג חברה` and visually confirmed the logo picker action row is RTL. Screenshot captured at `/var/folders/xf/8h1_qd0x159_l7v8kj6dxpk40000gn/T/screenshot_optimized_e85d0aa1-1a79-4383-a0e9-a035ee606095.jpg`.
- Tests: XcodeBuildMCP `test_sim` passed with 71 passed, 0 failed, 0 skipped.
- Updated `tasks/appstore-submission/version-1.0.2-draft-notes.md` with this logo picker RTL fix.

---

## App Store 6.5-inch screenshot polish

- [x] Confirm App Store technical constraints for the existing 6.5-inch screenshot slot
- [x] Create a reusable screenshot composition script using real app screenshots as the UI source
- [x] Generate a new `iphone-6.5-v2` set without overwriting current screenshots
- [x] Verify generated dimensions, color mode, and visual quality
- [x] Document the result and remaining App Store review caveats

## Review

- Added `AppStore/scripts/make_appstore_screenshots.py`, which composes the real 6.5-inch app UI captures into a cleaner App Store presentation with Hebrew headlines, benefit subtitles, professional light background, and an iPhone-style frame.
- Generated six new PNG files in `AppStore/screenshots/iphone-6.5-v2/`; the original `AppStore/screenshots/iphone-6.5/` files were not overwritten.
- Verification: all generated files are `1242 x 2688`, PNG, RGB/no alpha, and the script reruns successfully.
- App Store caveat: these are technically valid for the 6.5-inch screenshot slot and use real app UI, but Apple review can still reject screenshots if the displayed app content/branding does not match the submitted binary. The current screenshots still show the existing in-app `Inspectley` logo/login branding where that appears in the real app capture.

---

# v1.0.1 — Storage & Export Cleanup — ✅ COMPLETE (2026-06-17)

> Status: **implemented, tested (71 passing), real-device share QA passed.** One clean commit prepared.
> Scope was locked to storage/export *file hygiene*. RTL/UI polish was completed earlier in the cycle.

## FINAL v1.0.1 SUMMARY (release `release-prep`)
**Two bodies of work shipped in 1.0.1:**
1. **Hebrew/RTL UI polish** — Project/Report forms, Settings rows/headers, mixed Hebrew/English values, report-editor date row. (`DirectionalTextField` alignment option; `AccountInfoRow`/`Settings*Row` helpers; RTL rules added to `AGENTS.md`.)
2. **Storage/export cleanup** — removed dead `ExportCache`; safe empty-folder cleanup on project delete (never touches non-empty/moved-photo folders); transient exports (delete-after-share + purge `Exports/` on launch).

**Verification:** clean build, **71 Swift Testing tests pass** (iPhone 16 sim), real-device PDF/DOCX share QA passed.
**Guardrails honored:** originals/annotated photos never deleted; non-empty folders never removed; export quality unchanged (economical); no workflow changes.
**Security:** redacted a plaintext reviewer password from `tasks/appstore-submission/SUBMISSION-PACKAGE.md` (2 spots). NOTE: it remains in git **history** — rotate the reviewer account password after release.
**Excluded from the commit (untracked, unrelated):** `inspectley_login/` (login design prototype), `AppStore/` screenshot binaries + `.DS_Store`.
**Version:** bumped to `MARKETING_VERSION 1.0.1` / build `2` (done); `xcodegen generate` run; 71 tests still pass.
**Reviewer account:** VERIFIED working 2026-06-17 (login + export entitlement active, trial_end 2030-12-31). Credentials kept UNCHANGED. Password only in gitignored `reviewer-credentials.local.md` + App Store Connect; removed from tracked docs (still in older git history).
**Submission docs:** `version-1.0.1-fix-summary.md`, `review-notes.md`, `version-1.0.1-archive-upload-checklist.md`.

---

## Guardrails / non-goals (do NOT touch in 1.0.1)
- Export quality stays **economical only**. No quality picker. No multiple quality modes.
- No cloud storage. No Supabase photo storage.
- No Share-individual-photo, no Save-to-Gallery, no Move/Copy photos between projects.
- No Storage-management screen UI.

## Explicitly deferred from the earlier approved scope (flagging so you can pull back if intended)
- **Annotated image quality 0.92 → 0.85** (old item 5) — *deferred* per "cleanup only."
- **PDF byte-budget audit / enforcement** (old item 6) — *deferred* per "cleanup only."
  - (Both are real wins but are export *content* changes, not file hygiene. Say the word and I re-add them.)

## Decisive facts this plan relies on (verified in code)
- Exports are written **permanently** to `Documents/InspectorPro/Exports/` and are **never cleaned**; re-exports add `_1/_2…` duplicates. (`PdfExporter.outputFileURL`, `DocxExporter.outputFileURL`)
- The app sets **no `UIFileSharingEnabled` / `LSSupportsOpeningDocumentsInPlace`** → `Documents/` is private; export files are **not** visible in the Files app. ⇒ purging them is invisible to users and safe.
- `ExportCache` is **dead**: only `invalidate(for:)` is ever called (2 sites in `AnnotationView`), and it operates on a cache that is **never populated or read**. (`compressedImageData`/`clearAll` have zero callers.)
- Project deletion deletes photo files **by path** and leaves an **empty** `Images/<projectID>/` dir behind. The existing `deleteProjectDirectory(_:)` (wholesale `rm -rf`) is intentionally **unused** because a moved report's photos can still physically live in its old project's folder.
- Launch hook for maintenance already exists: `FileManagerService.ensureDirectoriesExist()` in `InspectorProApp.init()`.

---

## Key design decision (needs your nod): export retention model
**Recommended — "transient exports":**
1. Delete each exported file when its share session finishes (`UIActivityViewController.completionWithItemsHandler`).
2. On app launch, empty the `Exports/` directory (regenerable on demand; reclaims existing backlog).

Result: `Exports/` is ~empty at rest, ≤ one export (~≤11 MB economical) at peak.

**Alternative — "keep then purge":** keep exports, purge on launch anything older than 24 h (lets users re-share without re-exporting). Slightly more storage; I don't recommend it given exports are cheap to regenerate.

→ **Plan below assumes the recommended transient model.** Tell me if you want the 24 h variant.

---

## Change 1 — Transient export files (cleanup + retention + stop accumulation + sharing-safe)
Covers: "Exports folder cleanup", "prevent repeated exports accumulating forever", "safe retention policy", "verify cleanup does not break sharing".

**Files:** `Services/FileManagerService.swift`, `InspectorProApp.swift`, `Views/Export/ExportOptionsSheet.swift` (`ShareSheet`).

**Tasks**
- [x] Add `FileManagerService.purgeExports()` — delete all files inside `Exports/`, keep the directory. ✅ (also removes the legacy empty `ExportCache/` dir)
- [x] Call `purgeExports()` from `InspectorProApp.init()` right after `ensureDirectoriesExist()`. ✅
- [x] In `ShareSheet.makeUIViewController`, set `completionWithItemsHandler` to delete `fileURL` once the activity finishes (completed **or** cancelled). ✅
- [x] Keep the existing `_1/_2…` filename uniquifier. ✅ (untouched)
- [x] Tests: `purgeExports()` empties the dir but keeps the directory. ✅ `purgeExportsClearsLeftoverFilesButKeepsExportsDirectory`
- [ ] Manual share QA matrix — **requires a device/your hands** (see verification). Code path verified; cannot be unit-tested.

- **Expected storage savings:** One-time reclaim of the **entire existing `Exports/` backlog** on first 1.0.1 launch — unbounded today (heavy users: tens→hundreds of MB; e.g. 30 exports × ~4 MB ≈ 120 MB). Ongoing: unbounded growth → **~0 at rest, ≤~11 MB transient peak**.
- **Risk level:** **MEDIUM** — only because it touches the share flow. Mitigations: delete strictly in `completionWithItemsHandler`; launch purge is a belt-and-suspenders safety net; manual share QA matrix (below).
- **Impact on existing reports/projects:** **None** to data. Existing accumulated export *files* are cleared on first launch — intended, and they regenerate on demand.
- **Migration requirements:** **None** (filesystem only; no schema change).
- **App Store review impact:** **None.** No new permissions/privacy; no file-sharing flag, so files aren't user-visible. Mild positive (smaller footprint).

## Change 2 — Remove dead `ExportCache` code
Covers: "Remove unused ExportCache code if truly dead." (Confirmed dead.)

**Files:** delete `Export/ExportCache.swift`; `Views/Photos/AnnotationView.swift` (remove the 2 `ExportCache.shared.invalidate(for:)` calls, ~L169 & ~L189); `Utilities/Constants.swift` (remove `exportCacheDirectoryName` + `exportCacheURL`); `Services/FileManagerService.swift` (drop `exportCacheURL` from `ensureDirectoriesExist`). Then `xcodegen generate`.

**Tasks**
- [x] `grep -r ExportCache` returns **no** references after edits. ✅ (no refs in Swift sources or pbxproj)
- [ ] Optional defensive: delete any legacy `ExportCache/` dir on launch (typically empty → ~0 bytes). → folded into Step 3 launch maintenance.
- [x] `xcodegen generate`; confirm the file drops out of `project.pbxproj`. ✅ (0 references in pbxproj)
- [x] Build + full test suite pass on iPhone 16 sim. ✅ (69 tests passed)

- **Expected storage savings:** **~0 bytes** (cache was never populated). Value is code clarity + one fewer directory created at launch. *(Honest: this is a maintainability cleanup, not a storage win.)*
- **Risk level:** **LOW.** The only callers are no-ops against an empty cache; removing them changes no behavior. Annotation save/clear flow re-verified after removal.
- **Impact on existing reports/projects:** **None.**
- **Migration requirements:** **None.**
- **App Store review impact:** **None.**

## Change 3 — Remove orphaned empty image folders after project deletion
Covers: "Remove orphaned empty image folders after project deletion."

**Files:** `Services/ImageStorageService.swift` (new `removeDirectoryIfEmpty`), `Views/Projects/ProjectListView.swift` (`deleteProjects`).

**Critical safety constraint:** **remove a directory only if it is empty.** Do NOT use the wholesale `deleteProjectDirectory(_:)` — a report moved out of this project can still have its photo files physically stored under this project's folder, and a wholesale delete would destroy them.

**Tasks**
- [x] Add `ImageStorageService.removeDirectoryIfEmpty(at relativeDir:)` (lists contents; removes dir only when empty). ✅ + `FileManagerService.removeDirectoryIfEmpty(at:)` primitive.
- [x] In `deleteProjects`, after the existing by-path `deletePhotoFiles` loop, derive the unique parent dirs from `deletedPhotoPaths` and call `removeDirectoryIfEmpty` on each. ✅
- [x] Regression test: deleting a project whose report was moved elsewhere **preserves** the moved report's files (non-empty dir kept); a genuinely empty dir is removed. ✅ `removeDirectoryIfEmptyRemovesEmptyButPreservesMovedReportPhotos`
- [x] Scope to **project deletion only**. ✅
- [x] Build + full test suite pass (70 tests incl. new one). ✅

- **Expected storage savings:** **Negligible bytes** (empty directories). Value is hygiene — prevents orphan-folder accumulation over the app's lifetime.
- **Risk level:** **LOW as specified** (remove-only-if-empty). NOTE: a naive wholesale delete would be **HIGH** (moved-photo data loss) — the plan forbids it and adds the regression test.
- **Impact on existing reports/projects:** **None** (only empty dirs removed; moved-report files untouched).
- **Migration requirements:** **None.**
- **App Store review impact:** **None.**

---

## Cross-cutting verification (gate before "done")
- [x] `xcodegen generate` after removing `ExportCache.swift`. ✅ (0 refs in pbxproj)
- [x] Build (sim) clean; **full Swift Testing suite passes** — **71 tests** (69 original + 2 new), no errors/warnings. ✅
- [ ] **Manual share QA matrix** (the real risk surface for Change 1): export **PDF** and **DOCX**, then share via **AirDrop**, **Mail attach**, **WhatsApp (document)**, **Save to Files** — for each confirm: (a) share succeeds, (b) the export file is removed afterward, (c) re-export works, (d) after app relaunch `Exports/` is empty. → **needs you / a device.**
- [x] Annotation save/clear path reviewed after `ExportCache` removal (the removed `invalidate` calls were no-ops on a never-populated cache; thumbnail invalidation + model save are unchanged). ✅

## Implementation result (2026-06-17)
- **Files changed:** `Export/ExportCache.swift` (deleted), `Services/FileManagerService.swift`, `Services/ImageStorageService.swift`, `Utilities/Constants.swift`, `Views/Photos/AnnotationView.swift`, `Views/Projects/ProjectListView.swift`, `Views/Export/ExportOptionsSheet.swift`, `InspectorProApp.swift`, `InspectorProTests/ExportTests.swift`, regenerated `InspectorPro.xcodeproj`.
- **Tests:** 71 passing (added `removeDirectoryIfEmptyRemovesEmptyButPreservesMovedReportPhotos`, `purgeExportsClearsLeftoverFilesButKeepsExportsDirectory`).
- **Guardrails honored:** originals/annotated photos never deleted; non-empty folders never removed (`deleteProjectDirectory` wholesale delete left unused); export quality unchanged (economical); no workflow changes.
- **Not committed** — left for review alongside the separate uncommitted RTL work.
- **Note (optional follow-up, out of scope):** `ImageStorageService.deleteProjectDirectory(_:)` is now fully unused; could be removed later to eliminate a wholesale-delete footgun.

## Sequencing
1. Change 2 (lowest risk, isolates the `xcodegen generate`).
2. Change 3 (+ regression test).
3. Change 1 (+ manual share QA matrix).
- Work on a dedicated branch off `release-prep`; commit per change; run tests between.

## Combined outcome
- **Before:** `Exports/` grows without bound; re-exports duplicate; empty image folders pile up.
- **After:** `Exports/` ~0 at rest / ≤~11 MB peak; existing backlog reclaimed on first launch (the only large real-world win); no orphan folders; no dead cache code/dir.

**→ Awaiting approval. No code will change until you approve this plan (and confirm the retention model).**

---

## New report form RTL polish

- [x] Restore a full-width divider below the report date row
- [x] Move the attendees placeholder/text to the visual right
- [x] Verify the focused SwiftUI form change with build/test checks

## Review

- Updated the New/Edit Report date row to hide the default row separator and draw one full-width divider inside the row, so the line under `תאריך` spans the form content width.
- Forced the `נוכחים` input to use the current app language direction and matching text alignment, keeping the Hebrew placeholder and entered text on the visual right.
- Validation:
- XcodeBuildMCP `build_sim` on iPhone 16 / iOS 18.6 passed with no warnings or errors.
- XcodeBuildMCP `test_sim` on iPhone 16 / iOS 18.6 passed with 69 tests.

## v1.0.1 App Store fix summary

- [x] Create a dedicated 1.0.1 fix summary for App Store submission
- [x] Include paste-ready App Store "What's New" text in English and Hebrew
- [x] Include detailed internal fix list, changed files, and QA checklist

## Review

- Added `tasks/appstore-submission/version-1.0.1-fix-summary.md` for the next App Store update.
- The file summarizes the RTL fixes across Project forms, Report editing, and Settings.
- It includes App Store Connect release-note text, changed files, completed verification, and manual QA reminders before upload.

## v1.0.1 Settings full RTL polish

- [x] Inspect remaining Settings sections below account
- [x] Right-align Settings section headers
- [x] Put row labels/titles on the visual right and values/controls/actions on the visual left
- [x] Preserve account row fix and unrelated Settings behavior
- [x] Add permanent Hebrew / RTL UI Rules to project instructions
- [x] Run build/tests and record validation results

## Review

- Added Settings-specific row/header helpers so visual order is explicit without forcing the whole Settings screen LTR.
- `SettingsSectionHeader` right-aligns Hebrew section titles.
- `SettingsControlRow` puts controls such as the dark-mode toggle on the visual left and the row title on the visual right.
- `SettingsValueRow` puts values/actions such as the version, branding logo/disclosure, and other secondary content on the visual left while titles remain on the visual right.
- Replaced the native branding `NavigationLink` row with a plain button plus `navigationDestination` so the logo and chevron can stay grouped on the visual left and the company title/subtitle stay right-aligned.
- `SettingsActionRow` keeps the logout action readable and right-weighted without changing sign-out behavior.
- Preserved the existing account row fix: labels on the right, values/status/date on the left.
- Added `## Hebrew / RTL UI Rules` to `AGENTS.md`.
- Validation:
- `build_sim` via XcodeBuildMCP on iPhone 17 Pro / iOS 26.4 passed.
- `test_sim` via XcodeBuildMCP on iPhone 17 Pro / iOS 26.4 passed with 69 tests.
- `build_run_sim` launched the updated app in Hebrew, but the simulator remained on the login screen, so authenticated Settings visual inspection still needs a logged-in session.

## v1.0.1 Settings account RTL rows

- [x] Inspect Settings account section row layout
- [x] Add/update a reusable account detail row with value on visual left and label on visual right
- [x] Apply it to user, company, export status, and trial expiration rows
- [x] Keep unrelated Settings controls unchanged
- [x] Run build/tests and record validation results

## Review

- Replaced the account section's mirrored `HStack { label Spacer value }` rows with `AccountInfoRow`, a local two-column row that forces only row content to left-to-right physical layout.
- Each account row now renders the value view first on the visual left and the secondary label column second on the visual right.
- Email and trial date values keep a local left-to-right environment so they stay readable; the company name remains Hebrew but is placed in the left value column with controlled wrapping/truncation.
- The export status badge remains the same colored status view, now grouped on the left value side.
- Unrelated Settings sections, buttons, toggles, language selector, card styling, and navigation were not changed.
- Validation:
- `test_sim` via XcodeBuildMCP on iPhone 16 / iOS 18.6 passed with 69 tests.
- `build_sim` via XcodeBuildMCP on iPhone 16 / iOS 18.6 passed.
- `build_run_sim` on iPhone 17 Pro / iOS 26.4 launched the updated app in Hebrew, but the simulator was on the login screen, so live Settings account-section inspection still needs a logged-in session.

## v1.0.1 focused RTL polish

- [x] Inspect project/report form fields and current shared input behavior
- [x] Add an explicit alignment option to the shared directional text field
- [x] Set New Project/Edit Project name and address input content to visual right
- [x] Keep Edit Report name and address input content visual right
- [x] Remove the extra short date-row underline while preserving the long row separator
- [x] Run build/tests and record validation results

## Review

- Added `DirectionalTextFieldAlignment` so shared text fields can explicitly resolve content alignment as `.left`, `.right`, or the ambient layout direction. Existing callers keep the default layout-direction behavior.
- Project create/edit name and address fields now pass `.right`, forcing placeholder and entered value content to the visual right inside the field only.
- Report create/edit name and address fields now pass `.right`, keeping those Hebrew report details right-aligned in the RTL form.
- Removed the custom internal `Divider()` from `RTLDateField`; the `Form` row separator remains, eliminating the extra short underline below `תאריך` while preserving one row separator.
- Validation:
- `test_sim` via XcodeBuildMCP on iPhone 16 / iOS 18.6 passed with 69 tests.
- `build_sim` via XcodeBuildMCP on iPhone 16 / iOS 18.6 passed.
- The user-provided New Project screenshot showed the project placeholders on the visual left; source now sets those fields to `.right`.
- `git diff --check` passed.

## Cover page export typography 12pt

- [x] Inspect current PDF/DOCX cover-page font sizes and bold flags
- [x] Set cover-page metadata labels and values to 12pt in PDF and DOCX
- [x] Make only cover-page labels bold while keeping user-entered values regular
- [x] Update focused DOCX export tests for 12pt sizing and bold rules
- [x] Run build/tests and record validation results

## Review

- Added a shared 12pt cover metadata size and routed address/date/attendees/notes labels and values through it for PDF and DOCX.
- PDF cover export now renders address/date/notes labels and the `נוכחים` heading as bold, while all values and user-entered text render regular.
- DOCX cover export now emits 24 half-point font sizes for all cover metadata labels and values, with `<w:b/>` only on label paragraphs.
- Updated focused DOCX tests to assert 12pt sizing, bold labels, regular values, centered attendees, and no old blue attendee color.
- Validation:
- `test_sim` via XcodeBuildMCP on iPhone 16 / iOS 18.6 passed with 69 tests.
- `build_sim` via XcodeBuildMCP on iPhone 16 / iOS 18.6 passed.
- `git diff --check` passed.

## Language switch list text rendering

- [x] Inspect dynamic language switching and project/report row rendering
- [x] Force affected SwiftUI lists to rebuild when the app language changes
- [x] Verify build/tests after the scoped UI refresh fix

## Review

- Root cause is consistent with SwiftUI reusing `List` row render state while the app-wide `layoutDirection` changes from Hebrew RTL to English LTR. A fresh app launch rebuilt the rows, which is why the text looked correct only after restarting.
- Added language-scoped list identities to the project list, report list, and move-report project picker. When `languageCode` changes, SwiftUI now rebuilds those lists immediately instead of keeping rows in the bad intermediate text-rendering state.
- The fix does not mutate project/report names, remove bidi isolation, or manually reverse any user-entered text.
- Validation:
- `test_sim` via XcodeBuildMCP on iPhone 16 / iOS 18.6 passed with 69 tests.
- `build_sim` via XcodeBuildMCP on iPhone 16 / iOS 18.6 passed.
- `git diff --check` passed.

## Project form RTL and cover export metadata cleanup

- [x] Inspect current project creation form and cover export rendering for project name, address, attendees, and notes
- [x] Right-align the new-project name placeholder/input in Hebrew
- [x] Remove the fixed bold address label from the project/report address input while keeping the placeholder
- [x] Make `נוכחים` cover-page styling match the other metadata headings in PDF and DOCX
- [x] Omit the cover-page notes section from PDF and DOCX when notes are empty
- [x] Update focused export tests for attendee styling and empty notes omission
- [x] Run build/tests and record validation results

## Review

- Replaced the project/report name and address fields with the shared directional text field so empty placeholders align to the visual right in Hebrew.
- Removed the old inline `כתובת:` label inside the address field. The address row now shows only the `כתובת` placeholder until the user types.
- Strengthened `DirectionalTextField` so placeholders use the same paragraph alignment and writing direction as typed text.
- Updated PDF cover export so `נוכחים` uses the same muted heading color as `כתובת`, `תאריך`, and `הערות`, is not bold, and no longer uses the blue attendee accent color.
- Updated DOCX cover export with the same attendee heading style and regular black attendee lines.
- Changed DOCX/PDF notes handling so the cover-page `הערות` section is omitted when notes are nil, empty, or whitespace-only.
- Added focused DOCX tests for the new attendee styling and missing-notes omission.
- Validation:
- `test_sim` via XcodeBuildMCP on iPhone 16 / iOS 18.6 passed with 69 tests.
- `build_sim` via XcodeBuildMCP on iPhone 16 / iOS 18.6 passed.
- `git diff --check` passed.

## Report export 60/40 table proportions

- [x] Confirm current PDF/DOCX report tables use the shared image/text column ratios
- [x] Change the report table split to 60% photo / 40% description
- [x] Keep full-cell no-crop image placement for both PDF and DOCX
- [x] Update focused tests for the 60/40 ratios and recalculated full-cell DOCX image extents
- [x] Run build/tests and record validation results

## Review

- Changed the shared export table split from 68% image / 32% description to 60% image / 40% description in `ExportOptions`. PDF and DOCX both derive their table widths from these same ratios.
- Kept `ReportImageFitMode.fillCellNoCrop` unchanged. Images still fill the cell with no crop metadata and no aspect-fit white margins, but the narrower 60% image cell reduces horizontal stretch.
- DOCX image extents are still calculated from the current image cell drawable width and target image height. With the new ratio, the test exporter logs changed report images from roughly `476×361pt` to `418×361pt`.
- Updated export tests to assert exact 60/40 point, twip, and EMU ratios, plus the existing no-crop full-cell extents across landscape, portrait, and square fixtures.
- Validation:
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -derivedDataPath /tmp/InspectorPro-CodexDerivedData test CODE_SIGNING_ALLOWED=NO` passed with 66 Swift Testing tests.
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -derivedDataPath /tmp/InspectorPro-CodexDerivedData build CODE_SIGNING_ALLOWED=NO` passed.
- Residual warning:
- The existing CoreData editable-model checksum warning still appears during test-host startup.

## App Store release readiness for Inspectley 1.0.0

- [x] Inspect current App Store checklist and release-related project settings
- [x] Verify Supabase auth/export gating is present in the current codebase
- [x] Run release-style build and Swift Testing validation
- [x] Confirm App Store metadata, privacy policy, support URL, screenshots, and review credentials needed outside the repo
- [x] Produce easiest safe submission sequence for App Store Connect

## Review

- Current `main` is locally buildable for release after setting the first-release version to `1.0.0` build `1`: `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -configuration Release -destination 'generic/platform=iOS' -archivePath /tmp/InspectorPro-AppStore.xcarchive archive` succeeded.
- Simulator validation passed: `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' -derivedDataPath /tmp/InspectorPro-AppStore-DD test CODE_SIGNING_ALLOWED=NO` passed with 66 Swift Testing tests.
- `xcodebuild -resolvePackageDependencies -project InspectorPro.xcodeproj -scheme InspectorPro` passed and resolved Supabase 2.44.1 and ZIPFoundation 0.9.20.
- Archive Info.plist confirms display name `Inspectley`, bundle id `com.aloniter.inspectorpro`, version `1.0.0`, build `1`, iOS minimum `18.0`, category `public.app-category.utilities`, and `ITSAppUsesNonExemptEncryption = false`.
- Supabase auth is present, the root app requires login before project access, and export is gated through `ExportPermissionService` against Supabase profile/company rows.
- App Store audit confirmed no service-role Supabase key in source, no external payment/subscription/checkout links in app code, a valid 1024x1024 App Store icon, a branded launch screen, iPhone-only portrait settings, camera/photo library purpose strings, and PrivacyInfo declarations for linked email/UserDefaults/file timestamp access.
- Created App Store submission materials under `tasks/appstore-submission/`: Hebrew metadata, English metadata, privacy answers, App Review notes with the supplied reviewer account, exact submission steps, and a screenshot plan.
- Live App Store URLs were created and verified by the user:
- Privacy Policy URL: `https://aloniter.github.io/inspectley-appstore-pages/privacy.html`
- Support URL: `https://aloniter.github.io/inspectley-appstore-pages/support.html`
- Remaining manual App Store Connect items: upload the archive, paste the live URLs, fill App Privacy answers, upload screenshots, confirm category/age rating/pricing/availability, and submit for review.

## Report export full-cell image layout

- [x] Inspect current PDF/DOCX report image placement and identify why the exported image does not match manual Word resize
- [x] Add/adjust shared report image placement mode for full-cell no-crop stretching
- [x] Apply full-cell image drawing to PDF report table rows
- [x] Apply full-cell image dimensions to DOCX report table rows without crop metadata
- [x] Update focused export tests for full-cell image extents and no crop tags
- [x] Run build/tests and record validation results

## Review

- Root cause: the current export path had been changed to no-crop aspect-fit. That preserved the original photo aspect ratio but left visible empty bands inside the report image cell, which does not match a manual Word resize to the table borders.
- Added `ReportImageFitMode.fillCellNoCrop` and routed PDF report-table drawing through it. PDF now draws the baked annotated image directly into the padded image cell drawable rect, with no aspect-fit shrinking and no crop.
- Changed PDF row sizing to reserve the configured report image height instead of shrinking rows to the aspect-fit image height. The image column stays dominant at 68% and uses the existing 4pt cell padding.
- Changed DOCX image processing so each report image is inserted at the table image content width and target row/image height. DOCX still emits no `<a:srcRect>` crop metadata, and Word receives fixed dimensions like a manual resize.
- Updated focused tests from aspect-fit expectations to full-cell extent expectations across landscape, portrait, and square fixtures.
- Validation:
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -derivedDataPath /tmp/InspectorPro-CodexDerivedData test CODE_SIGNING_ALLOWED=NO` passed with 66 Swift Testing tests.
- Residual warning:
- The existing CoreData editable-model checksum warning still appears during test-host startup.

## Footer settings field layout

- [x] Create branch `fix/settings-footer-fields-layout` before making changes
- [x] Inspect current branding footer settings UI and export label usage
- [x] Rework footer settings inputs so each value is visually paired with its label in RTL
- [x] Change the additional contact visible field label from `מספר נוסף` to `דוא"ל`
- [x] Verify saved footer values still load/save through the existing model
- [x] Run focused build/tests and record results

## Review

- Updated the shared compact footer input component so the editable value appears above a divider and its label sits directly underneath inside the same visual block.
- Changed the secondary contact's second value field from `מספר נוסף` to `דוא"ל`, with email keyboard, email content type, no autocapitalization, and no autocorrection.
- Kept the existing `BrandingSecondaryFooterFields` storage and `secondaryFooterLine` save/load path unchanged, preserving existing saved footer values and avoiding migration changes.
- Export labels were not changed because PDF/DOCX footer rendering does not emit this settings field label; exports continue rendering the saved footer tokens through `BrandingFooterFormatter` runs.
- Validation:
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' build CODE_SIGNING_ALLOWED=NO` passed.
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' test CODE_SIGNING_ALLOWED=NO` passed with 65 Swift Testing tests.
- Residual warning:
- The existing CoreData editable-model checksum warning still appears during test-host startup.

## Export annotated image fit parity

- [x] Inspect annotation/export image fit model and identify mismatch root cause
- [x] Add shared export aspect-fit sizing helper
- [x] Apply no-crop centered aspect-fit rendering to PDF and DOCX report tables
- [x] Change report table image/text columns to an image-prioritized ratio
- [x] Update focused export tests for no-crop DOCX image fitting and column ratios
- [x] Replace fixed half-page finding rows with compact content-driven row sizing
- [x] Run export tests/build checks and record validation results

## Review

- Root cause: the annotation editor uses full-frame aspect-fit and saves a flattened annotated JPEG, but export rendering had switched report-table images to aspect-fill/cover behavior. PDF clipped the fitted image inside the cell, and DOCX emitted `<a:srcRect>` crop values, so exported annotations could appear visually shifted relative to the photo.
- Added shared `ExportImageFitter` sizing in export options and used it from PDF and DOCX report-table image rendering.
- PDF now draws each report image centered inside the padded image cell with no clipping/cropping and preserved aspect ratio.
- DOCX now writes proportional image extents that fit inside the image content box and always uses `ImageCrop.none`; generated report image XML no longer emits `<a:srcRect>`.
- Second-pass size fix: the aspect-fit helper was correct, but it was still fitting into a conservative target box: 65/35 columns, 4pt image cell padding, and a 12pt DOCX table safety gap.
- Third-pass layout fix: the table still looked unfinished because every finding row reserved a fixed half-page block, leaving huge blank description cells when text was short.
- Changed shared report table proportions to 68% image column / 32% text column and restored balanced 4pt image padding.
- Added a professional max image height of 260pt with a 96pt minimum row height.
- PDF now calculates each finding row from the fitted image height and measured description text height, so short findings shrink and long descriptions can grow naturally.
- DOCX no longer emits exact row height XML for finding rows; Word can auto-size each row from the image/text content.
- Added focused export tests for image-prioritized column sizing, shared PDF fit rect behavior, DOCX no-crop aspect-fit behavior, and absence of exact DOCX row-height rules.
- Validation:
- First `xcodebuild ... test` attempt failed because a new helper file was not included in the generated `.xcodeproj`; moved the helper into an existing export source file.
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -derivedDataPath /tmp/InspectorPro-CodexDerivedData test CODE_SIGNING_ALLOWED=NO` passed with 66 Swift Testing tests.
- PDF raster visual validation with `pdftoppm` was not available in this environment because Poppler is not installed; PDF aspect-fit behavior is covered by the shared fit-rectangle test used by `PdfExporter`.
- Visual QA checklist for manual review: landscape annotated + short description, portrait annotated + short description, landscape annotated + long description, multiple photos on one page, PDF export, DOCX export.
- Residual warning:
- The existing CoreData editable-model checksum warning still appears during test-host startup.

- [x] Correct `נוכחים` cover-page alignment regression from side-aligned back to centered
- [x] Verify DOCX/PDF export tests still pass after centered attendee alignment
- [x] Explain where cover-page export layout is controlled for future manual edits

## Review

- Restored the `נוכחים` cover block to centered alignment in both `PdfExporter.drawAttendeesCoverFieldSection` and `DocxTemplateBuilder.attendeesCoverFieldSectionXML`.
- Kept the requested typography from the previous pass: heading is not bold, heading is 10pt, attendee numbered lines are 10pt, and the numbered attendee text behavior remains unchanged.
- Updated the DOCX cover XML test so it now requires center alignment for both the `נוכחים:` heading and the numbered attendee lines, and rejects `w:jc w:val="right"` in that cover details XML.
- Added a lesson to avoid treating RTL direction as a reason to change centered cover sections to side alignment.
- Validation:
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' test CODE_SIGNING_ALLOWED=NO` passed with 63 Swift Testing tests.
- Residual warning:
- The existing CoreData editable-model checksum warning still appears during test-host startup.

- [x] Inspect PDF and DOCX cover-page rendering for `נוכחים` and `הערות`
- [x] Add shared export cover typography constants for attendee and notes sizing/alignment
- [x] Update PDF export cover typography while preserving attendee numbering
- [x] Update DOCX export cover typography with explicit Word font-size and bold controls
- [x] Add focused DOCX assertions for attendee heading/item sizes, no heading bold, notes center alignment, and attendee numbering
- [x] Run export tests/build and record validation results

## Review

- Added `ExportTypography.Cover` constants so PDF point sizes and DOCX half-point sizes are derived from one place: attendees heading 10pt, attendee items 10pt, and notes content 12pt.
- PDF cover export now keeps attendee numbering, renders `נוכחים:` non-bold at 10pt, renders attendee lines at 10pt, keeps attendees RTL/right-aligned, and renders notes as a separate centered content block at 12pt with wrapping through the existing paragraph renderer.
- DOCX cover export now writes explicit `<w:sz>` and `<w:szCs>` sizes for those same values, omits bold tags from the attendees heading/items, keeps the numbered attendee text lines, and keeps notes content centered at 12pt.
- Validation:
- `docxCoverDetailsAvoidsDirectionalIsolatesAndUsesSeparateLabelValueParagraphs` asserts `נוכחים:` is right-aligned, 10pt, and not bold; attendee numbered lines remain present, right-aligned, 10pt, and not bold; notes content is centered and 12pt.
- `docxExporterProducesWellFormedXMLParts` now exports a Hebrew DOCX report with attendees and notes and verifies the generated package contains the numbered attendees and notes text.
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' test CODE_SIGNING_ALLOWED=NO` passed with 63 Swift Testing tests.
- Residual warning:
- The existing CoreData editable-model checksum warning still appears during test-host startup.

- [x] Inspect current project/report persistence and branding/export text paths for the report move + creator text change
- [x] Add a safe report move operation that changes only the parent project relationship and preserves report-owned data
- [x] Add "Move to Project" from the report list and inside the report detail menu, with current/no-other/failure/cancel handling
- [x] Update creator text coverage to "Created by Iter Engineering" wherever present, without changing app identity or user-controlled branding
- [x] Add or update focused tests for report movement and branding fallback text
- [x] Run build/tests and record verification results

## Review

- Added `Report.move(to:)`, which changes only the report's `project` relationship and leaves report fields, photos, annotation paths, export settings, and branding profile untouched.
- Added a `MoveReportToProjectView` picker sheet. It is available from a report row swipe/context menu and from the report detail menu. The current project is disabled and marked, the sheet handles no-other-projects/cancel/current-project no-op cases, and failed saves roll back the relationship before showing an error.
- Project deletion now deletes only image files belonging to reports actually deleted with that project instead of deleting the entire project image directory. This keeps moved reports' existing image paths safe even if their old project is later deleted.
- Added central `AppBranding.createdByText = "Created by Iter Engineering"` and used it for PDF creator metadata and generated DOCX core properties. Existing user/company branding fields remain user-controlled and empty defaults still resolve to unbranded exports.
- Search confirmed the legacy personal creator phrase is absent from app/export sources.
- Validation:
- `plutil -lint InspectorPro/Resources/en.lproj/Localizable.strings InspectorPro/Resources/he.lproj/Localizable.strings` passed.
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' build CODE_SIGNING_ALLOWED=NO` passed.
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' test CODE_SIGNING_ALLOWED=NO` passed with 63 Swift Testing tests.
- Residual warning:
- The existing CoreData editable-model checksum warning still appears during test-host startup.

- [x] Add App Store export-compliance encryption flag to generated Info.plist settings
- [x] Regenerate/sync the Xcode project from `project.yml`
- [x] Verify the built app Info.plist contains `ITSAppUsesNonExemptEncryption = false`

## Review

- Added `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO` to the main app target in `project.yml`. This maps to `ITSAppUsesNonExemptEncryption = false` in the generated app Info.plist.
- Regenerated `InspectorPro.xcodeproj` with `xcodegen generate`, which added `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO;` to both generated build configurations for the app target.
- While syncing the generated project, preserved the app's existing `Inspectley` display name, `1.2.0` marketing version, and utilities category in `project.yml` so future XcodeGen runs do not regress those current build settings.
- Validation:
- `rg -n "ITSAppUsesNonExemptEncryption|INFOPLIST_KEY_ITSAppUsesNonExemptEncryption" project.yml InspectorPro.xcodeproj/project.pbxproj` shows the key in both source-of-truth and generated project files.
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -configuration Debug -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' build` passed.
- `plutil -p .../InspectorPro.app/Info.plist | rg "ITSAppUsesNonExemptEncryption|CFBundleDisplayName|CFBundleShortVersionString|LSApplicationCategoryType"` returned `"ITSAppUsesNonExemptEncryption" => false` and preserved `Inspectley`, `1.2.0`, and `public.app-category.utilities`.

- [x] Locate every PDF/DOCX export path that renders the branding company name
- [x] Remove company-name rendering from export headers while preserving logo/footer branding and stored company data
- [x] Update focused export tests so company names stay internal-only
- [x] Run the export test suite and record verification results

## Review

- Removed company-name rendering from the PDF header path. Stored branding data still resolves normally, and logo/footer rendering still uses the same branding object.
- Removed the DOCX header `companyName` parameter and stopped passing `branding.companyName` from `DocxExporter`, so `word/header1.xml` now contains only the optional logo paragraph.
- Updated focused tests so the DOCX header is expected not to include company-name RTL paragraphs, and the generated no-logo DOCX package asserts the legacy company name is absent from `header1.xml`.
- Validation:
- `rg -n "headerXML\\(|drawHeader\\(|branding\\.companyName|companyName:" InspectorPro/Export InspectorProTests/ExportTests.swift` confirms export header writing no longer references `branding.companyName`.
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' test` passed with 52 Swift Testing tests.
- Residual warning:
- The existing CoreData editable-model checksum warning still appears during test-host startup.

- [x] Audit `docs/superpowers/plans/2026-04-25-branding-local-first.md` against current code
- [x] Complete missing local-first branding export changes for PDF and DOCX headers
- [x] Remove authenticated read-only branding gate and seed cached remote branding only once when local branding is blank
- [x] Add async save confirmation feedback in branding settings
- [x] Add/adjust focused export tests for local-first branding and DOCX header company name
- [x] Run build/tests and record verification results

## Review

- Completed the remaining local-first branding plan gaps: PDF headers now render `branding.companyName`, DOCX headers accept and emit a right-aligned RTL company-name paragraph, and `DocxExporter` passes the resolved local company name into the generated header.
- Authenticated users now load the same editable `BrandingSettingsView` as unauthenticated users. If their local profile is blank, the cached remote branding is copied once as an editable starting point.
- Branding save now runs through an async `performSave()` path, shows green `נשמר!` feedback for roughly 1.5 seconds, then dismisses.
- Added focused tests for DOCX header company-name XML and strengthened the local-profile branding assertion to include `companyName`.
- Validation:
- The default no-destination build still fails before compilation because Xcode selects `My Mac`, whose provisioning profile does not match this iOS-only app.
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -configuration Debug -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' build` passed.
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' test` passed with 53 Swift Testing tests.
- Residual warning:
- The existing CoreData editable-model checksum warning still appears during test-host startup.

- [x] Inspect project/report settings RTL layout entry points
- [x] Fix Hebrew form headers, address rows, date divider, and image-numbering toggle order
- [x] Build and visually verify the project settings and report edit screens on an iPhone portrait simulator
- [x] Record verification results for the RTL layout pass

## Review

- Updated `ProjectFormView` and `ReportFormView` so Hebrew section headers use explicit right-anchored containers instead of default `Section("...")` placement.
- Reworked address rows into an inline `כתובת:` field, backed by a UIKit text field with a fixed right-side label so the label/value read as one row and remain editable in both project settings and report edit.
- Replaced the report date and image-numbering rows with explicit RTL helpers: the date divider spans the full row, and the image-numbering toggle sits on the visual left with the Hebrew label on the right.
- Validation:
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -configuration Debug -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' build` passed.
- `build_run_sim` launched successfully on the booted iPhone 16 portrait simulator (`AA68CADB-2203-4CB3-A38E-1BA44EC9B389`).
- Simulator visual check covered project creation/editing and report creation/editing. Report save and edit save both returned to the expected screens, and the report edit screen showed right-aligned `פרטי דוח` / `נוכחים:`, a complete date divider, inline `כתובת:`, and the toggle on the visual left.

- [x] Implement SwiftData V8 project-folder/report hierarchy
- [x] Migrate each legacy report-like project into one project folder with one report
- [x] Refactor main project list, project detail report list, and report detail photo/export flow
- [x] Update Hebrew report/project/settings labels
- [x] Add per-report address override under the report date, defaulting from the parent project address
- [x] Move the report edit date label to the visual right and date picker value to the visual left
- [x] Build and test the app, then record verification results

## Review

- Added `InspectorProSchemaV8` with project folders, reports, and report-owned photos. The `V7 -> V8` custom migration preserves each legacy report-like project as one folder with one report, keeps the legacy project UUID as the folder ID for existing image paths, and carries branding/photos/report metadata forward.
- Added `InspectorProSchemaV9` for report-level address overrides without mutating the already-defined V8 schema. New reports copy the parent project address into the report, existing reports fall back to the project address and are backfilled on bootstrap when possible, and exports now prefer the report address before falling back to the project address.
- Main project creation now captures only project name/address. Opening a project lists reports; creating/editing a report uses the existing report metadata/photo/export flow under `דוח חדש` / `עריכת דוח`.
- The report edit form now shows an editable `כתובת` field under the date. The date row was adjusted so `תאריך` is on the visual right and the date picker value is on the visual left.
- Exports now operate on `Report` and resolve cover-page address output from the report override first, then the parent project address. Branding bootstrap/backfill now assigns default branding to reports.
- Replaced the branding settings toggle label from `הצג פוטר בדוח` to `הצג כותרת בדוח`. A whole-code search confirms the old exact string no longer appears under `InspectorPro/`.
- Updated export tests for the new `Report` model and current image-quality constants.
- Validation:
- Initial requested build without a destination failed before compilation because Xcode selected `My Mac`, whose provisioning profile is not valid for this iOS target.
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -configuration Debug -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' build` passed.
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' test` passed with 49 Swift Testing tests.
- Simulator smoke check passed: the app built, installed, launched on iPhone 16 simulator, and displayed the Hebrew projects root screen.
- Residual warning:
- The existing CoreData editable-model checksum warning still appears during test startup.

- [x] Confirm the remaining DOCX problem: visually good literal bullets do not align with manually added real Word bullets
- [x] Inspect the latest clipped-bullet DOCX and confirm `w:start="360"` with `w:hanging="360"` places the marker on the table-cell edge
- [x] Increase the logical RTL bullet start indent so the marker has visible room inside the cell
- [x] Verify the generated package/list XML and run the Swift test suite

## Review

- Kept the real editable Word list semantics and logical RTL layout, but changed the list indent to `w:ind w:start="540" w:hanging="360"` so the bullet marker sits inside the table cell instead of being clipped by the right border.
- Temporary Quick Look renders of the supplied DOCX showed `start=480`, `540`, `600`, and `720` all make the marker visible; `540` is the smallest safe-looking value without stealing too much text width.
- Validation: `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' test` passed with 47 Swift Testing tests. The existing CoreData checksum warning still appears during test-host startup.

- [x] Inspect the latest user-supplied DOCX and confirm physical `w:left` indentation still leaves editable bullets on the wrong visual side in Word
- [x] Reintroduce editable DOCX bullets with logical RTL list geometry so Word anchors Hebrew bullets from the paragraph start edge
- [x] Verify the generated package/list XML and run the Swift test suite

## Review

- DOCX bullets are real Word list paragraphs again, but the RTL geometry now uses logical paragraph-start layout with visible marker room: `w:ind w:start="540" w:hanging="360"` with `w:jc w:val="start"` and `w:suff w:val="space"`.
- Removed physical `w:left` and `w:right` indentation from the list shape because Word still rendered those on the wrong visual side for Hebrew RTL editing inside the report table cell.
- Bullet body runs contain only the Hebrew body text; the bullet glyph comes from `word/numbering.xml`, so pressing Enter in Word should continue the same list instead of creating a differently styled manual bullet.
- Validation:
- Rendered a temporary logical-start variant of the supplied DOCX and confirmed the generated XML uses logical RTL indentation instead of physical left/right indentation.
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' test` passed with 47 Swift Testing tests.
- The existing CoreData checksum warning still appears during the test-host launch path and was not changed by this DOCX bullet fix.

- [x] Inspect the user-supplied DOCX package to confirm which bullet/list XML produced the bad Word layout
- [x] Revert only the DOCX real-list/RTL bullet changes from this session while preserving unrelated exporter work
- [x] Verify the reverted DOCX export path with the Swift test suite and document the result

## Review

- The supplied DOCX used the session's real-list path: `InspectorDescriptionBullet`, `w:numPr`, `w:bidi`, `w:start` hanging indent, and `word/numbering.xml` inside the photo description table cell.
- Reverted that DOCX bullet/list implementation for now: no generated `word/numbering.xml`, no numbering relationship/content type, no `InspectorDescriptionBullet` style, and no dedicated list paragraph helper.
- Description bullets are back on the existing shared DOCX paragraph path that writes the formatter output, matching the pre-list behavior while preserving unrelated exporter changes in the dirty worktree.
- Validation:
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' test` passed with 45 Swift Testing tests.
- The existing CoreData checksum warning still appears during the test-host launch path and was not changed by this revert.

- [x] Inspect the current branding schema, settings UI, and export builders for the smallest safe hooks for logo/footer visibility and optional secondary contact
- [x] Add persisted branding visibility defaults that keep existing users on logo ON / footer ON without making branding required for export
- [x] Update the branding settings UI with logo/footer toggles plus collapsible secondary contact fields that auto-expand when data already exists
- [x] Update PDF and DOCX branding rendering to skip hidden or empty logo/footer content without changing report layout or photo rendering
- [x] Verify the change with focused export tests and the full test suite, then record results in the review section

## Review

- Added persisted `BrandingProfile` visibility flags for logo/footer with default `true` behavior preserved for both new profiles and migrated `V6` stores via a custom `V6 -> V7` migration.
- Branding settings now expose `הצג לוגו בדוח` and `הצג פוטר בדוח`, while the secondary contact block is collapsed by default when empty, auto-expands when existing data is present, and can be cleared with `הסר פרטי קשר נוספים`.
- PDF and DOCX exports now skip hidden branding and omit empty footer lines cleanly, including suppressing the secondary footer line when its fields are empty, without changing the report’s existing layout or photo rendering path.
- Validation:
- `xcodebuild -project /Users/aloniter/Projects/InspectorPro/InspectorPro.xcodeproj -scheme InspectorPro -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' build`
- `xcodebuild -project /Users/aloniter/Projects/InspectorPro/InspectorPro.xcodeproj -scheme InspectorPro -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' test` passed with 53 Swift Testing tests.
- Residual warning:
- The existing CoreData checksum warning still appears during test-host startup, but the prior `BrandingProfile.showFooterInReport` migration failure is resolved and the app/test host now loads the store successfully.

- [x] Confirm the repository is already initialized and points at the requested GitHub remote
- [x] Create a savepoint commit for the current project state so it can be restored later
- [x] Push the savepoint to GitHub and verify the remote branch reflects the new snapshot

## Review

- Savepoint commit created at `3aeac97` on branch `codex/attendees-rtl-export`
- Savepoint tag `savepoint-2026-04-17` created and pushed; it resolves to commit `3aeac97`
- Remote `origin` at `https://github.com/aloniter/Inspector_pro.git` now contains both the updated branch head and the savepoint tag

- [x] Inspect the cover-page attendees block in both exporters to confirm why attendee names render to the visual right of the `נוכחים` heading
- [x] Center exported attendee names directly beneath the `נוכחים` heading in both PDF and DOCX without changing unrelated cover metadata
- [x] Verify the updated attendees alignment with focused export tests and record the result

- [x] Inspect the PDF/DOCX report row builders to find where the image-side number and reduced image height were introduced
- [x] Remove the export number from above the image while keeping numbering only in the right-hand description/notes column
- [x] Restore image sizing/cropping so exported photos fill the square image cell again
- [x] Verify the updated numbered-row behavior with focused export tests and record the outcome

- [x] Inspect the current project form, cover-page builders, attendees formatting, and image-row numbering to confirm the exact edit points for this follow-up export pass
- [x] Number attendee names under `נוכחים` in both export formats while keeping the dark-blue 12pt heading and polished RTL spacing
- [x] Strengthen the numbered row presentation so the full opening numbered line is emphasized and the image-side number is more prominent when the per-project toggle is ON
- [x] Change the report cover-page date to numeric `d.M.yyyy` formatting in all relevant export builders without affecting unrelated dates
- [x] Verify the persisted project setting, ON/OFF numbered-image behavior, attendee numbering, and numeric cover-page date with focused tests and simulator build/run

- [x] Inspect the current attendees cover styling and report row builders to identify the minimal edit points for export numbering
- [x] Darken the exported `נוכחים` title styling and reduce its title size from 14pt to 12pt without changing unrelated metadata fields
- [x] Add a persisted per-project toggle in the project settings form for numbered images in exported reports
- [x] Update PDF and DOCX report row generation so the toggle adds matching item numbers on the image side and description side while preserving RTL layout
- [x] Verify storage, migration, and both export paths with focused tests/build validation and record the result

- [x] Reduce exported address and date values to 10pt
- [x] Make exported `נוכחים:` 14pt and left-aligned with the colon after the word
- [x] Align the in-app attendees header to the left while matching the surrounding header style

- [x] Match the in-app attendees header style to the surrounding section headers
- [x] Make exported attendees use a stronger blue accent and flip the colon to the opposite side
- [x] Verify the updated attendees heading format in tests

- [x] Adjust the in-app attendees heading color back to black
- [x] Render exported `נוכחים:` as a blue bold heading with blue non-bold values underneath in PDF and DOCX
- [x] Omit the attendees section entirely from export when no attendees were entered

- [x] Inspect the project form and data model to add a persisted attendees field beneath the date
- [x] Add the new `נוכחים:` project field in the SwiftUI form with dark-blue label styling and localization
- [x] Verify the field persists correctly and document the result

- [x] Inspect DOCX cover-page glyph boxes on Word and confirm the bidi-control root cause
- [x] Rebuild the DOCX cover-page metadata layout so it renders cleanly in Hebrew without visible square glyphs
- [x] Verify the updated DOCX cover page with focused tests and a rendered sample when available

- [x] Inspect cover-page export formatting for Hebrew label/value punctuation on `כתובת` and `הערות`
- [x] Fix cover-page RTL punctuation so `כתובת:` / `הערות:` keep the colon on the visual left in DOCX and PDF exports
- [x] Verify the updated cover-page export formatting with focused tests

- [x] Verify the app launches and is usable on an iPhone simulator with no startup/runtime errors
- [x] Capture simulator logs during app launch and fix any issue surfaced
- [x] Record the verification result and residual risks

- [x] Align XcodeGen bundle identifiers and signing metadata to `com.aloniter.inspectorpro`
- [x] Regenerate the Xcode project and verify Xcode resolves the expected bundle identifier
- [x] Verify provisioning for Shaked's iPhone and confirm a signed device build succeeds

- [x] Inspect current DOCX footer + lock behavior in export flow
- [x] Fix footer contact line format to: Avishay + phone + 'מייל' + email
- [x] Prevent edit-lock issues by cleaning stale Word lock files and forcing writable output
- [x] Fix Word "unreadable content" by preserving valid OpenXML namespaces in templates
- [x] Fix OpenXML schema-order violations in generated DOCX XML (document/header/footer/table/settings)
- [x] Verify by OpenXML SDK validation and test suite

- [x] Fix RTL note editing so Hebrew comments start on the right inside the app
- [x] Fix exported PDF/DOCX bullets so the bullet appears on the right side of Hebrew text
- [x] Verify note editing and export formatting with build/tests and simulator launch

- [x] Move the photo notes heading to the visual right side in Hebrew on the photo detail screen
- [x] Add a clear finish action for photo-note editing that ends editing and saves the current photo changes
- [x] Verify the updated photo-note editing flow with a focused build

- [x] Detect numbered photo-note lines in export formatting
- [x] Render numbered lines as bold headings without bullets or trailing dots in PDF and DOCX
- [x] Verify numbered-note export formatting with focused tests

# Review

- Exported attendee names now stay visually under the `נוכחים` heading in both PDF and DOCX by centering the attendee lines to the same anchor as the heading instead of pushing them to the right edge.
- Validation: `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' test -only-testing:InspectorProTests` passed 28/28 Swift Testing tests after the attendees alignment update.
- The pre-existing CoreData checksum warning still appears in the Xcode test-host path and was not changed by this layout fix.

- Numbered export rows now keep the item number only in the right-hand description/notes side; the image cell no longer renders a separate number above the photo in either PDF or DOCX.
- The photo image target height in both exporters now uses the full square cell area again, restoring the previous center-crop fill behavior instead of shrinking the image to make room for an image-side number.
- Validation: `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' test` passed 28/28 Swift Testing tests after updating the export-row assertions.
- The pre-existing CoreData checksum warning still appears in the Xcode test-host path and was not changed by this fix.

- Follow-up export pass: attendees under `נוכחים` are now emitted as numbered RTL list items in both PDF and DOCX while keeping the dark-blue 12pt heading.
- The per-project `showsNumberedImagesInReport` toggle remains stored on `Project` and now drives a stronger ON state: the image-side number is larger and the full opening numbered description line is emphasized, while OFF still keeps the previous unnumbered export behavior.
- The report cover-page date now uses numeric `d.M.yyyy` formatting through a shared formatter, so the main page renders values like `6.4.2026` instead of month text.
- Validation: `xcodebuild test` passed 28/28 Swift Testing tests on simulator `iPhone 16`, including new coverage for numbered attendees, numeric cover dates, and the stronger numbered-row presentation, and `build_run_sim` launched the app successfully afterward.
- The existing CoreData checksum warning still appears only in the Xcode test-host path and was not introduced by this task.

- Added `showsNumberedImagesInReport` to the project schema, migrated existing V4 projects to V5 with the flag defaulting to `false`, and surfaced the setting as a per-project toggle in the project form.
- Report export now checks `project.showsNumberedImagesInReport` in both the PDF and DOCX exporters; when enabled it injects matching row numbers on the image side and prefixes the first description line with the same number while emphasizing only the number prefix.
- Exported `נוכחים:` cover-page styling now uses a darker blue accent (`#1F4E79`) and a 12pt title in both PDF and DOCX, without changing the other cover metadata fields.
- Validation: `xcodebuild test` on simulator `iPhone 16` passed 26/26 Swift Testing tests, including new coverage for the per-project flag and numbered export rows, and `build_run_sim` launched the app successfully on the same simulator.
- The existing CoreData checksum warning still appears during the Xcode test-host path; this task did not change that pre-existing warning, and the simulator app launch still succeeded afterward.

- Export cover-page address and date values now render at 10pt in the generated report metadata.
- Exported `נוכחים:` now renders at 14pt, left-aligned, with the colon after the word, and the attendees section remains optional.
- The in-app `נוכחים:` header now keeps the shared secondary header color while anchoring to the left side.
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' test` passed with 22 Swift Testing tests after the typography/alignment update.

- The in-app `נוכחים:` header now uses the same secondary styling as the other section headers, so it reads consistently with the rest of the form.
- Exported attendees now use a stronger blue accent (`#1D4ED8`) and the heading text is emitted as `:נוכחים` to place the colon on the opposite side.
- Updated DOCX tests cover both the new blue accent and the flipped attendees heading punctuation.

- The in-app `נוכחים:` heading now renders in black instead of blue.
- Exported `נוכחים:` now uses a dedicated layout: blue bold label with colon, and blue non-bold attendee lines underneath.
- Empty attendees are now omitted entirely from DOCX/PDF cover-page metadata instead of exporting a placeholder or blank section.
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' test` passed with 22 Swift Testing tests for this correction.

- Added a persisted `attendees` field to the project schema and migrated stored projects from schema V3 to V4 without changing photo ordering or existing metadata.
- Project create/edit now shows a dedicated `נוכחים:` section between `תאריך` and `הערות`, with a black section label and multiline text entry.
- PDF and DOCX cover-page metadata now include `נוכחים` between `תאריך` and `הערות` only when attendees were entered.
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' test` passed with 21 Swift Testing tests.
- The existing CoreData checksum warning still appears under the Xcode test-host path; this task did not change that existing warning.

- Normal simulator launch now opens the project list screen successfully with no app-process CoreData checksum errors.
- Root cause fix: the live SwiftData models now belong to `InspectorProSchemaV3`, and the app container uses the versioned schema directly.
- `xcodebuild ... build` on simulator succeeds after the schema refactor.
- `xcodebuild ... test` still prints a CoreData checksum warning when Xcode launches the app as the test host, but the actual standalone app launch on simulator is clean.

- XcodeGen source of truth now uses `com.aloniter.inspectorpro` for the app target.
- Explicit `DEVELOPMENT_TEAM` and automatic signing settings are recorded in `project.yml` so regeneration preserves signing metadata.
- Added an explicit generated scheme for `InspectorPro` so `xcodegen generate` no longer strips the shared scheme.
- Verified resolved build settings show `PRODUCT_BUNDLE_IDENTIFIER = com.aloniter.inspectorpro`, `DEVELOPMENT_TEAM = H29SVV6K2S`, and automatic signing.
- Verified an unsigned generic iOS build succeeds.
- Verified provisioning/profile refresh for device `Shaked Iter` and then a normal signed device build succeeds.

- Footer line is now consistent across code-generated DOCX and both template files:
  - `אבישי 054-6222577 מייל iter@iter.co.il`
- Added stale Word lock cleanup for exported DOCX names (`~$<filename>.docx`) before selecting output path.
- Export now sets writable file permissions (`0644`) after creating the DOCX.
- Rebuilt templates from a known-good source and applied only a safe footer text update to avoid namespace corruption.
- Fixed schema-order issues in generated XML by reordering elements in:
  - `w:rPr`, `w:pPr`, `w:tblPr`, `w:tcPr`, `w:settings`
- Added end-to-end DOCX export test that parses all XML parts in the generated archive.
- Validation:
- OpenXML SDK validator on generated DOCX now reports `Errors: 0`.
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' test` passed (12 tests).

- Notes editors now use a UIKit-backed directional text view so Hebrew input starts from the right in both photo notes and project notes forms.
- PDF and DOCX exports now share one RTL bullet formatter that wraps each generated bullet line in RTL embedding marks, keeping the bullet on the right side of Hebrew text.
- `xcodegen generate` succeeded after adding the shared formatter/editor files.
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' build` succeeded.
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' test` now passes 17 tests, including the new RTL export formatter test.
- Verified a fresh simulator install by uninstalling both `com.aloniter.inspectorpro` and the stale `com.inspectorpro.app`, reinstalling the new build, and launching successfully to the main projects screen.
- Residual note: the existing CoreData checksum warning still appears only under the Xcode test host path during `xcodebuild test`; a normal app launch remains clean.

- Photo detail notes now use semantic leading alignment so the "הערות" heading lands on the visual right side in Hebrew.
- Photo detail note editing now stages text locally and exposes a prominent `סיום ושמירת הערות` button that ends editing and persists the current photo's note.
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -configuration Debug build` initially failed because Xcode selected `My Mac` and hit a provisioning mismatch.
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -configuration Debug -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' build` succeeded.

- Export formatting now detects note lines that begin with a numeric marker like `1. ` and converts them into heading lines.
- Numbered heading lines export without the bullet, without the trailing dot, and with bold styling in both PDF and DOCX output.
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' test` passed with 19 Swift Testing tests, including new numbered-heading export coverage.

- Cover-page `כתובת:` / `תאריך:` / `הערות:` lines now flow through one bidi-aware formatter that isolates the Hebrew label and the field value separately before export.
- DOCX cover-page placeholders now inject preformatted field lines instead of concatenating raw `label: value` text inside the XML template.
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' test` passed with 20 Swift Testing tests, including new cover-page RTL coverage.

- Word cover-page square glyphs were caused by bidi isolate control characters being injected into DOCX text runs on the cover page.
- The DOCX cover page now uses a cleaner layout: stronger title spacing, a divider line, and stacked metadata sections with separate label/value paragraphs instead of inline `label: value` text.
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' test` passed with 21 Swift Testing tests, including DOCX cover-page structure checks that assert no isolate characters are emitted.
- Visual DOCX rendering from the terminal was not available because `soffice` and `pdftoppm` are not installed in this environment.

- [x] Add a minimal `BrandingProfile` schema and lightweight V5 -> V6 migration without changing project behavior or app identity
- [x] Seed/link the default export branding through a best-effort bootstrapper with non-fatal fallback behavior
- [x] Route PDF and DOCX export branding through one shared resolved-branding layer and lock the fallback path with tests

## Review

- Added `InspectorProSchemaV6` with a minimal `BrandingProfile` model and an optional `Project.brandingProfile` relationship; the migration remains lightweight, with seeding/backfill handled outside the migration plan.
- `BrandingBootstrapper` now schedules a best-effort default-profile seed/link pass after startup, but export remains independent of bootstrap success because `ResolvedExportBranding` falls back to the current hardcoded branding values in code.
- PDF and DOCX exporters now pull logo/footer branding from the shared resolver, and focused tests cover both the linked-profile path and the nil-profile fallback path before the end-to-end export assertions run.

- [x] Add a minimal branding editor under the existing settings sheet for the default branding profile only
- [x] Allow manual editing of company name, logo image, footer address line, primary footer line, and secondary footer line without changing export layout geometry
- [x] Keep export header/footer composition fixed while loading custom branding content through the existing resolved-branding layer

## Review

- Added a default-profile branding editor under the existing gear/settings sheet, with a single form for company name, logo selection from the photo library, and the three footer lines.
- Custom logos are stored on disk at a fixed derived path under `Documents/InspectorPro/Branding/<profile-id>.jpg`; the persisted model still only uses the existing `usesBundledDefaultLogo` flag to switch between bundled and custom content.
- PDF and DOCX exporters keep the same fixed logo area, footer area, line count, spacing, and font sizing; only the logo bytes and footer strings now change.
- Validation will rely on `xcodegen generate`, simulator build/test, and a launch pass after the settings/editor wiring lands.

- [x] Replace raw mixed-direction footer-line editing with structured bidi-safe inputs while keeping the same branding/settings screen and export geometry
- [x] Normalize stored footer/address content so mixed Hebrew, English, email, and phone values render stably in PDF and DOCX without redesigning the footer
- [x] Verify the bidi footer fix with focused formatter/export tests plus simulator build/test

## Review

- The branding editor now keeps the same screen flow but replaces raw primary/secondary footer-line editing with structured contact fields, while the address line uses a UIKit-backed directional text field instead of a plain SwiftUI text field.
- Footer storage/export now flows through one shared bidi formatter: numeric/email/LTR tokens are wrapped with explicit LTR marks only when the line contains Hebrew, which stabilizes mixed-direction footer output without changing footer geometry in PDF or DOCX.
- Validation:
- `xcodegen generate`
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' build`
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' test` passed with 35 Swift Testing tests, including the new bidi formatter coverage.
- `xcrun simctl install ... && xcrun simctl launch ... com.aloniter.inspectorpro` succeeded on the iPhone 16 simulator.

- [x] Replace the fragmented footer contact editor with compact grouped primary/secondary contact blocks while keeping the branding screen structure intact
- [x] Update the footer formatter so secondary contacts use fully structured label/number pairs and export lines stay natural in Hebrew without fixed separators
- [x] Re-verify the compact footer pass with build, tests, and simulator launch

## Review

- The footer section now stays on the same branding screen but uses compact grouped rows: primary contact is edited as `name + role` and `phone + email`, while secondary contact is edited as `label/name + number` and `optional label + optional number`.
- The formatter still keeps structured data internally, but now emits natural Hebrew-style lines with a fixed token order and no visual separators: primary uses `name phone role email`, and secondary uses `label1 number1 label2 number2` with the trailing pair omitted cleanly when missing.

- [x] Replace mixed-direction footer-line rendering with stable visual-order runs in PDF and DOCX while keeping the footer geometry unchanged
- [x] Keep the address line in the existing fixed layout but force primary/secondary contact lines to render in the same visual order as the approved Iter example
- [x] Re-verify the export footer pass with build, full tests, and simulator launch

## Review

- Footer export no longer relies on a single mixed RTL/LTR string for the two contact lines. The branding layer now derives semantic runs from structured contact fields, then emits separate visual-order runs for export.
- PDF footer contact lines are now laid out token-by-token with explicit measured positions, centered as one line, so phones and email addresses no longer depend on Core Text bidi reordering.
- DOCX footer contact lines are now emitted as separate OpenXML runs in fixed visual order, centered in the same footer paragraphs as before, which matches the approved `אבישי / דפנה` style without changing logo placement, footer spacing, or paragraph count.
- Validation:
- `xcodebuild -project /Users/aloniter/Projects/InspectorPro/InspectorPro.xcodeproj -scheme InspectorPro -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' build`
- `xcodebuild -project /Users/aloniter/Projects/InspectorPro/InspectorPro.xcodeproj -scheme InspectorPro -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' test` passed with 40 Swift Testing tests.
- `xcrun simctl install AA68CADB-2203-4CB3-A38E-1BA44EC9B389 ...` and `xcrun simctl launch AA68CADB-2203-4CB3-A38E-1BA44EC9B389 com.aloniter.inspectorpro` both succeeded.
- Validation:
- `xcodegen generate`
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' build`
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' test` passed with 36 Swift Testing tests.
- `xcrun simctl install ... && xcrun simctl launch ... com.aloniter.inspectorpro` succeeded on the iPhone 16 simulator.

- [x] Inspect the annotation and export pipeline to confirm what image/annotation data is available at export time
- [x] Add a shared Smart Fit export helper and apply the same fitting policy in PDF and DOCX
- [x] Verify Smart Fit behavior with focused helper tests, DOCX export assertions, and the full export test suite

## Review

- Active export data remains photo-level only: export can tell whether `annotatedImagePath` exists, but annotation bounds are not persisted once the flattened annotated JPEG is saved.
- Added a shared `SmartImageFit` policy that uses zero-crop aspect-fit for annotated photos and only allows tiny capped center-crop for unannotated photos; larger crop requests now fall back to zero-crop aspect-fit.
- Export-specific image padding is now removed so the image uses the full cell content area without changing table structure, row heights, header/footer spacing, or the in-app photo UI.
- PDF and DOCX now both route through the same fit decision, so the same photo gets the same crop-vs-fit outcome in both formats.
- Validation:
- `xcodegen generate`
- `xcodebuild -project /Users/aloniter/Projects/InspectorPro/InspectorPro.xcodeproj -scheme InspectorPro -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' test` passed with 48 Swift Testing tests.
- The existing CoreData checksum warning still appears in the test-host launch path and was not changed by this export fit work.

- [x] Revert only the Smart Fit image fitting change so report images fill the PDF/DOCX image column again
- [x] Remove the Smart Fit helper/tests and restore the previous center-crop fill math in both exporters
- [x] Verify the restored fill behavior compiles and passes the export test suite

## Review

- PDF export now uses the previous center-crop cover draw path again, clipping the image to the full target area inside the image cell.
- DOCX export now emits full target image extents again with center-crop `srcRect` percentages, restoring full-cell fill behavior.
- Export image padding values are back to the previous `4pt` / `80 twips` / `50800 EMU` values.
- Footer, branding, bidi/text formatting, report row/page geometry, and in-app image display were not changed.
- Validation:
- `xcodegen generate`
- `xcodebuild -project /Users/aloniter/Projects/InspectorPro/InspectorPro.xcodeproj -scheme InspectorPro -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' test` passed with 45 Swift Testing tests.
- The existing CoreData checksum warning still appears in the test-host launch path and was not changed by this image-fitting revert.

- [x] Review Inspectley end-to-end for App Store/TestFlight readiness, including auth, export, branding, resources, localization, and metadata
- [x] Fix stability/export/auth/resource issues found during the readiness pass
- [x] Create `APP_STORE_READINESS.md` with current status, fixes, remaining risks, and upload checklist

## Review

- Fixed auth/session handling, logout cache clearing, export permission fallback behavior, missing-image export failures, branding fallback safety, DOCX RTL/logo metadata issues, launch screen/app icon/privacy/config resources, and localized user-facing auth/status text.
- Validation:
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -configuration Debug -sdk iphonesimulator build CODE_SIGNING_ALLOWED=NO` succeeded.
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro test -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' CODE_SIGNING_ALLOWED=NO` passed with 56 Swift Testing tests.
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -configuration Release -sdk iphonesimulator build CODE_SIGNING_ALLOWED=NO` succeeded.
- Simulator unauthenticated launch shows the login screen. The provided test account was rejected as invalid after logout, so real-account export/branding sync remains a manual blocker with a valid review account.
- Built Release simulator app contains `PrivacyInfo.xcprivacy`, localized `InfoPlist.strings`, `SupabaseConfig.plist`, and no bundled Supabase example config; `ITSAppUsesNonExemptEncryption` is false.
- The existing SwiftData/CoreData editable-model checksum warning still appears during test-host startup and should be watched in archive/real-device QA.

- [x] Inspect Supabase auth/session routing for reliance on initial-session behavior
- [x] Update app-owned auth handling to reject expired sessions before routing into the app
- [x] Verify no third-party package files were modified and run focused build/test validation

## Review

- `AuthService` relied on old initial-session behavior by marking `.initialSession` authenticated whenever Supabase emitted any non-nil session.
- Auth routing now uses Supabase's public `Session.isExpired` check before treating `.initialSession`, `.signedIn`, `.tokenRefreshed`, or `.userUpdated` as authenticated.
- Expired or nil sessions clear `isAuthenticated`, `currentUserID`, and `currentUserEmail` while ending the launch loading state; valid sessions still route into the app.
- Logout was already clearing local auth, export permission, and branding state before remote `signOut()`, so no logout change was needed.
- No `.build`, `SourcePackages`, or third-party Supabase files were modified.
- Validation: `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro test -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' CODE_SIGNING_ALLOWED=NO` passed with 58 Swift Testing tests, including the new auth session validity coverage.

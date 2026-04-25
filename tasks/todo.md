# TODO

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

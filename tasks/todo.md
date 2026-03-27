# TODO

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

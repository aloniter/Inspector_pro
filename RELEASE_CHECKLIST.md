# Release Checklist

## Baseline Policy

The current tester build is the stability baseline. Before sending another build, confirm that any new work preserves the shipped behavior unless the release explicitly intends to change it.

## Implemented Baseline Checks

- [ ] Verify the app still launches into the project list and can open project detail and photo detail screens.
- [ ] Verify project create/edit still supports name, address, date, attendees, notes, and numbered-image toggle.
- [ ] Verify photo import still works from photo library and camera when available.
- [ ] Verify annotation still saves an annotated image and the photo reload path uses it correctly.
- [ ] Verify PDF export still uses branded header/footer, A4 layout, and two photo rows per page.
- [ ] Verify DOCX export still builds successfully and includes branded header/footer content.
- [ ] Verify branding v1 still resolves through the shared branding layer for both exporters.
- [ ] Verify manual branding editing still supports logo, footer address, primary footer line, and secondary footer line.
- [ ] Verify bidi/footer handling still preserves stable visual order for mixed Hebrew/LTR contact details in both PDF and DOCX.
- [ ] Run the current export-focused automated suite in [InspectorProTests/ExportTests.swift](/Users/aloniter/Projects/InspectorPro/InspectorProTests/ExportTests.swift).

## Partially Implemented Release Checks

- [ ] Confirm whether the editable company name is expected to appear anywhere user-visible in this release.
- [ ] Confirm whether any branding change is safe to apply globally to all projects linked to the default profile.
- [ ] Decide whether export-cache behavior matters for this release, since the cache infrastructure exists but is not in the active export path.
- [ ] Confirm English-localization quality if the release positions language switching as a supported user-facing feature.

## Pending Before Larger Client-Customization Releases

- [ ] Add per-project or per-client branding profile selection before claiming multi-client branding support.
- [ ] Add safer branding previews or staged changes before broadening access to customization.
- [ ] Add visual regression review for PDF and DOCX output in real viewers, not only formatter/XML tests.
- [ ] Define whether historical projects should keep live branding links or frozen brand snapshots.
- [ ] Expand automated coverage beyond export logic into app workflow and migration scenarios.

## Known Risks To Review Every Release

- [ ] Default-profile branding edits can affect old and new projects at the same time.
- [ ] Export layout and bidi behavior are fragile areas; verify both PDF and DOCX together after any related change.
- [ ] The tester baseline should remain stable; avoid “cleanup” changes to header/footer geometry without explicit product approval.
- [ ] OpenXML namespace/order regressions can reintroduce Word repair or unreadable-content problems.
- [ ] Manual validation is still important because some viewer-specific issues will not be caught by the current test suite alone.

# InspectorPro

InspectorPro is an iPhone-only SwiftUI app for building inspectors to create inspection reports with photos and export them to PDF or DOCX with Hebrew/RTL support.

## Baseline

The current tester build is now the baseline and should be treated as the stable reference point before any new product changes. Documentation in this repository should describe that shipped behavior first, then call out gaps separately.

## Current Product Scope

### Implemented

- SwiftData-backed project management with project name, address, date, attendees, notes, and a per-project numbered-images export toggle.
- Photo import from camera or photo library, including bulk library import up to 500 selected images.
- Per-photo notes, manual photo reordering, deletion, and in-app annotation that saves an annotated JPEG copy.
- PDF export via `UIGraphicsPDFRenderer` and DOCX export via programmatically generated OpenXML zipped with `ZIPFoundation`.
- Hebrew-first export formatting including numbered attendees, numeric cover-page date formatting, RTL notes/bullets, and bidi-safe cover-page fields.
- Branding v1: one default branding profile is bootstrapped automatically, linked to projects, and used by both exporters.
- Manual branding editing in Settings for company name, logo, footer address, primary footer contact line, and secondary footer contact line.
- Bidi/footer handling changes in both exporters: structured footer inputs, normalized mixed RTL/LTR tokens, and fixed visual run ordering in PDF and DOCX footers.
- Localized app language support for Hebrew and English, with Hebrew as the default.

### Partially Implemented

- The data model supports per-project branding relationships, but the UI only exposes editing for the single default branding profile.
- Branding v1 stores an editable company name, but the exported documents currently use only the logo and footer content, not the company name text.
- `ExportCache` exists and is invalidated from annotation changes, but the active export paths still compress images directly instead of reading from the cache.

### Pending

- Multi-client branding management UI, profile duplication, and explicit per-project branding selection.
- Safer branding workflow controls such as previews, staged drafts, or “apply to future projects only” behavior.
- Broader automated verification beyond the current export-focused Swift Testing coverage.

### Known Risks

- Editing the default branding profile changes export branding for every project linked to that default profile, including existing projects.
- The tester build should remain stable; export layout, branding geometry, and RTL behavior should not be changed casually.
- Branding/company-name expectations may drift because the name is editable in settings but not rendered in the exported header/footer.
- Visual regressions in Word/PDF viewers are still more likely to be caught by manual review than by automated tests.

## Tech Stack

- iOS 18.0+
- SwiftUI
- SwiftData
- `ZIPFoundation`
- XcodeGen (`project.yml` is the source of truth)

## Build And Test

```bash
xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -configuration Debug build
xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro test
xcodegen generate
```

Current automated coverage lives in [InspectorProTests/ExportTests.swift](/Users/aloniter/Projects/InspectorPro/InspectorProTests/ExportTests.swift) and contains 40 Swift Testing tests focused mainly on export formatting and document generation.

## Project Docs

- [PROJECT_STATUS.md](/Users/aloniter/Projects/InspectorPro/PROJECT_STATUS.md)
- [ARCHITECTURE.md](/Users/aloniter/Projects/InspectorPro/ARCHITECTURE.md)
- [CLIENT_CUSTOMIZATION_PLAN.md](/Users/aloniter/Projects/InspectorPro/CLIENT_CUSTOMIZATION_PLAN.md)
- [RELEASE_CHECKLIST.md](/Users/aloniter/Projects/InspectorPro/RELEASE_CHECKLIST.md)

# Project Status

Last updated against the implemented codebase on 2026-04-18.

## Baseline

The current tester build is the baseline. New work should preserve its behavior unless a change is intentionally scoped, verified, and documented.

## Implemented

- Core app flow is in place: project list, project create/edit, project detail, photo detail, and export flow.
- SwiftData schema is at `InspectorProSchemaV6` with `Project`, `PhotoRecord`, and `BrandingProfile`.
- Projects support `name`, `address`, `date`, `attendees`, `notes`, `showsNumberedImagesInReport`, and an optional `brandingProfile`.
- Images are stored on disk under `Documents/InspectorPro/Images/` and only relative paths are persisted.
- Annotated photos are saved as separate JPEGs and automatically replace the original in display/export via `PhotoRecord.displayImagePath`.
- Export supports `PDF` and `DOCX`, with `economical`, `balanced`, and `high` image-quality presets.
- PDF export uses a branded header/footer, A4 layout, 2 photo rows per page, a 60/40 image-to-text split, and cover-page metadata.
- DOCX export is built programmatically through `DocxTemplateBuilder` and `OpenXMLBuilder`, then zipped with `ZIPFoundation`.
- Cover-page export includes numeric `d.M.yyyy` date formatting, numbered attendees, bidi-safe `label: value` handling, and omission of empty attendee sections.
- Numbered-image export is implemented as a per-project toggle and affects both PDF and DOCX report rows.
- Branding v1 is implemented:
- One default branding profile is created or reused on startup.
- Existing unlinked projects are backfilled to the default branding profile.
- New projects are linked to the default branding profile on creation.
- Manual branding editing is available in Settings for company name, logo, footer address, primary footer contact line, and secondary footer contact line.
- Footer bidi handling changes are implemented:
- The branding editor uses structured grouped inputs instead of raw mixed-direction footer strings.
- Footer/address content is normalized through `BrandingFooterFormatter`.
- PDF footers draw explicit token runs in fixed visual order.
- DOCX footers emit explicit runs with visual-order enforcement.
- The app supports Hebrew and English localization, with Hebrew and RTL as the default experience.
- Automated export coverage currently includes 40 Swift Testing tests in [InspectorProTests/ExportTests.swift](/Users/aloniter/Projects/InspectorPro/InspectorProTests/ExportTests.swift).

## Partially Implemented

- Branding is only surfaced as a single editable default profile in the UI, even though the model supports multiple branding profiles and per-project relationships.
- The branding editor allows editing the company name, but exported documents currently do not display that company name as text.
- `ExportCache` exists, but the live exporters do not currently use it as part of the compression path.
- Client customization support exists as a foundation, not as a complete workflow.
- Data model support exists.
- Bootstrap/linking exists.
- Manual default-profile editing exists.
- Client-specific profile creation, switching, and project-level selection do not exist yet.

## Pending

- Multi-client branding workflows beyond branding v1.
- Project-level client/profile assignment controls.
- Safer branding change management for exported historical projects.
- Dedicated visual regression checks for PDF and DOCX output.
- Broader non-export tests such as UI coverage, import stress coverage, and migration verification across real upgraded datasets.

## Known Risks

- Editing the default branding profile is a global change for linked projects and can retroactively change the look of old exports.
- The shipped tester build should remain stable; export layout geometry, footer ordering, and bidi handling are sensitive areas.
- The company-name setting can create expectation mismatch because it is editable but not shown in current export output.
- DOCX correctness depends on careful OpenXML ordering and namespace preservation; future edits in this area can easily reintroduce Word repair issues.
- Export validation is strong at the formatter/XML level but still lighter on full viewer-level visual checks.

## Notes For Next Changes

- Treat branding v1, manual branding editing, and the bidi/footer fixes as baseline behavior, not experiments.
- Prefer additive work over reworking the export geometry that testers already received.
- If a change touches export layout or branding, verify both PDF and DOCX paths together.

# Architecture

> Deeper shared agent context (flows, storage/export lifecycle, RTL warnings, verification rules) lives in [docs/AI_CONTEXT.md](/Users/aloniter/Projects/InspectorPro/docs/AI_CONTEXT.md).

## Baseline Constraint

Architecture changes should start from the current tester build as the stable baseline. Documentation below describes what is implemented now, not an aspirational design.

## High-Level Structure

Inspectley currently follows a local-first three-layer structure (the codebase, schema types, and paths below keep the internal `InspectorPro` name):

1. Data layer: SwiftData models plus file-backed image storage.
2. Service layer: filesystem, image persistence, thumbnails, export cache utilities.
3. UI/export layer: SwiftUI screens, PDF export, and DOCX/OpenXML generation.

## Implemented

### Data Layer

- `InspectorProSchemaV9` is the active schema in [InspectorPro/Models/InspectorProMigration.swift](/Users/aloniter/Projects/InspectorPro/InspectorPro/Models/InspectorProMigration.swift) (versioned schemas V1–V9 with a migration plan; only append V10+, never edit existing versions).
- `Project` stores name/address and cascades to `Report`.
- `Report` stores name, optional address (falls back to the project address), date, attendees, notes, `showsNumberedImagesInReport`, and an optional per-report `brandingProfile`; cascades to `PhotoRecord`.
- `PhotoRecord` stores relative image paths, optional annotated-image path, free text, manual order, and timestamps.
- `BrandingProfile` stores branding content:
- `name`
- `isDefault`
- `usesBundledDefaultLogo`
- `showLogoInReport`
- `showFooterInReport`
- `footerAddressLine`
- `primaryFooterLinePDF`
- `primaryFooterLineDOCX`
- `secondaryFooterLine`

### Storage Layer

- [ImageStorageService.swift](/Users/aloniter/Projects/InspectorPro/InspectorPro/Services/ImageStorageService.swift) saves resized original JPEGs and annotated JPEGs under `Documents/InspectorPro/Images/<project-id>/`.
- [FileManagerService.swift](/Users/aloniter/Projects/InspectorPro/InspectorPro/Services/FileManagerService.swift) ensures app directories for images, branding assets, and exports, and purges leftover exports (plus the legacy `ExportCache` directory) at every launch — exports are transient: each file is also deleted after its share sheet completes.
- [ThumbnailService.swift](/Users/aloniter/Projects/InspectorPro/InspectorPro/Services/ThumbnailService.swift) keeps an in-memory (never on-disk) thumbnail cache for photo lists.
- Photo/report/project deletion also deletes the image files; project deletion prunes now-empty per-project image folders.
- Branding logos are stored separately under `Documents/InspectorPro/Branding/`.

### App Flow

- [InspectorProApp.swift](/Users/aloniter/Projects/InspectorPro/InspectorPro/InspectorProApp.swift) initializes SwiftData (V9 + migration plan, in-memory fallback on failure), file directories, launch export purge, and branding bootstrap, then routes Login vs. project list via `AuthService`.
- Auth and gating: [AuthService.swift](/Users/aloniter/Projects/InspectorPro/InspectorPro/Services/AuthService.swift) + `SupabaseManager` handle Supabase sessions; [ExportPermissionService.swift](/Users/aloniter/Projects/InspectorPro/InspectorPro/Services/ExportPermissionService.swift) gates every export server-side (trial/suspension flags) with a 6-hour offline cache.
- [ProjectListView.swift](/Users/aloniter/Projects/InspectorPro/InspectorPro/Views/Projects/ProjectListView.swift) is the root screen for projects and settings.
- [ProjectDetailView.swift](/Users/aloniter/Projects/InspectorPro/InspectorPro/Views/Projects/ProjectDetailView.swift) owns photo import, reorder, delete, and export entry.
- [PhotoDetailView.swift](/Users/aloniter/Projects/InspectorPro/InspectorPro/Views/Photos/PhotoDetailView.swift) manages notes and annotation entry.
- [AnnotationView.swift](/Users/aloniter/Projects/InspectorPro/InspectorPro/Views/Photos/AnnotationView.swift) renders markup onto a saved JPEG composite.

### Export Architecture

- [ExportEngine.swift](/Users/aloniter/Projects/InspectorPro/InspectorPro/Export/ExportEngine.swift) dispatches to PDF or DOCX exporters.
- [ExportOptions.swift](/Users/aloniter/Projects/InspectorPro/InspectorPro/Export/ExportOptions.swift) centralizes A4 geometry, header/footer spacing, and 60/40 table sizing.
- [PdfExporter.swift](/Users/aloniter/Projects/InspectorPro/InspectorPro/Export/PdfExporter.swift) builds the cover page, table pages, header, and footer using Core Graphics/UIKit drawing.
- [DocxExporter.swift](/Users/aloniter/Projects/InspectorPro/InspectorPro/Export/DocxExporter.swift) generates OpenXML parts, writes media/assets, and zips the DOCX package.
- [DocxTemplateBuilder.swift](/Users/aloniter/Projects/InspectorPro/InspectorPro/Export/DocxTemplateBuilder.swift) defines the document shell, styles, header, footer, and cover sections.
- [OpenXMLBuilder.swift](/Users/aloniter/Projects/InspectorPro/InspectorPro/Export/OpenXMLBuilder.swift) builds row/table/footer fragments with RTL-aware WordprocessingML.
- [TemplateExtractor.swift](/Users/aloniter/Projects/InspectorPro/InspectorPro/Export/TemplateExtractor.swift) extracts the bundled default logo from `template.docx`.

### Branding V1 Architecture

- [BrandingBootstrapper.swift](/Users/aloniter/Projects/InspectorPro/InspectorPro/Branding/BrandingBootstrapper.swift) creates or finds the default profile and links unassigned reports to it.
- [DefaultBrandingProfile.swift](/Users/aloniter/Projects/InspectorPro/InspectorPro/Branding/DefaultBrandingProfile.swift) defines the shipped default footer content.
- [ResolvedExportBranding.swift](/Users/aloniter/Projects/InspectorPro/InspectorPro/Branding/ResolvedExportBranding.swift) is the shared export-facing abstraction used by both PDF and DOCX.
- [BrandingSettingsView.swift](/Users/aloniter/Projects/InspectorPro/InspectorPro/Views/Settings/BrandingSettingsView.swift) is the manual branding editor for the default profile.

### RTL And Footer Handling

- [ExportTextFormatter.swift](/Users/aloniter/Projects/InspectorPro/InspectorPro/Utilities/ExportTextFormatter.swift) handles numbered attendees, cover-page labels, bullets, and numbered headings with explicit RTL embeddings/isolation.
- [BrandingFooterFormatter.swift](/Users/aloniter/Projects/InspectorPro/InspectorPro/Branding/BrandingFooterFormatter.swift) tokenizes mixed Hebrew/LTR footer content and builds stable logical and display runs.
- PDF footer rendering uses explicit display runs to avoid relying on bidi resolution of one combined string.
- DOCX footer rendering writes per-run WordprocessingML with visual-order enforcement for mixed-direction lines.

## Partially Implemented

### Branding Model Vs. Branding Workflow

- The model supports multiple branding profiles and per-project linkage.
- The shipped UI only edits one default branding profile.
- There is no profile picker, duplication flow, archival flow, or “client library” UI.

### Branding Content Usage

- Logo and footer lines are used in exports.
- Company name is editable and persisted.
- Company name is not currently rendered in the export output.

### Caching

- The former `ExportCache` was removed; launch-time hygiene still deletes its leftover directory on old installs.
- Export code paths compress image data directly on every export (correct: compression budgets depend on the report's photo count).

## Pending

- Multi-client customization workflows on top of the existing branding foundation.
- Preview/approval controls for branding changes before they affect exports broadly.
- Stronger regression tooling for Word/PDF rendering.
- Cleaner separation between baseline export geometry and future client-specific layout variations.

## Known Risks

- Branding changes are currently global in practice because most projects point to the default profile.
- Export code is sensitive to bidi behavior and OpenXML schema order; small “cleanup” edits can break Word compatibility.
- The current tester build must remain stable, so architecture work should favor additive layers over reworking the current export pipeline.

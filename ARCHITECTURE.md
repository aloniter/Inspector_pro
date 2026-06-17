# Architecture

## Baseline Constraint

Architecture changes should start from the current tester build as the stable baseline. Documentation below describes what is implemented now, not an aspirational design.

## High-Level Structure

Inspectley currently follows a local-first three-layer structure (the codebase, schema types, and paths below keep the internal `InspectorPro` name):

1. Data layer: SwiftData models plus file-backed image storage.
2. Service layer: filesystem, image persistence, thumbnails, export cache utilities.
3. UI/export layer: SwiftUI screens, PDF export, and DOCX/OpenXML generation.

## Implemented

### Data Layer

- `InspectorProSchemaV6` is the active schema in [InspectorPro/Models/InspectorProMigration.swift](/Users/aloniter/Projects/InspectorPro/InspectorPro/Models/InspectorProMigration.swift).
- `Project` stores report metadata plus `showsNumberedImagesInReport` and an optional `brandingProfile`.
- `PhotoRecord` stores relative image paths, optional annotated-image path, free text, manual order, and timestamps.
- `BrandingProfile` stores branding v1 content:
- `name`
- `isDefault`
- `usesBundledDefaultLogo`
- `footerAddressLine`
- `primaryFooterLinePDF`
- `primaryFooterLineDOCX`
- `secondaryFooterLine`

### Storage Layer

- [ImageStorageService.swift](/Users/aloniter/Projects/InspectorPro/InspectorPro/Services/ImageStorageService.swift) saves resized original JPEGs and annotated JPEGs under `Documents/InspectorPro/Images/<project-id>/`.
- [FileManagerService.swift](/Users/aloniter/Projects/InspectorPro/InspectorPro/Services/FileManagerService.swift) ensures app directories for images, branding assets, export cache, and exports.
- [ThumbnailService.swift](/Users/aloniter/Projects/InspectorPro/InspectorPro/Services/ThumbnailService.swift) keeps an in-memory thumbnail cache for photo lists.
- Branding logos are stored separately under `Documents/InspectorPro/Branding/`.

### App Flow

- [InspectorProApp.swift](/Users/aloniter/Projects/InspectorPro/InspectorPro/InspectorProApp.swift) initializes SwiftData, file directories, and branding bootstrap.
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

- [BrandingBootstrapper.swift](/Users/aloniter/Projects/InspectorPro/InspectorPro/Branding/BrandingBootstrapper.swift) creates or finds the default profile and links unassigned projects to it.
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

- `ExportCache` exists as infrastructure.
- The active export code paths still compress image data directly rather than routing through the cache.

## Pending

- Multi-client customization workflows on top of the existing branding foundation.
- Preview/approval controls for branding changes before they affect exports broadly.
- Stronger regression tooling for Word/PDF rendering.
- Cleaner separation between baseline export geometry and future client-specific layout variations.

## Known Risks

- Branding changes are currently global in practice because most projects point to the default profile.
- Export code is sensitive to bidi behavior and OpenXML schema order; small “cleanup” edits can break Word compatibility.
- The current tester build must remain stable, so architecture work should favor additive layers over reworking the current export pipeline.

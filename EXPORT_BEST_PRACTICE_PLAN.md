# Export Best Practice Plan

## Executive Summary

Inspectley's export system should standardize on **architecture B: flatten the final photo + annotations once, then embed that same final image in both PDF and DOCX**.

This is the best fit for Inspectley because the most important release requirement is visual fidelity: when a user draws on a photo, the exported PDF and DOCX must match the editor with 100% annotation alignment. Editable annotation vectors inside Word are less important than preventing crop, zoom, scaling, and coordinate drift.

The current implementation already has the right basic direction: `AnnotationView` saves a flattened annotated JPEG, and export uses `PhotoRecord.displayImagePath` so annotated images win when present. The main weakness is that the report table currently stretches the flattened image to a fixed cell rectangle, which keeps annotations attached to the photo pixels but can distort the visual shape compared with the editor.

Keeping the photo and annotations separate during export is riskier for this app. PDF/Core Graphics and Word/DrawingML have different coordinate systems, crop metadata, layout rules, and image scaling behavior. Separate layers would require two independent renderers to reproduce the editor perfectly, increasing the chance of drift.

## Current Export Architecture

### PDF Flow

The PDF flow is:

`ExportOptionsSheet` -> `ExportEngine` -> `PdfExporter` -> `UIGraphicsPDFRenderer`

Key behavior:

- `ExportOptionsSheet` starts export with `report.sortedPhotos`, currently using `.economical` quality.
- `ExportEngine.exportReport` rejects empty photo lists, then dispatches `.pdf` to `PdfExporter.export`.
- `PdfExporter.export` resolves branding, loads/compresses all photo images, creates an A4 `UIGraphicsPDFRenderer`, draws a cover page, then draws a table of photo rows.
- Each content page gets header/footer branding.
- The table header is redrawn after PDF page breaks.
- Row height is image-driven at a 260pt target image height unless description text needs more height.

Current PDF risks:

- It preloads compressed `UIImage` instances for all photos before rendering, which is not ideal for very large reports.
- Very long notes can produce a row taller than the usable page body because rows are not split.
- Image drawing uses full-cell placement, so aspect ratio is not preserved.

### DOCX Flow

The DOCX flow is:

`ExportOptionsSheet` -> `ExportEngine` -> `DocxExporter` -> generated OpenXML parts -> ZIPFoundation

Key behavior:

- `ExportEngine.exportReport` dispatches `.docx` to `DocxExporter.export`.
- `DocxExporter` creates a temporary DOCX package tree.
- It writes generated XML parts for document, relationships, styles, numbering, settings, header, footer, properties, and media.
- It compresses each photo into `word/media/image*.jpg`.
- It builds report rows through `OpenXMLBuilder.buildPhotoRow`.
- It zips the temp package with ZIPFoundation into the exports directory.

Current DOCX table behavior:

- A4 page size.
- Top margin/header reserve: 92pt.
- Bottom margin/footer reserve: 72pt.
- Table split: 60% image / 40% text.
- Image target height: 260pt.
- Table uses fixed grid columns.
- Header row uses `<w:tblHeader/>`.
- Photo rows use `<w:cantSplit/>`.
- There are no explicit page breaks after every two findings; Word controls table pagination naturally.

Current DOCX risks:

- "Two photos per page" is a sizing target, not a hard guarantee.
- The table currently lacks table-level `<w:bidiVisual/>`, despite the project RTL guidance.
- The embedded image is stretched to the target DOCX extent.
- OpenXML tests parse XML and assert string markers, but do not prove Microsoft Word visual rendering or schema validity.

### Annotation Rendering Flow

The annotation flow is:

`PhotoDetailView` -> `AnnotationView` -> `ImageStorageService.saveAnnotatedImage` -> `PhotoRecord.annotatedImagePath`

Key behavior:

- `PhotoDetailView` loads the original image and optional annotated image.
- `AnnotationView` displays the active image with aspect-fit layout.
- User drawing points are normalized into the visible aspect-fit `imageFrame`.
- On save, `AnnotationView.renderComposite()` draws the base image into the full pixel image rect, denormalizes annotation points into that same full image rect, and saves one flattened annotated JPEG.
- `ImageStorageService.saveAnnotatedImage` writes `ann_<originalUUID>.jpg` at JPEG quality `0.92`.
- `PhotoRecord.displayImagePath` returns `annotatedImagePath` if it exists, otherwise the original image path.

This means export does not currently map annotation vectors into PDF or DOCX. It exports one baked image. That is good for alignment, as long as later export placement does not crop, zoom, or distort the image unexpectedly.

### Image Fitting And Scaling

Current fitting/scaling behavior:

- Imported images are resized to `AppConstants.importMaxWidth` of 2000px and saved as JPEG.
- Annotated images are saved as flattened JPEGs.
- Export compression uses `ImageCompressor.compressData`, which decodes the image, resizes by max width, then iteratively lowers JPEG quality and width to approach the target byte budget.
- `ExportOptions.exportImageMaxRenderWidth` adapts render width by quality preset and photo count.
- `ExportOptions.exportImageMaxBytes` adapts the per-image byte budget from the target total export size.
- Current report image placement uses `ExportImageFitter.placementRect(..., mode: .fillCellNoCrop)`.
- `.fillCellNoCrop` returns the full cell bounds, not an aspect-fit rect.

Practical result: annotation-to-photo alignment inside the flattened JPEG is preserved, but the exported image can be visually stretched compared with the editor because the original aspect ratio is not preserved.

### Branding, Header, And Footer

Current branding behavior:

- `ResolvedExportBranding.resolve(for:)` is the central export branding resolver.
- A linked local `BrandingProfile` is the source of truth.
- No local profile resolves to empty branding.
- PDF draws a logo in the header and footer lines when visible.
- DOCX writes logo header XML and footer XML with structured runs.
- Mixed Hebrew/LTR footer content is handled with `BrandingFooterFormatter` run sequences to reduce bidi instability.

Branding is already mostly centralized and should be preserved carefully. Future export image changes should not redesign branding geometry unless explicitly requested.

### Error Handling

Current error handling:

- `ExportError.noPhotos` blocks empty export through `ExportEngine`.
- Missing or undecodable images become `ExportError.imageLoadFailed`.
- Unknown PDF failures collapse to `ExportError.pdfGenerationFailed`.
- Unknown DOCX failures collapse to `ExportError.docxGenerationFailed`.
- User-facing messages are intentionally generic and localized.

This is reasonable for users, but support diagnostics are thin. Future implementation should add internal debug logging around missing files, decode failure, compression failure, XML/package write failure, and zip failure without exposing noisy details to users.

## Problems And Risks

### High

- **Current full-cell placement can distort photos and annotations visually.** Because the flattened JPEG is stretched into the image cell, annotations stay attached to their photo pixels but may not match the editor's aspect-fit visual proportions.
- **Annotation vectors are not persisted.** Once an annotated image is saved, the app keeps only the flattened JPEG path. Future vector re-rendering or re-editing from original strokes would require a model/storage change.

### Medium

- **DOCX does not truly enforce two photos per page.** `photosPerPage` informs sizing expectations, but Word handles table pagination based on row height, text length, margins, and `cantSplit`.
- **PDF export preloads all compressed images.** This weakens the large-report memory story for 100-500 photo reports.
- **Very long notes can overflow a PDF row/page.** The PDF path checks page fit before drawing a row, but does not split a row that is itself taller than the page body.
- **Compression byte caps are best-effort.** `ImageCompressor` can still return data above `maxBytes` after reaching minimum width or quality.
- **OpenXML tests are not full Word QA.** Current tests verify well-formed XML and expected tokens, but not OpenXML schema validity or visual rendering in Microsoft Word.
- **Very tall or unusual images can remain memory-heavy.** Resizing is width-based, so narrow/tall images may keep a large pixel height.

### Low

- **Unused or overlapping fitting helpers obscure intent.** The code contains old helper shapes and current `ExportImageFitter` behavior, making it easier to misunderstand the intended export policy.

## Best-Practice Recommendation

### Choose Flattened Final Export Images

Recommended architecture:

1. Determine the canonical source image for each finding.
2. Produce one final flattened export image for that finding.
3. Use the same final image bytes, dimensions, and metadata for both PDF and DOCX.
4. Place that image with the same aspect-ratio-preserving policy in both formats.
5. Avoid DOCX crop metadata for annotated images.

This architecture gives Inspectley a single visual truth: if the flattened image is correct, PDF and DOCX only need to place it predictably.

### Compare The Three Architectures

| Architecture | Strengths | Weaknesses | Fit For Inspectley |
| --- | --- | --- | --- |
| A. Current implementation | Already exports annotated JPEGs; simple; no separate annotation renderer in export | Full-cell stretch can distort aspect ratio; pagination and QA gaps remain | Good foundation, but not release-grade for visual fidelity |
| B. Flatten final photo + annotations once, then embed the same image | Best annotation alignment; same bytes in PDF/DOCX; avoids Word/PDF layer differences; easiest to QA | Annotations are not editable as separate Word objects; must manage image resolution/file size carefully | **Recommended** |
| C. Keep photo and annotations separate in export | Could preserve vector editability or higher-resolution base photos | Highest drift risk; duplicate coordinate/rendering logic for PDF and DOCX; Word crop/anchor/extent behavior is fragile | Not recommended for v1/App Store release |

### Single Source Of Truth

Future implementation should introduce one shared export image pipeline with one source of truth for:

- editor/export image coordinate mapping,
- aspect-fit rectangle math,
- normalized annotation coordinate mapping,
- final flattened export image dimensions,
- PDF image placement,
- DOCX image placement,
- compression target selection.

Likely new files:

- `InspectorPro/Export/ExportImageGeometry.swift`
- `InspectorPro/Export/FlattenedExportImageRenderer.swift`

### Placement Policy

The recommended report image placement is:

- preserve aspect ratio,
- never crop annotated images,
- never use DOCX `srcRect` crop metadata for annotated images,
- center the image inside the image cell,
- allow letterboxing/empty space only when required to preserve visual truth,
- use identical geometry math for PDF and DOCX.

This means the exported image should match the editor's visual proportions. A professional report should not make circles into ovals or arrows look visually stretched.

### 60/40 Versus 65/35

Keep **60/40** as the default report table split.

Reasons:

- Inspection reports need readable descriptions, often in Hebrew and often with multi-line notes.
- 60/40 already gives the image approximately 4.18in x 3.61in of drawable area in the current A4 table geometry before accounting for all renderer differences.
- Moving to 65/35 gives photos slightly more space but makes notes more cramped, increasing row height and pagination risk.
- 65/35 can remain a future optional style for photo-heavy reports with consistently short notes.

### Recommended Image Resolution

Recommended embedded image targets:

- Default/email: about `900-1100px` wide for the table image area.
- High quality: about `1200-1400px` wide.
- Avoid dropping below about `800px` for annotated findings unless the report is very large.

The current adaptive render width is directionally correct, but should be tied to final display size and annotation readability, not only source width and total photo count.

### Recommended JPEG Quality

Recommended JPEG quality:

- Default/email: `0.70-0.75`.
- High: `0.82-0.85`.
- Adaptive lower bound should protect red/yellow annotation strokes from becoming blurry or blocky.

Annotated images should bias slightly toward clarity because arrows, circles, and freehand marks are report-critical content, not decorative pixels.

### Expected File Size Targets

Expected targets:

- Normal report: under `10MB` when practical.
- Large report: adaptive mode around `100-180KB` per finding image.
- Very large reports should remain shareable by email or WhatsApp where possible, but not at the cost of unreadable annotations.

## Proposed Implementation Plan

### Phase 1: Documentation-Only Audit

Status for this step:

- Add only this plan file.
- Do not change app code, tests, project files, App Store files, Fastlane, screenshots, login, Supabase, or task docs.

### Phase 2: Shared Export Geometry

Introduce shared geometry utilities for:

- aspect-fit size,
- centered aspect-fit rect,
- normalized point to image-pixel mapping,
- image-pixel to export-rect mapping,
- PDF point dimensions,
- DOCX EMU dimensions.

Acceptance for this phase:

- PDF and DOCX call the same geometry policy.
- Existing fitting behavior is covered before changing behavior.
- Tests cover landscape, portrait, square, and invalid sizes.

### Phase 3: Final Flattened Export Image Pipeline

Add a dedicated flattened export image renderer/selector:

- If an annotated image exists, use it as the canonical visual source.
- If only the original exists, use the original as the canonical visual source.
- Normalize orientation and scale.
- Produce deterministic JPEG data for export.
- Return both data and pixel dimensions.

Acceptance for this phase:

- PDF and DOCX receive the same final image bytes or the same deterministic render output.
- Annotated images are not separately redrawn by each exporter.
- Missing image behavior remains a controlled export failure.

### Phase 4: PDF And DOCX Placement

Update PDF and DOCX placement to:

- preserve aspect ratio,
- center the image in the image cell,
- remove crop metadata for annotated images,
- use a shared image placement decision.

Acceptance for this phase:

- Circles remain circles.
- Arrows and freehand strokes stay on their landmarks.
- PDF and DOCX use equivalent visual placement.

### Phase 5: Pagination And Long Notes

Improve report layout behavior:

- Keep the 60/40 default split.
- Preserve header/footer reserved space.
- Make PDF long-note behavior explicit: split text, move row, or cap/continue in a documented way.
- Decide whether DOCX should rely on Word pagination or inject explicit page breaks for predictable two-finding pages.

Acceptance for this phase:

- Long notes do not draw into the footer.
- Many-photo reports remain stable.
- DOCX remains editable and opens without Word repair warnings.

### Phase 6: QA And Release Verification

Perform manual and automated QA:

- Generate golden sample PDF and DOCX.
- Visually compare editor, PDF, and Word output.
- Validate DOCX XML and, when available, run OpenXML schema validation.
- Check output size for normal and large reports.
- Run the full Swift Testing suite.

## Exact Files Involved

### Current Files To Audit Or Carefully Modify Later

- `InspectorPro/Views/Export/ExportOptionsSheet.swift`
- `InspectorPro/Export/ExportEngine.swift`
- `InspectorPro/Export/PdfExporter.swift`
- `InspectorPro/Export/DocxExporter.swift`
- `InspectorPro/Export/ExportOptions.swift`
- `InspectorPro/Export/OpenXMLBuilder.swift`
- `InspectorPro/Export/DocxTemplateBuilder.swift`
- `InspectorPro/Export/ImageCompressor.swift`
- `InspectorPro/Views/Photos/AnnotationView.swift`
- `InspectorPro/Services/ImageStorageService.swift`
- `InspectorPro/Models/PhotoRecord.swift`
- `InspectorPro/Branding/ResolvedExportBranding.swift`
- `InspectorProTests/ExportTests.swift`

### Future Likely New Files

- `InspectorPro/Export/ExportImageGeometry.swift`
- `InspectorPro/Export/FlattenedExportImageRenderer.swift`

### Files And Areas Not To Change In This Export Architecture Work

- App Store submission files.
- Fastlane files, if added later.
- Screenshot generation assets.
- Login/auth UI.
- Supabase services and configuration.
- Unrelated SwiftData schema/migration files unless a future annotation-vector persistence decision explicitly requires it.
- Branding settings UI unless report branding requirements change.

## Golden Sample QA Plan

Create a repeatable golden sample report set with:

- Portrait image.
- Landscape image.
- Square image.
- Annotation near top-left.
- Annotation near bottom-right.
- Arrow over a clear landmark.
- Circle around a clear landmark.
- Freehand line over a clear landmark.
- Text-like/freehand label over a clear landmark.
- Long Hebrew notes.
- Many findings: 20, 50, 100, and 300+ images.
- Missing original image.
- Stale annotated image path with valid original fallback.
- Valid annotated path.
- With logo/footer branding.
- Without branding/logo.

Manual QA steps:

1. Open each source photo in the editor and capture/reference the visual placement.
2. Export PDF.
3. Export DOCX.
4. Open PDF in Apple Preview.
5. Open DOCX in Microsoft Word.
6. Verify annotations sit on the same landmarks in all outputs.
7. Verify no crop, zoom, aspect distortion, or unexpected stretching.
8. Verify long notes are readable and do not collide with header/footer.
9. Verify file sizes are reasonable for sharing.
10. Verify branded and unbranded exports both look intentional.

Golden sample acceptance:

- No annotation drift.
- No circles becoming ovals.
- No arrows pointing away from the intended landmark.
- No image crop for annotated findings.
- No Word repair dialog.
- No footer overlap.
- Output remains readable on phone and desktop.

## Test Plan

### Automated Tests To Add

- Unit tests for aspect-fit math:
  - landscape in fixed cell,
  - portrait in fixed cell,
  - square in fixed cell,
  - zero/invalid sizes.
- Unit tests for normalized coordinate mapping:
  - top-left,
  - center,
  - bottom-right,
  - out-of-bounds clamping.
- Tests for flattened export image dimensions:
  - deterministic output size,
  - orientation normalization,
  - annotated and unannotated source paths.
- Tests for PDF/DOCX consistency:
  - same source image path/data selected,
  - same aspect-fit placement policy,
  - same displayed dimensions converted between points and EMUs.
- Tests that annotated DOCX images never emit `<a:srcRect>`.
- Tests for compression/file-size behavior:
  - flat-color image,
  - noisy/high-detail image,
  - annotated high-contrast strokes,
  - large photo set adaptive budgets.
- Pagination edge tests:
  - empty description,
  - short description,
  - very long Hebrew description,
  - enough rows to cross pages,
  - missing image failure.
- DOCX package tests:
  - XML well-formedness,
  - expected relationships,
  - expected image media count,
  - planned OpenXML schema validation when tooling is available.

### Existing Tests To Preserve

Preserve current coverage around:

- image quality presets,
- `PhotoRecord.displayImagePath`,
- XML escaping and invalid XML character stripping,
- DOCX table structure,
- RTL paragraphs/bullets,
- header/footer branding,
- stale Word lock file cleanup,
- export errors,
- no-logo behavior.

## Acceptance Criteria

For this documentation phase:

- Branch is `export-best-practice-plan`.
- `EXPORT_BEST_PRACTICE_PLAN.md` is added.
- No app source files are changed by this phase.
- No test files are changed by this phase.
- No project files are changed by this phase.
- No App Store, Fastlane, screenshots, login, Supabase, or task docs are changed by this phase.

For the recommended future implementation:

- The file clearly compares:
  - current architecture,
  - flattened final image architecture,
  - separate photo/annotation architecture.
- The recommendation is explicit:
  - flatten once,
  - embed the same final image in PDF and DOCX,
  - preserve aspect ratio,
  - avoid annotation-vector export for v1 release.
- PDF and DOCX match the editor visually for annotated findings.
- Annotation alignment is correct at image corners and center.
- Portrait, landscape, and square images all export without crop/zoom mismatch.
- Long notes remain readable and do not overlap footer content.
- Large reports remain stable and reasonably sized.
- DOCX opens in Microsoft Word without repair dialogs.
- Golden sample PDF and DOCX pass manual visual QA.

## Recommended Next Implementation Prompt

Implement the export best-practice architecture from `EXPORT_BEST_PRACTICE_PLAN.md`.

Scope:

- Work only on the PDF/DOCX export and annotation-to-export image pipeline.
- Do not touch App Store, Fastlane, screenshots, login, Supabase, or unrelated app areas.
- Add a shared export geometry source of truth.
- Add a flattened final export image renderer/selector.
- Route PDF and DOCX through the same final image bytes or deterministic final render.
- Preserve aspect ratio in export placement.
- Do not use DOCX crop metadata for annotated findings.
- Keep 60/40 as the default table ratio unless tests or golden samples prove otherwise.
- Add focused tests for image fitting math, coordinate mapping, flattened image dimensions, PDF/DOCX consistency, compression behavior, and pagination edge cases.
- Verify with the golden sample QA set and the full Swift Testing suite.

## References

- Apple `UIGraphicsPDFRenderer`: [developer.apple.com/documentation/uikit/uigraphicspdfrenderer](https://developer.apple.com/documentation/uikit/uigraphicspdfrenderer)
- Apple `UIGraphicsImageRenderer`: [developer.apple.com/documentation/uikit/uigraphicsimagerenderer](https://developer.apple.com/documentation/uikit/uigraphicsimagerenderer)
- Microsoft WordprocessingML tables: [learn.microsoft.com/en-us/office/open-xml/word/working-with-wordprocessingml-tables](https://learn.microsoft.com/en-us/office/open-xml/word/working-with-wordprocessingml-tables)
- Microsoft DrawingML `srcRect`: [learn.microsoft.com/mt-mt/dotnet/api/documentformat.openxml.drawing.sourcerectangle](https://learn.microsoft.com/mt-mt/dotnet/api/documentformat.openxml.drawing.sourcerectangle?view=openxml-3.0.1)
- Microsoft DrawingML `fillRect`: [learn.microsoft.com/en-us/dotnet/api/documentformat.openxml.drawing.fillrectangle](https://learn.microsoft.com/en-us/dotnet/api/documentformat.openxml.drawing.fillrectangle?view=openxml-3.0.1)

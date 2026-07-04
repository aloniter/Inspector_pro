# AI Context — Inspectley / InspectorPro

Shared deep context for AI coding agents (Claude, Codex, or any other).
Read this before changing anything. Entry-point rules live in `CLAUDE.md`
(Claude) and `AGENTS.md` (Codex/general); this file is the substance both
point to. Hard-won RTL/export failure knowledge lives in `tasks/lessons.md`
— read it before touching export or RTL code.

## What the app is

**Inspectley** (App Store name) is a production iOS 18+ SwiftUI/SwiftData app
for Hebrew-speaking building inspectors. Flow: Project → Reports → Photos
(with drawn annotations) → export a professional A4 report as **PDF or DOCX**,
shared via the iOS share sheet, usually by email. Hebrew/RTL is the default
language and the reason the export code looks the way it does.

- Internal Xcode project, target, scheme, module, and folders are
  **InspectorPro** (bundle id `com.aloniter.inspectorpro`). Never rename
  internals; use "Inspectley" only for user-facing/product references.
- iPhone only, portrait only. Dependencies: ZIPFoundation and supabase-swift
  (SPM). `project.yml` is the source of truth; regenerate with
  `xcodegen generate`.

## Production status

Current repo version is 1.0.2 build 3 in project.yml. App Store Connect
confirmed: iOS App Version 1.0.2 is Ready for Distribution (2026-07-04).
This is a **live production app** — regressions reach paying B2B users.
Login and export are gated through Supabase (`AuthService`,
`ExportPermissionService`: trial/suspension flags, 6-hour offline cache).

## Main user flows

1. **Login** (`LoginView` + `AuthService`/`SupabaseManager`) → project list.
2. **Create** project (`ProjectFormView`) → report (`ReportFormView`, same
   file) with name/address/date/attendees/notes.
3. **Photos** (`ProjectDetailView`): camera or gallery import (batched, DB
   save checkpoint every 20 photos), reorder, per-photo free text
   (`PhotoDetailView`), drawn annotations (`AnnotationView` renders a
   flattened JPEG composite).
4. **Export** (`ExportOptionsSheet`): permission gate → `ExportEngine` →
   `PdfExporter` or `DocxExporter` → share sheet → exported file deleted
   after sharing.

## Architecture

- **Data**: versioned SwiftData schemas V1→V9 in
  `InspectorPro/Models/InspectorProMigration.swift`. **V9 is active**
  (typealiased in `Project.swift` / `PhotoRecord.swift`). Relationships:
  Project —cascade→ Report —cascade→ PhotoRecord; BrandingProfile —nullify→
  Report. Only append V10+; never edit existing schema versions.
- **Files on disk** (SwiftData stores only relative paths), all under
  `Documents/InspectorPro/` (see `Utilities/Constants.swift`):
  - Originals: `Images/<projectID>/<uuid>.jpg` — resized to ≤2000px wide,
    JPEG 0.85, EXIF stripped (`ImageStorageService`).
  - Annotated composites: `Images/<projectID>/ann_<uuid>.jpg` — capped like
    imports; overwritten in place on re-save; deleted when markup is cleared.
  - Branding logos: `Branding/<profileID>.jpg`.
  - Exports: `Exports/` — **transient by design**: deleted in the share
    sheet's completion handler and purged at every launch
    (`FileManagerService.purgeExports()`).
  - Thumbnails are memory-only (`ThumbnailService`, 300-entry cache).
- **Deletion cleanup**: project/report/photo deletion also deletes the image
  files (`deletePhotoFiles`); project deletion prunes empty image folders.
  `PhotoRecord.displayImagePath` prefers the annotated file when it exists.
- **Branding**: local-first. `BrandingBootstrapper` links reports without a
  profile to the default profile. `ResolvedExportBranding` is the single
  export-facing abstraction used by both PDF and DOCX. The bundled default
  logo is extracted from `Resources/template.docx` (`TemplateExtractor`) —
  that is template.docx's **only** role; the DOCX file itself is generated
  fully programmatically.

## Export system

```
ExportOptionsSheet (permission gate, quality hardcoded .economical)
  → ExportEngine
      → PdfExporter   (UIGraphicsPDFRenderer drawing)
      → DocxExporter  (programmatic OpenXML via DocxTemplateBuilder/
                       OpenXMLBuilder → ZIPFoundation zip)
Shared by both: ExportOptions (ALL A4 geometry: margins, 60/40 columns,
twips/EMU conversion), ImageQuality (byte/width budgets, adaptive per photo
count), FlattenedExportImageRenderer + ImageCompressor (source selection and
compression — guarantees PDF and DOCX embed identical image bytes),
ExportTextFormatter, AttendeeCoverLayout, ResolvedExportBranding.
```

- Layout: A4, 2 photos/page, 60% image / 40% text columns, header ~92pt
  (logo), footer ~72pt (branding lines), cover page with title, address,
  date, red open-defects line, attendees block, notes.
- File naming: `<reportName>_<yyyy-MM-dd>[_n].{pdf,docx}` in `Exports/`.
- DOCX builds in a system-temp dir cleaned by `defer`; stale Word `~$` lock
  files are removed; share sheet hands raw `Data` to Microsoft/Word targets
  so the file opens editable.
- Size budgets (`ImageQuality` + `ExportOptions.exportImageMaxBytes`):
  economical targets ≤9MB total, ≤100KB/image, adaptive floor 55KB/image and
  render width down to ~500px for 300+ photos.

## Hebrew / RTL warnings

The attendee/cover RTL layout was rebuilt several times; the current design
is deliberate and fragile-looking on purpose:

- DOCX attendees: fixed borderless table columns with **literal** "N." marker
  text and an explicit `<w:bidiVisual/>` — NOT Word auto-numbering
  (`w:numPr`), which rendered inconsistently in real Word.
- PDF attendees: marker and name drawn in separately positioned fixed
  columns; plain Western digits must NOT get an RTL base writing direction
  (bidi-ambiguous, renders inconsistently row-to-row).
- General OpenXML RTL: `<w:bidiVisual/>` on tables, `<w:bidi/>` on
  paragraphs, `<w:rtl/>` on runs, `<w:rFonts w:cs="Arial"/>` for Hebrew.
- Every failed approach and why it failed is documented in
  `tasks/lessons.md`. Do not "simplify" back to auto-numbering, single-string
  markers, or implicit column order.

In-app UI (not export) RTL rules:

- The app is Hebrew-first; never solve an RTL issue with a global LTR
  override. Apply local `layoutDirection` fixes only to the specific value.
- Settings-style rows: section headers and row labels align right; values/
  toggles/actions usually sit on the left. Use explicit row components
  instead of relying blindly on SwiftUI leading/trailing.
- Form fields: alignment depends on purpose — project/report name and
  address inputs are intentionally right-aligned; do not force all fields to
  one side.
- Mixed content (emails, versions, dates, identifiers) must remain readable,
  not reversed.

## Do not casually change

- Anything in `InspectorPro/Export/` that affects layout: `ExportOptions`
  numbers, `DocxTemplateBuilder`, `OpenXMLBuilder`, `AttendeeCoverLayout`,
  drawing code in `PdfExporter`. The report's visual design is frozen unless
  the owner explicitly approves a change.
- `UIImage.resized(maxWidth:)`'s `format.scale = 1` — removing it silently
  triples stored pixels (was a real production bug; see lessons).
- Schema history V1–V9 in `InspectorProMigration.swift`.
- The transient-exports lifecycle (delete-after-share + launch purge).
- Internal naming (`InspectorPro`, bundle id).
- Localization: Hebrew is default; add strings to BOTH
  `he.lproj/Localizable.strings` and `en.lproj/Localizable.strings`; retrieve
  via `AppStrings.text()`.

## Build & test rules

```bash
xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -configuration Debug build
xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro test   # Swift Testing, #expect()
xcodegen generate   # after editing project.yml
```

- Tests: `InspectorProTests/ExportTests.swift` (86 tests as of 2026-07).
- **Use a fresh `-derivedDataPath`** (e.g. a scratch dir) for simulator test
  runs: the default location can silently install a stale app binary while
  reporting BUILD/TEST SUCCEEDED (documented in `tasks/lessons.md`).
- **Never run two xcodebuild invocations concurrently** on this project —
  racing DerivedData can leave an unsigned app product that breaks the
  simulator until DerivedData is deleted.
- `TEST_RUNNER_X=1`-style variables must be shell environment variables, not
  xcodebuild arguments.

## Verification rules for export/RTL work

- XML string assertions are NOT enough: numbering/indentation bugs have only
  been visible in rendered output. Render generated DOCX via LibreOffice
  headless (`soffice --convert-to pdf`) + `pdftoppm`, and pixel-measure
  (crop + dark-pixel clusters), don't eyeball.
- LibreOffice is faithful for numbering/marker/indentation bugs but NOT for
  table centering (`w:jc="center"`) — real Microsoft Word is authoritative
  there.
- Test attendees with 12+ names including one-character and very long names.
- Any UI change must be checked in Hebrew on simulator/device, including both
  placeholder and entered-text alignment.

## Known open issues (audited 2026-07-04; do not re-discover)

- `PdfExporter` accumulates all export images (Data + UIImage) in an array
  before rendering — memory-pressure risk for 150+ photo reports. A fix must
  not change drawn output. (DOCX streams per photo and is fine.)
- `UIImage.thumbnail(maxSize:)` renders at screen scale (3×); this is fine
  for display thumbnails but means `BrandingAssetStorage.saveCustomLogo`
  stores logos above the intended 1200px cap.
- Photos imported before the pixel-inflation fix (commit `e560ffb`) remain
  oversized on existing user devices; any re-compression migration needs
  explicit owner approval.
- Export requires a network-verified permission (6h cache): offline users
  with a stale cache cannot export. Business decision, not a bug.
- Reference material from the storage audit (StorageDiagnosticsService tool,
  compression research docs) is preserved on the
  `archive/storage-diagnostics-preservation` branch — reference only, never
  merge it.

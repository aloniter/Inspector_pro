# AGENTS.md

Guidance for Codex and other general coding agents working in this
repository. Aligned with `CLAUDE.md` (Claude-specific entry point); the deep
shared context both files defer to is **`docs/AI_CONTEXT.md`** — read it
before making changes.

## What this is

**Inspectley** — a **production App Store app** (iOS 18+, SwiftUI + SwiftData,
iPhone portrait only) used by Hebrew-speaking building inspectors to create
photo inspection reports and export them as PDF/DOCX with full Hebrew/RTL
support. Regressions reach paying users.

- Internal project/target/module/folders are **InspectorPro**
  (bundle id `com.aloniter.inspectorpro`). Never rename internals;
  "Inspectley" is only for user-facing references.
- Current repo version is 1.0.2 build 3 in project.yml. Actual App Store
  Connect live/submitted version must be confirmed manually before release.
- `project.yml` is the source of truth for the Xcode project
  (`xcodegen generate` after editing it). Dependencies: ZIPFoundation,
  supabase-swift (SPM).

## Read before coding

1. `docs/AI_CONTEXT.md` — app purpose, flows, storage/export architecture,
   RTL warnings, do-not-touch areas, verification rules, known open issues.
2. `ARCHITECTURE.md` — module map and file-level pointers.
3. `tasks/lessons.md` — **mandatory before any export/RTL/numbering work.**
   It documents every approach that already failed in real Word and why.

## Hard rules

- **Do not casually change PDF/DOCX/export/RTL/storage/report-layout code.**
  The report's visual design (A4 layout, 60/40 columns, cover page, attendee
  numbering, Hebrew alignment, DOCX editability) is frozen unless the owner
  explicitly approves a change. This covers `InspectorPro/Export/`,
  `ImageStorageService`, `UIImage.resized(maxWidth:)` (`format.scale = 1` is
  load-bearing), and the transient-exports lifecycle.
- SwiftData schemas V1–V9 in `InspectorProMigration.swift` are history:
  only append V10+, never edit existing versions.
- Localization: add strings to BOTH `he.lproj` and `en.lproj`
  `Localizable.strings`; retrieve via `AppStrings.text()`.
- Hebrew UI: never fix RTL with a global LTR override; verify UI changes in
  Hebrew on simulator/device.

## Build & test

```bash
xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -configuration Debug build
xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro test   # Swift Testing (#expect), 86 tests
xcodegen generate   # after editing project.yml
```

- **Use a fresh `-derivedDataPath`** (scratch directory) for simulator test
  runs — the default DerivedData can silently install a stale app binary
  while still reporting BUILD/TEST SUCCEEDED (see `tasks/lessons.md`).
- **Never run two xcodebuild invocations concurrently** on this project —
  racing DerivedData can leave an unsigned app product that breaks the
  simulator until DerivedData is deleted.
- Export/RTL changes need rendered-output verification (LibreOffice headless
  + `pdftoppm`, pixel measurement), not just XML assertions; real Microsoft
  Word is authoritative for table centering. Details in `docs/AI_CONTEXT.md`.

## Workflow

- Plan non-trivial tasks in `tasks/todo.md` before implementing; keep items
  checkable and add a review section when done.
- After any correction from the owner, capture the pattern in
  `tasks/lessons.md`.
- Never mark work complete without running the tests and demonstrating
  correctness.
- Simplicity first: minimal, root-cause fixes; no temporary hacks; touch only
  what's necessary.

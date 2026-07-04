# Storage Forensics Investigation

This note documents the current read-only diagnostics added for investigating
unexpected iOS `Documents & Data` growth. It intentionally does not add cleanup,
migration, recompression, or user-facing warning UI.

## Storage Locations Covered

`StorageDiagnosticsService` measures these app container areas separately:

- `Documents`
- `Documents/InspectorPro`
- `Documents/InspectorPro/Images`
- `Documents/InspectorPro/Exports`
- legacy `Documents/InspectorPro/ExportCache`
- `Documents/InspectorPro/Branding`
- `tmp`
- `Library`
- `Library/Caches`
- `Library/Application Support`
- `Library/HTTPStorages`
- residual `Library` files outside Caches, Application Support, and HTTPStorages
- likely SwiftData database files in `Library/Application Support`

It also reports counts and total sizes for:

- original image files
- annotated image files
- PDF files
- DOCX files
- temporary files
- `docx_export_*` temporary DOCX package directories
- empty image folders
- potential orphan image files, when known photo references are supplied

The service is read-only. It enumerates files and sizes only.

## Known Write Paths

- `ImageStorageService.saveImage`: writes imported JPEGs under
  `Documents/InspectorPro/Images/<project-id>/`.
- `ImageStorageService.saveAnnotatedImage`: writes annotated JPEGs under
  `Documents/InspectorPro/Images/<project-id>/`.
- `PdfExporter.export`: writes generated PDFs under
  `Documents/InspectorPro/Exports/`.
- `DocxExporter.export`: creates a temporary `tmp/docx_export_<UUID>` package,
  zips it to `Documents/InspectorPro/Exports/`, and removes the temp package in
  `defer`.
- `ShareSheet`: removes the exported PDF/DOCX from `Exports` when the share
  sheet completes or is dismissed.
- `FileManagerService.purgeExports`: clears `Exports` on launch and removes old
  `Documents/InspectorPro/ExportCache`.
- `BrandingAssetStorage.saveCustomLogo`: writes custom branding logos under
  `Documents/InspectorPro/Branding/`.
- `InspectorProMigration`: writes temporary JSON migration payloads under `tmp`
  and removes each payload in `defer`.
- SwiftData writes its persistent store and WAL files under the app container,
  usually `Library/Application Support`.
- URL loading / auth/network frameworks may write HTTP storage files under
  `Library/HTTPStorages`.

No app code currently writes directly to `Library/Caches` or
`Library/HTTPStorages`. System frameworks may still use app temp/cache/library
locations during auth, import, share, and SwiftData work.

## How To Print Diagnostics

For an affected debug build, call:

```swift
StorageDiagnosticsService.debugPrintReport()
```

Useful temporary call sites:

- after `FileManagerService.shared.purgeExports()` in `InspectorProApp.init()`
- immediately before starting an export in `ExportOptionsSheet.startExport()`
- immediately after `ExportEngine.exportReport(...)` returns
- inside `ShareSheet`'s `completionWithItemsHandler`, after the export file is
  removed

Expected console shape:

```text
[StorageDiagnostics]
Documents total: 10.2 MB
InspectorPro total: 8.1 MB
Images: 5.7 MB
Exports: 0 KB
Legacy ExportCache: 0 KB
Branding: 120 KB
Temp: 1.3 MB
Library total: 1.1 MB
Caches: 0 KB
Application Support: 820 KB
HTTPStorages: 180 KB
Other Library: 100 KB
SwiftData: 780 KB
Original images: 3 files, 4.0 MB
Annotated images: 1 files, 1.7 MB
PDF exports: 0 files, 0 KB
DOCX exports: 0 files, 0 KB
Temporary files: 2 files, 1.3 MB
DOCX temp packages: 0 dirs, 0 KB
Orphans: 0 files, 0 KB
Empty image folders: 0
SwiftData files: default.store, default.store-wal
```

To detect image orphans precisely, call `makeReport(knownPhotoReferences:)` with
the current SwiftData photo paths. Without references, orphan totals stay at
zero because the service avoids guessing and never deletes anything.

## Manual Forensics Sequence

Run the same report at each checkpoint and compare the bucket deltas:

1. fresh launch
2. after creating one project and one empty report
3. after adding one photo
4. after PDF export returns and before share completion
5. after PDF share dismissal/completion
6. after DOCX export returns and before share completion
7. after DOCX share dismissal/completion
8. after deleting the report
9. after relaunch

The main evidence to look for:

- `Exports` should grow only while a share sheet is active and return near zero
  after share completion or relaunch.
- `DOCX temp packages` should stay at zero after DOCX export returns.
- `Temp` should not accumulate `docx_export_*` directories.
- `SwiftData` should not grow by hundreds of MB for empty or one-photo reports.
- `HTTPStorages` and `Other Library` should stay small; growth here points to
  network/auth/session storage rather than report photos or exports.
- image growth should be explainable by original and annotated JPEG counts.

## Real Device Capture

Do not uninstall the app before this run. Use an install/run path over the same
bundle identifier so the existing app container stays in place.

Xcode path:

1. Open `InspectorPro.xcodeproj`.
2. Select the `InspectorPro` scheme.
3. Select the affected iPhone as the run destination.
4. Make sure the scheme is using the Debug configuration.
5. Unlock the iPhone and keep it awake.
6. Run with Product > Run.
7. In the Xcode debug console, filter for `StorageDiagnostics`.
8. Perform the manual forensics sequence above.
9. Copy every block beginning with `[StorageDiagnostics]`.

CLI path used in this investigation:

```sh
xcodebuild \
  -project InspectorPro.xcodeproj \
  -scheme InspectorPro \
  -configuration Debug \
  -destination 'platform=iOS,id=00008140-001C6C380250801C' \
  -derivedDataPath /tmp/InspectorProDeviceDerivedData \
  build

xcrun devicectl device install app \
  --device 22E605AF-E0AC-51E1-BA60-DE243D6B15F6 \
  /tmp/InspectorProDeviceDerivedData/Build/Products/Debug-iphoneos/InspectorPro.app

# The device must be unlocked before this launch command.
xcrun devicectl device process launch \
  --device 22E605AF-E0AC-51E1-BA60-DE243D6B15F6 \
  --terminate-existing \
  --console \
  com.aloniter.inspectorpro | tee /tmp/inspectley-storage-diagnostics.log
```

If the launch command fails with `RequestDenied` / `Locked`, unlock the iPhone
and rerun only the `devicectl device process launch` command.

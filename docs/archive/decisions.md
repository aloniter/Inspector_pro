# Architecture Decisions

## Storage: SwiftData + FileManager
- SwiftData for structured data (projects, findings, photo metadata)
- FileManager for image files on disk
- Only relative paths stored in SwiftData
- Path: Documents/InspectorPro/Images/{projectID}/{findingID}/{uuid}.jpg

## Image Management
- Never hold all images in memory simultaneously
- Thumbnails (200px) for grid views
- Full images loaded one at a time
- autoreleasepool during export loops

## Export: Template-based DOCX
- DOCX template created programmatically (DocxTemplateBuilder)
- No binary template in bundle (version control friendly)
- ZIPFoundation SPM package for zip/unzip operations
- OpenXML with full RTL support at all levels

## RTL Strategy
- App-level .environment(\.layoutDirection, .rightToLeft)
- Hebrew locale for date formatting
- All UI strings hardcoded in Hebrew (no localization for MVP)
- Export: RTL at document, table, paragraph, and run levels

## Project Generation
- XcodeGen for CLI-based Xcode project creation
- project.yml as single source of truth for build settings
- iOS 18.0 minimum deployment target

## Dependencies
- ZIPFoundation 0.9.19+ (DOCX zip/unzip)
- No other third-party dependencies

# Inspector Pro - MVP Plan

## Overview
iPhone app for building inspectors to create inspection reports with photos.
Hebrew RTL UI, local-first, exports to PDF and DOCX.

## Milestones

### A: Data + Navigation
- SwiftData models: Project, Finding, Photo
- SwiftUI screens: ProjectList, ProjectDetail, FindingEditor
- Auto-numbering, reordering findings

### B: Photos + Annotation
- Camera + photo library import
- Disk-based image storage (paths in SwiftData)
- PencilKit annotation with annotated copy

### C: Compression + Caching
- 3 quality presets (Economical/Balanced/High)
- ExportCache with fingerprint-based keys
- Sequential processing, never all in memory

### D: PDF Export
- UIGraphicsPDFRenderer, A4, RTL
- 2-column finding tables (60/40)
- 2 findings per page, page breaks
- Extra photos full-width with captions

### E: DOCX Export
- Template-based (OpenXML)
- ZIPFoundation for zip/unzip
- Same layout rules as PDF
- RTL at all XML levels

### F: Stress Test
- 25 findings, 120 images
- Validate no crash, correct output

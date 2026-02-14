# DOCX Template Instructions

## How the Template Works
The app generates DOCX reports using a template-based approach.
The template is created programmatically by `DocxTemplateBuilder.swift`.

## Placeholders
The template uses these placeholders in `word/document.xml`:
- `{{PROJECT_TITLE}}` - Project name
- `{{ADDRESS}}` - Project address
- `{{DATE}}` - Inspection date
- `{{INSPECTOR}}` - Inspector name
- `{{FINDINGS_BLOCK}}` - Replaced with generated findings XML

## Customizing the Template
To modify the template structure:
1. Edit `DocxTemplateBuilder.swift`
2. Modify the XML in `buildDocumentXML()` method
3. Styles are defined in `buildStylesXML()`

## Finding Block Structure
Each finding generates:
1. A 2-column table (60% image / 40% text)
2. Additional photos as full-width images below
3. Page break after every 2 finding tables

## RTL Support
RTL is enforced at multiple XML levels:
- `<w:bidiVisual/>` on tables
- `<w:bidi/>` on paragraphs
- `<w:rtl/>` on text runs
- `<w:rFonts w:cs="Arial"/>` for Hebrew font

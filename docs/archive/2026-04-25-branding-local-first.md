# Branding Local-First Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make company branding fully local and user-controlled — every user (authenticated or not) edits branding on-device, and PDF/DOCX exports use only that local data.

**Architecture:** Remove the Supabase-branding-as-export-fallback path. `ResolvedExportBranding.resolve()` reads local SwiftData `BrandingProfile` first; if the report has none, it returns a clean empty branding. Authenticated users are no longer locked into a read-only view — they get the same editable settings screen with optional one-time seeding from remote if their local profile is blank. Company name is added to `ResolvedExportBranding` and rendered in the PDF and DOCX header.

**Tech Stack:** SwiftUI, SwiftData, UIGraphicsPDFRenderer, OpenXML (DOCX), ZIPFoundation

---

## File Map

| File | Change |
|------|--------|
| `InspectorPro/Branding/DefaultBrandingProfile.swift` | Clear all hardcoded Iter Engineering strings |
| `InspectorPro/Branding/ResolvedExportBranding.swift` | Add `companyName`, flip priority, remove Supabase fallback, add `empty` static |
| `InspectorPro/Export/PdfExporter.swift` | Render company name in header alongside logo |
| `InspectorPro/Export/DocxTemplateBuilder.swift` | Accept `companyName` in `headerXML()`, emit RTL company name paragraph |
| `InspectorPro/Export/DocxExporter.swift` | Pass `branding.companyName` to `headerXML()` |
| `InspectorPro/Views/Settings/BrandingSettingsView.swift` | Remove auth read-only gate, add one-time seeding for auth users, async save with "נשמר!" feedback, delete `RemoteBrandingReadOnlyView` |
| `InspectorProTests/ExportTests.swift` | Add tests for new resolve priority and company name in DOCX header |

---

## Task 1: Clear hardcoded Iter Engineering defaults

**Files:**
- Modify: `InspectorPro/Branding/DefaultBrandingProfile.swift`

- [ ] **Step 1: Replace all Iter strings with empty strings**

Replace the entire file content:

```swift
import Foundation

enum DefaultBrandingProfile {
    static let name = ""
    static let footerAddressLine = ""
    static let primaryFooterLinePDF = ""
    static let primaryFooterLineDOCX = ""
    static let secondaryFooterLine = ""

    static func makeBrandingProfile() -> BrandingProfile {
        BrandingProfile(
            name: name,
            isDefault: true,
            usesBundledDefaultLogo: true,
            showLogoInReport: true,
            showFooterInReport: true,
            footerAddressLine: footerAddressLine,
            primaryFooterLinePDF: primaryFooterLinePDF,
            primaryFooterLineDOCX: primaryFooterLineDOCX,
            secondaryFooterLine: secondaryFooterLine
        )
    }
}
```

- [ ] **Step 2: Build — verify no compile errors**

```bash
xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -configuration Debug build 2>&1 | grep -E "error:|warning:|BUILD"
```

Expected: `BUILD SUCCEEDED` (or only pre-existing warnings, no new errors).

- [ ] **Step 3: Commit**

```bash
git add InspectorPro/Branding/DefaultBrandingProfile.swift
git commit -m "fix: clear hardcoded Iter Engineering defaults from DefaultBrandingProfile"
```

---

## Task 2: Add `companyName` to `ResolvedExportBranding`, flip export priority

**Files:**
- Modify: `InspectorPro/Branding/ResolvedExportBranding.swift`
- Test: `InspectorProTests/ExportTests.swift`

- [ ] **Step 1: Write two failing tests**

Append to `InspectorProTests/ExportTests.swift`:

```swift
@Test func brandingResolvesLocalProfileFirst() {
    let profile = BrandingProfile(
        name: "Test Company",
        isDefault: true,
        usesBundledDefaultLogo: true,
        showLogoInReport: true,
        showFooterInReport: true,
        footerAddressLine: "123 Test St",
        primaryFooterLinePDF: "",
        primaryFooterLineDOCX: "",
        secondaryFooterLine: ""
    )
    let report = Report(name: "Test Report")
    report.brandingProfile = profile

    let resolved = ResolvedExportBranding.resolve(for: report)
    #expect(resolved.companyName == "Test Company")
}

@Test func brandingResolvesEmptyWhenNoProfile() {
    let report = Report(name: "No Branding Report")
    // brandingProfile intentionally nil

    let resolved = ResolvedExportBranding.resolve(for: report)
    #expect(resolved.companyName == "")
    #expect(resolved.logoImageData == nil)
    #expect(!resolved.hasVisibleFooterContent)
}
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro test 2>&1 | grep -E "passed|failed|error:"
```

Expected: the two new tests fail (companyName property does not exist yet).

- [ ] **Step 3: Rewrite `ResolvedExportBranding.swift`**

Replace the entire file:

```swift
import Foundation
import UIKit

struct ResolvedExportBranding {
    let companyName: String
    let logoImageData: Data?
    let footerAddressLine: String
    let primaryFooterLinePDF: String
    let primaryFooterLineDOCX: String
    let secondaryFooterLine: String
    let footerAddressRuns: [BrandingFooterFormatter.FooterRun]
    let primaryFooterRuns: [BrandingFooterFormatter.FooterRun]
    let secondaryFooterRuns: [BrandingFooterFormatter.FooterRun]
    let primaryFooterDisplayRuns: [BrandingFooterFormatter.FooterRun]
    let secondaryFooterDisplayRuns: [BrandingFooterFormatter.FooterRun]

    var coverMutedLabelColor: UIColor { Self.coverMutedLabelColorValue }
    var attendeesAccentColor: UIColor { Self.attendeesAccentColorValue }
    var footerTextColor: UIColor { Self.footerTextColorValue }
    var footerTextColorHex: String { Self.footerTextColorHexValue }
    var hasVisibleFooterContent: Bool {
        !footerAddressLine.isEmpty ||
        !primaryFooterDisplayRuns.isEmpty ||
        !secondaryFooterDisplayRuns.isEmpty
    }

    /// MVP: Local BrandingProfile is the single source of truth for export.
    /// If no profile is attached, return clean empty branding — never fall back to remote or Iter defaults.
    static func resolve(for report: Report) -> ResolvedExportBranding {
        if let brandingProfile = report.brandingProfile {
            return resolved(from: brandingProfile)
        }
        return empty
    }

    /// Empty branding — no logo, no company name, no footer. Export succeeds cleanly.
    static let empty = ResolvedExportBranding(
        companyName: "",
        logoImageData: nil,
        footerAddressLine: "",
        primaryFooterLinePDF: "",
        primaryFooterLineDOCX: "",
        secondaryFooterLine: "",
        footerAddressRuns: [],
        primaryFooterRuns: [],
        secondaryFooterRuns: [],
        primaryFooterDisplayRuns: [],
        secondaryFooterDisplayRuns: []
    )

    private static let coverMutedLabelColorValue = UIColor(
        red: 0x64 / 255.0,
        green: 0x74 / 255.0,
        blue: 0x8B / 255.0,
        alpha: 1
    )

    private static let attendeesAccentColorValue = UIColor(
        red: 0x1F / 255.0,
        green: 0x4E / 255.0,
        blue: 0x79 / 255.0,
        alpha: 1
    )

    private static let footerTextColorValue = UIColor(
        red: 0,
        green: 0x20 / 255.0,
        blue: 0x60 / 255.0,
        alpha: 1
    )

    private static let footerTextColorHexValue = "002060"

    private static func resolved(from brandingProfile: BrandingProfile) -> ResolvedExportBranding {
        let logoImageData = brandingProfile.showLogoInReport
            ? BrandingAssetStorage.displayLogoImageData(for: brandingProfile)
            : nil
        let footerAddressSource = brandingProfile.showFooterInReport ? brandingProfile.footerAddressLine : ""
        let primaryFooterPDFSource = brandingProfile.showFooterInReport ? brandingProfile.primaryFooterLinePDF : ""
        let primaryFooterDOCXSource = brandingProfile.showFooterInReport ? brandingProfile.primaryFooterLineDOCX : ""
        let secondaryFooterSource = brandingProfile.showFooterInReport ? brandingProfile.secondaryFooterLine : ""

        let primaryFields = BrandingPrimaryFooterFields.fromStoredLines(
            pdf: primaryFooterPDFSource,
            docx: primaryFooterDOCXSource
        )
        let secondaryFields = BrandingSecondaryFooterFields.fromStoredLine(secondaryFooterSource)

        return ResolvedExportBranding(
            companyName: brandingProfile.name,
            logoImageData: logoImageData,
            footerAddressLine: BrandingFooterFormatter.normalizeAddressLine(footerAddressSource),
            primaryFooterLinePDF: BrandingFooterFormatter.normalizeFreeformLine(primaryFooterPDFSource),
            primaryFooterLineDOCX: BrandingFooterFormatter.normalizeFreeformLine(primaryFooterDOCXSource),
            secondaryFooterLine: BrandingFooterFormatter.normalizeFreeformLine(secondaryFooterSource),
            footerAddressRuns: BrandingFooterFormatter.addressRuns(from: footerAddressSource),
            primaryFooterRuns: BrandingFooterFormatter.primaryRuns(primaryFields),
            secondaryFooterRuns: BrandingFooterFormatter.secondaryRuns(secondaryFields),
            primaryFooterDisplayRuns: BrandingFooterFormatter.primaryDisplayRuns(primaryFields),
            secondaryFooterDisplayRuns: BrandingFooterFormatter.secondaryDisplayRuns(secondaryFields)
        )
    }
}
```

- [ ] **Step 4: Run tests — expect the two new tests to pass, all others to pass**

```bash
xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro test 2>&1 | grep -E "passed|failed|error:"
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add InspectorPro/Branding/ResolvedExportBranding.swift InspectorProTests/ExportTests.swift
git commit -m "feat: add companyName to ResolvedExportBranding, flip export priority to local-first"
```

---

## Task 3: Render company name in PDF header

**Files:**
- Modify: `InspectorPro/Export/PdfExporter.swift` (the `drawBranding`, `drawHeader` private methods only)

- [ ] **Step 1: Update `drawBranding` to pass `branding` to `drawHeader`**

Find the `drawBranding` method (around line 387) and replace it:

```swift
// MARK: - Header / Footer Branding

private static func drawBranding(
    logoImage: UIImage?,
    branding: ResolvedExportBranding,
    options: ExportOptions
) {
    drawHeader(logoImage: logoImage, branding: branding, options: options)
    drawFooter(branding: branding, options: options)
}
```

- [ ] **Step 2: Update `drawHeader` to render company name right-aligned alongside the logo**

Replace the `drawHeader` method:

```swift
private static func drawHeader(
    logoImage: UIImage?,
    branding: ResolvedExportBranding,
    options: ExportOptions
) {
    let headerY = options.brandedHeaderDistancePt
    let headerHeight: CGFloat = options.headerZoneHeight

    // Logo: left-aligned, scaled to fit within the header zone.
    if let logo = logoImage {
        let maxDimension: CGFloat = min(75, headerHeight)
        let scale = min(maxDimension / logo.size.width, maxDimension / logo.size.height)
        let drawSize = CGSize(width: logo.size.width * scale, height: logo.size.height * scale)
        logo.draw(in: CGRect(x: options.marginLeft, y: headerY, width: drawSize.width, height: drawSize.height))
    }

    // Company name: right-aligned (RTL) in the same header zone.
    if !branding.companyName.isEmpty {
        drawRTLText(
            branding.companyName,
            in: CGRect(x: options.marginLeft, y: headerY, width: options.contentWidth, height: headerHeight),
            fontSize: 14,
            bold: true,
            alignment: .right
        )
    }
}
```

- [ ] **Step 3: Build — verify no compile errors**

```bash
xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -configuration Debug build 2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 4: Run all tests**

```bash
xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro test 2>&1 | grep -E "passed|failed|error:"
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add InspectorPro/Export/PdfExporter.swift
git commit -m "feat: render company name in PDF header alongside logo"
```

---

## Task 4: Render company name in DOCX header

**Files:**
- Modify: `InspectorPro/Export/DocxTemplateBuilder.swift` (the `headerXML` method only)
- Modify: `InspectorPro/Export/DocxExporter.swift` (the `headerXML` call only)
- Test: `InspectorProTests/ExportTests.swift`

- [ ] **Step 1: Write a failing test for company name in DOCX header XML**

Append to `InspectorProTests/ExportTests.swift`:

```swift
@Test func docxHeaderXMLContainsCompanyName() {
    let xml = DocxTemplateBuilder.headerXML(includesLogo: false, companyName: "Acme Ltd")
    #expect(xml.contains("Acme Ltd"))
    #expect(xml.contains("<w:bidi/>"))
    #expect(xml.contains("<w:rtl/>"))
}

@Test func docxHeaderXMLOmitsCompanyNameWhenEmpty() {
    let xmlWithLogo = DocxTemplateBuilder.headerXML(includesLogo: true, companyName: "")
    // Should produce same output as current single-argument call
    #expect(!xmlWithLogo.contains("<w:bidi/>"))
}
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro test 2>&1 | grep -E "passed|failed|error:"
```

Expected: the two new tests fail (`companyName` parameter does not exist yet).

- [ ] **Step 3: Update `headerXML` in `DocxTemplateBuilder.swift` to accept and render company name**

Find the `headerXML` static function and replace it entirely (preserving the existing logo logic, adding company name support):

```swift
static func headerXML(includesLogo: Bool = true, companyName: String = "") -> String {
    let trimmedName = companyName.trimmingCharacters(in: .whitespacesAndNewlines)
    let hasCompanyName = !trimmedName.isEmpty

    // Build the company name paragraph (right-aligned, RTL, bold, 14pt).
    let companyNameParagraph: String
    if hasCompanyName {
        let escapedName = OpenXMLBuilder.escapeXML(trimmedName)
        companyNameParagraph = """

  <w:p>
    <w:pPr>
      <w:spacing w:after="0" w:line="240" w:lineRule="auto"/>
      <w:jc w:val="right"/>
      <w:bidi/>
    </w:pPr>
    <w:r>
      <w:rPr>
        <w:b/>
        <w:sz w:val="28"/>
        <w:rFonts w:cs="Arial"/>
        <w:rtl/>
      </w:rPr>
      <w:t>\(escapedName)</w:t>
    </w:r>
  </w:p>
"""
    } else {
        companyNameParagraph = ""
    }

    guard includesLogo else {
        if hasCompanyName {
            return """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:hdr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">\(companyNameParagraph)
  <w:p>
    <w:pPr><w:spacing w:after="0" w:line="240" w:lineRule="auto"/></w:pPr>
  </w:p>
</w:hdr>
"""
        }
        return """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:hdr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:p>
    <w:pPr><w:spacing w:after="0" w:line="240" w:lineRule="auto"/><w:jc w:val="left"/></w:pPr>
  </w:p>
</w:hdr>
"""
    }

    let logoSizeEMU = 952500 // 75pt
    return """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:hdr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
       xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
       xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
       xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
       xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
  <w:p>
    <w:pPr><w:spacing w:after="0" w:line="240" w:lineRule="auto"/><w:jc w:val="left"/></w:pPr>
    <w:r>
      <w:drawing>
        <wp:inline distT="0" distB="0" distL="0" distR="0">
          <wp:extent cx="\(logoSizeEMU)" cy="\(logoSizeEMU)"/>
          <wp:effectExtent l="0" t="0" r="0" b="0"/>
          <wp:docPr id="1" name="Logo"/>
          <a:graphic>
            <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
              <pic:pic>
                <pic:nvPicPr>
                  <pic:cNvPr id="1" name="image1.jpeg"/>
                  <pic:cNvPicPr/>
                </pic:nvPicPr>
                <pic:blipFill>
                  <a:blip r:embed="rId1"/>
                  <a:stretch><a:fillRect/></a:stretch>
                </pic:blipFill>
                <pic:spPr>
                  <a:xfrm>
                    <a:off x="0" y="0"/>
                    <a:ext cx="\(logoSizeEMU)" cy="\(logoSizeEMU)"/>
                  </a:xfrm>
                  <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
                </pic:spPr>
              </pic:pic>
            </a:graphicData>
          </a:graphic>
        </wp:inline>
      </w:drawing>
    </w:r>
  </w:p>\(companyNameParagraph)
</w:hdr>
"""
}
```

- [ ] **Step 4: Update the `headerXML` call in `DocxExporter.swift`**

Find the line (around line 58):
```swift
try DocxTemplateBuilder.headerXML(includesLogo: includesLogo).write(
```

Replace with:
```swift
try DocxTemplateBuilder.headerXML(includesLogo: includesLogo, companyName: branding.companyName).write(
```

- [ ] **Step 5: Run all tests — all should pass including the two new ones**

```bash
xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro test 2>&1 | grep -E "passed|failed|error:"
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add InspectorPro/Export/DocxTemplateBuilder.swift InspectorPro/Export/DocxExporter.swift InspectorProTests/ExportTests.swift
git commit -m "feat: render company name in DOCX header"
```

---

## Task 5: Remove auth read-only gate — all users get the editable branding screen

**Files:**
- Modify: `InspectorPro/Views/Settings/BrandingSettingsView.swift`

This task rewrites `BrandingSettingsContainerView` and deletes `RemoteBrandingReadOnlyView`.

- [ ] **Step 1: Replace `BrandingSettingsContainerView` and delete `RemoteBrandingReadOnlyView`**

In `BrandingSettingsView.swift`, replace the entire `BrandingSettingsContainerView` struct (lines 6–58) and the entire `RemoteBrandingReadOnlyView` struct (lines 62–138) with:

```swift
struct BrandingSettingsContainerView: View {
    private enum LoadState {
        case loading
        case loaded(BrandingProfile)
        case failed
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(AuthService.self) private var authService
    @State private var loadState: LoadState = .loading

    var body: some View {
        Group {
            switch loadState {
            case .loaded(let brandingProfile):
                BrandingSettingsView(brandingProfile: brandingProfile)
            case .loading:
                ProgressView(AppStrings.text("טוען..."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed:
                EmptyStateView(
                    icon: "exclamationmark.triangle",
                    title: AppStrings.text("לא ניתן לטעון את הגדרות המיתוג"),
                    subtitle: AppStrings.text("נסה שוב מאוחר יותר")
                )
                .padding()
            }
        }
        .task {
            await loadBrandingProfileIfNeeded()
        }
        .navigationTitle(AppStrings.text("מיתוג חברה"))
        .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    private func loadBrandingProfileIfNeeded() async {
        guard case .loading = loadState else { return }

        do {
            let brandingProfile = try BrandingBootstrapper.fetchOrCreateDefaultBrandingProfile(in: modelContext)

            // For authenticated users: if local profile is still blank (first open),
            // seed fields from the cached remote Supabase data as a one-time convenience.
            // The user can then edit or clear these fields freely.
            if authService.isAuthenticated,
               brandingProfile.name.isEmpty,
               let remote = CompanyBrandingService.shared.loadCached() {
                brandingProfile.name = remote.name
                brandingProfile.footerAddressLine = remote.footerAddressLine
                brandingProfile.primaryFooterLinePDF = remote.primaryFooterLinePDF
                brandingProfile.primaryFooterLineDOCX = remote.primaryFooterLineDOCX
                brandingProfile.secondaryFooterLine = remote.secondaryFooterLine
                brandingProfile.showLogoInReport = remote.showLogoInReport
                brandingProfile.showFooterInReport = remote.showFooterInReport
                if let logoData = CompanyBrandingService.shared.cachedLogoImageData(),
                   let image = UIImage(data: logoData) {
                    try? BrandingAssetStorage.saveCustomLogo(image, for: brandingProfile)
                    brandingProfile.usesBundledDefaultLogo = false
                }
                try? modelContext.save()
            }

            loadState = .loaded(brandingProfile)
        } catch {
            loadState = .failed
        }
    }
}
```

- [ ] **Step 2: Build — verify no compile errors**

```bash
xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -configuration Debug build 2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Run all tests**

```bash
xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro test 2>&1 | grep -E "passed|failed|error:"
```

Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add InspectorPro/Views/Settings/BrandingSettingsView.swift
git commit -m "feat: remove auth read-only gate — all users can edit local branding; seed from remote on first open"
```

---

## Task 6: Add async save with "נשמר!" feedback

**Files:**
- Modify: `InspectorPro/Views/Settings/BrandingSettingsView.swift` (the private `BrandingSettingsView` struct)

- [ ] **Step 1: Add `saveSucceeded` state and rewrite `saveBranding` as async**

In the `BrandingSettingsView` struct, add one state property next to `isSaving`:

```swift
@State private var saveSucceeded = false
```

Replace the `saveBranding()` method with two methods — a synchronous launcher and an async body:

```swift
private func saveBranding() {
    Task {
        await performSave()
    }
}

@MainActor
private func performSave() async {
    let normalizedCompanyName = normalized(companyName)
    let normalizedFooterAddressLine = BrandingFooterFormatter.normalizeAddressLine(normalized(footerAddressLine))
    let normalizedPrimaryFooterFields = BrandingPrimaryFooterFields(
        contactName: normalized(primaryFooterFields.contactName),
        roleLabel: normalized(primaryFooterFields.roleLabel),
        phoneNumber: normalized(primaryFooterFields.phoneNumber),
        emailAddress: normalized(primaryFooterFields.emailAddress)
    )
    let normalizedSecondaryFooterFields = BrandingSecondaryFooterFields(
        firstLabel: normalized(secondaryFooterFields.firstLabel),
        firstNumber: normalized(secondaryFooterFields.firstNumber),
        secondLabel: normalized(secondaryFooterFields.secondLabel),
        secondNumber: normalized(secondaryFooterFields.secondNumber)
    )

    guard !normalizedCompanyName.isEmpty else { return }

    isSaving = true
    defer { isSaving = false }

    do {
        brandingProfile.name = normalizedCompanyName
        brandingProfile.footerAddressLine = normalizedFooterAddressLine
        brandingProfile.showLogoInReport = showLogoInReport
        brandingProfile.showFooterInReport = showFooterInReport

        if normalizedPrimaryFooterFields != initialPrimaryFooterFields {
            let normalizedPrimaryLine = BrandingFooterFormatter.composePrimaryLine(normalizedPrimaryFooterFields)
            brandingProfile.primaryFooterLinePDF = normalizedPrimaryLine
            brandingProfile.primaryFooterLineDOCX = normalizedPrimaryLine
        }

        if normalizedSecondaryFooterFields != initialSecondaryFooterFields {
            brandingProfile.secondaryFooterLine = BrandingFooterFormatter.composeSecondaryLine(normalizedSecondaryFooterFields)
        }

        if usesBundledDefaultLogo {
            BrandingAssetStorage.deleteCustomLogo(for: brandingProfile)
            brandingProfile.usesBundledDefaultLogo = true
        } else {
            if let pendingCustomLogoImage {
                try BrandingAssetStorage.saveCustomLogo(pendingCustomLogoImage, for: brandingProfile)
                self.pendingCustomLogoImage = nil
            }
            brandingProfile.usesBundledDefaultLogo = false
        }

        try modelContext.save()
        initialPrimaryFooterFields = normalizedPrimaryFooterFields
        initialSecondaryFooterFields = normalizedSecondaryFooterFields

        // Show "נשמר!" confirmation for 1.5 seconds before dismissing.
        saveSucceeded = true
        try await Task.sleep(for: .seconds(1.5))
        dismiss()
    } catch is CancellationError {
        // Task was cancelled — don't dismiss, just reset state.
        saveSucceeded = false
    } catch {
        saveSucceeded = false
        errorMessage = AppStrings.text("אירעה שגיאה בשמירה")
    }
}
```

- [ ] **Step 2: Update the Save toolbar button to show "נשמר!" when successful**

Find the `ToolbarItem(placement: .confirmationAction)` block and replace it:

```swift
ToolbarItem(placement: .confirmationAction) {
    Button(saveSucceeded ? AppStrings.text("נשמר!") : AppStrings.text("שמור")) {
        saveBranding()
    }
    .disabled(!isFormValid || isSaving)
    .tint(saveSucceeded ? .green : nil)
}
```

- [ ] **Step 3: Build — verify no compile errors**

```bash
xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -configuration Debug build 2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 4: Run all tests**

```bash
xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro test 2>&1 | grep -E "passed|failed|error:"
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add InspectorPro/Views/Settings/BrandingSettingsView.swift
git commit -m "feat: add async save with 'נשמר!' confirmation feedback in BrandingSettingsView"
```

---

## Task 7: Manual verification

These items cannot be unit-tested and must be verified on device or simulator.

- [ ] **Verify 1 — New user sees blank branding (no Iter data)**
  1. Delete the app from simulator, reinstall fresh.
  2. Go to Settings → Company Branding.
  3. All fields must be empty. Company name must be empty. Logo shows the default bundled icon (acceptable) but no Iter name, address, or contact info.

- [ ] **Verify 2 — Edit and save persists across app restart**
  1. Enter a company name, address line, and primary contact.
  2. Tap "שמור" — button shows green "נשמר!" for ~1.5s, then view dismisses.
  3. Force-quit the app and reopen.
  4. Go to Settings → Company Branding — all entered values must still be present.

- [ ] **Verify 3 — PDF export uses saved branding**
  1. With branding saved (company name, footer), open a report and export as PDF.
  2. Open the PDF — the header must show the company name (right side) and the bundled logo (left side).
  3. The footer must show the saved address/contact lines.
  4. No "Iter Engineering" or "איטר הנדסה" must appear.

- [ ] **Verify 4 — DOCX export uses saved branding**
  1. Export the same report as DOCX.
  2. Open in Word or Pages — header must show the company name; footer must show the saved footer lines.
  3. RTL layout must be correct (company name on the right, Hebrew text right-to-left).

- [ ] **Verify 5 — Export with no branding set does not crash**
  1. Delete and reinstall app (blank BrandingProfile with empty company name).
  2. Export a report with at least one photo — both PDF and DOCX.
  3. Export must succeed without crash. Header shows logo (or is empty if no logo); no footer appears.

- [ ] **Verify 6 — Logo picker works; logo appears in export**
  1. In Settings → Company Branding, tap "בחר לוגו מהספריה" and pick any image.
  2. Save. Export a report as PDF — the selected logo must appear in the header.
  3. Tap "השתמש בלוגו ברירת מחדל" — save. Export again — bundled logo appears.

- [ ] **Verify 7 — Authenticated user gets editable screen (not read-only)**
  1. Log in (authenticate via Supabase in the app).
  2. Go to Settings → Company Branding — the editable form must appear (not the old read-only banner).
  3. Edit company name and save. Verify the saved name persists.

- [ ] **Verify 8 — Hebrew RTL layout is correct throughout**
  1. In BrandingSettingsView, text fields and labels must be right-aligned.
  2. In exported PDF, company name must appear on the right side of the header.
  3. Footer lines must be right-aligned with Hebrew text rendering correctly.

---

## Risks and Notes

| Risk | Mitigation |
|------|-----------|
| Existing users with Iter branding already in SwiftData will keep Iter data | This is correct — they explicitly saved it; they can clear it in Settings |
| Authenticated users whose Supabase data hasn't been fetched yet won't get seeded | Seeding is a convenience, not required; they start with blank branding and fill it in |
| Overlap of logo and company name in PDF header for very long company names | Acceptable for MVP; layout can be refined if needed |
| `Task.sleep` in `performSave` may behave unexpectedly if view is deallocated early | The `CancellationError` catch handles this cleanly |

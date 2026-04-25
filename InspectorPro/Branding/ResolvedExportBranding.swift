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

    static let legacyDefault = ResolvedExportBranding(
        companyName: DefaultBrandingProfile.name,
        logoImageData: BrandingAssetStorage.bundledLogoImageData,
        footerAddressLine: BrandingFooterFormatter.normalizeAddressLine(DefaultBrandingProfile.footerAddressLine),
        primaryFooterLinePDF: BrandingFooterFormatter.normalizeFreeformLine(DefaultBrandingProfile.primaryFooterLinePDF),
        primaryFooterLineDOCX: BrandingFooterFormatter.normalizeFreeformLine(DefaultBrandingProfile.primaryFooterLineDOCX),
        secondaryFooterLine: BrandingFooterFormatter.normalizeFreeformLine(DefaultBrandingProfile.secondaryFooterLine),
        footerAddressRuns: BrandingFooterFormatter.addressRuns(from: DefaultBrandingProfile.footerAddressLine),
        primaryFooterRuns: BrandingFooterFormatter.primaryRuns(
            BrandingPrimaryFooterFields.fromStoredLines(
                pdf: DefaultBrandingProfile.primaryFooterLinePDF,
                docx: DefaultBrandingProfile.primaryFooterLineDOCX
            )
        ),
        secondaryFooterRuns: BrandingFooterFormatter.secondaryRuns(
            BrandingSecondaryFooterFields.fromStoredLine(DefaultBrandingProfile.secondaryFooterLine)
        ),
        primaryFooterDisplayRuns: BrandingFooterFormatter.primaryDisplayRuns(
            BrandingPrimaryFooterFields.fromStoredLines(
                pdf: DefaultBrandingProfile.primaryFooterLinePDF,
                docx: DefaultBrandingProfile.primaryFooterLineDOCX
            )
        ),
        secondaryFooterDisplayRuns: BrandingFooterFormatter.secondaryDisplayRuns(
            BrandingSecondaryFooterFields.fromStoredLine(DefaultBrandingProfile.secondaryFooterLine)
        )
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
        if brandingProfile.isDefault,
           brandingProfile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           brandingProfile.footerAddressLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           brandingProfile.primaryFooterLinePDF.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           brandingProfile.primaryFooterLineDOCX.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           brandingProfile.secondaryFooterLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return empty
        }

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

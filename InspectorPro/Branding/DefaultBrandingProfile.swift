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
            usesBundledDefaultLogo: false,
            showLogoInReport: false,
            showFooterInReport: false,
            footerAddressLine: footerAddressLine,
            primaryFooterLinePDF: primaryFooterLinePDF,
            primaryFooterLineDOCX: primaryFooterLineDOCX,
            secondaryFooterLine: secondaryFooterLine
        )
    }
}

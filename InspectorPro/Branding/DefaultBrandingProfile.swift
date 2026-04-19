import Foundation

enum DefaultBrandingProfile {
    static let name = "איטר הנדסה וניהול פרוייקטים"
    static let footerAddressLine = "כפר ויתקין, ת\"ד 635 מיקוד 4020000"
    static let primaryFooterLinePDF = "אבישי 054-6222577 דוא\"ל iter@iter.co.il"
    static let primaryFooterLineDOCX = "‎iter@iter.co.il‎ מייל ‎054-6222577‎ אבישי"
    static let secondaryFooterLine = "דפנה 054-6222575 משרד 09-8665885"

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

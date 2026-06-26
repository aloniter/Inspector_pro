# v1.0.2 Draft Notes

> Draft only. Current submitted App Store release is 1.0.1 build 2, Waiting for Review as of 2026-06-17.

## Scope Captured For 1.0.2

These changes were made after the 1.0.1 submission and should be considered for the next release notes / QA checklist:

1. **Settings layout polish**
   - Moved `רענון פרטי חברה` out of the top account details area.
   - The refresh-company-details action now appears in the `מיתוג חברה` section, below the company branding row.
   - The action remains authenticated-only and keeps the same loading/error behavior.

2. **Account deletion placement**
   - Moved `בקשת מחיקת חשבון` below `רענון פרטי חברה`.
   - The deletion request remains authenticated-only.
   - The support-email footer text remains attached to the deletion section.

3. **Report form RTL polish**
   - Fixed the `נוכחים` field in New/Edit Report so the placeholder and input align to the visual right.
   - Replaced the SwiftUI vertical `TextField` with the existing UIKit-backed `DirectionalTextField`, forced to `.right`, matching the app's Hebrew-first RTL form behavior.

4. **Branding settings RTL polish**
   - Fixed the company name field in `מיתוג חברה` so the placeholder and value align to the visual right.
   - Fixed branding toggle rows so labels such as `הצג לוגו בדוח` and `הצג כותרת בדוח` appear on the visual right and their switches appear on the visual left.
   - Fixed the `בחר לוגו מהספריה` action row so its icon/text use explicit RTL visual order.
   - Kept technical fields such as email and phone number on their existing explicit LTR behavior.

5. **Open defects count in export flow**
   - The `ייצוא דוח` summary row now reads `מספר ליקויים פתוחים X` instead of `תמונות X`, keeping the same RTL row style (label right, number left).
   - The PDF and DOCX cover/first page now include a combined line `מספר ליקויים פתוחים: X`.
   - Count is derived live from the logical report photos via a new `Report.openDefectCount` helper (one `PhotoRecord` = one defect). Annotated copies are not counted separately; deleting a photo before export lowers the number.
   - English localization added: `Open defects`.

6. **Splash/login app icon alignment**
   - Replaced the `AppLogo` image asset used by the launch screen and login screen with the same artwork as the App Store icon.
   - `LaunchScreen.storyboard` and `LoginView` already reference `AppLogo`, so the splash screen and login system picture now stay consistent with the App Store icon.
   - The shared logo asset is now `1024 x 1024`, RGB PNG, no alpha.

7. **Export sheet RTL polish**
   - Fixed the `פורמט` and `סיכום` section headers in the export sheet so they appear on the visual right.
   - Fixed the open-defects summary row so `מספר ליקויים פתוחים` stays on the visual right and the count stays on the visual left.
   - Implemented with explicit local row/header components instead of a global layout-direction override.

## Candidate App Store "What's New"

English:

```text
Improved Hebrew RTL layout in Settings, branding, and report editing. Company refresh and account deletion actions are now placed more naturally, Hebrew text fields now align correctly, and branding switches now show labels on the right with controls on the left.
```

Hebrew:

```text
שיפורי תצוגה ויישור בעברית במסכי ההגדרות, המיתוג ועריכת הדוח. פעולות רענון פרטי חברה ומחיקת חשבון ממוקמות בצורה ברורה יותר, שדות טקסט בעברית מיושרים כראוי לימין, ומתגי המיתוג מציגים טקסט מימין וכפתור משמאל.
```

## Verification Completed

- XcodeBuildMCP build/run succeeded on iPhone 16 Pro / iOS 18.6.
- Settings UI snapshot verified `רענון פרטי חברה` appears before `בקשת מחיקת חשבון`.
- New Report screen screenshot verified the `נוכחים` placeholder appears on the visual right.
- Branding Settings screen screenshots verified the company name value appears on the visual right, branding toggles place labels on the right with switches on the left, and the logo picker action uses RTL order.
- Open defects count: full suite passed 73/0/0 (added `reportOpenDefectCountMatchesLogicalPhotoCountIgnoringAnnotations` and `docxCoverDetailsIncludesOpenDefectCountAsSingleCombinedLine`). DOCX combined line asserted in XML; PDF line verified by build + shared helper (PDF text not unit-assertable in this env).
- Splash/login icon: XcodeBuildMCP build/run succeeded on iPhone 16 Pro / iOS 18.6; login screenshot verified the App Store icon artwork appears on the login screen. `AppLogo` is byte-identical to `AppIcon.appiconset/ItunesArtwork@2x.png`.
- Export sheet RTL polish: XcodeBuildMCP build/run succeeded on iPhone 16 Pro / iOS 18.6; `test_sim` passed with 73 passed, 0 failed, 0 skipped. Visual export-modal capture still needs an authenticated/manual pass.

## Follow-Up Before 1.0.2 Submission

- Re-run a clean build and full Swift Testing suite after final version/build bump.
- Re-check Settings screen in Hebrew on simulator/device.
- Re-check New Report and Edit Report attendee field placeholder and entered-text alignment.
- Re-check Branding Settings company name placeholder and entered-text alignment.
- Re-check Branding Settings toggle rows for logo/header visibility: label on the right, switch on the left.
- Re-check the `בחר לוגו מהספריה` action row for RTL icon/text order.
- On device/simulator, open `ייצוא דוח` for a report with photos and confirm the summary reads `מספר ליקויים פתוחים X`; export PDF and DOCX and confirm the first page shows `מספר ליקויים פתוחים: X`. Delete a photo and re-export to confirm the number drops.
- In the same export sheet, confirm `פורמט` and `סיכום` appear on the visual right, with `מספר ליקויים פתוחים` on the right and its number on the left.
- Re-check first launch and login screen branding after any future App Store icon replacement, because both now intentionally share the same artwork through `AppLogo`.
- If possible, manually type Hebrew into `נוכחים` and the company name field on device/simulator keyboard, because AXe UI automation cannot type Hebrew characters.

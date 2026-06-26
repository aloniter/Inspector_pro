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
- XcodeBuildMCP `test_sim` passed: 71 passed, 0 failed, 0 skipped.

## Follow-Up Before 1.0.2 Submission

- Re-run a clean build and full Swift Testing suite after final version/build bump.
- Re-check Settings screen in Hebrew on simulator/device.
- Re-check New Report and Edit Report attendee field placeholder and entered-text alignment.
- Re-check Branding Settings company name placeholder and entered-text alignment.
- Re-check Branding Settings toggle rows for logo/header visibility: label on the right, switch on the left.
- Re-check the `בחר לוגו מהספריה` action row for RTL icon/text order.
- If possible, manually type Hebrew into `נוכחים` and the company name field on device/simulator keyboard, because AXe UI automation cannot type Hebrew characters.

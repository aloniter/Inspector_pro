# Inspectley — App Store Connect Submission Package

**App:** Inspectley · **Bundle ID:** `com.aloniter.inspectorpro` · **Version:** 1.0.1 · **Build:** 2
**Primary language:** Hebrew · **Secondary:** English
**Status:** Production-ready copy. Paste directly into App Store Connect.

---

## 1. App Information (set once)

| Field | Value |
|-------|-------|
| Bundle ID | `com.aloniter.inspectorpro` |
| SKU | `inspectley-ios-001` |
| Primary Category | **Business** |
| Secondary Category | **Productivity** |
| Primary Language | Hebrew |
| Content Rights (third-party content) | No |
| Age Rating | **4+** |

---

## 2. English Localization

**App Name** (10/30)
```
Inspectley
```

**Subtitle** (30/30)
```
Inspection reports with photos
```
Safer alt (24/30): `Photo inspection reports`

**Promotional Text** (152/170)
```
Create professional inspection reports in the field—capture photos, annotate findings, add company branding, and export polished PDF or DOCX in seconds.
```

**Keywords** (98/100)
```
building,property,defect,survey,PDF,DOCX,field,contractor,checklist,site,engineer,audit,realestate
```

**Description**
```
Inspectley is the fast, field-ready way for professional inspectors and surveyors to turn a site visit into a finished, client-ready report.

Built for real fieldwork: open a project, add a report, capture or import photos, mark up findings, write your notes, and export a clean PDF or Word (DOCX) document — all from your iPhone.

WHAT YOU CAN DO
• Organize work into projects and reports
• Capture photos with the camera or import from your library (up to 500 per report)
• Annotate photos to highlight defects and findings
• Write structured descriptions with full Hebrew and right-to-left (RTL) support
• Apply your company branding — logo and footer — to every report
• Export professional PDF and DOCX files, ready to send to clients
• Work in Hebrew or English with an instant in-app language switch

BUILT FOR THE FIELD
Your projects, reports, and photos are stored locally on your device. Reports are generated on-device and shared only when you choose to export them.

FOR INSPECTION TEAMS
Inspectley is a business tool. Your account is provided and managed by your organization. There are no in-app purchases — access is handled through your company.

Questions or access issues? Contact your administrator or our support team at inspectleyapp@gmail.com.
```

---

## 3. Hebrew Localization (RTL)

**App Name** (10/30)
```
Inspectley
```

**Subtitle** (18/30)
```
דוחות בדק מקצועיים
```

**Promotional Text** (108/170)
```
צרו דוחות בדק מקצועיים בשטח: צלמו תמונות, סמנו ממצאים, הוסיפו מיתוג חברה וייצאו דוח PDF או DOCX מוכן בשניות.
```

**Keywords** (84/100)
```
מבנים,נכס,ליקויים,פיקוח,קבלן,מהנדס,בדק בית,נדלן,אתר בנייה,תיעוד,דוח בדיקה,מסירת דירה
```

**Description**
```
Inspectley היא הדרך המהירה והנוחה לבודקי מבנים ולאנשי שטח להפוך ביקור באתר לדוח מקצועי ומוכן ללקוח.

האפליקציה בנויה לעבודה אמיתית בשטח: פותחים פרויקט, מוסיפים דוח, מצלמים או מייבאים תמונות, מסמנים ממצאים, כותבים הערות, ומייצאים קובץ PDF או Word‏ (DOCX) מסודר — הכול מהאייפון.

מה אפשר לעשות
• ניהול עבודה בפרויקטים ודוחות
• צילום תמונות במצלמה או ייבוא מהגלריה (עד 500 לכל דוח)
• סימון והדגשת ליקויים על גבי התמונות
• כתיבת תיאורים מסודרים עם תמיכה מלאה בעברית ובכיוון מימין לשמאל (RTL)
• מיתוג חברה — לוגו וכותרת תחתונה — בכל דוח
• ייצוא קובצי PDF ו-DOCX מקצועיים, מוכנים לשליחה ללקוח
• עבודה בעברית או באנגלית עם החלפת שפה מיידית באפליקציה

בנוי לשטח
הפרויקטים, הדוחות והתמונות נשמרים מקומית במכשיר. הדוחות נוצרים במכשיר ומשותפים רק כשתבחרו לייצא אותם.

לצוותי בדק
Inspectley הוא כלי עסקי. החשבון מסופק ומנוהל על ידי הארגון שלכם. אין רכישות מתוך האפליקציה — ההרשאות מנוהלות דרך החברה.

שאלות או בעיית גישה? פנו למנהל המערכת או לתמיכה בכתובת inspectleyapp@gmail.com.
```

---

## 4. Support Information

| Field | Value |
|-------|-------|
| Support URL | `https://aloniter.github.io/inspectley-appstore-pages/support.html` (live) |
| Marketing URL | (blank for v1.0) |
| Privacy Policy URL | `https://aloniter.github.io/inspectley-appstore-pages/privacy.html` (live) |
| Support / Review contact email | `inspectleyapp@gmail.com` |

Public Support & Privacy pages confirmed to use `inspectleyapp@gmail.com` (matches the app).

---

## 5. App Privacy answers

- Collects data: **Yes**
- Tracking: **No**
- Data type — Contact Info → Email Address: Collected **Yes** · Linked **Yes** · Tracking **No** · Purpose **App Functionality** (Supabase Auth login).
- NOT collected (local only): Photos, User Content, Location, Contacts, Identifiers, Usage Data, Diagnostics.
- Required-reason API manifest (already shipped in `PrivacyInfo.xcprivacy`): UserDefaults `CA92.1`, File Timestamp `C617.1`.

---

## 6. Age Rating → 4+

Answer None/No to all categories (Violence, Sexual Content, Profanity, Alcohol/Tobacco/Drugs, Gambling, Horror, Medical, Unrestricted Web). Made for Kids: No.

---

## 7. Screenshot Plan (iPhone 6.9", portrait, Hebrew UI)

| Order | Screen | App state | Sample content | Overlay headline |
|:--:|--|--|--|--|
| 1 | Login | Logged out, empty fields | Logo + tagline | "Built for professional inspectors" |
| 2 | Project list | Logged in, 3–4 projects | Fictional projects + report counts | "Every site in one place" |
| 3 | Report photo grid | Report open, 6–9 thumbnails | Generic building/defect photos | "Capture findings on site" |
| 4 | Photo annotation | Editor open, one markup visible | Wall crack + red circle | "Mark up defects in seconds" |
| 5 | Export options | Export sheet open, format picker | PDF/DOCX picker, photo count | "Polished PDF & Word reports" |
| 6 | Settings/branding | Logged in, export status Active | Company name + green "פעיל" | "Your logo on every report" |

Content rules: no real client data; never show payment/trial/expiry or the deletion email; show Active status; keep the demo password off-screen.

---

## 8. TestFlight QA Checklist (real device, fresh install)

```
AUTH
[ ] Login (inspectleyapp@gmail.com / <reviewer password — kept out of git>) -> project list
[ ] Wrong password shows clear error, no crash
[ ] Force-quit + relaunch -> session restored

CORE FLOW
[ ] Project creation
[ ] Report creation
[ ] Photo capture (camera permission)
[ ] Photo import (photos permission, PHPicker)
[ ] Annotation draw + save persists

EXPORT
[ ] PDF export -> share sheet
[ ] DOCX export -> share sheet
[ ] Open in Word/Pages: Hebrew RTL correct, photos present
[ ] Settings export status = Active

SETTINGS
[ ] Language switching Hebrew<->English flips layout
[ ] Request Account Deletion -> Mail composer, To inspectleyapp@gmail.com, Subject "Account Deletion Request"
[ ] Logout -> returns to login

EDGE
[ ] Airplane mode export blocked gracefully
[ ] Icon, launch screen, dark mode OK
[ ] Large report (50+ photos) exports
```

---

## 9. App Store Connect Field Checklist

```
APP INFO: Name, Subtitle (EN/HE), Primary=Business, Secondary=Productivity, Content Rights=No, Age=4+
PRICING: Free, availability
VERSION 1.0.1 (EN+HE): Promo, Description, Keywords, Support URL, Screenshots
BUILD: attach 1.0.1 (2), Export Compliance = No
APP PRIVACY: Data=Yes, Tracking=No, Email collected/linked/app-functionality, Privacy URL
REVIEW INFO: Sign-In ON, demo creds, contact, Notes (section 10)
SUBMIT: Add for Review -> Submit, Manual release
```

---

## 10. Apple Review Notes (paste into App Review Information → Notes)

```
=== INSPECTLEY — APP REVIEW NOTES ===

OVERVIEW
Inspectley is a BUSINESS (B2B) app for professional building-inspection firms.
It lets an inspector create local projects and reports, capture/import and annotate
inspection photos, and export the report as PDF or DOCX to share with clients.

LOGIN IS REQUIRED — please use the demo account in the Sign-In fields above.
Username: inspectleyapp@gmail.com
Password: [enter the reviewer password directly in the App Store Connect "Sign-In Information" fields — do not commit it to git]
This account is fully active with export enabled (valid through 2030).

B2B / NO IN-APP PURCHASE
This is an enterprise tool. Accounts are provisioned and billed through a separate
B2B commercial agreement between Inspectley and each inspection company. The individual
inspector never makes a purchase. There are NO in-app purchases, subscriptions, prices,
paywalls, or external checkout links anywhere in the app. If a company's account were
inactive, the app would only show a message to contact their administrator — the demo
account you have is active, so you will not see this.

BACKEND USE (Supabase)
Supabase is used ONLY for: user authentication, company branding, and export
authorization (account-active check). Inspection photos, reports, and project data are
stored LOCALLY on the device and are never uploaded to the backend.

HOW TO TEST EXPORT (PDF & DOCX)
1. Log in with the demo account above.
2. Tap "+" to create a Project.
3. Open the project and add a Report.
4. Add a photo — use the camera or import from the photo library.
5. (Optional) Tap a photo and draw an annotation, then save.
6. Tap Export, choose PDF or DOCX, and confirm the file appears in the iOS share sheet.
7. The report exports with full Hebrew right-to-left formatting.

ACCOUNT DELETION
The app provides Settings → "Request Account Deletion", which opens a prefilled email
to support. Account-deletion instructions are also published in our Privacy Policy.

NOTES
- iPhone-only, portrait, iOS 18+.
- Default language is Hebrew (RTL); English available via Settings.
- Support: inspectleyapp@gmail.com
```

Backend pre-check (validated 2026-06-13): auth user exists & confirmed; profile.company_id valid;
company "Apple Review Account" export_allowed=true, payment_status=active, trial_end_date=2030-12-31.
Do not change this account to suspended/expired until review concludes.

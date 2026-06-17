# Inspectley 1.0.1 — App Store Submission Notes

Use this file when preparing the App Store submission for version `1.0.1`.

Date prepared: 2026-06-17
Reviewer credentials: keep the password **only** in App Store Connect "Sign-In Information" (never in git).

---

## 1. App Store Connect "What's New" Text

### English
Improved Hebrew right-to-left layout across project, report, and settings screens — fixing form alignment, settings row layout, and mixed Hebrew/English values for a cleaner Hebrew-first experience. This update also reduces on-device storage use by automatically cleaning up temporary export files.

### Hebrew
שיפורי תצוגה בעברית ובכיוון מימין לשמאל במסכי פרויקטים, דוחות והגדרות — תיקון יישור שדות, פריסת שורות בהגדרות וערכים מעורבים בעברית/אנגלית לחוויה נקייה יותר. בנוסף, העדכון מצמצם את נפח האחסון במכשיר על ידי ניקוי אוטומטי של קובצי ייצוא זמניים.

---

## 2. User-Visible Changes

### Hebrew / RTL UI polish (completed earlier in this release cycle)
- New Project / Edit Project: Hebrew field alignment fixed; placeholders and entered text align consistently.
- Edit Report: name and address right-aligned; removed the extra short underline under the date label.
- Settings → Account: labels on the visual right, values on the visual left; email/dates stay LTR-readable.
- Settings → general: right-aligned section headers; dark-mode, language, company-branding, and version rows laid out correctly for RTL; footer centered. Language-switch behavior unchanged.

### Storage & export hygiene (this pass)
- Exported PDF/DOCX files are now **transient**: each file is removed automatically after the share flow finishes, and any leftovers are cleared on app launch. The app no longer accumulates export files indefinitely.
- Empty project image folders left behind after deleting a project are now removed safely.
- Removed unused internal export-cache code.
- **No change to report quality, export content, or any user workflow.**

---

## 3. App Review Notes
Paste the text in `review-notes.md` into the App Store Connect "App Review Notes" field, and enter the reviewer email/password into the "Sign-In Information" fields (do **not** put the password in the notes or in git).

Summary for the reviewer:
- Login is required; use the provided demo account (active trial, export enabled).
- Inspectley is a B2B inspection-report tool. No in-app purchases, subscriptions, prices, or external payment/checkout links.
- Flow to review export: log in → create project → create report → add/import a photo → export PDF or DOCX → confirm the file appears in the iOS share sheet.

---

## 4. Privacy / Payment / Storage Notes for Apple
- **Privacy:** No new data collection in 1.0.1. No tracking. `PrivacyInfo.xcprivacy` is unchanged. Supabase is used only for authentication, company branding, and export authorization/trial status.
- **Storage:** Inspection projects, report text, and photos are stored **locally on device** (`Documents/InspectorPro/`). The app does **not** upload inspection photos or report files to any server. 1.0.1 only changes local file *hygiene* (transient exports + empty-folder cleanup) — no new storage, network, or background activity.
- **Payment:** No in-app purchases or payment UI. Accounts are provisioned via a separate B2B agreement. If an account is expired/export-disabled, the app shows only a support/contact message.
- **Encryption:** `ITSAppUsesNonExemptEncryption = NO` (unchanged).

---

## 5. QA Checklist — Completed
- [x] Full Swift Testing suite: **71 tests passing** (iPhone 16 simulator, iOS 18.x), incl. 2 new tests for empty-folder cleanup and export purge.
- [x] Clean build, no compiler warnings.
- [x] Hebrew/RTL screens verified (New/Edit Project, Edit Report, Settings sections, language switching).
- [x] **Real-device share QA passed** — PDF and DOCX export + share verified; file is removed after the share completes; re-export works; `Exports/` is empty after relaunch.
- [x] Originals and annotated photos confirmed never deleted; non-empty folders never removed.
- [x] PDF/DOCX export still works after the changes.

---

## 6. Files Changed in 1.0.1
RTL/UI: `AGENTS.md`, `InspectorPro/Views/Components/DirectionalTextField.swift`, `InspectorPro/Views/Projects/ProjectFormView.swift`, `InspectorPro/Views/Projects/ProjectListView.swift`.
Storage/export: `InspectorPro/Export/ExportCache.swift` (deleted), `InspectorPro/Services/FileManagerService.swift`, `InspectorPro/Services/ImageStorageService.swift`, `InspectorPro/Utilities/Constants.swift`, `InspectorPro/Views/Photos/AnnotationView.swift`, `InspectorPro/Views/Export/ExportOptionsSheet.swift`, `InspectorPro/InspectorProApp.swift`.
Tests/docs/project: `InspectorProTests/ExportTests.swift`, `InspectorPro.xcodeproj` (regenerated), `tasks/lessons.md`, `tasks/todo.md`.

---

## 7. Pre-Upload Reminders
- Version set to `1.0.1` / build `2` in `project.yml` and the generated project (done).
- Screenshots for 6.9" and 6.5" are staged under `AppStore/screenshots/` (not committed to git).
- Verify reviewer Supabase account is active (see `review-notes.md` → backend requirements).
- **Security:** reviewer account verified working 2026-06-17; credentials kept unchanged. The password is no longer in any tracked file (only in the gitignored local file + App Store Connect). It still exists in older git history — rotate/scrub if repo access widens.

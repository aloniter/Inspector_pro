# Inspectley App Store Submission Plan

## A. Executive Summary

Status: **Almost ready, not ready to submit until final manual checks are complete**.

Confidence level: **Medium-high**. Debug build, Release simulator build, metadata checks, and automated tests passed during the readiness review, but signed archive validation and real-device QA still need to be completed.

Main reason: the app is technically close, but App Store submission depends on a valid Apple review login/export account, signed iPhoneOS archive validation, App Store Connect privacy/compliance answers, and real-device camera/photo/export verification.

**Version rule:** the App Store archive marketing version must be **1.0.3**. The old `1.2.0` value was stale and must not be used. Do not increment the marketing version unless explicitly requested later. Only increase the build number if App Store Connect rejects build `1` for version `1.0.3`.

## B. Critical Fixes Before App Store Submission

- `/Users/aloniter/Projects/InspectorPro/project.yml`: `MARKETING_VERSION` must stay `"1.0.3"` so `xcodegen generate` cannot regenerate the Xcode project back to stale version `1.2.0`.
- App Store Connect: create and verify a review account that can log in and export. The account must have valid Supabase auth, `profiles.company_id`, a matching `companies` row, and export permission enabled.
- Xcode Organizer: create and validate a signed iPhoneOS Release archive. Simulator Release builds are not enough for App Store submission.
- App Store Connect privacy/compliance: complete privacy nutrition labels and export-compliance answers to match actual Supabase auth/account data and local photo/report usage.

## C. Recommended Fixes Before First Customer Release

- Run real-device QA on a clean iPhone: first launch, login, session restore, logout, camera capture, photo-library import, logo import, PDF export, DOCX export, share sheet, and offline export denial.
- Test a large report with many photos to confirm memory and export completion under realistic use.
- Watch the existing SwiftData/CoreData editable-model checksum warning during real-device QA and archive validation.
- Decide whether visible `Created By Iter Engineering` in Settings and export metadata is intended for customer-facing builds.
- Update stale documentation that says ZIPFoundation is the only third-party dependency; the app also uses Supabase and its transitive packages.

## D. Optional Polish

- Add App Store screenshots from realistic Hebrew and English report flows.
- Add a short privacy/support page URL if not already prepared.
- Improve App Store listing copy with a clear “building inspection reports” positioning.

## E. What Changed

- `/Users/aloniter/Projects/InspectorPro/project.yml`: changed `MARKETING_VERSION` from stale `1.2.0` to correct App Store version `1.0.3`; left `CURRENT_PROJECT_VERSION` unchanged.
- `/Users/aloniter/Projects/InspectorPro/InspectorPro.xcodeproj/project.pbxproj`: regenerated from `project.yml`; verified both app target build configurations remain `MARKETING_VERSION = 1.0.3;`.
- `/Users/aloniter/Projects/InspectorPro/APP_STORE_SUBMISSION_PLAN.md`: added this App Store submission plan and explicit version rule.

## F. Tests And Builds Performed

- `xcodegen generate`
  - Result: succeeded.
- `rg -n "MARKETING_VERSION|CURRENT_PROJECT_VERSION|1\\.2\\.0|1\\.0\\.3" project.yml InspectorPro.xcodeproj/project.pbxproj`
  - Result: `project.yml` and both generated app target configurations use `1.0.3`; no `1.2.0` remains in these build settings.
- `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -configuration Release -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' build CODE_SIGNING_ALLOWED=NO`
  - Result: succeeded.
- `/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' <Release app>/Info.plist`
  - Result: `1.0.3`.
  - Build number remained `1`; display name remained `Inspectley`.

## G. Step-by-Step Checklist Until Apple Approval

1. Clean final build locally:
   - Confirm `/Users/aloniter/Projects/InspectorPro/InspectorPro/Resources/SupabaseConfig.plist` exists locally.
   - Run `xcodegen generate`.
   - Run `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -configuration Release -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' build CODE_SIGNING_ALLOWED=NO`.
   - Verify `CFBundleShortVersionString` is `1.0.3`.
2. Archive in Xcode:
   - Open `InspectorPro.xcodeproj`.
   - Select `Any iOS Device` or a connected iPhone.
   - Confirm version `1.0.3`; increase build number only if needed.
   - Product > Archive.
3. Upload to App Store Connect:
   - In Organizer, validate the archive.
   - Upload the validated archive.
4. Fill App Store listing:
   - Add app name, subtitle, description, keywords, category, support URL, privacy policy URL, age rating, and contact info.
5. Privacy questions:
   - Declare account email/auth data used for app functionality.
   - Declare user-created report/photo data according to actual storage and backend behavior.
   - Do not declare tracking unless the business actually tracks users across apps/sites.
6. Export compliance:
   - The app currently sets `ITSAppUsesNonExemptEncryption = false`.
   - Answer consistently unless legal/business review says the Supabase/TLS usage requires a different declaration.
7. TestFlight final sanity check:
   - Install on a real iPhone.
   - Log in with the review account.
   - Create project/report, add photos, export PDF and DOCX, share/open both files, test logout.
8. Add screenshots:
   - Use real app screens showing project/report/photo/export flows.
   - Include Hebrew-first screenshots if Hebrew is the primary market.
9. Submit for review:
   - Select the processed build.
   - Add review credentials in App Store Connect Sign-In Information.
   - Paste the Review Notes below.
10. Review Notes:
   - Include what the app does, how to test login/export, and that export is account-permission controlled.
11. If Apple rejects it:
   - Read the exact rejection reason.
   - Reproduce the reviewer path.
   - Fix only the cited issue.
   - Increase build number, rearchive, upload, and reply in Resolution Center with the fix summary.

## H. App Review Notes Draft

Inspectley is an iPhone app for building inspectors to create inspection reports with photos and export professional PDF/DOCX reports, including Hebrew and right-to-left layout support.

The app requires sign-in. Please use the demo/review account provided in App Store Connect Sign-In Information. After signing in, create a project, create a report, add or import photos, then use the report export action to generate PDF or DOCX output.

Export access is controlled by account permissions in our backend. The review account should have export enabled so App Review can test the full export flow. There are no in-app purchases in this build.

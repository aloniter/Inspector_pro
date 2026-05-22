# App Store Readiness Checklist

Status checked on 2026-05-11 for `main`, app version `1.0.3` build `2`.

## Code and Build Status

- [x] Supabase configuration file is bundled with `SUPABASE_URL` and `SUPABASE_ANON_KEY`
- [x] Login flow is required before entering the app
- [x] Export permission gate checks Supabase `profiles` and `companies`
- [x] Trial-expired/export-disabled messages do not include external payment links
- [x] Privacy manifest exists and declares linked email for app functionality
- [x] Camera and photo library purpose strings are present in Hebrew and English
- [x] Export compliance flag is set: `ITSAppUsesNonExemptEncryption = false`
- [x] App icon asset contains a 1024x1024 iOS marketing icon
- [x] App Store archive succeeds for iOS device
- [x] Swift Testing passes on iPhone 16 simulator with 66 tests

## Must Be Done in App Store Connect

- [ ] Create or verify the app record for bundle id `com.aloniter.inspectorpro`
- [ ] Set app name to `Inspectley`
- [ ] Create version `1.0.3` and attach uploaded build `2`
- [x] Add Privacy Policy URL: `https://aloniter.github.io/inspectley-appstore-pages/privacy.html`
- [x] Add Support URL: `https://aloniter.github.io/inspectley-appstore-pages/support.html`
- [ ] Fill app privacy answers to match current behavior
- [ ] Add App Review test credentials from Supabase directly in App Store Connect; do not commit the password to git
- [ ] Add App Review notes explaining the account/trial/export gating
- [ ] Upload required iPhone screenshots, at minimum 6.7-inch display size
- [ ] Set category, age rating, countries/regions, pricing, and contact information
- [ ] Submit first to TestFlight/App Review, then submit for App Store review

## Recommended App Privacy Answers

- Tracking: No
- Data collected and linked to user: Email Address, used for App Functionality
- Photos/reports/project data: currently stored on device and exported by user action; do not mark as collected unless backend behavior changes
- Supabase company/profile data: used for App Functionality, account management, branding, and export authorization
- Required reason APIs in privacy manifest: UserDefaults and File Timestamp

## Review Account Notes

- Provide Apple with a real Supabase reviewer account.
- The reviewer account should have an associated `profiles.company_id`.
- The linked `companies` row should allow export, for example `export_allowed = true` and `payment_status = trial` or active.
- Do not give Apple an expired/suspended account unless also providing instructions for the blocked-state review.

## Submission Notes

- Use Xcode Organizer for the easiest upload path: Product > Archive > Distribute App > App Store Connect > Upload.
- Let Xcode handle automatic signing during distribution.
- App Store Connect may take several minutes to process the uploaded build before it can be selected.
- Avoid external payment/subscription links in app screens or review notes.

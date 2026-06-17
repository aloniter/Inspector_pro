# Inspectley 1.0.1 — Archive & Upload Checklist (App Store Connect)

Prepared 2026-06-17. **Do not submit until you've completed every box.** Reviewer password lives only in `reviewer-credentials.local.md` (gitignored) and App Store Connect — never in git.

## 0. Pre-flight (already done in repo)
- [x] `MARKETING_VERSION = 1.0.1`, `CURRENT_PROJECT_VERSION = 2` (in `project.yml` and generated `project.pbxproj`).
- [x] `xcodegen generate` run; project in sync with `project.yml`.
- [x] Clean build + 71 Swift Testing tests pass (iPhone 16 sim).
- [x] Real-device share QA passed (PDF/DOCX export → share → file cleaned up).
- [x] `ITSAppUsesNonExemptEncryption = NO` present.
- [x] No plaintext reviewer password committed; `SupabaseConfig.plist` gitignored.

## 1. Rotate reviewer account (manual — do first)
- [ ] In Supabase → Authentication → Users, set `inspectleyapp@gmail.com` to the new password from `reviewer-credentials.local.md`.
- [ ] Verify login works in a local build with the new password.
- [ ] Confirm the account is export-enabled (active trial / `companies.export_allowed = true`, future `trial_end_date`) per `review-notes.md` backend requirements.

## 2. Archive
- [ ] Open `InspectorPro.xcodeproj` in Xcode; select **Any iOS Device (arm64)** as destination.
- [ ] Confirm signing: team `H29SVV6K2S`, automatic signing, bundle id `com.aloniter.inspectorpro`.
- [ ] Product → Archive (Release config).
- [ ] (CLI alt) `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -configuration Release -destination 'generic/platform=iOS' -archivePath /tmp/InspectorPro-1.0.1.xcarchive archive`
- [ ] In Organizer, confirm the archive shows version **1.0.1 (2)**.

## 3. Validate & Upload binary
- [ ] Organizer → Distribute App → App Store Connect → Validate. Resolve any validation errors.
- [ ] Upload. Wait for the build to finish processing in App Store Connect (can take 5–60 min).

## 4. App Store Connect — version 1.0.1 page
- [ ] Create the **1.0.1** version if not already present.
- [ ] Select the processed **build 2**.
- [ ] **What's New** — paste EN + HE text from `version-1.0.1-fix-summary.md` §1.
- [ ] **App Review Information → Sign-In Information**: user `inspectleyapp@gmail.com`, password = the new one from `reviewer-credentials.local.md` (typed here, not committed).
- [ ] **App Review Notes** — paste the block from `review-notes.md` (password stays out of the notes; it's in Sign-In Information).
- [ ] **Screenshots** — upload 6.9" and 6.5" sets from `AppStore/screenshots/` (these are not in git). No payment/trial/expiry/real-client data visible.
- [ ] **App Privacy** — confirm answers match `privacy-answers.md`; no changes in 1.0.1.
- [ ] Confirm category (business), age rating, pricing/availability unchanged.

## 5. Privacy / payment / storage statement (for reviewer, if asked)
- No new data collection in 1.0.1; no tracking; `PrivacyInfo.xcprivacy` unchanged.
- Photos/reports stored locally on device; nothing uploaded to a server. 1.0.1 only adds local file hygiene (transient exports + empty-folder cleanup).
- No in-app purchases / payment UI; accounts provisioned via B2B agreement.

## 6. Submit
- [ ] Final review of the version page.
- [ ] **Submit for Review** — only when you're ready (per current instruction: not yet).

## Post-release
- [ ] Reviewer password was previously in git history — rotation (step 1) addresses live risk; consider history scrub only if the repo becomes public.

# Inspectley 1.0.1 — Archive & Upload Checklist (App Store Connect)

Prepared 2026-06-17. **Do not submit until you've completed every box.** Reviewer password lives only in `reviewer-credentials.local.md` (gitignored) and App Store Connect — never in git.

## 0. Pre-flight (already done in repo)
- [x] `MARKETING_VERSION = 1.0.1`, `CURRENT_PROJECT_VERSION = 2` (in `project.yml` and generated `project.pbxproj`).
- [x] `xcodegen generate` run; project in sync with `project.yml`.
- [x] Clean build + 71 Swift Testing tests pass (iPhone 16 sim).
- [x] Real-device share QA passed (PDF/DOCX export → share → file cleaned up).
- [x] `ITSAppUsesNonExemptEncryption = NO` present.
- [x] No plaintext reviewer password committed; `SupabaseConfig.plist` gitignored.

## 1. Reviewer account — VERIFIED 2026-06-17 (no rotation needed)
- [x] Login verified against live Supabase with the existing password (`inspectleyapp@gmail.com`).
- [x] Export entitlement verified: company "Apple Review Account", `export_allowed = true`, `payment_status = active`, `trial_end_date = 2030-12-31` → export is allowed in-app.
- [x] Decision: existing credentials kept unchanged. Password lives only in `reviewer-credentials.local.md` (gitignored) + App Store Connect Sign-In Information.

## 2. Archive
- [ ] Open `InspectorPro.xcodeproj` in Xcode; select **Any iOS Device (arm64)** as destination.
- [ ] Confirm signing: team `H29SVV6K2S`, automatic signing, bundle id `com.aloniter.inspectorpro`.
- [ ] Product → Archive (Release config).
- [ ] (CLI alt) `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -configuration Release -destination 'generic/platform=iOS' -archivePath /tmp/InspectorPro-1.0.1.xcarchive archive`
- [ ] In Organizer, confirm the archive shows version **1.0.1 (2)**.

## 3. Validate & Upload binary
- [ ] Organizer → Distribute App → App Store Connect → Validate. Resolve any validation errors.
- [ ] Upload. Wait for the build to finish processing in App Store Connect (can take 5–60 min).

## 4. App Store Connect — version 1.0.1 page — DONE 2026-06-17
- [x] Created the **1.0.1** version.
- [x] Selected the processed **build 2** (`1.0.1 (2)`) — no Missing Compliance warning.
- [x] **What's New** — Hebrew text from `version-1.0.1-fix-summary.md` §1 entered & saved. (Hebrew is the app's only App Store localization, so no English "What's New" needed.)
- [x] **App Review Information → Sign-In Information**: `inspectleyapp@gmail.com` + password — carried over from v1.0, verified present.
- [x] **App Review Notes** — full B2B / login-required / no-IAP block carried over from v1.0.
- [x] **Screenshots** — carried over automatically from v1.0 (6 iPhone shots: projects, capture, annotate, export, branding, login).
- [x] **Release** — "Automatically release this version" (goes live on approval); rollout to all users immediately (no phased release).
- [x] App Privacy / category / age rating / pricing unchanged from v1.0.

## 5. Privacy / payment / storage statement (for reviewer, if asked)
- No new data collection in 1.0.1; no tracking; `PrivacyInfo.xcprivacy` unchanged.
- Photos/reports stored locally on device; nothing uploaded to a server. 1.0.1 only adds local file hygiene (transient exports + empty-folder cleanup).
- No in-app purchases / payment UI; accounts provisioned via B2B agreement.

## 6. Submit — DONE 2026-06-17
- [x] Final review of the version page.
- [x] **Submitted for Review** — submitted to Apple 2026-06-17 (~4:05 PM GMT+3). Status: **1.0.1 Waiting for Review**. Apple review can take up to 48h; email on completion. Auto-release means it goes live on the App Store once approved.

## Post-release
- [ ] Reviewer password is kept unchanged and still exists in older git history (not in any current tracked file). Rotate + scrub history if repo access ever widens (e.g. open-sourcing).

# Inspectley App Store Readiness

## Current Status: Needs Review

Inspectley is build/test clean on simulator and the major readiness issues found in this pass were fixed. It is not yet ready for App Store submission because a valid Apple-review/test login still needs to be confirmed, a signed Release archive must be validated through Xcode/App Store Connect, and final real-device camera/photo/export QA is still required.

## What Was Checked

- Project structure, XcodeGen configuration, SwiftUI app entry, SwiftData models, project/report/photo flow, export services, authentication services, branding services, resources, localization, and generated Xcode project.
- Debug simulator build, Release simulator build, and Swift Testing suite.
- Built app bundle metadata: display name, bundle identifier, version/build, launch screen, export compliance key, localized permission strings, privacy manifest, Supabase config bundling, and resource inclusion.
- App icon alpha status for the 1024x1024 marketing icon.
- Login-first unauthenticated launch behavior on simulator.
- Supabase/auth, branding sync, export permission gating, logout handling, and failure states from code and simulator behavior.
- PDF/DOCX export paths for missing images, custom branding/logo behavior, RTL OpenXML structure, DOCX template metadata, and generated document relationships.
- Repository exposure of Supabase example configuration and accidental bundling of template/example secrets.

## What Was Fixed

- Auth startup now times out instead of leaving users on an indefinite loading state when session checking stalls.
- Logout now clears local auth UI state, export permission cache, and branding cache immediately before remote sign-out finishes.
- Auth state now stores the current user ID/email for UI flows that need stable account identity.
- Export permission and branding services now fall back to Supabase `currentUser` when async session lookup is unavailable.
- Settings now shows explicit export status failures instead of silently showing only a dash.
- Settings no longer shows visible personal creator/debug text.
- Removed duplicate project-delete alert modifier.
- Supabase base URL validation now rejects service-path URLs and requires a normal Supabase project URL.
- Supabase example config was moved out of app resources and replaced with placeholder values only.
- Export permission gating now uses cache only for offline/transport failures, not for backend data errors.
- Missing profiles/companies now block export with a backend error instead of falling back unsafely.
- Missing export images now fail PDF/DOCX export with a real error instead of producing red placeholders or broken documents.
- Annotated image paths now fall back to the original image if the annotation file is missing.
- Empty/default branding no longer injects bundled/demo logo/footer into user exports.
- Missing custom logo no longer falls back to bundled branding.
- DOCX custom logos now preserve aspect ratio in the header.
- DOCX cover text gained additional RTL markers for Hebrew rendering.
- DOCX template metadata was neutralized to Inspectley-only values.
- Added localized InfoPlist permission strings.
- Added an app privacy manifest.
- Flattened the 1024x1024 app icon so it has no alpha channel.
- Launch screen now uses a static centered app logo.
- Added focused tests for branding fallback, missing image export failure, DOCX logo aspect ratio, and annotated image fallback.

## Remaining Issues

- The provided simulator login account was rejected by the app as an invalid email/password after logout. I did not store the password anywhere. A valid review/test account must be confirmed before TestFlight/App Review.
- Real Supabase export gating and branding sync could not be fully re-verified with that account after the credential rejection.
- Xcode still logs SwiftData/CoreData editable-model checksum warnings during test/app startup. Tests pass, but this should be watched during archive and real-device QA.
- A signed iPhoneOS Release archive has not been created or uploaded in this pass.
- Camera, Photos picker permissions, real-device photo capture/import, and share-sheet export opening still need manual device QA.
- App Store privacy nutrition labels still need to be completed manually in App Store Connect to match the privacy manifest and backend account data use.
- The real `InspectorPro/Resources/SupabaseConfig.plist` is intentionally ignored; every release/archive environment must provide it before running XcodeGen/build.

## App Store Items To Prepare Manually

- Confirm final app name, subtitle, category, age rating, support URL, marketing URL, privacy policy URL, and screenshots in App Store Connect.
- Enter a valid review/test account in App Store Connect Sign-In Information. Do not place credentials in the repository.
- Confirm bundle ID `com.aloniter.inspectorpro`, version `1.0.3`, and build number `1` are the intended upload values. Do not use stale version `1.2.0`.
- Confirm export compliance is correct for the app and dependencies. The app currently declares `ITSAppUsesNonExemptEncryption = false`.
- Complete privacy nutrition labels for account email, backend auth/company data, photos/documents created by users, diagnostics if collected, and any Supabase-related data handling.
- Provide the production `SupabaseConfig.plist` locally before archive/upload.
- Validate final app icon, screenshots, and launch appearance on real devices.

## TestFlight Checklist

- Regenerate the project with `xcodegen generate` on the release machine.
- Build and run `xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro test -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' CODE_SIGNING_ALLOWED=NO`.
- Create a signed Release archive for a real iOS device target.
- Validate the archive in Xcode Organizer before upload.
- Install the TestFlight build on a real iPhone.
- Verify first launch shows login for unauthenticated users.
- Sign in with the confirmed review/test account.
- Create a project, create a report, add findings, import/capture photos, annotate/edit photos, configure branding, export PDF, export DOCX, share/open both exports, refresh account/company status, test offline behavior, and log out.

## App Review Risks

- Invalid or missing review account will likely block review because unauthenticated users land on login.
- If `SupabaseConfig.plist` is missing or points to the wrong project, auth/export gating will fail.
- If Supabase profile/company rows are missing for the review account, export will be blocked by design.
- Privacy labels must match the app's real Supabase/account/photo usage.
- Real-device camera/photo permission copy should be checked in Hebrew and English.
- Archive validation may surface additional required-reason API items from Apple tooling or dependencies.

## Recommended Final Manual QA

- Fresh install on a real iPhone with no prior Keychain/session state.
- Login, force quit, relaunch, and confirm session restoration.
- Logout and confirm immediate return to login.
- Airplane mode launch and export attempt with no valid cached permission.
- Online export after permission refresh.
- PDF/DOCX export with no branding, bundled/default branding, custom logo, and missing-logo cases.
- Hebrew RTL report with long titles, long addresses, numbered findings, bullets, attendees, and mixed Hebrew/English numbers.
- Large report export with many photos to check memory and completion.
- App icon, launch screen, dark mode, language switching, and permission prompts.

## Exact Next Steps Before Upload

1. Confirm or replace the review/test account credentials and verify login on simulator and real device.
2. Confirm the Supabase profile/company rows for that account allow the intended export state.
3. Run `xcodegen generate`.
4. Run the simulator test command above.
5. Create and validate a signed Release archive in Xcode.
6. Upload to App Store Connect/TestFlight.
7. Fill App Store Connect Sign-In Information with the review/test account.
8. Complete privacy labels, screenshots, app metadata, and export compliance.
9. Install the TestFlight build on a real iPhone and complete the checklist.

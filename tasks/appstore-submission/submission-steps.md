# Submission Steps

## 1. Final Local Check

From `/Users/aloniter/Projects/InspectorPro`:

```bash
xcodegen generate
xcodebuild -resolvePackageDependencies -project InspectorPro.xcodeproj -scheme InspectorPro
xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -destination 'id=AA68CADB-2203-4CB3-A38E-1BA44EC9B389' -derivedDataPath /tmp/InspectorPro-AppStore-DD test CODE_SIGNING_ALLOWED=NO
xcodebuild -project InspectorPro.xcodeproj -scheme InspectorPro -configuration Release -destination 'generic/platform=iOS' -archivePath /tmp/InspectorPro-AppStore.xcarchive archive
```

If the simulator id is unavailable, choose any available iPhone simulator and record the destination used.

## 2. Upload Build from Xcode

1. Open `InspectorPro.xcodeproj` in Xcode.
2. Select scheme `InspectorPro`.
3. Select destination `Any iOS Device`.
4. Product > Archive.
5. When Organizer opens, select the new archive.
6. Click `Distribute App`.
7. Choose `App Store Connect`.
8. Choose `Upload`.
9. Let Xcode manage signing automatically.
10. Complete upload.

## 3. Wait for Processing

1. Open App Store Connect.
2. Go to My Apps > Inspectley.
3. Wait until build `1` for version `1.0.0` finishes processing.
4. Select build `1` for the app version.

Apple says uploaded builds need processing time before they appear in App Store Connect.

## 4. Fill App Store Connect

Use the files in this folder:

- `metadata-he.md`
- `metadata-en.md`
- `privacy-answers.md`
- `review-notes.md`
- `screenshot-plan.md`

Required manual fields:

- Privacy Policy URL: `https://aloniter.github.io/inspectley-appstore-pages/privacy.html`
- Support URL: `https://aloniter.github.io/inspectley-appstore-pages/support.html`
- App category
- Age rating
- Pricing/availability
- Contact information
- Screenshots
- App Review credentials and notes

## 5. Submit

1. Confirm all required metadata is complete.
2. Confirm App Privacy answers match `privacy-answers.md`.
3. Confirm screenshots are uploaded.
4. Confirm review credentials are correct, and paste the reviewer password directly into App Store Connect.
5. Confirm both public URLs load without login:
   - `https://aloniter.github.io/inspectley-appstore-pages/privacy.html`
   - `https://aloniter.github.io/inspectley-appstore-pages/support.html`
6. Submit for App Review.

## 6. If Upload Fails Because Build Number Already Exists

If App Store Connect says build `1` already exists for version `1.0.0`:

1. Increment `CURRENT_PROJECT_VERSION` in `project.yml`.
2. Run `xcodegen generate`.
3. Archive again.
4. Upload again.

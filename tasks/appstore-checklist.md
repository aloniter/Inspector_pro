# App Store Readiness Checklist

## 🔴 Blockers (must be done before submission)

- [ ] **Build Supabase auth system** — company registration, login, JWT token storage (Keychain)
- [ ] **Build trial management** — `companies` table in Supabase with `trial_start_at`, `is_active`; check on app launch
- [ ] **Build export lock** — disable export when trial expired / account inactive
- [ ] **Build onboarding / login screens** — `LoginView`, `RegisterView`, first-launch flow
- [ ] **Build trial-expired screen** — show message like "ניסיון חינמי הסתיים — צרו קשר כדי להמשיך" (NO external payment link — Apple will reject)
- [ ] **Publish Privacy Policy** — must be a live URL; covers camera, photos, email, company data
- [ ] **Create Support URL** — website, landing page, or even a GitHub page
- [ ] **Capture App Store screenshots** — required sizes: 6.7" (iPhone 16 Pro Max), recommended: 6.1"
- [ ] **Fill App Store Connect metadata** — app name, subtitle (≤30 chars), description (Hebrew + English), keywords (≤100 chars), category (Business), age rating

## 🟠 Important (polish + quality)

- [ ] **Fix export quality selector** — currently hardcoded to "economical" despite showing a UI; wire it up or remove the selector
- [ ] **Polish launch screen** — replace bare `LaunchScreen.storyboard` with branded screen showing the app icon
- [ ] **Add crash reporting** — Firebase Crashlytics or Sentry; essential for debugging production issues
- [ ] **Add data loss warning in settings** — data is device-only; warn users to back up (or add iCloud sync)
- [ ] **Verify app icon at small sizes** — check it's readable at 60×60pt

## 🟡 Nice to have

- [ ] **In-app review prompt** — call `SKStoreReviewController.requestReview()` after a successful export
- [ ] **Better empty states** — add illustrations + guiding text to project list and photo list
- [ ] **Analytics** — even basic Firebase Analytics helps understand how users use the app

## ⚠️ Apple Guideline Risk Note

The trial-expired screen must NOT include any payment URL, "subscribe here" link, or pricing page link. Apple's guideline 3.1.1 prohibits directing users to external payment for app features. Just show a "contact us" message with no clickable links to external checkout.

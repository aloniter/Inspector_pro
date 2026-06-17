# App Store Rejection — Root Cause & Response (Submission 88a532ae, v1.0 build 3)

Review date: 2026-06-14 · Review device: iPad Air (5th gen) · Two items: **2.3.10** (screenshots) and **2.1(b)** (business model / info needed).

---

## Root cause

### 2.3.10 — Non‑iOS status bar in screenshots  (HIGH confidence)
The submitted screenshots were **marketing mockups**, not genuine device captures. They were rendered with the
React/Figma device-frame tool in `inspectley_login/ios-frame.jsx` (`IOSStatusBar`, "Based on the iOS 26 UI Kit + Figma
status bar spec"). On screenshots `01/02/04/05` that synthetic bar drew the cellular signal as four **equal-height
vertical bars** with no proper iOS Wi‑Fi/cellular glyphs — which reads as an Android / non‑iOS status bar. That is the
"information about third‑party platforms" Apple flagged.

**Fix applied:** replaced all 6 with genuine in-app iPhone captures (real iOS status bar), resized to App Store slots.
- New assets: `AppStore/screenshots/iphone-6.9/` (1320×2868, required) and `AppStore/screenshots/iphone-6.5/` (1242×2688).
- Old mockups archived at `AppStore/screenshots/_rejected_mockups_65/`.

### 2.1(b) — "App may include paid digital content/services"  (HIGH confidence on trigger, LOW risk to approval)
Apple's automated/first-pass signals: login-only (no in-app sign-up), "team / company-managed accounts", a server-side
**trial/expiry/suspended** account status, and **report export gated** by that status
(`ExportPermissionService` → Supabase `companies.payment_status`, `trial_end_date`, `export_allowed`; UI message
"trial ended — contact management to activate the account"). That pattern looks like a paid service unlocked outside IAP.

**Reality (verified in code):** there are **no** in‑app purchases, prices, subscriptions, paywalls, upgrade buttons, or
external checkout/payment links anywhere. The only "payment" token is the backend field name `payment_status`, never shown
as a price. This is a **B2B / enterprise** tool: inspection *companies* license it directly; their inspectors just log in.
That is allowed without IAP (Guideline 3.1.3 Enterprise Services / Free Stand‑alone App). 2.1(b) is an information hold,
answerable by reply — **no binary change required**.

---

## Build vs metadata
- **No new build required.** Screenshots = metadata-only. 2.1(b) = written reply (+ optional description wording).
- Verified the shipping target `com.aloniter.inspectorpro` is `TARGETED_DEVICE_FAMILY = 1` (iPhone-only); only the
  *test* target carries `1,2`. The iPad Air review is just Apple running an iPhone-only app in compat mode — not a defect.

---

## Recommended reply to App Review (paste into App Store Connect → Resolution Center)

```
Hello, and thank you for the review.

GUIDELINE 2.3.10 — SCREENSHOTS
We have replaced all screenshots with genuine captures taken directly on iPhone running the app. They show the real iOS
status bar and only the app's own UI. The previous images used a marketing device-frame mockup whose status bar did not
match iOS; that was unintentional and has been corrected. Inspectley is iPhone-only (portrait), and there are no
references to Android, web, desktop, or any third-party platform in the app or its metadata.

GUIDELINE 2.1(b) — BUSINESS MODEL
Inspectley is a free business-to-business (B2B) tool for professional building-inspection companies. Answers to your
questions:

1) Who uses the services: Employees (inspectors) of professional inspection/engineering firms. The customer is the
   company, not individual consumers.

2) Where services are purchased: Nowhere on Apple's platform and nowhere inside the app. A firm licenses Inspectley
   directly from us through a separate, offline B2B commercial agreement (direct invoicing). Individual users never buy
   anything, in or out of the app.

3) What previously purchased services a user can access: None are purchased by the user. Once a firm's account is active,
   its inspectors log in and use the core features — create projects/reports, capture and annotate photos, and export a
   PDF or DOCX report. No digital content, credits, or upgrades are sold to or unlocked by the user.

4) Paid content/subscriptions/features unlocked without IAP: None for consumers. The app contains no in-app purchases,
   prices, subscriptions, paywalls, or external purchase links. Report export is enabled or disabled centrally based on
   whether the employing company's B2B account is active — an enterprise account-status check, not a consumer purchase.
   This follows the enterprise / free stand-alone model described in Guideline 3.1.3.

5) Sold to single users, consumers, or family use: Sold to businesses/organizations only (B2B enterprise). Not to
   single consumers and not for family use.

Additional context: all inspection projects, reports, and photos are stored locally on the device. Supabase is used only
for authentication, company branding, and the account-active (export) authorization check — no inspection content is
uploaded. The demo account provided in App Review Information is fully active (export enabled through 2030), so no
"contact your administrator" state appears during review.

We're happy to provide anything else that helps. Thank you!
```

## Optional hardening (NOT required for approval; future build)
- Reframe user-facing "trial / ניסיון" wording toward "account status / license" to avoid future consumer-IAP confusion.
- Ensure the **live** App Store description carries the explicit B2B line (already in SUBMISSION-PACKAGE §2/§3):
  "Inspectley is a business tool. Your account is provided and managed by your organization. There are no in-app
  purchases — access is handled through your company." (The shorter `metadata-en.md`/`metadata-he.md` lack it.)

## Fastest path to approval
1. In Media Manager, replace iPhone screenshots with `iphone-6.9/` (and 6.5" if that slot is populated). No new build.
2. Confirm the live description includes the explicit "no in-app purchases / managed by your organization" line.
3. Post the reply above in Resolution Center. Submit for review (same build is fine).

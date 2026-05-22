# App Privacy Answers

Use these answers in App Store Connect for the current `main` implementation.

## Tracking

Does this app use data to track users?

Answer: No

Reason: The app does not use advertising SDKs, IDFA, data brokers, cross-app tracking, or third-party advertising measurement.

## Data Collection

Does this app or its third-party partners collect data from this app?

Answer: Yes

## Data Types

### Contact Info - Email Address

- Collected: Yes
- Linked to the user: Yes
- Used for tracking: No
- Purpose: App Functionality

Why: Supabase Auth uses the user's email address for login and account access.

## Data Not Collected by Current App Code

Do not mark these as collected unless backend behavior changes:

- Photos: inspection photos are stored locally on device and exported by explicit user action.
- User Content: project names, report details, descriptions, and annotations are stored locally on device.
- Location: the app does not request device location.
- Contacts: the app does not request the user's contacts.
- Identifiers for tracking: not used.
- Usage data / diagnostics / analytics: no analytics or crash reporting SDK is currently integrated.

## Supabase Usage

Supabase is used for:

- Authentication
- Company profile lookup
- Company branding lookup
- Export permission/trial/account status lookup

Relevant tables used by current code:

- `profiles`
- `companies`

The app reads company/profile data for app functionality. It does not upload inspection photos, reports, or project records in the current implementation.

## Required Reason API Privacy Manifest

The included `PrivacyInfo.xcprivacy` declares:

- `NSPrivacyAccessedAPICategoryUserDefaults`
  - Reason: `CA92.1`
- `NSPrivacyAccessedAPICategoryFileTimestamp`
  - Reason: `C617.1`

## Permission Purpose Strings

Camera:

`Camera access is needed to capture project photos.`

Hebrew:

`המצלמה נדרשת לצילום תמונות לפרויקט`

Photo Library:

`Photo library access is needed to import project photos.`

Hebrew:

`גישה לגלריה נדרשת לייבוא תמונות לפרויקט`

## Privacy Policy Must Mention

- Account email is used for login.
- Supabase is used for authentication and account/company authorization.
- Company branding and export permission status are fetched from Supabase.
- Inspection projects, report details, and photos are stored locally on the user's device unless the user shares/exports them.
- The app does not sell data.
- The app does not track users across apps or websites.
- The app does not include ads.

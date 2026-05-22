# App Review Notes

Paste this into the App Review Notes field in App Store Connect.

```text
This app requires login. Please use the review account below.

Email: inspectleyapp@gmail.com
Password: [paste the reviewer password directly in App Store Connect; do not commit it to git]

The review account is configured with an active trial and export permission.

Inspectley is an inspection report app. Users create local projects/reports, add inspection photos, annotate photos, and export reports as PDF or DOCX.

Supabase is used for:
- User authentication
- Company branding
- Export authorization / trial status

Inspection projects, report descriptions, and photos are stored locally on the device in the current app version. The app does not upload inspection photos or report files to Supabase.

There are no external purchase, payment, subscription, or checkout links in the app. If an account is expired or export is disabled, the app only shows a contact/support message.

To review export:
1. Log in with the review account.
2. Create a project.
3. Create a report.
4. Add or import a photo.
5. Open export and choose PDF or DOCX.
6. Confirm the exported file appears in the iOS share sheet.
```

## Reviewer Account Backend Requirements

Before submitting, verify this account in Supabase:

- Auth user exists for `inspectleyapp@gmail.com`
- `profiles.id` matches the auth user id
- `profiles.company_id` points to an existing `companies.id`
- `companies.export_allowed = true`
- `companies.payment_status = trial` with a future `trial_end_date`, or another allowed active status recognized by the backend
- Company branding fields used by the app are non-null or safely populated

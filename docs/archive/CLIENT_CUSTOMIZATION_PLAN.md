# Client Customization Plan

## Baseline Rule

The current tester build is the baseline and should remain stable. Client customization work should build on the shipped branding v1 behavior instead of redesigning the export system before it is necessary.

## Current Foundation

### Implemented

- Branding v1 exists in the data model through `BrandingProfile`.
- A default branding profile is automatically created and linked to projects that do not already have branding.
- New projects are created with the default branding profile when available.
- Manual branding editing is available from Settings.
- Editable fields today:
- company name
- logo image
- footer address line
- primary footer contact line
- secondary footer contact line
- Both PDF and DOCX exporters resolve branding through the same shared layer.
- The bidi/footer handling changes are already in place for mixed Hebrew/LTR contact details.

### Partially Implemented

- The schema already supports multiple branding profiles and per-project links.
- The UI does not yet expose multi-client profile management.
- The editable company name is stored, but the current exports do not surface it visibly.
- Branding changes are effectively global because the default profile is shared broadly.

### Pending

- Client-specific profile creation and management.
- Explicit project-level client/profile selection.
- Safe duplication/cloning flow so one client change does not affect another.
- Historical export protection or snapshotting if brand identity must remain frozen per report/project.

## Recommended Next Phases

### Phase 1: Harden Branding V1

- Keep the existing export geometry unchanged.
- Decide whether the company name should appear in export output or be removed from the editable surface until it is used.
- Add a simple read-only “applies to all branded exports” explanation in the branding UI when product changes resume.
- Add focused regression verification for branding changes in both PDF and DOCX.

### Phase 2: Introduce Client Profiles

- Add profile list/create/rename/duplicate/delete flows.
- Keep one explicit default profile for new projects.
- Allow projects to choose a branding profile without altering the rest of the report structure.
- Migrate carefully so current tester data keeps resolving to the same default branding unless changed intentionally.

### Phase 3: Add Safer Change Management

- Add preview-before-save for branding updates.
- Decide whether completed projects should keep live branding links or store frozen export-brand snapshots.
- Add clearer auditability around when branding changed and which exports used which profile.

## Known Risks

- Changing the current default branding can retroactively change exports for existing linked projects.
- Client customization pressure can easily turn into export-layout churn; that would put the tester baseline at risk.
- Because company name is not currently rendered in exports, users may assume a branding change took effect when only logo/footer content actually changed.
- Mixed-direction footer content is now more stable, but any future shift back toward raw free-text footer editing would likely reintroduce bidi problems.

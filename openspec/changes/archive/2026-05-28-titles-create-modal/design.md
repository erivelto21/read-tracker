## Context

The titles list screen (`TitlesPage.tsx`) already renders a table with an "Add" button wired to an empty `onAddClick` callback. The backend `POST /v1/titles` endpoint is fully implemented. The gap is purely the frontend: no modal, no API call, no mutation hook exists yet.

The frontend stack is React 18 + TypeScript + Tailwind CSS v4 + React Query v5 + Axios. No animation library or form library is available — only `clsx` for class composition. The existing `SegmentedControl` component covers multi-option selection and matches the type-picker use case.

## Goals / Non-Goals

**Goals:**
- A two-step modal: step 1 picks the title type, step 2 fills in the relevant fields
- Conditional field visibility — only show fields required/relevant for the selected type
- Hybrid validation — client-side required checks before submit; server error details rendered inline per-field
- Top-level error banner for conflict (409) and unexpected errors (500)
- Close modal and refresh the list on success

**Non-Goals:**
- Toast/snackbar notifications on success
- Draft persistence (closing modal discards state)
- Edit or delete flows (separate concern)
- Backend changes of any kind

## Decisions

### Two-step flow over a flat conditional form

A flat form with show/hide fields is technically simpler but forces the user to scan irrelevant controls. Selecting the type first makes step 2 fully predictable — every visible field is required or meaningful for that type. The step-back affordance (`← Back`) preserves the type choice if the user wants to change it.

Alternatives considered: accordion sections per type, inline type-switch with animated fields. Both add complexity without improving clarity.

### Plain React state — no form library

The form has at most 5 fields. `react-hook-form` or similar would introduce a dependency for minimal gain. Modal state is local: `step`, `selectedType`, `fieldValues`, `fieldErrors`, `topLevelError`, `isSubmitting`. All managed with `useState`.

### Hybrid validation

Client side checks only the obvious: required fields (non-empty string / non-null number). Everything else — min/max, URL format, conditional rules — is trusted to the server. Server `details` array is mapped to field errors on a `4xx` response.

Rationale: duplicating all the conditional `required_if` rules on the client is fragile and diverges over time. The round trip cost is acceptable for a create form.

### Field name normalisation

The server returns `{ "field": "Name" }` — Go struct field names, PascalCase. The frontend form keys are camelCase / lowercase (`name`, `chapter`, etc.). Mapping: `detail.field.toLowerCase()` covers all current fields without a lookup table.

Risk: a future multi-word field like `SomeLong` would map to `somelong`, not `someLong`. Acceptable for now; revisit if the field set grows.

### Post-success behaviour

On `201 Created`: invalidate `queryKeys.titles.all()` via React Query's `queryClient` so the list refetches with the new entry, then close the modal and reset form state. No toast — the new row appearing in the table is sufficient feedback.

## Risks / Trade-offs

- **Field name mapping fragility** — `toLowerCase()` works for all single-word field names. Multi-word PascalCase fields would need a mapping table. → Mitigation: document the convention; the backend field set is small and stable.
- **No focus trap** — a proper modal should trap keyboard focus. Implementing a full focus trap adds ~40 lines with no library. → Mitigation: add `autoFocus` to the first interactive element in each step; full trap can be added later with a `useFocusTrap` hook.
- **Escape key not handled** — closing on `Escape` is a UX expectation. → Mitigation: add a `keydown` listener on the modal that calls `onClose` when `key === "Escape"`.

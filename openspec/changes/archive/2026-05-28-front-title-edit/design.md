## Context

The backend already exposes `PATCH /v1/titles/:id` accepting partial updates for `chapter`, `page`, `link`, and `observation`. The frontend has no way to call this endpoint. The existing `CreateTitleModal` establishes the pattern: a two-step modal (type selector → fields) with per-type conditional field rendering and inline error handling. The edit flow is simpler — type is immutable, so there is no step 1.

The `TitleRow` component already has a delete icon that appears on row hover (`opacity-0 group-hover:opacity-100`). The edit icon will follow the exact same pattern and sit to its left.

## Goals / Non-Goals

**Goals:**
- Add an edit icon to `TitleRow` (left of delete), visible on hover.
- `EditTitleModal`: single-step modal, pre-filled with current values, shows only fields relevant to the title's type.
- Partial update semantics: only send fields that have a non-empty value in the form.
- `useUpdateTitle` hook and `updateTitle` API function following the existing delete/create patterns.
- Add `UpdateTitlePayload` type.
- On success: close modal and invalidate the titles query.

**Non-Goals:**
- Changing `name` or `type` (not supported by the API).
- Adding an update endpoint to the backend (already exists).
- Editing from any screen other than the titles list.

## Decisions

### Decision: Separate `EditTitleModal` component, not a mode of `CreateTitleModal`

`CreateTitleModal` is a two-step wizard (type-selection → fields). The edit flow is a single step that starts with a known type and pre-populated values. Trying to unify them would add conditional branching that obscures both flows. A dedicated `EditTitleModal` keeps both components simple and independently testable.

**Alternatives considered:**
- Extend `CreateTitleModal` with an `initialTitle` prop and skip step 1 — rejected because the component's internal state machine assumes step 1 is always first; adapting it would complicate the existing flow without adding reuse value.

### Decision: `visibleFields` / `requiredFields` logic stays in each modal (no shared util for now)

The logic is small (~10 lines per function). Extracting it to a shared utility is premature until a third consumer exists. If a third consumer appears, extract to `src/features/titles/utils/titleFields.ts`.

### Decision: Edit state managed in `TitleTable`, not `TitleRow`

`TitleTable` already owns the delete mutation (`useDeleteTitle`). Keeping `editingTitle: Title | null` state in `TitleTable` is consistent with the existing pattern. `TitleRow` receives `onEdit?: (title: Title) => void` and is kept stateless regarding the modal.

### Decision: Partial update semantics — only send non-empty fields

Fields are pre-populated with the current title values. If the user clears a field, it is excluded from the PATCH payload (treated as "no change"). This avoids sending empty strings that would fail API validation. There is no explicit "clear this field" affordance — the API does not support nullifying optional fields, and the product does not need it yet.

## Risks / Trade-offs

- [Risk]: Users might expect clearing a field to remove its value, but it will be silently ignored.
  → Mitigation: The fields are always pre-populated; clearing is an unusual action. Accept for now; revisit if user feedback indicates confusion.

- [Risk]: `visibleFields` logic duplicated between `CreateTitleModal` and `EditTitleModal`.
  → Mitigation: Duplication is contained (~10 lines). Extract when a third consumer appears.

## Migration Plan

No data migration required. The change is additive UI-only. Deployment is a standard frontend build + push; the backend is unchanged.

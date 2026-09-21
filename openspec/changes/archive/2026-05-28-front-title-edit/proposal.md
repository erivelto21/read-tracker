## Why

Users have no way to update a title's progress (chapter, page, link, observation) from the UI — they can only create or delete. The backend already exposes `PATCH /v1/titles/:id`, so this is a frontend gap that blocks everyday usage.

## What Changes

- Add an edit (pencil) icon to each `TitleRow`, displayed to the left of the existing delete icon, visible on row hover.
- Clicking the edit icon opens a new `EditTitleModal` pre-filled with the title's current values.
- The modal shows only the fields that are editable for the title's type (no type-selection step since type is immutable).
- On save, the modal calls `PATCH /v1/titles/:id` with only the non-empty fields (partial update).
- On success, the modal closes and the titles list is refreshed.
- Add `useUpdateTitle` hook and `updateTitle` API function mirroring the existing delete pattern.
- Add `UpdateTitlePayload` type to the shared types file.

## Capabilities

### New Capabilities

- `title-edit`: Frontend capability for partially updating an existing title's mutable fields (chapter, page, link, observation) via a type-aware modal triggered from the titles list.

### Modified Capabilities

- `titles-list-screen`: The titles list row gains a new action button (edit icon), and the actions column widens to accommodate two icons.

## Impact

- **Frontend only** — no backend changes required; `PATCH /v1/titles/:id` already exists.
- **Files touched**: `TitleRow.tsx`, `TitleTable.tsx`, `types.ts`, `src/api/titles.ts`
- **New files**: `EditTitleModal.tsx`, `useUpdateTitle.ts`
- No breaking changes; existing create and delete flows are unaffected.

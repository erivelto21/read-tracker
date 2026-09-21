## Why

The Read Tracker has a working API for titles but no UI yet. Users need a screen to view and browse their tracked titles with basic filtering, making the app usable beyond raw API calls.

## What Changes

- Add a `TitlesPage` route at `/titles` in the frontend.
- Add a toolbar with a live-search name input (debounced ~300ms) and a type select (`All | book | manga | manhua | novel | article`) that compose filters with AND logic — no explicit submit button.
- Add a table showing columns: **Name**, **Type**, **Chapter**, **Page**, **Status** (hardcoded placeholder `"Reading"` for now).
- Wire the filters to `GET /titles?name=…&type=…` via a `useListTitles` hook backed by TanStack Query.
- Apply a light-blue (`sky-*`) + black Tailwind colour theme throughout the screen.

## Capabilities

### New Capabilities

- `titles-list-screen`: The titles list UI — page shell, toolbar with live filters, and a data table displaying name, type, chapter, page, and a placeholder status column.

### Modified Capabilities

<!-- No existing spec-level requirements are changing. The API already supports GET /titles with name/type query params. -->

## Impact

- **Frontend only** — all changes are inside `front/src/`.
- New files: `src/pages/TitlesPage.tsx`, `src/features/titles/components/TitleTable.tsx`, `src/features/titles/hooks/useListTitles.ts` (if not already present), `src/api/titles.ts` additions.
- No backend, API contract, or database changes required.
- Depends on the existing `GET /titles` endpoint returning `{ "titles": [...] }` (as established by the `title-list-response-struct` change).

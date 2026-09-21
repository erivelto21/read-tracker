## Context

The Read Tracker frontend (`front/`) is a blank-slate React + TypeScript + Tailwind 4 app. The backend already exposes `GET /titles?name=…&type=…` returning `{ "titles": [...] }`. This design covers how to structure the titles list screen within the existing project conventions defined in `front/AGENTS.md`.

## Goals / Non-Goals

**Goals:**
- Render a `/titles` route with a live-filter toolbar and a data table.
- Keep filter state local (no URL sync) for this first iteration.
- Follow the layered architecture: `pages/` → `features/titles/` → `api/`.
- Apply a consistent `sky-*` + black colour palette via Tailwind utility classes.

**Non-Goals:**
- URL-based filter persistence (bookmarkable URLs) — future iteration.
- Row click / title detail navigation — not in scope.
- Real status tracking — status column is a hardcoded placeholder (`"Reading"`).
- Pagination or infinite scroll — list all titles returned by the API.
- Creating, editing, or deleting titles from this screen.

## Decisions

### 1. Filter state in React local state, not URL
**Decision:** `useState` for `name` and `type` filter values inside `TitlesPage`.
**Rationale:** Simplest approach for a v1 screen. URL params add routing complexity (React Router `useSearchParams`) that isn't needed until sharing/bookmarking is a requirement. Easy to migrate later.
**Alternative considered:** `useSearchParams` — deferred; complexity not justified yet.

### 2. Debounce name input at the hook level
**Decision:** Debounce the `name` filter value ~300ms inside `useListTitles` (or via a `useDebounce` utility), so the query key only changes after the user pauses typing.
**Rationale:** Avoids a network request on every keystroke. The `type` select fires immediately (single selection, no typing).
**Alternative considered:** Debounce inside the component — rejected to keep components pure renderers per AGENTS.md.

### 3. Type select includes "All" as empty string
**Decision:** The select's "All" option maps to `type: ""`. When `type` is empty, omit the param from the API request.
**Rationale:** Clean API calls — no `?type=` empty param. Backend simply returns all types when the param is absent.

### 4. Table layout over card grid
**Decision:** Render titles as an HTML `<table>` with columns: Name, Type, Chapter, Page, Status.
**Rationale:** Five comparable fields map naturally to columns; a table makes scanning and comparison easy. Cards would waste horizontal space and obscure the column relationship.

### 5. Component split: `TitlesPage` → `TitleTable` → `TitleRow`
**Decision:**
```
pages/TitlesPage.tsx          ← route shell; owns filter state
  features/titles/
    components/
      TitleTable.tsx           ← receives titles[], renders table + empty state
      TitleRow.tsx             ← renders a single <tr>
    hooks/
      useListTitles.ts         ← TanStack Query; accepts { name, type } filter
api/titles.ts                  ← listTitles(filter) → GET /titles
```
**Rationale:** Matches the layer responsibilities in AGENTS.md. `TitlesPage` is a thin shell; `TitleTable` is a pure rendering component; `useListTitles` owns all data-fetching concerns.

### 6. Colour system via Tailwind `sky-*` palette
**Decision:**
| Element | Class |
|---|---|
| Page background | `bg-sky-100` |
| Toolbar bar | `bg-sky-200` |
| Table header | `bg-sky-300` |
| Even rows | `bg-white` |
| Odd rows | `bg-sky-50` |
| Row hover | `hover:bg-sky-100` |
| Text | `text-black` / `text-gray-900` |
| Input / Select focus ring | `focus:ring-sky-400` |

**Rationale:** Unified, accessible blue-on-white palette. All expressed in Tailwind utilities — no custom CSS.

## Risks / Trade-offs

- **No pagination** → could be slow with a large title list. Mitigation: acceptable for v1; add pagination when list grows.
- **Local filter state** → filters reset on page navigation. Mitigation: acceptable for v1; URL sync is a clear next step.
- **Hardcoded status** → "Reading" for every row may be confusing. Mitigation: column header or tooltip indicates it is a placeholder until real status is modelled.
- **Generated types not yet present** → `src/api/generated.ts` doesn't exist yet; `listTitles` will need a manual type until `npm run api:gen` is run. Mitigation: define a local `Title` interface in `src/features/titles/types.ts` that mirrors the API shape and replace it once generation is wired up.

## Why

The titles list screen exists but offers no way to add new titles from the UI. Users must call the API directly to create entries, making the application unusable as a standalone product.

## What Changes

- Add a two-step modal to the titles list screen for creating a new title
- Step 1: user selects the title type (book, manga, manhua, novel, article)
- Step 2: user fills in the fields relevant to that type (name, chapter, page, link, observation)
- Inline field-level error display driven by server validation responses (`400` details array)
- Top-level error banner for conflict (`409`) and unexpected server errors (`500`)
- On success: modal closes and the titles list refreshes automatically
- Add `createTitle` function to the API client layer
- Add `useCreateTitle` mutation hook using React Query

## Capabilities

### New Capabilities

_(none — the create endpoint already exists and is fully specced)_

### Modified Capabilities

- `title-creation`: Add frontend modal requirements — step-by-step flow, conditional field visibility by type, client-side hybrid validation, and server error rendering in the UI

## Impact

- **Frontend only** — no backend changes required
- Files changed: `front/src/api/titles.ts`, `front/src/features/titles/types.ts`, `front/src/features/titles/hooks/useCreateTitle.ts`, `front/src/features/titles/components/CreateTitleModal.tsx`, `front/src/pages/TitlesPage.tsx`
- No new dependencies — uses existing React Query, Axios, Tailwind CSS, and `clsx`

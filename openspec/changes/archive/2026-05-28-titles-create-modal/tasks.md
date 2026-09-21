## 1. API & Types

- [x] 1.1 Add `CreateTitlePayload` interface to `front/src/features/titles/types.ts`
- [x] 1.2 Add `createTitle(payload: CreateTitlePayload)` function to `front/src/api/titles.ts`

## 2. Mutation Hook

- [x] 2.1 Create `front/src/features/titles/hooks/useCreateTitle.ts` with a React Query `useMutation` that calls `createTitle` and invalidates `queryKeys.titles.all()` on success

## 3. Modal Component

- [x] 3.1 Create `front/src/features/titles/components/CreateTitleModal.tsx` with modal skeleton (backdrop, card, close button, Escape key handler)
- [x] 3.2 Implement step 1 — type selector using the existing `SegmentedControl` component; disable "Next" until a type is selected
- [x] 3.3 Implement step 2 — render conditional fields based on selected type (name always, chapter for all except article, page for book only, link for manga/manhua/novel, observation always)
- [x] 3.4 Add client-side required-field validation on submit (prevent network request if empty required fields)
- [x] 3.5 Map server `400` `details` array to inline per-field errors (`detail.field.toLowerCase()` → field key)
- [x] 3.6 Render top-level error banner for `409 Conflict` (message from `error.message`) and `500` errors
- [x] 3.7 Show loading/disabled state on the submit button while the mutation is in-flight
- [x] 3.8 Clear a field's inline error when the user modifies that field's value

## 4. Wiring

- [x] 4.1 Add modal open/close state to `front/src/pages/TitlesPage.tsx` and pass `onOpen` to the existing `onAddClick` prop
- [x] 4.2 Render `<CreateTitleModal>` in `TitlesPage` and wire `onClose` / `onSuccess` callbacks

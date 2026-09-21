## 1. Types and API Layer

- [x] 1.1 Add `UpdateTitlePayload` type to `front/src/features/titles/types.ts` with optional fields: `chapter`, `page`, `link`, `observation`
- [x] 1.2 Add `updateTitle(id: string, payload: UpdateTitlePayload): Promise<{ data: Title }>` function to `front/src/api/titles.ts` calling `PATCH v1/titles/:id`

## 2. Hook

- [x] 2.1 Create `front/src/features/titles/hooks/useUpdateTitle.ts` with a `useMutation` that calls `updateTitle` and invalidates `queryKeys.titles.all()` on success

## 3. EditTitleModal Component

- [x] 3.1 Create `front/src/features/titles/components/EditTitleModal.tsx` accepting `title: Title` and `onClose: () => void` props
- [x] 3.2 Implement `visibleFields(type)` returning the editable fields per type: book → `[chapter, page, observation]`; manga/manhua/novel → `[chapter, link, observation]`; article → `[observation]`
- [x] 3.3 Initialise form state pre-filled from the `title` prop values
- [x] 3.4 Render the modal header showing the title name and type as read-only context (no type-selection step)
- [x] 3.5 Render only the fields returned by `visibleFields`, using the same input types as `CreateTitleModal` (number for chapter/page, url for link, text for observation)
- [x] 3.6 On submit, build the PATCH payload including only non-empty fields; call `useUpdateTitle` mutation
- [x] 3.7 Map server `400` field-level errors to inline field errors below each input; clear error when user edits the field
- [x] 3.8 Display a top-level error banner for `500` or other non-field errors
- [x] 3.9 On success (`200 OK`), close the modal and reset form state
- [x] 3.10 Close modal on Escape key and backdrop click (same as `CreateTitleModal`)
- [x] 3.11 Disable the Save button and show a loading label while the mutation is pending

## 4. TitleRow — Edit Icon

- [x] 4.1 Add `onEdit?: (title: Title) => void` prop to `TitleRow`
- [x] 4.2 Render a pencil SVG icon button to the LEFT of the existing delete button, with the same `opacity-0 group-hover:opacity-100` hover-reveal styling and a blue hover colour (`hover:text-sky-600 hover:bg-sky-50`)
- [x] 4.3 On click, call `e.stopPropagation()` then `onEdit?.(title)`
- [x] 4.4 Widen the Actions `<th>` and `<td>` from `w-10` to `w-20` to accommodate both icons

## 5. TitleTable — Wire Up

- [x] 5.1 Add `editingTitle: Title | null` state to `TitleTable` (initially `null`)
- [x] 5.2 Pass `onEdit={(title) => setEditingTitle(title)}` to each `TitleRow`
- [x] 5.3 Render `<EditTitleModal>` when `editingTitle` is non-null, passing `title={editingTitle}` and `onClose={() => setEditingTitle(null)}`

## 6. Exports

- [x] 6.1 Export `EditTitleModal` from `front/src/features/titles/index.ts` (if the barrel file exports other components)

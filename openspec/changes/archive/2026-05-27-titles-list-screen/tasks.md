## 1. Project Scaffolding

- [x] 1.1 Run `npm install` inside `front/` to ensure dependencies are ready
- [x] 1.2 Create `src/features/titles/` directory structure: `components/`, `hooks/`, `index.ts`, `types.ts`
- [x] 1.3 Define a local `Title` interface in `src/features/titles/types.ts` mirroring the API shape (`id`, `name`, `type`, `chapter`, `page`, `link`, `observation`)
- [x] 1.4 Define `TitleType` constant and type in `src/features/titles/types.ts`: `book | manga | manhua | novel | article`

## 2. API Layer

- [x] 2.1 Create `src/api/client.ts` with an Axios instance using `getEnv('VITE_API_URL')` as `baseURL`
- [x] 2.2 Create `src/api/titles.ts` with a `listTitles(filter: { name?: string; type?: string })` function calling `GET /titles` and returning `{ titles: Title[] }`

## 3. Query Hook

- [x] 3.1 Create `src/lib/queryClient.ts` with the TanStack Query `QueryClient` instance
- [x] 3.2 Create `src/lib/queryKeys.ts` with `queryKeys.titles.list(filter)` key factory
- [x] 3.3 Create a `useDebounce<T>(value: T, delay: number): T` utility hook in `src/hooks/useDebounce.ts`
- [x] 3.4 Create `src/features/titles/hooks/useListTitles.ts` that accepts `{ name: string; type: string }`, debounces `name` ~300ms, omits empty params from the query, and uses TanStack Query to call `listTitles`

## 4. Table Components

- [x] 4.1 Create `src/features/titles/components/TitleRow.tsx` rendering a `<tr>` with cells: Name, Type, Chapter (`—` if absent), Page (`—` if absent), Status (hardcoded `"Reading"`)
- [x] 4.2 Create `src/features/titles/components/TitleTable.tsx` rendering a `<table>` with header row (Name, Type, Chapter, Page, Status) and mapping titles to `<TitleRow>` components; include empty-state message when `titles` is empty
- [x] 4.3 Apply `sky-*` Tailwind classes to the table: `bg-sky-300` header, alternating `bg-white` / `bg-sky-50` rows, `hover:bg-sky-100` on rows

## 5. Page Shell

- [x] 5.1 Create `src/pages/TitlesPage.tsx` with local `useState` for `name: string` and `type: string` filter values
- [x] 5.2 Add name filter `<input>` (top-left) with `placeholder="Filter by name…"` and `onChange` wired to the `name` state; style with `bg-white focus:ring-sky-400`
- [x] 5.3 Add type filter `<select>` (top-right) with options `All, book, manga, manhua, novel, article` wired to the `type` state
- [x] 5.4 Pass `{ name, type }` to `useListTitles` and render `<TitleTable>` with the returned titles
- [x] 5.5 Render a loading indicator while `isLoading` is true
- [x] 5.6 Render a visible error message while `isError` is true
- [x] 5.7 Apply page background `bg-sky-100` and toolbar background `bg-sky-200` via Tailwind

## 6. App Wiring

- [x] 6.1 Create `src/main.tsx` wrapping the app in `QueryClientProvider` with the shared `queryClient`
- [x] 6.2 Add a `/titles` route in the router (React Router) pointing to `TitlesPage`
- [x] 6.3 Export `TitleTable`, `TitleRow`, and `useListTitles` from `src/features/titles/index.ts`

## 7. Tests

- [x] 7.1 Add a `renderWithProviders` test utility in `src/utils/test-utils.tsx`
- [x] 7.2 Write a Vitest + RTL test for `TitleTable`: renders rows correctly, shows empty-state when titles array is empty
- [x] 7.3 Write a Vitest + RTL test for `TitlesPage`: shows loading state, shows error state, renders table when data loads (use MSW handler for `GET /titles`)
- [x] 7.4 Write a test for `useDebounce`: value updates only after delay
- [x] 7.5 Run `npm run lint` and `npm run type-check` — fix any errors

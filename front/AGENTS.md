# Copilot Coding Agent Instructions

This document provides instructions for AI coding agents working on the `front/` project.

## Project Overview

This is the React/TypeScript frontend for the **Read Tracker** application. It allows users to manage their reading progress across books, manga, manhuas, novels and articles.

The frontend talks to the `tracker/` Go API (see `tracker/AGENTS.md` for the API contract).

## Technology Stack

| Layer                      | Technology                     | Version             |
| :------------------------- | :----------------------------- | :------------------ |
| **Language**               | TypeScript                     | `5.x` (strict mode) |
| **UI Framework**           | React                          | `18+`               |
| **Build Tool**             | Vite                           | `5.x`               |
| **Styling**                | Tailwind CSS                   | `4.x`               |
| **Server State**           | TanStack Query (React Query)   | `5.x`               |
| **HTTP Client**            | Axios                          | `1.x`               |
| **Unit/Integration Tests** | Vitest + React Testing Library | latest              |
| **API Mocking**            | MSW (Mock Service Worker)      | `2.x`               |
| **E2E Tests**              | Playwright                     | latest              |
| **Linter**                 | ESLint                         | `9.x` (flat config) |
| **Formatter**              | Prettier                       | `3.x`               |
| **Git Hooks**              | Husky + lint-staged            | latest              |

## Directory Structure

```
front/
├── src/
│   ├── api/
│   │   ├── client.ts          # Axios instance — the only place with baseURL/headers
│   │   ├── generated.ts       # Auto-generated from Swagger — NEVER edit manually
│   │   └── titles.ts          # Typed API functions wrapping generated types
│   │
│   ├── features/              # Feature modules — this is where most code lives
│   │   └── titles/
│   │       ├── components/    # TitleCard, TitleForm, TitleList, etc.
│   │       ├── hooks/         # useListTitles, useCreateTitle, useUpdateTitle
│   │       ├── types.ts       # Feature-local types (if any beyond generated)
│   │       └── index.ts       # Public exports only — never import internals from outside
│   │
│   ├── components/            # Shared/reusable UI components (Button, Modal, Input)
│   ├── hooks/                 # Shared custom hooks
│   ├── lib/
│   │   └── queryClient.ts     # TanStack Query client configuration
│   ├── pages/                 # Route-level components — thin wrappers only
│   ├── utils/
│   │   └── env.ts             # getEnv() — all env access goes through here
│   └── types/                 # Global types (ApiError, etc.)
│
├── tests/
│   └── e2e/                   # Playwright E2E tests
│
├── src/mocks/
│   ├── handlers.ts            # MSW request handlers
│   └── browser.ts             # MSW browser setup
│
├── AGENTS.md
├── tsconfig.json              # strict: true — no exceptions
├── vite.config.ts
├── vitest.config.ts
└── package.json
```

## Getting Started

```bash
npm install
npm run dev
```

## Development Commands

| Command                 | Description                                    |
| :---------------------- | :--------------------------------------------- |
| `npm run dev`           | Start Vite dev server with HMR                 |
| `npm run build`         | Production build                               |
| `npm run preview`       | Preview production build locally               |
| `npm run test`          | Run unit/integration tests with Vitest         |
| `npm run test:coverage` | Run tests with coverage report                 |
| `npm run test:e2e`      | Run Playwright E2E tests                       |
| `npm run lint`          | Run ESLint                                     |
| `npm run fmt`           | Run Prettier                                   |
| `npm run type-check`    | Run `tsc --noEmit`                             |
| `npm run api:gen`       | Regenerate `src/api/generated.ts` from Swagger |

---

## Code Guidelines

### 1. Environment Variables

**Never import `import.meta.env` directly in application code.** All environment access goes through `getEnv()` in `src/utils/env.ts`.

```ts
// src/utils/env.ts
export function getEnv(key: string): string {
  const value = import.meta.env[key];
  if (!value) throw new Error(`Missing environment variable: ${key}`);
  return value;
}
```

```ts
// ✅ Good
import { getEnv } from "@/utils/env";
const apiUrl = getEnv("VITE_API_URL");

// ❌ Bad
const apiUrl = import.meta.env.VITE_API_URL;
```

---

### 2. TypeScript — No `any`, No Escape Hatches

- `strict: true` is mandatory in `tsconfig.json`. It must never be weakened.
- **No `any`** — ever. Use `unknown` and narrow with type guards.
- **No `as` type assertions** without an inline comment explaining why it is safe.
- **No non-null assertions (`!`)** without an inline comment explaining why null is impossible.
- **No implicit return types** on exported functions — always annotate.
- Prefer `interface` for object shapes, `type` for unions and intersections.
- Use `satisfies` instead of `as` where possible.

```ts
// ✅ Good — typed and explicit
interface Title {
  id: string;
  name: string;
  type: TitleType;
}

function mapTitle(raw: unknown): Title {
  if (!isTitleShape(raw)) throw new Error("Invalid title shape");
  return raw;
}

// ❌ Bad
function mapTitle(raw: any): any {
  return raw as Title;
}
```

---

### 3. No Magic Strings

Use constants or enums for any value that appears in more than one place, or that has semantic meaning (type discriminators, route paths, query keys).

```ts
// src/features/titles/types.ts
export const TITLE_TYPES = [
  "book",
  "manga",
  "manhua",
  "novel",
  "article",
] as const;
export type TitleType = (typeof TITLE_TYPES)[number];

// src/lib/queryKeys.ts
export const queryKeys = {
  titles: {
    all: () => ["titles"] as const,
    list: (filter: TitleFilter) => ["titles", "list", filter] as const,
  },
} as const;

// src/pages/routes.ts
export const ROUTES = {
  home: "/",
  titles: "/titles",
  title: (id: string) => `/titles/${id}`,
} as const;
```

---

### 4. API Layer — Never Fetch in Components

All API communication is encapsulated in `src/api/` and exposed to components only through **custom hooks**. Components never call `fetch`, `axios`, or API functions directly.

```
Component → useListTitles() hook → queryFn → src/api/titles.ts → src/api/client.ts
```

```ts
// src/api/titles.ts — typed API functions
import { client } from "./client";
import type { Title, TitleFilter, CreateTitleInput } from "./generated";

export async function listTitles(
  filter: TitleFilter,
): Promise<{ titles: Title[] }> {
  const { data } = await client.get("/titles", { params: filter });
  return data;
}

// src/features/titles/hooks/useListTitles.ts — hook wraps query
import { useQuery } from "@tanstack/react-query";
import { listTitles } from "@/api/titles";
import { queryKeys } from "@/lib/queryKeys";

export function useListTitles(filter: TitleFilter) {
  return useQuery({
    queryKey: queryKeys.titles.list(filter),
    queryFn: () => listTitles(filter),
  });
}
```

---

### 5. Generated API Types

The tracker exposes Swagger docs. **TypeScript types for the API must be auto-generated**, never hand-written.

```bash
npm run api:gen  # regenerates src/api/generated.ts from the live Swagger spec
```

- **Never edit `src/api/generated.ts` manually.** It is overwritten on every run.
- When the API changes, regenerate and adjust the feature code to match.
- If a type from the generated file needs extending, do it with intersection in `types.ts`, not by editing the generated file.

---

### 6. Components — Pure Rendering

- Components **render UI and emit events**. No business logic.
- Data fetching, mutations, and local state coordination live in **hooks**.
- If a component file exceeds ~100 lines, consider splitting it.
- Use named exports; avoid default exports for components.

```ts
// ✅ Good — component only renders
export function TitleCard({ title, onUpdate }: TitleCardProps) {
  return (
    <div data-testid="title-card">
      <span>{title.name}</span>
      <button data-testid="title-card-update-btn" onClick={() => onUpdate(title.id)}>
        Update
      </button>
    </div>
  );
}

// ❌ Bad — component fetching its own data and mixing concerns
export function TitleCard({ id }: { id: string }) {
  const [title, setTitle] = useState(null);
  useEffect(() => {
    fetch(`/titles/${id}`).then(r => r.json()).then(setTitle); // ❌
  }, [id]);
  // ...
}
```

---

### 7. Error Handling

- **Every async operation** (query or mutation) must have an error state handled in the UI. Silent failures are forbidden.
- Use **error boundaries** at the feature level to catch rendering errors.
- API error responses follow the tracker's envelope: `{ error: { code, message, details } }`. Handle them via a shared utility.
- Use `unknown` in catch clauses, never `any`:

```ts
// ✅ Good
try {
  await createTitle(input);
} catch (err: unknown) {
  const message = isApiError(err)
    ? err.response.data.error.message
    : "Something went wrong";
  setErrorMessage(message);
}
```

---

### 8. Testing

#### Philosophy

- Test **behavior, not implementation**. Test what a user sees and does, not internal function calls.
- Use **`userEvent`**, never `fireEvent`. It simulates real browser interactions.
- Mock at the **network level with MSW**, not at the module/import level. This makes tests closer to reality.

#### Unit / Integration Tests (Vitest + RTL)

- Every component with meaningful UI must have a test.
- Every custom hook must have a test.
- Use a `renderWithProviders` helper that wraps with `QueryClientProvider` and router:

```ts
// src/utils/test-utils.tsx
export function renderWithProviders(ui: ReactElement) {
  const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>{ui}</BrowserRouter>
    </QueryClientProvider>
  );
}
```

#### `data-testid` Convention

Every interactive or meaningful element must have a `data-testid`. Use the format `feature-element[-variant]`:

```tsx
<div data-testid="title-list">
  <form data-testid="create-title-form">
    <input data-testid="create-title-name-input" />
    <button data-testid="create-title-submit-btn">Add</button>
  </form>
  <ul data-testid="title-list-items">
    <li data-testid="title-card">...</li>
  </ul>
</div>
```

#### E2E Tests (Playwright)

- Cover critical user journeys: create a title, list titles, update progress.
- Never hit the real API in E2E — use MSW or a test server.

#### What NOT to do

- No snapshot tests — they break for unrelated reasons and add no signal.
- No testing implementation details (don't assert on internal state or function calls).
- No disabled `eslint` rules in test files to silence typing errors.

---

### 9. Tailwind CSS Rules

- **No inline `style` props** except for truly dynamic values that cannot be expressed with Tailwind (e.g., a CSS variable computed at runtime). Always leave a comment when you use `style`.
- **No arbitrary values** (e.g., `w-[347px]`) unless absolutely necessary.
- Extract repeated class combinations into component variants using `clsx`/`cva`, not by duplicating long class strings.
- Keep className strings readable — split long ones across lines.

```tsx
// ✅ Good
import { clsx } from "clsx";

const buttonVariants = cva("rounded px-4 py-2 font-medium", {
  variants: {
    intent: {
      primary: "bg-blue-600 text-white hover:bg-blue-700",
      ghost: "bg-transparent text-blue-600 hover:bg-blue-50",
    },
  },
});

// ❌ Bad
<button style={{ padding: "8px 16px", borderRadius: "4px" }}>Click</button>;
```

---

### 10. Project Layer Responsibilities

| Layer                         | Responsibility                                                      |
| :---------------------------- | :------------------------------------------------------------------ |
| `pages/`                      | Route-level shells. Thin wrappers. Delegate everything to features. |
| `features/<name>/components/` | Render UI, emit events via props. No fetch, no business logic.      |
| `features/<name>/hooks/`      | Data fetching, mutations, local state coordination.                 |
| `api/`                        | Raw API calls with typed inputs/outputs. No React here.             |
| `components/`                 | Shared, stateless, reusable UI primitives.                          |
| `utils/`                      | Pure utility functions. No side effects, no React.                  |

---

### 11. Linting & Formatting

- `eslint` and `prettier` run automatically on staged files via Husky + lint-staged.
- **All lint errors are blocking** — no warnings in production code.
- Prefer `eslint-disable` sparingly; always add a comment explaining why.
- Key ESLint plugins: `@typescript-eslint`, `eslint-plugin-react`, `eslint-plugin-react-hooks`, `eslint-plugin-testing-library`, `eslint-plugin-jsx-a11y`.

---

### 12. Accessibility

- All interactive elements must be keyboard-navigable.
- All images must have meaningful `alt` text; decorative images use `alt=""`.
- Use semantic HTML (`<button>` not `<div onClick>`, `<nav>`, `<main>`, `<section>`).
- `eslint-plugin-jsx-a11y` is enabled and blocking — do not disable its rules.

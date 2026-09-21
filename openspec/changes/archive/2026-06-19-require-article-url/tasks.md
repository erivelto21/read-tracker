# Tasks: Require Link for Article Titles

1. [x] Update tracker handler validation
   - File: `tracker/handler/title.go`
   - Change: add `required_if=Type article` to `CreateTitleRequest.Link` validator tag.
   - Add or update unit tests in `tracker/handler/title_test.go` for article missing/invalid link.
   - Run `make test`.

- [x] Update frontend UI
  - Files: `front/src/features/titles/components/CreateTitleModal.tsx`, `front/src/features/titles/components/EditTitleModal.tsx`
  - Change: included `link` in visibleFields and requiredFields for `article` in CreateTitleModal and added `link` to visibleFields in EditTitleModal.
  - Client-side required validation already reuses requiredFields logic; no additional changes needed.
  - Update mapping of server validation details to show field errors (existing mapping covers this).
  - Run frontend tests (if present) and manual check.

- [x] Update docs
  - Files: `tracker/AGENTS.md`, handler OpenAPI comments in `tracker/handler/title.go`
  - Change: documented that `article` requires `http_url` in `link` field in tracker/AGENTS.md and updated handler comment.

- [x] Changelog & release notes
  - File: `openspec/changes/require-article-url/changelog.md`
  - Created changelog summarizing breaking change and migration guidance for clients.

- [x] QA & Verification
  - Run `make test`, `make lint` in tracker (passed)
  - Manual UI test: create article via UI without link (expect 400 client-side error), then with link (success)


Estimate: 2-4 hours.

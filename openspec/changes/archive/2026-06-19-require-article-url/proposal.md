# Require URL for Article Titles

## Summary
Make `link` (URL) required for titles of type `article` across the stack: API validation, frontend UI, tests, and documentation.

## Motivation
Article entries currently allow no link, which reduces usefulness for articles that should point to an external resource. Requiring a URL for `article` ensures consistency and enables features that open external links.

## Scope
- Tracker (API): require HTTP(S) URL for `article` type in CreateTitleRequest and Update behavior.
- Front: show `Link` field for `article` in Create/Edit modals and make it required client-side; map server validation errors.
- Tests: update/add unit tests in `tracker/handler/title_test.go` and front tests if present.
- Docs: update `tracker/AGENTS.md` and OpenAPI comments to state article requires `http_url`.

## Acceptance Criteria
- Creating a title with type `article` without `link` returns 400 with a human-friendly "This field is required" detail for the Link field.
- Front UI shows Link input for article and treats it as required.
- Tests updated and passing (`make test`).

## Risks
- Breaking existing clients that create article titles without link. Add changelog and migration notes.

## Next Steps
- Implement the change as defined in tasks.md and run tests/lint before merging.

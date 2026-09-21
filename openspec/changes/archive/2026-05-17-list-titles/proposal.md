## Why

The tracker API can create titles but has no way to retrieve them. This change introduces `GET /v1/titles` — enabling users to list all saved titles with optional filtering by type and name.

## What Changes

- Add `GET /v1/titles` public endpoint to the Gin router
- Support optional query filters: `?type=` (exact match, case-insensitive) and `?name=` (partial contains, case-insensitive)
- Extend the repository, usecase, and handler layers following the existing patterns

## Capabilities

### New Capabilities

- `title-listing`: GET endpoint to retrieve all titles with optional type and name filters, returning a standard `{ "data": [] }` envelope

### Modified Capabilities

- `title-creation`: no logic changes; `TitleFilter` struct added to `domain/title.go` (shared domain type)

## Impact

- **`domain/title.go`**: new `TitleFilter` struct with optional `Type` and `Name` fields
- **`repository/title.go`**: new `FindAll(ctx, TitleFilter)` method building a dynamic MongoDB query
- **`usecase/title.go`**: `TitleRepository` interface extended with `FindAll`; new `List` method added
- **`handler/title.go`**: `TitleUsecase` interface extended with `List`; new `ListTitles` handler registered on `GET /titles`
- **No breaking changes** — additive only

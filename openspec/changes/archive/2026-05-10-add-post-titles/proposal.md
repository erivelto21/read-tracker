## Why

The tracker API has no way to persist reading titles. This change introduces the first write endpoint — `POST /v1/titles` — enabling users to save a title (manga, book, novel, manhua, or article) along with their current reading progress.

## What Changes

- Add `POST /v1/titles` public endpoint to the Gin router
- Introduce the `titles` domain with full validation rules driven by the `Type` enum field
- Implement uniqueness enforcement: a title's `name` must be unique (usecase check + MongoDB unique index)
- Establish the standard JSON response envelope (`data` / `error`) to be used across all future endpoints

## Capabilities

### New Capabilities

- `title-creation`: POST endpoint to save a title with type-conditional field validation, uniqueness enforcement, and structured JSON response

### Modified Capabilities

_(none — this is the first feature)_

## Impact

- **New packages**: `domain/`, `handler/`, `usecase/`, `repository/`, `config/`
- **`cmd/api/main.go`**: wired from a stub to a full Gin server with MongoDB connection and route registration
- **MongoDB**: new `titles` collection with a unique index on `name`
- **Dependencies**: `gin-gonic/gin`, `go-playground/validator/v10`, `mongo-driver/v2` added to `go.mod`
- **No breaking changes** — greenfield feature on an empty API

## Why

The tracker API has no documentation, making it hard for new users to discover available endpoints, understand required fields, and test the API without reading source code. Adding Swagger UI provides a live, always-available reference that grows with the API.

## What Changes

- Add `swaggo/swag`, `swaggo/gin-swagger`, and `swaggo/files` as dependencies to `tracker/`
- Add global API annotations to `tracker/cmd/main.go` (`@title`, `@version`, `@description`, `@host`, `@BasePath`)
- Add endpoint annotations to handler functions (`@Summary`, `@Tags`, `@Param`, `@Success`, `@Failure`, `@Router`)
- Generate `tracker/docs/` directory via `swag init` (committed to repo)
- Register `GET /swagger/*any` route in the Gin router, served always (all environments)
- Add `swag init` step to `tracker/Makefile`

## Capabilities

### New Capabilities

- `swagger-docs`: Swagger UI and OpenAPI spec auto-generated from code annotations, served at `GET /swagger/index.html`

### Modified Capabilities

- `title-creation`: No requirement changes — only annotations added to the existing `POST /v1/titles` handler to document its request/response contract

## Impact

- **Code**: `tracker/cmd/main.go`, `tracker/handler/title.go`, `tracker/Makefile`
- **New files**: `tracker/docs/docs.go`, `tracker/docs/swagger.json`, `tracker/docs/swagger.yaml` (generated, committed)
- **Dependencies**: 3 new Go modules (`swaggo/swag`, `swaggo/gin-swagger`, `swaggo/files`)
- **No breaking changes** — existing routes and response shapes are unchanged

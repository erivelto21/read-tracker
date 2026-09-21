## ADDED Requirements

### Requirement: Swagger UI is served at a fixed route
The system SHALL expose a Swagger UI at `GET /swagger/index.html` (and the wildcard `GET /swagger/*any`) in all environments. No environment gate or feature flag SHALL be required to access it.

#### Scenario: Accessing the Swagger UI
- **WHEN** a user sends `GET /swagger/index.html`
- **THEN** the system SHALL return `200 OK` with an HTML page rendering the interactive Swagger UI

#### Scenario: Accessing the raw OpenAPI spec
- **WHEN** a user sends `GET /swagger/doc.json`
- **THEN** the system SHALL return `200 OK` with the generated OpenAPI JSON spec

---

### Requirement: API-level metadata is declared in annotations
The system SHALL declare global API metadata via swaggo annotations in `cmd/main.go`. This metadata SHALL appear in the generated spec and the Swagger UI header.

Required fields:
- `@title`: human-readable API name
- `@version`: current API version
- `@description`: short description of the API's purpose
- `@host`: host and port the API is served on
- `@BasePath`: base path prefix for all routes (e.g. `/v1`)

#### Scenario: Swagger UI shows API title and version
- **WHEN** a user opens the Swagger UI
- **THEN** the UI SHALL display the declared `@title` and `@version` in the page header

---

### Requirement: Each HTTP endpoint is documented with annotations
Every handler function that registers an HTTP route SHALL carry swaggo annotations documenting its contract. Annotations SHALL be placed immediately above the handler function.

Required annotation tags per endpoint:
- `@Summary`: one-line description of the operation
- `@Tags`: grouping label (e.g. `titles`)
- `@Accept`: request content type (e.g. `json`)
- `@Produce`: response content type (e.g. `json`)
- `@Param`: body parameter referencing the request struct
- `@Success`: documented success status code and response schema
- `@Failure`: documented failure status codes (400, 409, 500) and error schema
- `@Router`: path and HTTP method

#### Scenario: POST /v1/titles is documented
- **WHEN** a user opens the Swagger UI
- **THEN** the UI SHALL show `POST /titles` under the `titles` tag with its request body schema, success (201), and failure (400, 409, 500) response schemas

---

### Requirement: Generated docs are committed to the repository
The `tracker/docs/` directory produced by `swag init` SHALL be committed to version control so the Swagger UI is available without requiring contributors to run `swag init` before starting the server.

#### Scenario: Server starts without running swag init
- **WHEN** a contributor clones the repo and runs the server without running `swag init`
- **THEN** the Swagger UI SHALL be available because `docs/` is already committed

---

### Requirement: swag init is integrated into the build workflow
The `tracker/Makefile` SHALL include a `swag` target (or integrate `swag init` into an existing `build` or `generate` target) so documentation regeneration is a single documented command.

#### Scenario: Regenerating docs after annotation changes
- **WHEN** a developer adds or modifies handler annotations
- **THEN** running `make swag` (or equivalent) from `tracker/` SHALL regenerate `docs/` with the updated spec

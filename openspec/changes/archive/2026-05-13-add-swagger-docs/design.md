## Context

The `tracker` API is a Gin-based REST service backed by MongoDB. It currently has no API documentation. New contributors and users must read source code to understand available endpoints, required fields, and response shapes.

The goal is to add a live, interactive Swagger UI powered by `swaggo/swag` — the de-facto annotation-driven documentation tool for Go/Gin. There is no auth layer today, so no security schemes are required in this change.

## Goals / Non-Goals

**Goals:**
- Serve a live Swagger UI at `/swagger/index.html` in all environments
- Document the existing `POST /v1/titles` endpoint with full request/response schemas
- Establish the annotation pattern for all future endpoints

**Non-Goals:**
- Gating docs by environment (always served)
- Documenting nightcrawler (separate service)
- Adding auth/security schemes (no auth exists yet)
- Generating client SDKs from the spec

## Decisions

### Use swaggo/swag (annotation-driven) over a hand-written OpenAPI spec

**Decision**: Use `github.com/swaggo/swag` with `github.com/swaggo/gin-swagger`.

**Rationale**: Annotations live next to handler code, so docs stay in sync naturally as the API evolves. The Gin integration (`gin-swagger`) is mature and widely used. For a solo/internal project the verbosity of annotations is acceptable.

**Alternative considered**: Hand-written `openapi.yaml` — rejected because it requires manual sync with code, which drifts over time with no enforcement.

---

### Document success responses without wrapping envelope type

**Decision**: Annotate `@Success` responses using the inner domain type directly (e.g., `domain.Title`), not a typed wrapper struct.

**Rationale**: The `DataEnvelope` struct uses `interface{}` for its `Data` field, which swag renders as an opaque `{}` object — useless in the UI. Creating per-endpoint typed wrappers (e.g., `TitleDataResponse`) adds boilerplate for an internal API. Documenting the payload shape directly is the pragmatic tradeoff.

**Alternative considered**: Typed wrapper structs per response — deferred, can be added later if the API becomes public.

---

### Commit generated docs/ directory

**Decision**: Commit `tracker/docs/` to version control.

**Rationale**: The Swagger UI depends on the generated `docs.go` import at server startup. Requiring contributors to run `swag init` before starting the server adds friction. Committing docs removes that step and makes the UI available immediately after clone.

**Alternative considered**: Generate docs in CI only / add to `.gitignore` — rejected because it breaks local server startup out of the box.

---

### Add swag target to Makefile

**Decision**: Add a `swag` target to `tracker/Makefile` that runs `swag init -g cmd/main.go`.

**Rationale**: Makes regeneration a single, discoverable command. Keeps the workflow consistent with existing Makefile conventions in the repo.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Annotations drift from actual behavior | Keep annotations in same file as handler; code review checks both together |
| `docs/` gets stale after annotation changes | `make swag` is the documented regen command; CI can enforce freshness if needed later |
| swag annotation syntax is verbose | Accepted tradeoff for an internal API; swag's editor tooling helps |

## Context

The `tracker` API currently returns raw `go-playground/validator` tag names in error responses (e.g., `"failed on 'required' validation"`), uses a non-standard error code `VALIDATION_ERROR`, and lacks URL format enforcement on the `link` field. All validation logic is centralised in `handler/title.go`.

## Goals / Non-Goals

**Goals:**
- Translate all `validator.FieldError` tags to human-readable messages via a dedicated function
- Standardise validation error responses to use `code: "BAD_REQUEST"` and `message: "Bad Request"`
- Add `http_url` validator tag to the `Link` field to enforce HTTP/HTTPS-only URLs
- Update all existing handler tests to reflect the new error shape

**Non-Goals:**
- Internationalisation (i18n) — English only for now
- Changing non-validation error codes (`CONFLICT`, `INTERNAL_ERROR`)
- Changing the success response envelope
- Adding validation to any layer other than the handler

## Decisions

### 1. Switch-based translation function over `validator.RegisterTranslation`

**Decision**: A local `validationMessage(fe validator.FieldError) string` switch function in the `handler` package.

**Rationale**: The official `universal-translator` extension adds a dependency and significant setup boilerplate for a small, bounded set of tags. A switch function is self-contained, trivially testable, and sufficient for this codebase's scale.

**Alternative considered**: `validator.RegisterTranslation` with `go-playground/locales` — rejected due to added dependency weight and setup complexity.

### 2. `http_url` over `url`

**Decision**: Use the `http_url` built-in tag on the `Link` field.

**Rationale**: `url` accepts any RFC 3986 URI (including `ftp://`, `mailto:`, bare paths). Reading source links are always HTTP/HTTPS web addresses. `http_url` restricts to those schemes without custom logic.

### 3. `BAD_REQUEST` error code

**Decision**: Replace `VALIDATION_ERROR` with `BAD_REQUEST` for all 400-level validation failures.

**Rationale**: Aligns with standard HTTP semantics and common API conventions. `VALIDATION_ERROR` is an implementation detail; `BAD_REQUEST` is client-facing and self-explanatory.

### 4. Tag-to-message mapping

| Tag | Message |
| :--- | :--- |
| `required`, `required_if` | `"This field is required"` |
| `oneof` | `"Valid values are: <param list formatted with 'and'>"` |
| `min` | `"Minimum value is <param>"` |
| `max` | `"Maximum value is <param>"` |
| `http_url` | `"Must be a valid URL"` |
| _(fallback)_ | `"Invalid value"` |

The `oneof` values come from `fe.Param()` (space-separated); the function formats them as a comma-separated list ending with `"and <last>"`.

## Risks / Trade-offs

- **Test breakage**: All existing tests asserting `wantCode: "VALIDATION_ERROR"` will fail until updated — acceptable, they are in the same PR scope.
- **Fallback message**: Unknown validator tags fall back to `"Invalid value"`, which is intentionally vague to avoid leaking internals. New tags added in future must be explicitly mapped.

## Migration Plan

1. Add `http_url` tag to `Link` field in `CreateTitleRequest`
2. Implement `validationMessage` helper in `handler/title.go`
3. Update both `RespondError` call sites in `CreateTitle` to use `BAD_REQUEST` / `"Bad Request"`
4. Update `title_test.go` assertions and add new test cases
5. Run `make test` — all tests must pass before merging

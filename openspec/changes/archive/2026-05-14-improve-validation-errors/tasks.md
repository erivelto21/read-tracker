## 1. Validation Tag Update

- [x] 1.1 Add `http_url` tag to the `Link` field validate string in `CreateTitleRequest` (after `omitempty`, before `max=200`)

## 2. Error Translation

- [x] 2.1 Implement `validationMessage(fe validator.FieldError) string` helper in `handler/title.go` with a switch on `fe.Tag()` covering: `required`, `required_if`, `oneof` (format `fe.Param()` as comma-separated list ending with "and <last>"), `min`, `max`, `http_url`, and a fallback `"Invalid value"`
- [x] 2.2 Replace the inline `fmt.Sprintf("failed on '%s' validation", fe.Tag())` call in `CreateTitle` with `validationMessage(fe)`
- [x] 2.3 Update both `RespondError` calls in `CreateTitle` that use `"VALIDATION_ERROR"` / `"request validation failed"` to use `"BAD_REQUEST"` / `"Bad Request"`

## 3. Test Updates

- [x] 3.1 Update all `wantCode: "VALIDATION_ERROR"` assertions in `title_test.go` to `"BAD_REQUEST"`
- [x] 3.2 Add a test case for invalid `link` URL (e.g., `link: "not-a-url"`) asserting `400` + `BAD_REQUEST`
- [x] 3.3 Add a test case asserting the human-readable message for a `required` failure (e.g., missing `name` → `"This field is required"`)
- [x] 3.4 Add a test case asserting the human-readable message for an `oneof` failure (e.g., invalid `type` → `"Valid values are: book, manga, manhua, novel and article"`)
- [x] 3.5 Run `make test` and confirm all tests pass

## Why

Validation errors currently expose raw validator tag names (e.g., `"failed on 'required' validation"`) and use a non-standard `VALIDATION_ERROR` code, making API responses confusing for clients. This change makes all error messages human-friendly, standardises the error code to `BAD_REQUEST`, and adds proper URL validation to the `link` field.

## What Changes

- Replace `VALIDATION_ERROR` code with `BAD_REQUEST` and `"request validation failed"` with `"Bad Request"` across all validation failure responses
- Introduce a `validationMessage` translation function that maps `validator.FieldError` tags to human-readable messages (`required`/`required_if` → `"This field is required"`, `oneof` → `"Valid values are: ..."`, `min`/`max` → `"Minimum/Maximum value is X"`, `http_url` → `"Must be a valid URL"`)
- Add `http_url` validator tag to the `Link` field on `CreateTitleRequest`
- Update all handler tests to assert `BAD_REQUEST` instead of `VALIDATION_ERROR`

## Capabilities

### New Capabilities

_(none)_

### Modified Capabilities

- `title-creation`: validation error shape changes — code, message, and per-field messages are now human-friendly; `link` field gains URL format enforcement

## Impact

- **`tracker/handler/title.go`**: new `validationMessage` helper, updated error calls, updated `Link` validate tag
- **`tracker/handler/title_test.go`**: updated `wantCode` assertions + new test cases for `http_url` and human messages
- **`openspec/specs/title-creation/spec.md`**: delta spec to reflect new error contract
- **No breaking changes to successful responses** — only error shape is updated

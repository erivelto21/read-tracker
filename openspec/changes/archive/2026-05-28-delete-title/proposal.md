## Why

The `DELETE /v1/titles/:id` endpoint currently returns `404` when the target title does not exist, violating HTTP idempotency semantics. A DELETE whose goal is "this resource must not exist" has achieved its goal regardless of whether the resource was present — repeated calls should be safe and return the same success status.

## What Changes

- `DELETE /v1/titles/:id` is made fully idempotent: calling it on a non-existent ID returns `204 No Content` instead of `404 Not Found`.
- The usecase layer drops the pre-flight `FindByExternalID` check, delegating existence detection entirely to the repository's `DeleteOne` result.
- The repository's `DeleteByExternalID` treats `DeletedCount == 0` as a successful no-op (returns `nil`) instead of `domain.ErrNotFound`.
- Tests for the "not found" delete path are updated to assert `204` instead of `404`.

## Capabilities

### New Capabilities

_None._

### Modified Capabilities

- `title-deletion`: The "delete non-existent title" scenario changes from `404 NOT_FOUND` to `204 No Content`, making the endpoint idempotent.

## Impact

- **`tracker/repository/title.go`** — `DeleteByExternalID`: remove `ErrNotFound` return when `DeletedCount == 0`.
- **`tracker/usecase/title.go`** — `Delete`: remove `FindByExternalID` pre-check.
- **`tracker/usecase/title_test.go`** — update "not found" delete test expectation.
- **`tracker/handler/title_test.go`** — update "not found" delete test expectation.
- No API contract breakage for callers that already treat `204` as success; callers that expected `404` on missing IDs will see a behaviour change.

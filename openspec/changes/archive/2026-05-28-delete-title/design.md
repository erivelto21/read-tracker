## Context

The `DELETE /v1/titles/:id` endpoint exists and functions correctly for happy-path deletion. However, it currently returns `404 Not Found` when the target resource does not exist, which breaks HTTP idempotency semantics (RFC 9110 §9.2.2): a client retrying a DELETE after a timeout cannot distinguish "already deleted" from a genuine error without additional state.

The current implementation performs two sequential MongoDB operations: a `FindByExternalID` pre-check followed by `DeleteByExternalID`. This is unnecessary — `DeleteOne` already tells us whether a document was removed via `DeletedCount`.

Stack layout:
```
Handler → Usecase → Repository → MongoDB
```

The fix is applied at the **repository** and **usecase** layers only. The handler and domain are untouched.

## Goals / Non-Goals

**Goals:**
- Make `DELETE /v1/titles/:id` idempotent: return `204 No Content` for both existing and non-existing IDs.
- Remove the unnecessary `FindByExternalID` pre-check from `usecase.Delete`.
- Treat `DeletedCount == 0` as a no-op (success) in `repository.DeleteByExternalID`.
- Update tests to assert the new `204` behaviour for the "not found" path.

**Non-Goals:**
- Soft delete / archiving — this remains a hard delete.
- Any change to the handler, domain, or route registration.
- Any change to other endpoints (Create, List, Update).

## Decisions

### Decision: Remove the pre-flight FindByExternalID in the usecase

**Choice**: Delete without pre-check; rely solely on `DeleteOne` result.

**Rationale**: The pre-check adds a round-trip to MongoDB and provides no value when idempotency is the goal. `DeleteOne` already returns `DeletedCount`, which is the only signal needed. Removing the pre-check simplifies the call graph and halves the database operations per delete.

**Alternatives considered**:
- *Keep pre-check, suppress ErrNotFound in handler*: Simpler handler change but still wastes a DB round-trip and leaks "not found" semantics into the handler layer.
- *Keep pre-check, suppress ErrNotFound in usecase*: Cleaner than the handler option but still an extra DB op for no gain.

### Decision: Repository returns nil when DeletedCount == 0

**Choice**: `DeleteByExternalID` returns `nil` when no document is matched.

**Rationale**: The repository's contract is "ensure this ID is absent". If it was already absent, the post-condition is already satisfied. Returning an error for a no-op would force every caller to handle a non-error condition as an error. This also makes the repository honest about idempotency at the data layer.

**Alternatives considered**:
- *Return a new sentinel like `ErrAlreadyDeleted`*: Adds complexity with no consumer benefit since we don't want to distinguish these cases.

## Risks / Trade-offs

- **Callers expecting 404 on missing IDs** → Any client that used `404` to detect "title doesn't exist" must now use a `GET` before deleting if that distinction matters. This is a deliberate breaking behaviour change documented in the proposal.
- **Lost observability of "was it actually there?"** → The usecase no longer knows if the title existed before deletion. If future requirements need an audit log ("deleted existing" vs "no-op"), the repository would need to restore `DeletedCount` signal propagation. Low risk for current scope.

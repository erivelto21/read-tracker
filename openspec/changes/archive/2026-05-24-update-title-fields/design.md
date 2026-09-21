## Context

The tracker API follows a layered architecture: `handler → usecase → repository`, with interfaces between each layer. The domain model `Title` has two ID fields: an internal `bson.ObjectID` (never exposed) and a public `ExternalID` (UUID, exposed as `"id"` in JSON responses).

Currently only `Create` and `List` operations exist. The four mutable fields — `chapter`, `page`, `link`, `observation` — are all pointer types in the domain, which naturally supports partial updates (nil = not provided).

## Goals / Non-Goals

**Goals:**
- Expose `PATCH /titles/:id` for partial updates of `chapter`, `page`, `link`, `observation`
- Touch only the fields present in the request body; leave all others unchanged
- Reject requests that send no updatable fields (`400 Bad Request`)
- Return the updated title in the response
- Apply the same field-level validation rules as `POST /titles`

**Non-Goals:**
- Updating `name` or `type` (immutable after creation)
- Bulk updates
- Clearing/nullifying a field (absent = no-op; null not supported)

## Decisions

### D1: PATCH over PUT
Use `PATCH` (partial update) rather than `PUT` (full replacement). Users track reading progress incrementally — they want to update `chapter` without having to resend `link` and `observation`. PATCH semantics match this exactly.

### D2: Pointer fields as the absent/present signal
All four updatable fields are `*int` / `*string` in the domain. A `nil` pointer after JSON unmarshalling means "not sent". This is sufficient because null-clearing is explicitly out of scope. No custom JSON unmarshalling or wrapper types needed.

### D3: Introduce `TitleUpdate` domain struct
Rather than passing a `map[string]any` or raw BSON through layers, introduce a `domain.TitleUpdate` struct with the same pointer fields. This keeps the usecase and handler type-safe and decoupled from the persistence layer.

```
domain.TitleUpdate {
    Chapter     *int
    Page        *int
    Link        *string
    Observation *string
}
```

### D4: Repository builds the `$set` document
The repository `Update` method receives a `TitleUpdate` and constructs the MongoDB `$set` only from non-nil fields. This keeps MongoDB details out of the usecase layer.

### D5: Lookup by ExternalID
`PATCH /titles/:id` uses the public `ExternalID` (UUID). A new `FindByExternalID` repository method is added to support the existence check in the usecase, and `Update` also targets by `external_id`.

### D6: Usecase performs existence check
The usecase calls `FindByExternalID` before updating. If not found, it returns `domain.ErrNotFound`, which the handler maps to `404`. This mirrors the `ErrAlreadyExists` pattern already in place for `Create`.

### D7: Empty-body → 400
If the request body contains none of the four fields (all pointers are nil after unmarshalling), the handler returns `400 Bad Request` before calling the usecase. An empty PATCH is a client error.

## Risks / Trade-offs

- **Race condition on existence check + update** → Two separate MongoDB calls (FindByExternalID + UpdateOne) are not atomic. A concurrent delete between them would result in a no-op update that returns 404 — acceptable for this use case. Could be solved with `FindOneAndUpdate` returning `ErrNoDocuments`, but adds complexity.
- **No clearing of fields** → Users cannot unset `link` or `observation` once set. Acceptable for current scope; a future change can introduce explicit null support with a JSON wrapper type.
- **`$set` with zero-value ints** → If `chapter: 0` is sent, it will be stored (pointer is non-nil). This is correct behaviour — `0` is a valid chapter value.

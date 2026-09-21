## Architecture

Follows the same layered architecture as `POST /titles`:

```
Handler → Usecase → Repository → MongoDB
```

Each layer communicates through interfaces defined in the layer above it.

## TitleFilter (domain)

```go
// TitleFilter holds optional filters for listing titles.
type TitleFilter struct {
    Type *TitleType // exact match after lowercasing
    Name *string    // case-insensitive partial match
}
```

Lives in `domain/title.go` alongside the `Title` struct.

## Repository — FindAll

Builds a `bson.M` filter dynamically:

- `Type` set → `{ "type": <value> }` (already lowercased by handler)
- `Name` set → `{ "name": { "$regex": <value>, "$options": "i" } }`
- Both set → both conditions combined in the same `bson.M`
- Neither set → empty `bson.M{}` → returns all documents

Uses `collection.Find()` + cursor decode into `[]domain.Title`.  
Returns empty slice (not nil) when no documents match.

## Usecase — List

Thin delegation to repository. No business logic beyond passing the filter through.

## Handler — ListTitles

1. Read `?type` query param → lowercase → validate against enum (if non-empty)
2. Read `?name` query param (if non-empty)
3. Build `domain.TitleFilter` with non-empty values as pointers
4. Call `usecase.List(ctx, filter)`
5. Respond `200 { "data": [...] }` — always 200, even on empty result

## Validation

| Scenario | Response |
|---|---|
| `?type=manga` | valid, normalized |
| `?type=MANGA` | normalized to `"manga"`, valid |
| `?type=invalid` | `400 BAD_REQUEST` |
| `?type=` (empty) | ignored, treated as not provided |
| `?name=` (empty) | ignored, treated as not provided |
| no params | returns all titles |
| no results | `200 { "data": [] }` |

## Swagger Annotations

`ListTitles` gets full `@Summary`, `@Tags`, `@Param`, `@Success`, `@Failure`, `@Router` annotations consistent with `CreateTitle`.

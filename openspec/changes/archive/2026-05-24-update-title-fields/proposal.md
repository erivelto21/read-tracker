## Why

The tracker API currently supports creating and listing titles, but provides no way to update a reading entry after it's created. Users need to update their reading progress (chapter, page) and metadata (link, observation) as they continue reading.

## What Changes

- Add `PATCH /titles/:id` endpoint that accepts partial updates for `chapter`, `page`, `link`, and `observation`
- Only fields explicitly included in the request body are updated; absent fields are left unchanged
- Requests with no fields provided are rejected with `400 Bad Request`
- Same validation rules as `POST /titles` apply to each updatable field

## Capabilities

### New Capabilities

- `title-update`: Partial update of a tracked title's mutable fields (`chapter`, `page`, `link`, `observation`) via `PATCH /titles/:id`

### Modified Capabilities

## Impact

- `tracker/domain/title.go` — new `TitleUpdate` struct for the updatable fields
- `tracker/repository/title.go` — new `FindByExternalID` and `Update` methods; `TitleRepository` interface extended
- `tracker/usecase/title.go` — new `Update` method; `TitleUsecase` interface extended
- `tracker/handler/title.go` — new `UpdateTitleRequest`, `UpdateTitle` handler, and route `PATCH /titles/:id`

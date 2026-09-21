## 1. Domain

- [x] 1.1 Add `TitleUpdate` struct to `tracker/domain/title.go` with fields `Chapter *int`, `Page *int`, `Link *string`, `Observation *string`

## 2. Repository

- [x] 2.1 Add `FindByExternalID(ctx context.Context, externalID string) (*domain.Title, error)` to `MongoTitleRepository` in `tracker/repository/title.go` — query by `external_id`, return `domain.ErrNotFound` when no document matches
- [x] 2.2 Add `Update(ctx context.Context, externalID string, fields domain.TitleUpdate) (*domain.Title, error)` to `MongoTitleRepository` — build a `$set` document from non-nil fields only, use `FindOneAndUpdate` with `ReturnDocument: After`, return `domain.ErrNotFound` when no document matches
- [x] 2.3 Extend the `TitleRepository` interface in `tracker/usecase/title.go` with `FindByExternalID` and `Update` signatures

## 3. Usecase

- [x] 3.1 Add `Update(ctx context.Context, externalID string, fields domain.TitleUpdate) (*domain.Title, error)` to `TitleUsecase` — call `FindByExternalID`, return `domain.ErrNotFound` if missing, then call `repo.Update`
- [x] 3.2 Extend the `TitleUsecase` interface in `tracker/handler/title.go` with the `Update` signature

## 4. Handler

- [x] 4.1 Add `UpdateTitleRequest` struct in `tracker/handler/title.go` with the four pointer fields and validation tags matching `CreateTitleRequest` (`chapter: min=-100,max=10000`, `page: min=0,max=10000`, `link: http_url,max=200`, `observation: max=500`)
- [x] 4.2 Add `UpdateTitle` handler method — bind and validate `UpdateTitleRequest`, reject with `400` if all four fields are nil, call `usecase.Update`, map `domain.ErrNotFound` to `404`, return `200` with updated title
- [x] 4.3 Register route `PATCH /titles/:id` in `RegisterRoutes`

## 5. Tests

- [x] 5.1 Add usecase unit tests for `Update`: success, `ErrNotFound` propagation, and repository error propagation
- [x] 5.2 Add handler unit tests for `UpdateTitle`: success, empty body `400`, validation errors `400`, not found `404`, internal error `500`

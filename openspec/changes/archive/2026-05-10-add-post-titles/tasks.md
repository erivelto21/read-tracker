## 1. Project Setup

- [x] 1.1 Add dependencies to `go.mod`: `gin-gonic/gin v1.12`, `go-playground/validator/v10`, `mongo-driver/v2`
- [x] 1.2 Run `go mod tidy` to download and verify dependencies

## 2. Domain Layer

- [x] 2.1 Create `domain/title.go` with the `TitleType` constants (`Book`, `Manga`, `Manhua`, `Novel`, `Article`)
- [x] 2.2 Add the `Title` struct with fields: `Name`, `Type`, `Chapter`, `Page`, `Link`, `Observation` and bson tag `_id,omitempty` on an unexported ID field
- [x] 2.3 Define sentinel errors in `domain/title.go`: `ErrAlreadyExists`, `ErrNotFound`

## 3. Repository Layer

- [x] 3.1 Create `repository/title.go` with `MongoTitleRepository` struct holding a `*mongo.Collection`
- [x] 3.2 Implement `FindByName(ctx, name) (*domain.Title, error)` — returns `domain.ErrNotFound` when not found
- [x] 3.3 Implement `Save(ctx, title) (*domain.Title, error)` — maps mongo duplicate-key error (`E11000`) to `domain.ErrAlreadyExists`
- [x] 3.4 Add `NewMongoTitleRepository(col *mongo.Collection)` constructor

## 4. Usecase Layer

- [x] 4.1 Create `usecase/title.go` with `TitleRepository` interface (`FindByName`, `Save`)
- [x] 4.2 Implement `TitleUsecase` struct with constructor `NewTitleUsecase(repo TitleRepository)`
- [x] 4.3 Implement `Create(ctx, title) (*domain.Title, error)` — calls `FindByName` first, returns `domain.ErrAlreadyExists` if found, otherwise calls `Save`

## 5. Handler Layer

- [x] 5.1 Create `handler/response.go` with shared `DataEnvelope`, `ErrorEnvelope`, `ErrorDetail` structs and helper functions `RespondData`, `RespondError`
- [x] 5.2 Create `handler/title.go` with `CreateTitleRequest` DTO using `json` and `validate` tags (base rules + `required_if` for conditional fields; pointer types for `Chapter`, `Page`, `Link`, `Observation`)
- [x] 5.3 Implement `TitleHandler` struct with `TitleUsecase` interface and constructor `NewTitleHandler`
- [x] 5.4 Implement `CreateTitle(c *gin.Context)` handler: bind JSON → validate → map to `domain.Title` → call usecase → respond 201 or mapped error (400 / 409 / 500)
- [x] 5.5 Add `RegisterRoutes(rg *gin.RouterGroup)` method on `TitleHandler` that registers `POST /titles`

## 6. Config & Wiring

- [x] 6.1 Create `config/config.go` with `Config` struct (`MongoURI`, `DBName`, `Port`) loaded from environment variables; fail fast on missing required vars
- [x] 6.2 Rewrite `cmd/api/main.go`: load config → connect MongoDB → create unique index on `titles.name` → wire repository → usecase → handler → register routes under `/v1` → start Gin server

## 7. MongoDB Index

- [x] 7.1 In `main.go` startup, programmatically create a unique ascending index on the `name` field of the `titles` collection using `mongo-driver` `IndexView.CreateOne`

## 8. Tests

- [x] 8.1 Write table-driven unit tests for `usecase.TitleUsecase.Create` covering: success, duplicate name, repository save error
- [x] 8.2 Write table-driven unit tests for `handler.CreateTitle` covering: valid request per type, missing required fields (name, chapter for manga, page for book, link for novel), duplicate name (409), invalid type enum

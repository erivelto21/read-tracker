## Tasks

### 1. Add `TitleFilter` to domain

- [x] Add `TitleFilter` struct to `tracker/domain/title.go`

---

### 2. Add `FindAll` to repository

- [x] Add `FindAll(ctx, TitleFilter)` to `MongoTitleRepository` in `tracker/repository/title.go`

---

### 3. Extend usecase

- [x] Add `FindAll` to `TitleRepository` interface in `tracker/usecase/title.go`
- [x] Add `List` method to `TitleUsecase`

---

### 4. Add `ListTitles` handler

- [x] Add `List` to `TitleUsecase` interface in `tracker/handler/title.go`
- [x] Add `ListTitles` handler with Swagger annotations
- [x] Register `GET /titles` route

---

### 5. Regenerate Swagger docs

- [x] Run `make swag` from `tracker/`

---

### 6. Add tests

- [x] Handler tests: `tracker/handler/title_test.go` — `TestListTitles`
- [x] Usecase tests: `tracker/usecase/title_test.go` — `TestTitleUsecase_List`

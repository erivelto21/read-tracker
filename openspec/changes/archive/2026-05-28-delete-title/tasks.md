## 1. Repository

- [x] 1.1 In `tracker/repository/title.go`, update `DeleteByExternalID` to return `nil` when `DeletedCount == 0` instead of `domain.ErrNotFound`

## 2. Usecase

- [x] 2.1 In `tracker/usecase/title.go`, remove the `FindByExternalID` pre-check from `Delete` — call `DeleteByExternalID` directly

## 3. Tests

- [x] 3.1 In `tracker/usecase/title_test.go`, update the `Delete` "not found" test case to expect `nil` error instead of `domain.ErrNotFound`
- [x] 3.2 In `tracker/handler/title_test.go`, update the `DeleteTitle` "not found" test case to expect `204 No Content` instead of `404 Not Found`
- [x] 3.3 Run `go test ./tracker/...` and confirm all tests pass

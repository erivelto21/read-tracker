## 1. Dependencies

- [x] 1.1 Install `github.com/swaggo/swag` CLI tool (`go install github.com/swaggo/swag/cmd/swag@latest`)
- [x] 1.2 Add `github.com/swaggo/gin-swagger` to `tracker/go.mod` (`go get github.com/swaggo/gin-swagger`)
- [x] 1.3 Add `github.com/swaggo/files` to `tracker/go.mod` (`go get github.com/swaggo/files`)

## 2. Global API Annotations

- [x] 2.1 Add swaggo global annotations to `tracker/cmd/main.go` (`@title`, `@version`, `@description`, `@host`, `@BasePath /v1`)
- [x] 2.2 Add `_ "github.com/erivelto/read-tracker/tracker/docs"` blank import to `tracker/cmd/main.go`

## 3. Swagger Route

- [x] 3.1 Import `ginSwagger "github.com/swaggo/gin-swagger"` and `swaggerFiles "github.com/swaggo/files"` in `tracker/cmd/main.go`
- [x] 3.2 Register `GET /swagger/*any` route on the root router (outside the `/v1` group) in `tracker/cmd/main.go`

## 4. Endpoint Annotations

- [x] 4.1 Add swaggo annotations to `TitleHandler.CreateTitle` in `tracker/handler/title.go` (`@Summary`, `@Tags`, `@Accept`, `@Produce`, `@Param`, `@Success 201`, `@Failure 400`, `@Failure 409`, `@Failure 500`, `@Router /titles [post]`)

## 5. Generate Docs

- [x] 5.1 Run `swag init -g cmd/main.go` from `tracker/` to generate the `tracker/docs/` directory
- [x] 5.2 Verify `tracker/docs/docs.go`, `tracker/docs/swagger.json`, and `tracker/docs/swagger.yaml` are generated correctly

## 6. Makefile Integration

- [x] 6.1 Add a `swag` target to `tracker/Makefile` that runs `swag init -g cmd/main.go`

## 7. Verification

- [x] 7.1 Start the server and confirm `GET /swagger/index.html` returns `200 OK` with the Swagger UI
- [x] 7.2 Confirm `POST /titles` appears in the UI under the `titles` tag with correct request body and response schemas
- [x] 7.3 Confirm `GET /swagger/doc.json` returns the raw OpenAPI JSON spec
- [x] 7.4 Run existing tests to confirm no regressions (`go test ./...` from `tracker/`)

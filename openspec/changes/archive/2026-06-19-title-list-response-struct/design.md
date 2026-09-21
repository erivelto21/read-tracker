# Design: Titles response envelope

Goal

Return GET /titles payload in a typed envelope `{ "titles": [ ... ] }` instead of the generic `{ "data": ... }`.

Design choices

1. Add a typed TitlesEnvelope in tracker/handler/response.go to make the swagger UI render the payload shape:

```go
// in handler/response.go
import (
    "net/http"
    "github.com/gin-gonic/gin"
    "github.com/erivelto/read-tracker/tracker/domain"
)

type TitlesEnvelope struct {
    Titles []domain.Title `json:"titles"`
}

func RespondTitles(c *gin.Context, status int, titles []domain.Title) {
    c.JSON(status, TitlesEnvelope{Titles: titles})
}
```

2. Change ListTitles in tracker/handler/title.go to call RespondTitles and update the swagger annotation to reference `handler.TitlesEnvelope`.

3. Update tests to decode the `titles` field instead of `data` and update openspec docs/specs so examples show `{ "titles": [...] }`.

Backward compatibility

This is a breaking change for clients who expect the `data` envelope. Two migration strategies:

- Bump API minor/major and document migration steps (preferred), or
- Support both envelopes temporarily (return both `data` and `titles`) and deprecate `data` (more work but backward-compatible).

Swagger/docs

Regenerate swagger artifacts after code changes. If project uses swaggo, run:

  swag init -g tracker/handler/title.go -o tracker/docs

Acceptance criteria

- Tests expecting list endpoints updated and passing
- Swagger shows `titles` array with title fields
- GET /titles returns `{ "titles": [] }` for empty results


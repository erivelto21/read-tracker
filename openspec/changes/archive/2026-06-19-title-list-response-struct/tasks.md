# Tasks

- [x] Update handler/response.go
  - Add TitlesEnvelope type and RespondTitles helper
  - Add domain import

- [x] Update handler/title.go
  - Change @Success 200 annotation to use TitlesEnvelope
  - Replace RespondData call in ListTitles with RespondTitles

- [x] Update unit tests
  - tracker/handler/title_test.go: change fixtures to expect `titles` key
  - run `go test ./...` and fix failures

- [x] Update OpenSpec and docs
  - openspec/specs/title-listing/spec.md: update examples to use `titles`
  - Update changelog and release notes
  - Regenerate tracker/docs/swagger.yaml and swagger.json

- [x] Decide migration strategy and document in changelog

Estimated time: 1–2 hours (code + tests + docs)


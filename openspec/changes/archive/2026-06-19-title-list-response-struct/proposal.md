# Change: Title list response structure

Summary

Replace GET /titles response envelope from:

  { "data": [ ... ] }

to:

  { "titles": [ { /* title object */ } ] }

Rationale

- Make response field explicit and self-describing for clients and generated docs/UI.
- Avoid opaque `data` field which hides the payload shape in swagger UI.

Impact

- Handler: add a typed TitlesEnvelope (json:"titles") and a RespondTitles helper; change ListTitles to use it.
- Handler tests: update expectations to read `titles` instead of `data`.
- Swagger/docs: update annotations and generated swagger.yaml/json to reference the new envelope.
- OpenSpec artifacts: update listing specs to expect `{ "titles": [...] }`.
- Breaking change for API clients: must document and release as a minor version with deprecation notes.

Files to change

- tracker/handler/response.go: add TitlesEnvelope and RespondTitles
- tracker/handler/title.go: update ListTitles swagger comment and call RespondTitles
- tracker/handler/title_test.go: update test fixtures/structs expecting `data`
- tracker/docs/swagger.yaml and swagger.json: regenerate (or update definitions) to include handler.TitlesEnvelope
- openspec/specs/title-listing/spec.md: update examples to `{ "titles": [...] }`

Acceptance criteria

- GET /titles returns 200 with `{ "titles": [...] }` for both non-empty and empty results.
- Tests updated and passing.
- Swagger shows the titles array shape rather than opaque `{}` under `data`.
- Change proposal documented and communicated in changelog.

Migration plan

- Add new endpoint response now, keep old response available under a v1 compatibility header (optional) OR bump minor version and communicate breaking change.
- Provide a short migration note in README and changelog.

Do you want me to create design/tasks files and draft the code snippets next? 


# Design: Require Link for Article Titles

## Overview
This change enforces that titles of type `article` include a valid HTTP/HTTPS URL. Validation is performed at the handler layer using `go-playground/validator` tag `http_url`.

## Tracker (API)
- Update CreateTitleRequest.Link tag to include `required_if=Type article` in addition to existing required_if for manga/manhua/novel.
  - From: `validate:"required_if=Type manga,required_if=Type manhua,required_if=Type novel,omitempty,http_url,max=200"`
  - To:   `validate:"required_if=Type manga,required_if=Type manhua,required_if=Type novel,required_if=Type article,omitempty,http_url,max=200"`
- Ensure UpdateTitleRequest behavior: when updating Link, keep `http_url` validation; no change to optionality on patch.
- Keep validation messages via `validationMessage` ("This field is required" / "Must be a valid URL").

## Frontend
- CreateTitleModal and EditTitleModal:
  - visibleFields for `article` should include `link` (currently only `name, observation`).
  - requiredFields for `article` should include `link` (currently only `name`).
  - Client-side required validation should check `link` is non-empty and display "This field is required".
  - Input type for link remains `url` and keep server error mapping.

## Tests
- tracker/handler/title_test.go:
  - Update the test case "valid article request (chapter not required)" to include `link` and ensure it's accepted.
  - Add failing and success cases for article link missing/invalid.
- Front: if there are unit tests asserting visible/required fields, update accordingly.

## Docs & API
- Update `tracker/AGENTS.md` and handler OpenAPI comments to document: "article requires an http(s) URL in the `link` field".
- Changelog entry and migration note: clients must be updated to provide `link` for articles.

## Rollout
- Soft rollout unnecessary; change is backward-incompatible for clients. Communicate in changelog and release notes.

## Verification
- Run `make test` and `make lint`.
- Manual UI flow: Add article via UI and verify link input required and errors surfaced.

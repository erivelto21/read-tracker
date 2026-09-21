# Changelog — Require Link for Article Titles

## Unreleased
- Breaking change: titles with type `article` now require a `link` HTTP(S) URL. Clients creating articles without `link` will receive a 400 `BAD_REQUEST`.

## Migration
- Update any clients (mobile, browser extensions, API consumers) to include a `link` field when creating or updating titles with `type: "article"`.

## Release notes (suggested)
- "Articles now require an external URL. Please update integrations to provide `link` when creating articles. This change improves linkability for article-type entries."

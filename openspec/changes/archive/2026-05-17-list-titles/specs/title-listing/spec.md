## Overview

`GET /v1/titles` returns a list of all titles saved in the database, with optional query-param filters.

## Endpoint

```
GET /v1/titles
```

## Query Parameters

| Param | Type   | Required | Description |
|-------|--------|----------|-------------|
| type  | string | No       | Filter by title type. Case-insensitive. Must be one of: `book`, `manga`, `manhua`, `novel`, `article`. |
| name  | string | No       | Filter by partial name match. Case-insensitive. |

## Response

### 200 OK

```json
{
  "data": [
    {
      "id": "uuid",
      "name": "Full Name",
      "type": "manga",
      "chapter": 10,
      "link": "https://example.com"
    }
  ]
}
```

- `data` is always an array; empty array `[]` when no results match.
- Each item is a `domain.Title` (same shape as `POST /titles` response).
- Fields with `omitempty` (`chapter`, `page`, `link`, `observation`) are omitted when null.

### 400 Bad Request

Returned when `?type` is provided but not a valid enum value.

```json
{
  "error": {
    "code": "BAD_REQUEST",
    "message": "Bad Request",
    "details": [
      { "field": "type", "message": "Valid values are: book, manga, manhua, novel and article" }
    ]
  }
}
```

### 500 Internal Server Error

```json
{
  "error": {
    "code": "INTERNAL_ERROR",
    "message": "an unexpected error occurred"
  }
}
```

## Behavior Rules

1. Both `?type` and `?name` are optional and combinable.
2. `?type` value is normalized to lowercase before validation.
3. Empty string values for either param are ignored (treated as not provided).
4. `?name` performs a case-insensitive substring match (MongoDB `$regex` with `i` option).
5. When no filters are provided, all titles are returned.
6. A query matching zero documents returns `200` with `{ "data": [] }` — never `404`.

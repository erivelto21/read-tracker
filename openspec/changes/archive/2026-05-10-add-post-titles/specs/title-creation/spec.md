## ADDED Requirements

### Requirement: Save a new title
The system SHALL expose a `POST /v1/titles` endpoint that persists a new title entry in the database and returns the created title (without the MongoDB `_id`) in a standard `data` envelope with HTTP 201. The response SHALL include an `id` field containing a UUID v4 generated at creation time. This `id` is the public identifier to be used in future lookup operations.

#### Scenario: Successful creation of a manga title
- **WHEN** a valid request is sent with `type=manga`, a `name`, a `chapter`, and a `link`
- **THEN** the system SHALL return `201 Created` with the saved title fields in `{ "data": { ... } }`

#### Scenario: Successful creation of a book title
- **WHEN** a valid request is sent with `type=book`, a `name`, a `chapter`, and a `page`
- **THEN** the system SHALL return `201 Created` with the saved title fields in `{ "data": { ... } }`

#### Scenario: Successful creation of an article title
- **WHEN** a valid request is sent with `type=article` and a `name` only
- **THEN** the system SHALL return `201 Created` with the saved title fields in `{ "data": { ... } }`

---

### Requirement: Validate title fields by type enum
The system SHALL enforce field-level validation rules. Base rules apply to all types; conditional rules apply based on the `type` field value.

**Base rules (all types):**
- `name`: required, string, min length 3, max length 100
- `type`: required, one of `book | manhua | manga | article | novel`
- `chapter`: optional globally; integer, min -100, max 10000
- `page`: optional globally; integer, min 0, max 10000
- `link`: optional globally; string, max length 200
- `observation`: optional, string, max length 500

**Conditional rules by type:**

| Field     | book       | manga      | manhua     | novel      | article |
|-----------|-----------|-----------|-----------|-----------|---------|
| `chapter` | required  | required  | required  | required  | —       |
| `page`    | required  | —         | —         | —         | —       |
| `link`    | —         | required  | required  | required  | —       |

#### Scenario: Missing required name
- **WHEN** a request is sent without the `name` field
- **THEN** the system SHALL return `400 Bad Request` with `error.code = "VALIDATION_ERROR"` and a `details` array identifying the `name` field

#### Scenario: Name too short
- **WHEN** a request is sent with `name` shorter than 3 characters
- **THEN** the system SHALL return `400 Bad Request` with `error.code = "VALIDATION_ERROR"`

#### Scenario: Invalid type value
- **WHEN** a request is sent with `type` not in the allowed enum
- **THEN** the system SHALL return `400 Bad Request` with `error.code = "VALIDATION_ERROR"`

#### Scenario: Chapter missing for manga
- **WHEN** a request is sent with `type=manga` and no `chapter` field
- **THEN** the system SHALL return `400 Bad Request` with `error.code = "VALIDATION_ERROR"` and `details` identifying `chapter`

#### Scenario: Page missing for book
- **WHEN** a request is sent with `type=book` and no `page` field
- **THEN** the system SHALL return `400 Bad Request` with `error.code = "VALIDATION_ERROR"` and `details` identifying `page`

#### Scenario: Link missing for novel
- **WHEN** a request is sent with `type=novel` and no `link` field
- **THEN** the system SHALL return `400 Bad Request` with `error.code = "VALIDATION_ERROR"` and `details` identifying `link`

#### Scenario: Chapter absent for article
- **WHEN** a request is sent with `type=article` and no `chapter` field
- **THEN** the system SHALL return `201 Created` (chapter is not required for article)

---

### Requirement: Enforce title name uniqueness
The system SHALL reject creation of a title whose `name` already exists in the database.

#### Scenario: Duplicate title name
- **WHEN** a request is sent with a `name` that already exists in the database
- **THEN** the system SHALL return `409 Conflict` with `error.code = "CONFLICT"` and `error.message = "a title with this name already exists"`

#### Scenario: Race condition on duplicate insert
- **WHEN** two concurrent requests with the same `name` reach the database simultaneously and bypass the usecase uniqueness check
- **THEN** the MongoDB unique index on `name` SHALL reject the second insert and the system SHALL return `409 Conflict`

---

### Requirement: Return structured error responses
The system SHALL return all errors in a standard JSON envelope. Internal error details SHALL never be exposed to the client.

#### Scenario: Validation failure response shape
- **WHEN** the request fails validation
- **THEN** the system SHALL return `{ "error": { "code": "VALIDATION_ERROR", "message": "request validation failed", "details": [{ "field": "...", "message": "..." }] } }`

#### Scenario: Conflict response shape
- **WHEN** the title name already exists
- **THEN** the system SHALL return `{ "error": { "code": "CONFLICT", "message": "a title with this name already exists" } }` with no `details` field

#### Scenario: Unexpected internal error
- **WHEN** an unhandled error occurs (e.g., database connection failure)
- **THEN** the system SHALL return `500 Internal Server Error` with `{ "error": { "code": "INTERNAL_ERROR", "message": "an unexpected error occurred" } }` and no internal details

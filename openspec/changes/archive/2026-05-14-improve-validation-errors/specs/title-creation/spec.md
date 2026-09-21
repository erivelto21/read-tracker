## MODIFIED Requirements

### Requirement: Validate title fields by type enum
The system SHALL enforce field-level validation rules. Base rules apply to all types; conditional rules apply based on the `type` field value.

**Base rules (all types):**
- `name`: required, string, min length 3, max length 100
- `type`: required, one of `book | manhua | manga | article | novel`
- `chapter`: optional globally; integer, min -100, max 10000
- `page`: optional globally; integer, min 0, max 10000
- `link`: optional globally; string, valid HTTP/HTTPS URL (`http_url`), max length 200
- `observation`: optional, string, max length 500

**Conditional rules by type:**

| Field     | book       | manga      | manhua     | novel      | article |
|-----------|-----------|-----------|-----------|-----------|---------|
| `chapter` | required  | required  | required  | required  | —       |
| `page`    | required  | —         | —         | —         | —       |
| `link`    | —         | required  | required  | required  | —       |

#### Scenario: Missing required name
- **WHEN** a request is sent without the `name` field
- **THEN** the system SHALL return `400 Bad Request` with `error.code = "BAD_REQUEST"` and a `details` array with `{ "field": "Name", "message": "This field is required" }`

#### Scenario: Name too short
- **WHEN** a request is sent with `name` shorter than 3 characters
- **THEN** the system SHALL return `400 Bad Request` with `error.code = "BAD_REQUEST"` and `details` containing a human-readable minimum length message

#### Scenario: Invalid type value
- **WHEN** a request is sent with `type` not in the allowed enum
- **THEN** the system SHALL return `400 Bad Request` with `error.code = "BAD_REQUEST"` and `details` containing `{ "field": "Type", "message": "Valid values are: book, manga, manhua, novel and article" }`

#### Scenario: Chapter missing for manga
- **WHEN** a request is sent with `type=manga` and no `chapter` field
- **THEN** the system SHALL return `400 Bad Request` with `error.code = "BAD_REQUEST"` and `details` identifying `chapter` with `"This field is required"`

#### Scenario: Page missing for book
- **WHEN** a request is sent with `type=book` and no `page` field
- **THEN** the system SHALL return `400 Bad Request` with `error.code = "BAD_REQUEST"` and `details` identifying `page` with `"This field is required"`

#### Scenario: Link missing for novel
- **WHEN** a request is sent with `type=novel` and no `link` field
- **THEN** the system SHALL return `400 Bad Request` with `error.code = "BAD_REQUEST"` and `details` identifying `link` with `"This field is required"`

#### Scenario: Link is not a valid URL
- **WHEN** a request is sent with a `link` value that is not a valid HTTP/HTTPS URL (e.g., `"not-a-url"`)
- **THEN** the system SHALL return `400 Bad Request` with `error.code = "BAD_REQUEST"` and `details` containing `{ "field": "Link", "message": "Must be a valid URL" }`

#### Scenario: Chapter absent for article
- **WHEN** a request is sent with `type=article` and no `chapter` field
- **THEN** the system SHALL return `201 Created` (chapter is not required for article)

---

## MODIFIED Requirements

### Requirement: Return structured error responses
The system SHALL return all errors in a standard JSON envelope. Internal error details SHALL never be exposed to the client.

#### Scenario: Validation failure response shape
- **WHEN** the request fails validation
- **THEN** the system SHALL return `{ "error": { "code": "BAD_REQUEST", "message": "Bad Request", "details": [{ "field": "...", "message": "<human-readable message>" }] } }`

#### Scenario: Conflict response shape
- **WHEN** the title name already exists
- **THEN** the system SHALL return `{ "error": { "code": "CONFLICT", "message": "a title with this name already exists" } }` with no `details` field

#### Scenario: Unexpected internal error
- **WHEN** an unhandled error occurs (e.g., database connection failure)
- **THEN** the system SHALL return `500 Internal Server Error` with `{ "error": { "code": "INTERNAL_ERROR", "message": "an unexpected error occurred" } }` and no internal details

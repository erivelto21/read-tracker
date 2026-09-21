# Spec: Title Creation

## Purpose

Defines the behaviour of the title creation capability exposed via `POST /v1/titles`. Covers request validation, uniqueness enforcement, and the structure of all success and error responses.

---

## Requirements

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
- **THEN** the system SHALL return `{ "error": { "code": "BAD_REQUEST", "message": "Bad Request", "details": [{ "field": "...", "message": "<human-readable message>" }] } }`

#### Scenario: Conflict response shape
- **WHEN** the title name already exists
- **THEN** the system SHALL return `{ "error": { "code": "CONFLICT", "message": "a title with this name already exists" } }` with no `details` field

#### Scenario: Unexpected internal error
- **WHEN** an unhandled error occurs (e.g., database connection failure)
- **THEN** the system SHALL return `500 Internal Server Error` with `{ "error": { "code": "INTERNAL_ERROR", "message": "an unexpected error occurred" } }` and no internal details

---

## Frontend Creation Flow Requirements

### Requirement: Open the create modal from the titles list screen
The system SHALL render a button on the titles list screen that opens the create title modal. The modal SHALL be closed by default and open only when the user activates the button.

#### Scenario: User clicks the add button
- **WHEN** the user clicks the "Add title" button on the titles list screen
- **THEN** the system SHALL display the create title modal in step 1 (type selection)

#### Scenario: User dismisses the modal
- **WHEN** the user clicks the backdrop, presses Escape, or clicks the close (×) button
- **THEN** the system SHALL close the modal and discard any unsaved form state

---

### Requirement: Select title type in step 1
The system SHALL present a type-selection step as the first screen of the create modal, using a segmented control that shows all available title types. The user MUST select a type before proceeding.

#### Scenario: All types are displayed
- **WHEN** the create modal opens
- **THEN** the system SHALL display five type options: book, manga, manhua, novel, and article

#### Scenario: User selects a type and proceeds
- **WHEN** the user selects a type and clicks "Next"
- **THEN** the system SHALL advance to step 2 with the selected type visible and the relevant fields rendered

#### Scenario: Next is disabled without a selection
- **WHEN** the create modal is on step 1 and no type has been selected
- **THEN** the system SHALL disable the "Next" button

---

### Requirement: Show conditional fields in step 2 based on type
The system SHALL render only the fields relevant to the selected type in step 2. Fields not applicable to the selected type SHALL NOT be visible.

#### Scenario: Book fields
- **WHEN** the user selected `book` in step 1
- **THEN** step 2 SHALL show: name (required), chapter (required), page (required), observation (optional)

#### Scenario: Manga / manhua / novel fields
- **WHEN** the user selected `manga`, `manhua`, or `novel` in step 1
- **THEN** step 2 SHALL show: name (required), chapter (required), link (required), observation (optional)

#### Scenario: Article fields
- **WHEN** the user selected `article` in step 1
- **THEN** step 2 SHALL show: name (required), observation (optional)

#### Scenario: User navigates back from step 2
- **WHEN** the user clicks "Back" in step 2
- **THEN** the system SHALL return to step 1 with the previously selected type still selected

---

### Requirement: Display inline validation errors from server response
The system SHALL map server-returned field-level errors to the corresponding form fields and display them inline below each field. Errors SHALL be cleared when the user modifies the field value.

#### Scenario: Server returns field validation errors
- **WHEN** the server responds with `400 Bad Request` and a `details` array
- **THEN** the system SHALL render each `{ field, message }` entry below the corresponding input in step 2

#### Scenario: Client-side required field check
- **WHEN** the user submits the form with a required field left empty
- **THEN** the system SHALL prevent submission and display an inline error for each empty required field without making a network request

#### Scenario: Error clears on input change
- **WHEN** the user modifies a field that currently shows an inline error
- **THEN** the system SHALL clear that field's error immediately

---

### Requirement: Display a top-level error banner for non-field errors
The system SHALL show a visible error banner inside the modal when the server returns a conflict or unexpected error. The banner SHALL describe the problem in plain language.

#### Scenario: Duplicate title name (409 Conflict)
- **WHEN** the server responds with `409 Conflict`
- **THEN** the system SHALL display a banner in step 2 with the message from `error.message` and SHALL NOT close the modal

#### Scenario: Unexpected server error (500)
- **WHEN** the server responds with `500 Internal Server Error`
- **THEN** the system SHALL display a generic error banner in step 2 and SHALL NOT close the modal

---

### Requirement: Close modal and refresh list on successful creation
The system SHALL close the create modal and trigger a refresh of the titles list after a title is successfully created.

#### Scenario: Successful creation
- **WHEN** the server responds with `201 Created`
- **THEN** the system SHALL close the modal, reset all form state, and invalidate the titles list query so the new entry appears in the table

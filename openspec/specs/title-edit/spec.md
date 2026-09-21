# Spec: Title Edit

## Purpose

Defines the behaviour for editing existing titles from the titles list UI and persisting partial updates through `PATCH /v1/titles/:id`.

---

## Requirements

### Requirement: Open the edit modal from the titles list screen
The system SHALL render an edit (pencil) icon button on each title row that opens the edit title modal. The button SHALL be positioned to the left of the existing delete button, follow the same hover-reveal pattern (`opacity-0 group-hover:opacity-100`), and pass the full `Title` object to the modal.

#### Scenario: User clicks the edit icon
- **WHEN** the user hovers over a title row and clicks the pencil icon
- **THEN** the system SHALL display the `EditTitleModal` pre-filled with that title's current values

#### Scenario: Edit icon is hidden until hover
- **WHEN** the user is not hovering over a title row
- **THEN** the edit icon SHALL NOT be visible

#### Scenario: User dismisses the edit modal
- **WHEN** the user clicks the backdrop, presses Escape, or clicks the close (×) button
- **THEN** the system SHALL close the modal and discard any unsaved form state

---

### Requirement: Show type-conditional editable fields in the edit modal
The system SHALL open the edit modal directly to the fields step (no type-selection step). Only the fields editable for the title's type SHALL be rendered, pre-populated with the title's current values.

#### Scenario: Edit modal for book
- **WHEN** the user opens the edit modal for a title with `type=book`
- **THEN** the modal SHALL show: chapter, page, observation — all pre-filled with current values

#### Scenario: Edit modal for manga / manhua / novel
- **WHEN** the user opens the edit modal for a title with `type=manga`, `manhua`, or `novel`
- **THEN** the modal SHALL show: chapter, link, observation — all pre-filled with current values

#### Scenario: Edit modal for article
- **WHEN** the user opens the edit modal for a title with `type=article`
- **THEN** the modal SHALL show: observation only — pre-filled with current value

#### Scenario: Title type is displayed but not editable
- **WHEN** the edit modal is open
- **THEN** the modal SHALL display the title's name and type as read-only context in the header; no type-selection control SHALL be rendered

---

### Requirement: Submit a partial update via PATCH
The system SHALL submit only the non-empty fields from the edit form to `PATCH /v1/titles/:id`. Empty fields SHALL be excluded from the payload.

#### Scenario: User updates a field and saves
- **WHEN** the user modifies one or more fields and clicks "Save"
- **THEN** the system SHALL send a `PATCH /v1/titles/:id` request containing only the fields that have a non-empty value

#### Scenario: User clears a field
- **WHEN** the user clears a previously-populated field and saves
- **THEN** the system SHALL exclude that field from the PATCH payload (the existing value is preserved on the server)

#### Scenario: Successful update
- **WHEN** the server responds with `200 OK`
- **THEN** the system SHALL close the modal, reset form state, and invalidate the titles list query so the updated values appear in the table

---

### Requirement: Display inline validation errors from server response on edit
The system SHALL map server-returned field-level errors to the corresponding form fields and display them inline. Errors SHALL be cleared when the user modifies the field value.

#### Scenario: Server returns field validation errors on edit
- **WHEN** the server responds with `400 Bad Request` and a `details` array
- **THEN** the system SHALL render each `{ field, message }` entry below the corresponding input

#### Scenario: Error clears on input change in edit modal
- **WHEN** the user modifies a field that currently shows an inline error
- **THEN** the system SHALL clear that field's error immediately

---

### Requirement: Display a top-level error banner for non-field errors on edit
The system SHALL show a visible error banner inside the edit modal when the server returns an unexpected error.

#### Scenario: Unexpected server error on edit (500)
- **WHEN** the server responds with `500 Internal Server Error`
- **THEN** the system SHALL display a generic error banner and SHALL NOT close the modal

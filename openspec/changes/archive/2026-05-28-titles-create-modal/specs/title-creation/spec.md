## ADDED Requirements

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
The system SHALL present a type-selection step as the first screen of the create modal, showing all available title types. The user MUST select a type before proceeding.

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
- **WHEN** the user selected "book" in step 1
- **THEN** step 2 SHALL show: name (required), chapter (required), page (required), observation (optional)

#### Scenario: Manga / manhua / novel fields
- **WHEN** the user selected "manga", "manhua", or "novel" in step 1
- **THEN** step 2 SHALL show: name (required), chapter (required), link (required), observation (optional)

#### Scenario: Article fields
- **WHEN** the user selected "article" in step 1
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

# Spec: Title Deletion

## Purpose

Defines the behaviour for deleting titles through the API and titles list UI, including deletion confirmation, success handling, and error cases.

---

## Requirements

### Requirement: Delete a title by ID
The system SHALL provide a `DELETE /v1/titles/:id` endpoint that permanently removes the title identified by the given external UUID. The endpoint SHALL be idempotent: on success it SHALL return `204 No Content` with no response body, regardless of whether the title existed prior to the request.

#### Scenario: Successful deletion
- **WHEN** a `DELETE /v1/titles/:id` request is made with a valid existing title ID
- **THEN** the system returns `204 No Content` and the title no longer exists in the database

#### Scenario: Delete non-existent title
- **WHEN** a `DELETE /v1/titles/:id` request is made with an ID that does not match any title
- **THEN** the system returns `204 No Content`

#### Scenario: Repeated deletion is idempotent
- **WHEN** a `DELETE /v1/titles/:id` request is made for a title that was already deleted
- **THEN** the system returns `204 No Content` on every subsequent call

---

### Requirement: Confirm before deleting in UI
The frontend UI SHALL require explicit user confirmation before issuing a delete request. A trash icon button SHALL be hidden by default on each title row and revealed only on row hover. Clicking it SHALL open a confirmation modal displaying the title name and a warning that the action cannot be undone.

#### Scenario: Delete button hidden at rest
- **WHEN** a title row is rendered and the user is not hovering over it
- **THEN** the trash icon button SHALL NOT be visible

#### Scenario: Delete button revealed on hover
- **WHEN** the user hovers over a title row
- **THEN** the trash icon button SHALL become visible

#### Scenario: Confirmation modal shown on click
- **WHEN** the user clicks the trash icon button on a title row
- **THEN** a confirmation modal SHALL appear showing the title name and "Cancel" / "Delete" actions

#### Scenario: Cancel aborts deletion
- **WHEN** the confirmation modal is open and the user clicks "Cancel"
- **THEN** the modal SHALL close and no delete request SHALL be sent

#### Scenario: Confirm triggers deletion
- **WHEN** the confirmation modal is open and the user clicks "Delete"
- **THEN** the system SHALL send `DELETE /v1/titles/:id` and remove the row from the list on success

#### Scenario: Delete button disabled during in-flight request
- **WHEN** a delete request has been sent and a response has not yet been received
- **THEN** the "Delete" button in the confirmation modal SHALL be disabled to prevent duplicate requests

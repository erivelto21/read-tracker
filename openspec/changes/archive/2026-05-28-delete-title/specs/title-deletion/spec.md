## MODIFIED Requirements

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

## MODIFIED Requirements

### Requirement: Display titles in a filterable table
The system SHALL render a `/titles` page that fetches all titles from `GET /titles` and displays them in a table with columns: Name, Type, Progress, Status, and Actions. Each row SHALL expose an edit (pencil) icon and a delete (trash) icon in the Actions column, both visible on row hover. The Actions column SHALL be wide enough to accommodate both icons side by side.

#### Scenario: Page loads with titles
- **WHEN** the user navigates to `/titles` and the API returns a non-empty list
- **THEN** the system SHALL display a table with one row per title, showing each title's name, type, chapter/page progress, a hardcoded status of `"Reading"`, and an Actions column with edit and delete icons

#### Scenario: Page loads with no titles
- **WHEN** the user navigates to `/titles` and the API returns an empty list
- **THEN** the system SHALL display an empty-state message inside the table area indicating no titles were found

#### Scenario: API request fails
- **WHEN** the user navigates to `/titles` and the API call returns an error
- **THEN** the system SHALL display a visible error message; it SHALL NOT silently fail or render a blank screen

#### Scenario: Page is loading
- **WHEN** the user navigates to `/titles` and the API call is in-flight
- **THEN** the system SHALL display a loading indicator in place of the table

#### Scenario: Actions column shows both icons on hover
- **WHEN** the user hovers over a title row
- **THEN** the system SHALL reveal both the edit icon (left) and the delete icon (right) with the `opacity-0 group-hover:opacity-100` transition

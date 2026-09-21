## ADDED Requirements

### Requirement: Display titles in a filterable table
The system SHALL render a `/titles` page that fetches all titles from `GET /titles` and displays them in a table with columns: Name, Type, Chapter, Page, and Status.

#### Scenario: Page loads with titles
- **WHEN** the user navigates to `/titles` and the API returns a non-empty list
- **THEN** the system SHALL display a table with one row per title, showing each title's name, type, chapter, page, and a hardcoded status of `"Reading"`

#### Scenario: Page loads with no titles
- **WHEN** the user navigates to `/titles` and the API returns an empty list
- **THEN** the system SHALL display an empty-state message inside the table area indicating no titles were found

#### Scenario: API request fails
- **WHEN** the user navigates to `/titles` and the API call returns an error
- **THEN** the system SHALL display a visible error message; it SHALL NOT silently fail or render a blank screen

#### Scenario: Page is loading
- **WHEN** the user navigates to `/titles` and the API call is in-flight
- **THEN** the system SHALL display a loading indicator in place of the table

### Requirement: Filter titles by name with live search
The system SHALL provide a text input in the toolbar that filters the titles table by name in real-time, with a debounce of approximately 300ms.

#### Scenario: User types a name filter
- **WHEN** the user types a value into the name filter input and 300ms have elapsed
- **THEN** the system SHALL re-fetch titles using `GET /titles?name=<value>` and update the table to show only matching results

#### Scenario: User clears the name filter
- **WHEN** the user clears the name filter input
- **THEN** the system SHALL re-fetch titles without the `name` parameter and display all titles

#### Scenario: Filter does not require a submit button
- **WHEN** the user types into the name filter input
- **THEN** the system SHALL NOT require the user to press any button to apply the filter

### Requirement: Filter titles by type with a select
The system SHALL provide a select element in the toolbar with options: `All`, `book`, `manga`, `manhua`, `novel`, `article`. Selecting a type SHALL immediately filter the table.

#### Scenario: User selects a specific type
- **WHEN** the user selects a type (e.g., `manga`) from the type select
- **THEN** the system SHALL re-fetch titles using `GET /titles?type=manga` and update the table to show only titles of that type

#### Scenario: User selects All
- **WHEN** the user selects `All` from the type select
- **THEN** the system SHALL re-fetch titles without the `type` parameter and display all types

#### Scenario: Name and type filters compose with AND logic
- **WHEN** the user has both a name filter value and a type selected (not `All`)
- **THEN** the system SHALL request `GET /titles?name=<value>&type=<type>` and display only titles matching both conditions

### Requirement: Apply light-blue and black colour theme
The system SHALL style the titles list screen using a light-blue (`sky-*`) Tailwind palette with black text, with no inline `style` props.

#### Scenario: Page background and toolbar are styled
- **WHEN** the user views the `/titles` page
- **THEN** the page background SHALL use `bg-sky-100`, the toolbar SHALL use `bg-sky-200`, and the table header row SHALL use `bg-sky-300`

#### Scenario: Table rows alternate colours
- **WHEN** the titles table renders multiple rows
- **THEN** even rows SHALL use a white background and odd rows SHALL use `bg-sky-50`; rows SHALL highlight with `bg-sky-100` on hover

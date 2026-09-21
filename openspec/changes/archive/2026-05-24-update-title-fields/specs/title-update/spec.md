## ADDED Requirements

### Requirement: Partial update of a title's mutable fields
The system SHALL expose a `PATCH /titles/:id` endpoint that updates only the fields provided in the request body. Fields not present in the request body SHALL remain unchanged. The `:id` path parameter refers to the title's public `ExternalID` (UUID).

#### Scenario: Update a single field
- **WHEN** a client sends `PATCH /titles/:id` with a valid `id` and body `{ "chapter": 10 }`
- **THEN** the system updates only `chapter` to `10`, leaves all other fields unchanged, and returns `200` with the full updated title

#### Scenario: Update multiple fields at once
- **WHEN** a client sends `PATCH /titles/:id` with a valid `id` and body `{ "chapter": 5, "page": 120, "observation": "great arc" }`
- **THEN** the system updates all three provided fields, leaves `link` unchanged, and returns `200` with the full updated title

#### Scenario: Title not found
- **WHEN** a client sends `PATCH /titles/:id` with an `id` that does not match any existing title
- **THEN** the system returns `404` with error code `NOT_FOUND`

### Requirement: Empty update body is rejected
The system SHALL reject a `PATCH /titles/:id` request that contains none of the updatable fields.

#### Scenario: Empty JSON object body
- **WHEN** a client sends `PATCH /titles/:id` with body `{}`
- **THEN** the system returns `400` with error code `BAD_REQUEST`

#### Scenario: Body with only unknown fields
- **WHEN** a client sends `PATCH /titles/:id` with a body that contains no recognised updatable fields
- **THEN** the system returns `400` with error code `BAD_REQUEST`

### Requirement: Updatable fields are validated on update
The system SHALL apply the same validation rules to each updatable field on `PATCH` as on `POST /titles`. Invalid values SHALL be rejected with field-level error details.

#### Scenario: chapter below minimum
- **WHEN** a client sends `PATCH /titles/:id` with body `{ "chapter": -200 }`
- **THEN** the system returns `400` with error code `BAD_REQUEST` and a field error on `Chapter` indicating the minimum value

#### Scenario: page above maximum
- **WHEN** a client sends `PATCH /titles/:id` with body `{ "page": 99999 }`
- **THEN** the system returns `400` with error code `BAD_REQUEST` and a field error on `Page` indicating the maximum value

#### Scenario: link is not a valid URL
- **WHEN** a client sends `PATCH /titles/:id` with body `{ "link": "not-a-url" }`
- **THEN** the system returns `400` with error code `BAD_REQUEST` and a field error on `Link` indicating it must be a valid URL

#### Scenario: observation exceeds maximum length
- **WHEN** a client sends `PATCH /titles/:id` with body `{ "observation": "<string longer than 500 chars>" }`
- **THEN** the system returns `400` with error code `BAD_REQUEST` and a field error on `Observation` indicating the maximum length

#### Scenario: all provided fields are valid
- **WHEN** a client sends `PATCH /titles/:id` with a body containing only valid field values
- **THEN** the system applies the update and returns `200` with the updated title

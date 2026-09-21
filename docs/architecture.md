# Architecture

A high-level overview of the **read-tracker** system: its components, how they communicate, and how they are deployed.

---

## System Topology

The macro view — from user to storage.

```mermaid
flowchart LR
    User(["👤 User<br/>(Browser)"])

    subgraph cluster["Kubernetes Cluster"]
        Ingress["nginx<br/>(Ingress + Static Front)"]
        API["tracker<br/>(Go REST API)"]
        Crawler["nightcrawler<br/>(Go Crawler)"]
    end

    DB[("MongoDB")]

    subgraph external["External"]
        Sites["Manga / Novel<br/>Sites"]
    end

    User -->|"HTTPS"| Ingress
    Ingress -->|"HTTP /v1"| API
    API -->|"read / write"| DB
    Crawler -->|"scheduled crawl"| Sites
    Crawler -->|"read / write"| DB
```

---

## Workloads

| Workload | Path | Role |
|---|---|---|
| **tracker** | `tracker/` | REST API — persists and retrieves reading progress |
| **nightcrawler** | `nightcrawler/` | Crawler — fetches newly released chapters from external sites |
| **front** | `front/` | Browser UI — built into static files and served directly by nginx *(coming soon)* |

---

## Public API Endpoints

Base path: `/v1`

| Method | Path | Description | Handler |
|---|---|---|---|
| `GET` | `/titles` | List titles (filter by `type`, `name`) | `tracker/handler/title.go:ListTitles` |
| `POST` | `/titles` | Create a new title | `tracker/handler/title.go:CreateTitle` |
| `PATCH` | `/titles/:id` | Partial update (chapter, page, link, observation) | `tracker/handler/title.go:UpdateTitle` |
| `DELETE` | `/titles/:id` | Delete a title | `tracker/handler/title.go:DeleteTitle` |
| `GET` | `/healthz` | Health check (liveness probe) | `tracker/cmd/api/main.go` (inline) |
| `GET` | `/swagger/*` | Swagger UI | `tracker/cmd/api/main.go` (gin-swagger) |

---

## tracker — Internal Architecture

The API follows **Clean Architecture**: each layer depends only on the layer below it via interfaces, and the domain has no outward dependencies.

The following sequence diagrams show the request flow for each API router: handler validation, usecase invocation, repository persistence, and DB interaction.

```mermaid
sequenceDiagram
  participant C as Client
  participant H as TitleHandler
  participant U as TitleUsecase
  participant R as MongoTitleRepository
  participant DB as MongoDB

  C->>H: POST /v1/titles
  alt invalid input
    H-->>C: 400 Bad Request
  else valid
    H->>U: CreateTitle(req)
    alt already exists
      U-->>H: ErrAlreadyExists
      H-->>C: 409 Conflict
    else created
      U->>R: Save(title)
      R->>DB: insert document
      DB-->>R: insert result
      R-->>U: saved
      U-->>H: created
      H-->>C: 201 Created
    end
  end
```

```mermaid
sequenceDiagram
  participant C as Client
  participant H as TitleHandler
  participant U as TitleUsecase
  participant R as MongoTitleRepository
  participant DB as MongoDB

  C->>H: GET /v1/titles?filters
  H->>U: ListTitles(filters)
  U->>R: Query(filters)
  R->>DB: find
  DB-->>R: results
  R-->>U: titles
  U-->>H: titles
  H-->>C: 200 OK
```

```mermaid
sequenceDiagram
  participant C as Client
  participant H as TitleHandler
  participant U as TitleUsecase
  participant R as MongoTitleRepository
  participant DB as MongoDB

  C->>H: PATCH /v1/titles/:id
  H->>H: validate input
  H->>U: UpdateTitle(id, patch)
  U->>R: Update(id, changes)
  R->>DB: updateOne
  DB-->>R: update result
  R-->>U: updated
  U-->>H: updated
  H-->>C: 200 OK
```

```mermaid
sequenceDiagram
  participant C as Client
  participant H as TitleHandler
  participant U as TitleUsecase
  participant R as MongoTitleRepository
  participant DB as MongoDB

  C->>H: DELETE /v1/titles/:id
  H->>H: parse id / validate
  H->>U: DeleteTitle(id)
  U->>R: Delete(id)
  R->>DB: deleteOne
  DB-->>R: delete result
  R-->>U: deleted
  U-->>H: deleted
  H-->>C: 204 No Content
```

```mermaid
sequenceDiagram
  participant C as Client
  participant H as HealthHandler
  participant DB as MongoDB

  C->>H: GET /v1/healthz
  H->>DB: ping
  DB-->>H: ok
  H-->>C: 200 OK
```

```mermaid
sequenceDiagram
  participant C as Client
  participant I as Ingress/nginx
  participant API as tracker
  participant S as StaticFiles/Swagger

  C->>I: GET /v1/swagger/*
  I->>API: proxy request
  API->>S: fetch swagger assets
  S-->>API: html/js
  API-->>I: 200 OK
  I-->>C: 200 OK
```

(Health and swagger endpoints are simple probes and do not modify domain state.)


### Domain Model

```mermaid
classDiagram
    class Title {
        +string ExternalID
        +string Name
        +TitleType Type
        +int? Chapter
        +int? Page
        +string? Link
        +string? Observation
    }

    class TitleType {
        <<enumeration>>
        book
        manga
        manhua
        novel
        article
    }

    Title --> TitleType
```

---


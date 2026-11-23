# nightcrawler

Go crawler that checks the titles you are reading for chapters newer than the
one you last reached, and notifies you when it finds one.

## How it works

The crawler holds no list of sites. Every run it reads the `titles` collection
and takes the three fields it needs from each crawlable title:

| Field | Used for |
|---|---|
| `link` | the page that lists the chapters |
| `selector` | the CSS selector that picks the chapter entries on that page |
| `chapter` | the chapter you last reached, so only newer ones are reported |

A title is crawlable when its type is `manga`, `manhua` or `novel`. Books are
read by page and articles are a single URL, so neither has a chapter list.

Adding a site, or fixing a selector when a site changes its layout, is an edit
to the title through the API — no release required.

The latest chapter is the highest number found on the page. A page that yields
no chapter is reported as such rather than treated as "no new chapters".

## Running

Requires Go 1.25+ and a reachable MongoDB.

```bash
export MONGO_URI="mongodb://localhost:27017"
export DB_NAME="read_tracker"

make run      # one crawl, then exit
```

The crawler is a one-shot process: it crawls, reports, and exits. Scheduling it
is the deployment's job, not the binary's.

## Environment

| Variable | Required | Description |
|---|---|---|
| `MONGO_URI` | yes | MongoDB connection string |
| `DB_NAME` | yes | database holding the `titles` collection |

## Commands

| Target | Description |
|---|---|
| `make run` | run one crawl |
| `make build` | compile to `bin/nightcrawler` |
| `make test` | run the test suite |
| `make test-race` | run the suite with the race detector |
| `make lint` | run golangci-lint |
| `make fmt` | format with gofmt and goimports |

## Structure

```
nightcrawler/
├── cmd/crawler/     entrypoint: config, Mongo connection, wiring
├── config/          environment configuration
├── crawler/         the run itself: fetch, extract, compare, notify
├── repository/      reads crawlable titles from MongoDB
└── notification/    where a new chapter is reported
```

## Docker

Built from the repository root:

```bash
make build-crawler
```

The image runs the binary as a non-root user and expects `MONGO_URI` and
`DB_NAME` in its environment.
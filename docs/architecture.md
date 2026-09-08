# Architecture

OSWatcher is a pipeline. An OS image goes in at one end; a queryable graph comes out the other.

```
        ISO  /  cloud golden image  /  raw disk image
                          │
                          ▼
              ┌───────────────────────┐
              │      osw-builder      │  build the VM with Packer, install updates,
              │   (capture pipeline)  │  mount the disk offline via libguestfs
              └───────────┬───────────┘
                          │
              ┌───────────┴───────────┐
              ▼                       ▼
     ┌─────────────────┐   ┌────────────────────────┐
     │     neogit      │──▶│   oswatcher-plugins    │  extract symbols, parsed
     │ Merkle snapshot │   │       (analysis)       │  structs, registry hives
     └────────┬────────┘   └───────────┬────────────┘
              │                        │
              ▼                        ▼
     ┌──────────────────────────────────────────────┐
     │  Neo4j    commits, trees, blobs, enrichment  │
     │  + oswatcher-procedures (custom tree diff)   │
     │  MinIO / S3    file contents keyed by SHA-1  │
     └──────────────────────┬───────────────────────┘
                            ▼
              ┌───────────────────────────┐
              │  graphql-api  →  frontend │
              └───────────────────────────┘
                            ▲
              orchestrated by this repository
```

## The deployment stack

`docker compose up -d` in this repository brings up six services:

| Service | Image | Role |
|---------|-------|------|
| **Neo4j** | `neo4j` + APOC | Graph database holding OS snapshots as Merkle trees |
| **procedure-init** | `ghcr.io/oswatcher/oswatcher-procedures` | Installs the [custom Neo4j diff procedures](https://github.com/OSWatcher/oswatcher-procedures) JAR into Neo4j's plugin volume before the database starts |
| **MinIO** | `minio/minio` | S3-compatible object storage for file blobs |
| **minio-init** | `minio/mc` | Creates the read-only blob-download user and sets the bucket policy |
| **API** | `ghcr.io/oswatcher/graphql-api` | GraphQL API over the graph |
| **Traefik** | `traefik` | Reverse proxy and TLS termination |
| **Frontend** | `ghcr.io/oswatcher/frontend` | Vue 3 web UI (published image in production, sibling checkout in development) |

## Compose file layout

The stack is a base file plus one overlay:

| File | Purpose |
|------|---------|
| `compose.yml` | Base service definitions. Not runnable on its own: the `api` service has no image or build context until an overlay supplies one. |
| `compose.prod.yml` | Runs published images from GHCR. Selected by the committed `.env`, both for local evaluation and on a server. |
| `compose.dev.yml` | Builds the API, frontend and Neo4j procedures from sibling checkouts. See [development.md](development.md). |

The committed `.env` sets `COMPOSE_FILE=compose.yml:compose.prod.yml`, so a plain
`docker compose up -d` runs the production overlay. Development needs the explicit
`-f compose.yml -f compose.dev.yml`.

## Why a graph

Git already content-addresses a filesystem snapshot: identical files share a blob, identical
subtrees share a tree object. OSWatcher keeps that model but moves the object graph into Neo4j so
that:

- traversal works in **both** directions (a blob can enumerate every commit that contains it), and
- analysis output (symbols, structs, registry values) attaches to the same graph as first-class
  nodes, deduplicated and diffable exactly like file bytes.

[neogit](https://github.com/OSWatcher/neogit) is the library that implements this. Its
[Why neogit?](https://github.com/OSWatcher/neogit/blob/master/docs/explanation/why-neogit.md)
document is the ten-minute version of the idea.

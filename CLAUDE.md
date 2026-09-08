# CLAUDE.md

Guidance for Claude Code (claude.ai/code) when working in this repository.

## What this repo is

`OSWatcher/oswatcher` is the **entry point** to the OSWatcher project. It holds two things:

1. The project `README.md` and `docs/` (the "start here" material: what OSWatcher is, how the
   pieces fit, which repository to open next).
2. The **Docker Compose deployment stack** that runs the whole platform (Neo4j, MinIO, GraphQL
   API, frontend, Traefik).

It also carries the git history of the original 2016 single-repo OSWatcher framework, preserved
at the `v0-legacy` tag. Do not rewrite or drop that history.

## Core commands

### Local evaluation (published images)
```bash
docker compose up -d      # committed .env selects compose.yml + compose.prod.yml
docker compose down       # never add -v: it destroys the data volumes
```
No setup or password editing is required for local evaluation.

### Development (build from source)
```bash
docker compose -f compose.yml -f compose.dev.yml up -d --build
docker compose -f compose.yml -f compose.dev.yml down
```
Requires `../graphql-api`, `../frontend` and `../oswatcher-procedures` checked out as siblings.
See `docs/development.md`.

### Production on a server
Same production overlay, different `.env`. See `docs/deployment.md`.

### Backup and restore
```bash
./scripts/neo4j-backup.sh [dev|prod]
./scripts/minio-backup.sh
./scripts/restore-backup-offline.sh <backup_file> [dev|prod]   # neo4j-admin dump restore
./scripts/restore-neo4j-volume.sh <backup.tar.gz> [dev|prod]   # raw volume restore
```
Scripts assume the Compose project name is `oswatcher` (volumes `oswatcher_neo4j_data`,
`oswatcher_minio_data`). `.env` sets `COMPOSE_PROJECT_NAME=oswatcher` so this holds regardless of
the checkout directory name.

### Ansible
`ansible/` deploys self-hosted GitHub Actions runners for `OSWatcher/osw-builder`. It is
unrelated to the Compose stack. See `ansible/README.md`.

## Compose file layout

| File | Role |
|------|------|
| `compose.yml` | Base definitions. Not runnable alone: `api` has no image or build context until an overlay adds one. |
| `compose.prod.yml` | Published GHCR images, security fail-safes (default-password check), server memory defaults. Selected by the committed `.env`. |
| `compose.dev.yml` | Local builds for API, frontend and procedures; verbose Neo4j logging; self-signed TLS from `certs/`. |

## Environment configuration

`.env` is intentionally committed with localhost defaults so `docker compose up -d` works
straight after cloning. Key variables:

- `COMPOSE_PROJECT_NAME` : pinned to `oswatcher`
- `COMPOSE_FILE` : selects the base + production overlay for plain Compose commands
- `DOMAIN` : base domain for production Traefik routing (`api.<DOMAIN>`, `storage.<DOMAIN>`)
- `HTTP_SCHEME` : `http` locally, `https` on a TLS server (HTTPS if unset)
- `BIND_ADDRESS` : host interface for every published port; template uses `127.0.0.1`
- `NEO4J_AUTH` : `none` locally, real credentials on a server
- `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD` : local defaults committed; the production overlay
  rejects the default password
- `NEO4J_HEAP_*`, `NEO4J_PAGECACHE_SIZE` : small local values; size for the corpus on a server
- `SEED_DB` / `SEED_DB_URL` / `SEED_DB_VERSION` : on first boot, `db-seed` downloads the dump at
  `SEED_DB_URL` and loads it before Neo4j starts. `SEED_DB=false` (or an empty URL) starts empty.
  Bump `SEED_DB_VERSION` to re-seed from a refreshed dump.

## Important notes

- **Never `docker compose down -v`.** It removes `neo4j_data` and `minio_data`; recovery is a
  manual restore from backup.
- **Neo4j custom procedures** come from `oswatcher-procedures`. Dev builds the JAR from
  `../oswatcher-procedures` (`procedure-builder`); prod pulls
  `ghcr.io/oswatcher/oswatcher-procedures:latest` (`procedure-init`). Either way the JAR lands in
  the `procedure_plugin` volume and Neo4j waits for the init container before starting.
- **Database seeding** is handled by `db-seed` (`scripts/db-seed.sh`), which Neo4j also waits
  for. It downloads `SEED_DB_URL` into the `db_seed_cache` volume with `wget -c` and runs
  `neo4j-admin database load`. A `.oswatcher-seed-version` marker on `neo4j_data` records what was
  loaded, so it is a no-op on later boots until `SEED_DB_VERSION` changes, and it refuses to
  overwrite a database it did not seed itself.
- **Frontend API URI** is baked as a placeholder and substituted at container start, so no
  rebuild is needed to retarget a deployment. Dev points it at `http://localhost:4000`; prod at
  `<HTTP_SCHEME>://api.<DOMAIN>`.
- **MinIO**: prefer dedicated users (e.g. `api-blob-download`, readonly) over root credentials in
  applications. `minio-init` creates that user from `MINIO_ACCESS_KEY`/`MINIO_SECRET_KEY`.

## Documentation map

| File | Covers |
|------|--------|
| `README.md` | Project overview, quickstart, repository map |
| `docs/architecture.md` | Pipeline and service diagram, compose layout |
| `docs/development.md` | Building the stack from sibling checkouts |
| `docs/building-a-corpus.md` | The default seeded corpus, and building your own with `osw-builder` |
| `docs/deployment.md` | Server setup, updates, rollback, troubleshooting |

## Related repositories

Sibling checkouts for development: `../graphql-api`, `../frontend`, `../oswatcher-procedures`.
Full map in `README.md`.

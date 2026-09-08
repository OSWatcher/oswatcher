# Development

Development mode builds the API, frontend and Neo4j procedures from local checkouts instead of
pulling published images. It authenticates against nothing, so this is the mode for evaluating
or hacking on the services.

## Set up

Clone this repository **and the three components it builds from, as siblings**, or the build
fails on missing contexts:

```bash
git clone https://github.com/OSWatcher/oswatcher
git clone https://github.com/OSWatcher/graphql-api
git clone https://github.com/OSWatcher/frontend
git clone https://github.com/OSWatcher/oswatcher-procedures

cd oswatcher
docker compose -f compose.yml -f compose.dev.yml up -d --build
```

The two `-f` flags are required. `compose.yml` is a base layer that is not runnable alone, and
the committed `.env` selects the production overlay by default; the explicit flags override that
selection for development.

## Endpoints

| Service | URL |
|---------|-----|
| Frontend | <http://localhost:5173> |
| API | <http://api.localhost> (via Traefik) or <http://localhost:4000> |
| Neo4j browser | <http://localhost:7474> |
| MinIO console | <http://localhost:9001> |

## Smoke test

```bash
curl -s -X POST http://localhost:4000/graphql \
  -H 'Content-Type: application/json' \
  -d '{"query":"{ branches { name } }"}'
# {"data":{"branches":[{"name":"win95"},{"name":"winxp-sp3"}, ...]}}
```

Dev mode seeds the ready-to-use corpus on first boot too, like the default stack. Set
`SEED_DB=false` in [`.env`](../.env) to skip the ~2.4 GB download and work against an empty
graph, then fill it with [osw-builder](https://github.com/OSWatcher/osw-builder); see
[building-a-corpus.md](building-a-corpus.md).

## What dev mode changes

- **API and frontend** build from `../graphql-api` and `../frontend`.
- **Neo4j procedures** build from `../oswatcher-procedures` via the `procedure-builder` service
  rather than being pulled from GHCR.
- **Neo4j** runs with verbose query logging and APOC file export enabled.
- **Traefik** serves a self-signed certificate from `certs/` and exposes its dashboard
  (`--api.insecure=true`).
- The frontend is published on host port **5173** and points at the API's published port 4000,
  because `http://api` is a container-internal name the browser cannot resolve.

## Stopping

```bash
docker compose -f compose.yml -f compose.dev.yml down
```

Never pass `-v`: it deletes the `neo4j_data` and `minio_data` volumes.

# OSWatcher

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Stars](https://img.shields.io/github/stars/OSWatcher/oswatcher?style=flat&color=blue)](https://github.com/OSWatcher/oswatcher/stargazers)

> A queryable graph of how operating systems change, release over release.

OSWatcher captures the filesystem and registry of historical OS releases (Windows 95 to 11,
Ubuntu 6.10 to 25.04) offline and stores each one as a content-addressed Merkle graph in Neo4j,
with file contents in S3-compatible object storage. Think of it as git for golden images:
the object graph lives in a database instead of a packfile, so you can walk OS history in any
direction and hang your own extracted data off it.

Ask it which release first shipped a binary, every image that ever contained a given DLL, or how
a registry subtree drifted across a decade of service packs.

## Quickstart

```bash
git clone https://github.com/OSWatcher/oswatcher
cd oswatcher
docker compose up -d
```

That is the whole setup. The repository ships local defaults, so there is nothing to configure,
no passwords to set and no domain to register. Give the services a minute to come up, then open
<http://localhost>.

| Service | URL |
|---------|-----|
| Web UI | <http://localhost> |
| GraphQL API | <http://localhost:4000/graphql> |
| Neo4j browser | <http://localhost:7474> |
| MinIO console | <http://localhost:9001> |

Check the API is alive:

```bash
curl -s -X POST http://localhost:4000/graphql \
  -H 'Content-Type: application/json' \
  -d '{"query":"{ branches { name } }"}'
# {"data":{"branches":[{"name":"win95"},{"name":"winxp-sp3"},{"name":"ubuntu-6.10"}, ...]}}
```

On the first `up -d` the stack downloads a ready-to-use corpus (a Neo4j dump, ~2.4 GB) and
loads it before the database starts, so the graph is queryable straight away. This happens once;
the data then lives in the `neo4j_data` volume and later starts are instant.

To start from an empty graph instead and build OS history yourself from installation media
with [osw-builder](https://github.com/OSWatcher/osw-builder), set `SEED_DB=false` in
[`.env`](.env) before the first `up -d`. See [docs/building-a-corpus.md](docs/building-a-corpus.md).

Stop the stack and keep its data:

```bash
docker compose down
```

> **Never run `docker compose down -v`.** It deletes the volumes holding the database and the
> blob storage.

## What you can ask it

Git content-addresses snapshots too, but its object graph is forward-only: a commit points at its
files and never the reverse. Putting the same objects in a graph database makes it possible to
answer questions in a single traversal that git's format can't: how one file, symbol, struct or
registry value evolved across an OS's entire release history; given one artifact, every image
that ever contained it; or corpus-wide aggregates, such as which characteristics stay most stable
across a decade of releases.

## The repositories

This repository is the entry point and runs the stack. `neogit` and `oswatcher-plugins` build the
graph as OS images are captured; `osw-builder` drives that capture; `graphql-api` and `frontend`
serve the result. `oswatcher-procedures` is a Neo4j plugin loaded directly into the database.

```mermaid
flowchart LR
    subgraph foundation [ ]
        neogit --> plugins[oswatcher-plugins]
    end

    subgraph capture ["capture (optional, builds a graph from scratch)"]
        packer[packer-templates] --> builder[osw-builder]
        pywinupdate -. WinRM .-> builder
    end

    neogit --> builder
    plugins --> builder
    builder --> graph[(Neo4j graph)]
    dump([published corpus dump]) --> graph

    subgraph deploy ["this repository: docker compose up -d"]
        procedures[oswatcher-procedures] --> graph
        graph --> api[graphql-api]
        api --> frontend
    end
```

### Core

| Repository | What it is |
|------------|------------|
| [neogit](https://github.com/OSWatcher/neogit) | Git-like content-addressed filesystem snapshots, backed by Neo4j and pluggable object storage. The foundation everything builds on (`pipx install neogit`). |
| [oswatcher-plugins](https://github.com/OSWatcher/oswatcher-plugins) | Capture and analysis plugins that enrich the graph with symbols, parsed structs and registry data. |
| [oswatcher-procedures](https://github.com/OSWatcher/oswatcher-procedures) | User-defined Neo4j procedures, chiefly recursive tree diffing, shipped as a JAR. |

### Capture

| Repository | What it is |
|------------|------------|
| [osw-builder](https://github.com/OSWatcher/osw-builder) | The capture pipeline: ISO to booted VM to captured graph, with optional update chains. |
| [packer-templates](https://github.com/OSWatcher/packer-templates) | Packer templates for the OS images osw-builder builds. |
| [pywinupdate](https://github.com/OSWatcher/pywinupdate) | Automated Windows Update installation over WinRM, used when building update chains. |

### Serve

| Repository | What it is |
|------------|------------|
| [graphql-api](https://github.com/OSWatcher/graphql-api) | GraphQL API over the graph. |
| [frontend](https://github.com/OSWatcher/frontend) | Vue 3 web interface. |

Three archived datasets ([windows-desktop](https://github.com/OSWatcher/windows-desktop),
[ubuntu-server](https://github.com/OSWatcher/ubuntu-server),
[osw-fs-windows](https://github.com/OSWatcher/osw-fs-windows)) hold captures from the original
2016 to 2020 OSWatcher, which committed filesystems straight into git. They are frozen and not
part of the current toolchain.

## Documentation

| Guide | Covers |
|-------|--------|
| [docs/architecture.md](docs/architecture.md) | How the pieces fit together |
| [docs/development.md](docs/development.md) | Running the API, frontend and procedures from source |
| [docs/building-a-corpus.md](docs/building-a-corpus.md) | Filling the graph with osw-builder |
| [docs/deployment.md](docs/deployment.md) | Running on a server: domain, TLS, backups, rollback |

## Contributing and security

Issues and questions are welcome here for anything cross-cutting, or on the specific repository
for anything scoped to it. See
[CONTRIBUTING](https://github.com/OSWatcher/.github/blob/main/CONTRIBUTING.md) and, for
vulnerability reports, [SECURITY](https://github.com/OSWatcher/.github/blob/main/SECURITY.md).

The original single-repo framework (2016 to 2021) is preserved in this repository's history at
the [`v0-legacy`](https://github.com/OSWatcher/oswatcher/tree/v0-legacy) tag.

## License

[Apache 2.0](LICENSE)

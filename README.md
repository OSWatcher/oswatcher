# OSWatcher

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Stars](https://img.shields.io/github/stars/OSWatcher/oswatcher?style=flat&color=blue)](https://github.com/OSWatcher/oswatcher/stargazers)

> A queryable graph of how operating systems change, release over release.

OSWatcher captures the filesystem and registry of historical OS releases (Windows 95 to 11,
Ubuntu 6.10 to 25.04) offline and stores each one as a content-addressed Merkle graph in Neo4j,
with file contents in S3-compatible object storage. Think of it as **git for golden images**:
the object graph lives in a database instead of a packfile, so you can walk OS history in any
direction and hang your own extracted data off it.

Ask it which release first shipped a binary, every image that ever contained a given DLL, or how
a registry subtree drifted across a decade of service packs.

<sub><b>Not the Oracle tool.</b> OSWatcher Black Box (<code>oswbb</code>), Oracle's database metrics
collector, is an unrelated project. This is offline image analysis, not runtime monitoring.</sub>

## Quickstart

```bash
git clone https://github.com/OSWatcher/oswatcher
cd oswatcher
docker compose up -d
```

That is the whole setup. The repository ships local defaults, so there is nothing to configure,
no passwords to set and no domain to register. Give the services a minute to come up, then open
**<http://localhost>**.

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
# {"data":{"branches":[]}}
```

An empty `branches` list is the correct answer on a fresh install. **The graph starts empty by
design**, not because a download is missing: you rebuild OS history yourself from installation
media with [osw-builder](https://github.com/OSWatcher/osw-builder), one release at a time. See
[docs/building-a-corpus.md](docs/building-a-corpus.md).

Stop the stack and keep its data:

```bash
docker compose down
```

> **Never run `docker compose down -v`.** It deletes the volumes holding the database and the
> blob storage.

## What you can ask it

Git content-addresses snapshots too, but its object graph is forward-only: a commit points at its
files and never the reverse. Putting the same objects in a graph database makes three classes of
question answerable in a single traversal:

- **Evolution:** how one file, symbol, struct or registry value changed across an OS's entire
  release history.
- **Provenance:** given one artifact, every image that ever contained it.
- **Commonality:** corpus-wide aggregates, such as which characteristics stay most stable across
  a decade of releases.

## The repositories

This repository is the entry point and runs the stack. The rest of the system:

**Core**

| Repository | What it is |
|------------|------------|
| [neogit](https://github.com/OSWatcher/neogit) | Git-like content-addressed filesystem snapshots, backed by Neo4j and pluggable object storage. The foundation everything builds on (`pipx install neogit`). |
| [oswatcher-plugins](https://github.com/OSWatcher/oswatcher-plugins) | Capture and analysis plugins that enrich the graph with symbols, parsed structs and registry data. |
| [oswatcher-procedures](https://github.com/OSWatcher/oswatcher-procedures) | User-defined Neo4j procedures, chiefly recursive tree diffing, shipped as a JAR. |

**Capture**

| Repository | What it is |
|------------|------------|
| [osw-builder](https://github.com/OSWatcher/osw-builder) | The capture pipeline: ISO to booted VM to captured graph, with optional update chains. |
| [packer-templates](https://github.com/OSWatcher/packer-templates) | Packer templates for the OS images osw-builder builds. |
| [pywinupdate](https://github.com/OSWatcher/pywinupdate) | Automated Windows Update installation over WinRM, used when building update chains. |

**Serve**

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

## Status

Developed since 2016, open-sourced in 2026. Actively developed but **solo-maintained**, so APIs
may change between releases and response times vary. Some security controls (blob-download
authentication, registry redaction) ship disabled in the open-source configuration: review
[docs/deployment.md](docs/deployment.md) before exposing an instance publicly.

## Contributing and security

Issues and questions are welcome here for anything cross-cutting, or on the specific repository
for anything scoped to it. See
[CONTRIBUTING](https://github.com/OSWatcher/.github/blob/main/CONTRIBUTING.md) and, for
vulnerability reports, [SECURITY](https://github.com/OSWatcher/.github/blob/main/SECURITY.md).

The original single-repo framework (2016 to 2021) is preserved in this repository's history at
the [`v0-legacy`](https://github.com/OSWatcher/oswatcher/tree/v0-legacy) tag.

## License

[Apache 2.0](LICENSE)

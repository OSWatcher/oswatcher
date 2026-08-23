# OSWatcher

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

> A queryable graph of how operating systems change, release over release.

**This repository is the entry point to the OSWatcher project.** It contains no code. It explains what the project is, how the pieces fit together, and which repository to open next.

## What it is

OSWatcher builds virtual machine images for historical operating system releases (Windows 95 through 11, Ubuntu 6.10 through 25.04), captures each image's filesystem and registry offline, and stores the result as a content-addressed Merkle graph in Neo4j, with file contents in S3-compatible object storage.

The point is that operating system history becomes something you can **query** instead of something you have to re-derive from scratch every time. Which release first shipped this binary. Every image that ever contained this DLL. How a registry subtree drifted across a decade of service packs. What changed, byte for byte, between two Ubuntu LTS releases.

The closest analogy is **git for golden images**, with the object graph living in a database rather than a packfile, so history can be traversed in any direction and enriched with your own extracted data.

> **Not the Oracle tool.** If you are looking for OSWatcher Black Box (`oswbb`), Oracle's OS metrics collector for database diagnostics, that is an unrelated project. OSWatcher here is offline image analysis, not runtime monitoring.

## What you can ask it

Git content-addresses snapshots too, but its object graph is forward-only: a commit points at its files and never the reverse. Putting the same objects in a graph database makes three classes of question answerable in a single traversal:

- **Evolution** — how one file, symbol, struct or registry value changed across an OS's entire release history.
- **Provenance** — given one artifact, every image that ever contained it.
- **Commonality** — corpus-wide aggregates, such as which characteristics are most stable across a decade of releases.

## Start here

| If you want to... | Go to |
|---|---|
| Understand the core idea in ten minutes | [neogit: Why neogit?](https://github.com/OSWatcher/neogit/blob/master/docs/explanation/why-neogit.md) |
| Run the full stack locally | [Getting started](#getting-started), then [oswatcher-deploy](https://github.com/OSWatcher/oswatcher-deploy) (Docker Compose, six services) |
| Snapshot and diff a filesystem, without the rest | [neogit](https://github.com/OSWatcher/neogit) (`pipx install neogit`) |
| Capture your own OS images | [osw-builder](https://github.com/OSWatcher/osw-builder) (needs KVM, libvirt, Vagrant, Packer) |
| Write an analysis plugin | [oswatcher-plugins](https://github.com/OSWatcher/oswatcher-plugins) |
| Build the corpus and query it | [Getting started](#getting-started) |

## Getting started

The deployment stack is the entry point. It runs in two modes:

- **Development** builds the API, frontend and Neo4j procedures from local checkouts. Nothing to
  authenticate against, so this is the mode to evaluate or hack on the project.
- **Production** pulls pre-built images and expects a domain and real credentials. See
  [oswatcher-deploy](https://github.com/OSWatcher/oswatcher-deploy) for that path.

To bring up the development stack, clone the deploy repo **and the three components it builds from,
as siblings**:

```bash
git clone https://github.com/OSWatcher/oswatcher-deploy
git clone https://github.com/OSWatcher/graphql-api
git clone https://github.com/OSWatcher/frontend
git clone https://github.com/OSWatcher/oswatcher-procedures

cd oswatcher-deploy
cp .env.example .env
docker compose -f compose.yml -f compose.dev.yml up -d --build
```

Note the two `-f` flags. `compose.yml` is a base layer and is not runnable on its own; it needs
either the `dev` or the `prod` overlay.

That gives you Neo4j, MinIO, the GraphQL API, the web frontend and Traefik, with an empty graph:

| Service | URL |
|---|---|
| Frontend | <http://localhost:5173> |
| GraphQL API | <http://localhost:4000/graphql> |
| Neo4j browser | <http://localhost:7474> |
| MinIO console | <http://localhost:9001> |

Check it is alive:

```bash
curl -s -X POST http://localhost:4000/graphql \
  -H 'Content-Type: application/json' \
  -d '{"query":"{ branches { name } }"}'
# {"data":{"branches":[]}}
```

An empty `branches` list is the expected answer on a fresh deployment.

Filling it is the second step, and it is the point of the project. There is deliberately no corpus
to download. [osw-builder](https://github.com/OSWatcher/osw-builder) ships the recipes to rebuild
the history yourself, release by release, and commit each one into the graph:

```bash
osw-builder capture_os win10-22h2-19045.2006
osw-builder capture_os ubuntu-22.04
```

Each capture builds the VM with Packer, installs the updates in order, mounts the resulting disk
offline with libguestfs, and writes a commit. Run a series and you have the timeline. Because you
build it from installation media rather than downloading someone else's database, you control the
editions, the update chain and the exact builds you care about, and you can verify every step.

This is the expensive path by design: it needs KVM, libvirt, Vagrant, Packer and your own
installation media, and a single Windows capture wants the ISO plus room for the VM disk, so budget
tens of gigabytes per release. See [osw-builder](https://github.com/OSWatcher/osw-builder) for the
full prerequisites.

## How the pieces fit

```
        ISO  /  cloud golden image  /  raw disk image
                          │
                          ▼
              ┌───────────────────────┐
              │      osw-builder      │  build VM with Packer, install updates,
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
     │  Neo4j  — commits, trees, blobs, enrichment  │
     │  + oswatcher-procedures (custom tree diff)   │
     │  MinIO / S3 — file contents by SHA-1         │
     └──────────────────────┬───────────────────────┘
                            ▼
              ┌───────────────────────────┐
              │  graphql-api  →  frontend │
              └───────────────────────────┘
                            ▲
              orchestrated by oswatcher-deploy
```

## Repository map

**Core**

| Repository | What it is |
|---|---|
| [neogit](https://github.com/OSWatcher/neogit) | Git-like content-addressed snapshots of a filesystem, backed by Neo4j and pluggable object storage. The foundation everything else builds on. |
| [oswatcher-plugins](https://github.com/OSWatcher/oswatcher-plugins) | Capture and analysis plugins that enrich the graph with symbols, structs, registry data and more. |
| [oswatcher-procedures](https://github.com/OSWatcher/oswatcher-procedures) | User-defined Neo4j procedures, chiefly recursive tree diffing, shipped as a JAR. |

**Capture**

| Repository | What it is |
|---|---|
| [osw-builder](https://github.com/OSWatcher/osw-builder) | The pipeline: ISO to booted VM to captured graph, with optional update chains. |
| [packer-templates](https://github.com/OSWatcher/packer-templates) | Packer templates for the OS images osw-builder builds. |
| [pywinupdate](https://github.com/OSWatcher/pywinupdate) | Automated Windows Update installation over WinRM, used when building update chains. |

**Serve**

| Repository | What it is |
|---|---|
| [oswatcher-deploy](https://github.com/OSWatcher/oswatcher-deploy) | Docker Compose stack tying everything together. The fastest way to see the system running. |
| [graphql-api](https://github.com/OSWatcher/graphql-api) | GraphQL API over the graph. |
| [frontend](https://github.com/OSWatcher/frontend) | Vue 3 web interface. |

**Archived datasets (legacy)**

These come from the original 2016-2020 OSWatcher, which committed captured filesystems straight
into git. They are frozen, read-only, and not part of the current toolchain, which builds the
corpus into Neo4j instead (see [Getting started](#getting-started)). Coverage stops in 2020-2021,
so a file missing from them is not evidence it was never shipped.

| Repository | What it is |
|---|---|
| [windows-desktop](https://github.com/OSWatcher/windows-desktop) | Windows desktop captures, Windows 10 1507 to 20H2. Archived. |
| [ubuntu-server](https://github.com/OSWatcher/ubuntu-server) | Ubuntu server captures, 12.04 to 18.04. Archived. |
| [osw-fs-windows](https://github.com/OSWatcher/osw-fs-windows) | Windows filesystem paths, Windows 98 to Windows 10 20H1. Archived. |

## Status and known gaps

OSWatcher has been developed since 2016 and open-sourced in 2026. It is actively developed but **solo-maintained**, so APIs may change between releases and response times vary.

Two things worth knowing before you invest time:

- **A fresh deployment starts with an empty graph, and you fill it yourself.** This is a design decision, not a missing feature: `osw-builder` ships the recipes to rebuild the Windows and Ubuntu history from installation media and commit it into the graph. It does mean the first useful result is hours away, not minutes, and it needs KVM, libvirt, Vagrant, Packer and your own media. See [Getting started](#getting-started).
- **Some security controls ship disabled by default** in the open-source configuration, including blob download authentication and registry redaction. Review the deployment configuration before exposing an instance publicly.

## Contributing and security

Issues and questions are welcome on this repository for anything cross-cutting, or on the specific repository for anything scoped to it. See [CONTRIBUTING](https://github.com/OSWatcher/.github/blob/main/CONTRIBUTING.md) and, for vulnerability reports, [SECURITY](https://github.com/OSWatcher/.github/blob/main/SECURITY.md).

## History

This repository began in 2016 as the original single-repo OSWatcher framework and kept that history through the 2026 move to the current multi-repository architecture. The original implementation is preserved at the [`v0-legacy`](https://github.com/OSWatcher/oswatcher/tree/v0-legacy) tag.

## License

[Apache 2.0](LICENSE)

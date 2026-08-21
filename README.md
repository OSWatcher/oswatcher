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
| Run the full stack locally | [oswatcher-deploy](https://github.com/OSWatcher/oswatcher-deploy) (Docker Compose, six services) |
| Snapshot and diff a filesystem, without the rest | [neogit](https://github.com/OSWatcher/neogit) (`pipx install neogit`) |
| Capture your own OS images | [osw-builder](https://github.com/OSWatcher/osw-builder) (needs KVM, libvirt, Vagrant, Packer) |
| Write an analysis plugin | [oswatcher-plugins](https://github.com/OSWatcher/oswatcher-plugins) |
| Browse what has been captured | [windows-desktop](https://github.com/OSWatcher/windows-desktop), [ubuntu-server](https://github.com/OSWatcher/ubuntu-server) |

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

**Data**

| Repository | What it is |
|---|---|
| [windows-desktop](https://github.com/OSWatcher/windows-desktop) | Inventory and analysis of captured Windows desktop releases. |
| [ubuntu-server](https://github.com/OSWatcher/ubuntu-server) | Inventory and analysis of captured Ubuntu server releases. |

## Status and known gaps

OSWatcher has been developed since 2016 and open-sourced in 2026. It is actively developed but **solo-maintained**, so APIs may change between releases and response times vary.

Two things worth knowing before you invest time:

- **A fresh deployment starts with an empty graph.** Populating it currently means running `osw-builder` yourself, which needs KVM, libvirt, Vagrant, Packer, and your own installation media. A downloadable seed dataset is planned and not yet published.
- **Some security controls ship disabled by default** in the open-source configuration, including blob download authentication and registry redaction. Review the deployment configuration before exposing an instance publicly.

## Contributing and security

Issues and questions are welcome on this repository for anything cross-cutting, or on the specific repository for anything scoped to it. See [CONTRIBUTING](https://github.com/OSWatcher/.github/blob/main/CONTRIBUTING.md) and, for vulnerability reports, [SECURITY](https://github.com/OSWatcher/.github/blob/main/SECURITY.md).

## History

This repository began in 2016 as the original single-repo OSWatcher framework and kept that history through the 2026 move to the current multi-repository architecture. The original implementation is preserved at the [`v0-legacy`](https://github.com/OSWatcher/oswatcher/tree/v0-legacy) tag.

## License

[Apache 2.0](LICENSE)

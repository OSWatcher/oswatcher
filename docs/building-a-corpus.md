# Building a corpus

By default the stack downloads a ready-to-use corpus on first boot (see the
[quickstart](../README.md#quickstart)). Set `SEED_DB=false` in [`.env`](../.env) before the
first `up -d` to start from an empty graph instead, then build OS history yourself:
[osw-builder](https://github.com/OSWatcher/osw-builder) ships the recipes to rebuild each release
from installation media and commit it into the graph. You can also point osw-builder at a
seeded graph to extend it with your own captures.

```bash
osw-builder capture_os win10-22h2-19045.2006
osw-builder capture_os ubuntu-22.04
```

Each capture builds the VM with Packer, installs the updates in order, mounts the resulting disk
offline with libguestfs, and writes a commit into Neo4j. Run a series and you have the timeline.

Because you build from installation media rather than downloading someone else's database, you
control the editions, the update chain and the exact builds you care about, and you can verify
every step.

## What it costs

This is the expensive path by design. A single capture needs:

- **KVM, libvirt, Vagrant and Packer** on the build host
- **Your own installation media** (ISOs, product keys where applicable)
- **Tens of gigabytes** of disk per release, for the ISO plus the VM disk

See [osw-builder](https://github.com/OSWatcher/osw-builder) for the full prerequisites and the
[first-capture tutorial](https://oswatcher.github.io/osw-builder/tutorials/first-capture.html),
which goes from zero to a captured Ubuntu image with a single Neo4j container and no product
keys.

## Pointing osw-builder at this stack

osw-builder needs a reachable Neo4j instance and, optionally, MinIO for blob storage. This
stack exposes both on localhost:

- Neo4j: `bolt://localhost:7687` (no auth in the local default configuration)
- MinIO: `http://localhost:9000`, credentials from [`.env`](../.env)

neogit defaults to local-filesystem object storage, so MinIO is only needed when you want blob
contents served through the API and frontend.

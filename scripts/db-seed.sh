#!/usr/bin/env bash
# Populate the Neo4j database from a published OSWatcher corpus dump.
#
# Runs to completion before Neo4j starts (compose.yml: neo4j depends_on db-seed).
# It is idempotent: once a dump is loaded, a marker file on the data volume
# records its version and subsequent runs are no-ops until SEED_DB_VERSION changes.
#
# Controlled entirely by environment:
#   SEED_DB          "true" to enable seeding (default), anything else disables it
#   SEED_DB_URL      HTTP(S) URL of the .dump file; empty disables seeding
#   SEED_DB_VERSION  opaque version tag written to the marker; bump to re-seed

set -euo pipefail

SEED_DB="${SEED_DB:-true}"
SEED_DB_URL="${SEED_DB_URL:-}"
SEED_DB_VERSION="${SEED_DB_VERSION:-}"

DATA_DB="/data/databases/neo4j"
MARKER="/data/.oswatcher-seed-version"
DUMP="/seed/neo4j.dump"

log() { echo "[db-seed] $*"; }

if [ "$SEED_DB" != "true" ] || [ -z "$SEED_DB_URL" ]; then
    log "seeding disabled (SEED_DB=$SEED_DB, URL $([ -n "$SEED_DB_URL" ] && echo set || echo unset)); leaving the database untouched"
    exit 0
fi

if [ -f "$MARKER" ] && [ "$(cat "$MARKER")" = "$SEED_DB_VERSION" ]; then
    log "already seeded with version '$SEED_DB_VERSION'; nothing to do"
    exit 0
fi

if [ -d "$DATA_DB" ] && [ -n "$(ls -A "$DATA_DB" 2>/dev/null)" ] && [ ! -f "$MARKER" ]; then
    log "WARNING: /data already holds a 'neo4j' database that this container did not seed."
    log "Refusing to overwrite it. Remove the neo4j_data volume to seed from scratch."
    exit 0
fi

log "downloading corpus dump from $SEED_DB_URL"
mkdir -p /seed
wget -c --tries=5 --retry-connrefused --waitretry=10 -O "$DUMP" "$SEED_DB_URL"

log "loading dump into database 'neo4j' (this can take a few minutes)"
neo4j-admin database load neo4j --from-path=/seed --overwrite-destination --verbose

echo "$SEED_DB_VERSION" > "$MARKER"
log "seed complete (version '$SEED_DB_VERSION')"

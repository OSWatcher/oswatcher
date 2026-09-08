#!/bin/bash

# Restore Neo4j volume from a tar backup
# Replaces the contents of the neo4j_data Docker volume with the backup.
# Neo4j must be stopped during restore.
#
# Usage: ./scripts/restore-neo4j-volume.sh backups/neo4j-data-20260216.tar.gz [dev|prod]

set -eu

BACKUP_FILE="$1"
PROD_DEV="${2:-dev}"
COMPOSE_CMD="docker compose -f compose.yml -f compose.${PROD_DEV}.yml"

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 <backup.tar.gz> [dev|prod]"
    exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file '$BACKUP_FILE' not found"
    exit 1
fi

echo "Stopping Neo4j..."
$COMPOSE_CMD stop neo4j

echo "Restoring from $BACKUP_FILE..."
docker run --rm \
    -v oswatcher_neo4j_data:/data \
    -v "$(realpath "$BACKUP_FILE")":/backup/neo4j-data.tar.gz:ro \
    alpine sh -c "rm -rf /data/* && tar xzf /backup/neo4j-data.tar.gz -C /data"

echo "Starting Neo4j..."
$COMPOSE_CMD start neo4j

echo "Waiting for Neo4j to start..."
sleep 10

echo "Verifying restore..."
$COMPOSE_CMD exec neo4j cypher-shell "MATCH (n) RETURN count(n)"

echo "Restore completed!"

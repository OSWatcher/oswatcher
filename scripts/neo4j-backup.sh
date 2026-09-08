#!/bin/bash

# Neo4j volume backup via tar
# Creates a compressed tar of the neo4j_data Docker volume.
# Neo4j must be stopped for a clean copy.
#
# Usage (on prod): ./scripts/neo4j-backup.sh prod
# Usage (on dev):  ./scripts/neo4j-backup.sh dev

set -eu

PROD_DEV="${1:-dev}"
COMPOSE_CMD="docker compose -f compose.yml -f compose.${PROD_DEV}.yml"
BACKUP_DIR="backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/neo4j-data-$TIMESTAMP.tar.gz"

mkdir -p "$BACKUP_DIR"

echo "Stopping Neo4j..."
$COMPOSE_CMD stop neo4j

echo "Creating backup: $BACKUP_FILE"
docker run --rm \
    -v oswatcher_neo4j_data:/data:ro \
    -v "$(pwd)/$BACKUP_DIR":/backup \
    alpine tar czf "/backup/$(basename "$BACKUP_FILE")" -C /data .

echo "Starting Neo4j..."
$COMPOSE_CMD start neo4j

echo "Backup completed: $BACKUP_FILE"
echo "Size: $(du -h "$BACKUP_FILE" | cut -f1)"

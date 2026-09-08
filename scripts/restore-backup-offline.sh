#!/bin/bash

# Offline Neo4j restore with docker compose
BACKUP_FILE="$1"
PROD_DEV="${2:-dev}"
COMPOSE_CMD="docker compose -f compose.yml -f compose.${PROD_DEV}.yml"

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 <backup_file>"
    echo "Example: $0 neo4j-backup.dump"
    exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file '$BACKUP_FILE' not found"
    exit 1
fi

set -eu

# Stop Neo4j service
echo "Stopping Neo4j..."
$COMPOSE_CMD stop neo4j

# Run restore using neo4j-admin container
echo "Restoring backup from $BACKUP_FILE to neo4j database..."
docker run --rm \
  -v $(realpath $BACKUP_FILE):/backup/neo4j.dump \
  -v oswatcher_neo4j_data:/data \
  neo4j/neo4j-admin:latest \
  neo4j-admin database load --from-path=/backup neo4j --overwrite-destination --verbose

# Start Neo4j service
echo "Starting Neo4j..."
$COMPOSE_CMD start neo4j

# Wait and test
echo "Waiting for Neo4j to start..."
sleep 10
echo "Testing restored database..."

$COMPOSE_CMD exec neo4j cypher-shell "SHOW DATABASES"
$COMPOSE_CMD exec neo4j cypher-shell "MATCH (n) RETURN count(*)"

echo "Restore completed!"

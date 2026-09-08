#!/bin/bash

# MinIO backup script with heavy compression
set -eu

BACKUP_DIR="backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/minio-backup-$TIMESTAMP.tar.xz"
XZ_OPT='-T0 -9'

mkdir -p "$BACKUP_DIR"

echo "Creating heavily compressed MinIO backup: $BACKUP_FILE"

# Backup with maximum xz compression
docker run --rm \
    -v "$(pwd)/$BACKUP_DIR":/backup \
    -v oswatcher_minio_data:/minio_data:ro \
    ubuntu:latest \
    bash -c "apt-get update -qq && apt-get install -y xz-utils && tar -cvJf /backup/$(basename "$BACKUP_FILE") -C /minio_data ."

echo "Backup completed: $BACKUP_FILE"
echo "Size: $(du -h "$BACKUP_FILE" | cut -f1)"

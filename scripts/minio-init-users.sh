#!/bin/sh
set -e

echo "Waiting for MinIO to be ready..."
until mc alias set myminio http://minio:9000 "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}" 2>/dev/null; do
  echo "MinIO not ready yet, retrying in 2 seconds..."
  sleep 2
done

echo "MinIO is ready!"

# Check if user exists
if mc admin user info myminio "${MINIO_ACCESS_KEY}" 2>/dev/null; then
  echo "User '${MINIO_ACCESS_KEY}' already exists, skipping creation"
else
  echo "Creating user '${MINIO_ACCESS_KEY}' with readonly access..."

  # Generate password or use provided one
  if [ -z "${MINIO_SECRET_KEY}" ]; then
    echo "ERROR: MINIO_SECRET_KEY must be set"
    exit 1
  fi

  mc admin user add myminio "${MINIO_ACCESS_KEY}" "${MINIO_SECRET_KEY}"
  mc admin policy attach myminio readonly --user "${MINIO_ACCESS_KEY}"

  echo "User '${MINIO_ACCESS_KEY}' created successfully with readonly policy"
fi

# Ensure objects bucket is private
echo "Setting 'objects' bucket to private..."
mc anonymous set none myminio/objects 2>/dev/null || echo "Bucket 'objects' policy already set or doesn't exist yet"

echo "MinIO initialization complete!"

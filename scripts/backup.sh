#!/bin/sh

set -eu

now="$(date -u +%Y%m%dT%H%M%SZ)"
retention_days="${BACKUP_RETENTION_DAYS:-7}"

mkdir -p /backups

db_file="/backups/postgres-${now}.sql.gz"
data_file="/backups/moodledata-${now}.tar.gz"

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Starting PostgreSQL backup"
pg_dump --no-owner --no-privileges | gzip -9 > "$db_file"

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Starting moodledata backup"
tar -C /bitnami -czf "$data_file" moodledata

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Applying retention policy: ${retention_days} days"
find /backups -type f -name "postgres-*.sql.gz" -mtime "+${retention_days}" -delete
find /backups -type f -name "moodledata-*.tar.gz" -mtime "+${retention_days}" -delete

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Backup completed"

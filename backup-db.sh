#!/usr/bin/env bash
set -e

PODMAN_SH_LIB="$HOME/projects/podman-sh-lib"
source "$PODMAN_SH_LIB/lib/podman.sh"

BACKUP_DIR="/srv/seafile-data/backups"
ENV_FILE="$HOME/projects/seafile-iac/seafile.env"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

base_log_step "Preparing directories and files."
mkdir -p "$BACKUP_DIR"

export $(grep -E '^(MYSQL_ROOT_PASSWORD)=' "$ENV_FILE" | xargs)

if ! podman ps --format '{{.Names}}' | grep -q "^seafile-db$"; then
    base_log_error "Container seafile-db not started. Backup stopped." >&2
    exit 1
fi

base_log_step "Run backup and rotation."

podman exec -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" seafile-db \
    mysqldump --single-transaction --routines --triggers \
    --databases ccnet_db seafile_db seahub_db \
    | gzip > "$BACKUP_DIR/seafile_db_$TIMESTAMP.sql.gz"

find "$BACKUP_DIR" -type f -name "seafile_db_*.sql.gz" -mtime +3 -delete

base_log_ok "Backup saved in $BACKUP_DIR"

MSG="Backup completed and saved to $BACKUP_DIR"

base_log_ok "$MSG"

source "$HOME/projects/notify-sh-lib/lib/email.sh"
email_send "genre-grunt-dander@duck.com" "Systemd notify - seafile backup" "$MSG" 
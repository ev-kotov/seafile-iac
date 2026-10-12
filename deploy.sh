#!/usr/bin/env bash
set -e

PODMAN_SH_LIB="$HOME/projects/podman-sh-lib"
source "$PODMAN_SH_LIB/lib/podman.sh"

QUADLET_DIR="$HOME/.config/containers/systemd"
USER_UNIT_DIR="$HOME/.config/systemd/user"
PROJECT_DIR="$HOME/projects/seafile-iac"
DATA_DIR="/srv/seafile-data"
PODMAN_SOCK="/run/user/$UID/podman/podman.sock"

base_log_step "Preparing directories and files."

mkdir -p "$DATA_DIR/db"
mkdir -p "$DATA_DIR/seafile"
mkdir -p "$DATA_DIR/backups"

base_log_step "Correct rights."

chmod 755 "$DATA_DIR/backups"
chmod 644 "$PROJECT_DIR/seafile.env"
chmod +x "$PROJECT_DIR/backup-db.sh"

base_log_step "Containers. Creating Quadlet symlinks."

ln -sf "$PROJECT_DIR/seafile-db.container" "$QUADLET_DIR/"
ln -sf "$PROJECT_DIR/seafile-memcached.container" "$QUADLET_DIR/"
ln -sf "$PROJECT_DIR/seafile-server.container" "$QUADLET_DIR/"

base_log_step "Services and timers. Creating systemd unit symlinks."

ln -sf "$PROJECT_DIR/seafile-backup.service" "$USER_UNIT_DIR/"
ln -sf "$PROJECT_DIR/seafile-backup.timer" "$USER_UNIT_DIR/"

base_log_step "Reloading systemd user configuration"
systemctl --user daemon-reload

base_log_step "Restart user services"
systemctl --user restart seafile-server.service

base_log_step "Start timers"
systemctl --user enable --now seafile-backup.timer

base_log_step "Check status... Please, waiting."
sleep 3
systemctl --user status seafile-server.service --no-pager
podman ps --filter name=seafile-server
systemctl --user list-timers --no-pager

base_log_ok "Service deployed."
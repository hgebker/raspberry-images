#!/bin/sh
set -eu

# Backs up the SQLite database used by the mvp-vote staging stack
# (see mvp-vote.yml). Run on the Docker host, e.g. via cron, from
# this directory where ./data/local.db is bind-mounted into the app.
#
# Usage: ./mvp-vote-backup.sh [keep_days]

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
DB_FILE="$SCRIPT_DIR/data/local.db"
BACKUP_DIR="$SCRIPT_DIR/backups"
KEEP_DAYS="${1:-7}"

if [ ! -f "$DB_FILE" ]; then
	echo "No database found at $DB_FILE" >&2
	exit 1
fi

mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +%Y-%m-%dT%H-%M-%S)
BACKUP_FILE="$BACKUP_DIR/local-$TIMESTAMP.db"

# Use sqlite3's online backup API so a concurrently-writing app can't
# leave the copy in a half-written state (a plain `cp` can).
sqlite3 "$DB_FILE" ".backup '$BACKUP_FILE'"

echo "Backed up $DB_FILE -> $BACKUP_FILE"

find "$BACKUP_DIR" -name 'local-*.db' -mtime "+$KEEP_DAYS" -delete

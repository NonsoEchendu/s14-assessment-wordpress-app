#!/bin/bash

APP_DIR="$HOME/s14-assessment-wordpress-app"
BACKUP_ROOT_DIR="$HOME/wordpress_backups"
# WORDPRESS_SERVICE_NAME and DB_SERVICE_NAME should tally with the service names the docker-compose.yml file
WORDPRESS_SERVICE_NAME="wordpress"
DB_SERVICE_NAME="db"
WORDPRESS_DATA_PATH="/var/www/html"

# days to keep backups
RETENTION_DAYS=7

TIMESTAMP=$(date +%Y%m%d%H%M%S)
BACKUP_DIR="$BACKUP_ROOT_DIR/$TIMESTAMP"

# ensure backup root directory exists
mkdir -p "$BACKUP_ROOT_DIR"

# create timestamped backup directory
mkdir "$BACKUP_DIR"

LOG_FILE="$BACKUP_DIR/backup.log"


# --- backup starting.... ---

echo "Starting backup at $TIMESTAMP" > "$LOG_FILE"
echo "Backup directory: $BACKUP_DIR" >> "$LOG_FILE"

# --- get db credentials from .env ---
if [ -f "$APP_DIR/.env" ]; then
  echo "Reading DB credentials from $APP_DIR/.env" >> "$LOG_FILE"
  set -a # automatically export variables
  source "$APP_DIR/.env"
  set +a # stop automatically exporting variables

  # mapping .env variables to script variables
  DB_NAME="${WORDPRESS_DB_NAME:-wordpress}"
  DB_USER="${WORDPRESS_DB_USER:-wordpress}"
  DB_PASSWORD="${WORDPRESS_DB_PASSWORD:-password}"
else
  echo "Warning: .env file not found at $APP_DIR/.env. Ensure DB credentials are set in script or environment." >> "$LOG_FILE"
fi

# --- Backup WordPress Files ---
echo "Backing up WordPress files from $WORDPRESS_SERVICE_NAME:$WORDPRESS_DATA_PATH..." >> "$LOG_FILE"
# using docker compose exec to copy files from the running container
cd "$APP_DIR" || { echo "Error: Could not change to app directory." >> "$LOG_FILE" ; exit 1; }
docker compose exec -T $WORDPRESS_SERVICE_NAME tar -czf - $WORDPRESS_DATA_PATH 2>> "$LOG_FILE" > "$BACKUP_DIR/wordpress_files.tar.gz"

if [ $? -eq 0 ]; then
  echo "WordPress files backup successful." >> "$LOG_FILE"
else
  echo "Error: WordPress files backup failed." >> "$LOG_FILE"
  exit 1
fi
cd - >> "$LOG_FILE" 2>&1

# --- Backup MySQL Database ---
echo "Backing up MySQL database '$DB_NAME' from service '$DB_SERVICE_NAME'..." >> "$LOG_FILE"
# using docker compose exec to run mysqldump inside the database container
cd "$APP_DIR" || { echo "Error: Could not change to app directory." >> "$LOG_FILE" ; exit 1; }
docker compose exec -T $DB_SERVICE_NAME mysqldump -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" 2>> "$LOG_FILE"  > "$BACKUP_DIR/database.sql"

if [ $? -eq 0 ]; then
  echo "Database backup successful." >> "$LOG_FILE"
else
  echo "Error: Database backup failed." >> "$LOG_FILE"
  exit 1
fi
cd - >> "$LOG_FILE" 2>&1


# --- Clean up old backups ---
echo "Cleaning up backups older than $RETENTION_DAYS days..." >> "$LOG_FILE"
find "$BACKUP_ROOT_DIR" -maxdepth 1 -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \; >> "$LOG_FILE" 2>&1

echo "Backup finished at $(date +%Y%m%d%H%M%S)" >> "$LOG_FILE"

exit 0

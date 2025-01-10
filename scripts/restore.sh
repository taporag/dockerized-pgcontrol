#!/bin/bash
BACKUP_DIR=$1
CONTAINER_NAME=$2
POSTGRES_USER=$3

echo "Fetching available backups..."
BACKUP_FILES=($(ls -1 "$BACKUP_DIR"/backup_*_*.sql 2>/dev/null))
if [ ${#BACKUP_FILES[@]} -eq 0 ]; then
    echo "No backup files found in $BACKUP_DIR."
    exit 1
fi

echo "Choose restore option:"
echo "1. Restore a full database dump"
echo "2. Restore a specific database backup"
read -p "Enter your choice (1/2): " choice

if [ "$choice" = "1" ]; then
    FULL_BACKUPS=($(ls -1 "$BACKUP_DIR"/backup_all_*.sql 2>/dev/null))
    if [ ${#FULL_BACKUPS[@]} -eq 0 ]; then
        echo "No full database dumps found."
        exit 1
    fi

    echo "Available full database dumps:"
    for i in "${!FULL_BACKUPS[@]}"; do
        echo "$((i + 1)). ${FULL_BACKUPS[$i]}"
    done
    read -p "Enter the number of the dump to restore: " selection
    DUMP_FILE=${FULL_BACKUPS[$((selection - 1))]}
    if [ ! -s "$DUMP_FILE" ]; then
      echo "Error: invalid selection of backup: $DUMP_FILE"
      exit 1
    fi
    docker cp "$DUMP_FILE" "$CONTAINER_NAME:/tmp/full_dump.sql"
    docker exec -i "$CONTAINER_NAME" psql -U "$POSTGRES_USER" -f /tmp/full_dump.sql
    echo "Full database restored successfully."
elif [ "$choice" = "2" ]; then
    echo "Available specific database backups:"
    BACKUP_FILES=($(ls -1 "$BACKUP_DIR"/backup_*_*.sql 2>/dev/null | grep -v "backup_all_"))
    for i in "${!BACKUP_FILES[@]}"; do
        echo "$((i + 1)). ${BACKUP_FILES[$i]}"
    done
    read -p "Enter the number of the backup to restore: " selection
    BACKUP_FILE=${BACKUP_FILES[$((selection - 1))]}
    
    if [ ! -s "$BACKUP_FILE" ]; then
      echo "Error: invalid selection of backup: $BACKUP_FILE"
      exit 1
    fi

    DB_NAME=$(basename "$BACKUP_FILE" | sed -E 's/^backup_([a-zA-Z0-9_-]+)_.*\.sql$/\1/')

    echo "Do you want to restore as (1) a new database or (2) replace the existing one?"
    read -p "Enter choice (1/2): " restore_choice
    if [ "$restore_choice" = "1" ]; then
        NEW_DB_NAME="${DB_NAME}_$(date +%Y%m%d_%H%M%S)"
        docker exec -i "$CONTAINER_NAME" psql -U "$POSTGRES_USER" -c "CREATE DATABASE \"$NEW_DB_NAME\";"
        docker cp "$BACKUP_FILE" "$CONTAINER_NAME:/tmp/backup.sql"
        docker exec -i "$CONTAINER_NAME" psql -U "$POSTGRES_USER" -d "$NEW_DB_NAME" -f /tmp/backup.sql
        echo "Database restored as new: $NEW_DB_NAME"
    elif [ "$restore_choice" = "2" ]; then
        docker exec -i "$CONTAINER_NAME" psql -U "$POSTGRES_USER" -c "DROP DATABASE IF EXISTS \"$DB_NAME\";"
        docker exec -i "$CONTAINER_NAME" psql -U "$POSTGRES_USER" -c "CREATE DATABASE \"$DB_NAME\";"
        docker cp "$BACKUP_FILE" "$CONTAINER_NAME:/tmp/backup.sql"
        docker exec -i "$CONTAINER_NAME" psql -U "$POSTGRES_USER" -d "$DB_NAME" -f /tmp/backup.sql
        echo "Database restored and replaced: $DB_NAME"
    else
        echo "Invalid choice. No restoration performed."
    fi
else
    echo "Invalid choice. No restoration performed."
fi

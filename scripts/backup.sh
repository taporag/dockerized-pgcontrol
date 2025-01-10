# #!/bin/bash
# BACKUP_DIR=$1
# CONTAINER_NAME=$2
# POSTGRES_USER=$3
# TIMESTAMP=$4
# RETENTION_DAYS=$5

# echo "Fetching list of databases..."
# docker exec "$CONTAINER_NAME" psql -U "$POSTGRES_USER" -d postgres -t -c "SELECT datname FROM pg_database WHERE datistemplate = false;" | sed 's/^ *//;s/ *$//' > /tmp/db_list.txt

# echo "Available databases:"
# awk '{printf "\033[1;34m%s\033[0m\n", $0}' /tmp/db_list.txt

# echo "Choose backup option:"
# echo "1. Backup all databases"
# echo "2. Backup specific databases"
# read -p "Enter your choice (1/2): " choice

# if [ "$choice" = "1" ]; then
#     echo "Backing up all databases..."
#     docker exec "$CONTAINER_NAME" pg_dumpall -U "$POSTGRES_USER" > "$BACKUP_DIR/backup_all_$TIMESTAMP.sql"
#     echo "Backup completed: $BACKUP_DIR/backup_all_$TIMESTAMP.sql"
# elif [ "$choice" = "2" ]; then
#     echo "Available databases:"
#     awk '{printf "\033[1;34m%s\033[0m\n", $0}' /tmp/db_list.txt
#     read -p "Enter a space-separated list of databases to back up: " db_list
#     for db in $db_list; do
#         if [ -z "$db" ]; then
#             echo "Invalid database name: $db"
#             exit 1
#         fi
#         echo "Backing up database: $db"
#         docker exec "$CONTAINER_NAME" pg_dump -U "$POSTGRES_USER" "$db" > "$BACKUP_DIR/backup_$db_$TIMESTAMP.sql"
#         echo "Backup for $db completed: $BACKUP_DIR/backup_$db_$TIMESTAMP.sql"
#     done
# else
#     echo "Invalid choice. No backups performed."
# fi

# echo "Removing backups older than $RETENTION_DAYS days..."
# find "$BACKUP_DIR" -type f -name "*.sql" -mtime +"$RETENTION_DAYS" -exec rm -f {} \;

# rm -f /tmp/db_list.txt


#!/bin/bash

BACKUP_DIR=$1
CONTAINER_NAME=$2
POSTGRES_USER=$3
TIMESTAMP=$4
RETENTION_DAYS=$5
OPTION=$6
DB=$7

if [[ -z "$BACKUP_DIR" || -z "$CONTAINER_NAME" || -z "$POSTGRES_USER" || -z "$TIMESTAMP" || -z "$RETENTION_DAYS" ]]; then
    echo "Usage: backup.sh <BACKUP_DIR> <CONTAINER_NAME> <POSTGRES_USER> <TIMESTAMP> <RETENTION_DAYS> [OPTION] [DB]"
    exit 1
fi

echo "Fetching list of databases..."
docker exec "$CONTAINER_NAME" psql -U "$POSTGRES_USER" -d postgres -t -c "SELECT datname FROM pg_database WHERE datistemplate = false;" | sed 's/^ *//;s/ *$//' > /tmp/db_list.txt

echo "Available databases:"
awk '{printf "\033[1;34m%s\033[0m\n", $0}' /tmp/db_list.txt

# Handle backup option
if [[ "$OPTION" == "1" ]]; then
    echo "Backing up all databases..."
    BACKUP_FILE="$BACKUP_DIR/backup_all_$TIMESTAMP.sql"
    docker exec "$CONTAINER_NAME" pg_dumpall -U "$POSTGRES_USER" > "$BACKUP_FILE"
    if [[ ! -s "$BACKUP_FILE" ]]; then
        echo "Error: Backup file was not created or is empty: $BACKUP_FILE"
        exit 1
    fi
    echo "Backup completed: $BACKUP_FILE"
elif [[ "$OPTION" == "2" ]]; then
    if [[ -z "$DB" ]]; then
        echo "Enter a space-separated list of databases to back up: "
        read db_input
        DB=$db_input
    fi
    for db_name in $DB; do
        echo "Backing up database: $db_name..."
        BACKUP_FILE="$BACKUP_DIR/backup_${db_name}_$TIMESTAMP.sql"
        docker exec "$CONTAINER_NAME" pg_dump -U "$POSTGRES_USER" "$db_name" > "$BACKUP_FILE"
        if [[ ! -s "$BACKUP_FILE" ]]; then
            echo "Error: Backup file was not created or is empty: $BACKUP_FILE"
            exit 1
        fi
        echo "Backup for $db_name completed: $BACKUP_FILE"
    done
else
    echo "Choose backup option:"
    echo "1. Backup all databases"
    echo "2. Backup specific databases"
    read -p "Enter your choice (1/2): " choice
    exec bash "$0" "$BACKUP_DIR" "$CONTAINER_NAME" "$POSTGRES_USER" "$TIMESTAMP" "$RETENTION_DAYS" "$choice"
fi

echo "Removing backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -type f -name "*.sql" -mtime +"$RETENTION_DAYS" -exec rm -f {} \;

rm -f /tmp/db_list.txt

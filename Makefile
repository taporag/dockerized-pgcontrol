.DEFAULT_GOAL := help

# Load environment variables from .env file
ifeq (,$(wildcard .env))
  $(warning .env file not found. Using default values.)
else
  include .env
  export $(shell sed 's/=.*//' .env)
endif

POSTGRES_VERSION ?= 15
POSTGRES_CONTAINER_NAME ?= postgres-container
POSTGRES_PORT ?= 5432
POSTGRES_USER ?= postgres
POSTGRES_PASSWORD ?= postgres
BACKUP_DIR ?= ./backups
BACKUP_RETENTION_DAYS ?= 15
SCRIPTS_DIR ?= ./scripts

REQUIRED_VARS = POSTGRES_VERSION POSTGRES_CONTAINER_NAME POSTGRES_PORT POSTGRES_USER POSTGRES_PASSWORD BACKUP_DIR BACKUP_RETENTION_DAYS

.PHONY: up down wipe restart healthcheck backup restore list-backups logs tail-logs debug help validate-env

docker-compose-run = docker-compose $(1)

help:
	@echo "Available commands:"
	@echo "  make up                - Start PostgreSQL in production mode."
	@echo "  make down              - Stop and remove PostgreSQL containers."
	@echo "  make wipe              - Stop and remove containers and volumes."
	@echo "  make restart           - Restart PostgreSQL containers."
	@echo "  make healthcheck       - Check the health of PostgreSQL container."
	@echo "  make backup OPTION=<1|2> DB=<db_name> - Backup PostgreSQL data (all or specific)."
	@echo "  make list-backups      - List all available backups."
	@echo "  make restore           - Restore PostgreSQL data interactively."
	@echo "  make logs              - View PostgreSQL logs."
	@echo "  make tail-logs         - Tail PostgreSQL logs in real-time."
	@echo "  make debug             - Start containers in debug mode."

validate-env:
	@$(foreach var,$(REQUIRED_VARS), \
		$(if $(strip $($(var))),, \
			$(error Missing required environment variable: $(var))))
	@echo "All required environment variables are set."

up:
	@echo "Starting PostgreSQL in production mode..."
	$(call docker-compose-run,up -d)

down:
	@echo "Stopping and removing PostgreSQL containers..."
	$(call docker-compose-run,down --remove-orphans)

wipe:
	@echo "Stopping and removing PostgreSQL containers and volumes..."
	$(call docker-compose-run,down --volumes --remove-orphans)

restart:
	@$(MAKE) down
	@$(MAKE) up

healthcheck:
	@echo "Checking PostgreSQL container health..."
	@docker inspect --format '{{.State.Health.Status}}' $(POSTGRES_CONTAINER_NAME) | grep -q 'healthy' && echo "PostgreSQL container is healthy" || echo "PostgreSQL container is not healthy"

backup:
	@mkdir -p $(BACKUP_DIR)
	@BACKUP_TIMESTAMP=$$(date +%Y-%m-%d_%H-%M-%S); \
	bash $(SCRIPTS_DIR)/backup.sh $(BACKUP_DIR) $(POSTGRES_CONTAINER_NAME) $(POSTGRES_USER) $$BACKUP_TIMESTAMP $(BACKUP_RETENTION_DAYS) $(OPTION) "$(DB)"

list-backups:
	@echo "Available backups in $(BACKUP_DIR):"
	@ls -lh -t $(BACKUP_DIR) | grep -E 'backup_.*\.sql' || echo "No backups found."

restore:
	@bash $(SCRIPTS_DIR)/restore.sh $(BACKUP_DIR) $(POSTGRES_CONTAINER_NAME) $(POSTGRES_USER)

logs:
	@docker logs $(POSTGRES_CONTAINER_NAME)

tail-logs:
	@docker logs -f $(POSTGRES_CONTAINER_NAME)

debug:
	@$(call docker-compose-run,--verbose up -d)

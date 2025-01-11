# Dockerized PostgreSQL Setup with Automated Backup and Restore

Easily set up and manage PostgreSQL databases with Docker. This project simplifies database operations, including automated backups, seamless restores, and container lifecycle management. With support for PostgreSQL and compatibility with Docker Compose, it is ideal for development and production environments. Learn how to safeguard your data with this reliable and efficient solution.

Keywords: PostgreSQL, Docker, Database Backup, Database Restore, Docker Compose, PostgreSQL Management


## Installation & Setup:
To start with this project, first, clone the repository and navigate to the project directory:

```bash
git clone git@github.com:taporag/dockerized-postgresql.git
cd dockerized-pgcontrol
```

This project includes a setup.sh script to simplify the setup process. The script performs the following tasks:

1. Ensures the required dependencies (`make`, `docker`, and `docker-compose`) are installed.
2. Configures all necessary dependencies for the project.
3. Generates a `.env` file containing the required environment variables, including a randomly generated root password for MongoDB.

#### Running the Script
```bash
./setup.sh
```

## Environment Variables

The `.env` file is automatically created by the setup.sh script and must include the following variables:

```dotenv
POSTGRES_VERSION=15                       # PostgreSQL version
POSTGRES_CONTAINER_NAME=postgresql        # Name of the PostgreSQL container
POSTGRES_PORT=5432                        # PostgreSQL port
POSTGRES_USER=                            # Default PostgreSQL username
POSTGRES_PASSWORD=                        # Default PostgreSQL password
POSTGRES_DB=                              # Default database name
BACKUP_DIR=./backups                      # Directory to store backups
BACKUP_RETENTION_DAYS=15                  # Retain backups for 15 days
```

---

## Makefile Commands

| **Command**       | **Description**                                                                                 | **Usage**               |
|-------------------|-------------------------------------------------------------------------------------------------|-------------------------|
| `up`              | Start MongoDB service in detached mode.                                                         | `make up`               |
| `down`            | Stop and remove MongoDB containers.                                                             | `make down`             |
| `wipe`            | Stop and remove MongoDB containers along with volumes.                                          | `make wipe`             |
| `restart`         | Restart MongoDB service (stop and start).                                                       | `make restart`          |
| `healthcheck`     | Check the health status of the MongoDB container.                                               | `make healthcheck`      |
| `logs`            | View MongoDB logs.                                                                              | `make logs`             |
| `tail-logs`       | Tail MongoDB logs in real-time.                                                                 | `make tail-logs`        |
| `debug`           | Start containers with verbose output for debugging.                                             | `make debug`            |
| `backup`          | Backup MongoDB data with a timestamp.                                                           | `make backup`           |
| `restore`         | Restore MongoDB data from a backup.                                                             | `make restore`          |
| `list-backups`    | List all backup directories in the backup folder.                                               | `make list-backups`     |

---

## License
This project is licensed under the MIT License.

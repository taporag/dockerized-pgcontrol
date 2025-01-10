#!/bin/bash

# Function to install Docker
install_docker() {
    echo "Checking for Docker..."
    if ! command -v docker &> /dev/null; then
        echo "Docker is not installed. Installing Docker now..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            echo "Please install Docker Desktop manually from https://www.docker.com/products/docker-desktop."
            echo "After installation, ensure Docker Desktop is running."
            exit 1
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            sudo apt-get update
            sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io
            sudo systemctl start docker
            sudo systemctl enable docker
            echo "Docker installed successfully."
        else
            echo "Unsupported OS for automatic Docker installation."
            exit 1
        fi
    else
        echo "Docker is already installed."
    fi
}

# Function to install Docker Compose
install_docker_compose() {
    echo "Checking for Docker Compose..."
    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose is not installed. Installing Docker Compose now..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            echo "Please install Docker Compose as part of Docker Desktop."
            echo "Docker Desktop includes Docker Compose functionality."
        else
            # Linux
            sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            echo "Docker Compose installed successfully."
        fi
    else
        echo "Docker Compose is already installed."
    fi
}

# Function to install make
install_make() {
    echo "Checking for make..."
    if ! command -v make &> /dev/null; then
        echo "'make' is not installed. Installing it now..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            xcode-select --install
            echo "Command Line Tools installed successfully (includes 'make')."
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            sudo apt-get update && sudo apt-get install -y build-essential
            echo "'make' installed successfully."
        else
            echo "Unsupported OS for automatic 'make' installation."
            exit 1
        fi
    else
        echo "'make' is already installed."
    fi
}

# Function to generate a random password
generate_random_password() {
    tr -dc 'A-Za-z0-9@#$%!' < /dev/urandom | head -c 16
}

# Function to create or update the .env file
generate_env_file() {
    echo "Generating .env file..."

    POSTGRES_VERSION=${POSTGRES_VERSION:-15}
    POSTGRES_CONTAINER_NAME=${POSTGRES_CONTAINER_NAME:-postgresql}
    POSTGRES_PORT=${POSTGRES_PORT:-5432}
    POSTGRES_USER=${POSTGRES_USER:-admin}
    POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-$(generate_random_password)}
    BACKUP_DIR=${BACKUP_DIR:-./backups}
    BACKUP_RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-15}

    cat <<EOF > .env
POSTGRES_VERSION=${POSTGRES_VERSION}
POSTGRES_CONTAINER_NAME=${POSTGRES_CONTAINER_NAME}
POSTGRES_PORT=${POSTGRES_PORT}
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
BACKUP_DIR=${BACKUP_DIR}
BACKUP_RETENTION_DAYS=${BACKUP_RETENTION_DAYS}
EOF

    echo ".env file created/updated with the following content:"
    cat .env
}

# Main setup
install_docker
install_docker_compose
install_make
generate_env_file

echo "Setup completed successfully!"

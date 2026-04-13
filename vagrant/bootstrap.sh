#!/bin/bash

##############################################################################
# Vagrant Bootstrap Script
# Installs basic requirements and Docker/Docker Compose on Ubuntu 20.04 VM
##############################################################################

set -e  # Exit on error

echo "=========================================="
echo "EscolasApp Vagrant Bootstrap"
echo "=========================================="

# ============================================================================
# System Update
# ============================================================================
echo ""
echo "[1/6] Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# ============================================================================
# Install Dependencies
# ============================================================================
echo ""
echo "[2/6] Installing dependencies..."
sudo apt-get install -y \
    curl \
    wget \
    git \
    ca-certificates \
    gnupg \
    lsb-release \
    apt-transport-https \
    software-properties-common \
    build-essential

# ============================================================================
# Add Docker Repository and Install Docker
# ============================================================================
echo ""
echo "[3/6] Installing Docker..."

# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index with new Docker repo
sudo apt-get update

# Install Docker CE and Docker CLI
sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io

# ============================================================================
# Install Docker Compose
# ============================================================================
echo ""
echo "[4/6] Installing Docker Compose..."

# Download and install Docker Compose
DOCKER_COMPOSE_VERSION="1.29.2"  # Latest stable version compatible with Docker 20.x
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose

# Make executable
sudo chmod +x /usr/local/bin/docker-compose

# Create symlink for docker-compose
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# ============================================================================
# Configure Docker Group
# ============================================================================
echo ""
echo "[5/6] Configuring Docker permissions..."

# Create docker group if it doesn't exist
sudo groupadd docker 2>/dev/null || true

# Add vagrant user to docker group
sudo usermod -aG docker vagrant

# Apply new group membership
newgrp docker <<EOF
exit
EOF

# ============================================================================
# Start Docker Service
# ============================================================================
echo ""
echo "[6/6] Starting Docker service..."

# Enable Docker to start on boot
sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# ============================================================================
# Verification
# ============================================================================
echo ""
echo "=========================================="
echo "Verification"
echo "=========================================="

# Check Docker version
echo ""
echo "Docker version:"
docker --version

# Check Docker Compose version
echo ""
echo "Docker Compose version:"
docker-compose --version

# Test Docker (hello-world)
echo ""
echo "Testing Docker connectivity (hello-world)..."
docker run --rm hello-world > /dev/null 2>&1 && echo "✓ Docker is working" || echo "✗ Docker test failed"

# ============================================================================
# Completion
# ============================================================================
echo ""
echo "=========================================="
echo "Bootstrap Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. ssh into the VM:  vagrant ssh"
echo "  2. Navigate to project:  cd /home/vagrant/escolasapp"
echo "  3. Start containers:  docker-compose up -d"
echo "  4. Access app:  curl http://localhost:3002"
echo ""
echo "See INFRASTRUCTURE.md for detailed usage instructions"
echo ""

# Docker Guide for EscolasApp

Comprehensive guide to building, running, and deploying EscolasApp using Docker and Docker Compose.

---

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Building Images](#building-images)
4. [Running Containers](#running-containers)
5. [Development Workflow](#development-workflow)
6. [Production Deployment](#production-deployment)
7. [Troubleshooting](#troubleshooting)
8. [Docker Compose Reference](#docker-compose-reference)

---

## Overview

### Dockerfile Architecture

The `Dockerfile` uses a **multi-stage build** for optimal image size and security:

**Stage 1: Builder**
- Base image: `node:12-alpine`
- Installs all dependencies (dev + production)
- Runs `npm ci` and `npm run build`
- Produces compiled Angular SPA in `/dist`

**Stage 2: Runtime**
- Base image: `node:12-alpine` (minimal size ~140MB)
- Copies pre-built `dist/` from Stage 1
- Installs production dependencies only
- Runs container as non-root `nodejs` user
- Includes health check
- Exposes port 3002

**Benefits:**
- ✅ Final image size: ~400MB (vs ~600MB without optimization)
- ✅ Security: No build tools in final image
- ✅ Health checks: Automatic restart if unhealthy
- ✅ Non-root user: Reduced attack surface

### Docker Compose Services

**`app` service:**
- Builds from `Dockerfile`
- Exposes port 3002
- Environment-based configuration
- Links to MongoDB service

**`mongodb` service:**
- MongoDB 3.6 official image
- Data persisted to `mongodb_data` volume
- Configuration persistence in `mongodb_config` volume

---

## Quick Start

### Prerequisites

- Docker 19.03+ ([install](https://docs.docker.com/get-docker/))
- Docker Compose 1.25+ ([install](https://docs.docker.com/compose/install/))
- Git

### Clone and Run

```bash
# Clone the repository
git clone https://github.com/cemdevops/escolasapp.git
cd escolasapp

# Copy environment template
cp .env.example .env.development.local

# Start containers
docker-compose up -d

# View logs
docker-compose logs -f app

# Test application
curl http://localhost:3002

# Stop containers
docker-compose down
```

**Output:**
```
Creating escolasapp_mongodb_1 ... done
Creating escolasapp_app      ... done
```

---

## Building Images

### Build Locally

Build the image locally without pushing to registry:

```bash
# Build with default tag
docker build -t escolasapp:latest .

# Build with specific tag
docker build -t escolasapp:v1.0.0 .

# Build without cache (clean build)
docker build --no-cache -t escolasapp:latest .

# Build with build arguments
docker build \
  --build-arg NODE_ENV=production \
  -t escolasapp:latest .
```

### Verify Build

```bash
# List images
docker images | grep escolasapp

# Inspect image details
docker inspect escolasapp:latest

# View image layers
docker history escolasapp:latest
```

### Push to GHCR

```bash
# Login to GHCR
docker login ghcr.io -u YOUR_GITHUB_USERNAME -p YOUR_GHCR_TOKEN

# Tag image for GHCR
docker tag escolasapp:latest ghcr.io/cemdevops/escolasapp:latest

# Push image
docker push ghcr.io/cemdevops/escolasapp:latest

# Verify push
docker pull ghcr.io/cemdevops/escolasapp:latest
```

---

## Running Containers

### Using Docker Compose (Recommended)

Docker Compose is configured with **profiles** to support multiple environments in a single file.

#### Development (with hot-reload)

```bash
# Start development environment with volumes and debug ports
docker-compose --profile dev up -d

# View logs
docker-compose logs -f app-dev
```

**What starts:**
- `app-dev` service on port 3002 with source volumes mounted
- `mongodb` service on port 27017 with admin/admin123 credentials
- Debug port 9229 exposed for Node debugger
- DEBUG logging enabled

#### Staging (production-like)

```bash
# Start staging environment
docker-compose --profile staging up -d

# View logs
docker-compose logs -f app-staging
```

**What starts:**
- `app-staging` service pulling from GHCR registry image
- `mongodb` service accessible on port 27017
- Hardened configuration (no volumes, INFO logging)
- Restart policy: always

#### Production (hardened)

```bash
# Start production environment
docker-compose --profile production up -d

# View logs
docker-compose logs -f app-prod
```

**What starts:**
- `app-prod` service pulling from GHCR registry image
- `mongodb` service (internal only, no exposed port)
- Maximum hardening: no volumes, warn-level logging, security options
- Container port 3002 not exposed (use reverse proxy upstream)

#### Optional Tools (Development)

```bash
# Start with dev profile + mongo-express web UI
docker-compose --profile dev --profile dev-tools up -d

# Access mongo-express at http://localhost:8081
```

### Using Docker Run (Direct)

```bash
# Run app container only
docker run -d \
  --name escolasapp \
  -p 3002:3002 \
  -e NODE_ENV=development \
  -e DB_URL=mongodb://mongodb:27017/escolasapp \
  --link mongodb \
  escolasapp:latest

# Run MongoDB
docker run -d \
  --name mongodb \
  -p 27017:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=admin123 \
  -v mongodb_data:/data/db \
  mongo:3.6
```

### View Running Containers

```bash
# List containers for current environment
# Development:
docker-compose --profile dev ps

# Staging:
docker-compose --profile staging ps

# Production:
docker-compose --profile production ps

# View logs (replace app-dev with app-staging or app-prod for other envs)
docker-compose logs -f app-dev

# View specific number of lines
docker-compose logs --tail 100 app-dev

# View all services logs
docker-compose logs -f
```

---

## Development Workflow

### Hot Reloading for Development

The `docker-compose.yml` with `--profile dev` mounts source code directories:

```yaml
volumes:
  - ./src:/app/src
  - ./routes:/app/routes
  - ./models:/app/models
  - ./app.js:/app/app.js
  - ./bin:/app/bin
  - /app/node_modules
```

**Workflow:**
1. Ensure dev profile is active: `docker-compose --profile dev up -d`
2. Edit Angular files in `src/` on host machine
3. Wait for Angular CLI rebuild in container (if configured)
4. Refresh browser to see changes

**Manual rebuild:**

```bash
# Rebuild Angular SPA
docker-compose --profile dev exec app-dev npm run build

# Rebuild and restart
docker-compose --profile dev exec app-dev npm run build && docker-compose --profile dev restart app-dev
```

### Running Commands in Container

```bash
# Development environment:
docker-compose --profile dev exec app-dev npm install package-name
docker-compose --profile dev exec app-dev npm test
docker-compose --profile dev exec app-dev npm run lint
docker-compose --profile dev exec app-dev npm run e2e
docker-compose --profile dev exec app-dev /bin/sh

# Staging environment:
docker-compose --profile staging exec app-staging npm --version
docker-compose --profile staging exec app-staging node -v

# Production environment:
docker-compose --profile production exec app-prod docker-compose ps
```

### Accessing MongoDB

```bash
# Connect to MongoDB shell
docker-compose exec mongodb mongo

# Inside mongo shell:
use escolasapp
db.schools.find().limit(1)
db.schools.count()
exit

# Or one-liner:
docker exec escolasapp_mongodb_1 mongo --eval "db.schools.count()"
```

### Cleaning Up

```bash
# Stop containers (keep volumes)
docker-compose down

# Stop and remove volumes (data loss)
docker-compose down -v

# Remove specific volume
docker volume rm escolasapp_mongodb_data

# Remove unused images
docker image prune

# Remove unused volumes
docker volume prune

# Full cleanup (containers, images, volumes, networks)
docker system prune -a --volumes
```

---

## Production Deployment

### Pre-deployment Checklist

```bash
# 1. Verify image builds successfully
docker build -t escolasapp:v1.0.0 .

# 2. Test locally
docker run -d -p 3002:3002 escolasapp:v1.0.0

# 3. Verify health check
sleep 10 && curl http://localhost:3002

# 4. Push to registry
docker push ghcr.io/cemdevops/escolasapp:v1.0.0

# 5. Pull on production server and test
docker pull ghcr.io/cemdevops/escolasapp:v1.0.0
```

### Deploy with Ansible

```bash
# Deploy to staging
ansible-playbook \
  -i ansible/inventories/staging/hosts \
  ansible/playbooks/deploy.yml \
  --vault-password-file ~/.ansible-vault-pass

# Deploy to production
ansible-playbook \
  -i ansible/inventories/production/hosts \
  ansible/playbooks/deploy.yml \
  --vault-password-file ~/.ansible-vault-pass
```

### Manual Production Deployment

```bash
# SSH to production server
ssh -i ~/.ssh/prod_key admin@prod.example.com

# Login to GHCR
docker login ghcr.io -u $GITHUB_USERNAME -p $GHCR_TOKEN

# Pull latest image
docker pull ghcr.io/cemdevops/escolasapp:latest

# Stop old container
docker-compose down

# Start new container with production overrides
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Verify
docker-compose ps
curl http://localhost:3002
```

### Using Docker Swarm/Stack (Optional)

```bash
# Initialize Docker Swarm
docker swarm init

# Deploy stack
docker stack deploy -c docker-compose.yml escolasapp

# View services
docker service ls

# Scale app service
docker service scale escolasapp_app=3

# View logs
docker service logs escolasapp_app
```

---

## Troubleshooting

### Image Build Issues

#### Error: "npm ERR! code E404"

```bash
# Solution: Update npm cache, retry build
npm cache clean --force
docker build --no-cache -t escolasapp:latest .
```

#### Error: "ng: command not found"

```bash
# Solution: Verify Angular CLI installed in builder stage
docker run -it --rm node:12-alpine npm ls -g @angular/cli
```

#### Error: "FATAL: Out of memory"

```bash
# Solution: Increase Docker resources or build in stages
docker build --build-arg NODE_OPTIONS="--max-old-space-size=2048" .
```

### Container Runtime Issues

#### Error: "Cannot connect to Docker daemon"

```bash
# Solution: Ensure Docker service is running
sudo systemctl start docker
sudo usermod -aG docker $USER
newgrp docker
```

#### Error: "Port 3002 already in use"

```bash
# Solution: Change port or kill process
docker-compose down
# or
lsof -i :3002
kill -9 <PID>
```

#### Error: "Cannot connect to MongoDB"

```bash
# Solution: Verify MongoDB is running and healthy
docker-compose ps mongodb

# Check MongoDB logs
docker-compose logs mongodb

# Test connectivity from app container
docker-compose exec app ping mongodb

# Verify connection string
docker-compose exec app env | grep DB_URL
```

### Application Issues

#### Error: "Application exits immediately"

```bash
# Solution: Check logs for errors
docker-compose logs app

# Rebuild image
docker-compose build --no-cache

# Restart with verbose logging
docker-compose restart app
docker-compose logs -f app
```

#### Error: "Health check failing"

```bash
# Solution: Wait longer or adjust health check
# Edit docker-compose.yml:
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3002"]
  interval: 30s
  timeout: 10s
  retries: 5
  start_period: 60s  # Increased from 40s

# Restart
docker-compose up -d
```

---

## Docker Compose Reference

### File Structure

**[docker-compose.yml](docker-compose.yml)** — Base configuration
- Base services definition
- Default environment variables
- Volumes and networks

**[docker-compose.dev.yml](docker-compose.dev.yml)** — Development overrides
- Volume mounts for hot-reload
- Debug ports
- Development environment settings

**[docker-compose.prod.yml](docker-compose.prod.yml)** — Production overrides
- Hardened security
- No volumes (immutable)
- Production logging

### Common Commands

| Command | Purpose |
|---------|---------|
| `docker-compose up -d` | Start containers in background |
| `docker-compose down` | Stop and remove containers |
| `docker-compose ps` | List running containers |
| `docker-compose logs -f` | View live logs |
| `docker-compose exec app npm test` | Run command in container |
| `docker-compose build --no-cache` | Rebuild image |
| `docker-compose restart` | Restart all services |
| `docker-compose pull` | Pull latest images |

### Environment Variables

See `.env.example` for all available variables:

```bash
NODE_ENV          # development, staging, production
APP_PORT          # Application port (default: 3002)
DB_HOST           # MongoDB hostname
DB_PORT           # MongoDB port
DB_NAME           # Database name
DB_USER           # MongoDB username
DB_PASSWORD       # MongoDB password
DEBUG             # Debug logging (empty for production)
```

---

## Next Steps

- **Set up Vagrant**: See [INFRASTRUCTURE.md](INFRASTRUCTURE.md#vagrant-setup)
- **Configure Ansible**: See [ANSIBLE.md](ANSIBLE.md)
- **Deploy to Staging**: See [INFRASTRUCTURE.md](INFRASTRUCTURE.md#deployment-ansible)
- **Monitor Production**: See [INFRASTRUCTURE.md](INFRASTRUCTURE.md#troubleshooting)


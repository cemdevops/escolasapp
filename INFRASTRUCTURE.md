# Infrastructure Setup Guide

Complete infrastructure-as-code implementation for EscolasApp with Vagrant, Docker, and Ansible support for dev/staging/production environments.

---

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Architecture](#architecture)
4. [Local Development (Vagrant + Docker)](#local-development-vagrant--docker)
5. [Deployment (Ansible)](#deployment-ansible)
6. [CI/CD Pipeline](#cicd-pipeline)
7. [Troubleshooting](#troubleshooting)

---

## Overview

This infrastructure enables:

- **Local Development**: Vagrant VM (Ubuntu 20.04) with Docker/Docker Compose pre-provisioned via Ansible
- **Containerization**: Multi-stage Docker build for Angular + Node.js + MongoDB
- **Multi-Environment**: Separate configurations for development, staging, and production
- **Container Registry**: GitHub Container Registry (GHCR) for image storage
- **Infrastructure-as-Code**: Ansible playbooks define all provisioning and deployment logic

### Tech Stack

| Component | Version |
|-----------|---------|
| Vagrant | 2.x+ |
| VirtualBox | 6.x+ |
| Ubuntu | 20.04 LTS |
| Docker | Latest (installed by Ansible) |
| Docker Compose | 1.29+ (installed by Ansible) |
| Ansible | 2.9+ |
| Node.js | 7.10 (current, upgrade planned) |
| MongoDB | 3.4.9 (current, upgrade planned) |

---

## Quick Start

### For Local Development

```bash
# 1. Clone repository and navigate to it
cd escolasapp

# 2. Start Vagrant VM (first run takes 5-10 minutes)
vagrant up

# 3. SSH into the VM
vagrant ssh

# 4. Navigate to project and start containers (dev profile)
cd /home/vagrant/escolasapp
docker-compose --profile dev up -d

# 5. (Optional) Start admin tools
docker-compose --profile admin up -d

# 6. Verify app is running
curl http://localhost:3002

# 7. View logs
docker-compose logs -f app-dev

# 8. Access MongoDB (if using admin profile)
# MongoDB UI: http://localhost:8081
# MongoDB CLI: docker exec -it escolasapp_mongodb mongo
```

### For Staging/Production Deployment

```bash
# 1. Configure inventory
# Edit ansible/inventories/staging/hosts with target server IP/hostname

# 2. Set environment variables
# Create/update ansible/inventories/staging/group_vars/all.yml with secrets

# 3. Deploy application
ansible-playbook -i ansible/inventories/staging/hosts ansible/playbooks/deploy.yml
```

---

## Architecture

### System Design

```
┌─────────────────────────────────────────┐
│  Developer Machine (macOS/Windows/Linux)│
├─────────────────────────────────────────┤
│  VirtualBox                             │
│  ┌──────────────────────────────────────┤
│  │  Vagrant VM (Ubuntu 20.04)           │
│  │  ┌────────────────────────────────────┤
│  │  │  Docker                            │
│  │  │  ┌──────────────┐  ┌──────────────┐│
│  │  │  │ escolasapp   │  │ MongoDB      ││
│  │  │  │ (Node/Ang.)  │  │ (port 27017) ││
│  │  │  └──────────────┘  └──────────────┘│
│  │  │  (port 3002)                       │
│  │  └────────────────────────────────────┘
│  └──────────────────────────────────────┘
│  Port forwarding: 3002 → 3002            │
└─────────────────────────────────────────┘
         ↓ (vagrant ssh)
   SSH access on port 2222
```

### Container Architecture

**Application Services** (with profile selection):
- `app-dev` — Built from source, hot-reload volumes, debug port (profile: `dev`)
- `app-staging` — Pulled from GHCR, hardened configuration (profile: `staging`)
- `app-prod` — Pulled from GHCR, maximum hardening (profile: `production`)

**Database Service** (shared foundation):
- MongoDB 3.6 official image
- Used by all profiles
- Persistent volumes for data and configuration
- Health checks for service orchestration

**Admin Services** (optional):
- `mongo-express` — MongoDB web UI (profile: `admin`)

### Environment Files & Compose Configuration

```
escolasapp/
├── .env.example                          # Template for all environment variables
├── .env.development.local                # (gitignored) Dev config (dev profile)
├── .env.staging.local                    # (gitignored) Staging config (staging profile)
├── .env.production.local                 # (gitignored) Production config (production profile)
├── docker-compose.yml                    # Single file with all profiles
│   ├── [mongodb]                         # Shared foundation service
│   ├── [app-dev]                         # Development profile
│   ├── [app-staging]                     # Staging profile
│   ├── [app-prod]                        # Production profile
│   └── [mongo-express]                   # Admin tools (admin profile)
└── Dockerfile                            # Multi-stage build
```

**Profile Usage:**
- `docker-compose --profile dev up -d` — Development with source volumes & debug
- `docker-compose --profile staging up -d` — Staging environment
- `docker-compose --profile production up -d` — Production environment
- `docker-compose --profile dev --profile admin up -d` — Dev + MongoDB UI

---

## Local Development (Vagrant + Docker)

### Prerequisites

- VirtualBox 6.0 or later
- Vagrant 2.2 or later
- Git

### Setup Steps

#### 1. Start Vagrant VM

```bash
cd escolasapp
vagrant up
```

**What happens:**
- VirtualBox creates a new Ubuntu 20.04 VM
- Vagrant provisioner runs Ansible playbook `ansible/playbooks/vagrant_provision.yml`
- Ansible installs Docker, Docker Compose, configures docker group
- Project directory synced to `/home/vagrant/escolasapp`

#### 2. Connect to VM

```bash
vagrant ssh
```

You're now inside the VM with Docker/Docker Compose ready.

#### 3. Configure Environment Variables

```bash
cd /home/vagrant/escolasapp

# Copy env example to development local
cp .env.example .env.development.local

# Edit with your settings (usually defaults are fine)
nano .env.development.local
```

#### 4. Start Application

```bash
# Start development environment with dev profile
docker-compose --profile dev up -d

# Optionally add admin tools (mongo-express)
docker-compose --profile dev --profile admin up -d
```

**Services started:**
- `app-dev` — Node.js/Angular on port 3002 with source volumes mounted
- `mongodb` — MongoDB on port 27017
- `mongo-express` (if admin profile) — MongoDB UI on port 8081

#### 5. Verify Application

```bash
# Check container status
docker-compose --profile dev ps

# View app logs (development)
docker-compose logs -f app-dev

# Test endpoint
curl http://localhost:3002

# Access MongoDB shell
docker exec -it escolasapp_mongodb_1 mongo

# View environment variables in container
docker exec escolasapp_app env
```

### Development Workflow

#### Hot Reloading Code

**Frontend (Angular):**

If hot-reload is needed, volumes are mounted:

```bash
# Edit src/ directory on host machine
# Angular CLI watches and rebuilds in container (if ng serve configured)
# Or rebuild manually:
docker-compose exec app npm run build
```

**Backend (Express):**

Edit `app.js`, `routes/`, `models/` and restart:

```bash
docker-compose restart app
```

#### Running Commands in Container

```bash
# Install new npm package
docker-compose exec app npm install package-name

# Run tests
docker-compose exec app npm test

# Run linting
docker-compose exec app npm run lint

# Run e2e tests
docker-compose exec app npm run e2e
```

#### Stopping and Cleaning Up

```bash
# Stop containers (keep volumes)
docker-compose down

# Stop containers and remove volumes (clean slate)
docker-compose down -v

# Exit VM
exit

# Suspend VM (saves state, faster resume)
vagrant suspend

# Resume VM
vagrant resume

# Destroy VM (free up resources)
vagrant destroy
```

### Debugging

#### View Application Logs

```bash
# Stream logs from app container
docker-compose logs -f app

# View specific number of lines
docker-compose logs --tail 100 app

# View all services
docker-compose logs -f
```

#### Connect to MongoDB

```bash
docker exec -it escolasapp_mongodb_1 mongo

# In mongo shell:
use escolasapp_db
db.schools.find().limit(1)
exit
```

#### SSH into Running Container

```bash
docker exec -it escolasapp_app /bin/sh
```

#### Rebuild Image

```bash
# Clear cache, rebuild from scratch
docker-compose build --no-cache

# Restart services
docker-compose up -d
```

---

## Deployment (Ansible)

### Directory Structure

```
ansible/
├── ansible.cfg                           # Ansible configuration
├── inventories/
│   ├── development/
│   │   ├── hosts                         # Localhost for Vagrant
│   │   └── group_vars/
│   │       └── all.yml                   # Dev environment vars
│   ├── staging/
│   │   ├── hosts                         # Staging server IPs
│   │   └── group_vars/
│   │       └── all.yml                   # Staging environment vars
│   └── production/
│       ├── hosts                         # Production server IPs
│       └── group_vars/
│           └── all.yml                   # Production environment vars
├── roles/
│   ├── docker_setup/
│   │   ├── tasks/main.yml                # Install Docker, Docker Compose
│   │   └── handlers/main.yml             # Restart Docker daemon
│   ├── app_setup/
│   │   ├── tasks/main.yml                # Clone repo, build image, deploy containers
│   │   ├── templates/
│   │   │   ├── .env.j2                   # Template for .env file
│   │   │   └── docker-compose.override.j2 # Template for docker-compose override
│   │   └── handlers/main.yml             # Restart app container
│   └── monitoring/
│       └── tasks/main.yml                # (Optional) Configure logging/metrics
└── playbooks/
    ├── vagrant_provision.yml             # Called by Vagrant provisioner
    └── deploy.yml                        # General deployment playbook
```

### Ansible Roles Overview

#### `docker_setup` Role

**Tasks:**
- Install Docker CE
- Install Docker Compose
- Configure Docker daemon (log drivers, storage)
- Add user to docker group
- Enable Docker service on startup
- Verify Docker installation

**Usage:** Called during Vagrant provisioning and first-time server setup

#### `app_setup` Role

**Tasks:**
- Clone/pull latest repo from GitHub
- Create `.env` file from template with inventory variables
- Build Docker image (if not using GHCR)
- Pull image from GHCR (if using registry)
- Create docker-compose.override.yml with environment-specific settings
- Start/restart containers via docker-compose
- Verify application health

**Variables required (from inventory group_vars):**
- `docker_registry_url` — GHCR URL (e.g., `ghcr.io/cemdevops/escolasapp`)
- `app_environment` — dev/staging/prod
- `db_url` — MongoDB connection string
- `db_user`, `db_password` — MongoDB credentials
- `api_keys` — Any external API tokens
- `port` — Application port (usually 3002)

**Usage:** Called after docker_setup, on every deployment

#### `monitoring` Role (Optional)

**Tasks:**
- Configure container logs (optional log driver)
- Setup health checks
- (Future) Export metrics, alerts configurations

### Inventories

#### Development Inventory

**`ansible/inventories/development/hosts`**
```ini
[local]
localhost ansible_connection=local

[development]
localhost
```

**`ansible/inventories/development/group_vars/all.yml`**
```yaml
app_environment: development
docker_registry_url: ghcr.io/cemdevops/escolasapp
db_host: mongodb
db_port: 27017
db_name: escolasapp_dev
db_user: dev_user
db_password: dev_password
app_port: 3002
mongo_image: mongo:3.6
nodejs_version: 12
```

#### Staging Inventory

**`ansible/inventories/staging/hosts`**
```ini
[staging]
staging.example.com ansible_user=admin ansible_ssh_private_key_file=~/.ssh/staging_key

[staging:vars]
ansible_port=22
```

**`ansible/inventories/staging/group_vars/all.yml`** (encrypted with ansible-vault)
```yaml
app_environment: staging
docker_registry_url: ghcr.io/cemdevops/escolasapp
docker_registry_token: {{ vault_docker_registry_token }}
db_host: mongo-staging.internal
db_port: 27017
db_name: escolasapp_staging
db_user: {{ vault_db_user }}
db_password: {{ vault_db_password }}
app_port: 3002
```

#### Production Inventory

**`ansible/inventories/production/hosts`**
```ini
[production]
prod1.example.com ansible_user=admin ansible_ssh_private_key_file=~/.ssh/prod_key
prod2.example.com ansible_user=admin ansible_ssh_private_key_file=~/.ssh/prod_key

[production:vars]
ansible_port=22
```

**`ansible/inventories/production/group_vars/all.yml`** (encrypted with ansible-vault)
```yaml
app_environment: production
docker_registry_url: ghcr.io/cemdevops/escolasapp
docker_registry_token: {{ vault_docker_registry_token }}
db_host: mongo-prod.internal
db_port: 27017
db_name: escolasapp_prod
db_user: {{ vault_db_user }}
db_password: {{ vault_db_password }}
app_port: 3002
```

### Deploying to Staging

#### 1. Encrypt Sensitive Variables (One-time Setup)

```bash
# Create vault password file (gitignored)
echo "your-secure-vault-password" > ~/.ansible-vault-pass

# Encrypt group vars with sensitive data
ansible-vault encrypt ansible/inventories/staging/group_vars/all.yml --vault-password-file=~/.ansible-vault-pass

# View encrypted file
ansible-vault view ansible/inventories/staging/group_vars/all.yml --vault-password-file=~/.ansible-vault-pass
```

#### 2. Deploy Application

```bash
# Deploy with vault password
ansible-playbook \
  -i ansible/inventories/staging/hosts \
  ansible/playbooks/deploy.yml \
  --vault-password-file=~/.ansible-vault-pass

# Or using prompt for password
ansible-playbook \
  -i ansible/inventories/staging/hosts \
  ansible/playbooks/deploy.yml \
  --ask-vault-pass
```

#### 3. Verify Deployment

```bash
# SSH into staging server
ssh -i ~/.ssh/staging_key admin@staging.example.com

# Check containers running
docker ps

# View logs
docker-compose logs -f app

# Test endpoint
curl http://localhost:3002
```

### Deploying to Production

Same as staging, but use production inventory:

```bash
ansible-playbook \
  -i ansible/inventories/production/hosts \
  ansible/playbooks/deploy.yml \
  --vault-password-file=~/.ansible-vault-pass
```

---

## CI/CD Pipeline

### GitHub Actions Workflow

**`.github/workflows/build-and-push.yml`**

Triggers on:
- Push to `master` branch
- Semver tags (e.g., `v1.2.3`)

**Steps:**
1. Checkout code
2. Set up Docker buildx
3. Login to GHCR with `GHCR_TOKEN`
4. Build image with tags: `latest`, git SHA, version tag
5. Push image to GHCR

**Configuration:**

```bash
# 1. Create GitHub Personal Access Token (PAT) with `write:packages` scope
#    https://github.com/settings/tokens

# 2. Add as repository secret `GHCR_TOKEN`
#    https://github.com/cemdevops/escolasapp/settings/secrets

# 3. Push to master → workflow runs automatically
git add .
git commit -m "Add Dockerfile and CI/CD"
git push origin master

# 4. Verify workflow success
# https://github.com/cemdevops/escolasapp/actions
```

### Pulling Image from GHCR in Ansible

The `app_setup` role automatically pulls the latest image:

```bash
docker login ghcr.io -u {{ github_username }} -p {{ docker_registry_token }}
docker pull ghcr.io/cemdevops/escolasapp:latest
docker-compose up -d
```

---

## Troubleshooting

### Vagrant Issues

#### Error: "No provider 'virtualbox' found"

```bash
# Solution: Install VirtualBox
# https://www.virtualbox.org/wiki/Downloads
```

#### Error: "Vagrant up hangs during provisioning"

```bash
# Solution: Increase VM memory in Vagrantfile
# or Check Ansible playbook for errors:
vagrant provision --debug
```

#### Error: "Port 3002 already in use"

```bash
# Solution: Change port forwarding in Vagrantfile
# or Kill process using port 3002:
lsof -i :3002
kill -9 <PID>
```

### Docker Issues

#### Error: "docker: command not found"

```bash
# Ensure you're inside Vagrant VM:
vagrant ssh

# Verify Docker installed:
docker --version

# If missing, re-provision:
vagrant provision
```

#### Error: "Cannot connect to MongoDB"

```bash
# Check if MongoDB container is running:
docker-compose ps

# Check MongoDB logs:
docker-compose logs mongodb

# Ensure network connection:
docker-compose exec app ping mongodb

# Verify connection string in .env:
docker-compose exec app env | grep DB_URL
```

#### Error: "Image build fails"

```bash
# View build output with verbose logging:
docker-compose build --no-cache 2>&1 | tail -50

# Verify npm dependencies:
docker-compose exec app npm ci --verbose

# Check Dockerfile syntax:
docker build --dry-run .
```

### Ansible Issues

#### Error: "Permission denied (publickey)"

```bash
# Solution: Ensure SSH key permissions
chmod 600 ~/.ssh/staging_key

# Test SSH connection
ssh -i ~/.ssh/staging_key admin@staging.example.com
```

#### Error: "Timeout waiting for ping module"

```bash
# Solution: Increase timeout in ansible.cfg or command line
ansible-playbook -i inventory/staging/hosts playbook.yml --timeout=60
```

#### Error: "FAILED - unvault decryption failed"

```bash
# Solution: Verify vault password is correct
ansible-vault view ansible/inventories/staging/group_vars/all.yml --ask-vault-pass
```

### Application Issues

#### Error: "Cannot reach http://localhost:3002"

```bash
# 1. Check if container is running:
docker-compose ps

# 2. Check if port is forwarded correctly (if using Vagrant):
vagrant port

# 3. View app logs for startup errors:
docker-compose logs app

# 4. Rebuild and restart:
docker-compose build --no-cache
docker-compose down -v
docker-compose up -d --build
```

#### Error: "Application crashes on startup"

```bash
# View error logs
docker-compose logs app

# Check Node.js version compatibility
docker-compose exec app node --version

# Check environment variables
docker-compose exec app env | grep -E "DB|NODE_ENV"

# Test npm dependencies
docker-compose exec app npm ci
```

---

## Next Steps (Future Phases)

1. **Node.js & MongoDB Upgrade**
   - Upgrade Node.js from 7.10 to 14 LTS
   - Upgrade MongoDB from 3.4.9 to 5.x
   - Test application compatibility, migrate data if needed

2. **Advanced Monitoring**
   - Add Prometheus + Grafana for metrics
   - Configure ELK stack for centralized logging
   - Setup alerting

3. **Kubernetes Deployment** (if scaling needed)
   - Migrate from Docker Compose to Kubernetes manifests
   - Setup ingress, persistent volumes, resource limits

4. **SSL/TLS Termination**
   - Add Nginx reverse proxy with Let's Encrypt SSL
   - Configure certificate auto-renewal

5. **Database Backups & Replication**
   - Setup MongoDB replica sets for HA
   - Automated backup and restore procedures

---

## References

- [Vagrant Documentation](https://www.vagrantup.com/docs)
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Ansible Documentation](https://docs.ansible.com/)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)


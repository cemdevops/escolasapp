# Ansible Guide for EscolasApp

Complete guide to using Ansible for infrastructure provisioning and application deployment.

---

## Table of Contents

1. [Overview](#overview)
2. [Directory Structure](#directory-structure)
3. [Quick Start](#quick-start)
4. [Inventory Configuration](#inventory-configuration)
5. [Running Playbooks](#running-playbooks)
6. [Managing Secrets](#managing-secrets)
7. [Roles Reference](#roles-reference)
8. [Troubleshooting](#troubleshooting)

---

## Overview

Ansible enables **Infrastructure-as-Code** for EscolasApp with three main purposes:

1. **Vagrant Provisioning** — Local development VM setup
2. **Staging Deployment** — Test environment deployment
3. **Production Deployment** — Production environment deployment

### Architecture

```
ansible/
├── ansible.cfg              # Ansible configuration
├── inventories/
│   ├── development/         # Vagrant local VM
│   ├── staging/             # Staging servers
│   └── production/          # Production servers
├── roles/
│   ├── docker_setup/        # Install Docker & Docker Compose
│   └── app_setup/           # Deploy application
└── playbooks/
    ├── vagrant_provision.yml    # Local provisioning
    └── deploy.yml               # Remote deployment
```

### Key Benefits

✅ **Idempotent** — Safe to run multiple times  
✅ **Declarative** — Define desired state, not steps  
✅ **Reusable** — Same playbooks for all environments  
✅ **Auditable** — Version-controlled infrastructure code  
✅ **Scalable** — Deploy to 1 or 100 servers with one command  

---

## Directory Structure

### Configuration Files

**`ansible.cfg`**
```ini
[defaults]
inventory = ./inventories/
host_key_checking = False
timeout = 30
```

### Inventories

Each environment has:

**`inventories/<env>/hosts`**
```ini
[<env>]
hostname_or_ip
```

**`inventories/<env>/group_vars/all.yml`**
```yaml
app_environment: <env>
db_host: <hostname>
# ... all environment variables
```

### Roles

**`roles/docker_setup/`**
```
tasks/main.yml      # Install Docker, Docker Compose
handlers/main.yml   # Restart Docker service
```

**`roles/app_setup/`**
```
tasks/main.yml      # Clone repo, build image, deploy
handlers/main.yml   # Restart app containers
templates/
  .env.j2           # Environment file template
  docker-compose.override.j2  # Docker Compose overrides
```

### Playbooks

**`playbooks/vagrant_provision.yml`**
- Entry point for Vagrant provisioner
- Calls `docker_setup` and `app_setup` roles

**`playbooks/deploy.yml`**
- General-purpose deployment playbook
- Works for staging and production
- Requires inventory specification

---

## Quick Start

### Prerequisites

- Ansible 2.9+ ([install](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html))
- SSH access to target servers (for staging/prod)
- SSH keys configured for passwordless auth

### Installation

```bash
# Install on macOS
brew install ansible

# Install on Linux
sudo apt-get install ansible

# Install on Windows (via WSL or Docker)
wsl -- sudo apt-get install ansible
# or
docker run --rm -it -v $(pwd):/workspace ansible/ansible:latest

# Verify installation
ansible --version
```

### First-Time Setup: Vagrant

```bash
# No manual Ansible invocation needed!
# Vagrant provisioner runs automatically:
vagrant up

# Behind the scenes:
# Vagrant → vagrant/bootstrap.sh → ansible playbook (vagrant_provision.yml)
```

### First-Time Setup: Staging

```bash
# 1. Update inventory with staging server IP
vim ansible/inventories/staging/hosts
# Example: staging.example.com ansible_user=admin

# 2. Create vault password (one-time)
echo "your-secure-password" > ~/.ansible-vault-pass
chmod 600 ~/.ansible-vault-pass

# 3. Edit and encrypt staging secrets
ansible-vault edit --vault-password-file=~/.ansible-vault-pass \
  ansible/inventories/staging/group_vars/all.yml

# 4. Deploy
ansible-playbook \
  -i ansible/inventories/staging/hosts \
  ansible/playbooks/deploy.yml \
  --vault-password-file=~/.ansible-vault-pass
```

---

## Inventory Configuration

### Development (Vagrant)

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
db_host: mongodb
db_user: admin
db_password: admin123
```

### Staging

**`ansible/inventories/staging/hosts`**
```ini
[staging]
staging.example.com ansible_user=admin ansible_ssh_private_key_file=~/.ssh/staging_key

[staging:vars]
ansible_port=22
```

**`ansible/inventories/staging/group_vars/all.yml`** (encrypted)
```yaml
app_environment: staging
db_host: mongo-staging.internal
db_user: "{{ vault_db_user_staging }}"
db_password: "{{ vault_db_password_staging }}"
```

### Production

**`ansible/inventories/production/hosts`**
```ini
[production]
prod1.example.com ansible_user=admin ansible_ssh_private_key_file=~/.ssh/prod_key

[production:vars]
ansible_port=22
```

**`ansible/inventories/production/group_vars/all.yml`** (encrypted)
```yaml
app_environment: production
db_host: mongo-prod.internal
db_user: "{{ vault_db_user_prod }}"
db_password: "{{ vault_db_password_prod }}"
```

### Variable Precedence

Variables are resolved in this order (highest to lowest):
1. Command-line extra variables (`-e key=value`)
2. Playbook/role variables
3. Group variables (`group_vars/`)
4. Host variables
5. Defaults

---

## Running Playbooks

### Vagrant Provisioning (Automatic)

```bash
# Start Vagrant VM - provisioning runs automatically
vagrant up

# To re-provision existing VM
vagrant provision

# With debug output
vagrant provision --debug
```

### Manual Vagrant Provisioning

```bash
# SSH into VM first
vagrant ssh

# Navigate to project
cd /home/vagrant/escolasapp

# Run provisioning playbook manually
ansible-playbook \
  -i ansible/inventories/development/hosts \
  ansible/playbooks/vagrant_provision.yml
```

### Staging Deployment

```bash
# Simple deployment
ansible-playbook \
  -i ansible/inventories/staging/hosts \
  ansible/playbooks/deploy.yml \
  --vault-password-file=~/.ansible-vault-pass

# With extra verbosity
ansible-playbook \
  -i ansible/inventories/staging/hosts \
  ansible/playbooks/deploy.yml \
  --vault-password-file=~/.ansible-vault-pass \
  -vvv

# Run only docker_setup role
ansible-playbook \
  -i ansible/inventories/staging/hosts \
  ansible/playbooks/deploy.yml \
  --vault-password-file=~/.ansible-vault-pass \
  -t docker_setup

# Run only app_setup role
ansible-playbook \
  -i ansible/inventories/staging/hosts \
  ansible/playbooks/deploy.yml \
  --vault-password-file=~/.ansible-vault-pass \
  -t app_setup

# Dry-run (no changes)
ansible-playbook \
  -i ansible/inventories/staging/hosts \
  ansible/playbooks/deploy.yml \
  --vault-password-file=~/.ansible-vault-pass \
  --check
```

### Production Deployment

```bash
# Deploy to production (same as staging, different inventory)
ansible-playbook \
  -i ansible/inventories/production/hosts \
  ansible/playbooks/deploy.yml \
  --vault-password-file=~/.ansible-vault-pass

# Deploy to specific host only (useful for multiple servers)
ansible-playbook \
  -i ansible/inventories/production/hosts \
  ansible/playbooks/deploy.yml \
  --vault-password-file=~/.ansible-vault-pass \
  -l prod1.example.com
```

### Ad-Hoc Commands

```bash
# Ping all hosts in staging
ansible -i ansible/inventories/staging/hosts staging -m ping

# Run command on all staging servers
ansible -i ansible/inventories/staging/hosts staging -m command -a "docker ps"

# Check disk space
ansible -i ansible/inventories/staging/hosts staging -m shell -a "df -h"

# Get system facts
ansible -i ansible/inventories/staging/hosts staging -m setup

# Restart Docker service
ansible -i ansible/inventories/staging/hosts staging -m systemd -a "name=docker state=restarted"
```

---

## Managing Secrets

### Why Ansible Vault?

Store sensitive data (passwords, API keys) in version control while keeping them encrypted:

```
✓ Encrypted passwords in git  
✓ Easy rotation (re-encrypt with new password)  
✓ Audit trail (git history)  
✗ No unencrypted secrets in repo  
```

### Setup Vault

#### Create Vault Password File (One-Time)

```bash
# Generate secure password
openssl rand 32 | base64 > ~/.ansible-vault-pass

# Set restrictive permissions
chmod 600 ~/.ansible-vault-pass

# Add to .bash_profile for convenience
export ANSIBLE_VAULT_PASSWORD_FILE=~/.ansible-vault-pass
```

#### Encrypt Inventory Variables

```bash
# Encrypt staging group vars
ansible-vault encrypt \
  ansible/inventories/staging/group_vars/all.yml \
  --vault-password-file=~/.ansible-vault-pass

# Encrypt production group vars
ansible-vault encrypt \
  ansible/inventories/production/group_vars/all.yml \
  --vault-password-file=~/.ansible-vault-pass

# View encrypted file (without decrypting it)
ansible-vault view \
  ansible/inventories/staging/group_vars/all.yml \
  --vault-password-file=~/.ansible-vault-pass

# Edit encrypted file
ansible-vault edit \
  ansible/inventories/staging/group_vars/all.yml \
  --vault-password-file=~/.ansible-vault-pass
```

### Using Vault in Playbooks

**Example encrypted group_vars:**
```yaml
vault_db_user_staging: my_staging_user
vault_db_password_staging: mysecurepassword123
vault_docker_registry_token: ghp_xxxxxxxxxxxxxxxxxxxx
```

**Reference in playbook:**
```yaml
db_user: "{{ vault_db_user_staging }}"
db_password: "{{ vault_db_password_staging }}"
```

**Run playbook with vault:**
```bash
ansible-playbook \
  -i ansible/inventories/staging/hosts \
  ansible/playbooks/deploy.yml \
  --vault-password-file=~/.ansible-vault-pass
```

### GitHub Actions Integration

For CI/CD, store vault password as GitHub Secret:

```bash
# 1. Create repo  secret: ANSIBLE_VAULT_PASS
# 2. In workflow, write to file:
echo "${{ secrets.ANSIBLE_VAULT_PASS }}" > ~/.ansible-vault-pass

# 3. Run playbook
ansible-playbook ... --vault-password-file=~/.ansible-vault-pass
```

---

## Roles Reference

### docker_setup Role

**Purpose:** Install Docker and Docker Compose

**Tasks:**
- Install Docker prerequisites (`apt-transport-https`, `curl`, etc.)
- Add Docker GPG key and repository
- Install Docker CE, CLI, and Compose
- Create docker group and add users
- Enable Docker service on startup
- Configure logging and security options
- Verify installation

**Usage:**
```yaml
roles:
  - role: docker_setup
```

**Variables:**
```yaml
# No required variables - detects OS automatically
```

### app_setup Role

**Purpose:** Clone repository, build/pull image, deploy containers

**Tasks:**
- Install git
- Create application directory
- Clone/update repository
- Render `.env` file from template
- Build Docker image (local) or pull from registry (remote)
- Login to Docker registry (if credentials provided)
- Create `docker-compose.override.yml`
- Verify docker-compose configuration
- Start containers
- Wait for application health check
- Display status

**Usage:**
```yaml
roles:
  - role: app_setup
```

**Required Variables:**
```yaml
app_environment: staging           # development, staging, production
app_repo_url: https://github.com/... # Git repository URL
app_repo_branch: master            # Git branch to checkout
app_repo_dest: /opt/escolasapp     # Destination path on target
app_port: 3002                     # Application port
db_host: mongo-staging             # MongoDB hostname
db_port: 27017                     # MongoDB port
db_name: escolasapp_staging        # Database name
db_user: admin                     # MongoDB user
db_password: secretpassword        # MongoDB password
google_analytics_code: UA-...      # Analytics code
log_level: info                    # Logging level
```

**Optional Variables:**
```yaml
docker_registry_url: ghcr.io/cemdevops/escolasapp  # Image registry
docker_registry_username: username                  # Registry username
docker_registry_token: token                        # Registry token
```

---

## Troubleshooting

### Inventory Issues

#### Error: "Unable to parse <inventory>"

```bash
# Solution: Check YAML syntax
ansible-inventory -i ansible/inventories/staging/hosts --list

# Or validate directly
python -m yaml ansible/inventories/staging/hosts
```

#### Error: "No inventory was parsed"

```bash
# Solution: Verify hosts file exists and is readable
ls -la ansible/inventories/*/hosts
cat ansible/inventories/staging/hosts
```

### Connection Issues

#### Error: "SSH connection refused"

```bash
# Solution: Check SSH key and connectivity
ssh -vvv -i ~/.ssh/staging_key ubuntu@staging.example.com

# If key permission issue:
chmod 600 ~/.ssh/staging_key
```

#### Error: "Permission denied (passwordless access)"

```bash
# Solution: Use password authentication or fix SSH key
ansible-playbook ... -k  # Prompt for password
# or
ssh-copy-id -i ~/.ssh/staging_key ubuntu@staging.example.com
```

### Vault Issues

#### Error: "Decryption failed"

```bash
# Solution: Wrong vault password
# Check if vault password file is correct:
cat ~/.ansible-vault-pass

# Re-encrypt with correct password:
ansible-vault rekey \
  ansible/inventories/staging/group_vars/all.yml \
  --vault-password-file=~/.ansible-vault-pass
```

#### Error: "Failed to load vault identity"

```bash
# Solution: Vault password file not found or not readable
ls -la ~/.ansible-vault-pass
chmod 600 ~/.ansible-vault-pass
```

### Task Failures

#### Error: "Module <name> not found"

```bash
# Solution: Install required modules
pip install docker docker-compose

# Or use Docker instead:
docker run --rm -it -v $(pwd):/workspace ansible/ansible:latest \
  ansible-playbook -i inventories/staging/hosts playbooks/deploy.yml
```

#### Error: "Handler was not run"

```bash
# Solution: Handler names must match notify directive exactly
# Check tasks/main.yml and handlers/main.yml for typos
# Re-run with handler debug:
ansible-playbook ... --start-at-task="Task Name"
```

### Debugging

#### Increase verbosity

```bash
ansible-playbook ... -v    # 1 level
ansible-playbook ... -vv   # 2 levels
ansible-playbook ... -vvv  # 3 levels (very verbose)
```

#### Run in check mode (dry-run)

```bash
ansible-playbook ... --check
```

#### Run specific tag only

```bash
ansible-playbook ... -t docker_setup  # Only docker setup
ansible-playbook ... -t docker,app    # Multiple tags
```

#### Start from specific task

```bash
ansible-playbook ... --start-at-task="Task Name"
```

#### Debug variables

```yaml
- name: Debug variables
  debug:
    msg: |
      Environment: {{ app_environment }}
      Database: {{ db_host }}:{{ db_port }}/{{ db_name }}
      Port: {{ app_port }}
```

---

## Next Steps

- **Set up Vagrant**: `vagrant up`
- **Deploy to Staging**: `ansible-playbook -i ansible/inventories/staging/hosts ansible/playbooks/deploy.yml --vault-password-file=~/.ansible-vault-pass`
- **Configure Secrets**: `ansible-vault edit ansible/inventories/staging/group_vars/all.yml --vault-password-file=~/.ansible-vault-pass`
- **Monitor Deployment**: `docker-compose logs -f app`

---

## References

- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Vault Guide](https://docs.ansible.com/ansible/latest/user_guide/vault.html)
- [Docker Ansible Module](https://docs.ansible.com/ansible/latest/collections/community/docker/docker_container_module.html)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)


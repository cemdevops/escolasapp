#!/bin/bash
#
# EscolasApp Deployment Script - Vagrant VM
# Purpose: Deploy, update, and manage applications on Vagrant VM
# Usage:
#   ./scripts/deploy-staging.sh    - Deploy to staging environment
#   ./scripts/deploy-production.sh - Deploy to production environment
#   ./scripts/deploy-all.sh        - Deploy all environments
# Requirements:
#   - Vagrant VM running (vagrant up)
#   - SSH key configured for vagrant access
#   - GitHub Container Registry credentials configured
#

set -euo pipefail

# Configuration
VAGRANT_IP="localhost"
VAGRANT_SSH_PORT="2222"
VAGRANT_USER="vagrant"
VAGRANT_KEY_PATH=".vagrant/machines/default/virtualbox/private_key"
WORK_DIR="/home/vagrant/escolasapp"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
    exit 1
}

# SSH helper function
ssh_vagrant() {
    ssh -p $VAGRANT_SSH_PORT \
        -l $VAGRANT_USER \
        -i "$VAGRANT_KEY_PATH" \
        -o StrictHostKeyChecking=no \
        "$VAGRANT_IP" "$@"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if [ ! -f "$VAGRANT_KEY_PATH" ]; then
        log_error "Vagrant key not found at $VAGRANT_KEY_PATH. Run 'vagrant up' first."
    fi
    
    # Test SSH connection
    if ! ssh_vagrant "echo 'SSH connection OK'" > /dev/null 2>&1; then
        log_error "Cannot connect to Vagrant VM via SSH"
    fi
    
    log_success "Prerequisites check passed"
}

# Pull latest code from git
pull_latest_code() {
    log_info "Pulling latest code from git..."
    ssh_vagrant "cd $WORK_DIR && git pull origin master"
    log_success "Latest code pulled"
}

# Build Docker image
build_image() {
    local profile=$1
    log_info "Building Docker image for profile: $profile"
    
    ssh_vagrant "cd $WORK_DIR && \
        docker system prune -f && \
        docker build -t escolasapp:$profile . 2>&1 | tail -20"
    
    log_success "Docker image built: escolasapp:$profile"
}

# Deploy staging environment
deploy_staging() {
    log_info "========== DEPLOYING STAGING =========="
    
    check_prerequisites
    pull_latest_code
    
    ssh_vagrant "cd $WORK_DIR && \
        log_info 'Stopping staging containers...' && \
        COMPOSE_PROFILES=staging docker-compose down 2>&1 || true && \
        log_info 'Starting staging environment...' && \
        COMPOSE_PROFILES=staging docker-compose up -d && \
        sleep 10 && \
        log_info 'Checking health...' && \
        docker-compose ps && \
        curl -s http://localhost:3002/school | head -3 && \
        echo '' && \
        log_success 'Staging deployment complete'"
    
    log_success "Staging deployment successful"
}

# Deploy production environment
deploy_production() {
    log_info "========== DEPLOYING PRODUCTION =========="
    
    check_prerequisites
    
    # Ask for confirmation
    read -p "⚠  This will deploy to PRODUCTION. Continue? (yes/no) " -n 3 -r
    echo
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_error "Production deployment cancelled"
    fi
    
    pull_latest_code
    
    ssh_vagrant "cd $WORK_DIR && \
        log_info 'Stopping production containers...' && \
        COMPOSE_PROFILES=production docker-compose down 2>&1 || true && \
        log_info 'Starting production environment...' && \
        COMPOSE_PROFILES=production docker-compose up -d && \
        sleep 10 && \
        log_info 'Checking health...' && \
        docker-compose ps && \
        curl -s http://localhost:3002/school | head -3 && \
        echo '' && \
        log_success 'Production deployment complete'"
    
    log_success "Production deployment successful"
}

# Deploy all environments
deploy_all() {
    log_info "========== DEPLOYING ALL ENVIRONMENTS =========="
    
    check_prerequisites
    
    deploy_staging
    echo ""
    deploy_production
}

# Rollback to previous version
rollback() {
    log_info "Rolling back to previous version..."
    
    ssh_vagrant "cd $WORK_DIR && git revert --no-edit HEAD"
    pull_latest_code
    
    log_success "Rollback complete"
}

# Show logs
show_logs() {
    local profile=${1:-dev}
    log_info "Showing logs for $profile profile..."
    
    ssh_vagrant "cd $WORK_DIR && docker-compose logs --tail=50 -f" || true
}

# Main script logic
main() {
    case "${1:-help}" in
        staging)
            deploy_staging
            ;;
        production)
            deploy_production
            ;;
        all)
            deploy_all
            ;;
        rollback)
            rollback
            ;;
        logs)
            show_logs "${2:-dev}"
            ;;
        check)
            check_prerequisites
            ;;
        *)
            cat << 'EOF'
EscolasApp Deployment Script

Usage: ./scripts/deploy.sh <command>

Commands:
  staging         Deploy to staging environment
  production      Deploy to production environment
  all             Deploy to all environments (with confirmation)
  rollback        Rollback to previous git commit
  logs [profile]  Show container logs
  check           Check deployment prerequisites
  help            Show this message

Examples:
  ./scripts/deploy.sh staging
  ./scripts/deploy.sh production
  ./scripts/deploy.sh logs dev
EOF
            ;;
    esac
}

main "$@"

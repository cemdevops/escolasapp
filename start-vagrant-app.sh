#!/bin/bash
set -e

cd /home/vagrant/escolasapp

echo "=== Stopping old containers ==="
COMPOSE_PROFILES=dev docker-compose down -v 2>&1 || true

echo "=== Pulling latest images ==="
COMPOSE_PROFILES=dev docker-compose pull 2>&1 | tail -10

echo "=== Starting Docker Compose with dev profile ==="
COMPOSE_PROFILES=dev docker-compose up -d 2>&1

echo "=== Waiting for services to be ready (10 seconds) ==="
sleep 10

echo "=== Container Status ==="
docker-compose ps

echo "=== Testing MongoDB connection ==="
sleep 5
docker-compose exec -T mongodb mongo --eval "db.admin.ping()" 2>&1 || echo "MongoDB warming up..."

echo "=== Testing API endpoints ==="
echo ""
echo "Testing /school endpoint:"
curl -s http://localhost:3002/school 2>&1 | head -100

echo ""
echo "Testing /weightingarea endpoint:"
curl -s http://localhost:3002/weightingarea 2>&1 | head -100

echo ""
echo "=== Application is ready! ==="
echo "Access at: http://localhost:3002"

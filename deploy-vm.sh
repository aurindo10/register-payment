#!/bin/bash

# Deploy Payment System on AWS VM
# Run this after aws-vm-setup.sh

set -e

echo "🚀 Deploying Payment System on VM..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Build the project
echo "🔨 Building Maven project..."
mvn clean install -DskipTests

# Stop existing services if running
echo "🛑 Stopping existing services..."
docker-compose down --remove-orphans || true

# Remove old images to free space
echo "🧹 Cleaning up old Docker images..."
docker system prune -f

# Build and start services
echo "🐳 Building and starting services..."
docker-compose up -d --build

# Wait for services to be healthy
echo "⏳ Waiting for services to be ready..."

# Wait for PostgreSQL
echo "Waiting for PostgreSQL..."
timeout 60 bash -c 'until docker exec payment-postgres pg_isready -U postgres; do sleep 2; done'

# Wait for RabbitMQ
echo "Waiting for RabbitMQ..."
timeout 60 bash -c 'until docker exec payment-rabbitmq rabbitmq-diagnostics check_port_connectivity; do sleep 2; done'

# Wait for Gateway Service
echo "Waiting for Gateway Service..."
timeout 60 bash -c 'until curl -f http://localhost:8080/api/v1/gateway/health > /dev/null 2>&1; do sleep 2; done'

# Wait for Consumer Service
echo "Waiting for Consumer Service..."
timeout 60 bash -c 'until curl -f http://localhost:8081/actuator/health > /dev/null 2>&1; do sleep 2; done'

# Setup log directory
mkdir -p logs

# Show service status
echo "📊 Service Status:"
docker-compose ps

echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "🌐 Services are available at:"
echo "- Gateway API: http://$(curl -s http://checkip.amazonaws.com):8080"
echo "- Gateway API (via Nginx): http://$(curl -s http://checkip.amazonaws.com)"
echo "- RabbitMQ Management: http://$(curl -s http://checkip.amazonaws.com):15672"
echo "- Consumer Health: http://$(curl -s http://checkip.amazonaws.com):8081/actuator/health"
echo ""
echo "📋 Useful commands:"
echo "- docker-compose logs -f                 # View all logs"
echo "- docker-compose logs -f gateway-service # View gateway logs"
echo "- docker-compose logs -f consumer-service # View consumer logs"
echo "- docker-compose ps                      # Check container status"
echo "- docker-compose down                    # Stop all services"
echo "- docker-compose up -d                   # Start all services"
echo ""
echo "🧪 Test the API:"
echo "curl -X POST http://$(curl -s http://checkip.amazonaws.com)/api/v1/gateway/companies \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"name\": \"Test Company\", \"cnpj\": \"12345678901234\", \"externalCompanyId\": \"test-123\"}'" 
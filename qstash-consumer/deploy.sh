#!/bin/bash

set -e

echo "🚀 Deploying QStash Consumer Application"

# Check if QSTASH_CURRENT_SIGNING_KEY is set
if [ -z "$QSTASH_CURRENT_SIGNING_KEY" ]; then
    echo "❌ Error: QSTASH_CURRENT_SIGNING_KEY environment variable is not set"
    echo "Please set it with: export QSTASH_CURRENT_SIGNING_KEY=your_key_here"
    exit 1
fi

echo "📦 Building Docker image..."
docker build -t qstash-consumer:latest .

echo "🛑 Stopping existing containers..."
docker-compose down

echo "🚀 Starting services..."
docker-compose up -d

echo "⏳ Waiting for services to be healthy..."
sleep 10

echo "✅ Checking application health..."
curl -f http://localhost:8080/api/v1/webhooks/qstash/health || {
    echo "❌ Health check failed"
    docker-compose logs qstash-consumer
    exit 1
}

echo "✅ Deployment complete!"
echo ""
echo "📊 View logs with: docker-compose logs -f"
echo "🛑 Stop services with: docker-compose down"
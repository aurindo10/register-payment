#!/bin/bash
set -e

# RabbitMQ initialization script for Fly.io

echo "🐰 Starting RabbitMQ initialization..."

# Set default credentials if not provided
export RABBITMQ_DEFAULT_USER=${RABBITMQ_DEFAULT_USER:-admin}
export RABBITMQ_DEFAULT_PASS=${RABBITMQ_DEFAULT_PASS:-!@#Solenge123!}

# Create rabbitmq directories with proper permissions
mkdir -p /var/lib/rabbitmq
chown -R rabbitmq:rabbitmq /var/lib/rabbitmq

# Set erlang cookie for clustering (if needed in future)
echo "register-payment-cookie" > /var/lib/rabbitmq/.erlang.cookie
chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
chmod 400 /var/lib/rabbitmq/.erlang.cookie

echo "✅ RabbitMQ initialization complete"

# Start RabbitMQ with original entrypoint
exec docker-entrypoint.sh "$@"
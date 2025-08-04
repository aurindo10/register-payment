#!/bin/bash

# Script to wake up all Fly.io instances
# This starts all stopped machines

set -e

echo "☀️ Waking up all Fly.io instances..."

# List of all Fly.io apps in this project
APPS=(
  "register-payment-db"          # Start database first
  "register-payment-rabbitmq"    # Then RabbitMQ
  "register-payment-consumer"    # Then consumer
  "register-payment-publisher"   # Finally publisher
)

for app in "${APPS[@]}"; do
  echo "Starting machines for app: $app"
  
  # Check if app exists
  if flyctl apps list | grep -q "$app"; then
    # Start all machines for this app
    flyctl machine start --app "$app" --select
    echo "✅ $app machines started"
    
    # Wait a bit between starting services to ensure proper startup order
    if [[ "$app" == "register-payment-db" ]]; then
      echo "⏳ Waiting 15 seconds for PostgreSQL to initialize..."
      sleep 15
    elif [[ "$app" == "register-payment-rabbitmq" ]]; then
      echo "⏳ Waiting 10 seconds for RabbitMQ to initialize..."
      sleep 10
    fi
  else
    echo "⚠️  App $app not found, skipping..."
  fi
  
  echo ""
done

echo "🎉 All instances are now awake!"
echo "💡 To put them to sleep, run: ./scripts/fly-sleep.sh"
echo "📊 Check status with: flyctl status --app <app-name>"
#!/bin/bash

# Script to put all Fly.io instances to sleep
# This stops all machines but keeps the apps deployed

set -e

echo "🛌 Putting all Fly.io instances to sleep..."

# List of all Fly.io apps in this project
APPS=(
  "register-payment-publisher"
  "register-payment-consumer" 
  "register-payment-rabbitmq"
  "register-payment-db"
)

for app in "${APPS[@]}"; do
  echo "Stopping machines for app: $app"
  
  # Check if app exists
  if flyctl apps list | grep -q "$app"; then
    # Stop all machines for this app
    flyctl machine stop --app "$app" --select
    echo "✅ $app machines stopped"
  else
    echo "⚠️  App $app not found, skipping..."
  fi
  
  echo ""
done

echo "🎉 All instances are now sleeping!"
echo "💡 To wake them up, run: ./scripts/fly-wake.sh"
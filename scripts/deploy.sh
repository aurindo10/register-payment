#!/bin/bash

set -e

echo "🚀 Deploying register-payment microservices to fly.io..."

# Check if flyctl is installed
if ! command -v flyctl &> /dev/null; then
    echo "❌ flyctl is not installed. Please install it first:"
    echo "   curl -L https://fly.io/install.sh | sh"
    exit 1
fi

# Check if logged in to fly.io
if ! flyctl auth whoami &> /dev/null; then
    echo "❌ Not logged in to fly.io. Please login first:"
    echo "   flyctl auth login"
    exit 1
fi

echo "📊 Setting up shared infrastructure..."

# Set up PostgreSQL (shared between services)
echo "🐘 Setting up PostgreSQL..."
if ! flyctl postgres list 2>/dev/null | grep -q "register-payment-db"; then
    echo "Creating PostgreSQL database (accept defaults when prompted)..."
    flyctl postgres create --name register-payment-db --region iad --initial-cluster-size 1
fi

# Set up RabbitMQ (self-hosted on Fly.io)
echo "🐰 Setting up RabbitMQ..."
if ! flyctl apps list | grep -q "register-payment-rabbitmq"; then
    echo "Creating RabbitMQ app..."
    flyctl apps create register-payment-rabbitmq --org personal
    
    # Create volume for RabbitMQ data persistence
    flyctl volumes create rabbitmq_data --region iad --size 10 --app register-payment-rabbitmq
fi

# Deploy RabbitMQ service only if not already running
if ! flyctl status --app register-payment-rabbitmq 2>/dev/null | grep -q "started"; then
    echo "Deploying RabbitMQ service..."
    flyctl deploy --config fly.rabbitmq.toml --app register-payment-rabbitmq --wait-timeout 300
    
    # Wait for RabbitMQ to be ready
    echo "Waiting for RabbitMQ to be ready..."
    sleep 30
else
    echo "✅ RabbitMQ already running, skipping deployment"
fi

# Set RabbitMQ URL to our self-hosted instance (using internal networking)
RABBITMQ_HOST="register-payment-rabbitmq.internal"
RABBITMQ_URL="amqp://app_user:AppUser123!@${RABBITMQ_HOST}:5672/register-payment"

echo "✅ RabbitMQ deployed at: ${RABBITMQ_HOST}"
echo "✅ Using RabbitMQ URL: amqp://app_user:***@${RABBITMQ_HOST}:5672/register-payment"

# Deploy Publisher
echo "📤 Deploying Publisher API..."
if ! flyctl apps list | grep -q "register-payment-publisher"; then
    flyctl apps create register-payment-publisher --org personal
fi

# Attach PostgreSQL to publisher (for potential read operations) - only if not already attached
if ! flyctl secrets list --app register-payment-publisher 2>/dev/null | grep -q "DATABASE_URL"; then
    flyctl postgres attach register-payment-db --app register-payment-publisher
else
    echo "✅ PostgreSQL already attached to publisher"
fi

# Set publisher secrets (force update to ensure internal networking)
flyctl secrets set \
    RABBITMQ_URL="$RABBITMQ_URL" \
    --app register-payment-publisher

# Deploy publisher
flyctl deploy --config fly.toml --app register-payment-publisher --wait-timeout 300

# Deploy Consumer
echo "📥 Deploying Consumer Worker..."
if ! flyctl apps list | grep -q "register-payment-consumer"; then
    flyctl apps create register-payment-consumer --org personal
fi

# Attach PostgreSQL to consumer - only if not already attached
if ! flyctl secrets list --app register-payment-consumer 2>/dev/null | grep -q "DATABASE_URL"; then
    echo "Attaching PostgreSQL database to consumer..."
    flyctl postgres attach register-payment-db --app register-payment-consumer
else
    echo "✅ PostgreSQL already attached to consumer"
fi

# The postgres attach command automatically sets these environment variables:
# - DATABASE_URL (full connection string)
# - POSTGRES_HOST
# - POSTGRES_PORT  
# - POSTGRES_USER
# - POSTGRES_PASSWORD
# - POSTGRES_DB

# Set consumer secrets (force update to ensure internal networking)
flyctl secrets set \
    RABBITMQ_URL="$RABBITMQ_URL" \
    --app register-payment-consumer

# Deploy consumer
flyctl deploy --config fly.consumer.toml --app register-payment-consumer --wait-timeout 300

echo "✅ Microservices deployment complete!"
echo ""
echo "📊 Service URLs:"
echo "🔗 Publisher API: https://register-payment-publisher.fly.dev"
echo "👷 Consumer: register-payment-consumer (worker process)"
echo ""
echo "📝 Management:"
echo "   Monitor publisher: flyctl logs --app register-payment-publisher"
echo "   Monitor consumer:  flyctl logs --app register-payment-consumer"
echo "   Scale publisher:   flyctl scale count 2 --app register-payment-publisher"
echo "   Scale consumer:    flyctl scale count 2 --app register-payment-consumer"
echo ""
echo "⚠️  Next steps:"
echo "1. ✅ Self-hosted RabbitMQ deployed successfully"
echo "2. RabbitMQ Management UI: https://register-payment-rabbitmq.fly.dev (admin/!@#Solenge123!)"
echo "3. Verify database connection: flyctl ssh console --app register-payment-consumer"
echo "4. Check environment variables: flyctl ssh console --app register-payment-consumer -C 'env | grep POSTGRES'"
echo "5. Test the API: curl https://register-payment-publisher.fly.dev/api/v1/health"
echo "6. Monitor all services:"
echo "   - Publisher: flyctl logs --app register-payment-publisher"
echo "   - Consumer: flyctl logs --app register-payment-consumer"
echo "   - RabbitMQ: flyctl logs --app register-payment-rabbitmq"
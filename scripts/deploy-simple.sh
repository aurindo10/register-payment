#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo "🚀 Simple deployment script for register-payment microservices..."

# RabbitMQ URL for internal communication
RABBITMQ_URL="amqp://app_user:AppUser123!@register-payment-rabbitmq.internal:5672/register-payment"

# Deploy Publisher
log_info "Deploying Publisher service..."
flyctl deploy --config fly.toml --app register-payment-publisher
if [ $? -eq 0 ]; then
    log_success "Publisher deployed successfully"
else
    log_error "Publisher deployment failed"
    exit 1
fi

# Deploy Consumer  
log_info "Deploying Consumer service..."
flyctl deploy --config fly.consumer.toml --app register-payment-consumer
if [ $? -eq 0 ]; then
    log_success "Consumer deployed successfully"
else
    log_error "Consumer deployment failed"
    exit 1
fi

# Deploy RabbitMQ (if needed)
log_info "Checking RabbitMQ deployment..."
if flyctl status --app register-payment-rabbitmq 2>/dev/null | grep -q "started"; then
    log_success "RabbitMQ is already running"
else
    log_info "Deploying RabbitMQ..."
    flyctl deploy --config fly.rabbitmq.toml --app register-payment-rabbitmq
    if [ $? -eq 0 ]; then
        log_success "RabbitMQ deployed successfully"
    else
        log_warning "RabbitMQ deployment may have issues, but continuing..."
    fi
fi

log_success "🎉 Deployment completed!"
echo ""
log_info "📊 Service URLs:"
echo "   🔗 Publisher API: https://register-payment-publisher.fly.dev"
echo "   👷 Consumer: register-payment-consumer (worker process)"
echo "   🐰 RabbitMQ Management: https://register-payment-rabbitmq.fly.dev"
echo ""
log_info "📝 Management Commands:"
echo "   Monitor publisher: flyctl logs --app register-payment-publisher"
echo "   Monitor consumer:  flyctl logs --app register-payment-consumer"
echo "   Monitor RabbitMQ:  flyctl logs --app register-payment-rabbitmq"
echo ""
log_info "🧪 Test the deployment:"
echo "   curl https://register-payment-publisher.fly.dev/api/v1/health"
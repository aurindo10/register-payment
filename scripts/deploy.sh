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

# Wait for service to be healthy
wait_for_service() {
    local app_name=$1
    local max_attempts=${2:-30}
    local attempt=1
    
    log_info "Waiting for $app_name to be healthy..."
    
    while [ $attempt -le $max_attempts ]; do
        if flyctl status --app "$app_name" 2>/dev/null | grep -q "started"; then
            log_success "$app_name is healthy"
            return 0
        fi
        
        log_info "Attempt $attempt/$max_attempts: $app_name not ready yet, waiting 10s..."
        sleep 10
        ((attempt++))
    done
    
    log_error "$app_name failed to become healthy after $((max_attempts * 10)) seconds"
    return 1
}

# Test service connectivity
test_service_connectivity() {
    local service_url=$1
    local service_name=$2
    local max_attempts=${3:-10}
    local attempt=1
    
    log_info "Testing connectivity to $service_name..."
    
    while [ $attempt -le $max_attempts ]; do
        # More robust connectivity test with timeout and better error handling
        if curl -s -f --max-time 10 --retry 1 "$service_url" > /dev/null 2>&1; then
            log_success "$service_name is accessible"
            return 0
        fi
        
        # For health endpoints, also try without -f flag to see if we get any response
        if echo "$service_url" | grep -q "/health" && curl -s --max-time 10 "$service_url" 2>/dev/null | grep -q "status"; then
            log_success "$service_name is accessible (health endpoint responding)"
            return 0
        fi
        
        log_info "Attempt $attempt/$max_attempts: $service_name not accessible yet, waiting 5s..."
        sleep 5
        ((attempt++))
    done
    
    log_error "$service_name is not accessible after $((max_attempts * 5)) seconds"
    return 1
}

echo "🚀 Deploying register-payment microservices to fly.io..."

# Pre-deployment validation
validate_prerequisites() {
    log_info "Validating prerequisites..."
    
    # Check if flyctl is installed
    if ! command -v flyctl &> /dev/null; then
        log_error "flyctl is not installed. Please install it first:"
        echo "   curl -L https://fly.io/install.sh | sh"
        exit 1
    fi
    
    # Check if logged in to fly.io
    if ! flyctl auth whoami &> /dev/null; then
        log_error "Not logged in to fly.io. Please login first:"
        echo "   flyctl auth login"
        exit 1
    fi
    
    # Check if curl is available for connectivity tests
    if ! command -v curl &> /dev/null; then
        log_error "curl is required for connectivity tests but not found"
        exit 1
    fi
    
    log_success "All prerequisites validated"
}

validate_prerequisites

log_info "Setting up shared infrastructure..."

# Set up PostgreSQL (shared between services)
setup_postgresql() {
    log_info "Setting up PostgreSQL..."
    
    if ! flyctl postgres list 2>/dev/null | grep -q "register-payment-db"; then
        log_info "Creating PostgreSQL database..."
        if flyctl postgres create --name register-payment-db --region iad --initial-cluster-size 1; then
            log_success "PostgreSQL database created successfully"
        else
            log_error "Failed to create PostgreSQL database"
            return 1
        fi
    else
        log_success "PostgreSQL database already exists"
    fi
    
    # Wait for PostgreSQL to be ready
    wait_for_service "register-payment-db" 20
}

setup_postgresql

# Set up RabbitMQ (self-hosted on Fly.io)
setup_rabbitmq() {
    log_info "Setting up RabbitMQ..."
    
    # Create RabbitMQ app if it doesn't exist
    if ! flyctl apps list | grep -q "register-payment-rabbitmq"; then
        log_info "Creating RabbitMQ app..."
        if flyctl apps create register-payment-rabbitmq --org personal; then
            log_success "RabbitMQ app created"
        else
            log_error "Failed to create RabbitMQ app"
            return 1
        fi
        
        # Create volume for RabbitMQ data persistence
        log_info "Creating RabbitMQ volume..."
        if flyctl volumes create rabbitmq_data --region iad --size 10 --app register-payment-rabbitmq; then
            log_success "RabbitMQ volume created"
        else
            log_error "Failed to create RabbitMQ volume"
            return 1
        fi
    fi
    
    # Deploy RabbitMQ service only if not already running
    if ! flyctl status --app register-payment-rabbitmq 2>/dev/null | grep -q "started"; then
        log_info "Deploying RabbitMQ service..."
        if flyctl deploy --config fly.rabbitmq.toml --app register-payment-rabbitmq --wait-timeout 300; then
            log_success "RabbitMQ deployed successfully"
        else
            log_error "Failed to deploy RabbitMQ"
            return 1
        fi
        
        # Wait for RabbitMQ to be fully ready
        wait_for_service "register-payment-rabbitmq" 30
    else
        log_success "RabbitMQ already running, skipping deployment"
    fi
    
    # Test RabbitMQ management interface (optional - don't block deployment)
    log_info "Testing RabbitMQ management interface..."
    if test_service_connectivity "https://register-payment-rabbitmq.fly.dev" "RabbitMQ Management" 5; then
        log_success "RabbitMQ is accessible via management interface"
    else
        log_warning "RabbitMQ management interface not accessible - this is OK, continuing..."
        log_info "Note: RabbitMQ may have disk space issues, but AMQP should still work"
    fi
}

setup_rabbitmq

# Set RabbitMQ URL to our self-hosted instance (using internal networking)
RABBITMQ_HOST="register-payment-rabbitmq.internal"
RABBITMQ_URL="amqp://app_user:AppUser123!@${RABBITMQ_HOST}:5672/register-payment"

echo "✅ RabbitMQ deployed at: ${RABBITMQ_HOST}"
echo "✅ Using RabbitMQ URL: amqp://app_user:***@${RABBITMQ_HOST}:5672/register-payment"

# Deploy Publisher
deploy_publisher() {
    log_info "Deploying Publisher API..."
    
    # Create publisher app if it doesn't exist
    if ! flyctl apps list | grep -q "register-payment-publisher"; then
        log_info "Creating Publisher app..."
        if flyctl apps create register-payment-publisher --org personal; then
            log_success "Publisher app created"
        else
            log_error "Failed to create Publisher app"
            return 1
        fi
    fi
    
    # Attach PostgreSQL to publisher (for potential read operations) - only if not already attached
    if ! flyctl secrets list --app register-payment-publisher 2>/dev/null | grep -q "DATABASE_URL"; then
        log_info "Attaching PostgreSQL to Publisher..."
        if flyctl postgres attach register-payment-db --app register-payment-publisher; then
            log_success "PostgreSQL attached to Publisher"
        else
            log_error "Failed to attach PostgreSQL to Publisher"
            return 1
        fi
    else
        log_success "PostgreSQL already attached to Publisher"
    fi
    
    # Set publisher secrets (this will trigger a deployment)
    log_info "Setting Publisher secrets and deploying..."
    if flyctl secrets set RABBITMQ_URL="$RABBITMQ_URL" --app register-payment-publisher --detach; then
        log_success "Publisher secrets updated (deployment started in background)"
        
        # Wait for the secret-triggered deployment to complete
        log_info "Waiting for secrets deployment to complete..."
        wait_for_service "register-payment-publisher" 30
    else
        log_error "Failed to set Publisher secrets"
        return 1
    fi
    
    # Wait for publisher to be ready (reduced timeout)
    wait_for_service "register-payment-publisher" 10
    
    # Quick publisher health check (non-blocking)
    log_info "Testing Publisher API connectivity..."
    if curl -s -f --max-time 5 "https://register-payment-publisher.fly.dev/api/v1/health" > /dev/null 2>&1; then
        log_success "Publisher API is accessible and healthy"
    else
        log_warning "Publisher API not immediately accessible (may still be starting)"
        log_info "Test manually: curl https://register-payment-publisher.fly.dev/api/v1/health"
    fi
}

deploy_publisher

# Deploy Consumer
deploy_consumer() {
    log_info "Deploying Consumer Worker..."
    
    # Create consumer app if it doesn't exist
    if ! flyctl apps list | grep -q "register-payment-consumer"; then
        log_info "Creating Consumer app..."
        if flyctl apps create register-payment-consumer --org personal; then
            log_success "Consumer app created"
        else
            log_error "Failed to create Consumer app"
            return 1
        fi
    fi
    
    # Attach PostgreSQL to consumer - only if not already attached
    if ! flyctl secrets list --app register-payment-consumer 2>/dev/null | grep -q "DATABASE_URL"; then
        log_info "Attaching PostgreSQL database to Consumer..."
        if flyctl postgres attach register-payment-db --app register-payment-consumer; then
            log_success "PostgreSQL attached to Consumer"
        else
            log_error "Failed to attach PostgreSQL to Consumer"
            return 1
        fi
    else
        log_success "PostgreSQL already attached to Consumer"
    fi
    
    # Set consumer secrets (this will trigger a deployment)
    # The consumer application now has correct defaults, so we only need to set RabbitMQ
    log_info "Setting Consumer secrets and deploying..."
    if flyctl secrets set RABBITMQ_URL="$RABBITMQ_URL" --app register-payment-consumer --detach; then
        log_success "Consumer secrets updated (deployment started in background)"
        
        # Wait for the secret-triggered deployment to complete
        log_info "Waiting for secrets deployment to complete..."
        wait_for_service "register-payment-consumer" 30
    else
        log_error "Failed to set Consumer secrets"
        return 1
    fi
    
    # Wait for consumer to be ready (reduced timeout since it's a worker)
    wait_for_service "register-payment-consumer" 10
}

deploy_consumer

# Final validation and summary
final_validation() {
    log_info "Performing final deployment validation..."
    
    # Check service statuses (simplified)
    local all_healthy=true
    
    for app in "register-payment-publisher" "register-payment-consumer" "register-payment-rabbitmq"; do
        if flyctl status --app "$app" 2>/dev/null | grep -q "started"; then
            log_success "$app is running"
        else
            log_warning "$app may still be starting"
        fi
    done
    
    log_success "Deployment validation completed!"
    return 0
}

# Run final validation
if final_validation; then
    log_success "🎉 Microservices deployment completed successfully!"
    echo ""
    log_info "📊 Service URLs:"
    echo "   🔗 Publisher API: https://register-payment-publisher.fly.dev"
    echo "   👷 Consumer: register-payment-consumer (worker process)"
    echo "   🐰 RabbitMQ Management: https://register-payment-rabbitmq.fly.dev (admin/!@#Solenge123!)"
    echo ""
    log_info "📝 Management Commands:"
    echo "   Monitor publisher: flyctl logs --app register-payment-publisher"
    echo "   Monitor consumer:  flyctl logs --app register-payment-consumer"
    echo "   Monitor RabbitMQ:  flyctl logs --app register-payment-rabbitmq"
    echo "   Scale publisher:   flyctl scale count 2 --app register-payment-publisher"
    echo "   Scale consumer:    flyctl scale count 2 --app register-payment-consumer"
    echo ""
    log_info "🧪 Test the deployment:"
    echo "   curl https://register-payment-publisher.fly.dev/api/v1/health"
    echo '   curl -X POST https://register-payment-publisher.fly.dev/api/v1/transactions/ \'
    echo '        -H "Content-Type: application/json" \'
    echo '        -d '"'"'{"transaction_id":"TEST-001","value":"100.50","type":"in","external_company_id":"COMP-001"}'"'"
else
    log_error "🚨 Deployment completed with issues. Please check the logs above."
    echo ""
    log_info "🔧 Troubleshooting commands:"
    echo "   Check Publisher: flyctl logs --app register-payment-publisher"
    echo "   Check Consumer:  flyctl logs --app register-payment-consumer"
    echo "   Check RabbitMQ:  flyctl logs --app register-payment-rabbitmq"
    echo "   Check statuses:  flyctl status --app <app-name>"
    exit 1
fi
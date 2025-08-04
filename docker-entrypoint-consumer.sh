#!/bin/sh
set -e

echo "Starting Transaction Consumer..."

# Wait for PostgreSQL to be ready
wait_for_postgres() {
    echo "Waiting for PostgreSQL to be ready..."
    until pg_isready -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER"; do
        echo "PostgreSQL is unavailable - sleeping"
        sleep 2
    done
    echo "PostgreSQL is ready!"
}

# Wait for RabbitMQ to be ready
wait_for_rabbitmq() {
    echo "Waiting for RabbitMQ to be ready..."
    # Extract host and port from RABBITMQ_URL
    RABBITMQ_HOST=$(echo "$RABBITMQ_URL" | sed -n 's/.*@\([^:]*\):.*/\1/p')
    RABBITMQ_PORT=$(echo "$RABBITMQ_URL" | sed -n 's/.*:\([0-9]*\)\/.*/\1/p')
    
    if [ -z "$RABBITMQ_HOST" ]; then
        RABBITMQ_HOST="localhost"
    fi
    if [ -z "$RABBITMQ_PORT" ]; then
        RABBITMQ_PORT="5672"
    fi
    
    until nc -z "$RABBITMQ_HOST" "$RABBITMQ_PORT"; do
        echo "RabbitMQ is unavailable - sleeping"
        sleep 2
    done
    echo "RabbitMQ is ready!"
}

# Run database migrations
run_migrations() {
    echo "Running database migrations..."
    if command -v migrate > /dev/null 2>&1; then
        migrate -path ./migrations -database "postgres://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DB?sslmode=$POSTGRES_SSL_MODE" up
    else
        echo "migrate command not found, skipping migrations"
    fi
}

# Validate required environment variables
validate_environment() {
    echo "Validating environment variables..."
    
    # Database configuration
    if [ -z "$POSTGRES_HOST" ]; then
        echo "❌ ERROR: POSTGRES_HOST environment variable is required"
        exit 1
    fi
    
    if [ -z "$POSTGRES_USER" ]; then
        echo "❌ ERROR: POSTGRES_USER environment variable is required"
        exit 1
    fi
    
    if [ -z "$POSTGRES_PASSWORD" ]; then
        echo "❌ ERROR: POSTGRES_PASSWORD environment variable is required"
        exit 1
    fi
    
    if [ -z "$POSTGRES_DB" ]; then
        echo "❌ ERROR: POSTGRES_DB environment variable is required"
        exit 1
    fi
    
    # RabbitMQ configuration
    if [ -z "$RABBITMQ_URL" ]; then
        echo "❌ ERROR: RABBITMQ_URL environment variable is required"
        exit 1
    fi
    
    echo "✅ Environment validation passed"
}

# Main execution
main() {
    echo "Initializing Transaction Consumer..."
    
    # Validate environment variables first
    validate_environment
    
    # Wait for dependencies
    wait_for_postgres
    wait_for_rabbitmq
    
    # Run migrations
    run_migrations
    
    echo "Starting consumer process..."
    exec "$@"
}

# Call main function with all arguments
main "$@"
#!/bin/sh
set -e

echo "Starting Transaction Consumer..."

# Wait for PostgreSQL to be ready
wait_for_postgres() {
    echo "Waiting for PostgreSQL to be ready..."
    
    # Use defaults if not set
    PG_HOST=${POSTGRES_HOST:-register-payment-db.internal}
    PG_PORT=${POSTGRES_PORT:-5432}
    PG_USER=${POSTGRES_USER:-postgres}
    
    until pg_isready -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER"; do
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
        # Use defaults if not set
        PG_HOST=${POSTGRES_HOST:-register-payment-db.internal}
        PG_PORT=${POSTGRES_PORT:-5432}
        PG_USER=${POSTGRES_USER:-postgres}
        PG_PASSWORD=${POSTGRES_PASSWORD:-}
        PG_DB=${POSTGRES_DB:-register_payment}
        PG_SSL=${POSTGRES_SSL_MODE:-require}
        
        migrate -path ./migrations -database "postgres://$PG_USER:$PG_PASSWORD@$PG_HOST:$PG_PORT/$PG_DB?sslmode=$PG_SSL" up
    else
        echo "migrate command not found, skipping migrations"
    fi
}

# Validate required environment variables
validate_environment() {
    echo "Validating environment variables..."
    
    # Only validate critical variables that don't have sensible defaults
    # The Go application has defaults for most database variables
    
    # RabbitMQ configuration is critical and has no sensible default
    if [ -z "$RABBITMQ_URL" ]; then
        echo "❌ ERROR: RABBITMQ_URL environment variable is required"
        exit 1
    fi
    
    # Log the configuration we're using (with masked password)
    echo "📋 Configuration:"
    echo "   POSTGRES_HOST: ${POSTGRES_HOST:-register-payment-db.internal (default)}"
    echo "   POSTGRES_PORT: ${POSTGRES_PORT:-5432 (default)}"
    echo "   POSTGRES_USER: ${POSTGRES_USER:-postgres (default)}"
    echo "   POSTGRES_DB: ${POSTGRES_DB:-register_payment (default)}"
    echo "   POSTGRES_SSL_MODE: ${POSTGRES_SSL_MODE:-require (default)}"
    echo "   DATABASE_URL: $(echo "${DATABASE_URL:-not set}" | sed 's/:\/\/[^:]*:[^@]*@/:\/\/***:***@/')"
    echo "   RABBITMQ_URL: $(echo "$RABBITMQ_URL" | sed 's/:\/\/[^:]*:[^@]*@/:\/\/***:***@/')"
    
    # If DATABASE_URL exists, extract PostgreSQL host and override defaults
    if [ -n "$DATABASE_URL" ]; then
        echo "🔍 Extracting PostgreSQL details from DATABASE_URL..."
        
        # Extract components from DATABASE_URL
        DB_EXTRACTED_HOST=$(echo "$DATABASE_URL" | sed -n 's/.*@\([^:]*\):.*/\1/p')
        DB_EXTRACTED_DB=$(echo "$DATABASE_URL" | sed -n 's/.*\/\([^?]*\).*/\1/p')
        DB_EXTRACTED_USER=$(echo "$DATABASE_URL" | sed -n 's/.*:\/\/\([^:]*\):.*/\1/p')
        DB_EXTRACTED_PASSWORD=$(echo "$DATABASE_URL" | sed -n 's/.*:\/\/[^:]*:\([^@]*\)@.*/\1/p')
        
        # Override environment variables with extracted values
        export POSTGRES_HOST="${POSTGRES_HOST:-$DB_EXTRACTED_HOST}"
        export POSTGRES_DB="${POSTGRES_DB:-$DB_EXTRACTED_DB}"
        export POSTGRES_USER="${POSTGRES_USER:-$DB_EXTRACTED_USER}"
        export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-$DB_EXTRACTED_PASSWORD}"
        
        echo "✅ Updated PostgreSQL config from DATABASE_URL:"
        echo "   POSTGRES_HOST: $POSTGRES_HOST"
        echo "   POSTGRES_DB: $POSTGRES_DB"
        echo "   POSTGRES_USER: $POSTGRES_USER"
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
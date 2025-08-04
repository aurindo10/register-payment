# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Build and Test
```bash
# Build microservices
go build -o bin/publisher ./cmd/publisher  # API-only service
go build -o bin/consumer ./cmd/consumer    # Worker-only service

# Run tests
go test ./...

# Format code
go fmt ./...

# Vet code
go vet ./...
```

### Local Development
```bash
# Start infrastructure (PostgreSQL + RabbitMQ)
docker-compose up postgres rabbitmq -d

# Set environment variables
cp .env.example .env
# Edit .env with your values

# Run database migrations
go run scripts/migrate.go -direction=up

# Run publisher (API only)
go run ./cmd/publisher

# In another terminal, run consumer (worker only)
go run ./cmd/consumer
```

### Docker Deployment
```bash
# Deploy microservices stack
docker-compose up -d

# View logs
docker-compose logs -f publisher
docker-compose logs -f consumer

# Scale services independently
docker-compose up -d --scale publisher=3 --scale consumer=2

# Stop services
docker-compose down
```

### Fly.io Deployment
```bash
# Deploy both services with shared PostgreSQL
./scripts/deploy.sh

# Monitor services
flyctl logs --app register-payment-publisher
flyctl logs --app register-payment-consumer

# Scale services independently
flyctl scale count 3 --app register-payment-publisher  # Scale API
flyctl scale count 2 --app register-payment-consumer   # Scale workers
```

## Architecture Overview

This is a **Go microservices application** for transaction processing with **RabbitMQ message queuing**:

### Microservices Architecture

#### Publisher Service (`cmd/publisher`)
- **Purpose**: REST API that accepts transactions and publishes to RabbitMQ
- **Port**: 8080
- **Dependencies**: RabbitMQ only (no database)
- **Scaling**: Horizontal (stateless)

#### Consumer Service (`cmd/consumer`) 
- **Purpose**: Background worker that processes messages and persists to database
- **Port**: None (worker process)  
- **Dependencies**: RabbitMQ + PostgreSQL
- **Scaling**: Based on queue depth

### Message Flow
1. Frontend/API clients send transactions to Publisher API
2. Publisher validates and publishes messages to RabbitMQ
3. Consumer processes messages from queue
4. Consumer persists transaction data to PostgreSQL database

### Key Technologies
- Go 1.21+
- Gin HTTP framework
- RabbitMQ for reliable message queuing
- PostgreSQL with golang-migrate migrations
- Native Go Money type for financial precision
- Docker for deployment

## Database Schema

Tables managed via migrations in `migrations/`:
- `transactions` - Transaction records with value, type (in/out), and external company ID

## RabbitMQ Integration

- **Exchange**: `transactions` (direct exchange)
- **Queue**: `transaction.register` 
- **Routing Key**: `transaction.register`
- **Message Format**: JSON with TransactionRequest structure
- **Reliability**: Message acknowledgments and automatic retries

## REST API Endpoints

### Publisher API Endpoints (port 8080)
- `POST /api/v1/transactions/` - Queue transaction for processing
- `GET /api/v1/health` - Health check
- `GET /api/v1/metrics` - Publisher metrics

## Environment Configuration

### Publisher Service Environment Variables
- `PORT` (default: 8080) - HTTP server port
- `RABBITMQ_URL` (default: amqp://guest:guest@localhost:5672/) - RabbitMQ connection
- `RABBITMQ_EXCHANGE` (default: transactions) - RabbitMQ exchange name  
- `RABBITMQ_QUEUE` (default: transaction.register) - RabbitMQ queue name

### Consumer Service Environment Variables
- `POSTGRES_HOST` (default: localhost) - Database host
- `POSTGRES_PORT` (default: 5432) - Database port
- `POSTGRES_DB` (default: register_payment) - Database name
- `POSTGRES_USER` (default: postgres) - Database user
- `POSTGRES_PASSWORD` (default: password) - Database password
- `POSTGRES_SSL_MODE` (default: disable) - Database SSL mode
- `RABBITMQ_URL` (default: amqp://guest:guest@localhost:5672/) - RabbitMQ connection
- `RABBITMQ_EXCHANGE` (default: transactions) - RabbitMQ exchange name
- `RABBITMQ_QUEUE` (default: transaction.register) - RabbitMQ queue name

## Development Guidelines

### Application Structure
- Go microservices project structure:
  - `cmd/publisher/` - Publisher service entry point
  - `cmd/consumer/` - Consumer service entry point
  - `internal/config/` - Configuration management
  - `internal/dto/` - Data Transfer Objects
  - `internal/entity/` - Database entities
  - `internal/handler/` - HTTP and message handlers
  - `internal/repository/` - Data access layer
  - `internal/service/` - Business logic layer
  - `pkg/database/` - Database connection utilities
  - `pkg/rabbitmq/` - RabbitMQ connection and messaging
  - `pkg/money/` - Financial calculations with precision
  - `migrations/` - Database migrations
  - `scripts/` - Deployment scripts

### Testing Strategy
- Go test structure in each package
- Run tests with `go test ./...`
- Integration tests require running PostgreSQL

### Code Organization
- Clean architecture with dependency injection
- Interface-based service layer
- Repository pattern for data access
- Configuration via environment variables
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Build and Test
```bash
# Build the Go application
go build -o bin/server ./cmd/server

# Run tests
go test ./...

# Build Docker image
docker build -t register-payment:latest .

# Format code
go fmt ./...

# Vet code
go vet ./...
```

### Local Development
```bash
# Start PostgreSQL (required for the application)
docker run -d --name postgres \
  -e POSTGRES_DB=optica-db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=optica123 \
  -p 5432:5432 postgres:15

# Set environment variables
export QSTASH_CURRENT_SIGNING_KEY=your_current_signing_key_here
export QSTASH_NEXT_SIGNING_KEY=your_next_signing_key_here

# Run database migrations
go run scripts/migrate.go -direction=up

# Run the application (port 8080)
go run ./cmd/server
```

### Docker Deployment
```bash
# Deploy complete stack (PostgreSQL + Application)
docker-compose up -d

# View logs
docker-compose logs -f app

# Stop services
docker-compose down
```

## Architecture Overview

This is a **Go application** that processes **QStash webhook messages** for transaction registration:

### Core Application
- **register-payment**: Go application that receives QStash webhooks and processes transaction data (port 8080)

### Message Flow
1. Frontend sends transaction data to QStash API
2. QStash delivers webhook messages to application endpoints
3. Application verifies signatures and processes messages
4. Transaction data is stored in PostgreSQL database

### Key Technologies
- Go 1.21+
- Gin HTTP framework
- QStash for serverless message queuing
- PostgreSQL with golang-migrate migrations
- JWT and HMAC signature verification
- Docker for deployment

## Database Schema

Tables managed via migrations in `migrations/`:
- `transactions` - Transaction records with value, type (in/out), and external company ID

## QStash Integration

- **Webhook Endpoints**: `/api/v1/webhooks/qstash/transaction`
- **Signature Verification**: JWT-based and HMAC-256 with key rotation support
- **Retry Handling**: Automatic retries by QStash on 5xx responses
- **Security**: All endpoints require valid QStash signatures

## REST API Endpoints

### QStash Webhook Endpoints (port 8080)
- `POST /api/v1/webhooks/qstash/transaction` - Process transaction creation
- `GET /api/v1/webhooks/qstash/health` - Health check

## Environment Configuration

The service uses environment variables with sensible defaults:

### QStash Configuration
- `QSTASH_CURRENT_SIGNING_KEY` - Current signing key for webhook verification (required)
- `QSTASH_NEXT_SIGNING_KEY` - Next signing key for key rotation (optional)

### Database Configuration
- `POSTGRES_HOST` (default: localhost)
- `POSTGRES_PORT` (default: 5432)
- `POSTGRES_DB` (default: optica-db)
- `POSTGRES_USER` (default: postgres)
- `POSTGRES_PASSWORD` (default: optica123)
- `POSTGRES_SSL_MODE` (default: disable)

### Server Configuration
- `PORT` (default: 8080)

## Development Guidelines

### Application Structure
- Go project structure with clear separation of concerns:
  - `cmd/server/` - Application entry point
  - `internal/config/` - Configuration management
  - `internal/dto/` - Data Transfer Objects
  - `internal/entity/` - Database entities
  - `internal/handler/` - HTTP handlers
  - `internal/repository/` - Data access layer
  - `internal/service/` - Business logic layer
  - `pkg/database/` - Database connection utilities
  - `migrations/` - Database migrations
  - `scripts/` - Utility scripts

### Testing Strategy
- Go test structure in each package
- Run tests with `go test ./...`
- Integration tests require running PostgreSQL

### Code Organization
- Clean architecture with dependency injection
- Interface-based service layer
- Repository pattern for data access
- Configuration via environment variables
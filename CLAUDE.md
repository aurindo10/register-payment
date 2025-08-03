# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Build and Test
```bash
# Build the QStash consumer application
cd qstash-consumer
mvn clean install
mvn test

# Build Docker image
docker build -t qstash-consumer:latest .

# Package application
mvn clean package -DskipTests
```

### Local Development
```bash
# Start PostgreSQL (required for qstash-consumer)
docker run -d --name postgres \
  -e POSTGRES_DB=optica-db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=optica123 \
  -p 5432:5432 postgres:15

# Set QStash environment variables
export QSTASH_CURRENT_SIGNING_KEY=your_current_signing_key_here
export QSTASH_NEXT_SIGNING_KEY=your_next_signing_key_here

# Run QStash consumer service (port 8080)
cd qstash-consumer && mvn spring-boot:run
```

### Docker Deployment
```bash
# Deploy complete stack (PostgreSQL + QStash Consumer)
cd qstash-consumer
./deploy.sh

# View logs
docker-compose logs -f qstash-consumer

# Stop services
docker-compose down
```

## Architecture Overview

This is a **single Spring Boot application** that processes **QStash webhook messages**:

### Core Application
- **qstash-consumer**: Single Spring Boot application that receives QStash webhooks and processes payment data (port 8080)

### Message Flow
1. Frontend sends data to QStash API
2. QStash delivers webhook messages to consumer endpoints
3. QStash Consumer verifies signatures and processes messages
4. Data is stored in PostgreSQL database

### Key Technologies
- Java 21 + Spring Boot 3.2.0
- QStash for serverless message queuing
- PostgreSQL with Flyway migrations
- JPA/Hibernate for database access
- Docker for deployment

## Database Schema

Tables managed via Flyway migrations in `qstash-consumer/src/main/resources/db/migration/`:
- `company` - Company entities
- `account` - Account entities linked to companies
- `register` - Transaction registers
- `transaction` - Financial transactions
- `conciliation` - Reconciliation records

## QStash Integration

- **Webhook Endpoints**: `/api/v1/webhooks/qstash/{entity}`
- **Signature Verification**: JWT-based with HMAC-256
- **Retry Handling**: Automatic retries by QStash on 5xx responses
- **Security**: All endpoints require valid QStash signatures

## REST API Endpoints

### QStash Webhook Endpoints (port 8080)
- `POST /api/v1/webhooks/qstash/company` - Process company creation
- `POST /api/v1/webhooks/qstash/account` - Process account creation
- `POST /api/v1/webhooks/qstash/register` - Process register creation
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

## Development Guidelines

### Application Structure
- All code is in single module: `qstash-consumer/`
- Entities in `src/main/java/com/optica/consumer/entity/`
- DTOs in `src/main/java/com/optica/consumer/dto/`
- Controllers in `src/main/java/com/optica/consumer/controller/`
- Services in `src/main/java/com/optica/consumer/service/`
- Repositories in `src/main/java/com/optica/consumer/repository/`

### Testing Strategy
- Spring Boot test structure in `src/test/`
- Run tests with `mvn test`
- Use `./test-webhook.sh` to test webhook endpoints
- Integration tests require running PostgreSQL

### Code Organization
- Single application with clear package separation
- Service implementations follow interface pattern
- Repository layer uses Spring Data JPA
- Configuration classes in `config/` package
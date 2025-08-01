# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Build and Test
```bash
# Build entire project (parent + all modules)
mvn clean install

# Build without tests
mvn clean install -DskipTests

# Run tests
mvn test

# Build specific service
cd gateway-service && mvn clean package
cd consumer-service && mvn clean package
```

### Local Development
```bash
# Start PostgreSQL (required for consumer-service)
docker run -d --name postgres \
  -e POSTGRES_DB=optica-db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=optica123 \
  -p 5432:5432 postgres:15

# Start RabbitMQ (required for message queuing)
docker run -d --name rabbitmq \
  -e RABBITMQ_DEFAULT_USER=guest \
  -e RABBITMQ_DEFAULT_PASS=guest \
  -p 5672:5672 -p 15672:15672 \
  rabbitmq:3.12-management

# Run gateway service (port 8080)
cd gateway-service && mvn spring-boot:run

# Run consumer service (port 8081)
cd consumer-service && mvn spring-boot:run
```

### Docker and Kubernetes (K3s)
```bash
# Setup K3s on VM (first time only)
./k3s-setup.sh

# Build Docker images
./build-images.sh

# Deploy to K3s
cd k8s && ./deploy.sh

# Check deployment status
sudo k3s kubectl get pods -n payment-system
sudo k3s kubectl logs -f deployment/gateway-service -n payment-system
sudo k3s kubectl logs -f deployment/consumer-service -n payment-system
```

## Architecture Overview

This is a **multi-module Spring Boot microservices** project with **event-driven architecture** using RabbitMQ:

### Core Modules
- **shared-module**: Common entities, DTOs, and events shared across services
- **gateway-service**: HTTP REST API that publishes events to RabbitMQ (port 8080)
- **consumer-service**: Consumes RabbitMQ messages and handles database operations (port 8081)

### Message Flow
1. HTTP requests → Gateway Service
2. Gateway publishes events to RabbitMQ (payment.exchange)
3. Consumer Service processes events and updates PostgreSQL database

### Key Technologies
- Java 21 + Spring Boot 3.5.3
- RabbitMQ for messaging (Topic exchange)
- PostgreSQL with Flyway migrations
- JPA/Hibernate for database access
- Docker + Kubernetes deployment

## Database Schema

Tables managed via Flyway migrations in `src/main/resources/db/migration/`:
- `company` - Company entities
- `account` - Account entities linked to companies
- `register` - Transaction registers
- `transaction` - Financial transactions
- `conciliation` - Reconciliation records

## RabbitMQ Configuration

- **Exchange**: `payment.exchange` (Topic)
- **Queues & Routing Keys**:
  - `company.queue` → `company.created`
  - `account.queue` → `account.created` 
  - `register.queue` → `register.created`

## REST API Endpoints

### Gateway Service (port 8080)
- `POST /api/v1/gateway/companies` - Create company
- `POST /api/v1/gateway/accounts` - Create account  
- `POST /api/v1/gateway/registers` - Create register
- `GET /api/v1/gateway/health` - Health check

### Consumer Service (port 8081)
- `GET /actuator/health` - Health check

## Environment Configuration

Services use environment variables with sensible defaults:

### Database (Consumer Service)
- `POSTGRES_HOST` (default: localhost)
- `POSTGRES_PORT` (default: 5432)
- `POSTGRES_DB` (default: optica-db)
- `POSTGRES_USER` (default: postgres)
- `POSTGRES_PASSWORD` (default: optica123)

### RabbitMQ (Both Services)
- `RABBITMQ_HOST` (default: localhost)
- `RABBITMQ_PORT` (default: 5672)
- `RABBITMQ_USERNAME` (default: guest)
- `RABBITMQ_PASSWORD` (default: guest)

## Development Guidelines

### Module Dependencies
- Services depend on `shared-module` for common entities and DTOs
- Always build parent project first: `mvn clean install`
- Services are independently deployable but share data contracts

### Testing Strategy
- Basic Spring Boot test structure exists in `src/test/`
- Run tests with `mvn test`
- Integration tests require running PostgreSQL and RabbitMQ

### Code Organization
- Entities in `shared-module/src/main/java/com/optica/shared/entities/`
- REST controllers in each service's `controller/` package
- Service implementations follow interface pattern
- Repository layer uses Spring Data JPA
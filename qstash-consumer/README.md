# QStash Consumer Service

A Spring Boot application that consumes messages from QStash webhooks and saves them to a PostgreSQL database.

## Architecture

This service receives webhook calls from QStash for:
- Company creation
- Account creation
- Register/Transaction creation

Each webhook endpoint verifies the QStash signature before processing the message.

## Prerequisites

- Docker and Docker Compose
- QStash account and signing keys from Upstash

## Configuration

Set the following environment variables:

```bash
export QSTASH_CURRENT_SIGNING_KEY=your_current_signing_key_here
export QSTASH_NEXT_SIGNING_KEY=your_next_signing_key_here  # Optional, for key rotation
```

## Deployment

### Local Development

```bash
# Start PostgreSQL only
docker-compose up -d postgres

# Run the application
mvn spring-boot:run
```

### Production Deployment

```bash
# Set your QStash signing key
export QSTASH_CURRENT_SIGNING_KEY=your_key_here

# Deploy everything
./deploy.sh
```

## API Endpoints

### Webhook Endpoints (called by QStash)
- `POST /api/v1/webhooks/qstash/company` - Receive company creation messages
- `POST /api/v1/webhooks/qstash/account` - Receive account creation messages
- `POST /api/v1/webhooks/qstash/register` - Receive register creation messages

### Health Check
- `GET /api/v1/webhooks/qstash/health` - Application health status

## Database Schema

The application uses Flyway migrations to manage the database schema. Tables include:
- `company` - Company entities
- `account` - Account entities linked to companies
- `register` - Transaction registers
- `transaction` - Financial transactions
- `conciliation` - Reconciliation records

## Monitoring

View application logs:
```bash
docker-compose logs -f qstash-consumer
```

Check application health:
```bash
curl http://localhost:8080/api/v1/webhooks/qstash/health
```

## Security

- All webhook endpoints require valid QStash signatures
- Invalid signatures return 401 Unauthorized
- Processing errors return 500 to trigger QStash retries
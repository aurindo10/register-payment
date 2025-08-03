# QStash Payment Consumer Service

A Spring Boot application that processes payment-related messages from QStash webhooks and stores them in a PostgreSQL database. This service replaces traditional message brokers with QStash's serverless message queue for reliable, scalable message processing.

## Architecture

```
Frontend → QStash API → QStash Consumer Service → PostgreSQL Database
```

The system consists of:

### QStash Consumer Service (`qstash-consumer/`)
- **Port**: 8080
- **Purpose**: Receives webhook calls from QStash and processes payment data
- **Responsibilities**:
  - Receive and verify QStash webhook signatures
  - Process company, account, and register creation messages
  - Persist data to PostgreSQL database
  - Provide health checks and monitoring

### Key Features
- **QStash Integration**: Secure webhook endpoints with JWT signature verification
- **Asynchronous Processing**: Reliable message processing with automatic retries
- **Database Management**: PostgreSQL with Flyway migrations
- **Docker Deployment**: Single container deployment with docker-compose
- **Health Monitoring**: Built-in health checks and logging

## Technologies

- **Java 21** + **Spring Boot 3.2.0**
- **QStash** for serverless message queuing
- **PostgreSQL** with Flyway migrations
- **Docker** for containerization
- **Maven** for dependency management

## Quick Start

### 1. Prerequisites
- Docker and Docker Compose
- QStash account and signing keys from [Upstash Console](https://console.upstash.com/)

### 2. Set Environment Variables
```bash
export QSTASH_CURRENT_SIGNING_KEY=your_current_signing_key_here
export QSTASH_NEXT_SIGNING_KEY=your_next_signing_key_here  # Optional
```

### 3. Deploy the Service
```bash
cd qstash-consumer
./deploy.sh
```

The service will be available at `http://localhost:8080`

## API Endpoints

### Webhook Endpoints (Called by QStash)
- `POST /api/v1/webhooks/qstash/company` - Process company creation messages
- `POST /api/v1/webhooks/qstash/account` - Process account creation messages
- `POST /api/v1/webhooks/qstash/register` - Process register creation messages

### Health Check
- `GET /api/v1/webhooks/qstash/health` - Service health status

## Frontend Integration

Frontend applications send messages to QStash, which then delivers them to the webhook endpoints. See the [Frontend Integration Guide](FRONTEND_INTEGRATION_GUIDE.md) for detailed implementation examples.

### Quick Example (JavaScript)
```javascript
import { Client } from '@upstash/qstash';

const qstash = new Client({
  token: process.env.QSTASH_TOKEN,
});

// Create a company
await qstash.publishJSON({
  url: "https://your-domain.com/api/v1/webhooks/qstash/company",
  body: {
    name: "Example Company",
    cnpj: "12345678901234",
    externalCompanyId: "EXT-001"
  }
});
```

## Data Models

### CompanyRequest
```json
{
  "name": "Company Name",
  "cnpj": "12345678901234",
  "externalCompanyId": "EXT-001"
}
```

### AccountRequest
```json
{
  "companyId": 1,
  "accountNumber": "ACC-001", 
  "accountType": "CHECKING",
  "balance": 1000.00
}
```

### RegisterRequest
```json
{
  "accountId": 1,
  "description": "Transaction description",
  "amount": 100.00,
  "type": "CREDIT"
}
```

## Database Schema

The service uses PostgreSQL with Flyway migrations. Tables include:
- `company` - Company entities
- `account` - Account entities linked to companies
- `register` - Transaction registers
- `transaction` - Financial transactions
- `conciliation` - Reconciliation records

## Configuration

### Environment Variables
- `QSTASH_CURRENT_SIGNING_KEY` - QStash signing key for webhook verification
- `QSTASH_NEXT_SIGNING_KEY` - Next signing key for key rotation (optional)
- `POSTGRES_HOST` - PostgreSQL host (default: localhost)
- `POSTGRES_PORT` - PostgreSQL port (default: 5432)
- `POSTGRES_DB` - Database name (default: optica-db)
- `POSTGRES_USER` - Database username (default: postgres)
- `POSTGRES_PASSWORD` - Database password (default: optica123)

## Monitoring

### View Logs
```bash
docker-compose logs -f qstash-consumer
```

### Check Health
```bash
curl http://localhost:8080/api/v1/webhooks/qstash/health
```

### Database Access
```bash
docker-compose exec postgres psql -U postgres -d optica-db
```

## Security

- All webhook endpoints require valid QStash signatures
- Invalid signatures return 401 Unauthorized
- Processing errors return 500 to trigger QStash retries
- JWT-based signature verification with key rotation support

## Message Flow

1. **Frontend** sends HTTP request to QStash API
2. **QStash** stores message and delivers to webhook endpoint
3. **QStash Consumer** verifies signature and processes message
4. **Database** stores the processed entity
5. **QStash** receives success/failure response and handles retries if needed

## Development

### Local Development
```bash
# Start PostgreSQL
docker-compose up -d postgres

# Run the application
cd qstash-consumer
mvn spring-boot:run
```

### Testing Webhooks
```bash
# Test health endpoint
./test-webhook.sh
```

## Troubleshooting

### Common Issues
1. **Invalid Signature Errors**: Verify QStash signing keys are correctly set
2. **Database Connection**: Ensure PostgreSQL is running and accessible
3. **Message Processing Failures**: Check application logs for specific errors

### QStash Console
Monitor message delivery status, retries, and errors in the [QStash Console](https://console.upstash.com/)

## Documentation

- [Frontend Integration Guide](FRONTEND_INTEGRATION_GUIDE.md) - Detailed guide for frontend developers
- [CLAUDE.md](CLAUDE.md) - Development commands and project structure

## Support

For issues related to:
- **QStash**: [Upstash Documentation](https://docs.upstash.com/qstash)
- **Consumer Service**: Check application logs and health endpoints
- **Database**: Verify migrations and data consistency
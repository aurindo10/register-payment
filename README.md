# Payment System - Microservices Architecture

This project implements a microservices-based payment system using Spring Boot, RabbitMQ, and PostgreSQL, designed to run on Kubernetes.

## Architecture Overview

The system consists of the following components:

- **Gateway Service**: Exposes REST endpoints to the internet and publishes messages to RabbitMQ
- **Consumer Service**: Consumes RabbitMQ messages and processes them (database operations)
- **Shared Module**: Contains common entities, DTOs, and event classes
- **RabbitMQ**: Message broker for asynchronous communication
- **PostgreSQL**: Database for persistent storage

## Module Structure

```
payment-system/
├── shared-module/          # Common entities, DTOs, and events
├── gateway-service/        # HTTP to RabbitMQ gateway
├── consumer-service/       # RabbitMQ consumer and database processor
├── k8s/                   # Kubernetes manifests
├── build-images.sh        # Docker image build script
└── pom.xml               # Parent POM
```

## API Endpoints

### Gateway Service (Port 8080)

- `POST /api/v1/gateway/companies` - Create company
- `POST /api/v1/gateway/accounts` - Create account
- `POST /api/v1/gateway/registers` - Create register
- `GET /api/v1/gateway/health` - Health check

### Consumer Service (Port 8081)

- `GET /actuator/health` - Health check

## Prerequisites

- Java 21
- Maven 3.6+
- Docker
- Kubernetes cluster
- kubectl configured

## Local Development

### 1. Build the Project

```bash
mvn clean install
```

### 2. Run Services Locally

#### Start PostgreSQL and RabbitMQ (using Docker Compose)

```bash
docker run -d --name postgres \
  -e POSTGRES_DB=optica-db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=optica123 \
  -p 5432:5432 postgres:15

docker run -d --name rabbitmq \
  -e RABBITMQ_DEFAULT_USER=guest \
  -e RABBITMQ_DEFAULT_PASS=guest \
  -p 5672:5672 -p 15672:15672 \
  rabbitmq:3.12-management
```

#### Start Gateway Service

```bash
cd gateway-service
mvn spring-boot:run
```

#### Start Consumer Service

```bash
cd consumer-service
mvn spring-boot:run
```

## Kubernetes Deployment

### 1. Build Docker Images

```bash
./build-images.sh
```

### 2. Deploy to Kubernetes

```bash
cd k8s
./deploy.sh
```

### 3. Access Services

Add to your `/etc/hosts`:

```
127.0.0.1 payment-gateway.local
127.0.0.1 rabbitmq-management.local
```

- Gateway API: http://payment-gateway.local
- RabbitMQ Management: http://rabbitmq-management.local

## Testing the API

### Create a Company

```bash
curl -X POST http://payment-gateway.local/api/v1/gateway/companies \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Company",
    "cnpj": "12345678901234",
    "externalCompanyId": "ext-123"
  }'
```

### Create an Account

```bash
curl -X POST http://payment-gateway.local/api/v1/gateway/accounts \
  -H "Content-Type: application/json" \
  -d '{
    "balance": 1000.00,
    "externalAccountId": "acc-123",
    "companyId": 1
  }'
```

### Create a Register

```bash
curl -X POST http://payment-gateway.local/api/v1/gateway/registers \
  -H "Content-Type: application/json" \
  -d '{
    "type": "CREDIT",
    "amount": 500.00,
    "accountId": 1,
    "userId": "user-123"
  }'
```

## Message Flow

1. **HTTP Request** → Gateway Service
2. **RabbitMQ Message** → Queue (company.queue, account.queue, register.queue)
3. **Consumer Service** → Processes message and saves to database

## RabbitMQ Configuration

- **Exchange**: `payment.exchange` (Topic)
- **Queues**:
  - `company.queue` (routing key: `company.created`)
  - `account.queue` (routing key: `account.created`)
  - `register.queue` (routing key: `register.created`)

## Database Schema

The system uses the existing database schema with tables:

- `company`
- `account`
- `register`
- `transaction`
- `conciliation`

## Monitoring

- Gateway Service: `/api/v1/gateway/health`
- Consumer Service: `/actuator/health`
- RabbitMQ Management: Port 15672

## Configuration

### Environment Variables

- `POSTGRES_HOST`: PostgreSQL host
- `POSTGRES_PORT`: PostgreSQL port
- `POSTGRES_DB`: Database name
- `POSTGRES_USER`: Database username
- `POSTGRES_PASSWORD`: Database password
- `RABBITMQ_HOST`: RabbitMQ host
- `RABBITMQ_PORT`: RabbitMQ port
- `RABBITMQ_USERNAME`: RabbitMQ username
- `RABBITMQ_PASSWORD`: RabbitMQ password

## Best Practices Implemented

- **Microservices Architecture**: Separation of concerns
- **Event-Driven Architecture**: Asynchronous processing
- **Shared Libraries**: Common code reuse
- **Configuration Management**: Environment-based config
- **Health Checks**: Monitoring and observability
- **Resource Limits**: Kubernetes resource management
- **Persistent Storage**: Database and message persistence
- **Load Balancing**: Multiple service replicas

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -n payment-system
```

### View Logs

```bash
kubectl logs -f deployment/gateway-service -n payment-system
kubectl logs -f deployment/consumer-service -n payment-system
```

### Check RabbitMQ Queues

Access RabbitMQ Management UI at http://rabbitmq-management.local

### Database Connection Issues

```bash
kubectl exec -it deployment/postgres -n payment-system -- psql -U postgres -d optica-db
```

# 🚀 Deployment Guide

## Quick Deploy to Fly.io

### Prerequisites

1. **Install flyctl:**

   ```bash
   curl -L https://fly.io/install.sh | sh
   ```

2. **Login to fly.io:**
   ```bash
   flyctl auth login
   ```

### Deploy with Self-Hosted RabbitMQ (Recommended)

```bash
# Deploy everything including RabbitMQ on Fly.io
./scripts/deploy.sh
```

✅ **Full functionality** - Deploys PostgreSQL, RabbitMQ, Publisher, and Consumer all on Fly.io

**What gets deployed:**

- **PostgreSQL**: Managed database service
- **RabbitMQ**: Self-hosted with management UI
- **Publisher**: API service
- **Consumer**: Background worker

## What Gets Deployed

### Infrastructure

- **PostgreSQL Database**: `register-payment-db` (managed service)
- **RabbitMQ**: `register-payment-rabbitmq.fly.dev` (self-hosted)
- **Publisher API**: `register-payment-publisher.fly.dev`
- **Consumer Worker**: `register-payment-consumer` (background process)

### Services

- **Publisher**: HTTP API that accepts transactions and publishes to RabbitMQ
- **Consumer**: Background worker that processes messages and saves to database

## Post-Deployment

### Verify Deployment

```bash
# Check all services health
curl https://register-payment-publisher.fly.dev/api/v1/health
curl https://register-payment-rabbitmq.fly.dev  # RabbitMQ Management UI

# Check logs
flyctl logs --app register-payment-publisher
flyctl logs --app register-payment-consumer
flyctl logs --app register-payment-rabbitmq

# Test transaction
curl -X POST https://register-payment-publisher.fly.dev/api/v1/transactions/ \
  -H "Content-Type: application/json" \
  -d '{"transaction_id":"TEST-001","value":"100.50","type":"in","external_company_id":"COMP-001"}'
```

### Access RabbitMQ Management UI

- **URL**: https://register-payment-rabbitmq.fly.dev
- **Username**: admin
- **Password**: !@#Solenge123!

### Scale Services

```bash
# Scale API based on traffic
flyctl scale count 3 --app register-payment-publisher

# Scale workers based on queue depth
flyctl scale count 2 --app register-payment-consumer

# Scale RabbitMQ (if needed - usually 1 instance is sufficient)
flyctl scale count 1 --app register-payment-rabbitmq
```

## Troubleshooting

### Consumer Not Processing Messages

1. Check RabbitMQ URL is correct
2. Verify database connection
3. Check consumer logs: `flyctl logs --app register-payment-consumer`

### Database Connection Issues

```bash
# Check database status
flyctl postgres list
flyctl postgres show register-payment-db

# Verify environment variables
flyctl ssh console --app register-payment-consumer -C "env | grep POSTGRES"
```

### Publisher API Issues

```bash
# Check publisher logs
flyctl logs --app register-payment-publisher

# Verify RabbitMQ connection
flyctl ssh console --app register-payment-publisher -C "env | grep RABBITMQ"
```

#!/bin/bash

# Test script for QStash webhooks
# This simulates QStash webhook calls for testing

BASE_URL="http://localhost:8080/api/v1/webhooks/qstash"

echo "Testing QStash webhook endpoints..."

# Test health endpoint
echo "1. Testing health endpoint..."
curl -X GET "$BASE_URL/health"
echo -e "\n"

# Test company creation (without signature - should fail)
echo "2. Testing company creation without signature (should fail with 401)..."
curl -X POST "$BASE_URL/company" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Company",
    "document": "12345678901234",
    "email": "test@company.com",
    "phone": "+1234567890"
  }' \
  -w "\nHTTP Status: %{http_code}\n"
echo -e "\n"

# Test account creation (without signature - should fail)
echo "3. Testing account creation without signature (should fail with 401)..."
curl -X POST "$BASE_URL/account" \
  -H "Content-Type: application/json" \
  -d '{
    "companyId": 1,
    "accountNumber": "ACC001",
    "accountType": "CHECKING",
    "balance": 1000.00
  }' \
  -w "\nHTTP Status: %{http_code}\n"
echo -e "\n"

# Test register creation (without signature - should fail)
echo "4. Testing register creation without signature (should fail with 401)..."
curl -X POST "$BASE_URL/register" \
  -H "Content-Type: application/json" \
  -d '{
    "accountId": 1,
    "description": "Test transaction",
    "amount": 100.00,
    "type": "CREDIT"
  }' \
  -w "\nHTTP Status: %{http_code}\n"
echo -e "\n"

echo "Note: To test with valid signatures, you need to:"
echo "1. Set up QStash and get your signing keys"
echo "2. Use QStash to send messages to your webhook endpoints"
echo "3. Or use the QStash CLI/SDK to generate valid signatures"
# Frontend Integration Guide for QStash Consumer

This guide explains how frontend applications can integrate with the QStash Consumer service to send payment-related data that will be processed asynchronously through QStash webhooks.

## Table of Contents
- [Overview](#overview)
- [Architecture Flow](#architecture-flow)
- [QStash Setup](#qstash-setup)
- [Frontend Implementation](#frontend-implementation)
- [Data Models](#data-models)
- [Error Handling](#error-handling)
- [Testing](#testing)
- [Best Practices](#best-practices)

## Overview

The QStash Consumer service receives webhook messages from QStash and processes them to create companies, accounts, and transaction registers in the database. Frontend applications send data to QStash, which then delivers it to our webhook endpoints.

### Why QStash?
- **Reliability**: Automatic retries with exponential backoff
- **Scalability**: Handles high-volume message processing
- **Durability**: Messages are persisted until successfully delivered
- **Monitoring**: Built-in observability and metrics

## Architecture Flow

```
Frontend → QStash API → QStash Consumer Webhooks → PostgreSQL Database
```

1. **Frontend** sends HTTP requests to QStash API endpoints
2. **QStash** receives messages and delivers them to configured webhook URLs
3. **QStash Consumer** receives webhooks, verifies signatures, and processes data
4. **Database** stores the processed entities (companies, accounts, registers)

## QStash Setup

### 1. Create QStash Account
1. Sign up at [Upstash Console](https://console.upstash.com/)
2. Create a new QStash project
3. Get your **QStash Token** and **Signing Keys**

### 2. Configure Webhook Endpoints
Set up the following webhook URLs in your QStash console:

```
https://your-domain.com/api/v1/webhooks/qstash/company
https://your-domain.com/api/v1/webhooks/qstash/account  
https://your-domain.com/api/v1/webhooks/qstash/register
```

### 3. Environment Variables
Ensure the QStash Consumer service has these environment variables:

```bash
QSTASH_CURRENT_SIGNING_KEY=your_current_signing_key_here
QSTASH_NEXT_SIGNING_KEY=your_next_signing_key_here  # Optional
```

## Frontend Implementation

### JavaScript/TypeScript Implementation

#### 1. Install QStash SDK

```bash
npm install @upstash/qstash
```

#### 2. Initialize QStash Client

```typescript
import { Client } from '@upstash/qstash';

const qstash = new Client({
  token: process.env.QSTASH_TOKEN!, // Your QStash token
});
```

#### 3. Send Messages to QStash

```typescript
// Company Creation
async function createCompany(companyData: CompanyRequest) {
  try {
    const response = await qstash.publishJSON({
      url: "https://your-domain.com/api/v1/webhooks/qstash/company",
      body: companyData,
      headers: {
        "Content-Type": "application/json",
      },
      // Optional: Add delay
      // delay: 10, // seconds
      // Optional: Add retries
      // retries: 3,
    });
    
    console.log('Company creation queued:', response.messageId);
    return response;
  } catch (error) {
    console.error('Failed to queue company creation:', error);
    throw error;
  }
}

// Account Creation
async function createAccount(accountData: AccountRequest) {
  try {
    const response = await qstash.publishJSON({
      url: "https://your-domain.com/api/v1/webhooks/qstash/account",
      body: accountData,
    });
    
    console.log('Account creation queued:', response.messageId);
    return response;
  } catch (error) {
    console.error('Failed to queue account creation:', error);
    throw error;
  }
}

// Register Creation
async function createRegister(registerData: RegisterRequest) {
  try {
    const response = await qstash.publishJSON({
      url: "https://your-domain.com/api/v1/webhooks/qstash/register",
      body: registerData,
    });
    
    console.log('Register creation queued:', response.messageId);
    return response;
  } catch (error) {
    console.error('Failed to queue register creation:', error);
    throw error;
  }
}
```

#### 4. React Component Example

```tsx
import React, { useState } from 'react';

interface CompanyFormData {
  name: string;
  cnpj: string;
  externalCompanyId: string;
}

const CompanyForm: React.FC = () => {
  const [formData, setFormData] = useState<CompanyFormData>({
    name: '',
    cnpj: '',
    externalCompanyId: ''
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [message, setMessage] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    setMessage('');

    try {
      await createCompany(formData);
      setMessage('Company creation queued successfully!');
      setFormData({ name: '', cnpj: '', externalCompanyId: '' });
    } catch (error) {
      setMessage('Failed to queue company creation. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <div>
        <label htmlFor="name">Company Name:</label>
        <input
          id="name"
          type="text"
          value={formData.name}
          onChange={(e) => setFormData({...formData, name: e.target.value})}
          required
        />
      </div>
      
      <div>
        <label htmlFor="cnpj">CNPJ:</label>
        <input
          id="cnpj"
          type="text"
          value={formData.cnpj}
          onChange={(e) => setFormData({...formData, cnpj: e.target.value})}
          required
        />
      </div>
      
      <div>
        <label htmlFor="externalId">External ID:</label>
        <input
          id="externalId"
          type="text"
          value={formData.externalCompanyId}
          onChange={(e) => setFormData({...formData, externalCompanyId: e.target.value})}
          required
        />
      </div>
      
      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Creating...' : 'Create Company'}
      </button>
      
      {message && <p>{message}</p>}
    </form>
  );
};

export default CompanyForm;
```

### Python Implementation

#### 1. Install QStash Python SDK

```bash
pip install upstash-qstash
```

#### 2. Send Messages

```python
from qstash import QStash

# Initialize client
qstash = QStash(token="your_qstash_token")

def create_company(company_data):
    """Send company creation message to QStash"""
    try:
        response = qstash.message.publish_json(
            url="https://your-domain.com/api/v1/webhooks/qstash/company",
            body=company_data,
            headers={"Content-Type": "application/json"}
        )
        print(f"Company creation queued: {response['messageId']}")
        return response
    except Exception as e:
        print(f"Failed to queue company creation: {e}")
        raise

def create_account(account_data):
    """Send account creation message to QStash"""
    try:
        response = qstash.message.publish_json(
            url="https://your-domain.com/api/v1/webhooks/qstash/account",
            body=account_data
        )
        print(f"Account creation queued: {response['messageId']}")
        return response
    except Exception as e:
        print(f"Failed to queue account creation: {e}")
        raise

# Example usage
company_data = {
    "name": "Example Corp",
    "cnpj": "12345678901234",
    "externalCompanyId": "EXT-001"
}

create_company(company_data)
```

### cURL Examples

```bash
# Create Company via QStash
curl -X POST "https://qstash.upstash.io/v2/publish/https://your-domain.com/api/v1/webhooks/qstash/company" \
  -H "Authorization: Bearer YOUR_QSTASH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Example Company",
    "cnpj": "12345678901234", 
    "externalCompanyId": "EXT-001"
  }'

# Create Account via QStash
curl -X POST "https://qstash.upstash.io/v2/publish/https://your-domain.com/api/v1/webhooks/qstash/account" \
  -H "Authorization: Bearer YOUR_QSTASH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "companyId": 1,
    "accountNumber": "ACC-001",
    "accountType": "CHECKING",
    "balance": 1000.00
  }'

# Create Register via QStash  
curl -X POST "https://qstash.upstash.io/v2/publish/https://your-domain.com/api/v1/webhooks/qstash/register" \
  -H "Authorization: Bearer YOUR_QSTASH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "accountId": 1,
    "description": "Initial deposit",
    "amount": 1000.00,
    "type": "CREDIT"
  }'
```

## Data Models

### CompanyRequest
```typescript
interface CompanyRequest {
  name: string;           // Company name
  cnpj: string;          // Brazilian tax ID (14 digits)
  externalCompanyId: string; // Your internal company ID
}
```

### AccountRequest
```typescript
interface AccountRequest {
  companyId: number;      // ID of the company (must exist)
  accountNumber: string;  // Account identifier
  accountType: string;    // Account type (e.g., "CHECKING", "SAVINGS")
  balance: number;        // Initial balance
}
```

### RegisterRequest
```typescript
interface RegisterRequest {
  accountId: number;      // ID of the account (must exist)
  description: string;    // Transaction description
  amount: number;         // Transaction amount
  type: string;          // Transaction type (e.g., "CREDIT", "DEBIT")
}
```

## Error Handling

### QStash Error Responses
```typescript
interface QStashError {
  error: string;
  status: number; 
  message?: string;
}

// Handle QStash errors
async function handleQStashOperation<T>(operation: () => Promise<T>): Promise<T> {
  try {
    return await operation();
  } catch (error: any) {
    if (error.status === 401) {
      throw new Error('Invalid QStash token');
    } else if (error.status === 429) {
      throw new Error('Rate limit exceeded. Please try again later.');
    } else if (error.status >= 500) {
      throw new Error('QStash service temporarily unavailable');
    } else {
      throw new Error(`QStash error: ${error.message || 'Unknown error'}`);
    }
  }
}
```

### Consumer Service Error Responses
The webhook endpoints return:
- **200 OK**: Message processed successfully
- **401 Unauthorized**: Invalid QStash signature
- **500 Internal Server Error**: Processing failed (triggers QStash retry)

### Retry Strategy
QStash automatically retries failed webhook deliveries with exponential backoff:
- Initial retry: 1 second
- Max retries: 3 attempts by default
- Max delay: 900 seconds

## Testing

### 1. Test QStash Integration
```typescript
// Test function
async function testQStashIntegration() {
  const testCompany = {
    name: "Test Company",
    cnpj: "12345678901234",
    externalCompanyId: "TEST-001"
  };

  try {
    const response = await createCompany(testCompany);
    console.log('Test successful:', response);
  } catch (error) {
    console.error('Test failed:', error);
  }
}
```

### 2. Monitor Message Delivery
Check the QStash console to monitor:
- Message status (delivered, failed, retrying)
- Delivery timestamps
- Error logs
- Retry attempts

### 3. Verify Data in Database
After sending test messages, verify the data was properly stored:

```sql
-- Check companies
SELECT * FROM company WHERE name = 'Test Company';

-- Check accounts  
SELECT * FROM account WHERE company_id = 1;

-- Check registers
SELECT * FROM register WHERE account_id = 1;
```

## Best Practices

### 1. **Environment Management**
```typescript
// Use environment-specific configurations
const QSTASH_CONFIG = {
  development: {
    baseUrl: 'https://dev-your-domain.com',
    token: process.env.QSTASH_DEV_TOKEN
  },
  production: {
    baseUrl: 'https://your-domain.com', 
    token: process.env.QSTASH_PROD_TOKEN
  }
};
```

### 2. **Rate Limiting**
Implement client-side rate limiting to avoid hitting QStash limits:

```typescript
import pLimit from 'p-limit';

// Limit concurrent requests
const limit = pLimit(10); // Max 10 concurrent requests

const promises = companies.map(company => 
  limit(() => createCompany(company))
);

await Promise.all(promises);
```

### 3. **Idempotency**
Use unique `externalCompanyId` and similar fields to prevent duplicates:

```typescript
const companyData = {
  name: "Example Corp",
  cnpj: "12345678901234",
  externalCompanyId: `COMP-${Date.now()}-${Math.random()}` // Unique ID
};
```

### 4. **Monitoring and Logging**
```typescript
// Log all QStash operations
async function createCompanyWithLogging(companyData: CompanyRequest) {
  const startTime = Date.now();
  
  try {
    console.log('Sending company creation to QStash:', companyData);
    const response = await createCompany(companyData);
    
    console.log(`Company queued successfully in ${Date.now() - startTime}ms:`, {
      messageId: response.messageId,
      company: companyData.name
    });
    
    return response;
  } catch (error) {
    console.error(`Company creation failed after ${Date.now() - startTime}ms:`, {
      error: error.message,
      company: companyData.name
    });
    throw error;
  }
}
```

### 5. **User Feedback**
```typescript
// Provide clear user feedback
const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle');

const handleSubmit = async (data: CompanyRequest) => {
  setStatus('loading');
  
  try {
    await createCompany(data);
    setStatus('success');
    // Show success message: "Company creation has been queued and will be processed shortly"
  } catch (error) {
    setStatus('error');
    // Show error message: "Failed to queue company creation. Please try again."
  }
};
```

## Support

For issues related to:
- **QStash**: Check [Upstash Documentation](https://docs.upstash.com/qstash)
- **Consumer Service**: Check service logs and health endpoint
- **Database**: Verify data consistency and migrations

Remember: Messages sent to QStash are processed asynchronously. Use the QStash console to monitor delivery status and debug any issues.
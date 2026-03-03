# Account REST API - Functional Documentation

## Table of Contents
1. [Overview](#overview)
2. [API Endpoints](#api-endpoints)
3. [Authentication](#authentication)
4. [Request/Response Format](#requestresponse-format)
5. [CRUD Operations](#crud-operations)
6. [Error Handling](#error-handling)
7. [Status Codes](#status-codes)
8. [Rate Limiting](#rate-limiting)
9. [Examples](#examples)
10. [Implementation Notes](#implementation-notes)

---

## Overview

The Account REST API provides a complete set of operations for managing Salesforce Account records. It enables external systems to create, retrieve, update, and delete account information with robust error handling and validation.

**Base URL:** `https://{instance}.salesforce.com/services/apexrest/accounts`

**API Version:** v1.0

**Content-Type:** `application/json`

---

## API Endpoints

| Method | Endpoint | Operation | Description |
|--------|----------|-----------|-------------|
| POST | `/accounts` | CREATE | Create a new account |
| GET | `/accounts/{id}` | RETRIEVE | Get a specific account by ID |
| GET | `/accounts` | LIST | List all accounts with optional filtering |
| PUT | `/accounts/{id}` | UPDATE | Update an existing account |
| PATCH | `/accounts/{id}` | PARTIAL UPDATE | Partially update an account |
| DELETE | `/accounts/{id}` | DELETE | Delete an account |

---

## Authentication

All API requests must include proper authentication headers.

### Salesforce OAuth 2.0
```
Authorization: Bearer {access_token}
```

### Session Token Authentication
```
Authorization: SFDCSessionToken {session_token}
```

### Basic Authentication (for internal testing only)
```
Authorization: Basic {base64_encoded_credentials}
```

---

## Request/Response Format

### Common Headers
```
Content-Type: application/json
Accept: application/json
Authorization: Bearer {access_token}
X-Request-ID: {unique_request_identifier}  (Optional - for tracking)
```

### Request Body Structure
All request bodies use JSON format with proper UTF-8 encoding.

### Response Structure
```json
{
  "success": true|false,
  "data": {},
  "message": "Optional informational message",
  "errors": [],
  "timestamp": "2026-02-27T10:30:00Z",
  "requestId": "unique_request_id"
}
```

---

## CRUD Operations

### 1. CREATE - New Account

**Endpoint:** `POST /accounts`

**Description:** Create a new account record in Salesforce.

**Required Fields:**
- `name` (string, max 255 chars): Account name
- `billingCountry` (string, max 50 chars): Billing country

**Optional Fields:**
```json
{
  "name": "Acme Corporation",
  "description": "Account description",
  "phone": "+1-555-0100",
  "website": "https://acme.com",
  "industry": "Technology",
  "annualRevenue": 5000000,
  "numberOfEmployees": 150,
  "billingStreet": "100 Main Street",
  "billingCity": "San Francisco",
  "billingStateCode": "CA",
  "billingPostalCode": "94105",
  "billingCountry": "United States",
  "shippingStreet": "200 Market Street",
  "shippingCity": "San Francisco",
  "shippingStateCode": "CA",
  "shippingPostalCode": "94102",
  "shippingCountry": "United States",
  "customField__c": "custom value"
}
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "id": "0015g000008ZP7AAAW",
    "name": "Acme Corporation",
    "createdDate": "2026-02-27T10:30:00Z",
    "lastModifiedDate": "2026-02-27T10:30:00Z"
  },
  "message": "Account created successfully",
  "timestamp": "2026-02-27T10:30:00Z",
  "requestId": "req_1234567890"
}
```

**Error Response (400):**
```json
{
  "success": false,
  "errors": [
    {
      "code": "INVALID_FIELD",
      "message": "Field 'name' is required",
      "field": "name",
      "details": "Account name cannot be null or empty"
    }
  ],
  "timestamp": "2026-02-27T10:30:00Z",
  "requestId": "req_1234567890"
}
```

---

### 2. RETRIEVE - Fetch Account

**Endpoint:** `GET /accounts/{id}`

**Description:** Retrieve a single account by ID with all available fields.

**Parameters:**
- `id` (path parameter, required): Salesforce Account ID (18 characters)
- `fields` (query parameter, optional): Comma-separated list of fields to return
  - Example: `?fields=name,phone,website,industry`

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "0015g000008ZP7AAAW",
    "name": "Acme Corporation",
    "description": "Technology company",
    "phone": "+1-555-0100",
    "website": "https://acme.com",
    "industry": "Technology",
    "annualRevenue": 5000000,
    "numberOfEmployees": 150,
    "billingStreet": "100 Main Street",
    "billingCity": "San Francisco",
    "billingStateCode": "CA",
    "billingPostalCode": "94105",
    "billingCountry": "United States",
    "shippingStreet": "200 Market Street",
    "shippingCity": "San Francisco",
    "shippingStateCode": "CA",
    "shippingPostalCode": "94102",
    "shippingCountry": "United States",
    "createdDate": "2026-02-27T10:30:00Z",
    "lastModifiedDate": "2026-02-27T10:30:00Z",
    "createdById": "0051f000002bw84AAA"
  },
  "timestamp": "2026-02-27T10:30:00Z",
  "requestId": "req_1234567891"
}
```

**Error Response (404):**
```json
{
  "success": false,
  "errors": [
    {
      "code": "RESOURCE_NOT_FOUND",
      "message": "Account with ID '0015g000008ZP7AAAW' not found",
      "field": "id"
    }
  ],
  "timestamp": "2026-02-27T10:30:00Z",
  "requestId": "req_1234567891"
}
```

---

### 3. LIST - Fetch Multiple Accounts

**Endpoint:** `GET /accounts`

**Description:** Retrieve multiple accounts with optional filtering, sorting, and pagination.

**Query Parameters:**
```
- limit (integer, max 10000): Maximum records to return (default: 100)
- offset (integer): Records to skip for pagination (default: 0)
- sortBy (string): Field to sort by (default: lastModifiedDate)
- sortOrder (string): ASC or DESC (default: DESC)
- search (string): Search term (searches name and website)
- industry (string): Filter by industry
- createdAfter (ISO8601 datetime): Filter records created after this date
- createdBefore (ISO8601 datetime): Filter records created before this date
- fields (string): Comma-separated fields to return
```

**Example Request:**
```
GET /accounts?limit=50&offset=0&industry=Technology&sortBy=name&sortOrder=ASC&fields=id,name,phone,website
```

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "0015g000008ZP7AAAW",
      "name": "Acme Corporation",
      "phone": "+1-555-0100",
      "website": "https://acme.com"
    },
    {
      "id": "0015g000008ZP7AABB",
      "name": "GlobalTech Inc",
      "phone": "+1-555-0101",
      "website": "https://globaltech.com"
    }
  ],
  "pagination": {
    "totalRecords": 250,
    "returnedRecords": 50,
    "offset": 0,
    "limit": 50,
    "hasMore": true
  },
  "timestamp": "2026-02-27T10:30:00Z",
  "requestId": "req_1234567892"
}
```

**Error Response (400):**
```json
{
  "success": false,
  "errors": [
    {
      "code": "INVALID_PARAMETER",
      "message": "Invalid limit parameter",
      "field": "limit",
      "details": "Limit must be between 1 and 10000"
    }
  ],
  "timestamp": "2026-02-27T10:30:00Z",
  "requestId": "req_1234567892"
}
```

---

### 4. UPDATE - Full Update

**Endpoint:** `PUT /accounts/{id}`

**Description:** Update all fields of an existing account (full replacement).

**Parameters:**
- `id` (path parameter, required): Salesforce Account ID

**Request Body:**
All account fields can be updated. Omitted fields are not affected.

```json
{
  "name": "Acme Corporation Updated",
  "description": "Updated description",
  "phone": "+1-555-0102",
  "website": "https://newacme.com",
  "industry": "Software",
  "annualRevenue": 6000000,
  "numberOfEmployees": 200,
  "billingStreet": "150 Market Street",
  "billingCity": "San Francisco",
  "billingStateCode": "CA",
  "billingPostalCode": "94103",
  "billingCountry": "United States"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "0015g000008ZP7AAAW",
    "name": "Acme Corporation Updated",
    "lastModifiedDate": "2026-02-27T11:45:00Z"
  },
  "message": "Account updated successfully",
  "timestamp": "2026-02-27T11:45:00Z",
  "requestId": "req_1234567893"
}
```

**Error Response (409):**
```json
{
  "success": false,
  "errors": [
    {
      "code": "CONCURRENT_MODIFICATION",
      "message": "Record has been updated by another user",
      "field": "id",
      "details": "Please fetch the latest version and retry"
    }
  ],
  "timestamp": "2026-02-27T11:45:00Z",
  "requestId": "req_1234567893"
}
```

---

### 5. PATCH - Partial Update

**Endpoint:** `PATCH /accounts/{id}`

**Description:** Update specific fields of an existing account.

**Parameters:**
- `id` (path parameter, required): Salesforce Account ID

**Request Body:**
Only include fields that need updating.

```json
{
  "phone": "+1-555-0103",
  "website": "https://updated.com"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "0015g000008ZP7AAAW",
    "phone": "+1-555-0103",
    "website": "https://updated.com",
    "lastModifiedDate": "2026-02-27T12:00:00Z"
  },
  "message": "Account updated successfully",
  "timestamp": "2026-02-27T12:00:00Z",
  "requestId": "req_1234567894"
}
```

---

### 6. DELETE - Remove Account

**Endpoint:** `DELETE /accounts/{id}`

**Description:** Permanently delete an account record.

**Parameters:**
- `id` (path parameter, required): Salesforce Account ID

**Query Parameters:**
- `hard_delete` (boolean, optional): If true, performs hard delete (default: false for soft delete)

**Success Response (204):**
No content body. The response indicates successful deletion.

```
HTTP/1.1 204 No Content
```

**Or with response body (200):**
```json
{
  "success": true,
  "message": "Account deleted successfully",
  "timestamp": "2026-02-27T12:15:00Z",
  "requestId": "req_1234567895"
}
```

**Error Response (404):**
```json
{
  "success": false,
  "errors": [
    {
      "code": "RESOURCE_NOT_FOUND",
      "message": "Account with ID '0015g000008ZP7AAAW' not found"
    }
  ],
  "timestamp": "2026-02-27T12:15:00Z",
  "requestId": "req_1234567895"
}
```

**Error Response (403):**
```json
{
  "success": false,
  "errors": [
    {
      "code": "PERMISSION_DENIED",
      "message": "You do not have permission to delete this record",
      "details": "Required permission: delete on Account"
    }
  ],
  "timestamp": "2026-02-27T12:15:00Z",
  "requestId": "req_1234567895"
}
```

---

## Error Handling

### Error Response Structure
```json
{
  "success": false,
  "errors": [
    {
      "code": "ERROR_CODE",
      "message": "Human-readable error message",
      "field": "fieldName (optional)",
      "details": "Additional context or suggestion"
    }
  ],
  "timestamp": "ISO8601 timestamp",
  "requestId": "unique request ID"
}
```

### Error Categories

#### 1. Validation Errors (400)
Occur when request data is invalid or missing required fields.

**Common Codes:**
- `MISSING_REQUIRED_FIELD`: Required field is missing
- `INVALID_FIELD_VALUE`: Field value doesn't meet constraints
- `INVALID_FIELD_TYPE`: Field type mismatch
- `INVALID_FIELD_FORMAT`: Field format is invalid
- `FIELD_TOO_LONG`: Field exceeds maximum length

**Example:**
```json
{
  "success": false,
  "errors": [
    {
      "code": "MISSING_REQUIRED_FIELD",
      "message": "Field 'billingCountry' is required",
      "field": "billingCountry"
    },
    {
      "code": "INVALID_FIELD_VALUE",
      "message": "Field 'annualRevenue' must be a positive number",
      "field": "annualRevenue"
    }
  ]
}
```

#### 2. Authentication Errors (401)
Occur when authentication fails or credentials are invalid.

**Common Codes:**
- `AUTHENTICATION_FAILED`: Invalid credentials
- `INVALID_TOKEN`: OAuth token is invalid or expired
- `TOKEN_EXPIRED`: Token has expired
- `MISSING_AUTHORIZATION`: Authorization header is missing

**Example:**
```json
{
  "success": false,
  "errors": [
    {
      "code": "INVALID_TOKEN",
      "message": "Access token invalid or expired",
      "details": "Please obtain a new token and retry"
    }
  ]
}
```

#### 3. Authorization Errors (403)
Occur when user lacks required permissions.

**Common Codes:**
- `PERMISSION_DENIED`: User lacks required permissions
- `FIELD_PERMISSION_DENIED`: User cannot access specific field
- `INVALID_ORGANIZATION`: Request from unauthorized organization

**Example:**
```json
{
  "success": false,
  "errors": [
    {
      "code": "PERMISSION_DENIED",
      "message": "You do not have permission to create accounts",
      "details": "Contact your administrator to request access"
    }
  ]
}
```

#### 4. Resource Not Found (404)
Occurs when requested resource doesn't exist.

**Common Codes:**
- `RESOURCE_NOT_FOUND`: Record not found
- `ENDPOINT_NOT_FOUND`: API endpoint doesn't exist

**Example:**
```json
{
  "success": false,
  "errors": [
    {
      "code": "RESOURCE_NOT_FOUND",
      "message": "Account with ID 'invalid_id' not found"
    }
  ]
}
```

#### 5. Conflict Errors (409)
Occur when operation conflicts with current state.

**Common Codes:**
- `CONCURRENT_MODIFICATION`: Record modified by another user
- `DUPLICATE_RECORD`: Duplicate record already exists
- `INVALID_STATE`: Record is in invalid state for operation

**Example:**
```json
{
  "success": false,
  "errors": [
    {
      "code": "CONCURRENT_MODIFICATION",
      "message": "Record has been modified by another user",
      "details": "Fetch the latest version and retry your changes"
    }
  ]
}
```

#### 6. Rate Limit Errors (429)
Occur when API rate limits are exceeded.

**Common Codes:**
- `RATE_LIMIT_EXCEEDED`: Too many requests

**Example:**
```json
{
  "success": false,
  "errors": [
    {
      "code": "RATE_LIMIT_EXCEEDED",
      "message": "Too many requests. Rate limit: 1000 per hour",
      "details": "Retry after 3600 seconds"
    }
  ],
  "retryAfter": 3600
}
```

#### 7. Server Errors (500)
Occur due to unexpected server issues.

**Common Codes:**
- `INTERNAL_SERVER_ERROR`: Unexpected server error
- `SERVICE_UNAVAILABLE`: Service temporarily unavailable
- `DATABASE_ERROR`: Database operation failed

**Example:**
```json
{
  "success": false,
  "errors": [
    {
      "code": "INTERNAL_SERVER_ERROR",
      "message": "An unexpected error occurred",
      "details": "Please contact support with request ID: req_1234567890"
    }
  ]
}
```

### Error Handling Best Practices

1. **Always check the `success` field** to determine operation success
2. **Use error codes** for programmatic handling (not just messages)
3. **Implement retry logic** for 429 and 5xx errors
4. **Log the `requestId`** for debugging and support
5. **Handle multiple errors** - the errors array can contain multiple issues
6. **Check the `field` property** to identify which field caused the error
7. **Use `details`** for additional context and suggested actions

---

## Status Codes

| Code | Status | Meaning | Retry | Incident |
|------|--------|---------|-------|----------|
| 200 | OK | Successful GET, PUT, or PATCH | No | No |
| 201 | Created | Resource successfully created | No | No |
| 204 | No Content | Successful DELETE | No | No |
| 400 | Bad Request | Invalid request data | No | No |
| 401 | Unauthorized | Authentication failed | No | No |
| 403 | Forbidden | Insufficient permissions | No | No |
| 404 | Not Found | Resource doesn't exist | No | No |
| 409 | Conflict | Concurrent modification or duplicate | Yes | No |
| 422 | Unprocessable Entity | Validation failed | No | No |
| 429 | Too Many Requests | Rate limit exceeded | Yes | No |
| 500 | Internal Server Error | Server error | Yes | Yes |
| 502 | Bad Gateway | Gateway error | Yes | Yes |
| 503 | Service Unavailable | Service unavailable | Yes | Yes |

---

## Rate Limiting

API requests are subject to the following rate limits:

### Limits by Organization Type

| Organization Type | Requests per Hour | Concurrent Connections |
|-------------------|-------------------|----------------------|
| Production | 10,000 | 100 |
| Sandbox | 5,000 | 50 |
| Developer | 1,000 | 10 |

### Rate Limit Headers

Every response includes rate limit information:

```
X-RateLimit-Limit: 10000
X-RateLimit-Remaining: 9876
X-RateLimit-Reset: 1645865400
X-RateLimit-RetryAfter: 3600
```

### Handling Rate Limits

When you receive a 429 response:

1. Read the `X-RateLimit-RetryAfter` header
2. Wait the specified number of seconds
3. Retry the request
4. Implement exponential backoff for multiple retries

---

## Examples

### Example 1: Create Account (cURL)

```bash
curl -X POST https://instance.salesforce.com/services/apexrest/accounts \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Tech Solutions Inc",
    "phone": "+1-555-0100",
    "website": "https://techsolutions.com",
    "industry": "Technology",
    "billingCountry": "United States",
    "annualRevenue": 3000000
  }'
```

### Example 2: Retrieve Account (JavaScript/Fetch)

```javascript
const accountId = '0015g000008ZP7AAAW';

fetch(`https://instance.salesforce.com/services/apexrest/accounts/${accountId}`, {
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${accessToken}`,
    'Content-Type': 'application/json'
  }
})
  .then(response => {
    if (!response.ok) {
      throw new Error(`API error: ${response.status}`);
    }
    return response.json();
  })
  .then(data => {
    if (data.success) {
      console.log('Account:', data.data);
    } else {
      console.error('Errors:', data.errors);
    }
  })
  .catch(error => console.error('Request failed:', error));
```

### Example 3: List Accounts with Filtering (Python)

```python
import requests

url = 'https://instance.salesforce.com/services/apexrest/accounts'
headers = {
    'Authorization': f'Bearer {access_token}',
    'Content-Type': 'application/json'
}
params = {
    'industry': 'Technology',
    'limit': 50,
    'sortBy': 'name',
    'sortOrder': 'ASC'
}

response = requests.get(url, headers=headers, params=params)
data = response.json()

if data['success']:
    for account in data['data']:
        print(f"{account['name']} - {account['phone']}")
    print(f"Total: {data['pagination']['totalRecords']}")
else:
    for error in data['errors']:
        print(f"Error: {error['message']}")
```

### Example 4: Update Account (Node.js/Axios)

```javascript
const axios = require('axios');

const accountId = '0015g000008ZP7AAAW';
const updateData = {
  phone: '+1-555-0105',
  website: 'https://newwebsite.com',
  annualRevenue: 7500000
};

axios.patch(
  `https://instance.salesforce.com/services/apexrest/accounts/${accountId}`,
  updateData,
  {
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json'
    }
  }
)
  .then(response => {
    if (response.data.success) {
      console.log('Update successful:', response.data.data);
    } else {
      console.error('Update failed:', response.data.errors);
    }
  })
  .catch(error => console.error('Request error:', error.message));
```

### Example 5: Delete Account (cURL)

```bash
curl -X DELETE https://instance.salesforce.com/services/apexrest/accounts/0015g000008ZP7AAAW \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json"
```

### Example 6: Handling Errors and Retries (JavaScript)

```javascript
async function apiCallWithRetry(url, options, retries = 3) {
  for (let i = 0; i < retries; i++) {
    try {
      const response = await fetch(url, options);
      const data = await response.json();
      
      // Handle HTTP errors
      if (!response.ok) {
        if (response.status === 429) {
          const retryAfter = response.headers.get('X-RateLimit-RetryAfter');
          console.log(`Rate limited. Retrying after ${retryAfter}s`);
          await sleep(retryAfter * 1000);
          continue;
        } else if (response.status >= 500) {
          // Server error - retry
          console.log(`Server error ${response.status}. Retrying...`);
          await sleep(Math.pow(2, i) * 1000); // Exponential backoff
          continue;
        } else {
          throw new Error(`API Error: ${data.errors[0]?.message}`);
        }
      }
      
      // Success
      if (data.success) {
        return data;
      } else {
        throw new Error(`API Error: ${data.errors[0]?.message}`);
      }
    } catch (error) {
      if (i === retries - 1) throw error;
      await sleep(1000 * (i + 1));
    }
  }
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
```

---

## Implementation Notes

### Salesforce Apex Implementation

The API endpoints should be implemented as Salesforce Apex REST classes using the `@RestResource` annotation:

```apex
@RestResource(urlMapping='/accounts/*')
global class AccountRestService {
  
  @HttpPost
  global static void handleCreate(String name, String billingCountry) {
    // POST /accounts - Create new account
  }
  
  @HttpGet
  global static void handleRetrieve() {
    // GET /accounts or GET /accounts/{id} - Retrieve account(s)
  }
  
  @HttpPut
  global static void handleUpdate() {
    // PUT /accounts/{id} - Update account
  }
  
  @HttpPatch
  global static void handlePatch() {
    // PATCH /accounts/{id} - Partial update
  }
  
  @HttpDelete
  global static void handleDelete() {
    // DELETE /accounts/{id} - Delete account
  }
}
```

### Key Implementation Guidelines

1. **Validation**: Validate all input data before database operations
2. **Permission Checks**: Verify user has required CRUD permissions
3. **Transaction Safety**: Use try-catch blocks and rollback on errors
4. **Audit Logging**: Log all CRUD operations for compliance
5. **Field Masking**: Mask sensitive data in responses based on user permissions
6. **Query Optimization**: Use indexed queries and limit record processing
7. **Error Responses**: Always return consistent error format
8. **Request Tracking**: Generate and track unique request IDs
9. **Documentation**: Auto-generate Swagger/OpenAPI documentation
10. **Testing**: Implement unit tests and integration tests for all endpoints

### API Security Considerations

1. **HTTPS Only**: All API calls must use HTTPS
2. **OAuth Token Validation**: Validate token expiration and scope
3. **Input Sanitization**: Sanitize all user inputs to prevent injection
4. **CORS**: Implement CORS policies for browser-based clients
5. **Rate Limiting**: Enforce rate limits to prevent abuse
6. **API Key Management**: Rotate API keys regularly
7. **Audit Trail**: Maintain complete audit logs of all API access
8. **Data Encryption**: Encrypt sensitive data in transit and at rest

---

## Appendix: Common Field Validation Rules

| Field | Type | Length | Required | Format |
|-------|------|--------|----------|--------|
| id | String | 18 | Read-only | Salesforce ID format |
| name | String | 255 | Yes | Text |
| phone | String | 40 | No | Phone format |
| website | String | 255 | No | URL format |
| industry | String | 40 | No | Picklist value |
| annualRevenue | Number | - | No | Positive number |
| numberOfEmployees | Number | - | No | Positive integer |
| billingCountry | String | 50 | Yes | Valid country |
| shippingCountry | String | 50 | No | Valid country |
| description | String | 32000 | No | Text (long) |
| createdDate | DateTime | - | Read-only | ISO 8601 |
| lastModifiedDate | DateTime | - | Read-only | ISO 8601 |

---

**Document Version:** 1.0  
**Last Updated:** February 27, 2026  
**Status:** Ready for Implementation

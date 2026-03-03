# Account REST API - Quick Reference Guide

## API Base URL
```
https://{instance}.salesforce.com/services/apexrest/accounts
```

## Endpoints Summary

### Create Account
```
POST /accounts
Content-Type: application/json
Authorization: Bearer {token}

{
  "name": "Company Name",
  "billingCountry": "United States",
  "phone": "+1-555-0100",
  "website": "https://example.com"
}

Response: 201 Created
```

### Get Single Account
```
GET /accounts/{id}
Authorization: Bearer {token}

Response: 200 OK
```

### List Accounts
```
GET /accounts?limit=50&offset=0&sortBy=name&sortOrder=ASC
Authorization: Bearer {token}

Response: 200 OK
```

### Update Account
```
PUT /accounts/{id}
Content-Type: application/json
Authorization: Bearer {token}

{
  "phone": "+1-555-0101",
  "website": "https://newsite.com"
}

Response: 200 OK
```

### Partial Update
```
PATCH /accounts/{id}
Content-Type: application/json
Authorization: Bearer {token}

{
  "phone": "+1-555-0102"
}

Response: 200 OK
```

### Delete Account
```
DELETE /accounts/{id}
Authorization: Bearer {token}

Response: 204 No Content
```

---

## Common Error Codes

| Code | HTTP Status | Meaning |
|------|-------------|---------|
| INVALID_FIELD | 400 | Invalid field value |
| MISSING_REQUIRED_FIELD | 400 | Required field missing |
| INVALID_FIELD_FORMAT | 400 | Field format invalid |
| FIELD_TOO_LONG | 400 | Field exceeds max length |
| RESOURCE_NOT_FOUND | 404 | Record not found |
| PERMISSION_DENIED | 403 | Insufficient permissions |
| DUPLICATE_RECORD | 409 | Record already exists |
| CONCURRENT_MODIFICATION | 409 | Modified by another user |
| INTERNAL_SERVER_ERROR | 500 | Server error |
| RATE_LIMIT_EXCEEDED | 429 | Too many requests |

---

## Field Reference

### Required Fields
- `name` - Account name (max 255 chars)
- `billingCountry` - Billing country (max 50 chars)

### Optional Fields
- `phone` - Phone number (max 40 chars)
- `website` - Website URL (max 255 chars)
- `industry` - Industry picklist value
- `annualRevenue` - Annual revenue (decimal)
- `numberOfEmployees` - Number of employees (integer)
- `description` - Description (max 32000 chars)
- `billingStreet` - Billing street address
- `billingCity` - Billing city
- `billingStateCode` - Billing state
- `billingPostalCode` - Billing postal code
- `shippingStreet` - Shipping street address
- `shippingCity` - Shipping city
- `shippingStateCode` - Shipping state
- `shippingPostalCode` - Shipping postal code
- `shippingCountry` - Shipping country

### Read-Only Fields
- `id` - Record ID (18 chars)
- `createdDate` - Creation timestamp
- `lastModifiedDate` - Last modified timestamp
- `createdById` - Creator user ID

---

## Query Parameters

### List Accounts
- `limit` - Results per page (default: 100, max: 10000)
- `offset` - Records to skip (default: 0)
- `sortBy` - Field to sort by (default: lastModifiedDate)
- `sortOrder` - ASC or DESC (default: DESC)
- `search` - Search in name and website
- `industry` - Filter by industry
- `createdAfter` - Created after date (ISO 8601)
- `createdBefore` - Created before date (ISO 8601)
- `fields` - Comma-separated fields to return

### Example List Request
```
GET /accounts?limit=50&offset=0&industry=Technology&sortBy=name&sortOrder=ASC
```

---

## Response Structure

### Success Response
```json
{
  "success": true,
  "data": { /* response data */ },
  "message": "Operation description",
  "errors": [],
  "timestamp": "2026-02-27T10:30:00Z",
  "requestId": "req_1234567890"
}
```

### Error Response
```json
{
  "success": false,
  "data": null,
  "message": null,
  "errors": [
    {
      "code": "ERROR_CODE",
      "message": "Error message",
      "field": "fieldName",
      "details": "Additional context"
    }
  ],
  "timestamp": "2026-02-27T10:30:00Z",
  "requestId": "req_1234567890"
}
```

---

## HTTP Status Codes

| Status | Meaning | Retry |
|--------|---------|-------|
| 200 | OK - Request successful | No |
| 201 | Created - Resource created | No |
| 204 | No Content - Deleted | No |
| 400 | Bad Request - Invalid data | No |
| 401 | Unauthorized - Auth failed | No |
| 403 | Forbidden - No permission | No |
| 404 | Not Found - Resource missing | No |
| 409 | Conflict - Concurrent mod | Yes |
| 429 | Rate Limited | Yes |
| 500 | Server Error | Yes |

---

## Authentication

### OAuth 2.0 Bearer Token
```
Authorization: Bearer access_token_string
```

### Session Token
```
Authorization: SFDCSessionToken session_token_string
```

---

## Rate Limiting

### Limits by Org
- Production: 10,000 requests/hour
- Sandbox: 5,000 requests/hour
- Developer: 1,000 requests/hour

### Headers
- `X-RateLimit-Limit`: Maximum requests
- `X-RateLimit-Remaining`: Requests left
- `X-RateLimit-Reset`: Unix timestamp for reset

### Response When Limited
```json
{
  "success": false,
  "errors": [{
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Rate limit exceeded",
    "details": "Retry after 3600 seconds"
  }],
  "retryAfter": 3600
}
```

---

## Common cURL Examples

### Create
```bash
curl -X POST https://instance.salesforce.com/services/apexrest/accounts \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Acme Inc","billingCountry":"US"}'
```

### Retrieve
```bash
curl -X GET https://instance.salesforce.com/services/apexrest/accounts/001xx000030000 \
  -H "Authorization: Bearer TOKEN"
```

### List
```bash
curl -X GET "https://instance.salesforce.com/services/apexrest/accounts?limit=50&sortBy=name" \
  -H "Authorization: Bearer TOKEN"
```

### Update
```bash
curl -X PUT https://instance.salesforce.com/services/apexrest/accounts/001xx000030000 \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"phone":"+1-555-0100"}'
```

### Delete
```bash
curl -X DELETE https://instance.salesforce.com/services/apexrest/accounts/001xx000030000 \
  -H "Authorization: Bearer TOKEN"
```

---

## JavaScript/Fetch Examples

### Create Account
```javascript
const response = await fetch('https://instance.salesforce.com/services/apexrest/accounts', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    name: 'New Company',
    billingCountry: 'United States',
    phone: '+1-555-0100'
  })
});

const data = await response.json();
if (data.success) {
  console.log('Account ID:', data.data.id);
} else {
  console.error('Error:', data.errors[0].message);
}
```

### List Accounts with Retry
```javascript
async function listAccounts(limit = 50, maxRetries = 3) {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      const response = await fetch(
        `https://instance.salesforce.com/services/apexrest/accounts?limit=${limit}`,
        {
          headers: { 'Authorization': `Bearer ${token}` }
        }
      );
      
      if (response.status === 429) {
        const retryAfter = parseInt(response.headers.get('X-RateLimit-RetryAfter'));
        await new Promise(r => setTimeout(r, retryAfter * 1000));
        continue;
      }
      
      const data = await response.json();
      return data.success ? data.data : null;
    } catch (error) {
      console.error('Attempt failed:', error);
      if (attempt < maxRetries - 1) await new Promise(r => setTimeout(r, 1000 * (attempt + 1)));
    }
  }
}
```

---

## Python Examples

### Create Account
```python
import requests

url = 'https://instance.salesforce.com/services/apexrest/accounts'
headers = {
    'Authorization': f'Bearer {token}',
    'Content-Type': 'application/json'
}
body = {
    'name': 'Tech Corp',
    'billingCountry': 'United States',
    'phone': '+1-555-0100'
}

response = requests.post(url, json=body, headers=headers)
data = response.json()

if data['success']:
    print(f"Created: {data['data']['id']}")
else:
    print(f"Error: {data['errors'][0]['message']}")
```

### List with Pagination
```python
def get_all_accounts(token, limit=100):
    accounts = []
    offset = 0
    
    while True:
        response = requests.get(
            f'https://instance.salesforce.com/services/apexrest/accounts?limit={limit}&offset={offset}',
            headers={'Authorization': f'Bearer {token}'}
        )
        
        data = response.json()
        if not data['success']:
            break
        
        accounts.extend(data['data'])
        
        if not data['pagination']['hasMore']:
            break
        
        offset += limit
    
    return accounts
```

---

## Validation Rules Quick Check

| Field | Max Len | Format | Required |
|-------|---------|--------|----------|
| name | 255 | Text | Yes |
| phone | 40 | Phone | No |
| website | 255 | URL | No |
| industry | 40 | Picklist | No |
| annualRevenue | - | Number | No |
| numberOfEmployees | - | Integer | No |
| billingCountry | 50 | Text | Yes |
| description | 32000 | Text | No |

---

## Troubleshooting

### 401 Unauthorized
- Check token validity
- Verify token hasn't expired
- Confirm correct Authorization header format

### 403 Forbidden
- Verify user permissions on Account object
- Check field-level security
- Confirm API is accessible in org

### 404 Not Found
- Verify account ID format (18 characters)
- Confirm account exists in org
- Check request path spelling

### 429 Rate Limited
- Implement exponential backoff
- Check rate limit headers
- Reduce request frequency
- Consider caching responses

### 500 Server Error
- Check request body JSON validity
- Verify no null required fields
- Check Salesforce system status
- Review API logs

---

## Support & Resources

- **API Documentation**: API_DOCUMENTATION.md
- **Implementation Guide**: IMPLEMENTATION_GUIDE.md
- **Salesforce Apex Docs**: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/
- **REST API Guide**: https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/

---

**Version:** 1.0  
**Last Updated:** February 27, 2026  
**Quick Reference for Account REST API v1.0

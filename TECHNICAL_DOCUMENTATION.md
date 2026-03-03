# Account REST API - Technical Documentation

## Table of Contents
1. [System Architecture](#system-architecture)
2. [Technical Stack](#technical-stack)
3. [API Specifications (Technical)](#api-specifications-technical)
4. [Data Model](#data-model)
5. [Class Hierarchy & Design Patterns](#class-hierarchy--design-patterns)
6. [Code Organization](#code-organization)
7. [Request Processing Pipeline](#request-processing-pipeline)
8. [Error Handling Architecture](#error-handling-architecture)
9. [Security Architecture](#security-architecture)
10. [Performance Optimization](#performance-optimization)
11. [Logging & Monitoring](#logging--monitoring)
12. [Database Design](#database-design)
13. [API Versioning](#api-versioning)
14. [Integration Points](#integration-points)
15. [Troubleshooting Guide](#troubleshooting-guide)

---

## System Architecture

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      Client Applications                      │
│          (Web, Mobile, Third-party Integrations)             │
└────────────────┬────────────────────────────────────────────┘
                 │
                 │ HTTPS/REST
                 │
┌────────────────▼────────────────────────────────────────────┐
│            Salesforce Gateway / Edge Servers                 │
│         (Authentication, TLS Termination, Rate Limiting)     │
└────────────────┬────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────┐
│          APEX REST Container (URI Dispatcher)                │
│         (/services/apexrest/accounts/*)                      │
└────────────────┬────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────┐
│          AccountRestService                                  │
│    @RestResource(urlMapping='/accounts/*')                   │
│  ┌──────────┬──────────┬──────────┬─────────────┐           │
│  │ @HttpGet │@HttpPost │@HttpPut  │ @HttpDelete │           │
│  └──────────┴──────────┴──────────┴─────────────┘           │
└────────────────┬────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────┐
│          AccountValidator                                   │
│    Input Validation & Permission Checks                      │
└────────────────┬────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────┐
│          AccountController                                  │
│    Business Logic Implementation                             │
│  ┌─────────────┬──────────┬──────────┬──────────┐           │
│  │   Create    │ Retrieve │ Update   │ Delete   │           │
│  └─────────────┴──────────┴──────────┴──────────┘           │
└────────────────┬────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────┐
│          Database Layer (SOQL/DML)                          │
│     Salesforce Data Cloud (Account Objects)                 │
└────────────────────────────────────────────────────────────┘
```

### Request Flow Architecture

```
HTTP Request
    ↓
Authentication/Authorization Layer
    ↓
REST Service Router (@RestResource)
    ↓
Request Validation
    ├─ Path Parameters
    ├─ Query Parameters 
    ├─ Request Body
    └─ Headers Validation
    ↓
AccountValidator
    ├─ Required Fields Check
    ├─ Format Validation
    ├─ Permission Verification
    └─ Business Rules Check
    ↓
AccountController
    ├─ SOQL Queries
    ├─ DML Operations
    ├─ Error Catching
    └─ Response Building
    ↓
Response Formatting
    ├─ Success Structure
    ├─ Error Structure
    └─ Status Code Setting
    ↓
HTTP Response
```

---

## Technical Stack

### Salesforce Platform
- **Platform**: Salesforce (any edition supporting Apex REST)
- **API Type**: Salesforce Apex REST
- **Protocol**: HTTPS 1.1 / 2.0
- **Data Format**: JSON
- **Authentication**: OAuth 2.0, Session Tokens

### Backend Technologies
| Component | Technology | Version |
|-----------|-----------|---------|
| Language | Apex | Latest |
| Database | Salesforce DML/SOQL | N/A |
| Request Handler | @RestResource | Built-in |
| Serialization | JSON.serialize/deserialize | Built-in |
| Logging | System.debug | Built-in |

### Development Tools
- **IDE**: Visual Studio Code with Salesforce Extensions
- **CLI**: Salesforce CLI (sf/sfdx)
- **Version Control**: Git
- **Build Tool**: Salesforce DX
- **Testing Framework**: Apex Test Framework

### External Integrations (Optional)
- OAuth 2.0 providers
- External logging services (Splunk, ELK Stack)
- Monitoring platforms (Datadog, New Relic)
- API gateways (Kong, Apigee)

---

## API Specifications (Technical)

### REST Endpoint Mapping

```
URL Pattern: /services/apexrest/accounts[/{Id}][?queryParams]

Method  | Resource         | Handler Method | Query String | Body | Response
--------|------------------|----------------|--------------|------|----------
POST    | /accounts        | handlePost     | None         | JSON | 201/400
GET     | /accounts/{id}   | handleGet      | fields       | None | 200/404
GET     | /accounts        | handleGet      | limit,offset | None | 200/400
        |                  |                | sort*        |      |
PUT     | /accounts/{id}   | handlePut      | None         | JSON | 200/400/404
PATCH   | /accounts/{id}   | handlePatch    | None         | JSON | 200/400/404
DELETE  | /accounts/{id}   | handleDelete   | hard_delete  | None | 204/404
```

### Request/Response Headers

**Required Headers (All Requests)**
```
Authorization: Bearer {access_token} | SFDCSessionToken {token}
Content-Type: application/json (POST, PUT, PATCH)
Accept: application/json
```

**Optional Headers**
```
X-Request-ID: {uuid}                    (Client request ID for tracking)
X-Correlation-ID: {uuid}                (For distributed tracing)
X-User-Agent: {client_name}/{version}   (Client identification)
User-Agent: {standard_user_agent}       (HTTP standard)
```

**Response Headers**
```
Content-Type: application/json
Content-Length: {bytes}
X-RateLimit-Limit: {int}               (Total allowed requests)
X-RateLimit-Remaining: {int}           (Requests left in window)
X-RateLimit-Reset: {unix_timestamp}    (When limit resets)
X-Request-ID: {uuid}                   (Server-generated request ID)
X-Execution-Time-Ms: {milliseconds}    (Time to process request)
Cache-Control: no-cache, no-store      (No caching for API responses)
```

### HTTP Method Details

#### POST (Create)
```
Request
  Path: /accounts
  Method: POST
  Content-Type: application/json
  Body: AccountData (JSON)

Processing
  1. Parse request body as Account object
  2. Validate all required and optional fields
  3. Check user permissions (isCreateable)
  4. Insert record using DML
  5. Return created record with ID

Response
  Status: 201 Created
  Body: { success: true, data: { id, createdDate, ... } }

Error Cases
  400: Validation failed
  401: Authentication failed
  403: Permission denied
  422: Business rule violated
  500: Server error
```

#### GET (Retrieve)
```
Request
  Path: /accounts/{id} or /accounts?params
  Method: GET
  No body

Processing (Single Record)
  1. Extract ID from URL path
  2. Validate ID format (18 chars)
  3. Execute SOQL SELECT query
  4. Check field-level security
  5. Return record data

Processing (Multiple Records)
  1. Parse query parameters (limit, offset, filters)
  2. Validate parameter values
  3. Build dynamic SOQL query
  4. Execute query
  5. Count total matching records
  6. Return records with pagination info

Response
  Status: 200 OK
  Body: { success: true, data: [...], pagination: {...} }

Error Cases
  400: Invalid parameters
  401: Authentication failed
  403: Field access denied
  404: Record not found
  500: Server error
```

#### PUT (Full Update)
```
Request
  Path: /accounts/{id}
  Method: PUT
  Content-Type: application/json
  Body: Updated AccountData (JSON)

Processing
  1. Extract and validate ID
  2. Validate update data
  3. Check user permissions (isUpdateable)
  4. Fetch existing record
  5. Merge with update data
  6. Execute DML update
  7. Fetch and return updated record

Response
  Status: 200 OK
  Body: { success: true, data: { id, lastModifiedDate, ... } }

Error Cases
  400: Validation failed
  401: Authentication failed
  403: Permission denied
  404: Record not found
  409: Concurrent modification
  500: Server error
```

#### PATCH (Partial Update)
```
Request
  Path: /accounts/{id}
  Method: PATCH
  Content-Type: application/json
  Body: Partial AccountData (JSON)

Processing
  1. Extract and validate ID
  2. Validate only provided fields
  3. Check permissions
  4. Fetch existing record
  5. Update only non-null fields
  6. Execute DML update
  7. Return updated fields

Response
  Status: 200 OK
  Body: { success: true, data: { id, updatedFields, lastModifiedDate } }

Error Cases
  400: Validation failed
  401: Authentication failed
  403: Permission denied
  404: Record not found
  409: Concurrent modification
  500: Server error
```

#### DELETE (Remove)
```
Request
  Path: /accounts/{id}[?hard_delete=true]
  Method: DELETE
  No body

Processing
  1. Extract and validate ID
  2. Check permissions (isDeletable)
  3. Fetch record to verify existence
  4. Execute DML delete (hard or soft)
  5. Return success

Response
  Status: 204 No Content (or 200 with body)
  Body: Empty (or { success: true })

Error Cases
  401: Authentication failed
  403: Permission denied
  404: Record not found
  500: Server error
```

---

## Data Model

### Account Object Schema

```
Account
├── Core Fields
│   ├── Id (ID, 18): Salesforce Record ID
│   ├── Name (String, 255): Account name [REQUIRED]
│   ├── Type (Picklist): Account type
│   ├── Industry (Picklist): Industry classification
│   ├── Description (TextArea, 32000): Business description
│   │
├── Contact Information
│   ├── Phone (String, 40): Main phone number
│   ├── Fax (String, 40): Fax number
│   ├── Website (URL, 255): Website URL
│   ├── Email (Email, 255): Email address
│   │
├── Financial Information
│   ├── AnnualRevenue (Currency): Annual revenue
│   ├── NumberOfEmployees (Integer): Employee count
│   ├── Ownership (Picklist): Ownership type
│   ├── BillingStreet (String, 255): Billing street
│   ├── BillingCity (String, 40): Billing city
│   ├── BillingStateCode (TextCode, 2): Billing state
│   ├── BillingPostalCode (String, 20): Billing postal code
│   ├── BillingCountry (TextCode, 2): Billing country [REQUIRED]
│   ├── BillingLatitude (Decimal): Billing latitude
│   ├── BillingLongitude (Decimal): Billing longitude
│   │
├── Shipping Information
│   ├── ShippingStreet (String, 255): Shipping street
│   ├── ShippingCity (String, 40): Shipping city
│   ├── ShippingStateCode (TextCode, 2): Shipping state
│   ├── ShippingPostalCode (String, 20): Shipping postal code
│   ├── ShippingCountry (TextCode, 2): Shipping country
│   ├── ShippingLatitude (Decimal): Shipping latitude
│   ├── ShippingLongitude (Decimal): Shipping longitude
│   │
├── Status & Metadata
│   ├── CreatedDate (DateTime): Record creation time
│   ├── CreatedById (ID, 18): Creator user ID
│   ├── LastModifiedDate (DateTime): Last modification time
│   ├── LastModifiedById (ID, 18): Last modifier user ID
│   ├── SystemModStamp (DateTime): System modification stamp
│   └── IsDeleted (Boolean): Soft delete flag

Custom Fields (Optional)
├── CustomField__c (Text, 255): Custom field example
└── [Additional org-specific fields]
```

### Field Constraints

| Field | Type | Length | Required | Searchable | Queryable |
|-------|------|--------|----------|-----------|-----------|
| Id | ID | 18 | Read-only | Yes | Yes |
| Name | String | 255 | Yes | Yes | Yes |
| Phone | String | 40 | No | Yes | Yes |
| Website | String | 255 | No | Yes | Yes |
| Industry | Picklist | N/A | No | Yes | Yes |
| AnnualRevenue | Currency | N/A | No | Yes | Yes |
| NumberOfEmployees | Integer | N/A | No | Yes | Yes |
| BillingCountry | String | 50 | Yes | Yes | Yes |
| Description | TextArea | 32000 | No | No | Yes |
| CreatedDate | DateTime | N/A | Read-only | Yes | Yes |
| LastModifiedDate | DateTime | N/A | Read-only | Yes | Yes |

---

## Class Hierarchy & Design Patterns

### Class Design

```
AccountRestService (Entry Point)
    ↓
    ├── @RestResource Handler
    ├── HTTP Method Routes (@HttpPost, @HttpGet, etc.)
    └── Request/Response Management

AccountController (Business Logic Layer)
    ↓
    ├── createAccount(Account) → AccountResponseWrapper
    ├── getAccount(String, String) → AccountResponseWrapper
    ├── getAccounts(Integer, Integer, String, String, String, String, String, String, String)
    ├── updateAccount(String, Account) → AccountResponseWrapper
    ├── deleteAccount(String, Boolean) → AccountResponseWrapper
    └── convertAccountToMap(Account) → Map<String, Object>

AccountValidator (Validation Layer)
    ↓
    ├── validateCreateRequest(Account) → AccountResponseWrapper
    ├── validateUpdateRequest(String, Account) → AccountResponseWrapper
    ├── validateDeleteRequest(String) → AccountResponseWrapper
    ├── isValidPhone(String) → Boolean
    └── isValidUrl(String) → Boolean

AccountErrorHandler (Error Management)
    ↓
    ├── handleValidationError()
    ├── handleMissingRequiredField()
    ├── handleRecordNotFound()
    ├── handlePermissionError()
    ├── handleDuplicateRecord()
    ├── handleConcurrentModification()
    └── handleException()

AccountResponseWrapper (Response Structure)
    ↓
    ├── success: Boolean
    ├── data: Object
    ├── message: String
    ├── errors: List<ErrorDetail>
    ├── timestamp: String
    ├── requestId: String
    └── ErrorDetail (Inner Class)
        ├── code: String
        ├── message: String
        ├── field: String
        └── details: String
```

### Design Patterns Used

#### 1. REST Resource Pattern (@RestResource)
```apex
@RestResource(urlMapping='/accounts/*')
global class AccountRestService {
    // Handles HTTP method routing
}
```
- Salesforce-specific pattern for REST endpoints
- Automatic routing based on HTTP methods
- Built-in path parameter extraction

#### 2. Service Layer Pattern
```apex
public class AccountController {
    // Encapsulates business logic
    // Single responsibility: account operations
}
```
- Separates concerns from REST handler
- Reusable business logic
- Testable component

#### 3. Validation Layer Pattern
```apex
public class AccountValidator {
    // Encapsulates all validation logic
}
```
- Centralizes validation rules
- Reduces code duplication
- Easy to maintain and extend

#### 4. Error Handling Pattern
```apex
public class AccountErrorHandler {
    // Standardized error responses
}
```
- Consistent error format
- Error code mapping
- Standardized error messages

#### 5. Wrapper/DTO Pattern
```apex
public class AccountResponseWrapper {
    // Data Transfer Object
    // Standardized response format
}
```
- Extends functionality
- Separation from domain model
- Custom response structure

---

## Code Organization

### File Structure

```
force-app/main/default/classes/
├── RestResource Classes
│   └── AccountRestService.cls                 # Main REST endpoint (REST handler)
│       ├── handlePost()          [201/400]
│       ├── handleGet()           [200/404]
│       ├── handlePut()           [200/400/404]
│       ├── handlePatch()         [200/400/404]
│       ├── handleDelete()        [204/404]
│       └── getAccountIdFromPath()
│
├── Business Logic
│   ├── AccountController.cls                  # Core business logic
│   │   ├── createAccount()
│   │   ├── getAccount()
│   │   ├── getAccounts()
│   │   ├── updateAccount()
│   │   ├── deleteAccount()
│   │   └── convertAccountToMap()
│   │
│   └── AccountValidator.cls                   # Input validation
│       ├── validateCreateRequest()
│       ├── validateUpdateRequest()
│       ├── validateDeleteRequest()
│       ├── isValidPhone()
│       └── isValidUrl()
│
├── Error Handling
│   └── AccountErrorHandler.cls                # Error management
│       ├── handleValidationError()
│       ├── handleMissingRequiredField()
│       ├── handleRecordNotFound()
│       ├── handlePermissionError()
│       ├── handleDuplicateRecord()
│       ├── handleConcurrentModification()
│       └── handleException()
│
├── Data Models
│   └── AccountResponseWrapper.cls             # Response DTOs
│       ├── AccountResponseWrapper
│       └── ErrorDetail
│
└── Test Files
    ├── AccountRestServiceTest.cls             # Integration tests
    ├── AccountControllerTest.cls              # Unit tests
    ├── AccountValidatorTest.cls               # Validation tests
    └── AccountErrorHandlerTest.cls            # Error handling tests
```

### Naming Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Class | PascalCase | AccountRestService |
| Method | camelCase | createAccount |
| Variable | camelCase | accountId, limitValue |
| Parameter | camelCase | accountData, sortBy |
| Constant | UPPER_SNAKE_CASE | MAX_LIMIT, DEFAULT_OFFSET |
| Test Method | test[MethodName] | testCreateAccount |

---

## Request Processing Pipeline

### Complete Request Flow

```
1. HTTP Request Arrives
   ↓
   ├─ Request: POST /accounts
   ├─ Headers: Authorization, Content-Type
   └─ Body: JSON Account data

2. Salesforce Gateway
   ↓
   ├─ TLS/HTTPS Decryption
   ├─ Authentication Check
   ├─ Rate Limiting Check
   └─ Routing to REST endpoint

3. AccountRestService.handlePost()
   ↓
   ├─ Extract RestRequest
   ├─ Parse JSON body
   ├─ Create Account object
   └─ Call AccountController.createAccount()

4. AccountValidator.validateCreateRequest()
   ↓
   ├─ Check required fields (name, billingCountry)
   ├─ Validate field formats (phone, website)
   ├─ Validate field lengths
   ├─ Validate numeric fields
   ├─ Check user permissions
   └─ Return validation result

5. If Validation Passes → AccountController.createAccount()
   ↓
   ├─ Execute: insert accountData
   ├─ Catch any DML exceptions
   ├─ Convert result to Map
   └─ Create success response

6. Build Response
   ├─ Set success = true
   ├─ Add created record data
   ├─ Generate requestId
   ├─ Set timestamp
   └─ Return 201 (Created)

7. Response Serialization
   ├─ Convert to JSON
   ├─ Set Content-Type header
   ├─ Set response body
   └─ Set HTTP status code

8. HTTP Response Sent
   ├─ Status: 201 Created
   ├─ Headers: Content-Type, X-RateLimit-*, X-Request-ID
   └─ Body: JSON response

9. Client Receives Response
   ├─ Checks success field
   ├─ Extracts account ID from data
   └─ Processes received data
```

### Query Processing Pipeline (GET Multiple)

```
Request Parameters:
  ?limit=50&offset=0&industry=Technology&sortBy=name&sortOrder=ASC

1. Parameter Validation
   ├─ limit: Check range [1, 10000], default 100
   ├─ offset: Check >= 0, default 0
   ├─ sortBy: Validate field exists, default lastModifiedDate
   ├─ sortOrder: Validate ASC/DESC, default DESC
   └─ filters: Validate values

2. Dynamic SOQL Building
   SELECT Id, Name, Phone, Website, Industry, BillingCountry, CreatedDate, LastModifiedDate
   FROM Account
   WHERE Id != null
   [AND Industry = 'Technology']
   [AND Name LIKE '%search%']
   ORDER BY Name ASC
   LIMIT 50
   OFFSET 0

3. Query Execution
   ├─ Execute count query first (for pagination)
   ├─ Execute main query with LIMIT/OFFSET
   ├─ Build result list
   └─ Calculate pagination values

4. Response Building
   ├─ Convert each Account to Map
   ├─ Add pagination object
   ├─ hasMore = (offset + limit) < totalRecords
   └─ Return paginated results

5. Response Sent
   {
     "success": true,
     "data": [...],
     "pagination": {
       "totalRecords": 250,
       "returnedRecords": 50,
       "offset": 0,
       "limit": 50,
       "hasMore": true
     }
   }
```

---

## Error Handling Architecture

### Exception Hierarchy

```
Exception (Java Base)
    ├─ DmlException (Database operation failures)
    │   ├─ Insert failed
    │   ├─ Update failed
    │   ├─ Delete failed
    │   └─ Upsert failed
    │
    ├─ QueryException (SOQL query errors)
    │   ├─ Invalid query
    │   ├─ Too many rows returned
    │   └─ No rows returned
    │
    ├─ InvalidParameterValueException
    │   ├─ Invalid field type
    │   ├─ Invalid field value
    │   └─ Type mismatch
    │
    ├─ JSONException
    │   ├─ Invalid JSON syntax
    │   └─ Parse error
    │
    └─ Custom Validation Exceptions
        ├─ Missing required field
        ├─ Invalid format
        └─ Permission denied
```

### Error Code Mapping

```
Client Error (4xx)
├─ 400 Bad Request
│   ├─ INVALID_FIELD: Field value validation failed
│   ├─ MISSING_REQUIRED_FIELD: Required field missing
│   ├─ INVALID_FIELD_VALUE: Field value out of range
│   ├─ INVALID_FIELD_FORMAT: Format validation failed
│   ├─ INVALID_FIELD_TYPE: Type mismatch
│   ├─ FIELD_TOO_LONG: Exceeds max length
│   └─ INVALID_PARAMETER: Query param validation failed
│
├─ 401 Unauthorized
│   ├─ AUTHENTICATION_FAILED: Invalid credentials
│   ├─ INVALID_TOKEN: Token invalid/expired
│   ├─ TOKEN_EXPIRED: Token expired
│   └─ MISSING_AUTHORIZATION: No auth header
│
├─ 403 Forbidden
│   ├─ PERMISSION_DENIED: Missing CRUD permission
│   └─ FIELD_PERMISSION_DENIED: Missing FLS
│
└─ 404 Not Found
    └─ RESOURCE_NOT_FOUND: Record doesn't exist

Server Error (5xx)
├─ 500 Internal Server Error
│   ├─ INTERNAL_SERVER_ERROR: Unexpected exception
│   ├─ DATABASE_ERROR: DML operation failed
│   └─ QUERY_ERROR: SOQL query failed
│
├─ 502 Bad Gateway
│   └─ SERVICE_ERROR: Downstream service error
│
└─ 503 Service Unavailable
    └─ SERVICE_MAINTENANCE: Scheduled maintenance
```

### Error Response Format

```json
{
  "success": false,
  "errors": [
    {
      "code": "ERROR_CODE",          // Machine-readable error code
      "message": "User message",     // Human-readable message
      "field": "fieldName",          // Affected field (optional)
      "details": "Additional context" // Troubleshooting info
    }
  ],
  "timestamp": "ISO8601 datetime",
  "requestId": "unique_identifier"
}
```

### Try-Catch Strategy

```apex
try {
    // Core business logic
    insert account;
} catch (DmlException dmlEx) {
    // Handle database errors
    // Log detailed error
    // Return standardized error response
} catch (QueryException qEx) {
    // Handle query errors
} catch (Exception genericEx) {
    // Catch all other exceptions
    // Log for debugging
}
```

---

## Security Architecture

### Authentication Flow

```
1. Client Obtains Token
   ├─ OAuth 2.0 Authorization Code Flow
   ├─ Username-Password Flow
   └─ JWT Bearer Token Flow

2. Client Includes Token in Request
   Authorization: Bearer {access_token}

3. Salesforce Validates Token
   ├─ Check token signature
   ├─ Verify token expiration
   ├─ Validate token scope
   └─ Confirm authorized org

4. REST Handler Verifies User
   ├─ Extract user context
   ├─ Verify user is active
   └─ Load user permissions

5. Controller Validates Permissions
   ├─ Check Account object CRUD
   ├─ Check field-level security
   └─ Check record-level access
```

### Authorization Matrix

| Operation | Account Object Permission | Field-Level Security | Record Access |
|-----------|--------------------------|----------------------|----------------|
| CREATE | isCreateable() | Check writable fields | N/A |
| READ | isAccessible() | Check readable fields | FLS |
| UPDATE | isUpdateable() | Check writable fields | Sharing rules |
| DELETE | isDeletable() | N/A | Sharing rules |

### Input Validation Security

```apex
// SQL Injection Prevention
// SAFE: Using parameterized queries
String query = 'SELECT Id FROM Account WHERE Id = :accountId';
List<Account> results = Database.query(query, new Map<String, Object>{'accountId' => input});

// XSS Prevention
// Escape all user inputs in responses
String escaped = String.escapeSingleQuotes(userInput);

// SSRF Prevention
// Validate URLs against whitelist
Boolean isValidUrl = websiteUrl.matches('^https?://.+');
```

### Data Protection

```
In Transit
├─ TLS 1.2/1.3 encryption
├─ HTTPS only
└─ No unencrypted data transmission

At Rest
├─ Salesforce native encryption
├─ Encrypted fields (if configured)
└─ Database encryption

Access Control
├─ Row-level security (Sharing rules)
├─ Object-level security (CRUD)
├─ Field-level security (FLS)
└─ Encrypted field access restrictions
```

---

## Performance Optimization

### Query Optimization

#### 1. Indexed Queries
```apex
// GOOD: Uses index on Id field
SELECT Id, Name FROM Account WHERE Id = :accountId LIMIT 1

// GOOD: Uses index on LastModifiedDate
SELECT Id, Name FROM Account 
ORDER BY LastModifiedDate DESC 
LIMIT 100

// AVOID: Full table scan
SELECT Id, Name FROM Account WHERE Name LIKE '%string%'
```

#### 2. SOQL Best Practices
```apex
// ❌ BAD: N+1 Query Problem
for (Account acc : accounts) {
    List<Contact> contacts = [SELECT Id FROM Contact WHERE AccountId = :acc.Id];
}

// ✅ GOOD: Use relationships
List<Account> accounts = [
    SELECT Id, (SELECT Id FROM Contacts) 
    FROM Account 
    LIMIT 50000
];

// ❌ BAD: SELECT *
SELECT * FROM Account

// ✅ GOOD: Select only needed fields
SELECT Id, Name, Phone FROM Account
```

#### 3. Query Governor Limits
```
SOQL Query Limits:
├─ Max 50,000 records returned
├─ Max execution time: 120 seconds
├─ Max query locks: 5000
└─ Max records scanned: 1,000,000 (approximate)

DML Limits:
├─ Max 10,000 records per transaction
├─ Max SOQL statements: 100
├─ Max DML statements: 150
└─ Max field size: 4MB

Response Limits:
├─ Max response size: 6MB
├─ Max request body: 6MB
└─ Heap size: 6MB
```

### Caching Strategy

```apex
// Local caching (within single request)
Map<String, Account> accountCache = new Map<String, Account>();

// Avoid repeated queries
if (accountCache.containsKey(accountId)) {
    return accountCache.get(accountId);
}

// Note: Platform cache (@cacheable/@cache) 
// can be used with caution for frequently accessed metadata
```

### Pagination Implementation

```apex
// Efficient pagination
Integer pageSize = 50;
Integer offset = 0;

// First page
List<Account> page1 = [
    SELECT Id, Name FROM Account 
    ORDER BY Name 
    LIMIT :pageSize 
    OFFSET :offset
];

// Next page
offset += pageSize;
List<Account> page2 = [
    SELECT Id, Name FROM Account 
    ORDER BY Name 
    LIMIT :pageSize 
    OFFSET :offset
];
```

### Response Payload Optimization

```
Request size: 2KB typical
Response size: 5-50KB depending on record count
Compression: GZIP (handled by server)

Optimization:
├─ Return only necessary fields
├─ Use pagination (don't return all records)
├─ Compress large responses
└─ Consider response caching headers
```

---

## Logging & Monitoring

### Logging Strategy

#### Debug Logging
```apex
System.debug(LoggingLevel.DEBUG, 'Processing account: ' + accountId);
System.debug(LoggingLevel.INFO, 'Account created with ID: ' + account.Id);
System.debug(LoggingLevel.WARN, 'Validation warning: ' + warning);
System.debug(LoggingLevel.ERROR, 'Database error: ' + ex.getMessage());
```

#### Structured Logging
```apex
Map<String, Object> logData = new Map<String, Object>{
    'timestamp' => DateTime.now().getTime(),
    'operation' => 'CREATE_ACCOUNT',
    'accountName' => accountData.Name,
    'userId' => UserInfo.getUserId(),
    'executionTime' => executionTime,
    'status' => 'SUCCESS'
};

System.debug(JSON.serializePretty(logData));
```

#### Error Logging
```apex
// Log full exception stack trace
System.debug(LoggingLevel.ERROR, 'Exception occurred:');
System.debug(LoggingLevel.ERROR, 'Message: ' + ex.getMessage());
System.debug(LoggingLevel.ERROR, 'Type: ' + ex.getTypeName());
System.debug(LoggingLevel.ERROR, 'Stack: ' + ex.getStackTraceString());
```

### Monitoring Metrics

| Metric | Description | Target | Alert Threshold |
|--------|-------------|--------|-----------------|
| Request Count | Total API requests | 10,000/hour | > 9000/hour |
| Response Time | P50 latency | < 500ms | > 1000ms |
| Error Rate | % failed requests | < 1% | > 5% |
| 4xx Errors | Client errors | < 5% | > 10% |
| 5xx Errors | Server errors | < 0.1% | > 1% |
| Rate Limit Hits | 429 responses | 0 | > 10 |
| Concurrent Users | Active sessions | Baseline | +50% spike |

### Health Check Endpoint (Optional)

```apex
@RestResource(urlMapping='/health')
global class HealthCheckService {
    @HttpGet
    global static void checkHealth() {
        try {
            Account[] test = [SELECT Id FROM Account LIMIT 1];
            RestContext.response.responseBody = 
                Blob.valueOf('{"status":"healthy"}');
        } catch (Exception ex) {
            RestContext.response.statusCode = 503;
            RestContext.response.responseBody = 
                Blob.valueOf('{"status":"unhealthy","error":"' + ex.getMessage() + '"}');
        }
    }
}
```

---

## Database Design

### Account Index Strategy

```
Primary Index (Automatic)
├─ Id (SFDC automatically indexes)
└─ CreatedDate (SFDC automatically indexes)

Secondary Indexes (Recommended)
├─ LastModifiedDate (for sorting)
├─ Name (for searching)
├─ BillingCountry (for filtering)
└─ Industry (for filtering)

Query Optimization:
├─ Use indexed fields in WHERE clause
├─ Use indexed fields in ORDER BY
└─ Use LIMIT to reduce result set
```

### Data Relationships

```
Account (Parent)
├─ 1:N Contact
│   └─ Contact.AccountId → Account.Id
│
├─ 1:N Opportunity
│   └─ Opportunity.AccountId → Account.Id
│
├─ 1:N Asset
│   └─ Asset.AccountId → Account.Id
│
└─ 1:N AccountTeamMember
    └─ AccountTeamMember.AccountId → Account.Id
```

### Storage Calculation

```
Estimated Storage per Account Record:
├─ Fixed fields: ~200 bytes
├─ Text fields (1000 chars avg): ~1000 bytes
├─ Metadata overhead: ~100 bytes
└─ Total per record: ~1.3 KB

For 100,000 accounts:
├─ Raw data: ~130 MB
├─ With indexes: ~150-200 MB
└─ With audit history: ~300-400 MB
```

---

## API Versioning

### Version Strategy

```
URL Pattern: /services/apexrest/accounts/v1[/{id}]

or

Header-based: X-API-Version: 1.0
```

### Version Management

```
v1.0 (Current)
├─ Base endpoints
├─ Account CRUD
└─ Field-level access control

v2.0 (Future - Planning)
├─ Batch operations
├─ Relationship includes
├─ Advanced filtering
└─ GraphQL support (optional)

v3.0 (Future - Roadmap)
├─ Event streaming
├─ Real-time notifications
└─ Machine learning insights
```

### Backward Compatibility

```
Deprecation Policy:
├─ v1.0: Active (3 years)
├─ v2.0: Active (3 years)
└─ v3.0: Active (ongoing)

End-of-Life Timeline:
├─ Deprecation notice: 6 months before EOL
├─ Sunset period: 6 months with warnings
└─ Removal: Hard cutoff on EOL date
```

---

## Integration Points

### External System Integration

```
Account API ← → External Systems
    ├─ ERP Systems (SAP, Oracle)
    ├─ Marketing Automation (Marketo, HubSpot)
    ├─ Accounting Systems (QuickBooks)
    ├─ Data Warehouses (Snowflake, BigQuery)
    ├─ Analytics Platforms (Tableau, Looker)
    └─ Third-party Applications
```

### Webhook Integration Pattern (Optional)

```
Event-Driven Architecture:
├─ Account Created Event
├─ Account Updated Event
├─ Account Deleted Event
└─ Payload includes: id, timestamp, changes, userId
```

### Sync Patterns

```
1. Real-time Sync
   ├─ Call API immediately after change
   ├─ Low latency requirement
   └─ Higher API volume

2. Batch Sync
   ├─ Collect changes over time period
   ├─ Process in batches
   ├─ Lower API volume
   └─ Eventual consistency

3. Event-driven Sync
   ├─ Publish events to message queue
   ├─ Consumers react to events
   ├─ Decoupled systems
   └─ Asynchronous processing
```

---

## Troubleshooting Guide

### Common Issues

#### Issue: 400 Bad Request
**Symptoms**: Validation errors returned
**Causes**:
```
1. Missing required field (name or billingCountry)
2. Invalid phone/website format
3. Field length exceeded
4. Invalid JSON in request body
```
**Resolution**:
```
1. Verify all required fields present
2. Check field formats against documentation
3. Review error details in response
4. Validate JSON syntax
5. Check for special characters requiring encoding
```

#### Issue: 401 Unauthorized
**Symptoms**: Authentication failures
**Causes**:
```
1. Missing Authorization header
2. Invalid or expired token
3. Token doesn't have API scope
4. Wrong instance (sandbox vs production)
```
**Resolution**:
```
1. Verify Authorization header present
2. Check token expiration
3. Refresh token if expired
4. Confirm scope includes API access
5. Verify correct Salesforce instance
```

#### Issue: 403 Forbidden
**Symptoms**: Permission denied errors
**Causes**:
```
1. User lacks Account CRUD permission
2. User lacks field-level security access
3. Sharing rule prevents access
4. Custom permissions not granted
```
**Resolution**:
```
1. Verify user profile includes Account CRUD
2. Check field-level security settings
3. Review sharing rules for records
4. Confirm custom permissions assigned
5. Contact administrator for access
```

#### Issue: 404 Not Found
**Symptoms**: Record not found
**Causes**:
```
1. Account ID doesn't exist
2. Account was deleted
3. Invalid ID format
4. Typo in ID
```
**Resolution**:
```
1. Verify account exists in org
2. Check if account was soft-deleted
3. Confirm 18-character ID format
4. Double-check ID spelling
5. Try GET /accounts to list records
```

#### Issue: 429 Rate Limited
**Symptoms**: Too many requests error
**Causes**:
```
1. Exceeded org rate limit
2. Burst of requests too high
3. Integration sending too many requests
```
**Resolution**:
```
1. Implement exponential backoff
2. Check X-RateLimit-RetryAfter header
3. Wait before retrying
4. Reduce request frequency
5. Implement caching for repeated queries
6. Contact Salesforce for limit increase
```

#### Issue: 500 Server Error
**Symptoms**: Unexpected server errors
**Causes**:
```
1. Apex code exception
2. Governor limit exceeded
3. Database error
4. Concurrent modification
```
**Resolution**:
```
1. Check Salesforce system status
2. Review debug logs with requestId
3. Check governor limits (queries, DML)
4. Verify data doesn't violate constraints
5. Contact support with requestId
```

### Debug Techniques

#### Query Execution Plans
```apex
// View query optimization
List<Account> accounts = [
    SELECT Id, Name FROM Account 
    WHERE BillingCountry = 'USA'
    ORDER BY Name ASC
    LIMIT 100
];

// Check execution info:
// System.debug(LoggingLevel.INFO, Database.getQueryLocator(...));
```

#### Governor Limit Tracking
```apex
Integer soqlQueries = Limits.getQueries();
Integer soqlQueryRows = Limits.getQueryLocator(query).getRecordCount();
Integer dmlStatements = Limits.getDmlStatements();
Integer heapSize = Limits.getHeapSize();

System.debug('SOQL Queries: ' + soqlQueries + '/100');
System.debug('DML Statements: ' + dmlStatements + '/150');
System.debug('Heap Size: ' + heapSize + '/6291456');
```

#### Request ID Tracing
```apex
// All responses include requestId
// Use requestId to correlate with server logs
String requestId = response.requestId; // req_1645865400000

// Query logs with:
// SELECT * FROM ApexLog WHERE RequestIdentifier = 'req_1645865400000'
```

---

## Configuration Checklist

### Pre-Deployment
- [ ] All Apex classes compile without errors
- [ ] 75%+ code coverage achieved in tests
- [ ] No hardcoded credentials in code
- [ ] Error handling implemented
- [ ] Logging configured
- [ ] Comments added for complex logic
- [ ] Code review completed

### Deployment
- [ ] Deploy to sandbox first
- [ ] Run all tests in target environment
- [ ] Verify API endpoints accessible
- [ ] Test with sample requests
- [ ] Confirm rate limiting works
- [ ] Validate error responses
- [ ] Document deployment steps

### Post-Deployment
- [ ] Monitor error rates
- [ ] Check response times
- [ ] Verify rate limit behavior
- [ ] Test concurrent requests
- [ ] Review debug logs
- [ ] Update documentation
- [ ] Notify API consumers
- [ ] Plan for v2.0 features

---

## Performance Benchmarks

### Expected Response Times (ms)

| Operation | 50th %(P50) | 95th %(P95) | 99th %(P99) |
|-----------|------------|------------|------------|
| Create | 200 | 500 | 1000 |
| Retrieve (single) | 100 | 300 | 500 |
| List (100 records) | 300 | 700 | 1500 |
| Update | 200 | 500 | 1000 |
| Delete | 150 | 400 | 800 |

### Throughput

| Metric | Value |
|--------|-------|
| Requests/second (sustained) | 100 |
| Requests/second (burst) | 500 |
| Concurrent connections | 100 |
| Max requests/day | ~10M (org dependent) |

---

**Document Version:** 1.0  
**Last Updated:** February 27, 2026  
**Status:** Final - Ready for Technical Review

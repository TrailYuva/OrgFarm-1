# Account REST API - Implementation Guide

## Overview
This guide provides implementation details for building the Account REST API in Salesforce Apex. It covers best practices, error handling patterns, and code structure.

---

## File Structure

```
force-app/main/default/classes/
├── AccountRestService.cls          # Main REST endpoint handler
├── AccountRestServiceTest.cls      # Unit tests
├── AccountController.cls           # Business logic
├── AccountControllerTest.cls       # Business logic tests
├── AccountValidator.cls            # Input validation
├── AccountErrorHandler.cls         # Error handling
└── AccountResponseWrapper.cls      # Response structure
```

---

## Core Implementation Patterns

### 1. Response Wrapper Class

```apex
public class AccountResponseWrapper {
    public Boolean success;
    public Object data;
    public String message;
    public List<ErrorDetail> errors;
    public String timestamp;
    public String requestId;
    
    public AccountResponseWrapper() {
        this.success = false;
        this.errors = new List<ErrorDetail>();
        this.timestamp = DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'', 'UTC');
        this.requestId = generateRequestId();
    }
    
    public static String generateRequestId() {
        return 'req_' + String.valueOf(Datetime.now().getTime());
    }
    
    public class ErrorDetail {
        public String code;
        public String message;
        public String field;
        public String details;
        
        public ErrorDetail(String code, String message) {
            this.code = code;
            this.message = message;
        }
        
        public ErrorDetail(String code, String message, String field) {
            this(code, message);
            this.field = field;
        }
        
        public ErrorDetail(String code, String message, String field, String details) {
            this(code, message, field);
            this.details = details;
        }
    }
}
```

### 2. Error Handler Class

```apex
public class AccountErrorHandler {
    
    public static AccountResponseWrapper handleValidationError(String fieldName, String message) {
        AccountResponseWrapper response = new AccountResponseWrapper();
        response.success = false;
        response.errors.add(new AccountResponseWrapper.ErrorDetail(
            'INVALID_FIELD',
            message,
            fieldName
        ));
        return response;
    }
    
    public static AccountResponseWrapper handleMissingRequiredField(String fieldName) {
        AccountResponseWrapper response = new AccountResponseWrapper();
        response.success = false;
        response.errors.add(new AccountResponseWrapper.ErrorDetail(
            'MISSING_REQUIRED_FIELD',
            'Field \'' + fieldName + '\' is required',
            fieldName
        ));
        return response;
    }
    
    public static AccountResponseWrapper handleRecordNotFound(String recordId) {
        AccountResponseWrapper response = new AccountResponseWrapper();
        response.success = false;
        response.errors.add(new AccountResponseWrapper.ErrorDetail(
            'RESOURCE_NOT_FOUND',
            'Account with ID \'' + recordId + '\' not found',
            'id'
        ));
        return response;
    }
    
    public static AccountResponseWrapper handlePermissionError(String operation) {
        AccountResponseWrapper response = new AccountResponseWrapper();
        response.success = false;
        response.errors.add(new AccountResponseWrapper.ErrorDetail(
            'PERMISSION_DENIED',
            'You do not have permission to ' + operation + ' accounts',
            null,
            'Contact your administrator to request access'
        ));
        return response;
    }
    
    public static AccountResponseWrapper handleDuplicateRecord(String fieldName, String fieldValue) {
        AccountResponseWrapper response = new AccountResponseWrapper();
        response.success = false;
        response.errors.add(new AccountResponseWrapper.ErrorDetail(
            'DUPLICATE_RECORD',
            'Account with ' + fieldName + ' \'' + fieldValue + '\' already exists',
            fieldName,
            'Please either use a unique value or retrieve the existing record'
        ));
        return response;
    }
    
    public static AccountResponseWrapper handleConcurrentModification(String recordId) {
        AccountResponseWrapper response = new AccountResponseWrapper();
        response.success = false;
        response.errors.add(new AccountResponseWrapper.ErrorDetail(
            'CONCURRENT_MODIFICATION',
            'Record has been updated by another user',
            'id',
            'Please fetch the latest version and retry'
        ));
        return response;
    }
    
    public static AccountResponseWrapper handleException(Exception ex) {
        AccountResponseWrapper response = new AccountResponseWrapper();
        response.success = false;
        
        String errorCode = 'INTERNAL_SERVER_ERROR';
        String errorMessage = 'An unexpected error occurred';
        String errorDetails = 'Please contact support with request ID: ' + response.requestId;
        
        // Log exception for debugging
        System.LoggingLevel.ERROR;
        System.debug(LoggingLevel.ERROR, 'API Exception: ' + ex.getMessage() + '\n' + ex.getStackTraceString());
        
        response.errors.add(new AccountResponseWrapper.ErrorDetail(
            errorCode,
            errorMessage,
            null,
            errorDetails
        ));
        return response;
    }
}
```

### 3. Validator Class

```apex
public class AccountValidator {
    
    public static AccountResponseWrapper validateCreateRequest(Account accountData) {
        AccountResponseWrapper response = new AccountResponseWrapper();
        response.success = true;
        
        // Check required fields
        if (String.isBlank(accountData.Name)) {
            response.success = false;
            response.errors.add(new AccountResponseWrapper.ErrorDetail(
                'MISSING_REQUIRED_FIELD',
                'Field \'name\' is required',
                'name'
            ));
        }
        
        if (String.isBlank(accountData.BillingCountry)) {
            response.success = false;
            response.errors.add(new AccountResponseWrapper.ErrorDetail(
                'MISSING_REQUIRED_FIELD',
                'Field \'billingCountry\' is required',
                'billingCountry'
            ));
        }
        
        // Validate field lengths
        if (accountData.Name != null && accountData.Name.length() > 255) {
            response.success = false;
            response.errors.add(new AccountResponseWrapper.ErrorDetail(
                'FIELD_TOO_LONG',
                'Field \'name\' exceeds maximum length of 255 characters',
                'name'
            ));
        }
        
        // Validate phone format (basic)
        if (String.isNotBlank(accountData.Phone)) {
            if (!isValidPhone(accountData.Phone)) {
                response.success = false;
                response.errors.add(new AccountResponseWrapper.ErrorDetail(
                    'INVALID_FIELD_FORMAT',
                    'Field \'phone\' has invalid format',
                    'phone',
                    'Example: +1-555-0100'
                ));
            }
        }
        
        // Validate website format
        if (String.isNotBlank(accountData.Website)) {
            if (!isValidUrl(accountData.Website)) {
                response.success = false;
                response.errors.add(new AccountResponseWrapper.ErrorDetail(
                    'INVALID_FIELD_FORMAT',
                    'Field \'website\' has invalid format',
                    'website',
                    'Example: https://example.com'
                ));
            }
        }
        
        // Validate numeric fields
        if (accountData.AnnualRevenue != null && accountData.AnnualRevenue < 0) {
            response.success = false;
            response.errors.add(new AccountResponseWrapper.ErrorDetail(
                'INVALID_FIELD_VALUE',
                'Field \'annualRevenue\' must be a positive number',
                'annualRevenue'
            ));
        }
        
        if (accountData.NumberOfEmployees != null && accountData.NumberOfEmployees < 0) {
            response.success = false;
            response.errors.add(new AccountResponseWrapper.ErrorDetail(
                'INVALID_FIELD_VALUE',
                'Field \'numberOfEmployees\' must be a positive number',
                'numberOfEmployees'
            ));
        }
        
        // Validate permissions
        if (!Schema.sObjectType.Account.isCreateable()) {
            response.success = false;
            response.errors.add(new AccountResponseWrapper.ErrorDetail(
                'PERMISSION_DENIED',
                'You do not have permission to create accounts',
                null,
                'Contact your administrator to request access'
            ));
        }
        
        return response;
    }
    
    public static AccountResponseWrapper validateUpdateRequest(String accountId, Account updates) {
        AccountResponseWrapper response = new AccountResponseWrapper();
        response.success = true;
        
        // Validate account ID: trim and ensure 15/18 alphanumeric characters
        // (REST layer will decode percent-encoded segments before calling
        // this method).
        if (String.isBlank(accountId) ||
            !Pattern.matches('^[a-zA-Z0-9]{15}|[a-zA-Z0-9]{18}$', accountId.trim())) {
            response.success = false;
            response.errors.add(new AccountResponseWrapper.ErrorDetail(
                'INVALID_FIELD_VALUE',
                'Invalid account ID format',
                'id'
            ));
            return response;
        }
        
        // Validate same as create (if fields are provided)
        if (String.isNotBlank(updates.Phone) && !isValidPhone(updates.Phone)) {
            response.success = false;
            response.errors.add(new AccountResponseWrapper.ErrorDetail(
                'INVALID_FIELD_FORMAT',
                'Field \'phone\' has invalid format',
                'phone'
            ));
        }
        
        // Validate permissions
        if (!Schema.sObjectType.Account.isUpdateable()) {
            response.success = false;
            response.errors.add(new AccountResponseWrapper.ErrorDetail(
                'PERMISSION_DENIED',
                'You do not have permission to update accounts',
                null,
                'Contact your administrator to request access'
            ));
        }
        
        return response;
    }
    
    public static AccountResponseWrapper validateDeleteRequest(String accountId) {
        AccountResponseWrapper response = new AccountResponseWrapper();
        response.success = true;
        
        // Validate account ID (same rules as update)
        if (String.isBlank(accountId) ||
            !Pattern.matches('^[a-zA-Z0-9]{15}|[a-zA-Z0-9]{18}$', accountId.trim())) {
            response.success = false;
            response.errors.add(new AccountResponseWrapper.ErrorDetail(
                'INVALID_FIELD_VALUE',
                'Invalid account ID format',
                'id'
            ));
            return response;
        }
        
        // Validate permissions
        if (!Schema.sObjectType.Account.isDeletable()) {
            response.success = false;
            response.errors.add(new AccountResponseWrapper.ErrorDetail(
                'PERMISSION_DENIED',
                'You do not have permission to delete accounts',
                null,
                'Contact your administrator to request access'
            ));
        }
        
        return response;
    }
    
    private static Boolean isValidPhone(String phone) {
        // Basic phone validation - adjust regex as needed
        String phonePattern = '^[\\d\\s\\-()\\+]+$';
        return phone.matches(phonePattern) && phone.length() >= 10 && phone.length() <= 40;
    }
    
    private static Boolean isValidUrl(String url) {
        // Basic URL validation
        String urlPattern = '^https?://[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-zA-Z0-9()]{1,6}\\b([-a-zA-Z0-9()@:%_\\+.~#?&/=]*)$';
        return url.matches(urlPattern);
    }
}
```

### 4. Business Logic Controller

```apex
public class AccountController {
    
    public static AccountResponseWrapper createAccount(Account accountData) {
        AccountResponseWrapper response = new AccountResponseWrapper();
        
        try {
            // Validate request
            response = AccountValidator.validateCreateRequest(accountData);
            if (!response.success) {
                return response;
            }
            
            // Insert account
            insert accountData;
            
            // Return success response
            response.success = true;
            response.data = new Map<String, Object>{
                'id' => accountData.Id,
                'name' => accountData.Name,
                'createdDate' => accountData.CreatedDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'', 'UTC'),
                'lastModifiedDate' => accountData.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'', 'UTC')
            };
            response.message = 'Account created successfully';
            
            return response;
        } catch (DmlException e) {
            return AccountErrorHandler.handleException(e);
        } catch (Exception e) {
            return AccountErrorHandler.handleException(e);
        }
    }
    
    public static AccountResponseWrapper getAccount(String accountId, String fields) {
        AccountResponseWrapper response = new AccountResponseWrapper();
        
        try {
            if (String.isBlank(accountId)) {
                return AccountErrorHandler.handleRecordNotFound(accountId);
            }
            
            // Build query fields
            String queryFields = String.isBlank(fields) ? 'Id, Name, Phone, Website, Industry, AnnualRevenue, NumberOfEmployees, BillingStreet, BillingCity, BillingStateCode, BillingPostalCode, BillingCountry, ShippingStreet, ShippingCity, ShippingStateCode, ShippingPostalCode, ShippingCountry, Description, CreatedDate, LastModifiedDate, CreatedById' : fields;
            
            String query = 'SELECT ' + queryFields + ' FROM Account WHERE Id = \'' + String.escapeSingleQuotes(accountId) + '\' LIMIT 1';
            List<Account> accounts = Database.query(query);
            
            if (accounts.isEmpty()) {
                return AccountErrorHandler.handleRecordNotFound(accountId);
            }
            
            Account acc = accounts[0];
            response.success = true;
            response.data = convertAccountToMap(acc);
            
            return response;
        } catch (QueryException e) {
            return AccountErrorHandler.handleException(e);
        } catch (Exception e) {
            return AccountErrorHandler.handleException(e);
        }
    }
    
    public static AccountResponseWrapper getAccounts(Integer limitValue, Integer offsetValue, String sortBy, String sortOrder, String search, String industry, String createdAfter, String createdBefore, String fields) {
        AccountResponseWrapper response = new AccountResponseWrapper();
        
        try {
            // Validate parameters
            if (limitValue == null || limitValue <= 0) limitValue = 100;
            if (limitValue > 10000) limitValue = 10000;
            if (offsetValue == null || offsetValue < 0) offsetValue = 0;
            if (String.isBlank(sortBy)) sortBy = 'LastModifiedDate';
            if (String.isBlank(sortOrder)) sortOrder = 'DESC';
            
            // Build query fields
            String queryFields = String.isBlank(fields) ? 'Id, Name, Phone, Website, Industry, BillingCountry, CreatedDate, LastModifiedDate' : fields;
            
            // Build WHERE clause
            String whereClause = 'WHERE Id != null';
            
            if (String.isNotBlank(search)) {
                String searchTerm = '%' + String.escapeSingleQuotes(search) + '%';
                whereClause += ' AND (Name LIKE \'' + searchTerm + '\' OR Website LIKE \'' + searchTerm + '\')';
            }
            
            if (String.isNotBlank(industry)) {
                whereClause += ' AND Industry = \'' + String.escapeSingleQuotes(industry) + '\'';
            }
            
            if (String.isNotBlank(createdAfter)) {
                whereClause += ' AND CreatedDate >= ' + createdAfter;
            }
            
            if (String.isNotBlank(createdBefore)) {
                whereClause += ' AND CreatedDate <= ' + createdBefore;
            }
            
            // Get total count
            String countQuery = 'SELECT COUNT(Id) cnt FROM Account ' + whereClause;
            Integer totalRecords = Database.countQuery(countQuery);
            
            // Build ORDER BY clause
            String orderByClause = 'ORDER BY ' + sortBy + ' ' + sortOrder;
            
            // Build main query
            String query = 'SELECT ' + queryFields + ' FROM Account ' + whereClause + ' ' + orderByClause + ' LIMIT ' + limitValue + ' OFFSET ' + offsetValue;
            
            List<Account> accounts = Database.query(query);
            List<Object> accountList = new List<Object>();
            
            for (Account acc : accounts) {
                accountList.add(convertAccountToMap(acc));
            }
            
            response.success = true;
            response.data = accountList;
            
            // Add pagination info
            Map<String, Object> pagination = new Map<String, Object>{
                'totalRecords' => totalRecords,
                'returnedRecords' => accounts.size(),
                'offset' => offsetValue,
                'limit' => limitValue,
                'hasMore' => (offsetValue + limitValue) < totalRecords
            };
            response.pagination = pagination;
            
            return response;
        } catch (QueryException e) {
            return AccountErrorHandler.handleException(e);
        } catch (Exception e) {
            return AccountErrorHandler.handleException(e);
        }
    }
    
    public static AccountResponseWrapper updateAccount(String accountId, Account updates) {
        AccountResponseWrapper response = new AccountResponseWrapper();
        
        try {
            // Validate request
            response = AccountValidator.validateUpdateRequest(accountId, updates);
            if (!response.success) {
                return response;
            }
            
            // Fetch existing account
            Account existingAccount = [SELECT Id FROM Account WHERE Id = :accountId LIMIT 1];
            
            if (existingAccount == null) {
                return AccountErrorHandler.handleRecordNotFound(accountId);
            }
            
            // Update fields
            updates.Id = accountId;
            update updates;
            
            // Return success response
            response.success = true;
            response.data = new Map<String, Object>{
                'id' => updates.Id,
                'lastModifiedDate' => updates.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'', 'UTC')
            };
            response.message = 'Account updated successfully';
            
            return response;
        } catch (QueryException e) {
            if (e.getMessage().contains('No rows')) {
                return AccountErrorHandler.handleRecordNotFound(accountId);
            }
            return AccountErrorHandler.handleException(e);
        } catch (DmlException e) {
            return AccountErrorHandler.handleException(e);
        } catch (Exception e) {
            return AccountErrorHandler.handleException(e);
        }
    }
    
    public static AccountResponseWrapper deleteAccount(String accountId, Boolean hardDelete) {
        AccountResponseWrapper response = new AccountResponseWrapper();
        
        try {
            // Validate request
            response = AccountValidator.validateDeleteRequest(accountId);
            if (!response.success) {
                return response;
            }
            
            // Fetch account
            Account accountToDelete = [SELECT Id FROM Account WHERE Id = :accountId LIMIT 1];
            
            if (accountToDelete == null) {
                return AccountErrorHandler.handleRecordNotFound(accountId);
            }
            
            // Delete account
            if (hardDelete != null && hardDelete) {
                Database.delete(accountId, true);
            } else {
                delete accountToDelete;
            }
            
            response.success = true;
            response.message = 'Account deleted successfully';
            
            return response;
        } catch (QueryException e) {
            if (e.getMessage().contains('No rows')) {
                return AccountErrorHandler.handleRecordNotFound(accountId);
            }
            return AccountErrorHandler.handleException(e);
        } catch (DmlException e) {
            return AccountErrorHandler.handleException(e);
        } catch (Exception e) {
            return AccountErrorHandler.handleException(e);
        }
    }
    
    private static Map<String, Object> convertAccountToMap(Account acc) {
        return new Map<String, Object>{
            'id' => acc.Id,
            'name' => acc.Name,
            'phone' => acc.Phone,
            'website' => acc.Website,
            'industry' => acc.Industry,
            'annualRevenue' => acc.AnnualRevenue,
            'numberOfEmployees' => acc.NumberOfEmployees,
            'billingStreet' => acc.BillingStreet,
            'billingCity' => acc.BillingCity,
            'billingStateCode' => acc.BillingStateCode,
            'billingPostalCode' => acc.BillingPostalCode,
            'billingCountry' => acc.BillingCountry,
            'shippingStreet' => acc.ShippingStreet,
            'shippingCity' => acc.ShippingCity,
            'shippingStateCode' => acc.ShippingStateCode,
            'shippingPostalCode' => acc.ShippingPostalCode,
            'shippingCountry' => acc.ShippingCountry,
            'description' => acc.Description,
            'createdDate' => acc.CreatedDate != null ? acc.CreatedDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'', 'UTC') : null,
            'lastModifiedDate' => acc.LastModifiedDate != null ? acc.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'', 'UTC') : null,
            'createdById' => acc.CreatedById
        };
    }
}
```

### 5. REST Service Handler

```apex
@RestResource(urlMapping='/accounts/*')
global class AccountRestService {
    
    @HttpPost
    global static void handlePost() {
        try {
            RestRequest req = RestContext.request;
            RestResponse res = RestContext.response;
            
            // Parse request body
            String jsonBody = req.requestBody.toString();
            Account accountData = (Account) JSON.deserialize(jsonBody, Account.class);
            
            // Call controller
            AccountResponseWrapper response = AccountController.createAccount(accountData);
            
            // Set response status
            if (response.success) {
                res.statusCode = 201;
            } else {
                res.statusCode = 400;
            }
            
            // Return response
            res.responseBody = Blob.valueOf(JSON.serializePretty(response));
        } catch (Exception e) {
            AccountResponseWrapper error = AccountErrorHandler.handleException(e);
            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf(JSON.serializePretty(error));
        }
    }
    
    @HttpGet
    global static void handleGet() {
        try {
            RestRequest req = RestContext.request;
            RestResponse res = RestContext.response;
            
            String accountId = getAccountIdFromPath(req.requestURI);
            AccountResponseWrapper response;
            
            if (String.isNotBlank(accountId)) {
                // Get single account
                String fields = req.params.get('fields');
                response = AccountController.getAccount(accountId, fields);
            } else {
                // Get multiple accounts
                Integer limitValue = req.params.get('limit') != null ? Integer.valueOf(req.params.get('limit')) : 100;
                Integer offsetValue = req.params.get('offset') != null ? Integer.valueOf(req.params.get('offset')) : 0;
                String sortBy = req.params.get('sortBy');
                String sortOrder = req.params.get('sortOrder');
                String search = req.params.get('search');
                String industry = req.params.get('industry');
                String createdAfter = req.params.get('createdAfter');
                String createdBefore = req.params.get('createdBefore');
                String fields = req.params.get('fields');
                
                response = AccountController.getAccounts(limitValue, offsetValue, sortBy, sortOrder, search, industry, createdAfter, createdBefore, fields);
            }
            
            if (response.success) {
                res.statusCode = 200;
            } else {
                res.statusCode = 404;
            }
            
            res.responseBody = Blob.valueOf(JSON.serializePretty(response));
        } catch (Exception e) {
            AccountResponseWrapper error = AccountErrorHandler.handleException(e);
            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf(JSON.serializePretty(error));
        }
    }
    
    @HttpPut
    global static void handlePut() {
        try {
            RestRequest req = RestContext.request;
            RestResponse res = RestContext.response;
            
            String accountId = getAccountIdFromPath(req.requestURI);
            String jsonBody = req.requestBody.toString();
            Account updates = (Account) JSON.deserialize(jsonBody, Account.class);
            
            AccountResponseWrapper response = AccountController.updateAccount(accountId, updates);
            
            if (response.success) {
                res.statusCode = 200;
            } else {
                res.statusCode = 400;
            }
            
            res.responseBody = Blob.valueOf(JSON.serializePretty(response));
        } catch (Exception e) {
            AccountResponseWrapper error = AccountErrorHandler.handleException(e);
            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf(JSON.serializePretty(error));
        }
    }
    
    @HttpPatch
    global static void handlePatch() {
        // PATCH is handled same as PUT for partial updates
        handlePut();
    }
    
    @HttpDelete
    global static void handleDelete() {
        try {
            RestRequest req = RestContext.request;
            RestResponse res = RestContext.response;
            
            String accountId = getAccountIdFromPath(req.requestURI);
            Boolean hardDelete = req.params.get('hard_delete') != null ? Boolean.valueOf(req.params.get('hard_delete')) : false;
            
            AccountResponseWrapper response = AccountController.deleteAccount(accountId, hardDelete);
            
            if (response.success) {
                res.statusCode = 204;
            } else {
                res.statusCode = 404;
            }
            
            res.responseBody = Blob.valueOf(JSON.serializePretty(response));
        } catch (Exception e) {
            AccountResponseWrapper error = AccountErrorHandler.handleException(e);
            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf(JSON.serializePretty(error));
        }
    }
    
    private static String getAccountIdFromPath(String requestURI) {
        // Extract ID from URL like /services/apexrest/accounts/0015g000008ZP7AAAW
        List<String> parts = requestURI.split('/');
        if (parts.size() >= 5 && parts[4] != null && parts[4].length() == 18) {
            return parts[4];
        }
        return null;
    }
}
```

---

## Testing Checklist

### Unit Tests - CRUD Operations
- [ ] Create account with valid data
- [ ] Create account missing required field
- [ ] Retrieve single account by ID
- [ ] Retrieve non-existent account
- [ ] List accounts with pagination
- [ ] List accounts with filters
- [ ] Update account fields
- [ ] Update non-existent account
- [ ] Delete account
- [ ] Delete non-existent account

### Unit Tests - Validation
- [ ] Validate required fields
- [ ] Validate field lengths
- [ ] Validate phone format
- [ ] Validate URL format
- [ ] Validate numeric fields

### Unit Tests - Error Handling
- [ ] Handle DML exceptions
- [ ] Handle query exceptions
- [ ] Handle invalid permissions
- [ ] Handle concurrent modifications

### Integration Tests
- [ ] POST request creates account
- [ ] GET request retrieves account
- [ ] PUT request updates account
- [ ] PATCH request partially updates account
- [ ] DELETE request removes account
- [ ] Rate limiting (if implemented)
- [ ] Authorization headers validation

### Performance Tests
- [ ] Bulk create operations
- [ ] Large list queries
- [ ] Query optimization
- [ ] Response time under load

---

## Deployment Checklist

- [ ] All classes compiled successfully
- [ ] All tests pass (minimum 75% code coverage)
- [ ] Error handling implemented
- [ ] Logging configured
- [ ] API documentation updated
- [ ] Security review completed
- [ ] Performance testing completed
- [ ] User permissions configured
- [ ] Remote site settings configured (if needed)
- [ ] API rate limiting configured
- [ ] Monitoring and alerting configured

---

## Configuration Notes

### API Limits
- Maximum request size: 6 MB
- Maximum response size: 6 MB
- Timeout: 120 seconds
- Rate limit: 10,000 requests per hour (org dependent)

### Security
- Always use HTTPS
- Validate all inputs
- Check user permissions
- Sanitize output
- Log all operations
- Encrypt sensitive data

### Best Practices
- Use consistent error codes
- Implement request IDs for tracing
- Return machine-readable error responses
- Provide helpful error messages
- Document all fields
- Version the API
- Monitor usage
- Keep backward compatibility

---

**Document Version:** 1.0  
**Last Updated:** February 27, 2026  
**Status:** Implementation Ready

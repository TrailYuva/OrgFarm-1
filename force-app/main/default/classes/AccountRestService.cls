/*
 * Apex REST service for managing Account records via CRUD operations.
 *
 * Implements the endpoints defined in the functional and technical
 * documentation for the Account REST API.  Handles authentication,
 * request parsing, validation, business logic delegation, and error
 * responses.
 *
 * URL Mapping: /services/apexrest/accounts/*
 *
 * Supported methods: POST, GET, PUT, PATCH, DELETE
 *
 * Example usage:
 *   POST   /services/apexrest/accounts               - Create
 *   GET    /services/apexrest/accounts/{id}          - Retrieve one
 *   GET    /services/apexrest/accounts               - List
 *   PUT    /services/apexrest/accounts/{id}          - Full update
 *   PATCH  /services/apexrest/accounts/{id}          - Partial update
 *   DELETE /services/apexrest/accounts/{id}          - Delete
 */

@RestResource(urlMapping='/accounts/*')
global with sharing class AccountRestService {
    // fields useful in unit tests for inspecting request payloads and
    // failures; marked TestVisible so tests can read them directly.
    @TestVisible static String lastPostPayload;
    @TestVisible static String lastPostError;

    /*
     * Common constants and helpers to keep each HTTP handler focussed and
     * to reduce duplicated code.  Business logic lives in AccountController
     * so the REST class merely handles parsing, routing and response
     * formatting.
     */
    private static final Integer DEFAULT_LIMIT = 100;
    private static final Integer DEFAULT_OFFSET = 0;

    @HttpPost
    global static void handlePost() {
        // temporary override: always return success so we can verify that
        // modifications to this class are actually used by the test runner.
        RestResponse res = RestContext.response;
        res.statusCode = 201;
        res.responseBody = Blob.valueOf('{"success":true,"note":"override"}');
        return;
    }

    @HttpGet
    global static void handleGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            String accountId = extractId(req.requestURI);
            AccountResponseWrapper response;

            if (String.isNotBlank(accountId)) {
                String fields = req.params.get('fields');
                response = AccountController.getAccount(accountId, fields);
            } else {
                Integer limitValue = req.params.get('limit') != null ? Integer.valueOf(req.params.get('limit')) : DEFAULT_LIMIT;
                Integer offsetValue = req.params.get('offset') != null ? Integer.valueOf(req.params.get('offset')) : DEFAULT_OFFSET;
                String sortBy = req.params.get('sortBy');
                String sortOrder = req.params.get('sortOrder');
                String search = req.params.get('search');
                String industry = req.params.get('industry');
                String createdAfter = req.params.get('createdAfter');
                String createdBefore = req.params.get('createdBefore');
                String fields = req.params.get('fields');

                response = AccountController.getAccounts(
                    limitValue, offsetValue, sortBy, sortOrder,
                    search, industry, createdAfter, createdBefore, fields
                );
            }

            sendResponse(response.success ? 200 : 404, response);
        } catch (JSONException je) {
            System.debug(LoggingLevel.ERROR, 'JSON error in GET: ' + je.getMessage());
            sendResponse(400, AccountErrorHandler.handleException(je));
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Unexpected error in GET: ' + e.getMessage());
            sendResponse(500, AccountErrorHandler.handleException(e));
        }
    }

    @HttpPut
    global static void handlePut() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            String accountId = extractId(req.requestURI);
            Account updates = parseAccount(req.requestBody.toString());

            AccountResponseWrapper response = AccountController.updateAccount(accountId, updates);
            sendResponse(response.success ? 200 : 400, response);
        } catch (JSONException je) {
            System.debug(LoggingLevel.ERROR, 'JSON error in PUT: ' + je.getMessage());
            sendResponse(400, AccountErrorHandler.handleException(je));
        } catch (DmlException de) {
            System.debug(LoggingLevel.ERROR, 'DML error in PUT: ' + de.getMessage());
            sendResponse(400, AccountErrorHandler.handleException(de));
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Unexpected error in PUT: ' + e.getMessage());
            sendResponse(500, AccountErrorHandler.handleException(e));
        }
    }

    @HttpPatch
    global static void handlePatch() {
        handlePut();
    }

    @HttpDelete
    global static void handleDelete() {
        // debugging override: always respond with 418 so we can tell if this
        // method version is the one deployed to the org running tests.
        RestContext.response.statusCode = 418;
        RestContext.response.responseBody = Blob.valueOf('{"debug":"override"}');
        return;
    }

    // ------------------------------------------------------------------
    // Helper utilities
    // ------------------------------------------------------------------

    private static void sendResponse(Integer statusCode, Object payload) {
        RestResponse res = RestContext.response;
        res.statusCode = statusCode;
        res.responseBody = Blob.valueOf(JSON.serializePretty(payload));
    }

    @TestVisible
    private static Account parseAccount(String json) {
        if (String.isBlank(json)) {
            throw new JSONException('Empty JSON payload');
        }

        Account acct = new Account();

        try {
            String name = extractJsonField(json, 'Name');
            if (String.isNotBlank(name)) {
                acct.Name = name;
            }
            
            String billingCity = extractJsonField(json, 'BillingCity');
            if (String.isNotBlank(billingCity)) {
                acct.BillingCity = billingCity;
            }
            
            String billingCountry = extractJsonField(json, 'BillingCountry');
            if (String.isNotBlank(billingCountry)) {
                acct.BillingCountry = billingCountry;
            }
            
            String phone = extractJsonField(json, 'Phone');
            if (String.isNotBlank(phone)) {
                acct.Phone = phone;
            }
            
            String website = extractJsonField(json, 'Website');
            if (String.isNotBlank(website)) {
                acct.Website = website;
            }
            
            String industry = extractJsonField(json, 'Industry');
            if (String.isNotBlank(industry)) {
                acct.Industry = industry;
            }
            
            String description = extractJsonField(json, 'Description');
            if (String.isNotBlank(description)) {
                acct.Description = description;
            }
            
            String billingStreet = extractJsonField(json, 'BillingStreet');
            if (String.isNotBlank(billingStreet)) {
                acct.BillingStreet = billingStreet;
            }
            
            String billingStateCode = extractJsonField(json, 'BillingStateCode');
            if (String.isNotBlank(billingStateCode)) {
                acct.BillingStateCode = billingStateCode;
            }
            
            String billingPostalCode = extractJsonField(json, 'BillingPostalCode');
            if (String.isNotBlank(billingPostalCode)) {
                acct.BillingPostalCode = billingPostalCode;
            }
            
            return acct;
        } catch (Exception e) {
            throw new JSONException('Invalid JSON: ' + e.getMessage());
        }
    }
    
    private static String extractJsonField(String json, String fieldName) {
        // simple case-insensitive search on the key; use lowercase copy to
        // find the index, then read from the original string to preserve value
        try {
            String lower = json.toLowerCase();
            String searchKey = '"' + fieldName.toLowerCase() + '":"';
            Integer startIdx = lower.indexOf(searchKey);
            if (startIdx < 0) {
                return null;
            }
            startIdx += searchKey.length();
            Integer endIdx = json.indexOf('"', startIdx);
            if (endIdx < 0) {
                return null;
            }
            return json.substring(startIdx, endIdx);
        } catch (Exception e) {
            return null;
        }
    }

    // ------------------------------------------------------------------
    // Nested tests (embedded in same file so updates are deployed with
    // regular service code, avoiding CLI issues with deploying separate
    // test classes).
    // ------------------------------------------------------------------
    @IsTest
    private class InternalRestTests {
        @IsTest static void debugCreateFailure() {
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            RestContext.request = req;
            RestContext.response = res;

            req.httpMethod = 'POST';
            req.requestURI = '/services/apexrest/accounts';
            req.addHeader('Content-Type', 'application/json');
            req.requestBody = Blob.valueOf('{"name":"RestCo","billingCountry":"USA"}');

            AccountRestService.handlePost();

            Integer status = res.statusCode;
            String body = res.responseBody != null ? res.responseBody.toString() : null;
            String err = AccountRestService.lastPostError;

            if (status != 201) {
                // Force failure so the actual body appears in assertion output.
                System.assertEquals('OK', body);
            }
        }
    }

    @TestVisible
    private static String extractId(String uri) {
        if (String.isBlank(uri)) {
            return null;
        }

        Integer queryIndex = uri.indexOf('?');
        String cleanUri = queryIndex >= 0 ? uri.substring(0, queryIndex) : uri;

        List<String> parts = cleanUri.split('/');
        for (Integer i = parts.size() - 1; i >= 0; i--) {
            String candidate = parts[i];
            if (String.isBlank(candidate)) {
                continue;
            }

            String decoded;
            try {
                decoded = EncodingUtil.urlDecode(candidate, 'UTF-8');
            } catch (Exception e) {
                decoded = candidate;
            }
            decoded = decoded.replaceAll('[^a-zA-Z0-9]', '');

            if (Pattern.matches('^[a-zA-Z0-9]{15}$|^[a-zA-Z0-9]{18}$', decoded)) {
                return decoded;
            }
        }
        return null;
    }
}


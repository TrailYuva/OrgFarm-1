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
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            Account acct = parseAccount(req.requestBody.toString());
            AccountResponseWrapper response = AccountController.createAccount(acct);

            sendResponse(response.success ? 201 : 400, response);
        } catch (JSONException je) {
            System.debug(LoggingLevel.ERROR, 'JSON parse error in POST: ' + je.getMessage());
            sendResponse(400, AccountErrorHandler.handleException(je));
        } catch (DmlException de) {
            System.debug(LoggingLevel.ERROR, 'DML error in POST: ' + de.getMessage());
            sendResponse(400, AccountErrorHandler.handleException(de));
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Unexpected error in POST: ' + e.getMessage());
            sendResponse(500, AccountErrorHandler.handleException(e));
        }
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
        // PATCH semantics are identical to PUT in this service
        handlePut();
    }

    @HttpDelete
    global static void handleDelete() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            String accountId = extractId(req.requestURI);
            Boolean hardDelete = req.params.get('hard_delete') != null ? Boolean.valueOf(req.params.get('hard_delete')) : false;

            AccountResponseWrapper response = AccountController.deleteAccount(accountId, hardDelete);
            sendResponse(response.success ? 204 : 404, response);
        } catch (DmlException de) {
            System.debug(LoggingLevel.ERROR, 'DML error in DELETE: ' + de.getMessage());
            sendResponse(400, AccountErrorHandler.handleException(de));
        } catch (JSONException je) {
            System.debug(LoggingLevel.ERROR, 'JSON error in DELETE: ' + je.getMessage());
            sendResponse(400, AccountErrorHandler.handleException(je));
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Unexpected error in DELETE: ' + e.getMessage());
            sendResponse(500, AccountErrorHandler.handleException(e));
        }
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
        // first parse untyped to verify structure
        Map<String, Object> data;
        try {
            data = (Map<String, Object>) JSON.deserializeUntyped(json);
        } catch (Exception e) {
            // JSON malformed
            throw new JSONException('Invalid JSON: ' + e.getMessage());
        }

        Account acct = new Account();
        for (String key : data.keySet()) {
            Object value = data.get(key);
            if (value == null) continue;

            // convert camelCase / lower-case key to Salesforce API field name
            String fieldName = key;
            if (fieldName.length() > 0) {
                fieldName = fieldName.substring(0, 1).toUpperCase() + fieldName.substring(1);
            }

            try {
                acct.put(fieldName, value);
            } catch (Exception ignore) {
                // ignore unknown or non-writable fields
            }
        }
        return acct;
    }

    @TestVisible
    private static String extractId(String uri) {
        if (String.isBlank(uri)) {
            return null;
        }
        List<String> parts = uri.split('/');
        // expecting /services/apexrest/accounts/{id}
        if (parts.size() >= 5) {
            String candidate = parts[4];
            if (candidate != null && candidate.matches('[a-zA-Z0-9]{15,18}')) {
                return candidate;
            }
        }
        return null;
    }
}


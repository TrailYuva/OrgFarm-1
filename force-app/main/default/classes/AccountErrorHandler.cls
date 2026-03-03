public class AccountErrorHandler {
    public static AccountResponseWrapper handleValidationError(String fieldName, String message) {
        AccountResponseWrapper resp = new AccountResponseWrapper();
        resp.success = false;
        resp.errors.add(new AccountResponseWrapper.ErrorDetail('INVALID_FIELD', message, fieldName));
        return resp;
    }

    public static AccountResponseWrapper handleMissingRequiredField(String fieldName) {
        AccountResponseWrapper resp = new AccountResponseWrapper();
        resp.success = false;
        resp.errors.add(new AccountResponseWrapper.ErrorDetail('MISSING_REQUIRED_FIELD', 'Field \'"' + fieldName + '"\' is required', fieldName));
        return resp;
    }

    public static AccountResponseWrapper handleRecordNotFound(String recordId) {
        AccountResponseWrapper resp = new AccountResponseWrapper();
        resp.success = false;
        resp.errors.add(new AccountResponseWrapper.ErrorDetail('RESOURCE_NOT_FOUND', 'Account with ID \'"' + recordId + '"\' not found', 'id'));
        return resp;
    }

    public static AccountResponseWrapper handlePermissionError(String operation) {
        AccountResponseWrapper resp = new AccountResponseWrapper();
        resp.success = false;
        resp.errors.add(new AccountResponseWrapper.ErrorDetail('PERMISSION_DENIED', 'You do not have permission to ' + operation + ' accounts', null, 'Contact your administrator to request access'));
        return resp;
    }

    public static AccountResponseWrapper handleDuplicateRecord(String fieldName, String fieldValue) {
        AccountResponseWrapper resp = new AccountResponseWrapper();
        resp.success = false;
        resp.errors.add(new AccountResponseWrapper.ErrorDetail('DUPLICATE_RECORD', 'Account with ' + fieldName + '\'"' + fieldValue + '\'" already exists', fieldName, 'Please use a unique value or retrieve the existing record'));
        return resp;
    }

    public static AccountResponseWrapper handleConcurrentModification(String recordId) {
        AccountResponseWrapper resp = new AccountResponseWrapper();
        resp.success = false;
        resp.errors.add(new AccountResponseWrapper.ErrorDetail('CONCURRENT_MODIFICATION', 'Record has been updated by another user', 'id', 'Please fetch the latest version and retry'));
        return resp;
    }

    public static AccountResponseWrapper handleException(Exception ex) {
        AccountResponseWrapper resp = new AccountResponseWrapper();
        resp.success = false;
        String errorDetails = 'Please contact support with request ID: ' + resp.requestId;
        System.debug(LoggingLevel.ERROR, 'API Exception: ' + ex.getMessage() + '\n' + ex.getStackTraceString());
        resp.errors.add(new AccountResponseWrapper.ErrorDetail('INTERNAL_SERVER_ERROR', 'An unexpected error occurred', null, errorDetails));
        return resp;
    }
}

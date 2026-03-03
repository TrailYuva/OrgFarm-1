@IsTest
private class AccountErrorHandlerTest {
    @IsTest static void testErrorResponses() {
        AccountResponseWrapper resp;
        resp = AccountErrorHandler.handleValidationError('name','invalid');
        System.assert(!resp.success);
        System.assertEquals('INVALID_FIELD', resp.errors[0].code);

        resp = AccountErrorHandler.handleMissingRequiredField('billingCountry');
        System.assertEquals('MISSING_REQUIRED_FIELD', resp.errors[0].code);

        resp = AccountErrorHandler.handleRecordNotFound('001xxx');
        System.assertEquals('RESOURCE_NOT_FOUND', resp.errors[0].code);

        resp = AccountErrorHandler.handlePermissionError('delete');
        System.assertEquals('PERMISSION_DENIED', resp.errors[0].code);

        resp = AccountErrorHandler.handleDuplicateRecord('name','Acme');
        System.assertEquals('DUPLICATE_RECORD', resp.errors[0].code);

        resp = AccountErrorHandler.handleConcurrentModification('001xxx');
        System.assertEquals('CONCURRENT_MODIFICATION', resp.errors[0].code);

        // Salesforce sometimes complains about instantiating the base Exception type during deployment.
        // Use a concrete subclass to avoid the "Type cannot be constructed: Exception" error.
        Exception ex = new System.DmlException('test');
        resp = AccountErrorHandler.handleException(ex);
        System.assertEquals('INTERNAL_SERVER_ERROR', resp.errors[0].code);
    }
}

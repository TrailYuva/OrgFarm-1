@IsTest
private class AccountControllerTest {
    @IsTest static void testCreateGetUpdateDelete() {
        // Create
        Account a = new Account(Name = 'TestCo', BillingCountry = 'United States');
        Test.startTest();
        AccountResponseWrapper createResp = AccountController.createAccount(a);
        Test.stopTest();
        System.assert(createResp.success, 'Create should succeed: ' + JSON.serialize(createResp));
        String acctId = (String)((Map<String,Object>)createResp.data).get('id');
        System.assertNotEquals(null, acctId);

        // Get
        AccountResponseWrapper getResp = AccountController.getAccount(acctId, null);
        System.assert(getResp.success, 'Get should succeed');
        Map<String,Object> got = (Map<String,Object>) getResp.data;
        System.assertEquals('TestCo', (String)got.get('name'));

        // Update
        Account upd = new Account(Phone = '+1-555-9999');
        AccountResponseWrapper updateResp = AccountController.updateAccount(acctId, upd);
        System.assert(updateResp.success, 'Update should succeed: ' + JSON.serialize(updateResp));

        // Delete via REST to exercise handler
        RestRequest delReq = new RestRequest();
        delReq.requestURI = '/services/apexrest/accounts/' + acctId;
        RestContext.request = delReq;
        RestContext.response = new RestResponse();
        AccountRestService.handleDelete();
        System.assertEquals(200, RestContext.response.statusCode);
        Map<String,Object> respBody = (Map<String,Object>) JSON.deserializeUntyped(RestContext.response.responseBody.toString());
        System.assertEquals(true, respBody.get('success'));
        System.assertEquals('Account deleted successfully', respBody.get('message'));

        // verify controller method also works when record has been removed
        AccountResponseWrapper deleteResp = AccountController.deleteAccount(acctId, false);
        System.assert(!deleteResp.success, 'Deleting again should fail');
        System.assertEquals('RESOURCE_NOT_FOUND', deleteResp.errors[0].code);
    }

    @IsTest static void testExtractId_and_encodedIds() {
        String baseId = '001gL00000hKtnbQAC';
        // standard forms
        System.assertEquals(baseId,
            AccountRestService.extractId('/services/apexrest/accounts/' + baseId));
        System.assertEquals(baseId,
            AccountRestService.extractId('/services/apexrest/accounts/' + baseId + '/'));
        System.assertEquals(baseId,
            AccountRestService.extractId('/services/apexrest/accounts/' + baseId + '?foo=bar'));
        // encoded id segments should still yield clean id
        String encoded = EncodingUtil.urlEncode(baseId + ' ', 'UTF-8');
        // "baseId%20" becomes candidate; decoding and stripping should recover id
        System.assertEquals(baseId,
            AccountRestService.extractId('/services/apexrest/accounts/' + encoded));

        // invalid/missing URI returns null
        System.assertEquals(null, AccountRestService.extractId(''));
        System.assertEquals(null, AccountRestService.extractId(null));
    }

    @IsTest static void testRestServicePutHandlesEncodedUri() {
        // create an account to update
        Account a = new Account(Name='RestTest', BillingCountry='Canada');
        insert a;
        String acctId = a.Id;

        // build a request URI with a percent-encoded trailing space to mimic
        // problematic clients
        String uri = '/services/apexrest/accounts/' + EncodingUtil.urlEncode(acctId + ' ', 'UTF-8');

        RestRequest req = new RestRequest();
        req.requestURI = uri;
        Account upd = new Account(Phone = '+1-800-1234');
        req.requestBody = Blob.valueOf(JSON.serialize(upd));
        RestContext.request = req;
        RestContext.response = new RestResponse();

        // call handler directly
        AccountRestService.handlePut();
        // should succeed and return 200
        System.assertEquals(200, RestContext.response.statusCode,
            'Expected successful update with encoded URI');
    }
}

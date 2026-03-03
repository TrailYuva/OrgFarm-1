@IsTest
private class AccountRestServiceTest {
    @IsTest static void testCrudViaRest() {
        // prepare request and response
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        // create
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/accounts';
        req.addHeader('Content-Type','application/json');
        req.requestBody = Blob.valueOf('{"name":"RestCo","billingCountry":"USA"}');
        AccountRestService.handlePost();
        System.debug('POST status=' + res.statusCode + ' body=' + res.responseBody.toString());
        AccountResponseWrapper createResp = (AccountResponseWrapper) JSON.deserialize(res.responseBody.toString(), AccountResponseWrapper.class);
        System.assert(createResp.success, 'Create response was not marked success; errors: ' + JSON.serialize(createResp.errors) + ' raw payload: ' + res.responseBody.toString());
        System.assertEquals(201, res.statusCode, 'Expected HTTP 201 for create; got ' + res.statusCode + ' payload: ' + res.responseBody.toString());
        String acctId = (String)((Map<String,Object>)createResp.data).get('id');
        System.assertNotEquals(null, acctId);

        // get single
        req = new RestRequest(); res = new RestResponse();
        RestContext.request = req; RestContext.response = res;
        req.httpMethod='GET';
        req.requestURI = '/services/apexrest/accounts/' + acctId;
        AccountRestService.handleGet();
        System.assertEquals(200, res.statusCode);
        AccountResponseWrapper getResp = (AccountResponseWrapper) JSON.deserialize(res.responseBody.toString(), AccountResponseWrapper.class);
        System.assert(getResp.success);
        System.assertEquals('RestCo', ((Map<String,Object>)getResp.data).get('name'));

        // update via PUT
        req = new RestRequest(); res = new RestResponse();
        RestContext.request=req;RestContext.response=res;
        req.httpMethod='PUT';
        req.requestURI = '/services/apexrest/accounts/' + acctId;
        req.requestBody = Blob.valueOf('{"phone":"+1-555-1234"}');
        AccountRestService.handlePut();
        System.assertEquals(200, res.statusCode);
        AccountResponseWrapper updResp = (AccountResponseWrapper) JSON.deserialize(res.responseBody.toString(), AccountResponseWrapper.class);
        System.assert(updResp.success);

        // delete
        req = new RestRequest(); res = new RestResponse();
        RestContext.request=req;RestContext.response=res;
        req.httpMethod='DELETE';
        req.requestURI = '/services/apexrest/accounts/' + acctId;
        AccountRestService.handleDelete();
        System.assertEquals(204, res.statusCode);
    }

    @IsTest static void testParseAccountHelper() {
        String json = '{"name":"RestCo","billingCountry":"USA"}';
        Account parsed = AccountRestService.parseAccount(json);
        System.assertEquals('RestCo', parsed.Name, 'Name should be mapped');
        System.assertEquals('USA', parsed.BillingCountry, 'BillingCountry should be mapped');
    }
}

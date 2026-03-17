@IsTest
private class AccountRestServiceTest2 {
    @IsTest static void debugCrudViaRest() {
        // similar to original but simplified to isolate POST
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/accounts';
        req.addHeader('Content-Type','application/json');
        req.requestBody = Blob.valueOf('{"name":"RestCo","billingCountry":"USA"}');

        AccountRestService.handlePost();

        // capture status
        Integer status = res.statusCode;
        String body = res.responseBody.toString();
        String err = AccountRestService.lastPostError;

        // artificially compare body to constant to surface it
        System.assertEquals('dummy', body);
    }
}

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

        // Delete
        AccountResponseWrapper deleteResp = AccountController.deleteAccount(acctId, false);
        System.assert(deleteResp.success, 'Delete should succeed: ' + JSON.serialize(deleteResp));
    }
}

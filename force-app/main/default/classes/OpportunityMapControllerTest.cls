@isTest
public class OpportunityMapControllerTest {
    @TestSetup
    static void makeData() {
        // Create test Accounts with Billing Geolocation, then link Opportunities
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i,
                BillingStreet = 'Street ' + i,
                BillingCity = 'Chennai',
                BillingState = 'Tamil Nadu',
                BillingPostalCode = '600001',
                BillingCountry = 'India',
                BillingLatitude = 13.0827 + (i * 0.01),
                BillingLongitude = 80.2707 + (i * 0.01)
            ));
        }
        insert accounts;

        List<Opportunity> opps = new List<Opportunity>();
        for (Account acct : accounts) {
            opps.add(new Opportunity(
                Name = 'Test Opportunity ' + acct.Name,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                AccountId = acct.Id
            ));
        }
        insert opps;
    }

    @isTest
    static void testGetOpportunitiesByAddress_Success() {
        Test.startTest();
        List<Opportunity> result = OpportunityMapController.getOpportunitiesByAddress('Chennai', 10);
        Test.stopTest();

        System.assert(result.size() > 0, 'Should return opportunities for the search term');
        for (Opportunity opp : result) {
            System.assertNotEquals(null, opp.Account.BillingLatitude, 'Latitude should not be null');
            System.assertNotEquals(null, opp.Account.BillingLongitude, 'Longitude should not be null');
        }
    }

    @isTest
    static void testGetOpportunitiesByAddress_NoResults() {
        Test.startTest();
        List<Opportunity> result = OpportunityMapController.getOpportunitiesByAddress('NoSuchPlace', 10);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return no opportunities for unmatched search term');
    }
}
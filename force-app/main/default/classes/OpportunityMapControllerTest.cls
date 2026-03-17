@isTest
public class OpportunityMapControllerTest {
    @TestSetup
    static void makeData() {
        // Create test Opportunities with BillingAddress
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 5; i++) {
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity ' + i,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                BillingStreet = 'Street ' + i,
                BillingCity = 'Chennai',
                BillingState = 'Tamil Nadu',
                BillingPostalCode = '600001',
                BillingCountry = 'India',
                BillingLatitude = 13.0827 + (i * 0.01), // Slight variations
                BillingLongitude = 80.2707 + (i * 0.01)
            );
            opps.add(opp);
        }
        insert opps;
    }

    @isTest
    static void testGetOpportunitiesWithinRadius_Success() {
        Test.startTest();
        List<Opportunity> result = OpportunityMapController.getOpportunitiesWithinRadius(13.0827, 80.2707, 10);
        Test.stopTest();

        System.assert(result.size() > 0, 'Should return opportunities within radius');
        for (Opportunity opp : result) {
            System.assertNotEquals(null, opp.BillingLatitude, 'Latitude should not be null');
            System.assertNotEquals(null, opp.BillingLongitude, 'Longitude should not be null');
        }
    }

    @isTest
    static void testGetOpportunitiesWithinRadius_NoResults() {
        Test.startTest();
        List<Opportunity> result = OpportunityMapController.getOpportunitiesWithinRadius(0, 0, 1);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return no opportunities outside radius');
    }

    @isTest
    static void testGetOpportunitiesWithinRadius_Bulk() {
        // Test with more data if needed, but setup has 5
        Test.startTest();
        List<Opportunity> result = OpportunityMapController.getOpportunitiesWithinRadius(13.0827, 80.2707, 100);
        Test.stopTest();

        System.assert(result.size() >= 5, 'Should return all test opportunities');
    }
}
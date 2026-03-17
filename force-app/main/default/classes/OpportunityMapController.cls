public with sharing class OpportunityMapController {
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getOpportunitiesWithinRadius(Decimal lat, Decimal lng, Decimal radiusKm) {
        String query = 'SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude FROM Opportunity WHERE DISTANCE(BillingAddress, GEOLOCATION(:lat, :lng), \'km\') < :radiusKm AND BillingLatitude != null AND BillingLongitude != null';
        return Database.query(query);
    }
}
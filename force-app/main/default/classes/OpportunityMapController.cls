public with sharing class OpportunityMapController {
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getOpportunitiesByAddress(String searchTerm, Decimal radiusKm) {
        if (String.isBlank(searchTerm)) {
            return new List<Opportunity>();
        }

        String likeTerm = '%' + String.escapeSingleQuotes(searchTerm.trim()) + '%';

        // Find a base Account location from billing address fields
        Account baseAccount = [
            SELECT BillingLatitude, BillingLongitude
            FROM Account
            WHERE (BillingStreet LIKE :likeTerm OR BillingCity LIKE :likeTerm OR BillingState LIKE :likeTerm OR BillingPostalCode LIKE :likeTerm OR BillingCountry LIKE :likeTerm)
                AND BillingLatitude != null
                AND BillingLongitude != null
            LIMIT 1
        ];

        if (baseAccount == null || baseAccount.BillingLatitude == null || baseAccount.BillingLongitude == null) {
            return new List<Opportunity>();
        }

        // Find accounts within radius of the base location
        List<Account> nearbyAccounts = [
            SELECT Id
            FROM Account
            WHERE DISTANCE(BillingAddress, GEOLOCATION(:baseAccount.BillingLatitude, :baseAccount.BillingLongitude), 'km') < :radiusKm
                AND BillingLatitude != null
                AND BillingLongitude != null
        ];

        if (nearbyAccounts.isEmpty()) {
            return new List<Opportunity>();
        }

        Set<Id> accountIds = new Set<Id>();
        for (Account acct : nearbyAccounts) {
            accountIds.add(acct.Id);
        }

        // Return Opportunities where the Account is within the radius
        return [
            SELECT Id, Name, AccountId, Account.BillingStreet, Account.BillingCity, Account.BillingState,
                   Account.BillingPostalCode, Account.BillingCountry, Account.BillingLatitude, Account.BillingLongitude
            FROM Opportunity
            WHERE AccountId IN :accountIds
            AND Account.BillingLatitude != null
            AND Account.BillingLongitude != null
        ];
    }
}
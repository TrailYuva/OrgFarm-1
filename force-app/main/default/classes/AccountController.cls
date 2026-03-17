public class AccountController {
    public static AccountResponseWrapper createAccount(Account accountData) {
        AccountResponseWrapper resp = new AccountResponseWrapper();
        try {
            AccountResponseWrapper validation = AccountValidator.validateCreateRequest(accountData);
            if (!validation.success) return validation;

            insert accountData;

            resp.success = true;
            Map<String, Object> dataMap = new Map<String, Object>();
            dataMap.put('id', accountData.Id);
            dataMap.put('name', accountData.Name);
            if (accountData.CreatedDate != null) dataMap.put('createdDate', accountData.CreatedDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
            if (accountData.LastModifiedDate != null) dataMap.put('lastModifiedDate', accountData.LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
            resp.data = dataMap;
            resp.message = 'Account created successfully';
            return resp;
        } catch (DmlException dmlEx) {
            return AccountErrorHandler.handleException(dmlEx); 
        } catch (Exception ex) {
            return AccountErrorHandler.handleException(ex);
        }
    }

    public static AccountResponseWrapper getAccount(String accountId, String fields) {
        AccountResponseWrapper resp = new AccountResponseWrapper();
        try {
            if (String.isBlank(accountId)) return AccountErrorHandler.handleRecordNotFound(accountId);

            String queryFields = String.isBlank(fields) ? 'Id, Name, Phone, Website, Industry, AnnualRevenue, NumberOfEmployees, BillingStreet, BillingCity, BillingStateCode, BillingPostalCode, BillingCountry, ShippingStreet, ShippingCity, ShippingStateCode, ShippingPostalCode, ShippingCountry, Description, CreatedDate, LastModifiedDate, CreatedById' : fields;
            String safeId = String.escapeSingleQuotes(accountId);
            String query = 'SELECT ' + queryFields + ' FROM Account WHERE Id = \'' + safeId + '\' LIMIT 1';
            List<Account> accounts = Database.query(query);
            if (accounts.isEmpty()) return AccountErrorHandler.handleRecordNotFound(accountId);

            Account acc = accounts[0];
            resp.success = true;
            resp.data = convertAccountToMap(acc);
            return resp;
        } catch (QueryException qEx) {
            return AccountErrorHandler.handleException(qEx);
        } catch (Exception ex) {
            return AccountErrorHandler.handleException(ex);
        }
    }

    public static AccountResponseWrapper getAccounts(Integer limitValue, Integer offsetValue, String sortBy, String sortOrder, String search, String industry, String createdAfter, String createdBefore, String fields) {
        AccountResponseWrapper resp = new AccountResponseWrapper();
        try {
            if (limitValue == null || limitValue <= 0) limitValue = 100;
            if (limitValue > 10000) limitValue = 10000;
            if (offsetValue == null || offsetValue < 0) offsetValue = 0;
            if (String.isBlank(sortBy)) sortBy = 'LastModifiedDate';
            if (String.isBlank(sortOrder)) sortOrder = 'DESC';

            String queryFields = String.isBlank(fields) ? 'Id, Name, Phone, Website, Industry, AnnualRevenue, NumberOfEmployees, BillingStreet, BillingCity, BillingStateCode, BillingPostalCode, BillingCountry, ShippingStreet, ShippingCity, ShippingStateCode, ShippingPostalCode, ShippingCountry, Description, CreatedDate, LastModifiedDate, CreatedById' : fields;
            String whereClause = 'WHERE Id != null';

            if (String.isNotBlank(search)) {
                String searchTerm = '%' + String.escapeSingleQuotes(search) + '%';
                whereClause += ' AND (Name LIKE \'' + searchTerm + '\' OR Website LIKE \'' + searchTerm + '\')';
            }
            if (String.isNotBlank(industry)) {
                whereClause += ' AND Industry = \'' + String.escapeSingleQuotes(industry) + '\'';
            }
            if (String.isNotBlank(createdAfter)) {
                try {
                    Datetime ca = Datetime.valueOfGmt(createdAfter);
                    whereClause += ' AND CreatedDate >= ' + ca.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
                } catch (Exception e) {
                    return AccountErrorHandler.handleValidationError('createdAfter', 'Invalid datetime format for createdAfter');
                }
            }
            if (String.isNotBlank(createdBefore)) {
                try {
                    Datetime cb = Datetime.valueOfGmt(createdBefore);
                    whereClause += ' AND CreatedDate <= ' + cb.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
                } catch (Exception e) {
                    return AccountErrorHandler.handleValidationError('createdBefore', 'Invalid datetime format for createdBefore');
                }
            }

            String countQuery = 'SELECT COUNT() cnt FROM Account ' + whereClause;
            Integer totalRecords = 0;
            try {
                List<AggregateResult> cnt = Database.query(countQuery);
                if (!cnt.isEmpty()) totalRecords = (Integer) cnt[0].get('expr0');
            } catch (Exception e) {
                totalRecords = 0;
            }

            String orderByClause = 'ORDER BY ' + sortBy + ' ' + sortOrder;
            String query = 'SELECT ' + queryFields + ' FROM Account ' + whereClause + ' ' + orderByClause + ' LIMIT ' + limitValue + ' OFFSET ' + offsetValue;
            List<Account> accounts = Database.query(query);

            List<Object> accountList = new List<Object>();
            for (Account a : accounts) accountList.add(convertAccountToMap(a));

            resp.success = true;
            resp.data = accountList;
            resp.pagination = new Map<String, Object>{'totalRecords' => totalRecords, 'returnedRecords' => accounts.size(), 'offset' => offsetValue, 'limit' => limitValue, 'hasMore' => (offsetValue + limitValue) < totalRecords};
            return resp;
        } catch (QueryException qEx) {
            return AccountErrorHandler.handleException(qEx);
        } catch (Exception ex) {
            return AccountErrorHandler.handleException(ex);
        }
    }

    public static AccountResponseWrapper updateAccount(String accountId, Account updates) {
        AccountResponseWrapper resp = new AccountResponseWrapper();
        try {
            AccountResponseWrapper validation = AccountValidator.validateUpdateRequest(accountId, updates);
            if (!validation.success) return validation;

            Account existing = [SELECT Id FROM Account WHERE Id = :accountId LIMIT 1];
            if (existing == null) return AccountErrorHandler.handleRecordNotFound(accountId);

            updates.Id = accountId;
            update updates;

            // Refresh updated fields
            Account refreshed = [SELECT Id, LastModifiedDate FROM Account WHERE Id = :accountId LIMIT 1];
            resp.success = true;
            resp.data = new Map<String, Object>{'id' => refreshed.Id, 'lastModifiedDate' => refreshed.LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')};
            resp.message = 'Account updated successfully';
            return resp;
        } catch (QueryException qEx) {
            if (qEx.getMessage().contains('List has no rows')) return AccountErrorHandler.handleRecordNotFound(accountId);
            return AccountErrorHandler.handleException(qEx);
        } catch (DmlException dmlEx) {
            return AccountErrorHandler.handleException(dmlEx);
        } catch (Exception ex) {
            return AccountErrorHandler.handleException(ex);
        }
    }

    public static AccountResponseWrapper deleteAccount(String accountId, Boolean hardDelete) {
        AccountResponseWrapper resp = new AccountResponseWrapper();
        try {
            AccountResponseWrapper validation = AccountValidator.validateDeleteRequest(accountId);
            if (!validation.success) return validation;

            Account acc = [SELECT Id FROM Account WHERE Id = :accountId LIMIT 1];
            if (acc == null) return AccountErrorHandler.handleRecordNotFound(accountId);

            if (hardDelete == true) {
                Database.delete(accountId, true);
            } else {
                delete acc;
            }

            resp.success = true;
            resp.message = 'Account deleted successfully';
            return resp;
        } catch (QueryException qEx) {
            if (qEx.getMessage().contains('List has no rows')) return AccountErrorHandler.handleRecordNotFound(accountId);
            return AccountErrorHandler.handleException(qEx);
        } catch (DmlException dmlEx) {
            return AccountErrorHandler.handleException(dmlEx);
        } catch (Exception ex) {
            return AccountErrorHandler.handleException(ex);
        }
    }

    private static Map<String, Object> convertAccountToMap(Account acc) {
        Map<String, Object> m = new Map<String, Object>();
        m.put('id', acc.get('Id'));
        m.put('name', acc.get('Name'));
        m.put('phone', acc.get('Phone'));
        m.put('website', acc.get('Website'));
        m.put('industry', acc.get('Industry'));
        m.put('annualRevenue', acc.get('AnnualRevenue'));
        m.put('numberOfEmployees', acc.get('NumberOfEmployees'));
        m.put('billingStreet', acc.get('BillingStreet'));
        m.put('billingCity', acc.get('BillingCity'));
        m.put('billingStateCode', acc.get('BillingStateCode'));
        m.put('billingPostalCode', acc.get('BillingPostalCode'));
        m.put('billingCountry', acc.get('BillingCountry'));
        m.put('shippingStreet', acc.get('ShippingStreet'));
        m.put('shippingCity', acc.get('ShippingCity'));
        m.put('shippingStateCode', acc.get('ShippingStateCode'));
        m.put('shippingPostalCode', acc.get('ShippingPostalCode'));
        m.put('shippingCountry', acc.get('ShippingCountry'));
        m.put('description', acc.get('Description'));
        Object cd = acc.get('CreatedDate');
        m.put('createdDate', cd != null ? ((Datetime)cd).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') : null);
        Object lmd = acc.get('LastModifiedDate');
        m.put('lastModifiedDate', lmd != null ? ((Datetime)lmd).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') : null);
        m.put('createdById', acc.get('CreatedById'));
        return m;
    }
}

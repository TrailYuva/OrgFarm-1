public class AccountValidator {
    public static AccountResponseWrapper validateCreateRequest(Account accountData) {
        AccountResponseWrapper resp = new AccountResponseWrapper();
        resp.success = true;

        if (accountData == null) {
            resp.success = false;
            resp.errors.add(new AccountResponseWrapper.ErrorDetail('INVALID_FIELD', 'Request body is empty'));
            return resp;
        }

        if (String.isBlank(accountData.Name)) {
            resp.success = false;
            resp.errors.add(new AccountResponseWrapper.ErrorDetail('MISSING_REQUIRED_FIELD', 'Field \'name\' is required', 'name'));
        }

        if (String.isBlank(accountData.BillingCountry)) {
            resp.success = false;
            resp.errors.add(new AccountResponseWrapper.ErrorDetail('MISSING_REQUIRED_FIELD', 'Field \'billingCountry\' is required', 'billingCountry'));
        }

        if (accountData.Name != null && accountData.Name.length() > 255) {
            resp.success = false;
            resp.errors.add(new AccountResponseWrapper.ErrorDetail('FIELD_TOO_LONG', 'Field \'name\' exceeds maximum length of 255 characters', 'name'));
        }

        if (String.isNotBlank(accountData.Phone)) {
            if (!isValidPhone(accountData.Phone)) {
                resp.success = false;
                resp.errors.add(new AccountResponseWrapper.ErrorDetail('INVALID_FIELD_FORMAT', 'Field \'phone\' has invalid format', 'phone', 'Example: +1-555-0100'));
            }
        }

        if (String.isNotBlank(accountData.Website)) {
            if (!isValidUrl(accountData.Website)) {
                resp.success = false;
                resp.errors.add(new AccountResponseWrapper.ErrorDetail('INVALID_FIELD_FORMAT', 'Field \'website\' has invalid format', 'website', 'Example: https://example.com'));
            }
        }

        if (accountData.AnnualRevenue != null && accountData.AnnualRevenue < 0) {
            resp.success = false;
            resp.errors.add(new AccountResponseWrapper.ErrorDetail('INVALID_FIELD_VALUE', 'Field \'annualRevenue\' must be a positive number', 'annualRevenue'));
        }

        if (accountData.NumberOfEmployees != null && accountData.NumberOfEmployees < 0) {
            resp.success = false;
            resp.errors.add(new AccountResponseWrapper.ErrorDetail('INVALID_FIELD_VALUE', 'Field \'numberOfEmployees\' must be a positive number', 'numberOfEmployees'));
        }

        if (!Schema.sObjectType.Account.isCreateable()) {
            resp.success = false;
            resp.errors.add(new AccountResponseWrapper.ErrorDetail('PERMISSION_DENIED', 'You do not have permission to create accounts', null, 'Contact your administrator to request access'));
        }

        return resp;
    }

    public static AccountResponseWrapper validateUpdateRequest(String accountId, Account updates) {
        AccountResponseWrapper resp = new AccountResponseWrapper();
        resp.success = true;

        if (String.isBlank(accountId) || (accountId.length() != 15 && accountId.length() != 18)) {
            resp.success = false;
            resp.errors.add(new AccountResponseWrapper.ErrorDetail('INVALID_FIELD_VALUE', 'Invalid account ID format', 'id'));
            return resp;
        }

        if (updates == null) {
            resp.success = false;
            resp.errors.add(new AccountResponseWrapper.ErrorDetail('INVALID_FIELD', 'Request body is empty'));
            return resp;
        }

        if (String.isNotBlank(updates.Phone) && !isValidPhone(updates.Phone)) {
            resp.success = false;
            resp.errors.add(new AccountResponseWrapper.ErrorDetail('INVALID_FIELD_FORMAT', 'Field \'phone\' has invalid format', 'phone'));
        }

        if (!Schema.sObjectType.Account.isUpdateable()) {
            resp.success = false;
            resp.errors.add(new AccountResponseWrapper.ErrorDetail('PERMISSION_DENIED', 'You do not have permission to update accounts', null, 'Contact your administrator to request access'));
        }

        return resp;
    }

    public static AccountResponseWrapper validateDeleteRequest(String accountId) {
        AccountResponseWrapper resp = new AccountResponseWrapper();
        resp.success = true;

        if (String.isBlank(accountId) || (accountId.length() != 15 && accountId.length() != 18)) {
            resp.success = false;
            resp.errors.add(new AccountResponseWrapper.ErrorDetail('INVALID_FIELD_VALUE', 'Invalid account ID format', 'id'));
            return resp;
        }

        if (!Schema.sObjectType.Account.isDeletable()) {
            resp.success = false;
            resp.errors.add(new AccountResponseWrapper.ErrorDetail('PERMISSION_DENIED', 'You do not have permission to delete accounts', null, 'Contact your administrator to request access'));
        }

        return resp;
    }

    private static Boolean isValidPhone(String phone) {
        String phonePattern = '^[\\d\\s\\-()\\+]+$';
        // Apex doesn't support String.matches; use Pattern.matches instead
        return phone != null && Pattern.matches(phonePattern, phone) && phone.length() >= 7 && phone.length() <= 40;
    }

    private static Boolean isValidUrl(String url) {
        String urlPattern = '^(https?://).+';
        // use Pattern.matches for regex evaluation
        return url != null && Pattern.matches(urlPattern, url);
    }
}

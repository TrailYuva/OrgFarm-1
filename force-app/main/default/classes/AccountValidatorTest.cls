@IsTest
private class AccountValidatorTest {
    @IsTest static void testValidationSuccessAndFailures() {
        // success case
        Account a = new Account(Name='ValidCo', BillingCountry='USA');
        AccountResponseWrapper res = AccountValidator.validateCreateRequest(a);
        System.assert(res.success, 'Expected validation to pass but it failed: ' + JSON.serialize(res));

        // missing name
        Account b = new Account(BillingCountry='USA');
        res = AccountValidator.validateCreateRequest(b);
        System.assert(!res.success);
        System.assertEquals('MISSING_REQUIRED_FIELD', res.errors[0].code);

        // invalid phone
        Account c = new Account(Name='x', BillingCountry='USA', Phone='bad_phone');
        res = AccountValidator.validateCreateRequest(c);
        System.assert(!res.success);
        Boolean foundPhoneError = false;
        for (AccountResponseWrapper.ErrorDetail err : res.errors) if (err.field=='phone') foundPhoneError=true;
        System.assert(foundPhoneError);

        // long name
        Account d = new Account(Name=String.valueOf('a').repeat(300), BillingCountry='USA');
        res = AccountValidator.validateCreateRequest(d);
        System.assert(!res.success);
        System.assert(res.errors[0].code=='FIELD_TOO_LONG');
    }

    @IsTest static void testUpdateAndDeleteValidators() {
        AccountResponseWrapper res;
        // invalid id
        res = AccountValidator.validateUpdateRequest(null, new Account());
        System.assert(!res.success);
        res = AccountValidator.validateDeleteRequest('abc');
        System.assert(!res.success);

        // trimmed id should be accepted
        String validId = '001gL00000hKtnbQAC';
        res = AccountValidator.validateUpdateRequest('  ' + validId + '\n', new Account());
        System.assert(res.success, 'Trimmed ID should pass validation');
        res = AccountValidator.validateDeleteRequest('\t' + validId + ' ');
        System.assert(res.success, 'Trimmed ID should pass delete validation');
    }
}

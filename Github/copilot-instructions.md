# GitHub Copilot Instructions – Salesforce Apex Development

## General Rules

- Always generate production-ready Apex code.
- Do not generate pseudo code.
- Do not leave TODO comments.
- Do not generate incomplete methods.
- Follow Salesforce best practices at all times.
- Avoid hardcoded IDs or environment-specific values.
- Use meaningful variable and method names.

---

## Apex Class Standards

- Use `with sharing` unless explicitly told otherwise.
- Use `global` only when required (e.g., REST APIs).
- Use `public` for internal classes.
- Avoid SOQL inside loops.
- Always use LIMIT in SOQL queries.
- Use bulk-safe patterns where applicable.
- Handle null checks properly.

---

## REST API Standards

When generating Apex REST classes:

- Use `@RestResource(urlMapping='/ResourceName/*')`
- Declare class as `global with sharing`
- Implement proper HTTP methods:
  - `@HttpGet`
  - `@HttpPost`
  - `@HttpPut`
  - `@HttpDelete`
- Always parse JSON using `JSON.deserializeUntyped`
- Use structured response wrapper classes
- Set `RestContext.response.statusCode` properly:
  - 200 → Success
  - 201 → Created
  - 400 → Bad Request
  - 404 → Not Found
  - 500 → Server Error
- Always use try-catch blocks
- Handle:
  - `DmlException`
  - `JSONException`
  - Generic `Exception`

---

## Error Handling Standards

- Always return meaningful error messages.
- Never expose internal stack traces in responses.
- Log errors using `System.debug(LoggingLevel.ERROR, ...)`
- Validate required fields before DML operations.
- Check record existence before update/delete.

---

## Security Rules

- Respect object-level and field-level security.
- Use `with sharing` by default.
- Do not bypass sharing unless explicitly instructed.
- Avoid exposing sensitive data in API responses.

---

## Test Class Standards

- Generate separate test classes.
- Minimum 75% code coverage.
- Use `Test.startTest()` and `Test.stopTest()`.
- Cover:
  - Success scenarios
  - Failure scenarios
  - Validation errors
- Avoid SeeAllData=true unless explicitly required.

---

## Code Quality Rules

- Keep methods small and focused.
- Avoid duplicated logic.
- Use helper methods when necessary.
- Keep response format consistent.
- Write readable and maintainable code.

---

## What Not To Do

- Do not generate triggers unless explicitly requested.
- Do not use future methods unnecessarily.
- Do not use deprecated Apex features.
- Do not mix business logic directly inside REST methods; use helper methods when possible.

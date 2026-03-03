# Account REST API - Database Schema & Domain Model

## Table of Contents
1. [Entity-Relationship Diagram](#entity-relationship-diagram)
2. [Account Object Structure](#account-object-structure)
3. [Field Specifications](#field-specifications)
4. [Data Type Reference](#data-type-reference)
5. [Validation Rules](#validation-rules)
6. [Custom Field Extensions](#custom-field-extensions)
7. [Related Object Relationships](#related-object-relationships)
8. [Index Strategy](#index-strategy)
9. [Data Integrity Constraints](#data-integrity-constraints)
10. [Migration Guide](#migration-guide)

---

## Entity-Relationship Diagram

### Account-Centric Data Model

```
┌─────────────────────────────────────────────────────┐
│                    USER (Creator)                   │
│  ┌─────────────┬──────────────────────┬────────┐  │
│  │ Id (PK)     │ Name                 │ Email  │  │
│  │ Profile     │ Permissions          │ Active │  │
│  └─────────────┴──────────────────────┴────────┘  │
└────────────────────┬────────────────────────────────┘
                     │ CreatedById (FK)
                     │
┌────────────────────▼────────────────────────────────┐
│                   ACCOUNT (Main)                    │
│  ┌────────────────────────────────────┐           │
│  │ PRIMARY KEY: Id                    │           │
│  │ UNIQUE: Name                       │           │
│  ├────────────────────────────────────┤           │
│  │ Core Fields                        │           │
│  │  • Id (18)                         │           │
│  │  • Name (255) [Required]           │           │
│  │  • Type (Picklist)                 │           │
│  │  • Industry (Picklist)             │           │
│  │  • Description (TextArea, 32000)   │           │
│  │  • Website (URL, 255)              │           │
│  │  • Phone (40)                      │           │
│  │  • Fax (40)                        │           │
│  │                                    │           │
│  │ Billing Address                    │           │
│  │  • BillingStreet (255)             │           │
│  │  • BillingCity (40)                │           │
│  │  • BillingStateCode (2)            │           │
│  │  • BillingPostalCode (20)          │           │
│  │  • BillingCountry (50) [Required]  │           │
│  │  • BillingLatitude (Decimal)       │           │
│  │  • BillingLongitude (Decimal)      │           │
│  │                                    │           │
│  │ Shipping Address                   │           │
│  │  • ShippingStreet (255)            │           │
│  │  • ShippingCity (40)               │           │
│  │  • ShippingStateCode (2)           │           │
│  │  • ShippingPostalCode (20)         │           │
│  │  • ShippingCountry (50)            │           │
│  │  • ShippingLatitude (Decimal)      │           │
│  │  • ShippingLongitude (Decimal)     │           │
│  │                                    │           │
│  │ Financial Information              │           │
│  │  • AnnualRevenue (Currency)        │           │
│  │  • NumberOfEmployees (Integer)     │           │
│  │  • Ownership (Picklist)            │           │
│  │                                    │           │
│  │ Audit Fields                       │           │
│  │  • CreatedDate (DateTime)          │           │
│  │  • CreatedById (FK → User)         │           │
│  │  • LastModifiedDate (DateTime)     │           │
│  │  • LastModifiedById (FK → User)    │           │
│  │  • SystemModStamp (DateTime)       │           │
│  │  • IsDeleted (Boolean)             │           │
│  └────────────────────────────────────┘           │
└────────────────────────────────────────────────────┘
                     △
        ┌────────────┼────────────┐
        │            │            │
        │ 1:N        │ 1:N        │ 1:N
        │            │            │
┌───────▼──────┐ ┌───▼─────────┐ ┌─▼─────────────┐
│   CONTACT    │ │ OPPORTUNITY │ │     ASSET     │
└──────────────┘ └─────────────┘ └───────────────┘

       1:N          1:N          1:N
        │            │            │
        └────────────┼────────────┘
                     │
            ┌────────▼─────────┐
            │ ACCOUNT TEAM     │
            │ (Team Members)   │
            └──────────────────┘
```

---

## Account Object Structure

### Detailed Field Organization

```
ACCOUNT Object
│
├─── IDENTIFICATION
│    ├─ Id (String[18], Read-only, Primary Key)
│    │   └─ Format: 15-char or 18-char Salesforce ID
│    │      Example: 0015g000008ZP7A or 0015g000008ZP7AAAW
│    │
│    └─ Name (String[255], Required, Unique)
│        └─ Max: 255 characters
│           Example: "Acme Corporation"
│
├─── CATEGORIZATION
│    ├─ Type (Picklist)
│    │   └─ Values: Prospect, Customer, Channel Partner
│    │
│    ├─ Industry (Picklist)
│    │   └─ Values: Agriculture, Apparel, Automotive, etc.
│    │
│    └─ Ownership (Picklist)
│        └─ Values: Public, Private, Subsidiary
│
├─── CONTACT INFORMATION
│    ├─ Phone (String[40])
│    │   └─ Format: Various formats accepted
│    │      Examples: "+1-555-0100", "(555) 0100", "5550100"
│    │
│    ├─ Fax (String[40])
│    │   └─ Same format as Phone
│    │
│    ├─ Website (URL[255])
│    │   └─ Format: Valid URL with protocol
│    │      Example: "https://www.acme.com"
│    │
│    ├─ Email (Email[255])
│    │   └─ Format: Valid email address
│    │      Example: "info@acme.com"
│    │
│    └─ Description (TextArea[32000])
│        └─ Max: 32,000 characters
│           Purpose: Long form description of business
│
├─── BILLING ADDRESS
│    ├─ BillingStreet (String[255])
│    │   └─ Street address line
│    │
│    ├─ BillingCity (String[40])
│    │   └─ City name
│    │
│    ├─ BillingStateCode (TextCode[2])
│    │   └─ State/Province code (ISO 3166-2)
│    │      Example: "CA" for California
│    │
│    ├─ BillingPostalCode (String[20])
│    │   └─ ZIP/Postal code
│    │
│    ├─ BillingCountry (String[50], Required)
│    │   └─ Country name (full name required)
│    │      Example: "United States", "Canada"
│    │
│    ├─ BillingLatitude (Decimal)
│    │   └─ Latitude coordinate
│    │      Format: -90.0 to +90.0
│    │
│    └─ BillingLongitude (Decimal)
│        └─ Longitude coordinate
│           Format: -180.0 to +180.0
│
├─── SHIPPING ADDRESS
│    ├─ ShippingStreet (String[255])
│    │   └─ Street address line
│    │
│    ├─ ShippingCity (String[40])
│    │   └─ City name
│    │
│    ├─ ShippingStateCode (TextCode[2])
│    │   └─ State/Province code
│    │
│    ├─ ShippingPostalCode (String[20])
│    │   └─ ZIP/Postal code
│    │
│    ├─ ShippingCountry (String[50])
│    │   └─ Country name
│    │
│    ├─ ShippingLatitude (Decimal)
│    │   └─ Latitude coordinate
│    │
│    └─ ShippingLongitude (Decimal)
│        └─ Longitude coordinate
│
├─── FINANCIAL INFORMATION
│    ├─ AnnualRevenue (Currency)
│    │   └─ Annual company revenue
│    │      Format: Currency (8 digits, 2 decimals)
│    │      Example: 5000000.00
│    │
│    └─ NumberOfEmployees (Integer)
│        └─ Total number of employees
│           Format: Whole number
│           Example: 150
│
└─── AUDIT & SYSTEM FIELDS (Read-only)
     ├─ CreatedDate (DateTime)
     │   └─ Record creation timestamp
     │      Format: ISO 8601 UTC
     │
     ├─ CreatedById (ID[18])
     │   └─ User who created record
     │      Foreign Key → User.Id
     │
     ├─ LastModifiedDate (DateTime)
     │   └─ Last modification timestamp
     │      Format: ISO 8601 UTC
     │
     ├─ LastModifiedById (ID[18])
     │   └─ User who last modified record
     │      Foreign Key → User.Id
     │
     ├─ SystemModStamp (DateTime)
     │   └─ System modification timestamp
     │      Format: ISO 8601 UTC
     │
     └─ IsDeleted (Boolean)
         └─ Soft delete flag
            Default: false
            Marks record for deletion
```

---

## Field Specifications

### Core Fields Detail

| Field Name | Data Type | Length | Required | CRUD | Searchable | Sortable | Unique | Notes |
|------------|-----------|--------|----------|------|-----------|----------|--------|-------|
| Id | ID | 18 | Yes | R | Yes | Yes | Yes | Primary Key |
| Name | String | 255 | **Yes** | CRU | Yes | Yes | Yes | Account name |
| Type | Picklist | - | No | CRU | Yes | Yes | No | Account type |
| Industry | Picklist | - | No | CRU | Yes | Yes | No | Industry category |
| Description | TextArea | 32000 | No | CRU | No | No | No | Long description |
| Phone | String | 40 | No | CRU | Yes | Yes | No | Phone number |
| Fax | String | 40 | No | CRU | Yes | Yes | No | Fax number |
| Website | String | 255 | No | CRU | Yes | Yes | No | Website URL |
| Email | Email | 255 | No | CRU | Yes | Yes | No | Email address |
| AnnualRevenue | Currency | - | No | CRU | Yes | Yes | No | Annual revenue |
| NumberOfEmployees | Integer | - | No | CRU | Yes | Yes | No | Employee count |
| Ownership | Picklist | - | No | CRU | Yes | Yes | No | Ownership type |
| BillingStreet | String | 255 | No | CRU | No | No | No | Street address |
| BillingCity | String | 40 | No | CRU | Yes | Yes | No | City |
| BillingStateCode | TextCode | 2 | No | CRU | Yes | Yes | No | State code |
| BillingPostalCode | String | 20 | No | CRU | Yes | Yes | No | Postal code |
| BillingCountry | String | 50 | **Yes** | CRU | Yes | Yes | No | Country |
| BillingLatitude | Decimal | - | No | CRU | Yes | Yes | No | Latitude |
| BillingLongitude | Decimal | - | No | CRU | Yes | Yes | No | Longitude |
| ShippingStreet | String | 255 | No | CRU | No | No | No | Street address |
| ShippingCity | String | 40 | No | CRU | Yes | Yes | No | City |
| ShippingStateCode | TextCode | 2 | No | CRU | Yes | Yes | No | State code |
| ShippingPostalCode | String | 20 | No | CRU | Yes | Yes | No | Postal code |
| ShippingCountry | String | 50 | No | CRU | Yes | Yes | No | Country |
| ShippingLatitude | Decimal | - | No | CRU | Yes | Yes | No | Latitude |
| ShippingLongitude | Decimal | - | No | CRU | Yes | Yes | No | Longitude |
| CreatedDate | DateTime | - | R | - | Yes | Yes | No | Creation time |
| CreatedById | ID | 18 | R | R | Yes | Yes | No | Creator user |
| LastModifiedDate | DateTime | - | R | - | Yes | Yes | No | Last change time |
| LastModifiedById | ID | 18 | R | R | Yes | Yes | No | Modifier user |
| SystemModStamp | DateTime | - | R | - | Yes | Yes | No | System timestamp |
| IsDeleted | Boolean | - | R | - | Yes | Yes | No | Soft delete flag |

### Picklist Values

#### Type Field
```
Prospect: Potential future customer
Customer: Active customer
Channel Partner: Distribution partner
Competitor: Competing company
Other: Other account types
```

#### Industry Field
```
Agriculture, Apparel, Automotive, Banking, Biotechnology, 
Chemicals, Communications, Construction, Consulting, Education, 
Electronics, Energy, Engineering, Entertainment, Finance, 
Food & Beverage, Government, Healthcare, Hospitality, 
Insurance, Machinery, Manufacturing, Media, Not For Profit, 
Other, Pharmacy, Real Estate, Retail, Shipping, Telecom, 
Transportation, Utilities
```

#### Ownership Field
```
Public: Public company
Private: Private company
Subsidiary: Subsidiary of another company
Other: Other ownership structure
```

---

## Data Type Reference

### Salesforce Data Types

| Type | Size | Format | Validation | Example |
|------|------|--------|-----------|---------|
| ID | 18 chars | Alphanumeric | Salesforce format | 0015g000008ZP7AAAW |
| String | Configurable | Text | Max length enforced | "Acme Corp" |
| TextArea | Up to 32KB | Multi-line text | Line breaks allowed | "Business description..." |
| Email | Max 255 | email@domain.com | RFC 5322 validation | "info@acme.com" |
| URL | Max 255 | https://example.com | Protocol required | "https://example.com" |
| Phone | Max 40 | Various formats | Characters: 0-9, +, -, (), space | "+1-555-0100" |
| Currency | 16,2 | Numeric (8.2) | Decimal places: 2 | 5000000.00 |
| Decimal | Custom | Numeric | Configurable precision | 45.67 |
| Integer | N/A | Whole number | Must be whole | 150 |
| Boolean | N/A | true/false | Only 2 values | true |
| DateTime | N/A | ISO 8601 | UTC timezone | 2026-02-27T10:30:00Z |
| Picklist | N/A | Enumerated | Predefined values only | "Prospect" |
| Lookup | 18 | Reference to another object | Foreign key | 0015g000008ZP7AAAW |

---

## Validation Rules

### Built-in Field Validations

```
NAME Field
├─ Required: YES
├─ Max Length: 255 characters
├─ Type: Text
├─ Default: None
└─ Validation: Cannot be empty or null

BILLING_COUNTRY Field
├─ Required: YES
├─ Max Length: 50 characters
├─ Type: Text
├─ Default: None
└─ Validation: Must be valid country name

ANNUAL_REVENUE Field
├─ Required: NO
├─ Type: Currency (8 digits, 2 decimals)
├─ Range: 0 to 99999999.99
└─ Validation: Must be positive number

NUMBER_OF_EMPLOYEES Field
├─ Required: NO
├─ Type: Integer
├─ Range: 0 to 999999999
└─ Validation: Must be positive integer
```

### Custom Validation Rules (Implementation)

```apex
// Validation Rule 1: Phone format validation
Pattern: /^\d{10}$|^[+]?[(]?\d{3}[)]?[\s.-]?\d{3}[\s.-]?\d{4}$/
Examples:
  ✓ 5550100
  ✓ (555) 010-0100
  ✓ +1-555-0100
  ✓ +1 555 0100
  ✗ invalid-number

// Validation Rule 2: Website format validation
Pattern: /^https?:\/\/[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&/=]*)$/
Examples:
  ✓ https://www.example.com
  ✓ http://example.com
  ✓ https://subdomain.example.co.uk
  ✗ www.example.com (missing protocol)
  ✗ example.com (missing protocol)

// Validation Rule 3: Email format validation
Pattern: /^[^\s@]+@[^\s@]+\.[^\s@]+$/
Examples:
  ✓ info@example.com
  ✓ user+tag@example.co.uk
  ✗ invalid@email (missing domain extension)
  ✗ @example.com (missing local part)

// Validation Rule 4: AnnualRevenue format validation
Rules:
  ✓ Null (optional field)
  ✓ Positive decimal with max 2 decimal places
  ✓ Range: 0 to 99999999.99
  ✗ Negative numbers
  ✗ More than 2 decimal places
  ✗ Non-numeric values
```

---

## Custom Field Extensions

### Custom Field Examples

```
CUSTOM_FIELD_1: CompanyRegistrationNumber__c
├─ Type: String (50 chars)
├─ Purpose: Store company registration number
├─ Required: NO
├─ Validation: Format depends on country
└─ Example: "US-123456789"

CUSTOM_FIELD_2: PreferredLanguage__c
├─ Type: Picklist
├─ Purpose: Store company's preferred language
├─ Required: NO
├─ Values: English, Spanish, French, German, etc.
└─ Example: "Spanish"

CUSTOM_FIELD_3: CrmMigrationId__c
├─ Type: String (100 chars)
├─ Purpose: Track account migration from old system
├─ Required: NO
├─ Unique: YES
└─ Example: "LEGACY_CRM_12345"

CUSTOM_FIELD_4: LastBusinessReview__c
├─ Type: DateTime
├─ Purpose: Track last business review date
├─ Required: NO
├─ Default: Today's date
└─ Example: "2026-02-27T10:30:00Z"

CUSTOM_FIELD_5: AccountScore__c
├─ Type: Decimal (5,2)
├─ Purpose: Store account score/rating
├─ Required: NO
├─ Range: 0 to 100
└─ Example: "87.50"
```

### Adding Custom Fields to API

```apex
// In AccountResponseWrapper, add custom fields:
public class AccountResponseWrapper {
    // ... existing fields ...
    
    // Custom fields
    public String companyRegistrationNumber__c;
    public String preferredLanguage__c;
    public String crmMigrationId__c;
    public String lastBusinessReview__c;
    public Decimal accountScore__c;
}

// In AccountController.convertAccountToMap():
private static Map<String, Object> convertAccountToMap(Account acc) {
    return new Map<String, Object>{
        // ... existing fields ...
        'companyRegistrationNumber__c' => acc.CompanyRegistrationNumber__c,
        'preferredLanguage__c' => acc.PreferredLanguage__c,
        'crmMigrationId__c' => acc.CrmMigrationId__c,
        'lastBusinessReview__c' => acc.LastBusinessReview__c,
        'accountScore__c' => acc.AccountScore__c
    };
}
```

---

## Related Object Relationships

### Contact Object

```
Contact
├─ Primary Key: Id
├─ Foreign Key: AccountId → Account.Id
│
├─ Standard Fields
│   ├─ FirstName (String, 40)
│   ├─ LastName (String, 80) [Required]
│   ├─ Email (Email, 255)
│   ├─ Phone (String, 40)
│   ├─ Title (String, 128)
│   ├─ Department (String, 80)
│   └─ MailingAddress (Compound field)
│
└─ Relationship
    └─ 1 Account : N Contacts
       Example: Account[AcmeCorp] has Contacts[John Doe, Jane Smith]

JSON Representation:
{
  "id": "0031f0000040VCFAA2",
  "accountId": "0015g000008ZP7AAAW",
  "firstName": "John",
  "lastName": "Doe",
  "email": "john.doe@acme.com",
  "phone": "+1-555-0100",
  "title": "Sales Manager"
}

Query Example:
SELECT Id, FirstName, LastName, Email, Phone FROM Contact 
WHERE AccountId = '0015g000008ZP7AAAW'
```

### Opportunity Object

```
Opportunity
├─ Primary Key: Id
├─ Foreign Key: AccountId → Account.Id
│
├─ Standard Fields
│   ├─ Name (String, 120) [Required]
│   ├─ StageName (Picklist) [Required]
│   ├─ Amount (Currency)
│   ├─ Probability (Percent)
│   ├─ CloseDate (Date) [Required]
│   ├─ Type (Picklist)
│   └─ Description (TextArea)
│
└─ Relationship
    └─ 1 Account : N Opportunities
       Example: Account[AcmeCorp] has Opportunities[Q1 Deal, Q2 Contract]

JSON Representation:
{
  "id": "0061f0000055WCFAA2",
  "accountId": "0015g000008ZP7AAAW",
  "name": "Acme Implementation - Q1 2026",
  "stageName": "Proposal/Price Quote",
  "amount": 500000,
  "probability": 75,
  "closeDate": "2026-03-31"
}

Query Example:
SELECT Id, Name, Amount, StageName, CloseDate FROM Opportunity 
WHERE AccountId = '0015g000008ZP7AAAW' 
ORDER BY CloseDate DESC
```

### Asset Object

```
Asset
├─ Primary Key: Id
├─ Foreign Key: AccountId → Account.Id
│
├─ Standard Fields
│   ├─ Name (String, 255) [Required]
│   ├─ SerialNumber (String, 80)
│   ├─ InstallDate (Date)
│   ├─ PurchaseDate (Date)
│   ├─ UsageEndDate (Date)
│   ├─ Status (Picklist)
│   └─ Description (TextArea)
│
└─ Relationship
    └─ 1 Account : N Assets
       Example: Account[AcmeCorp] has Assets[License A, License B]

JSON Representation:
{
  "id": "0021f0000055WCHAA2",
  "accountId": "0015g000008ZP7AAAW",
  "name": "Professional License",
  "serialNumber": "SN-12345-ABC",
  "installDate": "2025-01-15",
  "status": "Active"
}

Query Example:
SELECT Id, Name, SerialNumber, Status FROM Asset 
WHERE AccountId = '0015g000008ZP7AAAW' 
AND Status = 'Active'
```

---

## Index Strategy

### Primary Indexes (Automatic in Salesforce)

```
ID Index (Automatic)
├─ Field: Id
├─ Type: Hash index
├─ Cardinality: Very High (unique)
├─ Query Performance: O(1) lookup
└─ Use Case: Direct record lookups by ID

CREATED_DATE Index (Automatic)
├─ Field: CreatedDate
├─ Type: B-tree index
├─ Cardinality: High
├─ Query Performance: O(log N) for range queries
└─ Use Case: Time-based filtering, sorting
```

### Recommended Secondary Indexes

```
NAME Index (Custom recommended)
├─ Field: Name
├─ Type: B-tree index (if available)
├─ Cardinality: Very High (unique)
├─ Benefits: Optimize searches by company name
├─ Query:
│   SELECT * FROM Account WHERE Name = 'Acme' LIMIT 1
└─ Performance: Reduces full table scan

LAST_MODIFIED_DATE Index (Custom recommended)
├─ Field: LastModifiedDate
├─ Type: B-tree index
├─ Cardinality: High
├─ Benefits: Sort and filter by modification time
├─ Query:
│   SELECT * FROM Account 
│   ORDER BY LastModifiedDate DESC LIMIT 100
└─ Performance: Faster sorting

BILLING_COUNTRY Index (Custom recommended)
├─ Field: BillingCountry
├─ Type: Hash or B-tree
├─ Cardinality: Medium
├─ Benefits: Filter by country
├─ Query:
│   SELECT * FROM Account WHERE BillingCountry = 'USA'
└─ Performance: Reduces rows scanned

INDUSTRY Index (Custom recommended)
├─ Field: Industry
├─ Type: Hash or B-tree
├─ Cardinality: Low-Medium
├─ Benefits: Filter by industry
├─ Query:
│   SELECT * FROM Account WHERE Industry = 'Technology'
└─ Performance: Quick filtering
```

### Query Optimization with Indexes

```apex
// GOOD: Uses indexed fields efficiently
SELECT Id, Name FROM Account 
WHERE BillingCountry = 'USA'
ORDER BY Name ASC
LIMIT 100

// Index lookup: BillingCountry = 'USA' (1 index lookup)
// Then: Sort by Name (in-memory or index sort)
// Performance: O(log N) + O(K log K) where K is result set

// OKAY: Full table scan but sorted
SELECT Id, Name FROM Account 
ORDER BY Industry, Name
LIMIT 100

// Performance: O(N log N) - full table scan with sort

// AVOID: Wildcard search without index
SELECT Id, Name FROM Account 
WHERE Name LIKE '%Technology%'
LIMIT 100

// Performance: O(N) - full table scan required
```

---

## Data Integrity Constraints

### Primary Key Constraint

```
CONSTRAINT: Account.Id must be unique and non-null
TYPE: Primary Key (Automatically enforced by Salesforce)
ENFORCEMENT: Database level

Violation Example:
├─ Attempting to INSERT duplicate Id: FAILS
├─ Attempting to INSERT NULL Id: FAILS
├─ Attempting to UPDATE Id: FAILS

Handling:
Never allow updates to Id field
Salesforce automatically generates unique Ids
```

### Required Field Constraint

```
REQUIRED FIELDS:
1. Name (String, 255 chars)
   ├─ Constraint: NOT NULL
   ├─ Validation: Cannot be empty string
   └─ Error: "INVALID_FIELD_VALUE:required field missing: Name"

2. BillingCountry (String, 50 chars)
   ├─ Constraint: NOT NULL
   ├─ Validation: Must be valid country
   └─ Error: "INVALID_FIELD_VALUE:required field missing: BillingCountry"

Violation Handling in Code:
try {
    insert account; // Missing Name or BillingCountry
} catch (DmlException ex) {
    // Returns: DML operation failed. First exception on row 0; 
    // first error: REQUIRED_FIELD_MISSING, required field missing: Name
}
```

### Field Length Constraints

```
String Field Lengths:
├─ Name: MAX 255 characters
│  └─ If Name.length() > 255: FIELD_TOO_LONG error
│
├─ Website: MAX 255 characters
│  └─ If Website.length() > 255: FIELD_TOO_LONG error
│
├─ Description: MAX 32,000 characters
│  └─ If Description.length() > 32000: FIELD_TOO_LONG error
│
├─ Phone: MAX 40 characters
│  └─ If Phone.length() > 40: FIELD_TOO_LONG error
│
└─ BillingCountry: MAX 50 characters
   └─ If BillingCountry.length() > 50: FIELD_TOO_LONG error

Enforcement Level: Database level
Action on Violation: Reject DML operation
```

### Referential Integrity Constraints

```
Foreign Key: CreatedById → User.Id
├─ Type: Lookup relationship
├─ Required: NO (but auto-populated by system)
├─ Cascade: NO (User record deletion doesn't delete Account)
└─ Orphan: Accounts with deleted users keep their CreatedById

Foreign Key: LastModifiedById → User.Id
├─ Type: Lookup relationship
├─ Required: NO (but auto-populated by system)
├─ Cascade: NO
└─ Orphan: Accounts with deleted users keep their LastModifiedById

Relationship: AccountId in Contact, Opportunity, Asset
├─ Type: Master-Detail relationship
├─ Cascade Delete: If Account deleted, related records deleted
│  (Unless relationship is Lookup type)
└─ Impact: Must handle cascading deletes in business logic
```

### Unique Constraint

```
Field: Name
├─ Constraint Type: Business rule (not database level)
├─ Enforcement: Application logic
├─ Validation: Check before INSERT or UPDATE
│
├─ Validation Query:
│   List<Account> existing = [
│       SELECT Id FROM Account WHERE Name = :accountName LIMIT 1
│   ];
│   if (!existing.isEmpty()) {
│       return error("Account with name already exists");
│   }
│
└─ Note: Salesforce allows duplicate names by default
   Custom validation rules or application logic must enforce uniqueness
```

---

## Migration Guide

### Data Migration Checklist

#### Pre-Migration
- [ ] Backup existing Account data
- [ ] Create staging table/environment
- [ ] Document data mapping rules
- [ ] Identify data quality issues
- [ ] Plan validation strategy
- [ ] Estimate data volume and migration time
- [ ] Test migration script on sandbox
- [ ] Get stakeholder approval

#### Migration Steps

```
1. Extract Production Data
   ├─ Export from source system
   ├─ Verify record count
   └─ Validate data completeness

2. Data Transformation
   ├─ Map source fields to Salesforce Account fields
   ├─ Handle data type conversions
   ├─ Validate required fields populated
   ├─ Cleanse phone/address formats
   └─ Generate Salesforce-compatible data

3. Load to Staging Environment
   ├─ Use Salesforce Data Import Wizard or API
   ├─ Verify all records loaded
   ├─ Check for load errors
   └─ Validate data integrity

4. Data Validation
   ├─ Record count matches
   ├─ Required fields populated
   ├─ Field values in valid ranges
   ├─ No duplicate Names (if applicable)
   └─ Referential integrity intact

5. User Testing
   ├─ Business users validate migrated data
   ├─ Spot-check sample records
   ├─ Verify data accuracy
   └─ Get sign-off

6. Production Migration
   ├─ Schedule during maintenance window
   ├─ Run migration script
   ├─ Verify record counts
   ├─ Monitor for errors
   └─ Validate data completeness

7. Post-Migration
   ├─ Delete staging records
   ├─ Update documentation
   ├─ Train users on new system
   ├─ Monitor application behavior
   └─ Archive legacy data
```

### Sample Transformation Mapping

```
Source System (Legacy CRM) → Salesforce Account

Source Field              Salesforce Field        Transformation
─────────────────────────────────────────────────────────────────
company_id                CustomField__c          Keep as-is
company_name              Name                    Trim, capitalize
company_type              Type                    Map to picklist
industry_code             Industry                Map to picklist
street_address            BillingStreet           Combine if split
city                      BillingCity             Trim
state_province            BillingStateCode        Convert to code
postal_code               BillingPostalCode       Trim
country_name              BillingCountry          Validate country
phone_number              Phone                   Reformat
fax_number                Fax                     Reformat
website_url               Website                 Validate URL
annual_revenue            AnnualRevenue           Convert to currency
employee_count            NumberOfEmployees      Convert to integer
notes                     Description             Keep as-is
created_date              CreatedDate             Convert datetime
last_updated              LastModifiedDate        Convert datetime
```

### Validation Query After Migration

```apex
// Validate migrated accounts
Map<String, Object> validation = new Map<String, Object>();

// 1. Check record count
Integer totalAccounts = [SELECT COUNT() FROM Account];
validation.put('totalRecords', totalAccounts);

// 2. Check required fields
List<Account> missingName = [SELECT Id FROM Account WHERE Name = null LIMIT 10];
validation.put('missingName', missingName.size());

List<Account> missingCountry = [SELECT Id FROM Account WHERE BillingCountry = null LIMIT 10];
validation.put('missingCountry', missingCountry.size());

// 3. Check for duplicates by Name
List<AggregateResult> duplicates = [
    SELECT Name, COUNT(Id) cnt FROM Account 
    GROUP BY Name HAVING COUNT(Id) > 1
];
validation.put('duplicateNames', duplicates.size());

// 4. Check custom field population (if used)
List<Account> withCustomField = [SELECT COUNT() FROM Account WHERE CustomField__c != null];
validation.put('customFieldPopulated', withCustomField.size());

// 5. Check data conversions
List<Account> negativeRevenue = [SELECT COUNT() FROM Account WHERE AnnualRevenue < 0];
validation.put('negativeRevenue', negativeRevenue.size());

System.debug(JSON.serializePretty(validation));
```

---

## Appendix: Sample Data

### Test Account Records

```json
{
  "id": "0015g000008ZP7AAAW",
  "name": "Acme Corporation",
  "type": "Customer",
  "industry": "Manufacturing",
  "description": "Leading manufacturer of industrial widgets",
  "phone": "+1-555-0100",
  "fax": "+1-555-0101",
  "website": "https://www.acme.com",
  "email": "info@acme.com",
  "annualRevenue": 5000000.00,
  "numberOfEmployees": 150,
  "ownership": "Private",
  "billingStreet": "100 Industrial Blvd",
  "billingCity": "Chicago",
  "billingStateCode": "IL",
  "billingPostalCode": "60601",
  "billingCountry": "United States",
  "billingLatitude": 41.8781,
  "billingLongitude": -87.6298,
  "shippingStreet": "200 Distribution Dr",
  "shippingCity": "Memphis",
  "shippingStateCode": "TN",
  "shippingPostalCode": "38103",
  "shippingCountry": "United States",
  "shippingLatitude": 35.1495,
  "shippingLongitude": -90.0490,
  "createdDate": "2025-01-15T10:30:00Z",
  "createdById": "0051f000002bw84AAA",
  "lastModifiedDate": "2026-02-27T14:22:00Z",
  "lastModifiedById": "0051f000002bw84AAA",
  "systemModStamp": "2026-02-27T14:22:00Z",
  "isDeleted": false
}
```

---

**Document Version:** 1.0  
**Last Updated:** February 27, 2026  
**Status:** Final - Complete Database Schema Reference

/**
 * Author: Vigneshwaran D
 * Date: 8 May 2025
 * Team: Sales-Execution-Smart-Workflows-GTMS
 * Purpose: Update Deal_Health__c field on Quote -> Deal Health Score Quartile Color from CRMA
 * Jira: GTMS-27488, GTMS-27491
 *
 * Description:
 * Test data utility class for building (not inserting) Accounts, Users, Contracts, Opportunities, Quotes, Products, PricebookEntries, and QuoteLines for DHS-related test scenarios.
 * All methods return SObject records or lists of SObjects. No DML is performed in this utility.
 * DML should be performed in bulk in the test class.
 */
@isTest
public class CRMA_TestDataUtility {

    public class TestException extends Exception {}

    /**
     * Builds an Account SObject (does not insert)
     */
    public static Account buildAccount(String name, Boolean isPartner) {
        Account acc = new Account(
            Name = name, 
            Organization_Size__c = '5000+', 
            BillingCountry = 'Canada', 
            Industry = 'Other'
        );
        if (isPartner) {
            acc.RecordTypeId = Schema.Account.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();
        }
        return acc;
    }

    /**
     * Builds an Account SObject with AnnualRevenue (does not insert)
     */
    public static Account buildAccount(String name, Boolean isPartner, Decimal annualRevenue) {
        Account acc = buildAccount(name, isPartner);
        acc.AnnualRevenue = annualRevenue;
        return acc;
    }

    /**
     * Builds a list of Account SObjects (does not insert)
     */
    public static List<Account> buildAccounts(List<Map<String, Object>> paramsList) {
        List<Account> accounts = new List<Account>();
        for (Map<String, Object> params : paramsList) {
            String name = (String)params.get('name');
            Boolean isPartner = (Boolean)params.get('isPartner');
            Decimal annualRevenue = (Decimal)params.get('annualRevenue');
            if (annualRevenue != null) {
                accounts.add(buildAccount(name, isPartner, annualRevenue));
            } else {
                accounts.add(buildAccount(name, isPartner));
            }
        }
        return accounts;
    }

    /**
     * Builds a User SObject (does not insert)
     */
    public static User buildUser(String profileId, String roleId, String alias) {
        User u = new User(
            ProfileId = profileId,
            EmployeeNumber = '123',
            LastName = 'last',
            UserRoleId = roleId,
            Email = 'puser' + Math.random() + '@test.com',
            Username = 'puser' + Math.random() + System.currentTimeMillis() + '@test.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = alias,
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = TRUE
        );
        return u;
    }
    
     public static void assignPermissionSet(Id userId, String permissionSetName) {
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = :permissionSetName LIMIT 1];
        insert new PermissionSetAssignment(
            AssigneeId = userId,
            PermissionSetId = ps.Id
        );
    }

    /**
     * Builds a Contract SObject (does not insert)
     */
    public static Contract buildContract(Id accountId, Date startDate, Date endDate, String status, Decimal contractRenewableACV) {
        Contract cont = new Contract(
            AccountId = accountId,
            StartDate = startDate,
            EndDate = endDate,
            ContractTerm = 1,
            Status = status,
            Contract_Renewable_ACV__c = contractRenewableACV
        );
        return cont;
    }

    /**
     * Builds an Opportunity SObject (does not insert)
     */
    public static Opportunity buildOpportunity(Id accountId, Id pricebookId, String name, String stage, Date closeDate, Boolean renewal, Id renewedContractId, String paymentType) {
        Opportunity opp = new Opportunity(
            AccountId = accountId,
            License_Term__c = 36,
            Pricebook2Id = pricebookId,
            VAT_Number__c = '123',
            Max_Approved_Discount__c = 0,
            Name = name,
            Configuration_Segment__c = 'Non Express',
            CloseDate = closeDate,
            StageName = stage,
            Renewal__c = renewal,
            SBQQ__RenewedContract__c = renewedContractId,
            Selected_Payment_Type__c = paymentType
        );
        return opp;
    }

    /**
     * Builds a Quote SObject (does not insert)
     */
    public static SBQQ__Quote__c buildQuote(Id accountId, Id opportunityId, String name, Boolean isPrimary, Decimal buyout, Decimal subsidy, String paymentType) {
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Quote_Name__c = name,
            SBQQ__Account__c = accountId,
            SBQQ__Opportunity2__c = opportunityId,
            SBQQ__Primary__c = isPrimary,
            SBQQ__SubscriptionTerm__c = 10,
            Estimated_Annual_Payment__c = 24,
            License_Term__c = '36',
            Configuration_Segment__c = 'Express',
            Buyout_Amount__c = buyout,
            Subsidy_Amount__c = subsidy,
            Selected_Payment_Type__c = paymentType
        );
        return quote;
    }

    /**
     * Builds a Product2 SObject (does not insert)
     */
    public static Product2 buildProduct(String name, String productCode, String family, String licenseTier) {
        Product2 product = new Product2(
            Name = name,
            ProductCode = productCode,
            Family = family,
            License_Tier__c = licenseTier
        );
        
        if(productCode.containsIgnoreCase('CM1')){
            product.Product_Tag__c = 'CM1';
        }else if(productCode.containsIgnoreCase('CM2')){
            product.Product_Tag__c = 'CM2';
        }else if(productCode.containsIgnoreCase('VG')){
            product.Product_Tag__c = 'VG';
        }else{
            product.Product_Tag__c = 'Other';
        }
        return product;
    }

    /**
     * Builds a list of Product2 SObjects (does not insert)
     */
    public static List<Product2> buildProducts(List<Map<String, String>> paramsList) {
        List<Product2> products = new List<Product2>();
        for (Map<String, String> params : paramsList) {
            products.add(buildProduct(params.get('name'), params.get('productCode'), params.get('family'), params.get('licenseTier')));
        }
        return products;
    }

    /**
     * Builds a PricebookEntry SObject (does not insert)
     */
    public static PricebookEntry buildPricebookEntry(Id pricebookId, Id productId, Decimal unitPrice) {
        PricebookEntry entry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = productId,
            UnitPrice = unitPrice,
            IsActive = true
        );
        return entry;
    }

    /**
     * Builds a list of PricebookEntry SObjects (does not insert)
     */
    public static List<PricebookEntry> buildPricebookEntries(List<Map<String, Object>> paramsList) {
        List<PricebookEntry> entries = new List<PricebookEntry>();
        for (Map<String, Object> params : paramsList) {
            entries.add(buildPricebookEntry((Id)params.get('pricebookId'), (Id)params.get('productId'), (Decimal)params.get('unitPrice')));
        }
        return entries;
    }

    /**
     * Builds a QuoteLine SObject (does not insert)
     */
    public static SBQQ__QuoteLine__c buildQuoteLine(Id quoteId, Id productId, Id pricebookEntryId, Decimal quantity, Decimal discount, Id accountId, Decimal customerPrice) {
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quoteId,
            SBQQ__Product__c = productId,
            SBQQ__PricebookEntryId__c = pricebookEntryId,
            SBQQ__Quantity__c = quantity,
            SBQQ__Discount__c = discount,
            accountLookupTest__c = accountId,
            SBQQ__CustomerPrice__c = customerPrice,
            SBQQ__NetPrice__c = customerPrice * quantity,
            SBQQ__ListPrice__c = customerPrice,
            SBQQ__ProrateMultiplier__c = 1.0,
            Account__c = accountId,
            Annual_Net_Total__c = customerPrice * quantity
        );
        return quoteLine;
    }

    /**
     * Builds a list of QuoteLine SObjects (does not insert)
     */
    public static List<SBQQ__QuoteLine__c> buildQuoteLines(List<Map<String, Object>> paramsList) {
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        for (Map<String, Object> params : paramsList) {
            quoteLines.add(buildQuoteLine(
                (Id)params.get('quoteId'),
                (Id)params.get('productId'),
                (Id)params.get('pricebookEntryId'),
                (Decimal)params.get('quantity'),
                (Decimal)params.get('discount'),
                (Id)params.get('accountId'),
                (Decimal)params.get('customerPrice')
            ));
        }
        return quoteLines;
    }

    // Utility methods for test context
    public static Id getStandardPricebookId() {
        return Test.getStandardPricebookId();
    }

    // No DML for config metadata or permission sets; these should be handled in the test class if needed
}
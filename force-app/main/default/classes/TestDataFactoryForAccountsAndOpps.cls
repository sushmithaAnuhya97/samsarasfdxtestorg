/* TestFactory method to create the required data for the test class ScheduledAssociateQuotaOpportunityTest */
@isTest
public class TestDataFactoryForAccountsAndOpps {

    public static User createUser(String email, String lastName, String profileName) {
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        User user = new User(
            Alias = 'usr',
            Email = email,
            EmailEncodingKey = 'UTF-8',
            LastName = lastName,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = email,
            ProfileId = p.Id,
            EmployeeNumber = '456'
        );
        insert user;
        return user;
    }

    public static User createUser(String email, String lastName, String profileName, Boolean isInsert) {
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        User user = new User(
            Alias = 'usr',
            Email = email,
            EmailEncodingKey = 'UTF-8',
            LastName = lastName,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = email,
            ProfileId = p.Id,
            IsActive = true,
            EmployeeNumber = '456'
        );
        if(isInsert) insert user;
        return user;
    }

    // Create Test Account
    public static Account createAccount(String name, Id ownerId) {
        Account account = new Account(
            Name = name, 
            Organization_Size__c = '1 - 99', 
            BillingState = 'California', 
            BillingCountry = 'United States', 
            OwnerId = ownerId
        );
        insert account;
        return account;
    }

    // Create Test Opportunity
    public static Opportunity createOpportunity(Id accountId) {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity', 
            AccountId = accountId, 
            StageName = 'Prospecting', 
            CloseDate = Date.today().addMonths(1)
        );
        insert opp;
        return opp;
    }
    //Create Test Opportunities
    public static void createOpportunities(Integer numberOfOpportunities, String type) {
        List<Account> newAccounts = new List<Account>();
        List<Opportunity> newOppotunities = new List<Opportunity>();
        List<Quota__c> newQuotas = new List<Quota__c>();
        Opportunity opportunityClosed;
        Opportunity opportunityRefunded;

        User user = [Select id from User where Id = :UserInfo.getUserId()];
        Account account = [Select id from Account where Name = 'Testing Class Account' limit 1];

        for (Integer j = 0; j < numberOfOpportunities; j++) {
            Integer randAmount = Math.round(Math.random() * 10000);
            Date closeDate = Date.Today();
            opportunityClosed = new Opportunity(Name = 'Test Opportunity ' + j, AccountId = account.Id, CloseDate = closeDate,
                    StageName = 'Closed Won', Amount = randAmount, Type = 'Revenue Opportunity',
                    Owner_Role_Copy__c = 'My Role', CurrencyIsoCode = type);

            newOppotunities.add(opportunityClosed);
        }

        for (Integer k = 0; k < numberOfOpportunities; k++) {
            Integer randAmount = Math.round(Math.random() * 10000);
            Date closeDate = Date.Today() + 1;
            opportunityRefunded = new Opportunity(Name = 'Test Opportunity ' + k, AccountId = account.Id, CloseDate = closeDate,
                    StageName = 'Refunded - Closed', Amount = randAmount, Type = 'Free Trail Opportunity',
                    Owner_Role_Copy__c = 'My Role', CurrencyIsoCode = type);
            newOppotunities.add(opportunityRefunded);
        }

        insert newOppotunities;

        TestData.ProductsAndPriceBooks productsAndPricebooks = TestData.createProductsAndPricebookEntries();
        Map<String, PricebookEntry> pricebookEntries = productsAndPricebooks.pricebookEntries;

        Map<String, OpportunityLineItem> items = new Map<String, OpportunityLineItem>();
        OpportunityLineItem ol = new OpportunityLineItem (Quantity = 5, OpportunityId = opportunityClosed.Id, PriceBookEntryId = pricebookEntries.get('vg33').Id, UnitPrice = pricebookEntries.get('vg33').UnitPrice, Discount = 2);
        items.put('revVg33', ol);

        ol = new OpportunityLineItem (Quantity = 5, OpportunityId = opportunityClosed.Id, PriceBookEntryId = pricebookEntries.get('em11').Id, UnitPrice = pricebookEntries.get('em11').UnitPrice, Discount = 2);
        items.put('revEm11', ol);

        ol = new OpportunityLineItem (Quantity = 5, OpportunityId = opportunityRefunded.Id, PriceBookEntryId = pricebookEntries.get('vgLicense').Id, UnitPrice = pricebookEntries.get('vgLicense').UnitPrice, Discount = 2, Created_From_NS__c = true);
        items.put('revVgLicense', ol);

        ol = new OpportunityLineItem (Quantity = 5, OpportunityId = opportunityRefunded.Id, PriceBookEntryId = pricebookEntries.get('emLicense').Id, UnitPrice = pricebookEntries.get('emLicense').UnitPrice, Discount = 2);
        items.put('revEmLicense', ol);

        insert items.values();

    }

    //Create Quotas
    public static void createQuota(String type) {

        User user = [Select id from User where Id = :UserInfo.getUserId()];
        if (type == 'USD') {
            Quota__c quota = new Quota__c(User__c = user.id, Role_at_Start_of_Fiscal_Period__c = 'My Role', CurrencyIsoCode = 'USD', Quota__c = 8000,Q1_Quota__c = 2000,Q2_Quota__c = 2000,Q3_Quota__c = 2000,Q4_Quota__c = 2000, Quota_Period_End_Date__c = Date.Today() + 4, Quota_Period_Start_Date__c = Date.Today() - 4, Fiscal_Period_End_Date__c = Date.Today() + 4, Fiscal_Period_Start_Date__c = Date.Today() - 4, Quota_Period__c = 'Test', Fiscal_Period__c = 'Test');
            insert quota;
        } else if (type == 'GBP') {
            Quota__c quota2 = new Quota__c(User__c = user.id, Role_at_Start_of_Fiscal_Period__c = 'My Role', CurrencyIsoCode = 'EUR', Quota__c = 9000, Q1_Quota__c = 2000,Q2_Quota__c = 2000,Q3_Quota__c = 2000,Q4_Quota__c = 3000, Quota_Period_End_Date__c = Date.Today() + 4, Quota_Period_Start_Date__c = Date.Today() - 4, Fiscal_Period_End_Date__c = Date.Today() + 4, Fiscal_Period_Start_Date__c = Date.Today() - 4, Quota_Period__c = 'Test', Fiscal_Period__c = 'Test');
            insert quota2;
        } else if (type == 'EUR') {
            Quota__c quota3 = new Quota__c(User__c = user.id, Role_at_Start_of_Fiscal_Period__c = 'My Role', CurrencyIsoCode = 'GBP', Quota__c = 10000, Q1_Quota__c = 3000,Q2_Quota__c = 3000,Q3_Quota__c = 3000,Q4_Quota__c = 1000, Quota_Period_End_Date__c = Date.Today() + 4, Quota_Period_Start_Date__c = Date.Today() - 4, Fiscal_Period_End_Date__c = Date.Today() + 4, Fiscal_Period_Start_Date__c = Date.Today() - 4, Quota_Period__c = 'Test', Fiscal_Period__c = 'Test');
            insert quota3;
        }
    }

    // Create Quota Opportunities
    public static void createQuotaOpportunities() {
        User user = [Select id from User where Id = :UserInfo.getUserId()];
        Quota__c quota = [Select id from Quota__c where User__c = :user.id];
        Opportunity opportunity = [Select Id, OwnerId, CloseDate, CurrencyIsoCode from Opportunity where name = 'Test Opportunity 1' Limit 1];
        Quota_Opportunity__c newQuotaOpportunity = new Quota_Opportunity__c();
        newQuotaOpportunity.Commissionable_Dollars__c = 100;
        newQuotaOpportunity.Converted_Commissionable_Dollars__c = 100;
        newQuotaOpportunity.Converted_Opportunity_Amount__c = 200;
        newQuotaOpportunity.Opportunity__c = opportunity.Id;
        newQuotaOpportunity.Opportunity_Amount__c = 200;
        newQuotaOpportunity.Opportunity_Close_Date__c = opportunity.CloseDate;
        newQuotaOpportunity.Opportunity_Owner__c = opportunity.OwnerId;
        newQuotaOpportunity.Related_Quota__c = quota.Id;
        newQuotaOpportunity.CurrencyIsoCode = opportunity.CurrencyIsoCode;
        insert newQuotaOpportunity;
    }
}
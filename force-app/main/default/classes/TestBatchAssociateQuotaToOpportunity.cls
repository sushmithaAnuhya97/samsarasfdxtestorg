@isTest
public with sharing class TestBatchAssociateQuotaToOpportunity {
    @TestSetup
    static void setup() {
//        Account acc = (Account) TestFactory.createSObject(
//                new Account(Name = 'Testing Class Account',
//                        Organization_Size__c = '1 - 99',
//                        Industry = 'Food & Beverage',
//                        CurrencyIsoCode = 'USD'),
//                true
//        );
//        final Integer oppAmount = Math.round(Math.random() * 10000);
//        insert new List<Opportunity>{
//                (Opportunity) TestFactory.createSObject(
//                        new Opportunity(AccountId = acc.Id,
//                                StageName = 'Closed Won',
//                                Amount = oppAmount,
//                                Type = 'Revenue Opportunity',
//                                Owner_Role_Copy__c = 'My Role',
//                                CurrencyIsoCode = 'USD')
//                ),
//                (Opportunity) TestFactory.createSObject(
//                        new Opportunity(AccountId = acc.Id,
//                                StageName = 'Refunded - Closed',
//                                Amount = oppAmount,
//                                Type = 'Free Trail Opportunity',
//                                Owner_Role_Copy__c = 'My Role',
//                                CurrencyIsoCode = 'USD')
//                )
//        };
        Account account = new Account(Name = 'Testing Class Account', Organization_Size__c = '1 - 99', Industry = 'Food & Beverage', CurrencyIsoCode = 'USD', Website = 'TestClassByHarsha.com', BillingCountry = 'United States', BillingState = 'California');
        insert account;
        List<Opportunity> newOppotunities = new List<Opportunity>();
        Opportunity opportunityClosed;
        Opportunity opportunityRefunded;
        for (Integer j = 0; j < 1; j++) {
            Integer randAmount = Math.round(Math.random() * 10000);
            Date closeDate = Date.Today();
            opportunityClosed = new Opportunity(Name = 'Test Opportunity ' + j, AccountId = account.Id, CloseDate = closeDate,
                    StageName = 'Closed Won', Amount = randAmount, Type = 'Revenue Opportunity',
                    Owner_Role_Copy__c = 'Management', CurrencyIsoCode = 'USD');

            newOppotunities.add(opportunityClosed);
        }

        for (Integer k = 0; k < 1; k++) {
            Integer randAmount = Math.round(Math.random() * 10000);
            Date closeDate = Date.Today() + 1;
            opportunityRefunded = new Opportunity(Name = 'Test Opportunity ' + k, AccountId = account.Id, CloseDate = closeDate,
                    StageName = 'Refunded - Closed', Amount = randAmount, Type = 'Free Trail Opportunity',
                    Owner_Role_Copy__c = 'Management', CurrencyIsoCode = 'USD');
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

    
    @isTest
    static void testbatchassociatequotaopportunityGBP() {
        System.debug(LoggingLevel.INFO, '##### ScheduledAssociateQuotaOpportunityTest -> testAssociateQuotaOpportunityUSDGBP -> in test');

        TestDataFactoryForAccountsAndOpps.createQuota('GBP');
        List<Opportunity> newOppotunities = new List<Opportunity>();
        Test.startTest();
        Account account = new Account(Name = 'Testing Class Account', Organization_Size__c = '1 - 99', Industry = 'Food & Beverage', CurrencyIsoCode = 'USD', Website = 'TestClassByHarsha.com', BillingCountry = 'United States', BillingState = 'California');
        insert account;
        
        Opportunity opportunityClosed = new Opportunity(Name = 'Test Opportunity 1', AccountId = account.Id, CloseDate = Date.Today(),
                    StageName = 'Closed Won', Amount = 456, Type = 'Revenue Opportunity',
                    Owner_Role_Copy__c = 'Management', CurrencyIsoCode = 'USD');
            newOppotunities.add(opportunityClosed);
        insert newOppotunities;

        User user = [Select id from User where Id = :UserInfo.getUserId()];
        Quota__c quota = new Quota__c(User__c = user.id, Role_at_Start_of_Fiscal_Period__c = 'Management', CurrencyIsoCode = 'USD', Quota__c = 8000,Q1_Quota__c = 2000,Q2_Quota__c = 2000,Q3_Quota__c = 2000,Q4_Quota__c = 2000, Quota_Period_End_Date__c = Date.Today() + 10, Quota_Period_Start_Date__c = Date.Today() - 4, Fiscal_Period_End_Date__c = Date.Today() + 4, Fiscal_Period_Start_Date__c = Date.Today() - 4, Quota_Period__c = 'Test', Fiscal_Period__c = 'Test');
        insert quota;
       
        BatchAssociateQuotaToOpportunity b = new BatchAssociateQuotaToOpportunity();
        b.execute(null);       
        //String CRON_EXP = '0 0 0 3 9 ? 2022';
        //String jobId = System.schedule('BatchAssociateQuotaToOpportunity', CRON_EXP, new BatchAssociateQuotaToOpportunity());
        Test.stopTest();
    }

    @isTest
    static void testmapdata() {
        

        List<Opportunity> newOppotunities = new List<Opportunity>();
        Account account = new Account(Name = 'Testing Class Account', Organization_Size__c = '1 - 99', Industry = 'Food & Beverage', CurrencyIsoCode = 'USD', Website = 'TestClassByHarsha.com', BillingCountry = 'United States', BillingState = 'California');
        insert account;
        Test.starttest();
        Opportunity opportunityClosed = new Opportunity(Name = 'Test Opportunity 1', AccountId = account.Id, CloseDate = Date.Today(),
                    StageName = 'Closed Won', Amount = 456, Type = 'Revenue Opportunity',
                    Owner_Role_Copy__c = 'My Role', CurrencyIsoCode = 'USD');
            newOppotunities.add(opportunityClosed);
        insert newOppotunities;

        User user = [Select id from User where Id = :UserInfo.getUserId()];
        Quota__c quota = new Quota__c(User__c = user.id, Role_at_Start_of_Fiscal_Period__c = 'My Role', CurrencyIsoCode = 'USD', Quota__c = 8000, Q1_Quota__c = 2000,Q2_Quota__c = 2000,Q3_Quota__c = 2000,Q4_Quota__c = 2000, Quota_Period_End_Date__c = Date.Today() + 4, Quota_Period_Start_Date__c = Date.Today() - 4, Fiscal_Period_End_Date__c = Date.Today() + 4, Fiscal_Period_Start_Date__c = Date.Today() - 4, Quota_Period__c = 'Test', Fiscal_Period__c = 'Test');
        insert quota;

        List<Quota_Opportunity__c> newQuotaOpportunities = new List<Quota_Opportunity__c>();
        Quota_Opportunity__c qo = new Quota_Opportunity__c(Related_Quota__c = quota.id);
        newQuotaOpportunities.add(qo);
        insert newQuotaOpportunities;



        BatchAssociateQuotaToOpportunity b = new BatchAssociateQuotaToOpportunity();  
        b.mapData(newQuotaOpportunities[0], newOppotunities[0], quota);
        Test.stopTest();
    }

}
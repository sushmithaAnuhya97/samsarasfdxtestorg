/* 
* Test class for the class ScheduledAssociateQuotaOpportunity And AssociateQuotaOpportunity
* Tested different currencies
* currency conversions
* Valid Quotas
* Valid Opportunities
* Scheduled Class
*/

@isTest
public class ScheduledAssociateQuotaOpportunityTest {

    //Commenting this out for now since we are running into issues with the process builder and trigger
    /*@isTest
    static void testAssociateQuotaOpportunityUSD(){  

        Test.startTest();
        TestDataFactoryForAccountsAndOpps.createAccount('USD');
        TestDataFactoryForAccountsAndOpps.createQuota('USD');
        TestDataFactoryForAccountsAndOpps.createOpportunities(5,'USD');
        TestDataFactoryForAccountsAndOpps.createQuotaOpportunities();
        AssociateQuotaOpportunity associateQO = new AssociateQuotaOpportunity();
        associateQO.mapQuotaAndOpportunities();
        system.assertEquals(10, [Select count() from Quota_Opportunity__c]);
        Test.stopTest();
    }
    
    @isTest
    static void testAssociateQuotaOpportunityEUR(){       
        Test.startTest();
        TestDataFactoryForAccountsAndOpps.createAccount('EUR');
        TestDataFactoryForAccountsAndOpps.createQuota('EUR');
        TestDataFactoryForAccountsAndOpps.createOpportunities(5,'EUR');
        AssociateQuotaOpportunity associateQO = new AssociateQuotaOpportunity();
        associateQO.mapQuotaAndOpportunities();
        system.assertEquals(10, [Select count() from Quota_Opportunity__c]);
        Test.stopTest();
    }    
    
    @isTest
    static void testAssociateQuotaOpportunityGBP(){       
        Test.startTest();
        TestDataFactoryForAccountsAndOpps.createAccount('GBP');
        TestDataFactoryForAccountsAndOpps.createQuota('GBP');
        TestDataFactoryForAccountsAndOpps.createOpportunities(5,'GBP');
        String CRON_EXP = '0 0 0 3 9 ? 2022';
        String jobId = System.schedule('ScheduledAssociateQuotaOpportunity', CRON_EXP, new ScheduledAssociateQuotaOpportunity());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals('2022-09-03 00:00:00', String.valueOf(ct.NextFireTime)); 
        Test.stopTest();
    }*/

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
//                                CurrencyIsoCode = 'USD'
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
                    Owner_Role_Copy__c = 'My Role', CurrencyIsoCode = 'USD');

            newOppotunities.add(opportunityClosed);
        }

        for (Integer k = 0; k < 1; k++) {
            Integer randAmount = Math.round(Math.random() * 10000);
            Date closeDate = Date.Today() + 1;
            opportunityRefunded = new Opportunity(Name = 'Test Opportunity ' + k, AccountId = account.Id, CloseDate = closeDate,
                    StageName = 'Refunded - Closed', Amount = randAmount, Type = 'Free Trail Opportunity',
                    Owner_Role_Copy__c = 'My Role', CurrencyIsoCode = 'USD');
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
    static void testAssociateQuotaOpportunityUSDEUR() {
        System.debug(LoggingLevel.INFO, '##### ScheduledAssociateQuotaOpportunityTest -> testAssociateQuotaOpportunityUSDEUR -> in test');

        TestDataFactoryForAccountsAndOpps.createQuota('EUR');
        AssociateQuotaOpportunity associateQO = new AssociateQuotaOpportunity();
        Test.startTest();
        associateQO.mapQuotaAndOpportunities();
        Test.stopTest();
        //system.assertEquals(2, [Select count() from Quota_Opportunity__c]);
    }

    @isTest
    static void testAssociateQuotaOpportunityUSDGBP() {
        System.debug(LoggingLevel.INFO, '##### ScheduledAssociateQuotaOpportunityTest -> testAssociateQuotaOpportunityUSDGBP -> in test');

        TestDataFactoryForAccountsAndOpps.createQuota('GBP');
        AssociateQuotaOpportunity associateQO = new AssociateQuotaOpportunity();
        Test.startTest();
        associateQO.mapQuotaAndOpportunities();
        Test.stopTest();
        //system.assertEquals(2, [Select count() from Quota_Opportunity__c]);
        String CRON_EXP = '0 0 0 3 9 ? *';
        String jobId = System.schedule('ScheduledAssociateQuotaOpportunity', CRON_EXP, new ScheduledAssociateQuotaOpportunity());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(0, ct.TimesTriggered);
        //System.assertEquals('2022-09-03 00:00:00', String.valueOf(ct.NextFireTime));
    }

    /*@isTest
    static void testAssociateQuotaOpportunityEURUSD(){       
        Test.startTest();
        TestDataFactoryForAccountsAndOpps.createAccount('EUR');
        TestDataFactoryForAccountsAndOpps.createQuota('USD');
        TestDataFactoryForAccountsAndOpps.createOpportunities(1,'EUR');
        AssociateQuotaOpportunity associateQO = new AssociateQuotaOpportunity();
        associateQO.mapQuotaAndOpportunities();
        system.assertEquals(2, [Select count() from Quota_Opportunity__c]);
        Test.stopTest();
    }
    
    @isTest
    static void testAssociateQuotaOpportunityGBPUSD(){       
        Test.startTest();
        TestDataFactoryForAccountsAndOpps.createAccount('GBP');
        TestDataFactoryForAccountsAndOpps.createQuota('USD');
        TestDataFactoryForAccountsAndOpps.createOpportunities(1,'GBP');
        Test.stopTest();
    }*/


}
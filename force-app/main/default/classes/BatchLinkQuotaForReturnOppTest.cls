@isTest
public class BatchLinkQuotaForReturnOppTest {

    @isTest
    static void testmapdataReturnOpp() {
        
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
        Quota_Opportunity__c qo = new Quota_Opportunity__c(Related_Quota__c = quota.id, Opportunity__c = opportunityClosed.Id);
        newQuotaOpportunities.add(qo);
        insert newQuotaOpportunities;

		Opportunity opportunityRefunded = new Opportunity(Name = 'Test Opportunity RTN', AccountId = account.Id, CloseDate = Date.Today(), Type = 'Rebate', 
                    StageName = 'Refunded - Closed', Amount = 6000, Returning_Opportunity__c = opportunityClosed.Id, 
                    Owner_Role_Copy__c = 'Management', CurrencyIsoCode = 'USD');
        insert opportunityRefunded;

        BatchLinkQuotaForReturnOpp b = new BatchLinkQuotaForReturnOpp();  
        database.executebatch(b,200); 
        String CRON_EXP = '0 0 0 3 9 ? *';
        String jobId = System.schedule('BatchLinkQuotaForReturnOpp', CRON_EXP, new BatchLinkQuotaForReturnOpp());
        Test.stopTest();
    }
    
}
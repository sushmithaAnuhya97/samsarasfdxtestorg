@isTest
public class CSRecordsBatchTest {
    
    @isTest
    static void testBatchExecution() {
        
        Account testAccounts = new Account();
        List<Opportunity> testOpportunities = new List<Opportunity>();

        // Create test accounts
        Account testAccount = new Account(Name = 'Testers 1 Inc',
		BillingStreet = '26 Napier Street',
		BillingCity = 'London',
		BillingPostalCode  = '1030',
		BillingCountry = 'United Kingdom',
		Billing_Email__c  = 'qdasdas@gmail.com',
		Organization_Size__c = '100 - 499',
        Customer_ARR__c = 100,
		Industry = 'Other');		
		TriggerHandler.bypass('GS_AccountTriggerHandler');
        insert testAccount;
        
        List<CS_Record__c> csRecords = [SELECT Id FROM CS_Record__c];
        if(!csRecords.IsEmpty()){
            delete csRecords;
        }
       

        // Start the batch job
        Test.startTest();
        CSRecordsBatch batchJob = new CSRecordsBatch();
        Database.executeBatch(batchJob);
        Test.stopTest();
    }

}
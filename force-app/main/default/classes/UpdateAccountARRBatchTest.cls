/**********************************************************************
Name: UpdateAccountARRBatchTest
Realated Class: UpdateAccountARRBatch
=======================================================================
Purpose: This class contains the test case methods for UpdateAccountARRBatch class                                                       
=======================================================================
History  
GTMS-12830	MANJUSHA JAMMULA	07/23/24	Intial Development
***********************************************************************/ 

@isTest
private class UpdateAccountARRBatchTest {

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
		Industry = 'Other',
        Customer_ARR__C = 10);		
		
        insert testAccount;
        
        // Create test opportunities associated with the test accounts
        Opportunity oppTest1 = new Opportunity(
            Name = 'Opportunity 1',
            AccountId = testAccount.Id,
            StageName = 'Closed Won',
            Type = 'Revenue Opportunity',
            CloseDate = Date.today().addDays(30),
            SBQQ__Renewal__c = false,
            SBQQ__AmendedContract__c = null,
            License_Start_Date__c = Date.today().addDays(-30),
            License_End_Date__c = Date.today(),
            Went_to_Closed_Won_Date__c = Date.today().addDays(-1)
            //ACV_Bookings_USD__c  = 500
        );
        testOpportunities.add(oppTest1);
        Opportunity oppTest2 = new Opportunity(
            Name = 'Opportunity 2',
            AccountId = testAccount.Id,
            StageName = 'Closed Won',
            Type = 'Warranty Exchange',
            CloseDate = Date.today().addDays(30),
            SBQQ__Renewal__c = true,
            SBQQ__AmendedContract__c = null,
            License_Start_Date__c = Date.today(),
            License_End_Date__c = Date.today().addDays(10)
            //ACV_Bookings_USD__c = 300
        );
        testOpportunities.add(oppTest2);
     	Opportunity oppTest3 = new Opportunity(
                Name = 'Test Opportunity 2',
                AccountId = testAccount.Id, // Assign to alternating accounts
                Type = 'Rebate',
            	StageName = 'Refunded - Closed',
            	CloseDate = Date.today().addDays(30),
                SBQQ__Renewal__c = false,
            	License_Start_Date__c = Date.today(),
                License_End_Date__c = Date.today().addDays(30)
                //ACV_Bookings_USD__c = 1000
        );
        testOpportunities.add(oppTest3);
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        insert testOpportunities;

        // Start the batch job
        Test.startTest();
        UpdateAccountARRBatch batchJob1 = new UpdateAccountARRBatch();
        Database.executeBatch(batchJob1);
        UpdateAccountARRBatch batchJob2 = new UpdateAccountARRBatch(Date.today().addDays(-31),Date.today().addDays(90));
        Database.executeBatch(batchJob2);
        UpdateAccountARRBatch batchJob3 = new UpdateAccountARRBatch(testAccount.Id);
        Database.executeBatch(batchJob3);
        Test.stopTest();

        // Verify the results
        Account updatedAccount = [SELECT Id, Customer_ARR__c FROM Account WHERE Id = :testAccount.Id];
        
        // Assert that Customer_ARR__c is updated correctly based on the test data
        System.assertEquals(0, updatedAccount.Customer_ARR__c, 'Customer ARR should be 0 for the updated Account');
        
        List<ManualAccountARRCalculation.ManualARRRequest> requestList = new List<ManualAccountARRCalculation.ManualARRRequest>();
        ManualAccountARRCalculation.ManualARRRequest request = new ManualAccountARRCalculation.ManualARRRequest();
        request.accountId = updatedAccount.Id;
        requestList.add(request);
        ManualAccountARRCalculation.calculateARR(requestList);
        
    }
    
    @isTest
    static void testBatchFinish() {
        
        Account testAccounts = new Account();
        Account testAccount = new Account(Name = 'Testers 1 Inc',
		BillingStreet = '26 Napier Street',
		BillingCity = 'London',
		BillingPostalCode  = '1030',
		BillingCountry = 'United Kingdom',
		Billing_Email__c  = 'qdasdas@gmail.com',
		Organization_Size__c = '100 - 499',
		Industry = 'Other',Customer_ARR__C = 10);		
        insert testAccount;
        Opportunity oppTest1 = new Opportunity(
            Name = 'Opportunity 1',
            AccountId = testAccount.Id,
            StageName = 'Closed Won',
            Type = 'Revenue Opportunity',
            CloseDate = Date.today().addDays(30),
            SBQQ__Renewal__c = false,
            SBQQ__AmendedContract__c = null,
            License_Start_Date__c = Date.today().addDays(-30),
            License_End_Date__c = Date.today().addDays(-1),
            Went_to_Closed_Won_Date__c = Date.today().addDays(-1)
            //ACV_Bookings_USD__c  = 500
        );
        
        Test.startTest();
        UpdateAccountARRBatch batchJob3 = new UpdateAccountARRBatch();
        Database.executeBatch(batchJob3);
        Test.stopTest();
        
    }
    
    @isTest
    static void testTriggerTest() {
        
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
		Industry = 'Other');		
		
        insert testAccount;
        
        // Create test opportunities associated with the test accounts
        Opportunity oppTest1 = new Opportunity(
            Name = 'Opportunity 1',
            AccountId = testAccount.Id,
            StageName = 'Incubate',
            Type = 'Revenue Opportunity',
            CloseDate = Date.today().addDays(30),
            SBQQ__Renewal__c = false,
            SBQQ__AmendedContract__c = null,
            License_Start_Date__c = Date.today().addDays(-30),
            License_End_Date__c = Date.today(),
            Went_to_Closed_Won_Date__c = Date.today().addDays(-1)
            //ACV_Bookings_USD__c  = 500
        );
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        insert oppTest1;
       oppTest1.StageName =  'Closed Won';
        update oppTest1;
    }
}
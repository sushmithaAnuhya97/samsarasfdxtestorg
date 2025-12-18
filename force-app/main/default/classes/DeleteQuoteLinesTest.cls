@isTest
private class DeleteQuoteLinesTest {
    @TestSetup
    static void setupTestData() {
        // Create test data using MercuryPhase2DataFactory
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('RequestTrackerTriggerHandler');
        TriggerHandler.bypass('SBQQ__QuoteTriggerHandler');
        TriggerHandler.bypass('SBQQ__QuoteLineTriggerHandler');
        TriggerHandler.bypass('ShippingAddressTriggerHandler');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        Account testAccount = MercuryPhase2DataFactory.createAccount('Test Account', true);
        Contact testContact = MercuryPhase2DataFactory.createContact(testAccount.Id, true);
        Shipping_Address__c testShippingAddress = MercuryPhase2DataFactory.createShippingAddress(testAccount.Id, testContact.Id, true);
        
        // Create Opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        
        Test.startTest();
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert testOpp;
        
        // Create Product and Pricebook Entry
        Product2 testProduct = MercuryPhase2DataFactory.createProduct(true);
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
        
        // Create Quote
        SBQQ__Quote__c testQuote = MercuryPhase2DataFactory.createQuote(testAccount.Id, testOpp.Id, true);
        
        // Create Quote Lines
        SBQQ__QuoteLine__c quoteLine = MercuryPhase2DataFactory.createQuoteLines(
            testAccount.Id, 
            testQuote.Id, 
            testShippingAddress.Id, 
            testProduct.Id, 
            pbe.Id, 
            100, 
            1, 
            true
        );
        
        // Create Amendment Tracker
        Request_Tracker__c rt = MercuryPhase2DataFactory.createAmendmentTracker(testAccount.Id, testContact.Id, pricebookId, testProduct.Id, false);
        rt.Shipping_Address_Id__c = testShippingAddress.Id;
        rt.Opportunity_Id__c = testOpp.Id;
        rt.Quote_Id__c = testQuote.Id;
        
        insert rt;
        TriggerHandler.clearAllBypasses();
      
        Test.stopTest();
    }
    
    @isTest
    static void testDeleteQuoteLines() {
        // Get the test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Request_Tracker__c tracker = [SELECT Id, 
                                    Account_Id__c, 
                                    Shipping_Address_Id__c,
                                    Opportunity_Id__c,
                                    Quote_Id__c,
                                    Request__c, 
                                    Step_Status__c, 
                                    Status__c, 
                                    Transaction_Type__c
                                    FROM Request_Tracker__c 
                                    WHERE Account_Id__c = :testAccount.Id 
                                    LIMIT 1];
        
        // Create test payload
        OrderPayload payload = new OrderPayload();
        payload.order = new OrderPayload.Order();
        payload.order.account_id = testAccount.Id;
        
        Test.startTest();
        // Execute the job
        TriggerHandler.bypass('RequestTrackerTriggerHandler');
        DeleteQuoteLines job = new DeleteQuoteLines(payload, 'Step1', tracker, 0);
        System.enqueueJob(job);
        Test.stopTest();
        
        // Verify the quote lines were deleted
        List<SBQQ__QuoteLine__c> remainingQuoteLines = [SELECT Id 
                                                       FROM SBQQ__QuoteLine__c 
                                                       WHERE SBQQ__Quote__c = :tracker.Quote_Id__c];
        System.assertEquals(0, remainingQuoteLines.size(), 'All quote lines should be deleted');
    }
}
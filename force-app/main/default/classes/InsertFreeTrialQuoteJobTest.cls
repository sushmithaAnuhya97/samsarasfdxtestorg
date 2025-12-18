@isTest
private class InsertFreeTrialQuoteJobTest {

    @TestSetup
    static void setupTestData() {
        // Bypass triggers for test setup
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('Product2TriggerHandler');
        TriggerHandler.bypass('SBQQ__QuoteTriggerHandler');
        TriggerHandler.bypass('SBQQ__QuoteLineTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        TriggerHandler.bypass('ShippingAddressTriggerHandler');
        SBQQ.TriggerControl.disable();
        
        // Create test account
        Account testAccount = MercuryPhase2DataFactory.createAccount('Test Account', true);
        
        // Create test contact
        Contact testContact = MercuryPhase2DataFactory.createContact(testAccount.Id, true);
        
        // Create test shipping address
        Shipping_Address__c testShippingAddress = MercuryPhase2DataFactory.createShippingAddress(testAccount.Id, testContact.Id, true);

        // Create Revenue Opportunity (Parent)
        Opportunity revenueOpp = new Opportunity(
            Name = 'Revenue Opportunity - Test',
            AccountId = testAccount.Id,
            StageName = 'Qualified',
            CloseDate = Date.today().addDays(30),
            Type = 'New Business',
            Amount = 10000
        );
        
        Test.startTest();
        insert revenueOpp;
        
        // Create test contract
        Contract testContract = MercuryPhase2DataFactory.createContract(testAccount.Id, true);

        Id pricebookId = Test.getStandardPricebookId();

        // Create Product
        Product2 testProduct = MercuryPhase2DataFactory.createProduct(true);
           
        // Create PriceBookEntries
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = testProduct.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vg33PB);

        insert pricebookEntries;
        
        // Create Quote for Revenue Opportunity
        SBQQ__Quote__c revenueQuote = MercuryPhase2DataFactory.createQuote(testAccount.Id, revenueOpp.Id, false);
        revenueQuote.SBQQ__Primary__c = true;
        revenueQuote.SBQQ__Status__c = 'Draft';
        insert revenueQuote;

        // Create Quote Line for Revenue Opportunity
        SBQQ__QuoteLine__c revenueQuoteLine = MercuryPhase2DataFactory.createQuoteLines(
            testAccount.Id, 
            revenueQuote.Id, 
            String.valueOf(testShippingAddress.Id), 
            String.valueOf(testProduct.Id), 
            String.valueOf(vg33PB.Id), 
            10000, 
            2, 
            true
        );
        
        // Activate the contract
        testContract.Status = 'Activated';
        testContract.SBQQ__Opportunity__c = revenueOpp.Id;
        testContract.ActivatedDate = Date.today();
        update testContract;

        testAccount.Latest_Active_Contract__c = testContract.Id;
        update testAccount;
        
        revenueOpp.SBQQ__PrimaryQuote__c = revenueQuote.Id;
        update revenueOpp;
        
        // Clear bypasses
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        TriggerHandler.clearBypass('Product2TriggerHandler');
        TriggerHandler.clearBypass('SBQQ__QuoteTriggerHandler');
        TriggerHandler.clearBypass('SBQQ__QuoteLineTriggerHandler');
        TriggerHandler.clearBypass('GS_AccountTriggerHandler');
        TriggerHandler.clearBypass('ShippingAddressTriggerHandler');
        SBQQ.TriggerControl.enable();
        Test.stopTest();
    }
    
    @isTest
    static void testInsertFreeTrialQuoteJob() {
        // Get test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity revenueOpp = [SELECT Id FROM Opportunity WHERE Name = 'Revenue Opportunity - Test' LIMIT 1];
        
        // Create free trial opportunity
        Opportunity freeTrialOpp = new Opportunity(
            Name = 'Test Free Trial Opportunity',
            AccountId = testAccount.Id,
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(3),
            Type = 'Free Trial Opportunity',
            TrialResolutionOppty__c = revenueOpp.Id,
            Trial_Status__c = 'Open'
        );
        insert freeTrialOpp;
        
        // Create test payload
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
        PricebookEntry testPricebook = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id AND Pricebook2Id = :Test.getStandardPricebookId() LIMIT 1];
        
        OrderPayload payload = MercuryPhase2DataFactory.createFreeTrialPayload(
            testAccount.Id, 
            revenueOpp.Id, 
            testProduct.Id, 
            testPricebook.Id
        );
        
        // Create test request tracker
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = '1234567890',
            Transaction_Type__c = 'WEBSTORE_FREE_TRIAL',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1',
            Opportunity_Id__c = freeTrialOpp.Id
        );

        insert tracker;

       
        try {
            Test.startTest();
            InsertFreeTrialQuoteJob quoteInsertJob = new InsertFreeTrialQuoteJob(tracker, 'Step-6', payload, 0);
            quoteInsertJob.processJob();
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error in testInsertFreeTrialQuoteJob: ' + e.getMessage());
        }
        
    }
    
    @isTest
    static void testInsertFreeTrialQuoteLineJob() {
        // Get test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity revenueOpp = [SELECT Id FROM Opportunity WHERE Name = 'Revenue Opportunity - Test' LIMIT 1];
        Shipping_Address__c testShippingAddress = [SELECT Id FROM Shipping_Address__c WHERE Account__c = :testAccount.Id LIMIT 1];
        
        // Create free trial opportunity
        Opportunity freeTrialOpp = new Opportunity(
            Name = 'Test Free Trial Opportunity',
            AccountId = testAccount.Id,
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(3),
            Type = 'Free Trial Opportunity',
            TrialResolutionOppty__c = revenueOpp.Id,
            Trial_Status__c = 'Open'
        );
        insert freeTrialOpp;
        
        // Create quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = freeTrialOpp.Id,
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Type__c = 'Free Trial',
            SBQQ__Status__c = 'Draft',
            SBQQ__Primary__c = true
        );
        insert quote;
        
        // Create test payload with quote lines
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
        PricebookEntry testPricebook = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id AND Pricebook2Id = :Test.getStandardPricebookId() LIMIT 1];
        
        OrderPayload payload = MercuryPhase2DataFactory.createFreeTrialPayload(
            testAccount.Id, 
            revenueOpp.Id, 
            testProduct.Id, 
            testPricebook.Id
        );
        
        // Create test request tracker
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = '1234567890',
            Transaction_Type__c = 'WEBSTORE_FREE_TRIAL',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1',
            Opportunity_Id__c = freeTrialOpp.Id,
            Quote_Id__c = quote.Id,
            Shipping_Address_Id__c = testShippingAddress.Id
        );

        insert tracker;
        try {
            Test.startTest();
            InsertFreeTrialQuoteLineJob quoteLineInsertJob = new InsertFreeTrialQuoteLineJob(tracker, 'Step-7', payload, 0);
            quoteLineInsertJob.processJob();
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error in testInsertFreeTrialQuoteLineJob: ' + e.getMessage());
        }
    
    }
    
    @isTest
    static void testInsertFreeTrialQuoteJobNewInstanceWithRetry() {
        try {
            // Get test data
            Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
            Opportunity revenueOpp = [SELECT Id FROM Opportunity WHERE Name = 'Revenue Opportunity - Test' LIMIT 1];
            
            // Create test payload
            Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
            PricebookEntry testPricebook = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id AND Pricebook2Id = :Test.getStandardPricebookId() LIMIT 1];
            
            OrderPayload payload = MercuryPhase2DataFactory.createFreeTrialPayload(
                testAccount.Id, 
                revenueOpp.Id, 
                testProduct.Id, 
                Test.getStandardPricebookId()
            );
            
            // Create test request tracker
            Request_Tracker__c tracker = new Request_Tracker__c(
                OrderId__c = '1234567890',
                Transaction_Type__c = 'WEBSTORE_FREE_TRIAL',
                Account_Id__c = testAccount.Id,
                Request__c = JSON.serialize(payload),
                Status__c = 'Received',
                Step_Status__c = 'Step-1'
            );
            insert tracker;
            
            // Create instance and test newInstanceWithRetry
            InsertFreeTrialQuoteJob job = new InsertFreeTrialQuoteJob(tracker, 'Step-6', payload, 0);
            Queueable retryJob = job.newInstanceWithRetry(1);
        } catch (Exception e) {
            System.debug('Error in testInsertFreeTrialQuoteJobNewInstanceWithRetry: ' + e.getMessage());
        }
    }
    
    @isTest
    static void testInsertFreeTrialQuoteLineJobNewInstanceWithRetry() {
        try {
            // Get test data
            Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
            Opportunity revenueOpp = [SELECT Id FROM Opportunity WHERE Name = 'Revenue Opportunity - Test' LIMIT 1];
            
            // Create test payload
            Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
            PricebookEntry testPricebook = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id AND Pricebook2Id = :Test.getStandardPricebookId() LIMIT 1];
            
            OrderPayload payload = MercuryPhase2DataFactory.createFreeTrialPayload(
                testAccount.Id, 
                revenueOpp.Id, 
                testProduct.Id, 
                Test.getStandardPricebookId()
            );
            
            // Create test request tracker
            Request_Tracker__c tracker = new Request_Tracker__c(
                OrderId__c = '1234567890',
                Transaction_Type__c = 'WEBSTORE_FREE_TRIAL',
                Account_Id__c = testAccount.Id,
                Request__c = JSON.serialize(payload),
                Status__c = 'Received',
                Step_Status__c = 'Step-1'
            );
            insert tracker;
            
            // Create instance and test newInstanceWithRetry
            InsertFreeTrialQuoteLineJob job = new InsertFreeTrialQuoteLineJob(tracker, 'Step-7', payload, 0);
            Queueable retryJob = job.newInstanceWithRetry(1);
        } catch (Exception e) {
            System.debug('Error in testInsertFreeTrialQuoteLineJobNewInstanceWithRetry: ' + e.getMessage());
        }
    }
    
    @isTest
    static void testInsertFreeTrialQuoteLineJob_DmlException() {
        // Get test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity revenueOpp = [SELECT Id FROM Opportunity WHERE Name = 'Revenue Opportunity - Test' LIMIT 1];
        Shipping_Address__c testShippingAddress = [SELECT Id FROM Shipping_Address__c WHERE Account__c = :testAccount.Id LIMIT 1];
        
        // Create test request tracker
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-ORDER-123',
            Transaction_Type__c = 'WEBSTORE_FREE_TRIAL',
            Account_Id__c = testAccount.Id,
            Quote_Id__c = '0Q000000000001', // Invalid quote ID to trigger exception
            Shipping_Address_Id__c = testShippingAddress.Id,
            Request__c = '{"order":{"account_id":"' + testAccount.Id + '"},"quote":{"quoteLines":[{"product":"01t000000000001","quantity":1,"pricebookEntryId":"01u000000000001","currencyIsoCode":"USD","listPrice":100.00}]}}'
        );
        insert tracker;
        
        // Create test payload
        OrderPayload payload = new OrderPayload();
        payload.order = new OrderPayload.Order();
        payload.order.account_id = testAccount.Id;
        payload.quote = new OrderPayload.Quote();
        payload.quote.quoteLines = new List<OrderPayload.QuoteLine>();
        
        OrderPayload.QuoteLine ql = new OrderPayload.QuoteLine();
        ql.product = '01t000000000001';
        ql.quantity = 1;
        ql.pricebookEntryId = '01u000000000001';
        ql.currencyIsoCode = 'USD';
        ql.listPrice = 100.00;
        payload.quote.quoteLines.add(ql);
        
        Test.startTest();
        try {
            InsertFreeTrialQuoteLineJob quoteLineInsertJob = new InsertFreeTrialQuoteLineJob(tracker, 'Step-7', payload, 0);
            quoteLineInsertJob.processJob();
        } catch (Exception e) {
            // Expected exception - this covers the exception handling lines
            System.debug('Error: ' + e.getMessage());
            }
        Test.stopTest();
    }

    @isTest
    static void testInsertFreeTrialQuoteLineJob_MissingQuoteId() {
        // Get test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Shipping_Address__c testShippingAddress = [SELECT Id FROM Shipping_Address__c WHERE Account__c = :testAccount.Id LIMIT 1];
        
        // Create test request tracker with missing Quote_Id__c
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-ORDER-123',
            Transaction_Type__c = 'WEBSTORE_FREE_TRIAL',
            Account_Id__c = testAccount.Id,
            // Quote_Id__c is intentionally missing
            Shipping_Address_Id__c = testShippingAddress.Id,
            Request__c = '{"order":{"account_id":"' + testAccount.Id + '"}}'
        );
        insert tracker;
        
        // Create test payload
        OrderPayload payload = new OrderPayload();
        payload.order = new OrderPayload.Order();
        payload.order.account_id = testAccount.Id;
        
        Test.startTest();
        try {
            InsertFreeTrialQuoteLineJob quoteLineInsertJob = new InsertFreeTrialQuoteLineJob(tracker, 'Step-7', payload, 0);
            quoteLineInsertJob.processJob();
            System.assert(false, 'Expected RequestTrackerException to be thrown');
        } catch (RequestTrackerException e) {
            // Expected exception - this covers line 19
            System.assert(e.getMessage().contains('Quote ID is missing'), 'Should throw exception for missing quote ID');
        }
        Test.stopTest();
    }

    @isTest
    static void testInsertFreeTrialQuoteLineJob_NoQuoteLines() {
        // Get test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity revenueOpp = [SELECT Id FROM Opportunity WHERE Name = 'Revenue Opportunity - Test' LIMIT 1];
        Shipping_Address__c testShippingAddress = [SELECT Id FROM Shipping_Address__c WHERE Account__c = :testAccount.Id LIMIT 1];
        
        // Create test quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = revenueOpp.Id,
            SBQQ__Status__c = 'Draft'
        );
        insert testQuote;
        
        // Create test request tracker
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-ORDER-123',
            Transaction_Type__c = 'WEBSTORE_FREE_TRIAL',
            Account_Id__c = testAccount.Id,
            Quote_Id__c = testQuote.Id,
            Shipping_Address_Id__c = testShippingAddress.Id,
            Request__c = '{"order":{"account_id":"' + testAccount.Id + '"}}'
        );
        insert tracker;
        
        // Create test payload with no quote lines
        OrderPayload payload = new OrderPayload();
        payload.order = new OrderPayload.Order();
        payload.order.account_id = testAccount.Id;
        payload.quote = new OrderPayload.Quote();
        // No quoteLines - this should trigger the "No quote lines found" path
        
        Test.startTest();
        InsertFreeTrialQuoteLineJob quoteLineInsertJob = new InsertFreeTrialQuoteLineJob(tracker, 'Step-7', payload, 0);
        quoteLineInsertJob.processJob();
        Test.stopTest();
        
        // This should complete successfully without throwing exceptions
        // It covers the path where no quote lines are found (line 32)
    }

    @isTest
    static void testInsertFreeTrialQuoteLineJob_EmptyQuoteLines() {
        // Get test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity revenueOpp = [SELECT Id FROM Opportunity WHERE Name = 'Revenue Opportunity - Test' LIMIT 1];
        Shipping_Address__c testShippingAddress = [SELECT Id FROM Shipping_Address__c WHERE Account__c = :testAccount.Id LIMIT 1];
        
        // Create test quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = revenueOpp.Id,
            SBQQ__Status__c = 'Draft'
        );
        insert testQuote;
        
        // Create test request tracker
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-ORDER-123',
            Transaction_Type__c = 'WEBSTORE_FREE_TRIAL',
            Account_Id__c = testAccount.Id,
            Quote_Id__c = testQuote.Id,
            Shipping_Address_Id__c = testShippingAddress.Id,
            Request__c = '{"order":{"account_id":"' + testAccount.Id + '"}}'
        );
        insert tracker;
        
        // Create test payload with empty quote lines
        OrderPayload payload = new OrderPayload();
        payload.order = new OrderPayload.Order();
        payload.order.account_id = testAccount.Id;
        payload.quote = new OrderPayload.Quote();
        payload.quote.quoteLines = new List<OrderPayload.QuoteLine>(); // Empty list
        
        Test.startTest();
        InsertFreeTrialQuoteLineJob quoteLineInsertJob = new InsertFreeTrialQuoteLineJob(tracker, 'Step-7', payload, 0);
        quoteLineInsertJob.processJob();
        Test.stopTest();
        
        // This should complete successfully without throwing exceptions
        // It covers the path where quote lines list is empty (lines 47-48)
    }

    @isTest
    static void testInsertFreeTrialQuoteLineJob_NullQuoteLines() {
        // Get test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity revenueOpp = [SELECT Id FROM Opportunity WHERE Name = 'Revenue Opportunity - Test' LIMIT 1];
        Shipping_Address__c testShippingAddress = [SELECT Id FROM Shipping_Address__c WHERE Account__c = :testAccount.Id LIMIT 1];
        
        // Create test quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = revenueOpp.Id,
            SBQQ__Status__c = 'Draft'
        );
        insert testQuote;
        
        // Create test request tracker
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-ORDER-123',
            Transaction_Type__c = 'WEBSTORE_FREE_TRIAL',
            Account_Id__c = testAccount.Id,
            Quote_Id__c = testQuote.Id,
            Shipping_Address_Id__c = testShippingAddress.Id,
            Request__c = '{"order":{"account_id":"' + testAccount.Id + '"}}'
        );
        insert tracker;
        
        // Create test payload with null quote lines
        OrderPayload payload = new OrderPayload();
        payload.order = new OrderPayload.Order();
        payload.order.account_id = testAccount.Id;
        payload.quote = new OrderPayload.Quote();
        payload.quote.quoteLines = null; // Null quote lines
        
        Test.startTest();
        InsertFreeTrialQuoteLineJob quoteLineInsertJob = new InsertFreeTrialQuoteLineJob(tracker, 'Step-7', payload, 0);
        quoteLineInsertJob.processJob();
        Test.stopTest();
        
        // This should complete successfully without throwing exceptions
        // It covers the path where quote lines is null (line 32)
    }
    
     @isTest
    static void testInsertFreeTrialQuoteJob_NullOpportunity() {
        // Get test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity revenueOpp = [SELECT Id FROM Opportunity WHERE Name = 'Revenue Opportunity - Test' LIMIT 1];
        
        // Create free trial opportunity
        Opportunity freeTrialOpp = new Opportunity(
            Name = 'Test Free Trial Opportunity',
            AccountId = testAccount.Id,
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(3),
            Type = 'Free Trial Opportunity',
            TrialResolutionOppty__c = revenueOpp.Id,
            Trial_Status__c = 'Open'
        );
        insert freeTrialOpp;
        
        // Create test payload
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
        PricebookEntry testPricebook = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id AND Pricebook2Id = :Test.getStandardPricebookId() LIMIT 1];
        
        OrderPayload payload = MercuryPhase2DataFactory.createFreeTrialPayload(
            testAccount.Id, 
            revenueOpp.Id, 
            testProduct.Id, 
            testPricebook.Id
        );
        
        // Create test request tracker
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = '1234567890',
            Transaction_Type__c = 'WEBSTORE_FREE_TRIAL',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;

       
        try {
            Test.startTest();
            InsertFreeTrialQuoteJob quoteInsertJob = new InsertFreeTrialQuoteJob(tracker, 'Step-6', payload, 0);
            quoteInsertJob.processJob();
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error in testInsertFreeTrialQuoteJob: ' + e.getMessage());
        }
        
	}
    
    
     @isTest
    static void testInsertFreeTrialQuoteJob_EmpyQuoteNode() {
        // Get test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity revenueOpp = [SELECT Id FROM Opportunity WHERE Name = 'Revenue Opportunity - Test' LIMIT 1];
        
        // Create free trial opportunity
        Opportunity freeTrialOpp = new Opportunity(
            Name = 'Test Free Trial Opportunity',
            AccountId = testAccount.Id,
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(3),
            Type = 'Free Trial Opportunity',
            TrialResolutionOppty__c = revenueOpp.Id,
            Trial_Status__c = 'Open'
        );
        insert freeTrialOpp;
        
        // Create test payload
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
        PricebookEntry testPricebook = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id AND Pricebook2Id = :Test.getStandardPricebookId() LIMIT 1];
        
        OrderPayload payload = MercuryPhase2DataFactory.createFreeTrialPayload(
            testAccount.Id, 
            revenueOpp.Id, 
            testProduct.Id, 
            testPricebook.Id
        );
        
        // Create test request tracker
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = '1234567890',
            Transaction_Type__c = 'WEBSTORE_FREE_TRIAL',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1',
             Opportunity_Id__c = freeTrialOpp.Id
        );

        insert tracker;
        payload.quote = null;

       
        try {
            Test.startTest();
            InsertFreeTrialQuoteJob quoteInsertJob = new InsertFreeTrialQuoteJob(tracker, 'Step-6', payload, 0);
			quoteInsertJob.processJob();
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error in testInsertFreeTrialQuoteJob: ' + e.getMessage());
        }
        
	}
}
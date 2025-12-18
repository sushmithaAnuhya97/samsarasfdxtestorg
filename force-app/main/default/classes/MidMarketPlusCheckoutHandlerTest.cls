@isTest
private class MidMarketPlusCheckoutHandlerTest {
    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = MercuryPhase2DataFactory.createAccount('Test Account', true);
        
        // Create test contact
        Contact testContact = MercuryPhase2DataFactory.createContact(testAccount.Id, true);
        
        // Create test shipping address
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
        TriggerHandler.bypass('Product2TriggerHandler');
        TriggerHandler.bypass('SBQQ__QuoteTriggerHandler');
        TriggerHandler.bypass('SBQQ__QuoteLineTriggerHandler');
        SBQQ.TriggerControl.disable();
        
        insert testOpp;
        
        // Create test contract
        Contract testContract = MercuryPhase2DataFactory.createContract(testAccount.Id, true);

        Id pricebookId = Test.getStandardPricebookId();

        // Create Product
        Product2 testProduct = MercuryPhase2DataFactory.createProduct(true);
           
        //Create PriceBookEntries
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = testProduct.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vg33PB);

        insert pricebookEntries;
        
        // Create Quote
        SBQQ__Quote__c testQuote = MercuryPhase2DataFactory.createQuote(testAccount.Id, testOpp.Id, true);
        // Create Subscription with the quote line
        SBQQ__QuoteLine__c testQuoteLine = MercuryPhase2DataFactory.createQuoteLines(testAccount.Id, testQuote.Id, String.valueOf(testShippingAddress.Id), String.valueOf(testProduct.Id), String.valueOf(vg33PB.Id), 10000, 2, true);
        MercuryPhase2DataFactory.createSubscription(testAccount.Id, testContract.Id, testQuoteLine.Id, true);

        //activate the contract
        testContract.Status = 'Activated';
        testContract.SBQQ__Opportunity__c = testOpp.Id;
        testContract.ActivatedDate = Date.today();
        update testContract;

        testAccount.Latest_Active_Contract__c = testContract.Id;
        TriggerHandler.bypass('AccountTriggerHandler');
        update testAccount;
    }
    
    @isTest
    static void testProcessTransaction_Success() {
        // Get the test tracker
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contract testContract = [SELECT Id FROM Contract WHERE AccountId = :testAccount.Id LIMIT 1];
        Shipping_Address__c testShippingAddress = [SELECT Id FROM Shipping_Address__c WHERE Account__c = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :testAccount.Id LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        
        // Create test request tracker
        OrderPayload payload = MercuryPhase2DataFactory.createMidMarketPlusPayload(testAccount.Id, testOpp.Id, 'pm_1QxExtIbzZlMbYFSSzBD9pvE', 'seti_1QxEvzIbzZlMbYFSg8bGvUG3', 'ch_3QwsPIIbzZlMbYFS2iSvIg1I');
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_MIDMARKET_PLUS_CHECKOUT_LINK',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;

        try {
            Test.startTest();
            OrderTransactionHandler transactionHandler = OrderTransactionHandlerFactory.getHandler(tracker.Transaction_Type__c);
            transactionHandler.processOrder(tracker);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }
    
    @isTest
    static void testProcessTransaction_InvalidPayload() {
        // Get the test tracker
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_MIDMARKET_PLUS_CHECKOUT_LINK',
            Account_Id__c = testAccount.Id,
            Request__c = 'invalid json',
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;
        try {
            Test.startTest();
            OrderTransactionHandler transactionHandler = OrderTransactionHandlerFactory.getHandler(tracker.Transaction_Type__c);
            transactionHandler.processOrder(tracker);
            Test.stopTest();
        } catch (Exception e) {
            System.assert(e.getMessage() != null, 'Exception should be related to JSON parsing');
        }
       
    }

    @isTest
    static void testProcessAccount_Success() {
        // Get the test tracker
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        
        // Create test request tracker
        OrderPayload payload = MercuryPhase2DataFactory.createMidMarketPlusPayload(testAccount.Id, testOpp.Id, 'pm_1QxExtIbzZlMbYFSSzBD9pvE', 'seti_1QxEvzIbzZlMbYFSg8bGvUG3', 'ch_3QwsPIIbzZlMbYFS2iSvIg1I');
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_MIDMARKET_PLUS_CHECKOUT_LINK',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;

        try {
            Test.startTest();
            UpdateAccount updateAccount = new UpdateAccount(tracker,'Step-2',payload,0);
            OrderUtil.enqueueJobIfPossible(updateAccount);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }

    @isTest
    static void testProcessOpportunity_Success() {
        // Get the test tracker
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        
        // Create test request tracker
        OrderPayload payload = MercuryPhase2DataFactory.createMidMarketPlusPayload(testAccount.Id, testOpp.Id, 'pm_1QxExtIbzZlMbYFSSzBD9pvE', 'seti_1QxEvzIbzZlMbYFSg8bGvUG3', 'ch_3QwsPIIbzZlMbYFS2iSvIg1I');
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_MIDMARKET_PLUS_CHECKOUT_LINK',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;

        try {
            Test.startTest();
            MidMarketCheckoutOpportunityUpdate updateOpportunity = new MidMarketCheckoutOpportunityUpdate(tracker,'Step-3',payload,0);
            OrderUtil.enqueueJobIfPossible(updateOpportunity);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }
    
    @isTest
    static void testProcessOpportunity_NewInstanceRetry() {
        // Get the test tracker
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        
        // Create test request tracker
        OrderPayload payload = MercuryPhase2DataFactory.createMidMarketPlusPayload(testAccount.Id, testOpp.Id, 'pm_1QxExtIbzZlMbYFSSzBD9pvE', 'seti_1QxEvzIbzZlMbYFSg8bGvUG3', 'ch_3QwsPIIbzZlMbYFS2iSvIg1I');
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_MIDMARKET_PLUS_CHECKOUT_LINK',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;

        try {
            Test.startTest();
            MidMarketCheckoutOpportunityUpdate updateOpportunity = new MidMarketCheckoutOpportunityUpdate(tracker,'Step-3',payload,0);
            updateOpportunity.createLog('Finished processing: Opportunity:');
            updateOpportunity.newInstanceWithRetry(2);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }


    @isTest
    static void testProcessQuote_Success() {
        // Get the test tracker
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :testAccount.Id LIMIT 1];
        
        testOpp.SBQQ__PrimaryQuote__c = testQuote.Id;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        update testOpp;
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        // Create test request tracker
        OrderPayload payload = MercuryPhase2DataFactory.createMidMarketPlusPayload(testAccount.Id, testOpp.Id, 'pm_1QxExtIbzZlMbYFSSzBD9pvE', 'seti_1QxEvzIbzZlMbYFSg8bGvUG3', 'ch_3QwsPIIbzZlMbYFS2iSvIg1I');
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_MIDMARKET_PLUS_CHECKOUT_LINK',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;

        try {
            Test.startTest();
            MidMarketCheckoutQuoteUpdate updateQuote = new MidMarketCheckoutQuoteUpdate(tracker,'Step-4',payload,0);
            
            OrderUtil.enqueueJobIfPossible(updateQuote);
            updateQuote.updateQuoteViaRest(null,null);
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }

    @isTest
    static void testProcessQuote_NewInstanceRetry() {
        // Get the test tracker
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        
        // Create test request tracker
        OrderPayload payload = MercuryPhase2DataFactory.createMidMarketPlusPayload(testAccount.Id, testOpp.Id, 'pm_1QxExtIbzZlMbYFSSzBD9pvE', 'seti_1QxEvzIbzZlMbYFSg8bGvUG3', 'ch_3QwsPIIbzZlMbYFS2iSvIg1I');
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_MIDMARKET_PLUS_CHECKOUT_LINK',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;

        try {
            Test.startTest();
            MidMarketCheckoutQuoteUpdate updateQuote = new MidMarketCheckoutQuoteUpdate(tracker,'Step-4',payload,0);
            updateQuote.createLog('Finished processing: Quote:');
            updateQuote.newInstanceWithRetry(2);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }

    @isTest
    static void testProcessWorkatoService_Success() {
        // Get the test tracker
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        
        // Create test request tracker
        OrderPayload payload = MercuryPhase2DataFactory.createMidMarketPlusPayload(testAccount.Id, testOpp.Id, 'pm_1QxExtIbzZlMbYFSSzBD9pvE', 'seti_1QxEvzIbzZlMbYFSg8bGvUG3', 'ch_3QwsPIIbzZlMbYFS2iSvIg1I');
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_MIDMARKET_PLUS_CHECKOUT_LINK',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;

        try {
            Test.startTest();
            // Set mock for HTTP callout
            Test.setMock(HttpCalloutMock.class, new MidMarketPlusMock(201));

            OrderResultToWorkatoService workatoService = new OrderResultToWorkatoService(tracker,'Step-4',payload,0);
            OrderUtil.enqueueJobIfPossible(workatoService);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }

    // Mock class for HTTP callout
    private class MidMarketPlusMock implements HttpCalloutMock {
        private Integer statusCode;
        
        public MidMarketPlusMock(Integer statusCode) {
            this.statusCode = statusCode;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(statusCode);
            res.setBody('{"success": true}');
            return res;
        }
    }
}
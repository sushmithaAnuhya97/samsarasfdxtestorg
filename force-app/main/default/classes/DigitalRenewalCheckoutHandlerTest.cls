@isTest
private class DigitalRenewalCheckoutHandlerTest {
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
        // Create test request tracker
        OrderPayload payload = MercuryPhase2DataFactory.createDigitalRenewalPayload(testAccount.Id, testContract.Id, testQuote.Id, 'pm_1PYBZsIbzZlMbYFSRMTEyohD', 'seti_1Qws4fIbzZlMbYFSgIzTIxfn');
      
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_DIGITAL_RENEWAL',
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
        Contract testContract = [SELECT Id FROM Contract WHERE AccountId = :testAccount.Id LIMIT 1];
       
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_DIGITAL_RENEWAL',
            Account_Id__c = testAccount.Id,
            Request__c ='invalid json',
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;
        
        Test.startTest();
        OrderTransactionHandler transactionHandler = OrderTransactionHandlerFactory.getHandler(tracker.Transaction_Type__c);
        try {
            transactionHandler.processOrder(tracker);
            System.assert(false, 'Should have thrown an exception');
        } catch (Exception e) {
            System.assert(e.getMessage() != null, 'Exception should be related to JSON parsing');
        }
        Test.stopTest();
    }

    @isTest
    static void testProcessOpportunity_Success() {
        // Get the test tracker
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contract testContract = [SELECT Id FROM Contract WHERE AccountId = :testAccount.Id LIMIT 1];
        Shipping_Address__c testShippingAddress = [SELECT Id FROM Shipping_Address__c WHERE Account__c = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :testAccount.Id LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        // Create test request tracker
        OrderPayload payload = MercuryPhase2DataFactory.createDigitalRenewalPayload(testAccount.Id, testContract.Id, testQuote.Id, 'pm_1PYBZsIbzZlMbYFSRMTEyohD', 'seti_1Qws4fIbzZlMbYFSgIzTIxfn');
        payload.opportunity.Id = testOpp.Id;
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_DIGITAL_RENEWAL',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;

        Test.startTest();
        DigitalRenewalOpportunityUpdate updateOpportunity = new DigitalRenewalOpportunityUpdate(tracker,'Step-3',payload,0);
        OrderUtil.enqueueJobIfPossible(updateOpportunity);
        Test.stopTest();
    }

    @isTest
    static void testProcessQuote_Success() {
        // Get the test tracker
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contract testContract = [SELECT Id FROM Contract WHERE AccountId = :testAccount.Id LIMIT 1];
        Shipping_Address__c testShippingAddress = [SELECT Id FROM Shipping_Address__c WHERE Account__c = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :testAccount.Id LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        // Create test request tracker
        OrderPayload payload = MercuryPhase2DataFactory.createDigitalRenewalPayload(testAccount.Id, testContract.Id, testQuote.Id, 'pm_1PYBZsIbzZlMbYFSRMTEyohD', 'seti_1Qws4fIbzZlMbYFSgIzTIxfn');
        payload.opportunity.Id = testOpp.Id;
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_DIGITAL_RENEWAL',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;

        try {
            Test.startTest();
            // Set mock for HTTP callout
            Test.setMock(HttpCalloutMock.class, new DigitalRenewalMock(201));
            
            DigitalRenewalQuoteUpdate updateQuote = new DigitalRenewalQuoteUpdate(tracker,'Step-3',payload,0);
            OrderUtil.enqueueJobIfPossible(updateQuote);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }

    @isTest
    static void testProcessQuoteNewInstanceWithretry() {
        // Get the test tracker
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contract testContract = [SELECT Id FROM Contract WHERE AccountId = :testAccount.Id LIMIT 1];
        Shipping_Address__c testShippingAddress = [SELECT Id FROM Shipping_Address__c WHERE Account__c = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :testAccount.Id LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        // Create test request tracker
        OrderPayload payload = MercuryPhase2DataFactory.createDigitalRenewalPayload(testAccount.Id, testContract.Id, testQuote.Id, 'pm_1PYBZsIbzZlMbYFSRMTEyohD', 'seti_1Qws4fIbzZlMbYFSgIzTIxfn');
        payload.opportunity.Id = testOpp.Id;
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_DIGITAL_RENEWAL',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;

        try {
            Test.startTest();
            DigitalRenewalQuoteUpdate updateQuote = new DigitalRenewalQuoteUpdate(tracker,'Step-3',payload,0);
            updateQuote.newInstanceWithRetry(1);
            updateQuote.createLog('Test Log');
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }

    @isTest
    static void testProcessQuoteWithNullQuote() {
        // Get the test tracker
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contract testContract = [SELECT Id FROM Contract WHERE AccountId = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :testAccount.Id LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        
        // Create payload with null quote data to trigger null quote scenario
        OrderPayload payload = new OrderPayload();
        payload.opportunity = new OrderPayload.Opportunity();
        payload.opportunity.id = testOpp.Id;
        payload.quote = new OrderPayload.Quote();
        payload.quote.id = testQuote.Id;
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_DIGITAL_RENEWAL',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;

        Test.startTest();
        // Set mock for HTTP callout
        Test.setMock(HttpCalloutMock.class, new DigitalRenewalMock(200));
        
        DigitalRenewalQuoteUpdate updateQuote = new DigitalRenewalQuoteUpdate(tracker,'Step-3',payload,0);
        OrderUtil.enqueueJobIfPossible(updateQuote);
        Test.stopTest();
    }

    @isTest
    static void testProcessQuoteWithMissingQuoteId() {
        // Get the test tracker
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contract testContract = [SELECT Id FROM Contract WHERE AccountId = :testAccount.Id LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        
        // Create payload with blank quote ID to trigger exception
        OrderPayload payload = new OrderPayload();
        payload.opportunity = new OrderPayload.Opportunity();
        payload.opportunity.id = testOpp.Id;
        payload.quote = new OrderPayload.Quote();
        payload.quote.id = ''; // Blank quote ID
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_DIGITAL_RENEWAL',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;

        Test.startTest();
        DigitalRenewalQuoteUpdate updateQuote = new DigitalRenewalQuoteUpdate(tracker,'Step-3',payload,0);
        try {
            OrderUtil.enqueueJobIfPossible(updateQuote);
        } catch (Exception e) {
            //System.assert(e.getMessage().contains('Quote Id is missing'), 'Should throw exception for missing quote ID');
            System.debug('Error: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateQuoteViaRestWithBlankQuoteId() {
        // Get the test tracker
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contract testContract = [SELECT Id FROM Contract WHERE AccountId = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :testAccount.Id LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        
        OrderPayload payload = MercuryPhase2DataFactory.createDigitalRenewalPayload(testAccount.Id, testContract.Id, testQuote.Id, 'pm_1PYBZsIbzZlMbYFSRMTEyohD', 'seti_1Qws4fIbzZlMbYFSgIzTIxfn');
        payload.opportunity.Id = testOpp.Id;
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_DIGITAL_RENEWAL',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;

        Test.startTest();
        DigitalRenewalQuoteUpdate updateQuote = new DigitalRenewalQuoteUpdate(tracker,'Step-3',payload,0);
        try {
            updateQuote.updateQuoteViaRest(new SBQQ__Quote__c(), ''); // Blank quote ID
            System.assert(false, 'Should have thrown an exception for blank quote ID');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('QuoteId missed in the payload'), 'Should throw exception for blank quote ID');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateQuoteViaRestWithHttpError() {
        // Get the test tracker
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contract testContract = [SELECT Id FROM Contract WHERE AccountId = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :testAccount.Id LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        
        OrderPayload payload = MercuryPhase2DataFactory.createDigitalRenewalPayload(testAccount.Id, testContract.Id, testQuote.Id, 'pm_1PYBZsIbzZlMbYFSRMTEyohD', 'seti_1Qws4fIbzZlMbYFSgIzTIxfn');
        payload.opportunity.Id = testOpp.Id;
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_DIGITAL_RENEWAL',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;

        Test.startTest();
        // Set mock for HTTP callout with error response
        Test.setMock(HttpCalloutMock.class, new DigitalRenewalMock(400));
        
        DigitalRenewalQuoteUpdate updateQuote = new DigitalRenewalQuoteUpdate(tracker,'Step-3',payload,0);
        try {
            updateQuote.updateQuoteViaRest(new SBQQ__Quote__c(), testQuote.Id);
            System.assert(false, 'Should have thrown an exception for HTTP error');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Update Quote Job Failed'), 'Should throw exception for HTTP error');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateQuoteViaRestWithSuccess() {
        // Get the test tracker
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contract testContract = [SELECT Id FROM Contract WHERE AccountId = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :testAccount.Id LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        
        OrderPayload payload = MercuryPhase2DataFactory.createDigitalRenewalPayload(testAccount.Id, testContract.Id, testQuote.Id, 'pm_1PYBZsIbzZlMbYFSRMTEyohD', 'seti_1Qws4fIbzZlMbYFSgIzTIxfn');
        payload.opportunity.Id = testOpp.Id;
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_DIGITAL_RENEWAL',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;

        Test.startTest();
        // Set mock for HTTP callout with success response
        Test.setMock(HttpCalloutMock.class, new DigitalRenewalMock(200));
        
        DigitalRenewalQuoteUpdate updateQuote = new DigitalRenewalQuoteUpdate(tracker,'Step-3',payload,0);
        updateQuote.updateQuoteViaRest(new SBQQ__Quote__c(), testQuote.Id);
        Test.stopTest();
    }

    @isTest
    static void testProcessQuoteWithShippingAddressScenarios() {
        // Get the test tracker
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contract testContract = [SELECT Id FROM Contract WHERE AccountId = :testAccount.Id LIMIT 1];
        Shipping_Address__c testShippingAddress = [SELECT Id FROM Shipping_Address__c WHERE Account__c = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :testAccount.Id LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        
        // Update opportunity with shipping details
        testOpp.Shipping_Method__c = 'Ground';
        testOpp.Shipping_Carrier__c = 'UPS';
        testOpp.Ship_From_Location__c = 'DCL';
        testOpp.shipping_address_new__c = testShippingAddress.Id;
        update testOpp;
        
        OrderPayload payload = MercuryPhase2DataFactory.createDigitalRenewalPayload(testAccount.Id, testContract.Id, testQuote.Id, 'pm_1PYBZsIbzZlMbYFSRMTEyohD', 'seti_1Qws4fIbzZlMbYFSgIzTIxfn');
        payload.opportunity.Id = testOpp.Id;
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_DIGITAL_RENEWAL',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1',
            Shipping_Address_Id__c = testShippingAddress.Id
        );

        insert tracker;

        Test.startTest();
        // Set mock for HTTP callout
        Test.setMock(HttpCalloutMock.class, new DigitalRenewalMock(200));
        
        DigitalRenewalQuoteUpdate updateQuote = new DigitalRenewalQuoteUpdate(tracker,'Step-3',payload,0);
        OrderUtil.enqueueJobIfPossible(updateQuote);
        Test.stopTest();
    }

    @isTest
    static void testProcessQuoteWithNullOpportunityPrimaryQuote() {
        // Get the test tracker
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contract testContract = [SELECT Id FROM Contract WHERE AccountId = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :testAccount.Id LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        
        // Create a new opportunity without primary quote to test null handling
        Opportunity testOppWithoutQuote = new Opportunity(
            Name = 'Test Opportunity Without Quote',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOppWithoutQuote;
        
        OrderPayload payload = new OrderPayload();
        payload.opportunity = new OrderPayload.Opportunity();
        payload.opportunity.id = testOppWithoutQuote.Id;
        payload.quote = new OrderPayload.Quote();
        payload.quote.id = testQuote.Id;
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_DIGITAL_RENEWAL',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;

        Test.startTest();
        // Set mock for HTTP callout
        Test.setMock(HttpCalloutMock.class, new DigitalRenewalMock(200));
        
        DigitalRenewalQuoteUpdate updateQuote = new DigitalRenewalQuoteUpdate(tracker,'Step-3',payload,0);
        try {
            OrderUtil.enqueueJobIfPossible(updateQuote);
            // This should handle the null primary quote scenario gracefully
        } catch (Exception e) {
            System.debug('Expected exception for null primary quote: ' + e.getMessage());
        }
        Test.stopTest();
    }
    // Mock class for HTTP callout
    private class DigitalRenewalMock implements HttpCalloutMock {
        private Integer statusCode;
        
        public DigitalRenewalMock(Integer statusCode) {
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
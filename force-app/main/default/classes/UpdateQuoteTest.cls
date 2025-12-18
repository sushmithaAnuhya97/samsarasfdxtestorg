@isTest
private class UpdateQuoteTest {

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
    static void testUpdateQuote() {
        // Get the test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :testAccount.Id LIMIT 1];
        Shipping_Address__c testShippingAddress = [SELECT Id FROM Shipping_Address__c WHERE Account__c = :testAccount.Id LIMIT 1];
        Id pricebookId = Test.getStandardPricebookId();

        OrderPayload payload = new OrderPayload();
        payload.order = new OrderPayload.Order();
        payload.order.id = '79243';
        payload.order.transaction_type = 'WEBSTORE_ADD_ON_PURCHASE';
        payload.order.account_id = testAccount.Id;
        payload.order.is_enterprise = false;
        
        payload.opportunity = new OrderPayload.Opportunity();
        payload.opportunity.id = testOpp.Id;
        payload.opportunity.stageName = 'Qualified';
        payload.opportunity.name = 'Updated Opportunity';
        payload.opportunity.closeDate = Date.today().addDays(60);
        payload.opportunity.smallFleetOpportunity = false;
        payload.opportunity.pricebook2Id = pricebookId;
        payload.opportunity.licenseTerm = 12;
        payload.opportunity.currencyIsoCode = 'USD';
        payload.opportunity.canCreate = true;
        payload.opportunity.excludeFromXactly = false;
        payload.opportunity.isWebstoreUpsellOpportunity = true;
        payload.opportunity.initialPaymentTerms = 'Net 30';
        payload.opportunity.paymentTerms = 'Net 60';
        payload.opportunity.configurationSegment = 'SMB';
        payload.opportunity.notes = 'Test notes';
        payload.opportunity.purchaseType = 'New';
        payload.opportunity.amountReceived = 1000;
        payload.opportunity.paymentToken = 'test_token';
        payload.opportunity.paymentMethod = 'Credit Card';
        payload.opportunity.stripeChargeId = 'test_charge';
        payload.opportunity.stripeIntentId = 'test_intent';
        payload.opportunity.shippingAndHandlingManual = 50;
        payload.opportunity.expressAgreementAcceptedDate = '2025-02-28';

        payload.quote = new OrderPayload.Quote();
        payload.quote.id = testQuote.Id;
        payload.quote.name = 'Test Quote';
        payload.quote.selectedPaymentType = 'Upfront Payments';
        payload.quote.checkoutDiscount = 100;
        payload.quote.shippingMethod = 'Express';
        payload.quote.paymentTerms = 'Net 60';
        payload.quote.poNumber = 'PO-12345';
        payload.quote.primary = true;
        payload.quote.status = 'Approved';
        payload.quote.expressAgreementAcceptedDate = Date.today();
        payload.quote.amountReceived = 1000;
        payload.quote.paymentToken = 'test_token';
        payload.quote.paymentMethod = 'Credit Card';
        payload.quote.stripeChargeId = 'test_charge';
        payload.quote.stripeIntentId = 'test_intent';
        payload.quote.shippingAndHandlingManual = 50;
        payload.quote.configurationSegment = 'SMB';
        payload.quote.account = testAccount.Id;
        payload.quote.opportunity = testOpp.Id;
        payload.quote.pricebook2Id = pricebookId;
        payload.quote.currencyIsoCode = 'USD';
        payload.quote.expressSelectedDiscount = 10.0;

        Request_Tracker__c tracker = new Request_Tracker__c(
            Account_Id__c = testAccount.Id,
            Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
            OrderId__c = '79243',
            Quote_Id__c = testQuote.Id,
            Opportunity_Id__c = testOpp.Id,
            Shipping_Address_Id__c = testShippingAddress.Id,
            Request__c = JSON.serialize(payload)
        );
        insert tracker;

        try {
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new UpdateQuoteMock(201));
            // Execute the job
            UpdateQuote job = new UpdateQuote(tracker, 'Step1', payload, 0);
            System.enqueueJob(job);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }

    @isTest
    static void testUpdateError() {
        // Get the test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :testAccount.Id LIMIT 1];
        Shipping_Address__c testShippingAddress = [SELECT Id FROM Shipping_Address__c WHERE Account__c = :testAccount.Id LIMIT 1];
        Id pricebookId = Test.getStandardPricebookId();

        OrderPayload payload = new OrderPayload();
        payload.order = new OrderPayload.Order();
        payload.order.id = '79243';
        payload.order.transaction_type = 'WEBSTORE_ADD_ON_PURCHASE';
        payload.order.account_id = testAccount.Id;
        payload.order.is_enterprise = false;
        
        payload.opportunity = new OrderPayload.Opportunity();
        payload.opportunity.id = testOpp.Id;
        payload.opportunity.stageName = 'Qualified';
        payload.opportunity.name = 'Updated Opportunity';
        payload.opportunity.closeDate = Date.today().addDays(60);
        payload.opportunity.smallFleetOpportunity = false;
        payload.opportunity.pricebook2Id = pricebookId;
        payload.opportunity.licenseTerm = 12;
        payload.opportunity.currencyIsoCode = 'USD';
        payload.opportunity.canCreate = true;
        payload.opportunity.excludeFromXactly = false;
        payload.opportunity.isWebstoreUpsellOpportunity = true;
        payload.opportunity.initialPaymentTerms = 'Net 30';
        payload.opportunity.paymentTerms = 'Net 60';
        payload.opportunity.configurationSegment = 'SMB';
        payload.opportunity.notes = 'Test notes';
        payload.opportunity.purchaseType = 'New';
        payload.opportunity.amountReceived = 1000;
        payload.opportunity.paymentToken = 'test_token';
        payload.opportunity.paymentMethod = 'Credit Card';
        payload.opportunity.stripeChargeId = 'test_charge';
        payload.opportunity.stripeIntentId = 'test_intent';
        payload.opportunity.shippingAndHandlingManual = 50;
        payload.opportunity.expressAgreementAcceptedDate = '2025-02-28';

        payload.quote = new OrderPayload.Quote();
        payload.quote.id = testQuote.Id;
        payload.quote.name = 'Test Quote';
        payload.quote.selectedPaymentType = 'Upfront Payments';
        payload.quote.checkoutDiscount = 100;
        payload.quote.shippingMethod = 'Express';
        payload.quote.paymentTerms = 'Net 60';
        payload.quote.poNumber = 'PO-12345';
        payload.quote.primary = true;
        payload.quote.status = 'Approved';
        payload.quote.expressAgreementAcceptedDate = Date.today();
        payload.quote.amountReceived = 1000;
        payload.quote.paymentToken = 'test_token';
        payload.quote.paymentMethod = 'Credit Card';
        payload.quote.stripeChargeId = 'test_charge';
        payload.quote.stripeIntentId = 'test_intent';
        payload.quote.shippingAndHandlingManual = 50;
        payload.quote.configurationSegment = 'SMB';
        payload.quote.account = testAccount.Id;
        payload.quote.opportunity = testOpp.Id;
        payload.quote.pricebook2Id = pricebookId;
        payload.quote.currencyIsoCode = 'USD';
        payload.quote.expressSelectedDiscount = 10.0;

        Request_Tracker__c tracker = new Request_Tracker__c(
            Account_Id__c = testAccount.Id,
            Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
            OrderId__c = '79243',
            Quote_Id__c = testQuote.Id,
            Opportunity_Id__c = testOpp.Id,
            Shipping_Address_Id__c = testShippingAddress.Id,
            Request__c = JSON.serialize(payload)
        );
        insert tracker;

        try {
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new UpdateQuoteMock(400));
            // Execute the job
            UpdateQuote job = new UpdateQuote(tracker, 'Step1', payload, 0);
            System.enqueueJob(job);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }

    @isTest
    static void testUpdateRetreyInstanceError() {
        // Get the test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :testAccount.Id LIMIT 1];
        Shipping_Address__c testShippingAddress = [SELECT Id FROM Shipping_Address__c WHERE Account__c = :testAccount.Id LIMIT 1];
        Id pricebookId = Test.getStandardPricebookId();

        OrderPayload payload = new OrderPayload();
        payload.order = new OrderPayload.Order();
        payload.order.id = '79243';
        payload.order.transaction_type = 'WEBSTORE_ADD_ON_PURCHASE';
        payload.order.account_id = testAccount.Id;
        payload.order.is_enterprise = false;
        
        payload.opportunity = new OrderPayload.Opportunity();
        payload.opportunity.id = testOpp.Id;
        payload.opportunity.stageName = 'Qualified';
        payload.opportunity.name = 'Updated Opportunity';
        payload.opportunity.closeDate = Date.today().addDays(60);
        payload.opportunity.smallFleetOpportunity = false;
        payload.opportunity.pricebook2Id = pricebookId;
        payload.opportunity.licenseTerm = 12;
        payload.opportunity.currencyIsoCode = 'USD';
        payload.opportunity.canCreate = true;
        payload.opportunity.excludeFromXactly = false;
        payload.opportunity.isWebstoreUpsellOpportunity = true;
        payload.opportunity.initialPaymentTerms = 'Net 30';
        payload.opportunity.paymentTerms = 'Net 60';
        payload.opportunity.configurationSegment = 'SMB';
        payload.opportunity.notes = 'Test notes';
        payload.opportunity.purchaseType = 'New';
        payload.opportunity.amountReceived = 1000;
        payload.opportunity.paymentToken = 'test_token';
        payload.opportunity.paymentMethod = 'Credit Card';
        payload.opportunity.stripeChargeId = 'test_charge';
        payload.opportunity.stripeIntentId = 'test_intent';
        payload.opportunity.shippingAndHandlingManual = 50;
        payload.opportunity.expressAgreementAcceptedDate = '2025-02-28';

        payload.quote = new OrderPayload.Quote();
        payload.quote.id = testQuote.Id;
        payload.quote.name = 'Test Quote';
        payload.quote.selectedPaymentType = 'Upfront Payments';
        payload.quote.checkoutDiscount = 100;
        payload.quote.shippingMethod = 'Express';
        payload.quote.paymentTerms = 'Net 60';
        payload.quote.poNumber = 'PO-12345';
        payload.quote.primary = true;
        payload.quote.status = 'Approved';
        payload.quote.expressAgreementAcceptedDate = Date.today();
        payload.quote.amountReceived = 1000;
        payload.quote.paymentToken = 'test_token';
        payload.quote.paymentMethod = 'Credit Card';
        payload.quote.stripeChargeId = 'test_charge';
        payload.quote.stripeIntentId = 'test_intent';
        payload.quote.shippingAndHandlingManual = 50;
        payload.quote.configurationSegment = 'SMB';
        payload.quote.account = testAccount.Id;
        payload.quote.opportunity = testOpp.Id;
        payload.quote.pricebook2Id = pricebookId;
        payload.quote.currencyIsoCode = 'USD';
        payload.quote.expressSelectedDiscount = 10.0;

        Request_Tracker__c tracker = new Request_Tracker__c(
            Account_Id__c = testAccount.Id,
            Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
            OrderId__c = '79243',
            Quote_Id__c = testQuote.Id,
            Opportunity_Id__c = testOpp.Id,
            Shipping_Address_Id__c = testShippingAddress.Id,
            Request__c = JSON.serialize(payload)
        );
        insert tracker;

        try {
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new UpdateQuoteMock(400));
            // Execute the job
            TestQueueableJob job = new TestQueueableJob(payload, 'Step1', tracker, 0);
            System.enqueueJob(job);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }

    // Mock class for HTTP callout
    private class UpdateQuoteMock implements HttpCalloutMock {
        private Integer statusCode;
        
        public UpdateQuoteMock(Integer statusCode) {
            this.statusCode = statusCode;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(statusCode);
            res.setBody('{"success": true}');
            return res;
        }
    }
    private class TestQueueableJob extends QueueableChainJob {
        private String stepStatus;
        private final Request_Tracker__c tracker;
        private final OrderPayload originalPayload;

        public TestQueueableJob(OrderPayload originalPayload, String stepStatus,Request_Tracker__c tracker, Integer retryCount) {
            super(retryCount, stepStatus,tracker);
            this.tracker = tracker;
            this.stepStatus=stepStatus;
            this.originalPayload = originalPayload;
        }

        public override void processJob() {
            throw new TestException('Quote Recalculation Job Failed');
        }

        protected override Queueable newInstanceWithRetry(Integer retryCount) {
            return new TestQueueableJob(originalPayload, stepStatus,tracker, retryCount);
        }
    }
    private class TestException extends Exception{}
}
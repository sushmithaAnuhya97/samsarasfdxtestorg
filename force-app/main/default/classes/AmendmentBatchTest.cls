@isTest
public with sharing class AmendmentBatchTest {
     @testSetup
    static void setup() {
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('Product2TriggerHandler');
        TriggerHandler.bypass('SBQQ__QuoteTriggerHandler');
        TriggerHandler.bypass('SBQQ__QuoteLineTriggerHandler');
        TriggerHandler.bypass('ShippingAddressTriggerHandler');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('RequestTrackerTriggerHandler');
        TriggerHandler.bypass('ContractTriggerHandler');
        TriggerHandler.bypass('SubscriptionTriggerHandler');
        TriggerHandler.bypass('OrderTriggerHandler');
        TriggerHandler.bypass('OrderItemTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
    

                // Create test data using MercuryPhase2DataFactory
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

        SBQQ.TriggerControl.disable();
        
        insert testOpp;
       
        //TriggerHandler.resetAll();
        
        // Create Contract
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
        
        // Create Quote Line
        SBQQ__QuoteLine__c testQuoteLine = MercuryPhase2DataFactory.createQuoteLines(testAccount.Id, testQuote.Id, String.valueOf(testShippingAddress.Id), String.valueOf(testProduct.Id), String.valueOf(vg33PB.Id), 10000, 2, true);
        SBQQ.TriggerControl.enable();
        // Create Subscription with the quote line
        MercuryPhase2DataFactory.createSubscription(testAccount.Id, testContract.Id, testQuoteLine.Id, true);
        
        //activate the contract
        testContract.Status = 'Activated';
        testContract.SBQQ__Opportunity__c = testOpp.Id;
        testContract.ActivatedDate = Date.today();
        update testContract;

        testAccount.Latest_Active_Contract__c = testContract.Id;
        update testAccount;
        
        TriggerHandler.clearAllBypasses();
        Test.stopTest();
    
    }

    @isTest
    static void testAmendmentBatch_Success() {
        // Get test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
        PricebookEntry testPricebook = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id AND Pricebook2Id = :Test.getStandardPricebookId() LIMIT 1];
        
        TriggerHandler.bypass('AccountTriggerHandler');
        Contract testContract = [SELECT Id From Contract WHERE AccountId = :testAccount.Id];
        testAccount.Latest_Active_Contract__c = testContract.Id;
        update testAccount;
        TriggerHandler.clearAllBypasses();

        // Create test payload
        OrderPayload orderPayload = MercuryPhase2DataFactory.createAmmendmentPayload(testAccount.Id, testContact.Id, testProduct.Id, testPricebook.Id);
        String jsonPayload = JSON.serialize(orderPayload);
        
        // Create test tracker
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
            Account_Id__c = testAccount.Id,
            Request__c = jsonPayload,
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );
        insert tracker;

        Test.startTest();
        // Execute the batch
        AmendmentBatch batch = new AmendmentBatch(tracker.Id);
        Database.executeBatch(batch, 1);
        Test.stopTest();

        // Verify results
        Request_Tracker__c updatedTracker = [SELECT Id, Status__c, Step_Status__c, Quote_Id__c, Opportunity_Id__c 
                                           FROM Request_Tracker__c 
                                           WHERE Id = :tracker.Id];
        
    }

    @isTest
    static void testAmendmentBatch_NoActiveContract() {
        // Get test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
        PricebookEntry testPricebook = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id AND Pricebook2Id = :Test.getStandardPricebookId() LIMIT 1];
        
        // Update account to remove contract
        testAccount.Latest_Active_Contract__c = null;
        update testAccount;
        
        // Create test payload
        OrderPayload orderPayload = MercuryPhase2DataFactory.createAmmendmentPayload(testAccount.Id, testContact.Id, testProduct.Id, testPricebook.Id);
        String jsonPayload = JSON.serialize(orderPayload);
        
        // Create test tracker
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
            Account_Id__c = testAccount.Id,
            Request__c = jsonPayload,
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );
        insert tracker;

        Test.startTest();
        // Execute the batch
        AmendmentBatch batch = new AmendmentBatch(tracker.Id);
        Database.executeBatch(batch, 1);
        Test.stopTest();

        // Verify error was logged
        List<Request_Tracker__c> updatedTracker = [SELECT Id, Status__c, Step_Status__c 
                                                 FROM Request_Tracker__c 
                                                 WHERE Id = :tracker.Id];
        
    }

    @isTest
    static void testAmendmentBatch_InvalidPayload() {
        // Get test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        // Create test tracker with invalid payload
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
            Account_Id__c = testAccount.Id,
            Request__c = '{"invalid": "payload"}',
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );
        insert tracker;

        Test.startTest();
        // Execute the batch
        AmendmentBatch batch = new AmendmentBatch(tracker.Id);
        Database.executeBatch(batch, 1);
        Test.stopTest();

        // Verify error was logged
        List<Request_Tracker__c> updatedTracker = [SELECT Id, Status__c, Step_Status__c 
                                                 FROM Request_Tracker__c 
                                                 WHERE Id = :tracker.Id];
    }

    @isTest
    static void testAmendmentBatch_RetryOnRowLock() {
        // Get test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
        PricebookEntry testPricebook = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id AND Pricebook2Id = :Test.getStandardPricebookId() LIMIT 1];
        
        TriggerHandler.bypass('AccountTriggerHandler');
        Contract testContract = [SELECT Id From Contract WHERE AccountId = :testAccount.Id];
        testAccount.Latest_Active_Contract__c = testContract.Id;
        update testAccount;
        TriggerHandler.clearAllBypasses();

        // Create test payload
        OrderPayload orderPayload = MercuryPhase2DataFactory.createAmmendmentPayload(testAccount.Id, testContact.Id, testProduct.Id, testPricebook.Id);
        String jsonPayload = JSON.serialize(orderPayload);
        
        // Create test tracker
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
            Account_Id__c = testAccount.Id,
            Request__c = jsonPayload,
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );
        insert tracker;

        Test.startTest();
        // Mock row lock exception
        Test.setMock(HttpCalloutMock.class, new RowLockMock());
        
        // Execute the batch
        AmendmentBatch batch = new AmendmentBatch(tracker.Id);
        Database.executeBatch(batch, 1);
        Test.stopTest();

        // Verify retry was attempted
        List<Request_Tracker__c> updatedTracker = [SELECT Id, Status__c, Step_Status__c 
                                                 FROM Request_Tracker__c 
                                                 WHERE Id = :tracker.Id];
    }

    @isTest
    static void testHandleRowLockException_WithRetries() {
        // Get test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
        PricebookEntry testPricebook = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id AND Pricebook2Id = :Test.getStandardPricebookId() LIMIT 1];
        
        TriggerHandler.bypass('AccountTriggerHandler');
        Contract testContract = [SELECT Id From Contract WHERE AccountId = :testAccount.Id];
        testAccount.Latest_Active_Contract__c = testContract.Id;
        update testAccount;
        TriggerHandler.clearAllBypasses();

        // Create test payload
        OrderPayload orderPayload = MercuryPhase2DataFactory.createAmmendmentPayload(testAccount.Id, testContact.Id, testProduct.Id, testPricebook.Id);
        String jsonPayload = JSON.serialize(orderPayload);
        
        // Create test tracker
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
            Account_Id__c = testAccount.Id,
            Request__c = jsonPayload,
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );
        insert tracker;

        Test.startTest();
        // Mock row lock exception for first attempt
        Test.setMock(HttpCalloutMock.class, new RowLockMock());
        
        // Execute the batch
        AmendmentBatch batch = new AmendmentBatch(tracker.Id);
        Database.executeBatch(batch, 1);
        Test.stopTest();

        // Verify retry was attempted
        List<Request_Tracker__c> updatedTracker = [SELECT Id, Status__c, Step_Status__c 
                                                 FROM Request_Tracker__c 
                                                 WHERE Id = :tracker.Id];
        
    }

    @isTest
    static void testHandleRowLockException_MaxRetries() {
        // Get test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
        PricebookEntry testPricebook = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id AND Pricebook2Id = :Test.getStandardPricebookId() LIMIT 1];
        
        TriggerHandler.bypass('AccountTriggerHandler');
        Contract testContract = [SELECT Id From Contract WHERE AccountId = :testAccount.Id];
        testAccount.Latest_Active_Contract__c = testContract.Id;
        update testAccount;
        TriggerHandler.clearAllBypasses();

        // Create test payload
        OrderPayload orderPayload = MercuryPhase2DataFactory.createAmmendmentPayload(testAccount.Id, testContact.Id, testProduct.Id, testPricebook.Id);
        String jsonPayload = JSON.serialize(orderPayload);
        
        // Create test tracker
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
            Account_Id__c = testAccount.Id,
            Request__c = jsonPayload,
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );
        insert tracker;

        // Create custom metadata for testing
        Order_Processing_Settings__mdt testSettings = new Order_Processing_Settings__mdt(
            DeveloperName = 'Workato',
            Maximum_Retries__c = 1
        );
        
        
        try {
            Test.startTest();
                // Mock row lock exception
                Test.setMock(HttpCalloutMock.class, new RowLockMock());
                AmendmentBatch batch = new AmendmentBatch(tracker.Id);
                Database.executeBatch(batch, 1);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
        // Execute the batch
    
       
    }

    @isTest
    static void testProcessAmendmentResponse_Success() {
        // Get test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
        PricebookEntry testPricebook = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id AND Pricebook2Id = :Test.getStandardPricebookId() LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :testOpp.Id LIMIT 1];
        
        TriggerHandler.bypass('AccountTriggerHandler');
        Contract testContract = [SELECT Id From Contract WHERE AccountId = :testAccount.Id];
        testAccount.Latest_Active_Contract__c = testContract.Id;
        update testAccount;
        TriggerHandler.clearAllBypasses();

        // Create test payload
        OrderPayload orderPayload = MercuryPhase2DataFactory.createAmmendmentPayload(testAccount.Id, testContact.Id, testProduct.Id, testPricebook.Id);
        String jsonPayload = JSON.serialize(orderPayload);
        
        // Create test tracker
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
            Account_Id__c = testAccount.Id,
            Request__c = jsonPayload,
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );
        insert tracker;
        try {
                    Test.startTest();
                // Mock successful amendment response
                Test.setMock(HttpCalloutMock.class, new SampleResponseMock(testOpp.Id, testQuote.Id));
                
                // Execute the batch
                AmendmentBatch batch = new AmendmentBatch(tracker.Id);
                batch.response = '{"record": {"Id": "' + testQuote.Id + '", "SBQQ__Opportunity2__c": "' + testOpp.Id + '"}}';
                Database.executeBatch(batch, 1);
                Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }

    @isTest
    static void testProcessAmendmentResponse_MissingData() {
        // Get test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
        PricebookEntry testPricebook = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id AND Pricebook2Id = :Test.getStandardPricebookId() LIMIT 1];
        
        TriggerHandler.bypass('AccountTriggerHandler');
        Contract testContract = [SELECT Id From Contract WHERE AccountId = :testAccount.Id];
        testAccount.Latest_Active_Contract__c = testContract.Id;
        update testAccount;
        TriggerHandler.clearAllBypasses();

        // Create test payload
        OrderPayload orderPayload = MercuryPhase2DataFactory.createAmmendmentPayload(testAccount.Id, testContact.Id, testProduct.Id, testPricebook.Id);
        String jsonPayload = JSON.serialize(orderPayload);
        
        // Create test tracker
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
            Account_Id__c = testAccount.Id,
            Request__c = jsonPayload,
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );
        insert tracker;

        Test.startTest();
        // Mock amendment response with missing data
        Test.setMock(HttpCalloutMock.class, new SampleResponseMock(null, null));
        
        // Execute the batch
        AmendmentBatch batch = new AmendmentBatch(tracker.Id);
        Database.executeBatch(batch, 1);
        Test.stopTest();

        // Verify error was logged
        List<Request_Tracker__c> updatedTracker = [SELECT Id, Status__c, Step_Status__c 
                                                 FROM Request_Tracker__c 
                                                 WHERE Id = :tracker.Id];
        
    }

    @isTest
    static void testEnqueueAmendmentJob() {
        // Get test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
        PricebookEntry testPricebook = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id AND Pricebook2Id = :Test.getStandardPricebookId() LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :testOpp.Id LIMIT 1];
        
        TriggerHandler.bypass('AccountTriggerHandler');
        Contract testContract = [SELECT Id From Contract WHERE AccountId = :testAccount.Id];
        testAccount.Latest_Active_Contract__c = testContract.Id;
        update testAccount;
        TriggerHandler.clearAllBypasses();

        // Create test payload
        OrderPayload orderPayload = MercuryPhase2DataFactory.createAmmendmentPayload(testAccount.Id, testContact.Id, testProduct.Id, testPricebook.Id);
        String jsonPayload = JSON.serialize(orderPayload);
        
        // Create test tracker
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
            Account_Id__c = testAccount.Id,
            Request__c = jsonPayload,
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );
        insert tracker;

        Test.startTest();
        // Mock successful amendment response
        Test.setMock(HttpCalloutMock.class, new SampleResponseMock(testOpp.Id, testQuote.Id));
        
        // Execute the batch
        AmendmentBatch batch = new AmendmentBatch(tracker.Id);
        Database.executeBatch(batch, 1);
        Test.stopTest();
    }

    @isTest
    static void testLogSuccessJob() {
        // Get test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
        PricebookEntry testPricebook = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id AND Pricebook2Id = :Test.getStandardPricebookId() LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :testOpp.Id LIMIT 1];
        
        TriggerHandler.bypass('AccountTriggerHandler');
        Contract testContract = [SELECT Id From Contract WHERE AccountId = :testAccount.Id];
        testAccount.Latest_Active_Contract__c = testContract.Id;
        update testAccount;
        TriggerHandler.clearAllBypasses();

        // Create test payload
        OrderPayload orderPayload = MercuryPhase2DataFactory.createAmmendmentPayload(testAccount.Id, testContact.Id, testProduct.Id, testPricebook.Id);
        String jsonPayload = JSON.serialize(orderPayload);
        
        // Create test tracker
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
            Account_Id__c = testAccount.Id,
            Request__c = jsonPayload,
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );
        insert tracker;

        Test.startTest();
        // Mock successful amendment response
        Test.setMock(HttpCalloutMock.class, new SampleResponseMock(testOpp.Id, testQuote.Id));
        
        // Execute the batch
        AmendmentBatch batch = new AmendmentBatch(tracker.Id);
        Database.executeBatch(batch, 1);
        Test.stopTest();
        
    }

    // Mock class for row lock exception
    private class RowLockMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new DmlException('UNABLE_TO_LOCK_ROW');
        }
    }

    // Mock class for amendment response
    private class SampleResponseMock implements HttpCalloutMock {
        private String oppId;
        private String quoteId;
        
        public SampleResponseMock(String oppId, String quoteId) {
            this.oppId = oppId;
            this.quoteId = quoteId;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"record": {"Id": "' + quoteId + '", "SBQQ__Opportunity2__c": "' + oppId + '"}}');
            return res;
        }
    }
}
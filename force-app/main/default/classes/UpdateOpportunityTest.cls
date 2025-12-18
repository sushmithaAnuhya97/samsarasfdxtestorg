@isTest
private class UpdateOpportunityTest {
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
    static void testUpdateOpportunity() {
        // Get the test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        Id pricebookId = Test.getStandardPricebookId();

        OrderPayload payload = MercuryPhase2DataFactory.createAmmendmentPayload(testAccount.Id, testContact.Id, testProduct.Id, pricebookId);
        payload.opportunity.Id = testOpp.Id;
        payload.opportunity.stageName = 'Qualified';
        payload.opportunity.name = 'Updated Opportunity';
        payload.opportunity.closeDate = Date.today().addDays(60);

        Request_Tracker__c tracker = new Request_Tracker__c(
            Account_Id__c = testAccount.Id,
            Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
            OrderId__c = '79243',
            Request__c = JSON.serialize(payload)
        );
        insert tracker;
    
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new UpdateOpportunityMock(201));
        // Execute the job
        UpdateOpportunity job = new UpdateOpportunity(tracker, 'Step1', payload, 0);
        System.enqueueJob(job);
        Test.stopTest();
    }

    @isTest
    static void testUpdateOpportunityError() {
        // Get the test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        Id pricebookId = Test.getStandardPricebookId();

        OrderPayload payload = MercuryPhase2DataFactory.createAmmendmentPayload(testAccount.Id, testContact.Id, testProduct.Id, pricebookId);
        payload.opportunity.Id = testOpp.Id;
        payload.opportunity.stageName = 'Qualified';
        payload.opportunity.name = 'Updated Opportunity';
        payload.opportunity.closeDate = Date.today().addDays(60);

        Request_Tracker__c tracker = new Request_Tracker__c(
            Account_Id__c = testAccount.Id,
            Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
            OrderId__c = '79243',
            Request__c = JSON.serialize(payload)
        );
        insert tracker;
    
        try {
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new UpdateOpportunityMock(400));
            // Execute the job
            UpdateOpportunity job = new UpdateOpportunity(tracker, 'Step1', payload, 0);
            System.enqueueJob(job);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }

    @isTest
    static void testUpdateOpportunityRetry() {
        // Get the test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        Id pricebookId = Test.getStandardPricebookId();

        OrderPayload payload = MercuryPhase2DataFactory.createAmmendmentPayload(testAccount.Id, testContact.Id, testProduct.Id, pricebookId);
        payload.opportunity.Id = testOpp.Id;
        payload.opportunity.stageName = 'Qualified';
        payload.opportunity.name = 'Updated Opportunity';
        payload.opportunity.closeDate = Date.today().addDays(60);

        Request_Tracker__c tracker = new Request_Tracker__c(
            Account_Id__c = testAccount.Id,
            Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
            OrderId__c = '79243',
            Request__c = JSON.serialize(payload)
        );
        insert tracker;
    
      
        // Bypass metadata requirement using reflection or injecting it via context (if required in constructor)
        // Execute the job
        try {
              Test.startTest();
            Test.setMock(HttpCalloutMock.class, new UpdateOpportunityMock(400));
        
            UpdateOpportunity job = new UpdateOpportunity(tracker, 'Step1', payload, 4);
            System.enqueueJob(job);
             Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
        
       
    }
    
    
    
    
    
    
    private class UpdateOpportunityMock implements HttpCalloutMock {
        private Integer statusCode;
        
        public UpdateOpportunityMock(Integer statusCode) {
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
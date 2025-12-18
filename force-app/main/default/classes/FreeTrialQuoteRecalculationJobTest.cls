@isTest
public with sharing class FreeTrialQuoteRecalculationJobTest {

    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = MercuryPhase2DataFactory.createAccount('Test Account', true);
        
        // Create test contact
        Contact testContact = MercuryPhase2DataFactory.createContact(testAccount.Id, true);
        
        // Create test shipping address
        Shipping_Address__c testShippingAddress = MercuryPhase2DataFactory.createShippingAddress(testAccount.Id, testContact.Id, true);

        // Create Revenue Opportunity for free trial
        Opportunity revenueOpp = new Opportunity(
            Name = 'Revenue Opportunity - Test Account',
            AccountId = testAccount.Id,
            StageName = 'Qualified',
            CloseDate = Date.today().addDays(30),
            Type = 'Revenue Opportunity'
        );
        
        Test.startTest();
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('Product2TriggerHandler');
        TriggerHandler.bypass('SBQQ__QuoteTriggerHandler');
        TriggerHandler.bypass('SBQQ__QuoteLineTriggerHandler');
        SBQQ.TriggerControl.disable();
        
        insert revenueOpp;
        
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
        
        // Create Free Trial Opportunity
        Opportunity freeTrialOpp = new Opportunity(
            Name = 'Webstore Free Trial Opportunity - Test Account',
            AccountId = testAccount.Id,
            StageName = 'Qualified',
            CloseDate = Date.today().addDays(60),
            Type = 'Free Trial',
            Pricebook2Id = pricebookId
        );
        insert freeTrialOpp;
        
        // Create Quote for free trial
        SBQQ__Quote__c testQuote = MercuryPhase2DataFactory.createQuote(testAccount.Id, freeTrialOpp.Id, true);
        
        // Create Subscription with the quote line
        SBQQ__QuoteLine__c testQuoteLine = MercuryPhase2DataFactory.createQuoteLines(testAccount.Id, testQuote.Id, String.valueOf(testShippingAddress.Id), String.valueOf(testProduct.Id), String.valueOf(vg33PB.Id), 10000, 2, true);
        MercuryPhase2DataFactory.createSubscription(testAccount.Id, testContract.Id, testQuoteLine.Id, true);

        //activate the contract
        testContract.Status = 'Activated';
        testContract.SBQQ__Opportunity__c = revenueOpp.Id;
        testContract.ActivatedDate = Date.today();
        update testContract;

        testAccount.Latest_Active_Contract__c = testContract.Id;
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        update testAccount;
    }

    @isTest
    static void testFreeTrialQuoteRecalculationJobSuccess() {
        // Get the test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
        Opportunity revenueOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id AND Type = 'Revenue Opportunity' LIMIT 1];
        Opportunity freeTrialOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id AND Type = 'Free Trial' LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :testAccount.Id LIMIT 1];
        Shipping_Address__c testShippingAddress = [SELECT Id FROM Shipping_Address__c WHERE Account__c = :testAccount.Id LIMIT 1];
        Id pricebookId = Test.getStandardPricebookId();

        // Create free trial payload
        OrderPayload payload = MercuryPhase2DataFactory.createFreeTrialPayload(testAccount.Id, revenueOpp.Id, testProduct.Id, pricebookId);
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            Account_Id__c = testAccount.Id,
            Transaction_Type__c = 'WEBSTORE_FREE_TRIAL',
            OrderId__c = '1234',
            Quote_Id__c = testQuote.Id,
            Opportunity_Id__c = freeTrialOpp.Id,
            Shipping_Address_Id__c = testShippingAddress.Id,
            Request__c = JSON.serialize(payload)
        );
        insert tracker;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new FreeTrialQuoteRecalculationJobMock(200));
        try {
            // Execute the job
            FreeTrialQuoteRecalculationJob job = new FreeTrialQuoteRecalculationJob(tracker, 'Step8', payload, 0);
            System.enqueueJob(job);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // Mock class for HTTP callout
    private class FreeTrialQuoteRecalculationJobMock implements HttpCalloutMock {
        private Integer statusCode;
        
        public FreeTrialQuoteRecalculationJobMock(Integer statusCode) {
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
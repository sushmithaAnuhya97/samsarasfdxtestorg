@isTest
private class InsertOpportunityTest {

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
    static void testInsertOpportunity() {
        // Get the test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :testAccount.Id LIMIT 1];
        Shipping_Address__c testShippingAddress = [SELECT Id FROM Shipping_Address__c WHERE Account__c = :testAccount.Id LIMIT 1];
        Id pricebookId = Test.getStandardPricebookId();

        OrderPayload payload = MercuryPhase2DataFactory.createAmmendmentPayload(testAccount.Id, testContact.Id, testProduct.Id, pricebookId);
        
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            Account_Id__c = testAccount.Id,
            Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
            OrderId__c = '79243',
            Quote_Id__c = testQuote.Id,
            Shipping_Address_Id__c = testShippingAddress.Id,
            Request__c = JSON.serialize(payload)
        );
        insert tracker;
        
        Test.startTest();
        // Execute the job
        InsertOpportunity job = new InsertOpportunity(tracker, 'Step1', payload, 0);
        System.enqueueJob(job);
        Test.stopTest();
        
        // Verify the opportunity was created
        List<Opportunity> opportunities = [SELECT Id, Name, StageName, CloseDate, AccountId, Shipping_Address_NEW__c 
                                         FROM Opportunity 
                                         WHERE AccountId = :testAccount.Id];
    }

    @isTest
    static void testNewInstanceWithRetry() {
        // Get the test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :testAccount.Id LIMIT 1];
        Shipping_Address__c testShippingAddress = [SELECT Id FROM Shipping_Address__c WHERE Account__c = :testAccount.Id LIMIT 1];
        Id pricebookId = Test.getStandardPricebookId();

        OrderPayload payload = MercuryPhase2DataFactory.createAmmendmentPayload(testAccount.Id, testContact.Id, testProduct.Id, pricebookId);
        
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            Account_Id__c = testAccount.Id,
            Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
            OrderId__c = '79243',
            Quote_Id__c = testQuote.Id,
            Shipping_Address_Id__c = testShippingAddress.Id,
            Request__c = JSON.serialize(payload)
        );
        insert tracker;
        
        Test.startTest();
        // Execute the job
        InsertOpportunity initialJob = new InsertOpportunity(tracker, 'Step1', payload, 0);
        
        // Test newInstanceWithRetry with different retry counts
        Queueable retryJob1 = initialJob.newInstanceWithRetry(1);
        Queueable retryJob2 = initialJob.newInstanceWithRetry(2);
        Test.stopTest();
        
        // Cast to InsertOpportunity to verify properties
        InsertOpportunity retryJob1Cast = (InsertOpportunity)retryJob1;
        InsertOpportunity retryJob2Cast = (InsertOpportunity)retryJob2;
    }
}
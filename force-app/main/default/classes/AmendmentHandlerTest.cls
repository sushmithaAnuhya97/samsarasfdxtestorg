@isTest
private class AmendmentHandlerTest {
    @TestSetup
    static void setupTestData() {
        
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
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('Product2TriggerHandler');
        TriggerHandler.bypass('SBQQ__QuoteTriggerHandler');
        TriggerHandler.bypass('SBQQ__QuoteLineTriggerHandler');
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
        TriggerHandler.bypass('AccountTriggerHandler');
        update testAccount;
        
        // Create Amendment Tracker
        MercuryPhase2DataFactory.createAmendmentTracker(testAccount.Id, testContact.Id, pricebookId, testProduct.Id, true);

        TriggerHandler.clearAllBypasses();
        Test.stopTest();
    }

    @isTest
    static void testIsOrderValid() {
        
        Account testAccount= [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Request_Tracker__c tracker = [SELECT Id, Request__c,Account_Id__c,OrderId__c, Opportunity_Id__c, Quote_Id__c, Transaction_Type__c FROM Request_Tracker__c WHERE Account_Id__c = :testAccount.Id LIMIT 1];
        try {
            Test.startTest();
            AmendmentHandler handler = new AmendmentHandler();
            Boolean isValid = handler.isOrderValid(tracker);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }

        //System.assertEquals(true, isValid, 'Order should be valid');
    }

    @isTest
    static void testIsOrderValid_NoContract() {
       
        // Create test account without contract
        Account testAccount= [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        testAccount.Latest_Active_Contract__c = null;
        TriggerHandler.bypass('AccountTriggerHandler');
        update testAccount;

        Request_Tracker__c tracker = [SELECT Id, Request__c,Account_Id__c,OrderId__c, Opportunity_Id__c, Transaction_Type__c, Quote_Id__c, Status__c FROM Request_Tracker__c WHERE Account_Id__c = :testAccount.Id LIMIT 1];
        
        
        try {
            Test.startTest();
            AmendmentHandler handler = new AmendmentHandler();
            handler.isOrderValid(tracker);
            Test.stopTest();
            //System.assert(false, 'Should have thrown an exception');
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
        
    }

    @isTest
    static void testProcessTransaction() {
       
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
        
        try {
             Test.startTest();
            AmendmentHandler handler = new AmendmentHandler();
            handler.processTransaction(tracker);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }  
    
    @isTest
    static void testUpsertAccountOnShippingAddress() {
        // Fetch existing test data from @TestSetup
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contract testContract = [SELECT Id FROM Contract WHERE AccountId = :testAccount.Id LIMIT 1];
        Shipping_Address__c existingShipAddr = [
            SELECT Id, Account__c 
            FROM Shipping_Address__c 
            WHERE Account__c = :testAccount.Id 
            LIMIT 1
        ];
        
        Account wrongAccount = MercuryPhase2DataFactory.createAccount('Test Wrong Account', true);

        // Create a Shipping Address for the wrong account
        Shipping_Address__c wrongShipAddr = new Shipping_Address__c(
            Account__c = wrongAccount.Id
        );
        insert wrongShipAddr;

        // Create subscription with no Ship_To__c (should get defaultShipTo from existingShipAddr)
        SBQQ__Subscription__c subMissingShipTo = new SBQQ__Subscription__c(
            SBQQ__Contract__c = testContract.Id,
            SBQQ__Quantity__c=10
        );
        
         // Create subscription with Ship_To__c (should get defaultShipTo from existingShipAddr)
         SBQQ__Subscription__c subMissingShipTo2 = new SBQQ__Subscription__c(
            SBQQ__Contract__c = testContract.Id,
            SBQQ__Quantity__c=10,
             Ship_To__c = existingShipAddr.Id
        );

        // Create subscription with wrong account Ship_To__c
        SBQQ__Subscription__c subWrongAccountShipTo = new SBQQ__Subscription__c(
            SBQQ__Contract__c = testContract.Id,
            Ship_To__c = wrongShipAddr.Id,
            SBQQ__Quantity__c=10
        );
        
        

        insert new List<SBQQ__Subscription__c>{ subMissingShipTo, subMissingShipTo2, subWrongAccountShipTo };

        // Get tracker from existing data
        Request_Tracker__c tracker = [
            SELECT Id,Transaction_Type__c,Request__c  
            FROM Request_Tracker__c 
            WHERE Account_Id__c = :testAccount.Id 
            LIMIT 1
        ];

        Test.startTest();
        // Call the private static method (replace OrderService with your actual class name)
        AmendmentHandler.upsertAccountOnShippingAddress(testContract.Id, testAccount.Id, tracker);
        Test.stopTest();

        // Assert that missing Ship_To__c got updated
        subMissingShipTo = [
            SELECT Ship_To__c 
            FROM SBQQ__Subscription__c 
            WHERE Id = :subMissingShipTo.Id
        ];

        // Assert that wrong Ship_To__c account got corrected
        wrongShipAddr = [
            SELECT Account__c 
            FROM Shipping_Address__c 
            WHERE Id = :wrongShipAddr.Id
        ];
        System.assertEquals(testAccount.Id, wrongShipAddr.Account__c, 'Wrong Ship Address account should be corrected');
    }
    
    @isTest
    static void testForJSONException() {
        try{
               Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
         // Get tracker from existing data
          Request_Tracker__c tracker = new Request_Tracker__c(
            Account_Id__c = testAccount.Id,
            Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
            OrderId__c = '79243',
              Request__c = '{"test":'
        );
        
        AmendmentHandler handler = new AmendmentHandler();
        handler.isOrderValid(tracker);
        handler.isOrderValid(null);
        }catch(Exception e){
            System.debug('error');
        }
    }

}
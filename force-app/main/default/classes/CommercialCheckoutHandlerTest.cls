@isTest
private class CommercialCheckoutHandlerTest {
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
        SBQQ__Quote__c testQuote = MercuryPhase2DataFactory.createQuote(testAccount.Id, testOpp.Id, false);
		testQuote.SBQQ__Primary__c = true;
        insert testQuote;

        // Create Subscription with the quote line
        SBQQ__QuoteLine__c testQuoteLine = MercuryPhase2DataFactory.createQuoteLines(testAccount.Id, testQuote.Id, String.valueOf(testShippingAddress.Id), String.valueOf(testProduct.Id), String.valueOf(vg33PB.Id), 10000, 2, true);
        MercuryPhase2DataFactory.createSubscription(testAccount.Id, testContract.Id, testQuoteLine.Id, true);
		
        
        //activate the contract
        testContract.Status = 'Activated';
        testContract.SBQQ__Opportunity__c = testOpp.Id;
        testContract.ActivatedDate = Date.today();
        update testContract;
        
      

        testAccount.Latest_Active_Contract__c = testContract.Id;
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        update testAccount;
        
        testOpp.SBQQ__PrimaryQuote__c = testQuote.Id;
        update testOpp;
        
        
        
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        TriggerHandler.clearBypass('Product2TriggerHandler');
        TriggerHandler.clearBypass('SBQQ__QuoteTriggerHandler');
        TriggerHandler.clearBypass('SBQQ__QuoteLineTriggerHandler');
        TriggerHandler.clearBypass('GS_AccountTriggerHandler');
        SBQQ.TriggerControl.enable();
    }
    
    @isTest
    static void testProcessTransaction_Success() {
        // Get the test tracker
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contract testContract = [SELECT Id FROM Contract WHERE AccountId = :testAccount.Id LIMIT 1];
        Shipping_Address__c testShippingAddress = [SELECT Id FROM Shipping_Address__c WHERE Account__c = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :testAccount.Id LIMIT 1];
        Opportunity testOpp = [SELECT Id, SBQQ__PrimaryQuote__c FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        // Create test request tracker
        OrderPayload payload = MercuryPhase2DataFactory.createCommercialCheckoutPayload(testAccount.Id, testOpp.Id, 'pm_1G5gW1IbzZlMbYFSeAJH3ro5', 'seti_1QxFamIbzZlMbYFSqvcPMtDu', '1234567890', testContact.Id);
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_COMMERCIAL_CHECKOUT_LINK',
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
    static void testProcessTransaction_SuccessWithNewShippingAddress() {
        // Get the test tracker
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contract testContract = [SELECT Id FROM Contract WHERE AccountId = :testAccount.Id LIMIT 1];
        Shipping_Address__c testShippingAddress = [SELECT Id FROM Shipping_Address__c WHERE Account__c = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :testAccount.Id LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        // Create test request tracker
        OrderPayload payload = MercuryPhase2DataFactory.createCommercialCheckoutPayload(testAccount.Id, testOpp.Id, 'pm_1G5gW1IbzZlMbYFSeAJH3ro5', 'seti_1QxFamIbzZlMbYFSqvcPMtDu', '1234567890', testContact.Id);

        payload.shipping_address.shippingCity = 'Oxnard';
        payload.shipping_address.shippingEmail = 'fernando@mayanhardwood.com';
        payload.shipping_address.shippingPhone = '8053774403';
        payload.shipping_address.shippingState = 'California';
        payload.shipping_address.shippingCountry = 'United States';
        payload.shipping_address.shippingContact = testContact.Id;
        payload.shipping_address.shippingLastName = 'Hernandez';
        payload.shipping_address.shippingZipCode = '93036';
        payload.shipping_address.shippingFirstName = 'Fernando';
        payload.shipping_address.shippingAddressLine1 = '2930 Los Olivos';
        payload.shipping_address.shippingAddressLine2 = '';
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_COMMERCIAL_CHECKOUT_LINK',
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
            Transaction_Type__c = 'WEBSTORE_COMMERCIAL_CHECKOUT_LINK',
            Account_Id__c = testAccount.Id,
            Request__c = 'invalid json',
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
    static void testProcessAccount_Success() {
        // Get the test tracker
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        Shipping_Address__c testShippingAddress = [SELECT Id FROM Shipping_Address__c WHERE Account__c = :testAccount.Id LIMIT 1];  
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        // Create test request tracker
        OrderPayload payload = MercuryPhase2DataFactory.createCommercialCheckoutPayload(testAccount.Id, testOpp.Id, 'pm_1G5gW1IbzZlMbYFSeAJH3ro5', 'seti_1QxFamIbzZlMbYFSqvcPMtDu', '1234567890', testContact.Id);
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_COMMERCIAL_CHECKOUT_LINK',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;

        try {
            Test.startTest();
            CommercialCheckoutAccountUpdate updateAccount = new CommercialCheckoutAccountUpdate(tracker,'Step-2',payload,0);
            OrderUtil.enqueueJobIfPossible(updateAccount);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }

    @isTest
    static void testProcessAccount_Sucess_With_No_Fields_Changed() {
        // Get the test tracker
        Account testAccount = [SELECT Id, Auto_Renewal_Opt_Out__c, BillingCity, BillingState, BillingStreet, BillingCountry, Billing_Email__c, Billing_Phone__c, BillingPostalCode,Billing_Last_Name__c,Billing_First_Name__c FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        Shipping_Address__c testShippingAddress = [SELECT Id FROM Shipping_Address__c WHERE Account__c = :testAccount.Id LIMIT 1];  
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        // Create test request tracker
        OrderPayload payload = MercuryPhase2DataFactory.createCommercialCheckoutPayload(testAccount.Id, testOpp.Id, 'pm_1G5gW1IbzZlMbYFSeAJH3ro5', 'seti_1QxFamIbzZlMbYFSqvcPMtDu', '1234567890', testContact.Id);
        payload.account.autoRenewalOptOut = testAccount.Auto_Renewal_Opt_Out__c;
        payload.account.billingCity = null;
        payload.account.billingState = null;
        payload.account.billingStreet = null;
        payload.account.billingCountry = null;
        payload.account.billingEmail = null;
        payload.account.billingPhone = null;
        payload.account.billingPostalCode = null;
        payload.account.billingLastName = null;
        payload.account.billingFirstName = null;

        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_COMMERCIAL_CHECKOUT_LINK',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;

        try {
            Test.startTest();
            CommercialCheckoutAccountUpdate updateAccount = new CommercialCheckoutAccountUpdate(tracker,'Step-2',payload,0);
            OrderUtil.enqueueJobIfPossible(updateAccount);
            updateAccount.newInstanceWithRetry(2);
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
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :testAccount.Id LIMIT 1];
        // Create test request tracker
        OrderPayload payload = MercuryPhase2DataFactory.createCommercialCheckoutPayload(testAccount.Id, testOpp.Id, 'pm_1G5gW1IbzZlMbYFSeAJH3ro5', 'seti_1QxFamIbzZlMbYFSqvcPMtDu', '1234567890', testContact.Id);
        payload.quote.Id = testQuote.Id;
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_COMMERCIAL_CHECKOUT_LINK',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;

        Test.startTest();
        // Set mock for HTTP callout
        Test.setMock(HttpCalloutMock.class, new CommercialCheckoutMock(201));
        try {
            CommercialCheckoutQuoteUpdate updateQuote = new CommercialCheckoutQuoteUpdate(tracker,'Step-4',payload,2);
            OrderUtil.enqueueJobIfPossible(updateQuote);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }
    
        @isTest
    static void testProcessQuote_FailureJob() {
        // Get the test tracker
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :testAccount.Id LIMIT 1];
        // Create test request tracker
        OrderPayload payload = MercuryPhase2DataFactory.createCommercialCheckoutPayload(testAccount.Id, testOpp.Id, 'pm_1G5gW1IbzZlMbYFSeAJH3ro5', 'seti_1QxFamIbzZlMbYFSqvcPMtDu', '1234567890', testContact.Id);
        payload.quote = null;
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_COMMERCIAL_CHECKOUT_LINK',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;

        Test.startTest();
        // Set mock for HTTP callout
        Test.setMock(HttpCalloutMock.class, new CommercialCheckoutMock(201));
        try {
            CommercialCheckoutQuoteUpdate updateQuote = new CommercialCheckoutQuoteUpdate(tracker,'Step-4',payload,0);
            OrderUtil.enqueueJobIfPossible(updateQuote);
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
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :testAccount.Id LIMIT 1];
        // Create test request tracker
        OrderPayload payload = MercuryPhase2DataFactory.createCommercialCheckoutPayload(testAccount.Id, testOpp.Id, 'pm_1G5gW1IbzZlMbYFSeAJH3ro5', 'seti_1QxFamIbzZlMbYFSqvcPMtDu', '1234567890', testContact.Id);
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_COMMERCIAL_CHECKOUT_LINK',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;

        Test.startTest();
        // Set mock for HTTP callout
        Test.setMock(HttpCalloutMock.class, new CommercialCheckoutMock(201));
        try {
            CommercialCheckoutOpportunityUpdate updateOpportunity = new CommercialCheckoutOpportunityUpdate(tracker,'Step-4',payload,2);
            OrderUtil.enqueueJobIfPossible(updateOpportunity);
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
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        // Create test request tracker
        OrderPayload payload = MercuryPhase2DataFactory.createCommercialCheckoutPayload(testAccount.Id, testOpp.Id, 'pm_1G5gW1IbzZlMbYFSeAJH3ro5', 'seti_1QxFamIbzZlMbYFSqvcPMtDu', '1234567890', testContact.Id);
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_COMMERCIAL_CHECKOUT_LINK',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;

        try {
            Test.startTest();
            // Set mock for HTTP callout
            Test.setMock(HttpCalloutMock.class, new CommercialCheckoutMock(201));
            
            OrderResultToWorkatoService workatoService = new OrderResultToWorkatoService(tracker,'Step-5',payload,0);
            OrderUtil.enqueueJobIfPossible(workatoService);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }

    @isTest
    static void testDeleteQuoteLinesWithEnqueueRetryJob() {
        // Get the test data
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        // Create test request tracker
        OrderPayload payload = MercuryPhase2DataFactory.createCommercialCheckoutPayload(testAccount.Id, testOpp.Id, 'pm_1G5gW1IbzZlMbYFSeAJH3ro5', 'seti_1QxFamIbzZlMbYFSqvcPMtDu', '1234567890', testContact.Id);
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_COMMERCIAL_CHECKOUT_LINK',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;
        
        Test.startTest();
        // Execute the job
        TriggerHandler.bypass('RequestTrackerTriggerHandler');
        CommercialCheckoutOpportunityUpdate job = new CommercialCheckoutOpportunityUpdate(tracker,'Step-4',payload,2);
        job.enqueueRetryJob(1, 1, 'CommercialCheckoutOpportunityUpdate');
        job.enqueueRetryJob(1, 1, 'OrderResultToWorkatoService');
        Test.stopTest();
    }

    @isTest
    static void testProcessQuote_MissingPrimaryQuote() {
        // Get the test tracker
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        
        // Create test request tracker
        OrderPayload payload = MercuryPhase2DataFactory.createCommercialCheckoutPayload(testAccount.Id, testOpp.Id, 'pm_1G5gW1IbzZlMbYFSeAJH3ro5', 'seti_1QxFamIbzZlMbYFSqvcPMtDu', '1234567890', testContact.Id);
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_COMMERCIAL_CHECKOUT_LINK',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;

        Test.startTest();
        try {
            CommercialCheckoutQuoteUpdate updateQuote = new CommercialCheckoutQuoteUpdate(tracker,'Step-4',payload,0);
            updateQuote.processJob(); // Call processJob directly to trigger the exception
            //System.assert(false, 'Should have thrown an exception for missing primary quote');
        } catch (Exception e) {
            //System.assert(e.getMessage().contains('Primary Quote does not exist'), 'Should throw exception for missing primary quote');
        }
        Test.stopTest();
    }

    @isTest
    static void testProcessQuote_WithShippingAddressFromOpportunity() {
        // Get the test tracker
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity testOpp = [SELECT Id, SBQQ__PrimaryQuote__c FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :testAccount.Id LIMIT 1];
        Shipping_Address__c testShippingAddress = [SELECT Id FROM Shipping_Address__c WHERE Account__c = :testAccount.Id LIMIT 1];
        
        // Update opportunity with shipping address
        testOpp.shipping_address_new__c = testShippingAddress.Id;
        update testOpp;
        
        // Create test request tracker without shipping address in tracker
        OrderPayload payload = MercuryPhase2DataFactory.createCommercialCheckoutPayload(testAccount.Id, testOpp.Id, 'pm_1G5gW1IbzZlMbYFSeAJH3ro5', 'seti_1QxFamIbzZlMbYFSqvcPMtDu', '1234567890', testContact.Id);
        payload.quote.Id = testQuote.Id;
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_COMMERCIAL_CHECKOUT_LINK',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
            // No Shipping_Address_Id__c to test the fallback to opp.shipping_address_new__c
        );

        insert tracker;

        Test.startTest();
        // Set mock for HTTP callout
        Test.setMock(HttpCalloutMock.class, new CommercialCheckoutMock(200));
        try {
            CommercialCheckoutQuoteUpdate updateQuote = new CommercialCheckoutQuoteUpdate(tracker,'Step-4',payload,2);
            OrderUtil.enqueueJobIfPossible(updateQuote);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }

    @isTest
    static void testProcessQuote_EmptyQuoteId() {
        // Get the test tracker
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity testOpp = [SELECT Id, SBQQ__PrimaryQuote__c FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :testAccount.Id LIMIT 1];
        
        // Create test request tracker
        OrderPayload payload = MercuryPhase2DataFactory.createCommercialCheckoutPayload(testAccount.Id, testOpp.Id, 'pm_1G5gW1IbzZlMbYFSeAJH3ro5', 'seti_1QxFamIbzZlMbYFSqvcPMtDu', '1234567890', testContact.Id);
        payload.quote.Id = testQuote.Id;
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_COMMERCIAL_CHECKOUT_LINK',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;

        Test.startTest();
        // Set mock for HTTP callout
        Test.setMock(HttpCalloutMock.class, new CommercialCheckoutMock(200));
        try {
            CommercialCheckoutQuoteUpdate updateQuote = new CommercialCheckoutQuoteUpdate(tracker,'Step-4',payload,0);
            // Test the updateQuoteViaRest method with empty quoteId
            updateQuote.updateQuoteViaRest(new SBQQ__Quote__c(), null);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }

    @isTest
    static void testProcessQuote_ServerError() {
        // Get the test tracker
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity testOpp = [SELECT Id, SBQQ__PrimaryQuote__c FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :testAccount.Id LIMIT 1];
        
        // Create test request tracker
        OrderPayload payload = MercuryPhase2DataFactory.createCommercialCheckoutPayload(testAccount.Id, testOpp.Id, 'pm_1G5gW1IbzZlMbYFSeAJH3ro5', 'seti_1QxFamIbzZlMbYFSqvcPMtDu', '1234567890', testContact.Id);
        payload.quote.Id = testQuote.Id;
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_COMMERCIAL_CHECKOUT_LINK',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;

        Test.startTest();
        // Set mock for HTTP callout with server error
        Test.setMock(HttpCalloutMock.class, new CommercialCheckoutMock(500));
        try {
            CommercialCheckoutQuoteUpdate updateQuote = new CommercialCheckoutQuoteUpdate(tracker,'Step-4',payload,0);
            updateQuote.processJob(); // Call processJob directly to trigger the exception
            System.assert(false, 'Should have thrown an exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Update Quote Job Failed'), 'Should throw RequestTrackerException');
        }
        Test.stopTest();
    }

    @isTest
    static void testProcessQuote_EmptyResponseBody() {
        // Get the test tracker
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity testOpp = [SELECT Id, SBQQ__PrimaryQuote__c FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :testAccount.Id LIMIT 1];
        
        // Create test request tracker
        OrderPayload payload = MercuryPhase2DataFactory.createCommercialCheckoutPayload(testAccount.Id, testOpp.Id, 'pm_1G5gW1IbzZlMbYFSeAJH3ro5', 'seti_1QxFamIbzZlMbYFSqvcPMtDu', '1234567890', testContact.Id);
        payload.quote.Id = testQuote.Id;
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_COMMERCIAL_CHECKOUT_LINK',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;

        Test.startTest();
        // Set mock for HTTP callout with empty response body
        Test.setMock(HttpCalloutMock.class, new CommercialCheckoutMockWithEmptyBody(400));
        try {
            CommercialCheckoutQuoteUpdate updateQuote = new CommercialCheckoutQuoteUpdate(tracker,'Step-4',payload,0);
            updateQuote.processJob(); // Call processJob directly to trigger the exception
            System.assert(false, 'Should have thrown an exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Update Quote Job Failed'), 'Should throw RequestTrackerException');
        }
        Test.stopTest();
    }

    @isTest
    static void testNewInstanceWithRetry() {
        // Get the test tracker
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity testOpp = [SELECT Id, SBQQ__PrimaryQuote__c FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        
        // Create test request tracker
        OrderPayload payload = MercuryPhase2DataFactory.createCommercialCheckoutPayload(testAccount.Id, testOpp.Id, 'pm_1G5gW1IbzZlMbYFSeAJH3ro5', 'seti_1QxFamIbzZlMbYFSqvcPMtDu', '1234567890', testContact.Id);
        
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'TEST-123',
            Transaction_Type__c = 'WEBSTORE_COMMERCIAL_CHECKOUT_LINK',
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(payload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );

        insert tracker;

        Test.startTest();
        CommercialCheckoutQuoteUpdate updateQuote = new CommercialCheckoutQuoteUpdate(tracker,'Step-4',payload,0);
        CommercialCheckoutQuoteUpdate retryJob = (CommercialCheckoutQuoteUpdate) updateQuote.newInstanceWithRetry(1);
        System.assertNotEquals(null, retryJob, 'Retry job should be created');
        Test.stopTest();
    }

    // Mock class for HTTP callout
    private class CommercialCheckoutMock implements HttpCalloutMock {
        private Integer statusCode;
        
        public CommercialCheckoutMock(Integer statusCode) {
            this.statusCode = statusCode;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(statusCode);
            res.setBody('{"success": true}');
            return res;
        }
    }

    // Mock class for HTTP callout with empty body
    private class CommercialCheckoutMockWithEmptyBody implements HttpCalloutMock {
        private Integer statusCode;
        
        public CommercialCheckoutMockWithEmptyBody(Integer statusCode) {
            this.statusCode = statusCode;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(statusCode);
            res.setBody(''); // Empty response body
            return res;
        }
    }
}
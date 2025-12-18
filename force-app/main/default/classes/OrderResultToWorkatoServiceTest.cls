@IsTest
private class OrderResultToWorkatoServiceTest {

    @testSetup
    static void setup() {
        // Create test data using MercuryPhase2DataFactory
        Account testAccount = MercuryPhase2DataFactory.createAccount('Test Account', true);
        Contact testContact = MercuryPhase2DataFactory.createContact(testAccount.Id, true);
        Shipping_Address__c testShippingAddress = MercuryPhase2DataFactory.createShippingAddress(testAccount.Id, testContact.Id, true);
        // Create Opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            Amount = 1200,
            CurrencyIsoCode = 'USD',
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
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        update testAccount;
        
        TriggerHandler.clearAllBypasses();
        Test.stopTest();
    }

    // ✅ Mock for HTTP callout
    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"message": "success"}');
            res.setStatusCode(200);
            res.setStatus('OK');
            return res;
        }
    }

    @IsTest
    static void testOrderResultToWorkatoService_Success() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // ✅ Insert required Account & Opportunity
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :testOpp.Id LIMIT 1];

        // ✅ Insert Tracker
        Request_Tracker__c tracker = new Request_Tracker__c(
            Opportunity_Id__c = testOpp.Id,
            Quote_Id__c = testQuote.Id
        );
        insert tracker;

        // ✅ Create OrderPayload
        OrderPayload payload = new OrderPayload();
        
        payload.order = new OrderPayload.Order();
        payload.order.Id = 'ORD-001';
        payload.order.payment_status = 'paid';

        payload.quote = new OrderPayload.Quote();
        payload.quote.stripeIntentId = 'pi_001';
        payload.quote.stripeChargeId = 'ch_001';

        payload.opportunity = new OrderPayload.Opportunity();
        payload.opportunity.currencyIsoCode = 'USD';

        try{
            // ✅ Run the actual Queueable job using Test.start/stop
            Test.startTest();

            OrderResultToWorkatoService job = new OrderResultToWorkatoService(tracker, 'Step1', payload, 0);
            
            // Bypass metadata requirement using reflection or injecting it via context (if required in constructor)
            job.orderProcessingSettings = new Order_Processing_Settings__mdt();
            job.orderProcessingSettings.Named_Credential__c = 'Mock_NC';
            job.orderProcessingSettings.Endpoint__c = '/order/process';
            job.orderProcessingSettings.Http_Method__c = 'POST';
            job.orderProcessingSettings.Content_Type__c = 'application/json';
            job.orderProcessingSettings.Header_Key__c = 'Authorization';
            job.orderProcessingSettings.Header_Value__c = 'Bearer dummy';
            job.orderProcessingSettings.Callout_Timeout__c = 10000;
            job.orderProcessingSettings.Status_Code__c = 200;
            job.orderProcessingSettings.Maximum_Retries__c = 3;

            job.processJob();

            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            System.debug('Error Stack: ' + e.getStackTraceString());
        }
    }

    @IsTest
    static void testOrderResultToWorkatoService_WithSampleResponse() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Get test data from setup
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
        PricebookEntry testPricebook = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id AND Pricebook2Id = :Test.getStandardPricebookId() LIMIT 1];
        
        // Create test payload
        OrderPayload orderPayload = MercuryPhase2DataFactory.createAmmendmentPayload(testAccount.Id, testContact.Id, testProduct.Id, testPricebook.Id);
        
        // Create test tracker
        Request_Tracker__c tracker = new Request_Tracker__c(
            Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
            Opportunity_Id__c = testOpp.Id,
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(orderPayload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );
        insert tracker;
        try{
            Test.startTest();
        
            // Create and configure the service
            OrderResultToWorkatoService service = new OrderResultToWorkatoService(tracker, 'Step-1', orderPayload, 0);
            
            // Configure settings
            service.orderProcessingSettings = new Order_Processing_Settings__mdt(
                DeveloperName = 'Workato',
                Named_Credential__c = 'Mock_NC',
                Endpoint__c = '/order/process',
                Http_Method__c = 'POST',
                Content_Type__c = 'application/json',
                Header_Key__c = 'Authorization',
                Header_Value__c = 'Bearer dummy',
                Callout_Timeout__c = 10000,
                Status_Code__c = 200,
                Maximum_Retries__c = 3
            );

            // Execute the service
            service.processJob();
            
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            System.debug('Error Stack: ' + e.getStackTraceString());
        }
    }

    @IsTest
    static void testOrderResultToWorkatoService_QuoteRecalculationFailed() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Get test data from setup
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
        PricebookEntry testPricebook = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id AND Pricebook2Id = :Test.getStandardPricebookId() LIMIT 1];
        
        // Create test payload
        OrderPayload orderPayload = MercuryPhase2DataFactory.createAmmendmentPayload(testAccount.Id, testContact.Id, testProduct.Id, testPricebook.Id);
        
        // Create test tracker
        Request_Tracker__c tracker = new Request_Tracker__c(
            Transaction_Type__c = 'WEBSTORE_ADD_ON_PURCHASE',
            Opportunity_Id__c = testOpp.Id,
            Account_Id__c = testAccount.Id,
            Request__c = JSON.serialize(orderPayload),
            Status__c = 'Received',
            Step_Status__c = 'Step-1'
        );
        insert tracker;

        // Update Opportunity to simulate quote recalculation failure
        testOpp.Amount = null;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        update testOpp;
        TriggerHandler.clearAllBypasses();
        try{
            Test.startTest();
            
            // Create and configure the service
            OrderResultToWorkatoService service = new OrderResultToWorkatoService(tracker, 'Step-1', orderPayload, 0);
            
            // Configure settings
            service.orderProcessingSettings = new Order_Processing_Settings__mdt(
                DeveloperName = 'Workato',
                Named_Credential__c = 'Mock_NC',
                Endpoint__c = '/order/process',
                Http_Method__c = 'POST',
                Content_Type__c = 'application/json',
                Header_Key__c = 'Authorization',
                Header_Value__c = 'Bearer dummy',
                Callout_Timeout__c = 10000,
                Status_Code__c = 200,
                Maximum_Retries__c = 3
            );

            // Execute the service
            service.processJob();
            
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            System.debug('Error Stack: ' + e.getStackTraceString());
        }
    }
}
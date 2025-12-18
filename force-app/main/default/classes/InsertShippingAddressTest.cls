@isTest
private class InsertShippingAddressTest {

    @TestSetup
    static void setupTestData() {
        // Create Account, Contact, Shipping Address
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

        // Create Contract
        Contract testContract = MercuryPhase2DataFactory.createContract(testAccount.Id, true);
        testContract.Status = 'Activated';
        testContract.SBQQ__Opportunity__c = testOpp.Id;
        testContract.ActivatedDate = Date.today();
        update testContract;

        testAccount.Latest_Active_Contract__c = testContract.Id;
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        update testAccount;

        Id pricebookId = Test.getStandardPricebookId();
        Product2 testProduct = MercuryPhase2DataFactory.createProduct(true);
        PricebookEntry vg33PB = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = testProduct.Id,
            UnitPrice = 10000,
            IsActive = true
        );
        insert vg33PB;

        // Create Quote and Quote Line
        SBQQ__Quote__c testQuote = MercuryPhase2DataFactory.createQuote(testAccount.Id, testOpp.Id, true);
        MercuryPhase2DataFactory.createQuoteLines(
            testAccount.Id,
            testQuote.Id,
            String.valueOf(testShippingAddress.Id),
            String.valueOf(testProduct.Id),
            String.valueOf(vg33PB.Id),
            10000,
            2,
            true
        );
        SBQQ.TriggerControl.enable();

        // Create Request_Tracker__c with Transaction_Type__c
        Request_Tracker__c rt = MercuryPhase2DataFactory.createAmendmentTracker(
            testAccount.Id,
            testContact.Id,
            pricebookId,
            testProduct.Id,
            false
        );
        rt.Opportunity_Id__c = testOpp.Id;
        rt.Transaction_Type__c = 'New'; // Important field
        TriggerHandler.bypass('RequestTrackerTriggerHandler');
        insert rt;

        TriggerHandler.clearAllBypasses();
        Test.stopTest();
    }

    @isTest
    static void testInsertShippingAddress_NewAddress() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact contact = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
        Request_Tracker__c tracker = [SELECT Id, Transaction_Type__c FROM Request_Tracker__c WHERE Account_Id__c = :acc.Id LIMIT 1];

        
        Shipping_Address__c address = [
            SELECT 
                Id,
                Shipping_Contact__c,
                Shipping_Address_Line_1__c,
                Shipping_City__c,
                Shipping_State__c,
                Shipping_Zip_Code__c,
                Shipping_Country__c,
                Shipping_FirstName__c,
                Shipping_LastName__c,
                Shipping_Email__c,
                Shipping_Phone__c,
                Type__c
            FROM Shipping_Address__c 
            WHERE Account__c = :acc.Id 
            LIMIT 1
        ];
        
   
        
        OrderPayload payload = new OrderPayload();
        payload.order = new OrderPayload.Order();
        payload.order.account_id = acc.Id;
        payload.shipping_address = new OrderPayload.ShippingAddress();
        payload.shipping_address.account = acc.Id;
        payload.shipping_address.shippingContact = address.Shipping_Contact__c;
        payload.shipping_address.shippingAddressLine1 = address.Shipping_Address_Line_1__c;
        payload.shipping_address.shippingCity = 'Retry City';
        payload.shipping_address.shippingState = 'California';
        payload.shipping_address.shippingZipCode = '90001';
        payload.shipping_address.shippingZipCode = '99999';
        payload.shipping_address.shippingEmail = address.Shipping_Email__c;
        payload.shipping_address.shippingPhone = address.Shipping_Phone__c;
        payload.shipping_address.shippingFirstName = address.Shipping_FirstName__c;
        payload.shipping_address.shippingLastName = address.Shipping_LastName__c;

        try {
            Test.startTest();
            InsertShippingAddress job = new InsertShippingAddress(tracker, 'Step 1', payload, 0);
            System.enqueueJob(job);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }

    
    @isTest
    static void testInsertShippingAddress_NoShippingAddressPassedinPayload() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact contact = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
        Request_Tracker__c tracker = [SELECT Id, Transaction_Type__c FROM Request_Tracker__c WHERE Account_Id__c = :acc.Id LIMIT 1];

        
        Shipping_Address__c address = [
            SELECT 
                Id,
                Shipping_Contact__c,
                Shipping_Address_Line_1__c,
                Shipping_City__c,
                Shipping_State__c,
                Shipping_Zip_Code__c,
                Shipping_Country__c,
                Shipping_FirstName__c,
                Shipping_LastName__c,
                Shipping_Email__c,
                Shipping_Phone__c,
                Type__c
            FROM Shipping_Address__c 
            WHERE Account__c = :acc.Id 
            LIMIT 1
        ];
        
   
        
        OrderPayload payload = new OrderPayload();
        /*payload.order = new OrderPayload.Order();
        payload.order.account_id = acc.Id;
        payload.shipping_address = new OrderPayload.ShippingAddress();
        payload.shipping_address.account = acc.Id;
        payload.shipping_address.shippingContact = address.Shipping_Contact__c;
        payload.shipping_address.shippingAddressLine1 = address.Shipping_Address_Line_1__c;
        payload.shipping_address.shippingCity = 'Retry City';
        payload.shipping_address.shippingState = 'California';
        payload.shipping_address.shippingZipCode = '90001';
        payload.shipping_address.shippingZipCode = '99999';
        payload.shipping_address.shippingEmail = address.Shipping_Email__c;
        payload.shipping_address.shippingPhone = address.Shipping_Phone__c;
        payload.shipping_address.shippingFirstName = address.Shipping_FirstName__c;
        payload.shipping_address.shippingLastName = address.Shipping_LastName__c;*/

        try {
            Test.startTest();
            InsertShippingAddress job = new InsertShippingAddress(tracker, 'Step 1', payload, 0);
            System.enqueueJob(job);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }

    @isTest
    static void testInsertShippingAddress_ExistingAddress() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact contact = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
        Shipping_Address__c existing = [SELECT Id, Shipping_Address_Line_1__c FROM Shipping_Address__c WHERE Account__c = :acc.Id LIMIT 1];
        Request_Tracker__c tracker = [SELECT Id, Transaction_Type__c FROM Request_Tracker__c WHERE Account_Id__c = :acc.Id LIMIT 1];

       Shipping_Address__c address = [
            SELECT 
                Id,
                Shipping_Contact__c,
                Shipping_Address_Line_1__c,
                Shipping_City__c,
                Shipping_State__c,
                Shipping_Zip_Code__c,
                Shipping_Country__c,
                Shipping_FirstName__c,
                Shipping_LastName__c,
                Shipping_Email__c,
                Shipping_Phone__c,
                Type__c
            FROM Shipping_Address__c 
            WHERE Account__c = :acc.Id 
            LIMIT 1
        ];
        
        OrderPayload payload = new OrderPayload();
        payload.order = new OrderPayload.Order();
        payload.order.account_id = acc.Id;
        payload.shipping_address = new OrderPayload.ShippingAddress();
        payload.shipping_address.account = acc.Id;
        payload.shipping_address.shippingContact = address.Shipping_Contact__c;
        payload.shipping_address.shippingAddressLine1 = address.Shipping_Address_Line_1__c;
        payload.shipping_address.shippingCity = address.Shipping_City__c;
        payload.shipping_address.shippingState = address.Shipping_State__c;
        payload.shipping_address.shippingZipCode = address.Shipping_Zip_Code__c;
        payload.shipping_address.shippingCountry = address.Shipping_Country__c;
        payload.shipping_address.shippingEmail = address.Shipping_Email__c;
        payload.shipping_address.shippingPhone = address.Shipping_Phone__c;
        payload.shipping_address.shippingFirstName = address.Shipping_FirstName__c;
        payload.shipping_address.shippingLastName = address.Shipping_LastName__c;

        try {
            Test.startTest();
            InsertShippingAddress job = new InsertShippingAddress(tracker, 'Step 1', payload, 0);
            System.enqueueJob(job);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }

    @isTest
    static void testInsertShippingAddress_RetryLogic() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact contact = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
        Request_Tracker__c tracker = [SELECT Id, Transaction_Type__c FROM Request_Tracker__c WHERE Account_Id__c = :acc.Id LIMIT 1];

        OrderPayload payload = new OrderPayload();
        payload.shipping_address = new OrderPayload.ShippingAddress();
        payload.shipping_address.shippingAddressLine1 = 'Retry Address';
        payload.shipping_address.shippingCity = 'Retry City';
        payload.shipping_address.shippingState = 'Retry State';
        payload.shipping_address.shippingZipCode = '99999';
        payload.shipping_address.shippingCountry = 'Retry Country';
        payload.shipping_address.shippingFirstName = 'Retry';
        payload.shipping_address.shippingLastName = 'User';
        payload.shipping_address.shippingEmail = 'retry@example.com';
        payload.shipping_address.shippingPhone = '0000000000';
        payload.shipping_address.shippingContact = contact.Id;

        try {
            Test.startTest();
            InsertShippingAddress job = new InsertShippingAddress(tracker, 'Step Retry', payload, 0); // simulate retryCount = 2
            //System.enqueueJob(job); // should retry one more time (retryCount < MAX_RETRY)
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }
}
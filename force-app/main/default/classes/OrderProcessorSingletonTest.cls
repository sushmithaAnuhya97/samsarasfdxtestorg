@isTest
private class OrderProcessorSingletonTest {

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
    
    static testMethod void testQueryAccount() {
        Account acc= [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        OrderProcessorSingleton ops = OrderProcessorSingleton.getInstance();
        Account result = ops.queryAccount(acc.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals(acc.Id, result.Id);
    }
    
    static testMethod void testQueryContact() {
        Account acc= [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Contact con = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
        
        Test.startTest();
        OrderProcessorSingleton ops = OrderProcessorSingleton.getInstance();
        Contact result = ops.queryContact(acc.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
    }
    
    static testMethod void testQueryCustomer360() {
        Account acc= [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Contract contract = [SELECT Id FROM Contract WHERE AccountId = :acc.Id LIMIT 1];
        
        Customer_360__c customer = new Customer_360__c(Account__c = acc.Id, Latest_Active_Contract_Historical__c = contract.Id);
        insert customer;

        Test.startTest();
        OrderProcessorSingleton ops = OrderProcessorSingleton.getInstance();
        Id result = ops.queryCustomer360(acc.Id);
        Test.stopTest();
        
        System.assertEquals(contract.Id, result);
    }
    
    static testMethod void testGetActiveSubscriptionsCount() {
        Account acc = new Account(Name = 'Test Account',Organization_Size__c='1 - 99',BillingCountry='United States',BillingCountryCode='US',BillingState='Texas',BillingStateCode='TX');
        insert acc;
        
        Contract contract = new Contract(AccountId = acc.Id, StartDate = Date.today(), EndDate = Date.today().addMonths(12));
        insert contract;
        
        SBQQ__Subscription__c sub = new SBQQ__Subscription__c(SBQQ__Contract__c = contract.Id, SBQQ__Quantity__c=10);
        insert sub;
        
        Test.startTest();
        OrderProcessorSingleton ops = OrderProcessorSingleton.getInstance();
        Integer count = ops.getActiveSubscriptionsCount(contract.Id);
        Test.stopTest();
        
        System.assertEquals(1, count);
    }
    
    static testMethod void testQueryShippingAddress() {
        Account acc= [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];


        
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
        
        Test.startTest();
        OrderProcessorSingleton ops = OrderProcessorSingleton.getInstance();
        Shipping_Address__c result = ops.queryShippingAddress(payload);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals(address.Id, result.Id);
    }
    
    static testMethod void testQueryOpportunity() {
        Account acc= [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId = :acc.Id LIMIT 1];
        
        Test.startTest();
        OrderProcessorSingleton ops = OrderProcessorSingleton.getInstance();
        Opportunity result = ops.queryOpportunity(opp.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals(opp.Id, result.Id);
    }
    
    static testMethod void testQueryQuote() {
        Account acc= [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId = :acc.Id LIMIT 1];
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opp.Id LIMIT 1];
        
        Test.startTest();
        OrderProcessorSingleton ops = OrderProcessorSingleton.getInstance();
        SBQQ__Quote__c result = ops.queryQuote(quote.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals(quote.Id, result.Id);
    }
    
    static testMethod void testDeserializePayload() {
        String json = '{ "shipping_address": { "account": "001xxxxxxxxxxxx", "shippingContact": "003xxxxxxxxxxxx", "shippingAddressLine1": "123 Main St", "shippingCity": "Austin", "shippingState": "TX", "shippingZipCode": "73301", "shippingCountry": "USA" } }';
        
        Test.startTest();
        OrderProcessorSingleton ops = OrderProcessorSingleton.getInstance();
        OrderPayload payload = ops.deserializePayload(json);
        Test.stopTest();
        
        System.assertNotEquals(null, payload);
        System.assertEquals('Austin', payload.shipping_address.shippingCity);
    }
    
    // static testMethod void testValidateContactAndShippingAddressIds() {
    //     Account acc = new Account(Name = 'Test Account',Organization_Size__c='1 - 99',BillingCountry='United States',BillingCountryCode='US',BillingState='Texas',BillingStateCode='TX');
    //     insert acc;
        
    //     Contact con = new Contact(FirstName = 'Jane', LastName = 'Doe', Email = 'test@example.com', Phone = '1234567890', AccountId = acc.Id);
    //     insert con;
        
    //     Shipping_Address__c addr = new Shipping_Address__c(
    //         Name = 'Addr1',
    //         Account__c = acc.Id,
    //         Shipping_Contact__c = con.Id,
    //         Shipping_Address_Line_1__c = '123 Main St',
    //         Shipping_City__c = 'Austin',
    //         Shipping_State__c = 'Texas',
    //         Shipping_Zip_Code__c = '73301',
    //         Shipping_Country__c = 'United States',
    //         Shipping_Email__c = 'test@example.com',
    //         Shipping_Phone__c = '1234567890',
    //         Shipping_FirstName__c = 'Jane',
    //         Shipping_LastName__c = 'Doe'
    //     );
    //     insert addr;
        
    //     OrderPayload payload = new OrderPayload();
    //     payload.shipping_address = new OrderPayload.ShippingAddress();
    //     payload.shipping_address.account = acc.Id;
    //     payload.shipping_address.shippingContact = con.Id;
    //     payload.shipping_address.shippingAddressLine1 = '123 Main St';
    //     payload.shipping_address.shippingCity = 'Austin';
    //     payload.shipping_address.shippingState = 'Texas';
    //     payload.shipping_address.shippingZipCode = '73301';
    //     payload.shipping_address.shippingCountry = 'United States';
        
    //     Test.startTest();
    //     OrderProcessorSingleton.getInstance().validateContactAndShippingAddressIds(payload);
    //     Test.stopTest();
        
    //     System.assert(true); // If no exception is thrown, it's valid.
    // }
    
    static testMethod void testDeserialization(){
        String jsonPayload = '{"order":{"id":79243,"transaction_type":"WEBSTORE_ADD_ON_PURCHASE","account_id":"001WF00000NbPBtYAN","is_enterprise":false,"docusign_envelope_id":"a8655d69-35f7-42c1-9316-ba103371dbc0","payment_status":null},"account":{"autoRenewalOptOut":true,"Id":"001WF00000NbPBtYAN"},"opportunity":{"accountId":"001WF00000NbPBtYAN","stageName":"Qualified","name":"Webstore Opportunity - 2025-02-28 - 0014p00001jj8ktAAA - 59168","closeDate":"2025-02-28","shippingContact":"003WF00000VjVqbYAF","smallFleetOpportunity":false,"pricebook2Id":"01s4p000004cVodAAE","licenseTerm":3,"currencyIsoCode":"USD","canCreate":true,"excludeFromXactly":false,"isWebstoreUpsellOpportunity":true,"initialPaymentTerms":"Net 30","paymentTerms":"Net 30","configurationSegment":"Non Express","notes":"<p>Arcadian Checkout V2</p><p>Webstore redesign variant, variant VGCM cross-sell</p><p><br></p>Order placed by - <p>First name: Earl</p><p>Last name: Perry</p><p>Email address: safety@beelinec.com</p><p>Order ID: 79243</p>"},"quote":{"selectedPaymentType":"Upfront Payments","checkoutDiscount":0,"shippingMethod":"Ground","paymentTerms":"Net 30","poNumber":null,"primary":true,"status":"Approved","startDate":"2025-02-28","amountReceived":0,"paymentToken":"pm_1IEf3FIbzZlMbYFSvAbpRda3","paymentMethod":"card","stripeChargeId":"","stripeIntentId":"seti_1QxBxbIbzZlMbYFSV9Xtbsnk","shippingAndHandlingManual":15,"vatId":null,"expressAgreementAcceptedDate":"2025-02-28","quote_lines":[{"product":"01t1a000001LU4ZAAW","pricebookEntryId":"01u4p000004KPnOAAW","currencyIsoCode":"USD","listPrice":55,"discount":0,"quantity":1},{"product":"01t1a000001LTstAAG","pricebookEntryId":"01u4p000004KPp0AAG","currencyIsoCode":"USD","listPrice":15,"discount":0,"quantity":2}]},"shipping_address":{"shippingCity":"Garden City","shippingEmail":"esp1361@gmail.com","shippingPhone":"9123089885","shippingState":"Georgia","shippingCountry":"United States","shippingContact":"003WF00000VjVqbYAF","shippingLastName":"Perry","shippingZipCode":"31408","shippingFirstName":"Earl S.","shippingAddressLine1":"1570 Dean Forrest Road","shippingAddressLine2":"Test","account":"001WF00000NbPBtYAN"}}';
        Test.startTest();
        OrderPayload orderpyaload = OrderProcessorSingleton.getInstance().deserializePayload(jsonPayload);
        Test.stopTest();
    }
    
    static testMethod void testQueryQuoteLines() {
        // Create test data
        Account acc= [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
        Shipping_Address__c testShippingAddress = [SELECT Id FROM Shipping_Address__c WHERE Account__c = :acc.Id LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId = :acc.Id LIMIT 1];
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opp.Id LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
        PricebookEntry vg33PB = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id AND Pricebook2Id = :Test.getStandardPricebookId() LIMIT 1];
         
        Test.startTest();
        List<SBQQ__QuoteLine__c> result = OrderProcessorSingleton.queryQuoteLines(quote.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
    }
    
    static testMethod void testQueryQuoteLines_Empty() {
        Test.startTest();
        List<SBQQ__QuoteLine__c> result = OrderProcessorSingleton.queryQuoteLines(null);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
    }

    static testMethod void testQueryShiippingAddressById() {
        Account acc= [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
        Shipping_Address__c testShippingAddress = [SELECT Id FROM Shipping_Address__c WHERE Account__c = :acc.Id LIMIT 1];
        String shippingAddressId = testShippingAddress.Id;
        Test.startTest();
        OrderProcessorSingleton ops = OrderProcessorSingleton.getInstance();
        try {
            Shipping_Address__c result = ops.queryShiippingAddressById(shippingAddressId);
            Request_Tracker__c result2 = ops.findRequestTracker(acc.Id, con.Id);
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
      
        Test.stopTest();
    }
}
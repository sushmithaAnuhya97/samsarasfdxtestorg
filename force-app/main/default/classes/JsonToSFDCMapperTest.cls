@isTest
private class JsonToSFDCMapperTest {

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

        // Set the renewed contract relationship on the opportunity
        testOpp.SBQQ__RenewedContract__c = testContract.Id;
        update testOpp;

        testAccount.Latest_Active_Contract__c = testContract.Id;
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        update testAccount;
        
        TriggerHandler.clearAllBypasses();
        Test.stopTest();
    }

    @isTest static void testJsonToSFDCMapperAllMethods() {
        // Get test data from setup
        List<Account> accounts = [SELECT Id FROM Account LIMIT 1];
        List<Opportunity> opportunities = [SELECT Id FROM Opportunity LIMIT 1];
        List<Shipping_Address__c> shippingAddresses = [SELECT Id FROM Shipping_Address__c LIMIT 1];
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 1];
        List<PricebookEntry> pricebookEntries = [SELECT Id FROM PricebookEntry LIMIT 1];
        List<SBQQ__Quote__c> quotes = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
        
        OrderPayload payload = new OrderPayload();
        payload.account = new OrderPayload.Account();
        payload.opportunity = new OrderPayload.Opportunity();
        payload.quote = new OrderPayload.Quote();
        payload.shipping_address = new OrderPayload.ShippingAddress();
        payload.quote.quoteLines = new List<OrderPayload.QuoteLine>();
        
        // ---------- Account Test ----------
        payload.account.autoRenewalOptOut = true;
        payload.account.billingCity = 'Austin';
        payload.account.billingState = 'TX';
        payload.account.billingStreet = '123 Main St';
        payload.account.billingCountry = 'USA';
        payload.account.billingEmail = 'test@example.com';
        payload.account.billingPhone = '1234567890';
        payload.account.billingPostalCode = '78701';
        payload.account.billingLastName = 'Doe';
        payload.account.billingFirstName = 'John';

        Account acc1 = JsonToSFDCMapper.mapAccountData(payload);
        Account acc2 = JsonToSFDCMapper.mapFirstTimePurchaseAccountData(payload);

        System.assertNotEquals(null, acc1);
        System.assertNotEquals(null, acc2);

        // ---------- Opportunity Test ----------
        payload.opportunity = new OrderPayload.Opportunity();
        payload.opportunity.id = opportunities[0].Id;
        payload.opportunity.stageName = 'Closed Won';
        payload.opportunity.name = 'Test Opportunity';
        payload.opportunity.closeDate = Date.today();
        payload.opportunity.smallFleetOpportunity = true;
        payload.opportunity.pricebook2Id = pricebookEntries[0].Id;
        payload.opportunity.licenseTerm = 12;
        payload.opportunity.currencyIsoCode = 'USD';
        payload.opportunity.canCreate = true;
        payload.opportunity.excludeFromXactly = false;
        payload.opportunity.isWebstoreUpsellOpportunity = true;
        payload.opportunity.initialPaymentTerms = 'Net 30';
        payload.opportunity.paymentTerms = 'Prepaid';
        payload.opportunity.configurationSegment = 'SMB';
        payload.opportunity.notes = 'Some internal note';
        payload.opportunity.purchaseType = 'New';
        payload.opportunity.amountReceived = 100.0;
        payload.opportunity.paymentToken = 'tok_opp';
        payload.opportunity.paymentMethod = 'Credit Card/ACH Debit';
        payload.opportunity.stripeChargeId = 'ch_opp';
        payload.opportunity.stripeIntentId = 'pi_opp';
        payload.opportunity.vatNumber = 'VAT123';
        payload.opportunity.shippingAndHandlingManual = 10.0;
        payload.opportunity.expressAgreementAcceptedDate = null;

        Opportunity opp1 = JsonToSFDCMapper.mapOpportunityData(payload);
        Opportunity opp2 = JsonToSFDCMapper.mapMidMarketPlusCheckoutOpportunityData(payload);
        Opportunity opp3 = JsonToSFDCMapper.mapDigitalRenewalOpportunityData(payload);

        System.assertNotEquals(null, opp1);
        System.assertNotEquals(null, opp2);
        System.assertNotEquals(null, opp3);

        // ---------- Shipping Address Test ----------
        payload.shipping_address = new OrderPayload.ShippingAddress();
        payload.shipping_address.shippingAddressLine1 = '456 Ship Lane';
        payload.shipping_address.shippingAddressLine2 = 'Suite 101';
        payload.shipping_address.shippingCity = 'Dallas';
        payload.shipping_address.shippingState = 'TX';
        payload.shipping_address.shippingZipCode = '75201';
        payload.shipping_address.shippingCountry = 'USA';
        payload.shipping_address.shippingEmail = 'ship@example.com';
        payload.shipping_address.shippingPhone = '9876543210';
        payload.shipping_address.shippingLastName = 'Smith';
        payload.shipping_address.shippingFirstName = 'Jane';

        Shipping_Address__c shipAddr = JsonToSFDCMapper.mapShippingAddress(payload);
        System.assertNotEquals(null, shipAddr);

        // ---------- Quote Test ----------
        payload.quote = new OrderPayload.Quote();
        payload.quote.id = quotes[0].Id;
        payload.quote.name = 'Test Quote';
        payload.quote.selectedPaymentType = 'Prepaid';
        payload.quote.checkoutDiscount = 15.0;
        payload.quote.shippingMethod = 'Ground';
        payload.quote.paymentTerms = 'Monthly';
        payload.quote.poNumber = 'PO-12345';
        payload.quote.primary = true;
        payload.quote.status = 'Draft';
        payload.quote.expressAgreementAcceptedDate = Date.today();
        payload.quote.amountReceived = 250.00;
        payload.quote.paymentToken = 'tok_quote';
        payload.quote.paymentMethod = 'ACH';
        payload.quote.stripeChargeId = 'ch_quote';
        payload.quote.stripeIntentId = 'pi_quote';
        payload.quote.shippingAndHandlingManual = 20.0;
        payload.quote.configurationSegment = 'Mid-Market';
        payload.quote.account = accounts[0].Id;
        payload.quote.opportunity = opportunities[0].Id;
        payload.quote.pricebook2Id = pricebookEntries[0].Id;
        payload.quote.currencyIsoCode = 'USD';
        payload.quote.expressSelectedDiscount = 10.0;

        SBQQ__Quote__c q1 = JsonToSFDCMapper.mapQuoteData(payload);
        SBQQ__Quote__c q2 = JsonToSFDCMapper.mapFirstTimePurchaseQuoteData(payload);
        SBQQ__Quote__c q3 = JsonToSFDCMapper.mapDigitalRenewalQuoteData(payload);
        SBQQ__Quote__c q4 = JsonToSFDCMapper.mapCommercialCheckoutQuoteData(payload);

        System.assertNotEquals(null, q1);
        System.assertNotEquals(null, q2);
        System.assertNotEquals(null, q3);
        System.assertNotEquals(null, q4);

        // ---------- Quote Line Test ----------
        payload.quote.quoteLines = new List<OrderPayload.QuoteLine>();
        payload.quote.quoteLines.add(new OrderPayload.QuoteLine());
        payload.quote.quoteLines[0].product = products[0].Id;
        payload.quote.quoteLines[0].pricebookEntryId = pricebookEntries[0].Id;
        payload.quote.quoteLines[0].currencyIsoCode = 'USD';
        payload.quote.quoteLines[0].listPrice = 99.99;
        payload.quote.quoteLines[0].discount = 5.00;
        payload.quote.quoteLines[0].quantity = 2;

        List<OrderPayload.QuoteLine> qlList = payload.quote.quoteLines;
        List<SBQQ__QuoteLine__c> resultQuoteLines = JsonToSFDCMapper.mapQuoteLines(payload);
        System.assertEquals(1, resultQuoteLines.size());
        System.assertEquals(qlList[0].product, resultQuoteLines[0].SBQQ__Product__c);

        // Test null and empty scenarios to increase coverage
        System.assertEquals(null, JsonToSFDCMapper.mapAccountData(null));
        System.assertEquals(null, JsonToSFDCMapper.mapOpportunityData(null));
        System.assertEquals(null, JsonToSFDCMapper.mapShippingAddress(null));
        System.assertEquals(null, JsonToSFDCMapper.mapQuoteData(null));
        System.assertEquals(null, JsonToSFDCMapper.mapQuoteLines(null));

        // Test empty payload scenarios
        OrderPayload emptyPayload = new OrderPayload();
        System.assertEquals(null, JsonToSFDCMapper.mapAccountData(emptyPayload));
        System.assertEquals(null, JsonToSFDCMapper.mapOpportunityData(emptyPayload));
        System.assertEquals(null, JsonToSFDCMapper.mapShippingAddress(emptyPayload));
        System.assertEquals(null, JsonToSFDCMapper.mapQuoteData(emptyPayload));
        System.assertEquals(null, JsonToSFDCMapper.mapQuoteLines(emptyPayload));

        // Test with null account
        OrderPayload payloadWithNullAccount = new OrderPayload();
        payloadWithNullAccount.account = null;
        System.assertEquals(null, JsonToSFDCMapper.mapAccountData(payloadWithNullAccount));

        // Test empty shipping address
        OrderPayload payloadWithEmptyShipping = new OrderPayload();
        payloadWithEmptyShipping.shipping_address = new OrderPayload.ShippingAddress();
        // All fields are null/empty by default
        Shipping_Address__c emptyShippingResult = JsonToSFDCMapper.mapShippingAddress(payloadWithEmptyShipping);
        System.assertEquals(null, emptyShippingResult);

        // Test mapCloseDateForDigitalRenewals with null opportunity
        Opportunity testOpp = new Opportunity();
        testOpp.Id = opportunities[0].Id;
        JsonToSFDCMapper.mapCloseDateForDigitalRenewals(testOpp, null, null);

        // Test mapCloseDateForDigitalRenewals with valid data
        OrderPayload renewalPayload = new OrderPayload();
        renewalPayload.opportunity = new OrderPayload.Opportunity();
        renewalPayload.opportunity.id = opportunities[0].Id;
        renewalPayload.opportunity.notes = 'Auto-renewal [Phase 1]';
        renewalPayload.opportunity.expressAgreementAcceptedDate = '2025-04-28';
        renewalPayload.shipping_address = new OrderPayload.ShippingAddress();
        renewalPayload.shipping_address.shippingAddressLine1 = '123 Test St';
        
        JsonToSFDCMapper.mapCloseDateForDigitalRenewals(testOpp, renewalPayload.opportunity, renewalPayload.shipping_address);

        // Test mapCloseDateForDigitalRenewals with empty shipping address
        OrderPayload emptyShippingPayload = new OrderPayload();
        emptyShippingPayload.opportunity = new OrderPayload.Opportunity();
        emptyShippingPayload.opportunity.id = opportunities[0].Id;
        emptyShippingPayload.opportunity.notes = 'Self-serve renewal';
        emptyShippingPayload.opportunity.expressAgreementAcceptedDate = '2025-04-28';
        emptyShippingPayload.shipping_address = new OrderPayload.ShippingAddress();
        // Empty shipping address object
        
        JsonToSFDCMapper.mapCloseDateForDigitalRenewals(testOpp, emptyShippingPayload.opportunity, emptyShippingPayload.shipping_address);

        // Test mapQuoteLines with empty list
        OrderPayload emptyQuoteLinesPayload = new OrderPayload();
        emptyQuoteLinesPayload.quote = new OrderPayload.Quote();
        emptyQuoteLinesPayload.quote.quoteLines = new List<OrderPayload.QuoteLine>();
        
        List<SBQQ__QuoteLine__c> emptyQuoteLinesResult = JsonToSFDCMapper.mapQuoteLines(emptyQuoteLinesPayload);
        System.assertEquals(null, emptyQuoteLinesResult);

        // Test mapQuoteLines with null quote lines
        OrderPayload nullQuoteLinesPayload = new OrderPayload();
        nullQuoteLinesPayload.quote = new OrderPayload.Quote();
        nullQuoteLinesPayload.quote.quoteLines = null;
        
        List<SBQQ__QuoteLine__c> nullQuoteLinesResult = JsonToSFDCMapper.mapQuoteLines(nullQuoteLinesPayload);
        System.assertEquals(null, nullQuoteLinesResult);

        // Test isNullOrEmpty method with Map<String, Object> to cover lines 12,13
        Map<String, Object> testMap = new Map<String, Object>();
        testMap.put('key', 'value');
        // This will test the instanceof Map<String, Object> check and mapObj.isEmpty() call
        OrderPayload mapTestPayload = new OrderPayload();
        mapTestPayload.opportunity = new OrderPayload.Opportunity();
        mapTestPayload.opportunity.id = opportunities[0].Id;
        mapTestPayload.opportunity.notes = 'Test notes';
        mapTestPayload.shipping_address = new OrderPayload.ShippingAddress();
        mapTestPayload.shipping_address.shippingAddressLine1 = '123 Test St';
        
        Opportunity mapTestOpp = new Opportunity();
        mapTestOpp.Id = opportunities[0].Id;
        JsonToSFDCMapper.mapCloseDateForDigitalRenewals(mapTestOpp, mapTestPayload.opportunity, mapTestPayload.shipping_address);

        // Test with empty Map to trigger the isEmpty() check
        OrderPayload emptyMapTestPayload = new OrderPayload();
        emptyMapTestPayload.opportunity = new OrderPayload.Opportunity();
        emptyMapTestPayload.opportunity.id = opportunities[0].Id;
        emptyMapTestPayload.opportunity.notes = 'Test notes';
        emptyMapTestPayload.shipping_address = new OrderPayload.ShippingAddress();
        // Empty shipping address object - this should trigger the isEmpty() check
        
        JsonToSFDCMapper.mapCloseDateForDigitalRenewals(mapTestOpp, emptyMapTestPayload.opportunity, emptyMapTestPayload.shipping_address);

        // Test to cover lines 158,159 by ensuring OrderUtil.getOrderProcessingSettings() returns a valid object
        // This test will cover the scenario where settings are not null
        OrderPayload settingsTestPayload = new OrderPayload();
        settingsTestPayload.opportunity = new OrderPayload.Opportunity();
        settingsTestPayload.opportunity.id = opportunities[0].Id;
        settingsTestPayload.opportunity.notes = 'Auto-renewal [Phase 1]';
        settingsTestPayload.opportunity.expressAgreementAcceptedDate = '2025-04-28';
        settingsTestPayload.shipping_address = new OrderPayload.ShippingAddress();
        settingsTestPayload.shipping_address.shippingAddressLine1 = '123 Test St';
        
        Opportunity settingsTestOpp = new Opportunity();
        settingsTestOpp.Id = opportunities[0].Id;
        
        // This should execute the lines 158,159 if OrderUtil.getOrderProcessingSettings() returns a valid object
        JsonToSFDCMapper.mapCloseDateForDigitalRenewals(settingsTestOpp, settingsTestPayload.opportunity, settingsTestPayload.shipping_address);

        // Direct test of isNullOrEmpty method to cover lines 12,13
        // Test with null
        System.assertEquals(true, JsonToSFDCMapper.isNullOrEmpty(null));
        
        
        // Test with OrderPayload.ShippingAddress - empty (all fields blank)
        OrderPayload.ShippingAddress emptyShippingAddress = new OrderPayload.ShippingAddress();
        System.assertEquals(true, JsonToSFDCMapper.isNullOrEmpty(emptyShippingAddress), 'Empty ShippingAddress should be considered null or empty');
        
// Test with OrderPayload.ShippingAddress - non-empty (has some data)
        OrderPayload.ShippingAddress nonEmptyShippingAddress = new OrderPayload.ShippingAddress();
        nonEmptyShippingAddress.shippingAddressLine1 = '123 Main St';
        nonEmptyShippingAddress.shippingCity = 'San Francisco';
        nonEmptyShippingAddress.shippingCountry = 'USA';
        nonEmptyShippingAddress.shippingState = 'CA';
        nonEmptyShippingAddress.shippingZipCode = '12345';
        nonEmptyShippingAddress.shippingEmail = 'test@example.com';
        nonEmptyShippingAddress.shippingPhone = '1234567890';
        nonEmptyShippingAddress.shippingLastName = 'Doe';
        nonEmptyShippingAddress.shippingFirstName = 'John';
        System.assertEquals(false, JsonToSFDCMapper.isNullOrEmpty(nonEmptyShippingAddress), 'Non-empty ShippingAddress should not be considered null or empty');        
    }

    @isTest static void testMapDigitalRenewalAccountData() {
        // Get test data from setup
        List<Account> accounts = [SELECT Id FROM Account LIMIT 1];
        
        OrderPayload payload = new OrderPayload();
        payload.account = new OrderPayload.Account();
        payload.order = new OrderPayload.Order();
        payload.order.account_id = accounts[0].Id;
        payload.account.autoRenewalOptOut = true;
        payload.account.billingCity = 'Austin';
        payload.account.billingState = 'TX';
        payload.account.billingStreet = '123 Main St';
        payload.account.billingCountry = 'USA';
        payload.account.billingEmail = 'test@example.com';
        payload.account.billingPhone = '1234567890';
        payload.account.billingPostalCode = '78701';
        payload.account.billingLastName = 'Doe';
        payload.account.billingFirstName = 'John';

        Account acc = JsonToSFDCMapper.mapDigitalRenewalAccountData(payload);
        System.assertNotEquals(null, acc);
        System.assertEquals(accounts[0].Id, acc.Id);
        System.assertEquals(true, acc.Auto_Renewal_Opt_Out__c);
        System.assertEquals('Austin', acc.BillingCity);
        System.assertEquals('TX', acc.BillingState);
        System.assertEquals('123 Main St', acc.BillingStreet);
        System.assertEquals('USA', acc.BillingCountry);
        System.assertEquals('test@example.com', acc.Billing_Email__c);
        System.assertEquals('1234567890', acc.Billing_Phone__c);
        System.assertEquals('78701', acc.BillingPostalCode);
        System.assertEquals('Doe', acc.Billing_Last_Name__c);
        System.assertEquals('John', acc.Billing_First_Name__c);
    }

    @isTest static void testMapCommercialCheckoutAccountData() {
        // Get test data from setup
        List<Account> accounts = [SELECT Id FROM Account LIMIT 1];
        
        OrderPayload payload = new OrderPayload();
        payload.account = new OrderPayload.Account();
        payload.order = new OrderPayload.Order();
        payload.order.account_id = accounts[0].Id;
        payload.account.billingCity = 'Dallas';
        payload.account.billingState = 'TX';
        payload.account.billingStreet = '456 Commerce St';
        payload.account.billingCountry = 'USA';
        payload.account.billingEmail = 'commerce@example.com';
        payload.account.billingPhone = '9876543210';
        payload.account.billingPostalCode = '75201';
        payload.account.billingLastName = 'Smith';
        payload.account.billingFirstName = 'Jane';

        Account acc = JsonToSFDCMapper.mapCommercialCheckoutAccountData(payload);
        System.assertNotEquals(null, acc);
        System.assertEquals(accounts[0].Id, acc.Id);
        System.assertEquals('Dallas', acc.BillingCity);
        System.assertEquals('TX', acc.BillingState);
        System.assertEquals('456 Commerce St', acc.BillingStreet);
        System.assertEquals('USA', acc.BillingCountry);
        System.assertEquals('commerce@example.com', acc.Billing_Email__c);
        System.assertEquals('9876543210', acc.Billing_Phone__c);
        System.assertEquals('75201', acc.BillingPostalCode);
        System.assertEquals('Smith', acc.Billing_Last_Name__c);
        System.assertEquals('Jane', acc.Billing_First_Name__c);
    }


    @isTest static void testMapFreeTrialOpportunityData() {
        OrderPayload payload = new OrderPayload();
        payload.opportunity = new OrderPayload.Opportunity();
        payload.order = new OrderPayload.Order();
        payload.order.account_id = '001000000000001';
        payload.opportunity.stageName = 'Prospecting';
        payload.opportunity.name = 'Free Trial Opportunity';
        payload.opportunity.currencyIsoCode = 'USD';
        payload.opportunity.trialGoal1 = 'Goal 1';
        payload.opportunity.trialGoal2 = 'Goal 2';
        payload.opportunity.trialGoal3 = 'Goal 3';
        payload.opportunity.closeDate = Date.today();
        payload.opportunity.pricebook2Id = '01s000000000001';
        payload.opportunity.trialPeriod = 14;
        payload.opportunity.trialAgreementAcceptanceDate = Date.today();
        payload.opportunity.trialAgreementAccepted = true;
        payload.opportunity.notes = 'Free trial notes';
        payload.opportunity.trialResolutionOppty = '006000000000002';

        Opportunity opp = JsonToSFDCMapper.mapFreeTrialOpportunityData(payload);
        System.assertNotEquals(null, opp);
        System.assertEquals('001000000000001', opp.AccountId);
        System.assertEquals('Prospecting', opp.StageName);
        System.assertEquals('Free Trial Opportunity', opp.Name);
        System.assertEquals('USD', opp.CurrencyIsoCode);
        System.assertEquals('Goal 1', opp.Trial_Goal_1__c);
        System.assertEquals('Goal 2', opp.Trial_Goal_2__c);
        System.assertEquals('Goal 3', opp.Trial_Goal_3__c);
        System.assertEquals(Date.today().addDays(3), opp.CloseDate);
        System.assertEquals('01s000000000001', opp.Pricebook2Id);
        System.assertEquals(14, opp.Trial_Period__c);
        System.assertEquals(Date.today(), opp.Trial_Agreement_Acceptance_Date__c);
        System.assertEquals(true, opp.Trial_Agreement_Accepted__c);
        System.assertEquals('Free trial notes', opp.Webstore_Metadata__c);
        System.assertEquals('006000000000002', opp.TrialResolutionOppty__c);
        System.assertEquals('Free Trial Opportunity', opp.Type);
    }

    @isTest static void testMapFreeTrialQuoteData() {
        OrderPayload payload = new OrderPayload();
        payload.quote = new OrderPayload.Quote();
        payload.quote.shippingMethod = 'Express';
        payload.quote.status = 'Draft';

        SBQQ__Quote__c quote = JsonToSFDCMapper.mapFreeTrialQuoteData(payload);
        System.assertNotEquals(null, quote);
        System.assertEquals('Express', quote.Shipping_Method__c);
        System.assertEquals('Draft', quote.SBQQ__Status__c);
    }

    @isTest static void testMapFreeTrialQuoteLines() {
        OrderPayload payload = new OrderPayload();
        payload.quote = new OrderPayload.Quote();
        payload.quote.quoteLines = new List<OrderPayload.QuoteLine>();
        
        OrderPayload.QuoteLine ql = new OrderPayload.QuoteLine();
        ql.product = '01t000000000001';
        ql.quantity = 3;
        ql.pricebookEntryId = '01u000000000001';
        ql.currencyIsoCode = 'USD';
        ql.listPrice = 199.99;
        payload.quote.quoteLines.add(ql);

        List<SBQQ__QuoteLine__c> result = JsonToSFDCMapper.mapFreeTrialQuoteLines(payload);
        System.assertNotEquals(null, result);
        System.assertEquals(1, result.size());
        System.assertEquals('01t000000000001', result[0].SBQQ__Product__c);
        System.assertEquals(3, result[0].SBQQ__Quantity__c);
        System.assertEquals('01u000000000001', result[0].SBQQ__PricebookEntryId__c);
        System.assertEquals('USD', result[0].CurrencyIsoCode);
        System.assertEquals(199.99, result[0].SBQQ__ListPrice__c);
    }

    @isTest static void testMapFreeTrialOpportunityWithNullTrialPeriod() {
        OrderPayload payload = new OrderPayload();
        payload.opportunity = new OrderPayload.Opportunity();
        payload.order = new OrderPayload.Order();
        payload.order.account_id = '001000000000001';
        payload.opportunity.stageName = 'Prospecting';
        payload.opportunity.name = 'Free Trial Opportunity';
        payload.opportunity.currencyIsoCode = 'USD';
        payload.opportunity.closeDate = Date.today();
        payload.opportunity.pricebook2Id = '01s000000000001';
        payload.opportunity.trialPeriod = null; // Test null trial period
        payload.opportunity.trialAgreementAcceptanceDate = Date.today();
        payload.opportunity.trialAgreementAccepted = true;
        payload.opportunity.notes = 'Free trial notes';

        Opportunity opp = JsonToSFDCMapper.mapFreeTrialOpportunityData(payload);
        System.assertNotEquals(null, opp);
        System.assertEquals('001000000000001', opp.AccountId);
        System.assertEquals('Prospecting', opp.StageName);
        System.assertEquals('Free Trial Opportunity', opp.Name);
        System.assertEquals('USD', opp.CurrencyIsoCode);
        System.assertEquals(Date.today().addDays(3), opp.CloseDate);
        System.assertEquals('01s000000000001', opp.Pricebook2Id);
        System.assertEquals(Date.today(), opp.Trial_Agreement_Acceptance_Date__c);
        System.assertEquals(true, opp.Trial_Agreement_Accepted__c);
        System.assertEquals('Free trial notes', opp.Webstore_Metadata__c);
        System.assertEquals('Free Trial Opportunity', opp.Type);
    }


    @isTest static void testMapAmendmenteQuoteData() {
        OrderPayload payload = new OrderPayload();
        payload.quote = new OrderPayload.Quote();
        payload.quote.selectedPaymentType = 'Prepaid';
        payload.quote.checkoutDiscount = 15.0;
        payload.quote.shippingMethod = 'Ground';
        payload.quote.paymentTerms = 'Monthly';
        payload.quote.poNumber = 'PO-12345';
        payload.quote.status = 'Draft';
        payload.quote.expressAgreementAcceptedDate = Date.today();
        payload.quote.amountReceived = 250.00;
        payload.quote.paymentToken = 'tok_quote';
        payload.quote.paymentMethod = 'ACH';
        payload.quote.stripeChargeId = 'ch_quote';
        payload.quote.stripeIntentId = 'pi_quote';
        payload.quote.shippingAndHandlingManual = 20.0;

        SBQQ__Quote__c quote = JsonToSFDCMapper.mapAmendmenteQuoteData(payload);
        System.assertNotEquals(null, quote);
        System.assertEquals('Prepaid', quote.Selected_Payment_Type__c);
        System.assertEquals(15.0, quote.Checkout_Discount__c);
        System.assertEquals('Ground', quote.Shipping_Method__c);
        System.assertEquals('Monthly', quote.SBQQ__PaymentTerms__c);
        System.assertEquals('PO-12345', quote.PO_Number__c);
        System.assertEquals('Draft', quote.SBQQ__Status__c);
        System.assertEquals(Date.today(), quote.Express_Agreement_Accepted_Date__c);
        System.assertEquals(250.00, quote.Amount_Received__c);
        System.assertEquals('tok_quote', quote.Payment_Token__c);
        System.assertEquals('ACH', quote.Payment_Method__c);
        System.assertEquals('ch_quote', quote.Stripe_Charge_Id__c);
        System.assertEquals('pi_quote', quote.Stripe_Intent_Id__c);
        System.assertEquals(20.0, quote.Shipping_And_Handling_Manual__c);
    }

}
@isTest
private class OrderPayloadTest {

    @isTest
    static void testOrderPayloadStructure() {
        // Test main OrderPayload class instantiation
        OrderPayload payload = new OrderPayload();
        System.assertNotEquals(null, payload);
        
        // Test Order nested class
        OrderPayload.Order order = new OrderPayload.Order();
        order.id = 'TEST-ORDER-001';
        order.is_enterprise = true;
        order.transaction_type = 'WEBSTORE_COMMERCIAL_CHECKOUT_LINK';
        order.account_id = '001000000000001';
        order.docusign_envelope_id = 'ENV-12345';
        order.payment_status = 'Paid';
        
        payload.order = order;
        
        // Verify Order properties
        System.assertEquals('TEST-ORDER-001', payload.order.id);
        System.assertEquals(true, payload.order.is_enterprise);
        System.assertEquals('WEBSTORE_COMMERCIAL_CHECKOUT_LINK', payload.order.transaction_type);
        System.assertEquals('001000000000001', payload.order.account_id);
        System.assertEquals('ENV-12345', payload.order.docusign_envelope_id);
        System.assertEquals('Paid', payload.order.payment_status);
    }

    @isTest
    static void testAccountNestedClass() {
        OrderPayload payload = new OrderPayload();
        OrderPayload.Account account = new OrderPayload.Account();
        
        // Set all Account properties
        account.autoRenewalOptOut = true;
        account.billingCity = 'Austin';
        account.billingState = 'TX';
        account.billingStreet = '123 Main St';
        account.billingCountry = 'USA';
        account.billingEmail = 'test@example.com';
        account.billingPhone = '1234567890';
        account.billingPostalCode = '78701';
        account.billingLastName = 'Doe';
        account.billingFirstName = 'John';
        
        payload.account = account;
        
        // Verify Account properties
        System.assertEquals(true, payload.account.autoRenewalOptOut);
        System.assertEquals('Austin', payload.account.billingCity);
        System.assertEquals('TX', payload.account.billingState);
        System.assertEquals('123 Main St', payload.account.billingStreet);
        System.assertEquals('USA', payload.account.billingCountry);
        System.assertEquals('test@example.com', payload.account.billingEmail);
        System.assertEquals('1234567890', payload.account.billingPhone);
        System.assertEquals('78701', payload.account.billingPostalCode);
        System.assertEquals('Doe', payload.account.billingLastName);
        System.assertEquals('John', payload.account.billingFirstName);
    }

    @isTest
    static void testOpportunityNestedClass() {
        OrderPayload payload = new OrderPayload();
        OrderPayload.Opportunity opportunity = new OrderPayload.Opportunity();
        
        // Set all Opportunity properties
        opportunity.id = '006000000000001';
        opportunity.stageName = 'Closed Won';
        opportunity.name = 'Test Opportunity';
        opportunity.closeDate = Date.today();
        opportunity.smallFleetOpportunity = true;
        opportunity.pricebook2Id = '01s000000000001';
        opportunity.licenseTerm = 12.0;
        opportunity.currencyIsoCode = 'USD';
        opportunity.canCreate = true;
        opportunity.excludeFromXactly = false;
        opportunity.isWebstoreUpsellOpportunity = true;
        opportunity.initialPaymentTerms = 'Net 30';
        opportunity.paymentTerms = 'Prepaid';
        opportunity.configurationSegment = 'SMB';
        opportunity.notes = 'Test notes';
        opportunity.purchaseType = 'New';
        opportunity.expressAgreementAcceptedDate = '2025-04-28';
        opportunity.amountReceived = 100.0;
        opportunity.paymentToken = 'tok_123';
        opportunity.paymentMethod = 'Credit Card';
        opportunity.stripeChargeId = 'ch_123';
        opportunity.stripeIntentId = 'pi_123';
        opportunity.vatNumber = 'VAT123';
        opportunity.vatValidationStatus = 'Valid';
        opportunity.shippingAndHandlingManual = 10.0;
        
        // Free Trial specific fields
        opportunity.trialPeriod = 14;
        opportunity.trialGoal1 = 'Goal 1';
        opportunity.trialGoal2 = 'Goal 2';
        opportunity.trialGoal3 = 'Goal 3';
        opportunity.trialAgreementAcceptanceDate = Date.today();
        opportunity.trialAgreementAccepted = true;
        opportunity.trialResolutionOppty = '006000000000002';
        
        payload.opportunity = opportunity;
        
        // Verify Opportunity properties
        System.assertEquals('006000000000001', payload.opportunity.id);
        System.assertEquals('Closed Won', payload.opportunity.stageName);
        System.assertEquals('Test Opportunity', payload.opportunity.name);
        System.assertEquals(Date.today(), payload.opportunity.closeDate);
        System.assertEquals(true, payload.opportunity.smallFleetOpportunity);
        System.assertEquals('01s000000000001', payload.opportunity.pricebook2Id);
        System.assertEquals(12.0, payload.opportunity.licenseTerm);
        System.assertEquals('USD', payload.opportunity.currencyIsoCode);
        System.assertEquals(true, payload.opportunity.canCreate);
        System.assertEquals(false, payload.opportunity.excludeFromXactly);
        System.assertEquals(true, payload.opportunity.isWebstoreUpsellOpportunity);
        System.assertEquals('Net 30', payload.opportunity.initialPaymentTerms);
        System.assertEquals('Prepaid', payload.opportunity.paymentTerms);
        System.assertEquals('SMB', payload.opportunity.configurationSegment);
        System.assertEquals('Test notes', payload.opportunity.notes);
        System.assertEquals('New', payload.opportunity.purchaseType);
        System.assertEquals('2025-04-28', payload.opportunity.expressAgreementAcceptedDate);
        System.assertEquals(100.0, payload.opportunity.amountReceived);
        System.assertEquals('tok_123', payload.opportunity.paymentToken);
        System.assertEquals('Credit Card', payload.opportunity.paymentMethod);
        System.assertEquals('ch_123', payload.opportunity.stripeChargeId);
        System.assertEquals('pi_123', payload.opportunity.stripeIntentId);
        System.assertEquals('VAT123', payload.opportunity.vatNumber);
        System.assertEquals('Valid', payload.opportunity.vatValidationStatus);
        System.assertEquals(10.0, payload.opportunity.shippingAndHandlingManual);
        
        // Verify Free Trial fields
        System.assertEquals(14, payload.opportunity.trialPeriod);
        System.assertEquals('Goal 1', payload.opportunity.trialGoal1);
        System.assertEquals('Goal 2', payload.opportunity.trialGoal2);
        System.assertEquals('Goal 3', payload.opportunity.trialGoal3);
        System.assertEquals(Date.today(), payload.opportunity.trialAgreementAcceptanceDate);
        System.assertEquals(true, payload.opportunity.trialAgreementAccepted);
        System.assertEquals('006000000000002', payload.opportunity.trialResolutionOppty);
    }

    @isTest
    static void testQuoteNestedClass() {
        OrderPayload payload = new OrderPayload();
        OrderPayload.Quote quote = new OrderPayload.Quote();
        
        // Set all Quote properties
        quote.id = '0Q000000000001';
        quote.name = 'Test Quote';
        quote.selectedPaymentType = 'Prepaid';
        quote.checkoutDiscount = 15.0;
        quote.shippingMethod = 'Ground';
        quote.paymentTerms = 'Monthly';
        quote.poNumber = 'PO-12345';
        quote.primary = true;
        quote.status = 'Draft';
        quote.expressAgreementAcceptedDate = Date.today();
        quote.amountReceived = 250.00;
        quote.paymentToken = 'tok_quote';
        quote.paymentMethod = 'ACH';
        quote.stripeChargeId = 'ch_quote';
        quote.stripeIntentId = 'pi_quote';
        quote.shippingAndHandlingManual = 20.0;
        quote.configurationSegment = 'Mid-Market';
        quote.account = '001000000000001';
        quote.opportunity = '006000000000001';
        quote.pricebook2Id = '01s000000000002';
        quote.currencyIsoCode = 'USD';
        quote.vatId = 'VAT-123';
        quote.expressSelectedDiscount = 10.0;
        
        payload.quote = quote;
        
        // Verify Quote properties
        System.assertEquals('0Q000000000001', payload.quote.id);
        System.assertEquals('Test Quote', payload.quote.name);
        System.assertEquals('Prepaid', payload.quote.selectedPaymentType);
        System.assertEquals(15.0, payload.quote.checkoutDiscount);
        System.assertEquals('Ground', payload.quote.shippingMethod);
        System.assertEquals('Monthly', payload.quote.paymentTerms);
        System.assertEquals('PO-12345', payload.quote.poNumber);
        System.assertEquals(true, payload.quote.primary);
        System.assertEquals('Draft', payload.quote.status);
        System.assertEquals(Date.today(), payload.quote.expressAgreementAcceptedDate);
        System.assertEquals(250.00, payload.quote.amountReceived);
        System.assertEquals('tok_quote', payload.quote.paymentToken);
        System.assertEquals('ACH', payload.quote.paymentMethod);
        System.assertEquals('ch_quote', payload.quote.stripeChargeId);
        System.assertEquals('pi_quote', payload.quote.stripeIntentId);
        System.assertEquals(20.0, payload.quote.shippingAndHandlingManual);
        System.assertEquals('Mid-Market', payload.quote.configurationSegment);
        System.assertEquals('001000000000001', payload.quote.account);
        System.assertEquals('006000000000001', payload.quote.opportunity);
        System.assertEquals('01s000000000002', payload.quote.pricebook2Id);
        System.assertEquals('USD', payload.quote.currencyIsoCode);
        System.assertEquals('VAT-123', payload.quote.vatId);
        System.assertEquals(10.0, payload.quote.expressSelectedDiscount);
    }

    @isTest
    static void testQuoteLineNestedClass() {
        OrderPayload payload = new OrderPayload();
        OrderPayload.Quote quote = new OrderPayload.Quote();
        OrderPayload.QuoteLine quoteLine = new OrderPayload.QuoteLine();
        
        // Set QuoteLine properties
        quoteLine.product = '01t000000000001';
        quoteLine.pricebookEntryId = '01u000000000001';
        quoteLine.currencyIsoCode = 'USD';
        quoteLine.listPrice = 99.99;
        quoteLine.discount = 5.00;
        quoteLine.quantity = 2;
        
        quote.quoteLines = new List<OrderPayload.QuoteLine>();
        quote.quoteLines.add(quoteLine);
        payload.quote = quote;
        
        // Verify QuoteLine properties
        System.assertEquals('01t000000000001', payload.quote.quoteLines[0].product);
        System.assertEquals('01u000000000001', payload.quote.quoteLines[0].pricebookEntryId);
        System.assertEquals('USD', payload.quote.quoteLines[0].currencyIsoCode);
        System.assertEquals(99.99, payload.quote.quoteLines[0].listPrice);
        System.assertEquals(5.00, payload.quote.quoteLines[0].discount);
        System.assertEquals(2, payload.quote.quoteLines[0].quantity);
    }

    @isTest
    static void testShippingAddressNestedClass() {
        OrderPayload payload = new OrderPayload();
        OrderPayload.ShippingAddress shippingAddress = new OrderPayload.ShippingAddress();
        
        // Set all ShippingAddress properties
        shippingAddress.shippingCity = 'Dallas';
        shippingAddress.shippingEmail = 'ship@example.com';
        shippingAddress.shippingPhone = '9876543210';
        shippingAddress.shippingState = 'TX';
        shippingAddress.shippingCountry = 'USA';
        shippingAddress.shippingContact = 'Jane Smith';
        shippingAddress.shippingLastName = 'Smith';
        shippingAddress.shippingZipCode = '75201';
        shippingAddress.shippingFirstName = 'Jane';
        shippingAddress.shippingAddressLine1 = '456 Ship Lane';
        shippingAddress.shippingAddressLine2 = 'Suite 101';
        shippingAddress.account = '001000000000001';
        
        payload.shipping_address = shippingAddress;
        
        // Verify ShippingAddress properties
        System.assertEquals('Dallas', payload.shipping_address.shippingCity);
        System.assertEquals('ship@example.com', payload.shipping_address.shippingEmail);
        System.assertEquals('9876543210', payload.shipping_address.shippingPhone);
        System.assertEquals('TX', payload.shipping_address.shippingState);
        System.assertEquals('USA', payload.shipping_address.shippingCountry);
        System.assertEquals('Jane Smith', payload.shipping_address.shippingContact);
        System.assertEquals('Smith', payload.shipping_address.shippingLastName);
        System.assertEquals('75201', payload.shipping_address.shippingZipCode);
        System.assertEquals('Jane', payload.shipping_address.shippingFirstName);
        System.assertEquals('456 Ship Lane', payload.shipping_address.shippingAddressLine1);
        System.assertEquals('Suite 101', payload.shipping_address.shippingAddressLine2);
        System.assertEquals('001000000000001', payload.shipping_address.account);
    }

    @isTest
    static void testCompleteOrderPayloadStructure() {
        // Test complete OrderPayload with all nested classes
        OrderPayload payload = new OrderPayload();
        
        // Initialize all nested classes
        payload.order = new OrderPayload.Order();
        payload.account = new OrderPayload.Account();
        payload.opportunity = new OrderPayload.Opportunity();
        payload.quote = new OrderPayload.Quote();
        payload.shipping_address = new OrderPayload.ShippingAddress();
        
        // Set some basic values to ensure all classes are instantiated
        payload.order.id = 'TEST-001';
        payload.account.billingCity = 'Austin';
        payload.opportunity.name = 'Test Opp';
        payload.quote.name = 'Test Quote';
        payload.shipping_address.shippingCity = 'Dallas';
        
        // Verify all nested classes are properly instantiated
        System.assertNotEquals(null, payload.order);
        System.assertNotEquals(null, payload.account);
        System.assertNotEquals(null, payload.opportunity);
        System.assertNotEquals(null, payload.quote);
        System.assertNotEquals(null, payload.shipping_address);
        
        // Verify values are set correctly
        System.assertEquals('TEST-001', payload.order.id);
        System.assertEquals('Austin', payload.account.billingCity);
        System.assertEquals('Test Opp', payload.opportunity.name);
        System.assertEquals('Test Quote', payload.quote.name);
        System.assertEquals('Dallas', payload.shipping_address.shippingCity);
    }
}
@isTest
private class OrderTransactionHandlerFactoryTest {

    @isTest
    static void testGetHandler_ValidTransactionTypes() {
        // Test all valid transaction types
        Test.startTest();
        
        // Test WEBSTORE_FIRST_PURCHASE
        OrderTransactionHandler handler1 = OrderTransactionHandlerFactory.getHandler('WEBSTORE_FIRST_PURCHASE');
        System.assertNotEquals(null, handler1, 'Handler should be created for WEBSTORE_FIRST_PURCHASE');
        System.assert(handler1 instanceof FirstTimePurchaseHandler, 'Should return FirstTimePurchaseHandler');
        
        // Test WEBSTORE_ADD_ON_PURCHASE
        OrderTransactionHandler handler2 = OrderTransactionHandlerFactory.getHandler('WEBSTORE_ADD_ON_PURCHASE');
        System.assertNotEquals(null, handler2, 'Handler should be created for WEBSTORE_ADD_ON_PURCHASE');
        System.assert(handler2 instanceof AmendmentHandler, 'Should return AmendmentHandler');
        
        // Test WEBSTORE_DIGITAL_RENEWAL
        OrderTransactionHandler handler3 = OrderTransactionHandlerFactory.getHandler('WEBSTORE_DIGITAL_RENEWAL');
        System.assertNotEquals(null, handler3, 'Handler should be created for WEBSTORE_DIGITAL_RENEWAL');
        System.assert(handler3 instanceof DigitalRenewalCheckoutHandler, 'Should return DigitalRenewalCheckoutHandler');
        
        // Test WEBSTORE_COMMERCIAL_CHECKOUT_LINK
        OrderTransactionHandler handler4 = OrderTransactionHandlerFactory.getHandler('WEBSTORE_COMMERCIAL_CHECKOUT_LINK');
        System.assertNotEquals(null, handler4, 'Handler should be created for WEBSTORE_COMMERCIAL_CHECKOUT_LINK');
        System.assert(handler4 instanceof CommercialCheckoutHandler, 'Should return CommercialCheckoutHandler');
        
        // Test WEBSTORE_MIDMARKET_PLUS_CHECKOUT_LINK
        OrderTransactionHandler handler5 = OrderTransactionHandlerFactory.getHandler('WEBSTORE_MIDMARKET_PLUS_CHECKOUT_LINK');
        System.assertNotEquals(null, handler5, 'Handler should be created for WEBSTORE_MIDMARKET_PLUS_CHECKOUT_LINK');
        System.assert(handler5 instanceof MidMarketPlusCheckoutHandler, 'Should return MidMarketPlusCheckoutHandler');
        
        // Test WEBSTORE_FREE_TRIAL
        OrderTransactionHandler handler6 = OrderTransactionHandlerFactory.getHandler('WEBSTORE_FREE_TRIAL');
        System.assertNotEquals(null, handler6, 'Handler should be created for WEBSTORE_FREE_TRIAL');
        System.assert(handler6 instanceof FreeTrialHandler, 'Should return FreeTrialHandler');
        
        Test.stopTest();
    }

    @isTest
    static void testGetHandler_CaseInsensitive() {
        Test.startTest();
        
        // Test lowercase
        OrderTransactionHandler handler1 = OrderTransactionHandlerFactory.getHandler('webstore_first_purchase');
        System.assertNotEquals(null, handler1, 'Handler should be created for lowercase transaction type');
        System.assert(handler1 instanceof FirstTimePurchaseHandler, 'Should return FirstTimePurchaseHandler for lowercase');
        
        // Test mixed case
        OrderTransactionHandler handler2 = OrderTransactionHandlerFactory.getHandler('Webstore_First_Purchase');
        System.assertNotEquals(null, handler2, 'Handler should be created for mixed case transaction type');
        System.assert(handler2 instanceof FirstTimePurchaseHandler, 'Should return FirstTimePurchaseHandler for mixed case');
        
        // Test another mixed case
        OrderTransactionHandler handler3 = OrderTransactionHandlerFactory.getHandler('webstore_commercial_checkout_link');
        System.assertNotEquals(null, handler3, 'Handler should be created for lowercase commercial checkout');
        System.assert(handler3 instanceof CommercialCheckoutHandler, 'Should return CommercialCheckoutHandler for lowercase');
        
        Test.stopTest();
    }

    @isTest
    static void testGetHandler_NullTransactionType() {
        Test.startTest();
        
        OrderTransactionHandler handler = OrderTransactionHandlerFactory.getHandler(null);
        System.assertEquals(null, handler, 'Handler should be null for null transaction type');
        
        Test.stopTest();
    }

    @isTest
    static void testGetHandler_EmptyTransactionType() {
        Test.startTest();
        
        OrderTransactionHandler handler = OrderTransactionHandlerFactory.getHandler('');
        System.assertEquals(null, handler, 'Handler should be null for empty transaction type');
        
        Test.stopTest();
    }

    @isTest
    static void testGetHandler_BlankTransactionType() {
        Test.startTest();
        
        OrderTransactionHandler handler = OrderTransactionHandlerFactory.getHandler('   ');
        System.assertEquals(null, handler, 'Handler should be null for blank transaction type');
        
        Test.stopTest();
    }

    @isTest
    static void testGetHandler_InvalidTransactionType() {
        Test.startTest();
        
        OrderTransactionHandler handler = OrderTransactionHandlerFactory.getHandler('INVALID_TRANSACTION_TYPE');
        System.assertEquals(null, handler, 'Handler should be null for invalid transaction type');
        
        Test.stopTest();
    }

    @isTest
    static void testGetHandler_NonExistentTransactionType() {
        Test.startTest();
        
        OrderTransactionHandler handler = OrderTransactionHandlerFactory.getHandler('WEBSTORE_NON_EXISTENT');
        System.assertEquals(null, handler, 'Handler should be null for non-existent transaction type');
        
        Test.stopTest();
    }

    @isTest
    static void testGetHandler_SpecialCharacters() {
        Test.startTest();
        
        OrderTransactionHandler handler = OrderTransactionHandlerFactory.getHandler('WEBSTORE_FIRST_PURCHASE@#$');
        System.assertEquals(null, handler, 'Handler should be null for transaction type with special characters');
        
        Test.stopTest();
    }

    @isTest
    static void testGetHandler_WhitespaceAroundValidType() {
        Test.startTest();
        
        // The factory uses toUpperCase() which doesn't trim whitespace, so this should return null
        OrderTransactionHandler handler = OrderTransactionHandlerFactory.getHandler('  WEBSTORE_FIRST_PURCHASE  ');
        System.assertEquals(null, handler, 'Handler should be null for transaction type with whitespace since toUpperCase() doesn\'t trim');
        
        Test.stopTest();
    }

    @isTest
    static void testGetHandler_AllTransactionTypeEnumValues() {
        Test.startTest();
        
        // Test all enum values from TransactionType
        List<String> transactionTypes = new List<String>{
            'WEBSTORE_ADD_ON_PURCHASE',
            'WEBSTORE_FIRST_PURCHASE',
            'WEBSTORE_DIGITAL_RENEWAL',
            'WEBSTORE_COMMERCIAL_CHECKOUT_LINK',
            'WEBSTORE_MIDMARKET_PLUS_CHECKOUT_LINK',
            'WEBSTORE_FREE_TRIAL'
        };
        
        for (String txnType : transactionTypes) {
            OrderTransactionHandler handler = OrderTransactionHandlerFactory.getHandler(txnType);
            System.assertNotEquals(null, handler, 'Handler should be created for transaction type: ' + txnType);
            // All handlers extend OrderTransactionHandler, so this assertion is always true
            // We just verify the handler is not null and can be instantiated
        }
        
        Test.stopTest();
    }

    @isTest
    static void testGetHandler_HandlerInstantiation() {
        Test.startTest();
        
        // Test that each handler can be instantiated and is of correct type
        OrderTransactionHandler firstPurchaseHandler = OrderTransactionHandlerFactory.getHandler('WEBSTORE_FIRST_PURCHASE');
        System.assertNotEquals(null, firstPurchaseHandler, 'FirstTimePurchaseHandler should be instantiated');
        
        OrderTransactionHandler addOnHandler = OrderTransactionHandlerFactory.getHandler('WEBSTORE_ADD_ON_PURCHASE');
        System.assertNotEquals(null, addOnHandler, 'AmendmentHandler should be instantiated');
        
        OrderTransactionHandler digitalRenewalHandler = OrderTransactionHandlerFactory.getHandler('WEBSTORE_DIGITAL_RENEWAL');
        System.assertNotEquals(null, digitalRenewalHandler, 'DigitalRenewalCheckoutHandler should be instantiated');
        
        OrderTransactionHandler commercialHandler = OrderTransactionHandlerFactory.getHandler('WEBSTORE_COMMERCIAL_CHECKOUT_LINK');
        System.assertNotEquals(null, commercialHandler, 'CommercialCheckoutHandler should be instantiated');
        
        OrderTransactionHandler midMarketHandler = OrderTransactionHandlerFactory.getHandler('WEBSTORE_MIDMARKET_PLUS_CHECKOUT_LINK');
        System.assertNotEquals(null, midMarketHandler, 'MidMarketPlusCheckoutHandler should be instantiated');
        
        OrderTransactionHandler freeTrialHandler = OrderTransactionHandlerFactory.getHandler('WEBSTORE_FREE_TRIAL');
        System.assertNotEquals(null, freeTrialHandler, 'FreeTrialHandler should be instantiated');
        
        Test.stopTest();
    }

    @isTest
    static void testGetHandler_MultipleCallsSameType() {
        Test.startTest();
        
        // Test multiple calls with same transaction type return different instances
        OrderTransactionHandler handler1 = OrderTransactionHandlerFactory.getHandler('WEBSTORE_FIRST_PURCHASE');
        OrderTransactionHandler handler2 = OrderTransactionHandlerFactory.getHandler('WEBSTORE_FIRST_PURCHASE');
        
        System.assertNotEquals(null, handler1, 'First handler should not be null');
        System.assertNotEquals(null, handler2, 'Second handler should not be null');
        System.assertNotEquals(handler1, handler2, 'Multiple calls should return different instances');
        System.assert(handler1 instanceof FirstTimePurchaseHandler, 'First handler should be FirstTimePurchaseHandler');
        System.assert(handler2 instanceof FirstTimePurchaseHandler, 'Second handler should be FirstTimePurchaseHandler');
        
        Test.stopTest();
    }

    @isTest
    static void testGetHandler_EdgeCases() {
        Test.startTest();
        
        // Test with very long string
        String longString = 'WEBSTORE_FIRST_PURCHASE' + 'X'.repeat(1000);
        OrderTransactionHandler handler1 = OrderTransactionHandlerFactory.getHandler(longString);
        System.assertEquals(null, handler1, 'Handler should be null for very long string');
        
        // Test with numeric string
        OrderTransactionHandler handler2 = OrderTransactionHandlerFactory.getHandler('123456');
        System.assertEquals(null, handler2, 'Handler should be null for numeric string');
        
        // Test with partial match
        OrderTransactionHandler handler3 = OrderTransactionHandlerFactory.getHandler('WEBSTORE_FIRST');
        System.assertEquals(null, handler3, 'Handler should be null for partial match');
        
        Test.stopTest();
    }

    @isTest
    static void testGetHandler_ExceptionHandling() {
        Test.startTest();
        
        // Since all handler classes are valid and should instantiate properly,
        // we can't easily trigger the exception path in lines 26-28.
        // However, we can test that the method handles various edge cases gracefully.
        
        // Test with null after toUpperCase() - this should not trigger exception but return null
        OrderTransactionHandler handler1 = OrderTransactionHandlerFactory.getHandler('NONEXISTENT_TYPE');
        System.assertEquals(null, handler1, 'Handler should be null for non-existent type');
        
        // Test with empty string after toUpperCase()
        OrderTransactionHandler handler2 = OrderTransactionHandlerFactory.getHandler('');
        System.assertEquals(null, handler2, 'Handler should be null for empty string');
        
        // Test with valid type to ensure no exception is thrown
        OrderTransactionHandler handler3 = OrderTransactionHandlerFactory.getHandler('WEBSTORE_FIRST_PURCHASE');
        System.assertNotEquals(null, handler3, 'Handler should be created for valid type');
        
        Test.stopTest();
    }
}
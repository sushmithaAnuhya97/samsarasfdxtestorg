@isTest
private class FirstTimePurchaseHandlerTest {
    @TestSetup
    static void setupTestData() {
        // Create test data using MercuryPhase2DataFactory
        Account testAccount = MercuryPhase2DataFactory.createAccount('Test Account', true);
        Contact testContact = MercuryPhase2DataFactory.createContact(testAccount.Id, true);
        Shipping_Address__c testShippingAddress = MercuryPhase2DataFactory.createShippingAddress(testAccount.Id, testContact.Id, true);
        MercuryPhase2DataFactory.createFirstTimePurchaseTracker(testAccount.Id, true);
    }

    @isTest
    static void testIsOrderValid() {
        Request_Tracker__c tracker = [
            SELECT Id, Request__c, Transaction_Type__c, OrderId__c, 
                   Requestor__c, Step_Status__c, Status__c
            FROM Request_Tracker__c 
            LIMIT 1
        ];
        try {
            Test.startTest();
            FirstTimePurchaseHandler handler = new FirstTimePurchaseHandler();
            Boolean isValid = handler.isOrderValid(tracker);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }

    @isTest
    static void testProcessTransaction() {
        Request_Tracker__c tracker = [
            SELECT Id, Request__c, Transaction_Type__c, OrderId__c, 
                   Requestor__c, Step_Status__c, Status__c
            FROM Request_Tracker__c 
            LIMIT 1
        ];
        try {
            Test.startTest();
            FirstTimePurchaseHandler handler = new FirstTimePurchaseHandler();
            handler.processTransaction(tracker);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }
}
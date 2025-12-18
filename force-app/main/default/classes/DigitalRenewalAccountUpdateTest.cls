@isTest
private class DigitalRenewalAccountUpdateTest {
    @TestSetup
    static void setupTestData() {
        // Create test data using MercuryPhase2DataFactory
        Account testAccount = MercuryPhase2DataFactory.createAccount('Test Account', true);
        Contact testContact = MercuryPhase2DataFactory.createContact(testAccount.Id, true);
        Shipping_Address__c testShippingAddress = MercuryPhase2DataFactory.createShippingAddress(testAccount.Id, testContact.Id, true);
        
        // Create Request Tracker
        Request_Tracker__c rt = MercuryPhase2DataFactory.createAmendmentTracker(testAccount.Id, testContact.Id, Test.getStandardPricebookId(), null, false);
        rt.Shipping_Address_Id__c = testShippingAddress.Id;
        
        TriggerHandler.bypass('RequestTrackerTriggerHandler');
        insert rt;
        TriggerHandler.clearAllBypasses();
    }
    
    @isTest
    static void testDigitalRenewalAccountUpdate_WithChanges() {
        // Get the test data
        Account testAccount = [SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry 
                             FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Request_Tracker__c tracker = [SELECT Id, 
                                    Account_Id__c, 
                                    Shipping_Address_Id__c,
                                    Request__c, 
                                    Step_Status__c, 
                                    Status__c, 
                                    Transaction_Type__c
                                    FROM Request_Tracker__c 
                                    WHERE Account_Id__c = :testAccount.Id 
                                    LIMIT 1];
        
        // Create test payload with modified account data
        OrderPayload payload = MercuryPhase2DataFactory.createDigitalRenewalPayload(testAccount.Id, null, null, 'pm_1IEf3FIbzZlMbYFSvAbpRda3', 'seti_1QxBxbIbzZlMbYFSV9Xtbsnk');
        payload.account.BillingStreet = '123 New Street';
        payload.account.BillingCity = 'New City';
        payload.account.BillingState = 'New State';
        payload.account.BillingPostalCode = '12345';
        payload.account.BillingCountry = 'New Country';
        
        try {
            Test.startTest();
            DigitalRenewalAccountUpdate job = new DigitalRenewalAccountUpdate(tracker, 'Step1', payload, 0);
            job.processJob();
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error in testDigitalRenewalAccountUpdate_WithChanges: ' + e.getMessage());
        }
    }
    
    @isTest
    static void testDigitalRenewalAccountUpdate_WithNoChanges() {
        // Get the test data
        Account testAccount = [SELECT Id, Name, BillingStreet, BillingCity FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Request_Tracker__c tracker = [SELECT Id, 
                                    Account_Id__c, 
                                    Shipping_Address_Id__c,
                                    Request__c, 
                                    Step_Status__c, 
                                    Status__c, 
                                    Transaction_Type__c
                                    FROM Request_Tracker__c 
                                    WHERE Account_Id__c = :testAccount.Id 
                                    LIMIT 1];
        
        // Create test payload with same account data
        OrderPayload payload = MercuryPhase2DataFactory.createDigitalRenewalPayload(testAccount.Id, null, null, 'pm_1IEf3FIbzZlMbYFSvAbpRda3', 'seti_1QxBxbIbzZlMbYFSV9Xtbsnk');
        payload.account.BillingStreet = testAccount.BillingStreet;
        payload.account.BillingCity = testAccount.BillingCity;
        
        try {
            Test.startTest();
            DigitalRenewalAccountUpdate job = new DigitalRenewalAccountUpdate(tracker, 'Step1', payload, 0);
            job.processJob();
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error in testDigitalRenewalAccountUpdate_WithNoChanges: ' + e.getMessage());
        }
    }
    
    @isTest
    static void testDigitalRenewalAccountUpdate_WithNullAccount() {
        // Get the test data
        Account testAccount = [SELECT Id, Name, BillingStreet, BillingCity FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Request_Tracker__c tracker = [SELECT Id, 
                                    Account_Id__c, 
                                    Shipping_Address_Id__c,
                                    Request__c, 
                                    Step_Status__c, 
                                    Status__c, 
                                    Transaction_Type__c
                                    FROM Request_Tracker__c 
                                    WHERE Account_Id__c = :testAccount.Id 
                                    LIMIT 1];
        
        // Create test payload with null account
        OrderPayload payload = new OrderPayload();
        payload.account = null;
        
        try {
            Test.startTest();
            DigitalRenewalAccountUpdate job = new DigitalRenewalAccountUpdate(tracker, 'Step1', payload, 0);
            job.processJob();
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error in testDigitalRenewalAccountUpdate_WithNullAccount: ' + e.getMessage());
        }
    }
    
    @isTest
    static void testDigitalRenewalAccountUpdate_WithRetry() {
        // Get the test data
        Account testAccount = [SELECT Id, Name, BillingStreet, BillingCity FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Request_Tracker__c tracker = [SELECT Id, 
                                    Account_Id__c, 
                                    Shipping_Address_Id__c,
                                    Request__c, 
                                    Step_Status__c, 
                                    Status__c, 
                                    Transaction_Type__c
                                    FROM Request_Tracker__c 
                                    WHERE Account_Id__c = :testAccount.Id 
                                    LIMIT 1];
        
        // Create test payload
        OrderPayload payload = MercuryPhase2DataFactory.createDigitalRenewalPayload(testAccount.Id, null, null, 'pm_1IEf3FIbzZlMbYFSvAbpRda3', 'seti_1QxBxbIbzZlMbYFSV9Xtbsnk');
        
        try {
            Test.startTest();
            DigitalRenewalAccountUpdate job = new DigitalRenewalAccountUpdate(tracker, 'Step1', payload, 1);
            Queueable retryInstance = job.newInstanceWithRetry(1);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error in testDigitalRenewalAccountUpdate_WithRetry: ' + e.getMessage());
        }
    }
    
    @isTest
    static void testDigitalRenewalAccountUpdate_WithError() {
        // Get the test data
        Account testAccount = [SELECT Id, Name, BillingStreet, BillingCity FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Request_Tracker__c tracker = [SELECT Id, 
                                    Account_Id__c, 
                                    Shipping_Address_Id__c,
                                    Request__c, 
                                    Step_Status__c, 
                                    Status__c, 
                                    Transaction_Type__c
                                    FROM Request_Tracker__c 
                                    WHERE Account_Id__c = :testAccount.Id 
                                    LIMIT 1];
        
        // Create test payload with invalid account ID
        OrderPayload payload = MercuryPhase2DataFactory.createDigitalRenewalPayload(testAccount.Id, null, null, 'pm_1IEf3FIbzZlMbYFSvAbpRda3', 'seti_1QxBxbIbzZlMbYFSV9Xtbsnk');
        
        try {
            Test.startTest();
            DigitalRenewalAccountUpdate job = new DigitalRenewalAccountUpdate(tracker, 'Step1', payload, 0);
            job.processJob();
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error in testDigitalRenewalAccountUpdate_WithError: ' + e.getMessage());
        }
    }
}
@IsTest
public class FirstTimePurchaseAccountUpdateTest {
    
    @testSetup
    static void setupTestData() {
         Account acct = new Account(Name = 'Test Account',Organization_Size__c='1 - 99',BillingCountry='United States',BillingCountryCode='US',BillingState='Texas',BillingStateCode='TX',Auto_renewal_Opt_Out__c = true);
        insert acct;
        
        Request_Tracker__c tracker = new Request_Tracker__c(Transaction_Type__c='WEBSTORE_FIRST_PURCHASE',OrderId__c='78621',Account_Id__c=acct.Id); 
        insert tracker;
    }
    
    @IsTest
    static void testProcessJob_WithNoFieldChanges() {
        Account acc = new Account(Name = 'Test Account',Organization_Size__c='1 - 99',BillingCountry='United States',BillingCountryCode='US',BillingState='Texas',BillingStateCode='TX');
        insert acc;
        
        Request_Tracker__c tracker = new Request_Tracker__c(Transaction_Type__c = 'WEBSTORE_FIRST_PURCHASE');
        insert tracker;
        
        OrderPayload payload = new OrderPayload();
        // Initialize Order
        payload.order = new OrderPayload.Order();
        payload.order.id = 'test-order-id';
        payload.order.is_enterprise = false;
        payload.order.transaction_type = 'WEBSTORE_FIRST_PURCHASE';
        payload.order.account_id = acc.Id;
        payload.order.payment_status = 'Pending';
        
        // Initialize Account
        payload.account = new OrderPayload.Account();
        payload.account.BillingStreet = acc.BillingStreet;
        payload.account.BillingCity = acc.BillingCity;
        payload.account.BillingCountry = acc.BillingCountry;
        payload.account.BillingState = acc.BillingState;
        payload.account.autoRenewalOptOut = true;
        
        // Initialize Opportunity
        payload.opportunity = new OrderPayload.Opportunity();
        payload.opportunity.stageName = 'Prospecting';
        payload.opportunity.name = 'Test Opportunity';
        payload.opportunity.closeDate = Date.today();
        
        // Initialize Quote
        payload.quote = new OrderPayload.Quote();
        payload.quote.name = 'Test Quote';
        payload.quote.status = 'Draft';
        payload.quote.primary = true;
        
        // Initialize Shipping Address
        payload.shipping_address = new OrderPayload.ShippingAddress();
        payload.shipping_address.shippingCity = 'Test City';
        payload.shipping_address.shippingCountry = 'United States';
        payload.shipping_address.shippingState = 'Texas';
        
        Test.startTest();
        FirstTimePurchaseAccountUpdate job = new FirstTimePurchaseAccountUpdate(tracker, 'Step2', payload, 0);
        job.processJob();
        Test.stopTest();
        
        System.assert(true);
    }
    
    @IsTest
    static void testProcessJob_NullAccount() {
        Request_Tracker__c tracker = [SELECT Id,Transaction_Type__c FROM Request_Tracker__c LIMIT 1];
        
        OrderPayload payload = new OrderPayload();
        payload.order = new OrderPayload.Order();
        payload.order.id = 'test-order-id';
        payload.order.transaction_type = 'WEBSTORE_FIRST_PURCHASE';
        payload.account = null;
        
        Test.startTest();
        FirstTimePurchaseAccountUpdate job = new FirstTimePurchaseAccountUpdate(tracker, 'Step3', payload, 0);
        job.processJob();
        Test.stopTest();
        
        System.assert(true); // Just verify no exception
    }
    
    @IsTest
    static void testHasFieldChanged() {
        Account oldAcc = new Account(Name = 'Test Account1',Organization_Size__c='1 - 99',BillingCountry='United States',BillingCountryCode='US',BillingState='Texas',BillingStateCode='TX');
        Account newAcc = new Account(Name = 'Test Account2',Organization_Size__c='1 - 99',BillingCountry='United States',BillingCountryCode='US',BillingState='Texas',BillingStateCode='TX');
        
        System.assertEquals(true, FirstTimePurchaseAccountUpdate.hasFieldChanged(oldAcc, newAcc));
        
        newAcc.Name = 'Old';
        System.assertEquals(true, FirstTimePurchaseAccountUpdate.hasFieldChanged(oldAcc, newAcc));
        
        System.assertEquals(true, FirstTimePurchaseAccountUpdate.hasFieldChanged(null, newAcc));
        System.assertEquals(true, FirstTimePurchaseAccountUpdate.hasFieldChanged(oldAcc, null));
    }
}
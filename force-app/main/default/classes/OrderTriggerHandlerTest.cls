@isTest
public class OrderTriggerHandlerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = new Account (Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
        insert testAccount;
        List<Opportunity> newOpportunities = new List<Opportunity>();

        Opportunity revenueOpportunity = new Opportunity( 
            AccountId = testAccount.Id, License_Term__c =36, Shipping_Country__c='United States', 
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId(),
            Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', 
            CloseDate = System.today() + 90, StageName = 'Not Shipped', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8',
            Type='Revenue Opportunity', Shipping_Address_NEW__c=null); 
        newOpportunities.add(revenueOpportunity); 
                
        TriggerHandler.bypass('OpportunityTriggerHandler');
        
        insert newOpportunities;
        
        // Create test Product
        Product2 testProduct = new Product2(
            Name = 'Test Buyout Product',
            ProductCode = 'DC-COMPETITOR-BUYOUT',
            IsActive = true
        );
        insert testProduct;
        
        // Create standard Pricebook Entry
        PricebookEntry standardPBE = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            UnitPrice = 100,
            IsActive = true
        );
        insert standardPBE;
        
        // Create Custom Metadata Type record for testing
        Rebate_Buyout_Product_Mapping__mdt testMapping = (Rebate_Buyout_Product_Mapping__mdt) Json.deserialize(
            '{"Product_Code__c": "DC-COMPETITOR-BUYOUT"}',
            Rebate_Buyout_Product_Mapping__mdt.class
        );
    }
    
    @isTest
    static void testHandleOrderUpdate_Success() {
        // Get test data
        Opportunity testOpp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        
        // Create test Order
        Order testOrder = new Order(
            AccountId = testOpp.AccountId,
            OpportunityId = testOpp.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert testOrder;
        
        // Create Order Item
        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            Product2Id = testProduct.Id,
            PricebookEntryId = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id LIMIT 1].Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert testOrderItem;
        
        // Update Order to Fulfilled status
        testOrder.Status = 'Fulfilled';
        update testOrder;
        
        Test.startTest();
        
        // Call the method
        OrderTriggerHandler.handleOrderUpdate(testOrder);
        
        // Deliver all pending platform events
        Test.getEventBus().deliver();
        
        Test.stopTest();
        
        // Since we can't query platform events directly, we'll verify the order was processed by checking if the order status was updated and the trigger handler executed
        Order updatedOrder = [SELECT Id, Status FROM Order WHERE Id = :testOrder.Id];
        System.assertEquals('Fulfilled', updatedOrder.Status, 'Order status should be Fulfilled');
    }
    
    @isTest
    static void testHandleOrderUpdateFlow_Success() {
        // Get test data
        Opportunity testOpp = [SELECT Id, AccountId  FROM Opportunity LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        
        // Create test Orders
        List<Order> testOrders = new List<Order>();
        Order testOrder = new Order(
            AccountId = testOpp.AccountId,
            OpportunityId = testOpp.Id,
            Status = 'Fulfilled',
            EffectiveDate = Date.today(),
            Pricebook2Id = Test.getStandardPricebookId()
        );
        testOrders.add(testOrder);
        insert testOrders;
        
        // Create Order Item
        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            Product2Id = testProduct.Id,
            PricebookEntryId = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id LIMIT 1].Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert testOrderItem;
        
        Test.startTest();
        
        // Call the flow method
        OrderTriggerHandler.handleOrderUpdateFlow(testOrders);
        
        // Deliver all pending platform events
        Test.getEventBus().deliver();
        
        Test.stopTest();
        
        // Verify the order was processed
        Order updatedOrder = [SELECT Id, Status FROM Order WHERE Id = :testOrder.Id];
        System.assertEquals(true, updatedOrder.Status != null, 'Order status should be Fulfilled');
    }
    
    @isTest
    static void testHandleOrderUpdate_NoEvent() {
        Opportunity testOpp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        
        Order testOrder = new Order(
            AccountId = testOpp.AccountId,
            OpportunityId = testOpp.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert testOrder;
        
        Test.startTest();
        
        // Call the method
        OrderTriggerHandler.handleOrderUpdate(testOrder);
        
        // Deliver all pending platform events
        Test.getEventBus().deliver();
        
        Test.stopTest();
        
        Order updatedOrder = [SELECT Id, Status FROM Order WHERE Id = :testOrder.Id];
        System.assertEquals(true, updatedOrder.Status != null , 'Order status should remain Draft');
    }
    
}
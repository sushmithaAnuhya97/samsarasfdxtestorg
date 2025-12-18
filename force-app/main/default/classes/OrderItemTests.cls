/**************************************************************************************************
* Date      	 - Project#       - Developer/ Company    
* -------------------------------------------------------------------------------------------------
* 6 June 2025    - GTMS-27708     - Rajat Kundlas/ Accenture 
*/

@isTest
public class OrderItemTests {
    
    @testSetup
    static void setupTestData() {
        
        RecordType returnOrderRecordType = [
            SELECT Id FROM RecordType
            WHERE DeveloperName = 'Return_Order' AND SObjectType = 'Order'
            LIMIT 1
        ];
        
        Id pricebookId = Test.getStandardPricebookId();
        
        Account acc = TestFactory.initializeAccount('Test Account');
        insert acc;
        Order testOrder = new Order(
            Name = 'Test Order',
            Status = 'In Progress',
            Type = 'Remorse Refund',
            RecordTypeId = returnOrderRecordType.Id,
            EffectiveDate = System.today(),
            AccountId = acc.Id,
            Pricebook2Id = pricebookId
        );
        insert testOrder;
        
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
        
        List<OrderItem> orderItems = new List<OrderItem>{
            new OrderItem(
                OrderId = testOrder.Id,
                Quantity = 1,
                UnitPrice = 100,
                PricebookEntryId = pbe.Id,
                ns_integration_error__c = null,
                Netsuite_RMA_ID__c = null
            ),
                new OrderItem(
                    OrderId = testOrder.Id,
                    Quantity = 2,
                    UnitPrice = 50,
                    PricebookEntryId = pbe.Id,
                    ns_integration_error__c = null,
                    Netsuite_RMA_ID__c = null
                )
                };
                    insert orderItems;
    }
    
    @isTest
    static void testAfterUpdate_RMACompleted() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        List<OrderItem> itemsToUpdate = [
            SELECT Id, ns_integration_error__c, Netsuite_RMA_ID__c 
            FROM OrderItem WHERE OrderId = :testOrder.Id
        ];
        
        for (OrderItem item : itemsToUpdate) {
            item.Netsuite_RMA_ID__c = 'RMA12345';
        }
        
        Test.startTest();
        update itemsToUpdate;
        Test.stopTest();
        
        Order updatedOrder = [SELECT Status FROM Order WHERE Id = :testOrder.Id];
        System.assertEquals('Return Completed', updatedOrder.Status, 'Order status should be updated to Return Completed');
    }
    
    @isTest
    static void testAfterUpdate_RMAFailed() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        List<OrderItem> itemsToUpdate = [
            SELECT Id, ns_integration_error__c, Netsuite_RMA_ID__c 
            FROM OrderItem WHERE OrderId = :testOrder.Id
        ];
        
        itemsToUpdate[0].ns_integration_error__c = 'Error occurred';
        
        Test.startTest();
        update itemsToUpdate;
        Test.stopTest();
        
        Order updatedOrder = [SELECT Status FROM Order WHERE Id = :testOrder.Id];
        System.assertEquals('Return Failed', updatedOrder.Status, 'Order status should be updated to RMA Failed');
    }
    
}
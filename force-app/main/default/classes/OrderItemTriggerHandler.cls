/**************************************************************************************************
 * @Test class: OrderItemTests
* Date      	 - Project#       - Developer/ Company    
* -------------------------------------------------------------------------------------------------
* 6 June 2025    - GTMS-27708     - Rajat Kundlas/ Accenture 
*/

public class OrderItemTriggerHandler extends TriggerHandler {
    private Map<Id, OrderItem> oldOrderItemMap;
    private Map<Id, OrderItem> newOrderItemMap;
    private List<OrderItem> newOrderItemList;
    private List<OrderItem> oldOrderItemList;
    
    public OrderItemTriggerHandler() {
        this.oldOrderItemMap = (Map<Id, OrderItem>) Trigger.oldMap;
        this.newOrderItemMap = (Map<Id, OrderItem>) Trigger.newMap;
        this.newOrderItemList = (List<OrderItem>) Trigger.new;
        this.oldOrderItemList = (List<OrderItem>) Trigger.old;
    }

    public override void afterUpdate() {
        Set<Id> affectedOrderIds = new Set<Id>();

        for (OrderItem newItem : newOrderItemList) {
            OrderItem oldItem = oldOrderItemMap.get(newItem.Id);

            if (newItem.ns_integration_error__c != oldItem.ns_integration_error__c ||
                newItem.Netsuite_RMA_ID__c != oldItem.Netsuite_RMA_ID__c) {
                if (newItem.OrderId != null) {
                    affectedOrderIds.add(newItem.OrderId);
                }
            }
        }

        if (!affectedOrderIds.isEmpty()) {
            OrderItemHelper.updateOrderStatuses(affectedOrderIds);
        }
    }
}
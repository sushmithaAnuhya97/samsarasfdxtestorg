/**************************************************************************************************
 * @Test class: OrderItemTests
* Date      	 - Project#       - Developer/ Company    
* -------------------------------------------------------------------------------------------------
* 6 June 2025    - GTMS-27708     - Rajat Kundlas/ Accenture 
*/

public class OrderItemHelper {
    public static void updateOrderStatuses(Set<Id> orderIds) {        
        List<Order> ordersToUpdate = new List<Order>();
		
        List<Order> orders = [
            SELECT Id, Status, Type, RecordType.DeveloperName,
                (SELECT ns_integration_error__c, Netsuite_RMA_ID__c FROM OrderItems)
            FROM Order
            WHERE Id IN :orderIds
        ];

        for (Order o : orders) {
            if (o.RecordType != null &&
                o.RecordType.DeveloperName == 'Return_Order' &&
                o.Type == 'Remorse Refund') {

                Boolean hasIntegrationError = false;
                Boolean allHaveRMAId = true;
                String newStatus = '';

                for (OrderItem item : o.OrderItems) {
                    if (!String.isBlank(item.ns_integration_error__c)) { //if (item.ns_integration_error__c != null) {
                        hasIntegrationError = true;
                        break;
                    }
                    if (String.isBlank(item.Netsuite_RMA_ID__c)) { //if (item.Netsuite_RMA_ID__c == null) {
                        allHaveRMAId = false;
                    }
                }

                if (hasIntegrationError) {
                    newStatus = 'Return Failed';
                } else if (allHaveRMAId) {
                    newStatus = 'Return Completed';
                } //else {
                    //newStatus = 'In Progress';
                //}

                if (o.Status != newStatus) {
                    o.Status = newStatus;
                    ordersToUpdate.add(o);
                }
            }
        }

        if (!ordersToUpdate.isEmpty()) {
            update ordersToUpdate;
        }
    }
}
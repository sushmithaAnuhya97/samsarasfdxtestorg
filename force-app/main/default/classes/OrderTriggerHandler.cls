public with sharing class OrderTriggerHandler {

    public static Map<Id,list<orderItem>> ordIdOrdItemsMap = new Map<Id,list<orderItem>>();
    public static List<string> ProductsToSync = new List<string>();
    public static string status ;
    @AuraEnabled
    public static String handleOrderUpdate(Order order) {
        status = 'Success';
            if (order != null) {
                handleOrderUpdateFlow(new List<Order>{order});
            }else{
                status = 'Error';
            } 
            return status;
        }
    
    @InvocableMethod(label='Handle Order Update' description='Process order update and fire platform event for buyout products')
    public static void  handleOrderUpdateFlow(List<Order> orders) {
        Set<Id> ordIds = new Set<Id>();
        try{
            if (orders != null && !orders.isEmpty()) {
                init(orders);
                List<order> ordToSync = new List<order>();
                for (Order ord : orders) {
                   if(hasBuyoutProduct(ord)){
                    ordToSync.add(ord);
                    ordIds.add(ord.Id);
                   } 
                }
                if(!ordToSync.isEmpty()){
                    status = 'Success';
                    firePlatformEvent(ordToSync);
                }else{
                    status = 'No orderItems to sync to Netsuite';
                }
             }
        }catch(Exception e){
            status = 'Error';
           LOGGER.atError().setExceptionOrMessage(e);
            if(!ordIds.isEmpty()){
                Logger.setRecordIds(ordIds);
            }
            Logger.insertMasterLogs(); 
        }  
    }
    private static void init(List<Order> orders){
        if(ordIdOrdItemsMap.isEmpty()){
            Set<Id> orderIds = new Set<Id>();
            for(Order ord : orders) {
                orderIds.add(ord.Id);
            }
            for(Orderitem OI : [SELECT Id,orderId,Product2.ProductCode ,ns_creditmemo_id__c FROM OrderItem WHERE OrderId IN :orderIds]){
                if(!ordIdOrdItemsMap.containsKey(OI.orderId)){
                   ordIdOrdItemsMap.put(OI.orderId,new list<orderItem>());
                }
                ordIdOrdItemsMap.get(OI.orderId).add(OI);
            }
        }
        Map<String, Rebate_Buyout_Product_Mapping__mdt> rebateMap = Rebate_Buyout_Product_Mapping__mdt.getAll();
        if(ProductsToSync.isEmpty() && !rebateMap.isEmpty()){
            for(Rebate_Buyout_Product_Mapping__mdt rebate : rebateMap.values()) {
                if(rebate.Notify_Integration_Platform__c){
                    ProductsToSync.add(rebate.Product_Code__c);
                }
           }
        }
}
@TestVisible     
public static boolean hasBuyoutProduct(Order ord){
        if (ord.Status == 'Fulfilled') {
            if(ordIdOrdItemsMap.containsKey(ord.id) && !ordIdOrdItemsMap.get(ord.id).isEmpty()){
                for(orderItem OI : ordIdOrdItemsMap.get(ord.id)){
                    if(OI.ns_creditmemo_id__c == null && ProductsToSync.contains(OI.Product2.ProductCode)){
                        return true;
                    }
                }
            }
        }
        return false;
    }
    
    private static void firePlatformEvent(List<Order> ordList) {
        List<CPQ_Deal_Component_Order_Event__e> events = new List<CPQ_Deal_Component_Order_Event__e>();
       for(Order ord : ordList){
        events.add(new CPQ_Deal_Component_Order_Event__e(
                Order_Id__c = ord.Id,
                Opportunity_ID__c = ord.OpportunityId,
                Order_RecordType__c = ord.RecordTypeId,
                Order_Status__c = ord.Status,
                Order_Type__c = ord.Type
            ));
        }
        List<Database.SaveResult> publishedEvents = EventBus.publish(events);
        for(integer i=0; i<publishedEvents.size();i++){
                if (publishedEvents[i].isSuccess()) {
                    Logger.setRecordId(events[i].Order_Id__c);
                    LOGGER.atInfo().setLineNumber(89).setMethod('firePlatformEvent').setCLassName('OrderTriggerHandler').setExceptionOrMessage('CPQ deal component platform event is published ,Id: '+publishedEvents[i].id);
                } else {
                    for (Database.Error err : publishedEvents[i].getErrors()) {
                        status = 'Failed to call platform event';
                        LOGGER.atError().setMethod('firePlatformEvent').setCLassName('OrderTriggerHandler').setRecordId(events[i].Order_Id__c).setExceptionOrMessage(err.getMessage());
                    }
                }
        }
        Logger.insertMasterLogs();     
    }
}
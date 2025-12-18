public class Customer360TriggerHelper {
    private Toggle_Platform_Event__mdt Cust360EventToggle;
    static CS360_Object_Field_WebStore__mdt [] csWSFields = [Select Id,Object_Api_Name__c,Field_Api_Name__c from CS360_Object_Field_WebStore__mdt Where Object_Api_Name__c = 'Customer_360__c'];
    
    
    public Customer360TriggerHelper(){
        this.cust360EventToggle = Toggle_Platform_Event__mdt.getInstance('Customer_360_Event');
    }

    public void publishPlatformEventInsert(List<Customer_360__c> newCustomer360List){
        if(newCustomer360List==null || newCustomer360List.isEmpty()){
            return;
        }
        
        Set<Id> customerIds = new Set<Id>();
        for(Customer_360__c newRecordInsert:newCustomer360List){
            customerIds.add(newRecordInsert.Id); 
        }
        
        if(customerIds.isEmpty()){
            return;
        }
        
        Map<Id, Customer_360_Event__e> cust360Events = new Map<Id, Customer_360_Event__e>();
        for(Customer_360__c cs360: [select Id,Account__c,Account__r.BigCommerce_Id__c from Customer_360__c where Account__c != null and Id IN: customerids]){
            if(!Cust360Events.containsKey(cs360.Account__c)){
                cust360Events.put(cs360.Account__c, new Customer_360_Event__e(Account_Id__c = cs360.Account__c));
            }
        }
        System.debug('cust360Events:After INSERT:::'+cust360Events);
        publishPlatformWSEvent(cust360Events);
    }
    public void publishPlatformEventBeforeUpdate(Map<Id,Customer_360__c> oldCustomer360Map,List<Customer_360__c> newCustomer360List){
        if(oldCustomer360Map==null || newCustomer360List==null || oldCustomer360Map.isEmpty() || newCustomer360List.isEmpty()){
            return;
        }
        for(Customer_360__c newRecord:newCustomer360List){
            Customer_360__c oldRecord=oldCustomer360Map.get(newRecord.Id);
              //Avoid Recurssion
            if (isRecordModifiedByMulesoft(newRecord,oldRecord)) {
                continue;
            }
            Boolean isPushToWebstoreUpdated = newRecord.Push_to_Webstore__c != oldRecord.Push_to_Webstore__c;
            Boolean isBigCommerceIdUpdated = newRecord.BigCommerce_Id__c != oldRecord.BigCommerce_Id__c;
            Boolean isWebstoreSyncErrorUpdated = newRecord.Webstore_Sync_Error__c != oldRecord.Webstore_Sync_Error__c;
            Boolean isUpdatedByWebstore =(isPushToWebstoreUpdated && (isBigCommerceIdUpdated || isWebstoreSyncErrorUpdated));
            
            Boolean changeFlagWebstore = isFieldValueChanged(oldRecord, newRecord, csWSFields);
            system.debug('changeFlagWebstore'+changeFlagWebstore);
            
            Boolean isPushtoWebstoreChanged = (newRecord.Push_to_Webstore__c==true && (newRecord.Push_to_Webstore__c!= oldRecord.Push_to_Webstore__c));
            
            Boolean isNotSyncInProgress = oldRecord.Push_to_Webstore__c == false;
            Boolean isCriteriaCheckPass = (oldRecord.BigCommerce_Id__c != null);
            if(newRecord.Account__c != null && (changeFlagWebstore || isPushtoWebstoreChanged) &&
               !isUpdatedByWebstore && isNotSyncInProgress && isCriteriaCheckPass && this.cust360EventToggle.toggle__c){
                newRecord.Push_to_Webstore__c = true;
            }
        }
    }
    
    public static Boolean isRecordModifiedByMulesoft(Customer_360__c newRecord, Customer_360__c oldRecord){
        String userName = UserInfo.getName(); 
        if (userName == 'Automated Process' || (userName == 'Mulesoft Bot' && (newRecord.Push_to_Webstore__c==false))) {
            return true;
        }else{
            return false;
        }
    }
    
    public void publishPlatformEventAfterUpdate(Map<Id,Customer_360__c> oldCustomer360Map,List<Customer_360__c> newCustomer360List){
        if(oldCustomer360Map==null || newCustomer360List==null || oldCustomer360Map.isEmpty() || newCustomer360List.isEmpty()){
            return;
        }
        Map<Id, Customer_360_Event__e> cust360Events = new Map<Id, Customer_360_Event__e>();
        for(Customer_360__c newRecord:newCustomer360List){
            Customer_360__c oldRecord=oldCustomer360Map.get(newRecord.Id);
            if (newRecord.Account__c != null && newRecord.Push_to_Webstore__c == true && oldRecord.Push_to_Webstore__c == false && !cust360Events.containsKey(newRecord.Account__c)) {                                                                                        
                         //Avoid Recurssion
              if (isRecordModifiedByMulesoft(newRecord,oldRecord)) {
                continue;
              }
                cust360Events.put(newRecord.Account__c, new Customer_360_Event__e(Account_Id__c = newRecord.Account__c));
                   }
               }
        if(cust360Events.isEmpty()){
            return;
        }
        
        System.debug('cust360Events:After UPDATE:::'+cust360Events);
        publishPlatformWSEvent(cust360Events);
    }
    
    public void publishPlatformWSEvent(Map<Id, Customer_360_Event__e> customer360EventList){
        if(customer360EventList == null || customer360EventList.isEmpty()){
            return;
        }
        Boolean checkPlatformEvent = PlatformEventCallback.checkPlatformEventLimits();
        if(!checkPlatformEvent){
            return;
        }
        // Call method to publish events
        if(customer360EventList.size()>0 && this.cust360EventToggle.toggle__c){
            List<Database.SaveResult> results = EventBus.publish(customer360EventList.values(), new PlatformEventCallback());
            
            // Inspect publishing result for each event
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                    System.debug('Successfully published event.'+ sr.getId());
                } else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug('Account fields that affected this error: ' + err.getFields());
                        System.debug('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    }
                }       
            }
        }
    }
    
    private static Boolean isFieldValueChanged(Customer_360__c oldRecord,Customer_360__c newRecord,CS360_Object_Field_WebStore__mdt [] CS360WSFields){
         for(CS360_Object_Field_WebStore__mdt  mdt: CS360WSFields){
             if(newRecord.get(mdt.Field_Api_Name__c)!=oldRecord.get(mdt.Field_Api_Name__c)){
                return true;
            }
        }
        return false;
    }
    
    public void publishPlatformEventAfterDelete(Map<Id,Customer_360__c> oldCustomer360Map){
        if(oldCustomer360Map == null || oldCustomer360Map.isEmpty()){
            return;
        }
        
        Map<Id,Customer_360_Event__e> customer360Event = new Map<Id,Customer_360_Event__e>();
        for(Customer_360__c custmer360:oldCustomer360Map.values()){
            if(custmer360.Account__c!=null){
                customer360Event.put(custmer360.Account__c, new Customer_360_Event__e(Account_Id__c = custmer360.Account__c));
            }
        }
        publishPlatformWSEvent(customer360Event);
    }
  }
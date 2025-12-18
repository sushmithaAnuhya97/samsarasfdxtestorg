public  without sharing class Product2TriggerHelper {
    private Toggle_Platform_Event__mdt productToggle;
    private Product_Object_Field_WebStore__mdt[] productNullCheckFields;
    static Product_Object_Field_WebStore__mdt[] prodWSFields = [Select Id,Object_Api_Name__c,Field_Api_Name__c from Product_Object_Field_WebStore__mdt Where Object_Api_Name__c = 'Product2'];
    
    public Product2TriggerHelper(){
        this.productToggle = Toggle_Platform_Event__mdt.getInstance('Product_Webstore_Event');
        this.productNullCheckFields = [Select Id,Object_Api_Name__c,Field_Api_Name__c ,Null_Check_Needed__c from Product_Object_Field_WebStore__mdt Where Object_Api_Name__c = 'Product2' and Null_Check_Needed__c = true];
    }
    
    public void publishPlatformEventInsert(List<product2> newProdList){
        if(newProdList==null || newProdList.isEmpty()){
            return;
        }
        
        Map<Id, Product_Webstore_Event__e> prodEvents = new Map<Id, Product_Webstore_Event__e>();
        for(product2 newRecordInsert:newProdList){
            Boolean nullFlagCheck = verifyNullCheck(newRecordInsert,this.productNullCheckFields);
            if (nullFlagCheck && !ProdEvents.containsKey(newRecordInsert.Id)) {                                                                                        
                prodEvents.put(newRecordInsert.Id, new Product_Webstore_Event__e(Product_Id__c = newRecordInsert.Id));
            }
        }
        publishPlatformWSEvent(prodEvents);
    }
    
     public static Boolean isRecordModifiedByMulesoft(product2 newRecord, product2 oldRecord){
        String userName = UserInfo.getName(); 
        if (userName == 'Automated Process' || 
            (FeatureManagement.checkPermission('NetSuite_Service_User_Permission') 
             && (newRecord.Push_to_Webstore__c==false || (newRecord.Push_to_Netsuite__c != oldRecord.Push_to_Netsuite__c)))) {
            return true;
        }else{
            return false;
        }
    }
    public void publishPlatformEventBeforeUpdate(Map<Id,product2> oldProdMap,List<product2> newProdList){
        if(oldProdMap==null || newProdList==null || oldProdMap.isEmpty() || newProdList.isEmpty()){
            return;
        }
        for(product2 newRecord:newProdList){
            Product2 oldRecord=oldProdMap.get(newRecord.Id);
            if (isRecordModifiedByMulesoft(newRecord,oldRecord)) {
                continue;
            }
            Boolean isPushToWebstoreUpdated = newRecord.Push_to_Webstore__c != oldRecord.Push_to_Webstore__c;
            Boolean isBigCommerceIdUpdated = newRecord.BigCommerce_Id__c != oldRecord.BigCommerce_Id__c;
            Boolean isWebstoreSyncErrorUpdated = newRecord.Webstore_Sync_Error__c != oldRecord.Webstore_Sync_Error__c;
            Boolean isUpdatedByWebstore =(isPushToWebstoreUpdated && (isBigCommerceIdUpdated || isWebstoreSyncErrorUpdated));
            
            Boolean changeFlagWebstore = isFieldValueChanged(oldRecord, newRecord, prodWSFields);
            Boolean nullFlagCheck = verifyNullCheck(newRecord,this.productNullCheckFields);
            
            Boolean isPushtoWebstoreChanged = (newRecord.Push_to_Webstore__c==true && (newRecord.Push_to_Webstore__c!= oldRecord.Push_to_Webstore__c));
            
            Boolean isNotSyncInProgress = oldRecord.Push_to_Webstore__c == false;
            Boolean isCriteriaCheckPass = (oldRecord.BigCommerce_Id__c != null || nullFlagCheck);
            if((changeFlagWebstore || isPushtoWebstoreChanged) && !isUpdatedByWebstore && isNotSyncInProgress && isCriteriaCheckPass && this.ProductToggle.toggle__c){
                newRecord.Push_to_Webstore__c = true;
            }
        }
    }
        
    public void publishPlatformEventUpdate(Map<Id,product2> oldProdMap,List<product2> newProdList){
        if(oldProdMap==null || newProdList==null || oldProdMap.isEmpty() || newProdList.isEmpty()){
            return;
        }
        
        Map<Id, Product_Webstore_Event__e > prodEvents = new Map<Id, Product_Webstore_Event__e>();
        for(product2 newRecord:newProdList){
            Product2 oldRecord=oldProdMap.get(newRecord.Id);
            if (newRecord.Id != null  && newRecord.Push_to_Webstore__c == true && oldRecord.Push_to_Webstore__c == false && !ProdEvents.containsKey(newRecord.Id)) {                                                                                        
                       if (isRecordModifiedByMulesoft(newRecord,oldRecord)) {
                		continue;
            			}
                ProdEvents.put(newRecord.Id, new Product_Webstore_Event__e(Product_Id__c = newRecord.Id));
                   }
                   System.debug('ProdEvents'+ProdEvents);
            	
            }
            
            	if(ProdEvents.isEmpty()){
            	return;
        		}
        
        System.debug('ProdEvents:After UPDATE:::'+ProdEvents);
        publishPlatformWSEvent(ProdEvents);
    }
    
    public Boolean isFieldValueChanged(product2 newProduct, product2 oldProduct,Product_Object_Field_WebStore__mdt[] prodWSFields){
        for(Product_Object_Field_WebStore__mdt  mdt: prodWSFields){
            if(newProduct.get(Mdt.Field_Api_Name__c)!=oldProduct.get(Mdt.Field_Api_Name__c)){
                return true;
            }
        }
        return false;
    }
    
    public Boolean verifyNullCheck(Product2 newProduct,Product_Object_Field_WebStore__mdt[] productNullCheckFields){
        for(Product_Object_Field_WebStore__mdt EachMdtField: productNullCheckFields){
            if(newProduct.get(EachMdtField.Field_Api_Name__c)==null){
                return false; 
            }
        }
        return true;
    }
    
    public void publishPlatformWSEvent(Map<Id, Product_Webstore_Event__e> newProdList){
        if(newProdList == null || newProdList.isEmpty()){
            return;
        }
        Boolean checkPlatformEvent = PlatformEventCallback.checkPlatformEventLimits();
        if(!checkPlatformEvent){
            return;
        }
        // Call method to publish events
        if(newProdList.size()>0 && ProductToggle.toggle__c){
            List<Database.SaveResult> results = EventBus.publish(newProdList.values(), new PlatformEventCallback());
            
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
}
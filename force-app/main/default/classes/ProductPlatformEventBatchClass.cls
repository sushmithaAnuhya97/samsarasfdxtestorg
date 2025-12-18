/* 
 * Class Created: 11/24/2022 Saiteja Kolishetti (GTMS-10382)
 * Test Class: ProductPlatformEventBatchClassTest
 * 11/24/2022 Saiteja - PLM Field Mapping, platform events and Integration testing
 */  
global class ProductPlatformEventBatchClass implements Database.Batchable<SObject>, Database.Stateful{
    
    public String pbeQuery;
    public ProductPlatformEventBatchClass(String query){
        this.pbeQuery = query;
    }
    global Database.QueryLocator start (Database.BatchableContext bc){
        System.debug('pbeQuery is:'+pbeQuery);
        return Database.getQueryLocator(pbeQuery);
    }
    
    global void execute(Database.BatchableContext bc, List<PricebookEntry> pbeList){
        Set<Id> productIds = new Set<Id>();
        List<Product_Event__e> productSyncEvents = new List<Product_Event__e>();
        for(PricebookEntry pbe : pbeList){
            productIds.add(pbe.Product2Id);
        }
         System.debug('productIds is:'+productIds);
        for(Id id : productIds){
            productSyncEvents.add(new Product_Event__e(Product_Id__c = id)); 
        }
        System.debug('productSyncEvents is:'+productSyncEvents);
        try{
            if(productSyncEvents.size()>0){
                List<Database.SaveResult> results = EventBus.publish(productSyncEvents);
            }
        }catch(Exception ex){
            System.debug('The exception occurred is: ' +ex.getMessage());
        }
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
    
}
public class Customer360TriggerHandler  extends TriggerHandler{
    public static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{Customer_360__c.SObjectType};
    Private List<Customer_360__c> newList;
    Private List<Customer_360__c> oldList;
    
    Private Map<Id,Customer_360__c> oldMap;
    Private Map<Id,Customer_360__c> newMap;
    private Customer360TriggerHelper cust360Helper;
    Private UnitOfWork uow;
    
    public Customer360TriggerHandler() {
        this.cust360Helper = new Customer360TriggerHelper();
        this.oldMap = (Map<Id, Customer_360__c>) Trigger.oldMap;
        this.newMap = (Map<Id, Customer_360__c>) Trigger.newMap;
        this.newList = (List<Customer_360__c>) Trigger.new;
        this.oldList = (List<Customer_360__c>) Trigger.old;
        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
        
    }
    public override void beforeInsert() {
        System.debug('TriggerHandler beforeInsert Start');
    }
    
    public override void afterInsert(){
        this.cust360Helper.publishPlatformEventInsert(newList); 
        
    }
    
    public override void beforeUpdate() {
        this.cust360Helper.publishPlatformEventBeforeUpdate(oldMap,newList);
    }
    
    public override void afterUpdate() {
        //this.cust360Helper.publishPlatformWSEvent();
        this.cust360Helper.publishPlatformEventAfterUpdate(oldMap,newList);
    }
    
    public override void afterDelete() {
        this.cust360Helper.publishPlatformEventAfterDelete(oldMap);
    }
    public override void publishDMLs() {
        uow = DMLWrapper.uow;
        DMLWrapper.publishDML(uow);
    }
    
}
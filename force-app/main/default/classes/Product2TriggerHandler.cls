public class Product2TriggerHandler extends TriggerHandler{
    public static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{product2.SObjectType};
    private List<product2> newList;
    private List<product2> oldList;
    
    private Map<Id,product2> oldMap;
    private Map<Id,product2> newMap;
    private Product2TriggerHelper productHelper;
    private UnitOfWork uow;
    
    public Product2TriggerHandler() {
        this.productHelper = new Product2TriggerHelper();
        this.oldMap = (Map<Id, product2>) Trigger.oldMap;
        this.newMap = (Map<Id, product2>) Trigger.newMap;
        this.newList = (List<product2>) Trigger.new;
        this.oldList = (List<product2>) Trigger.old;
        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
    }
    
    public override void beforeInsert() {
        System.debug('TriggerHandler beforeInsert Start');
    }
    
    public override void afterInsert(){
        this.productHelper.publishPlatformEventInsert(newList);
    }
    
    public override void beforeUpdate() {
        this.productHelper.publishPlatformEventBeforeUpdate(oldMap,newList);

    }
    
    public override void afterUpdate() {
        System.debug('afterUpdate1---------->');
        this.productHelper.publishPlatformEventUpdate(oldMap,newList);
     }
    
    public override void publishDMLs() {
        uow = DMLWrapper.uow;
        DMLWrapper.publishDML(uow);
    }
}
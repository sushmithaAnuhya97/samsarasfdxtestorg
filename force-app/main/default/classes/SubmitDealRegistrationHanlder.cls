public class SubmitDealRegistrationHanlder extends TriggerHandler{
    
    private Map<Id, SubmitDealRegistrationEvent__e> oldEventMap;
    private Map<Id, SubmitDealRegistrationEvent__e> newEventMap;
    private List<SubmitDealRegistrationEvent__e> newEventList;
    public static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
            Lead.SObjectType
    };
    private UnitOfWork uow ;
    
    public SubmitDealRegistrationHanlder() {
        this.oldEventMap = (Map<Id, SubmitDealRegistrationEvent__e>) Trigger.oldMap;
        this.newEventMap = (Map<Id, SubmitDealRegistrationEvent__e>) Trigger.newMap;
        this.newEventList = (List<SubmitDealRegistrationEvent__e>) Trigger.new;
        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
    }

    
    public override void afterInsert() {
        SubmitDealRegistrationHelper.afterInsertOperations(oldEventMap, newEventList);
    }

    public override void publishDMLs() {
        uow = DMLWrapper.uow;
        DMLWrapper.publishDML(uow);
    }
    
}
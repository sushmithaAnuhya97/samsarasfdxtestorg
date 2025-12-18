public class SubmitPartnerApplicationHandler extends TriggerHandler{
    
    private Map<Id, SubmitPartnerApplicationEvent__e> oldEventMap;
    private Map<Id, SubmitPartnerApplicationEvent__e> newEventMap;
    private List<SubmitPartnerApplicationEvent__e> newEventList;
    public static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
            Lead.SObjectType
    };
    private UnitOfWork uow ;
    
    public SubmitPartnerApplicationHandler() {
        this.oldEventMap = (Map<Id, SubmitPartnerApplicationEvent__e>) Trigger.oldMap;
        this.newEventMap = (Map<Id, SubmitPartnerApplicationEvent__e>) Trigger.newMap;
        this.newEventList = (List<SubmitPartnerApplicationEvent__e>) Trigger.new;
        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
    }

    
    public override void afterInsert() {
        SubmitPartnerApplicationHelper.afterInsertOperations(oldEventMap, newEventList);
    }

    public override void publishDMLs() {
        uow = DMLWrapper.uow;
        DMLWrapper.publishDML(uow);
    }
    
}
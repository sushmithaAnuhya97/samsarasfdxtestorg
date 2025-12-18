public class CreateOpportunityEventHandler extends TriggerHandler{
    
    private Map<Id, CreateOpportunityEvent__e > oldEventMap;
    private Map<Id, CreateOpportunityEvent__e > newEventMap;
    private List<CreateOpportunityEvent__e > newEventList;
    
    public CreateOpportunityEventHandler() {
        this.oldEventMap = (Map<Id, CreateOpportunityEvent__e >) Trigger.oldMap;
        this.newEventMap = (Map<Id, CreateOpportunityEvent__e >) Trigger.newMap;
        this.newEventList = (List<CreateOpportunityEvent__e >) Trigger.new;
    }

    
    public override void afterInsert() {
        CreateOpportunityEventHelper.afterInsertOperations(oldEventMap, newEventList);
    }
}
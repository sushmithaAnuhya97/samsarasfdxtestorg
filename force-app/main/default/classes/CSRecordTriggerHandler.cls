public class CSRecordTriggerHandler extends TriggerHandler{
     
    private Map<Id, CS_Record__c> oldCSMap;
    private Map<Id, CS_Record__c> newCSMap;

    public CSRecordTriggerHandler(){
        this.oldCSMap = (Map<Id, CS_Record__c>) Trigger.oldMap;
        this.newCSMap = (Map<Id, CS_Record__c>) Trigger.newMap;
    }
    
    public override void afterUpdate(){
        CSRecordHelper.afterUpdateOperations(oldCSMap, newCSMap);
    }
    
    // Added for GTMS-30390
    public override void beforeInsert(){
        CSRecordHelper.beforeInsertOperations((List<CS_Record__c>)Trigger.new);
    }

}
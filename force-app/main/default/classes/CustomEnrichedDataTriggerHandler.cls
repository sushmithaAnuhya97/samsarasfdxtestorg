/**
 * CustomEnrichedDataTriggerHandler is a trigger handler class that extends the TriggerHandler class.
 * It handles the after insert, after update, after delete, and after undelete events for Custom_Enriched_Data__c objects.
 * 
 * This class uses the CustomEnrichedDataTriggerHelper to update the origination source account based on the new and old maps of Custom_Enriched_Data__c records.
 * 
 * @author Hitesh Khatri
 */
public with sharing class CustomEnrichedDataTriggerHandler extends TriggerHandler{

    private Map<Id, Custom_Enriched_Data__c> oldCEDMap;
	private Map<Id, Custom_Enriched_Data__c> newCEDMap;

    public CustomEnrichedDataTriggerHandler() {
		this.oldCEDMap = (Map<Id, Custom_Enriched_Data__c >) Trigger.oldMap;
		this.newCEDMap = (Map<Id, Custom_Enriched_Data__c >) Trigger.newMap;
    }
    
    public override void afterInsert() {
        CustomEnrichedDataTriggerHelper.updateOriginationSourceAccount(this.newCEDMap, this.oldCEDMap);
    }

    public override void afterUpdate() {
        CustomEnrichedDataTriggerHelper.updateOriginationSourceAccount(this.newCEDMap, this.oldCEDMap);

    }

    public override void afterDelete() {
        CustomEnrichedDataTriggerHelper.updateOriginationSourceAccount(this.newCEDMap, this.oldCEDMap);

    }
    public override void afterUndelete() {
        CustomEnrichedDataTriggerHelper.updateOriginationSourceAccount(this.newCEDMap, this.oldCEDMap);
    }
}
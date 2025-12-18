/**
 * Trigger: CustomEnrichedDataTrigger
 * 
 * This trigger is executed on the Custom_Enriched_Data__c object and handles the following events:
 * - after insert
 * - after update
 * - after delete
 * - after undelete
 * 
 * The trigger utilizes the GS_TriggerHandlerRunnerConfig class to create and run a handler for the Custom_Enriched_Data__c object.
 * 
 * @trigger CustomEnrichedDataTrigger
 * @object Custom_Enriched_Data__c
 * @events after insert, after update, after delete, after undelete
 */
trigger CustomEnrichedDataTrigger on Custom_Enriched_Data__c (after insert, after update, after delete, after undelete) {
    new GS_TriggerHandlerRunnerConfig().createHandler('CustomEnrichedData').run();

}
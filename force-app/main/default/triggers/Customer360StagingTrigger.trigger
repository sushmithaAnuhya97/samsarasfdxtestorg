trigger Customer360StagingTrigger on Customer_360_Staging__c (after update) {
    
    //Not proceeding with Trigger Handler framework as the object will be erased once the C360 is fully reworked.

    if(Trigger.isAfter && Trigger.isUpdate){
        Customer360StagingTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
}
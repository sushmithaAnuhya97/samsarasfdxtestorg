trigger Customer360Trigger on Customer_360__c (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    new GS_TriggerHandlerRunnerConfig().createHandler('Customer360').run();
}
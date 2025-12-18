trigger OpportunityLineItemTrigger on OpportunityLineItem (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    //new OpportunityLineItemTriggerHandler().run();
    new GS_TriggerHandlerRunnerConfig().createHandler('OpportunityLineItem').run();
    // dlrs.RollupService.triggerHandler(OpportunityLineItem.SObjectType);
}
trigger OpportunityTrigger on Opportunity (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    OpportunityDomain.onOpportunityTrigger();
    //new OpportunityTriggerHandler().run();
    new GS_TriggerHandlerRunnerConfig().createHandler('Opportunity').run();
}
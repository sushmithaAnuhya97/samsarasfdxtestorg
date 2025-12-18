trigger SBQQQuoteTrigger on SBQQ__Quote__c (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    //new SBQQQuoteTriggerHandler().run();
    new GS_TriggerHandlerRunnerConfig().createHandler('SBQQQuote').run();
}
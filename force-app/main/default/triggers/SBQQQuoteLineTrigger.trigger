/* 
 * Class Created: 07/03/19 - @author: Harsha
 */  
trigger SBQQQuoteLineTrigger on SBQQ__QuoteLine__c (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    // new SBQQQuoteLineTriggerHandler().run();
    new GS_TriggerHandlerRunnerConfig().createHandler('SBQQQuoteLine').run();
}
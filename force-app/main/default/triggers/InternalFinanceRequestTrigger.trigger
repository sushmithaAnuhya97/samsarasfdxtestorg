trigger InternalFinanceRequestTrigger on Internal_Finance_Approval_Request__c (before insert, before update, after insert, after update, before delete, after delete, after undelete) 
{
    new GS_TriggerHandlerRunnerConfig().createHandler('InternalFinanceRequest').run();
}
trigger PartnerRegistration on Partner_Registration__c (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    new GS_TriggerHandlerRunnerConfig().createHandler('PartnerRegistration').run();
}
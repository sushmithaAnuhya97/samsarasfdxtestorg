trigger QuotaTrigger on Quota__c (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    new QuotaTriggerHandler().run();
}
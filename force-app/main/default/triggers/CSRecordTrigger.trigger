trigger CSRecordTrigger on CS_Record__c(before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    new CSRecordTriggerHandler().run();
}
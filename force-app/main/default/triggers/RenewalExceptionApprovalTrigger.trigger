trigger RenewalExceptionApprovalTrigger on Renewal_Exception_Approval__c (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    new RenewalExceptionApprovalTriggerHandler().run();
}
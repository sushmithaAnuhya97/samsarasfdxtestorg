trigger ApprovalTriggres on SBAA__Approval__c (after insert,after update) {
    new ApprovalTriggerHandler().run();
}
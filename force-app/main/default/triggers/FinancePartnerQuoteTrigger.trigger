trigger FinancePartnerQuoteTrigger on Finance_Partner_Quote__c (after update,before update, after insert) {
    new FinancePartnerQuoteTriggerHandler().run();
}
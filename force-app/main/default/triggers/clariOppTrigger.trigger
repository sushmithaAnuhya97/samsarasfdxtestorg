trigger clariOppTrigger on Clari_Opp__c (after insert) {
    
    clariOppTriggerHelper.afterInsert();
   
    
}
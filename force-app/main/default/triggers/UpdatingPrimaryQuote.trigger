trigger UpdatingPrimaryQuote on dsfs__DocuSign_Status__c (before insert ,before update) {

  DocuSignStatusHandler.updatePrimaryQuote(trigger.New,trigger.oldMap);

}
/*
Test class:QuoteOrderedQueueableTest
*/

public class RetryOrderCreationController {
    
    @InvocableMethod(label='Retry Order generation' description='Generates order, if it is not created')
    public static void makeCallout(List<Id> OppIds) {
        Set<Id> oppWithOrderIds = new Set<Id>();
        Set<Id> oppWithoutOrdersIds = new Set<Id>();
        for (order ord : [SELECT Id, OpportunityId FROM Order WHERE OpportunityId IN :OppIds]) {
            oppWithOrderIds.add(ord.OpportunityId);
        }
        for (Id OppId : OppIds) {
            if (!oppWithOrderIds.contains(OppId)) {
                oppWithoutOrdersIds.add(oppId);
            }
        }
        if (oppWithoutOrdersIds.isEmpty()) {
            return;
        }
        List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();
        for (Opportunity opp : [SELECT Id, SBQQ__PrimaryQuote__c, StageName FROM Opportunity WHERE Id IN: oppWithoutOrdersIds]) {
            SBQQ__Quote__c quote = new SBQQ__Quote__c();
            quote.Id = opp.SBQQ__PrimaryQuote__C;
            quote.SBQQ__Ordered__c = false;
            quotesToUpdate.add(quote);
        }
         // Step 3: First uncheck Ordered checkbox
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.bypass('SBQQQuoteTriggerHandler');
        SBQQ.TriggerControl.disable();
        update quotesToUpdate;
        TriggerHandler.clearAllBypasses();
        SBQQ.TriggerControl.enable();
        // Step 4: Re-check Ordered checkbox
        for (SBQQ__Quote__c q : quotesToUpdate) {
            q.SBQQ__Ordered__c = true;
        }
        Database.SaveResult[] results = Database.update(quotesToUpdate, false);
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                for (Database.Error err : results[i].getErrors()) {
                    LOGGER.atError().setCLassName('RetryOrderCreationController').setExceptionOrMessage(err.getMessage());
                    Logger.setFunctionalityType('Retry Ordering of Quotes'); 
                    Logger.setRecordId(quotesToUpdate[i].Id);
                }
            } else {
                Logger.atInfo().setCLassName('RetryOrderCreationController').setExceptionOrMessage('Quote was re-ordered successfully');
                Logger.setFunctionalityType('Retry Ordering of Quotes'); 
                Logger.setRecordId(quotesToUpdate[i].Id);
            }
        }
        Logger.insertMasterLogs();      
    }
}
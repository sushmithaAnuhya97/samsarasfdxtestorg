/*
 * Description:- This batch job is used to Amend Contract
 * 10/24/2022 - Rajesh  GTMS-9570 
 * 
 * 
 */
global with sharing class ContractAmender {

    /*global class FlowOutput {
        @InvocableVariable 
        global Id QuoteId;
    }*/
    
    @InvocableMethod(label='ContractAmender' description='Contract Amender')
    //GTMS-26025 Updated the logic to avoid SOQL in the loop
    public static List<SBQQ__Quote__c> load(List<Id> contractId) { 
        List<SBQQ__Quote__c> results = new List<SBQQ__Quote__c>(); 
        List<Id> quoteIds = new List<Id>();
        for (Id conId : contractId) { 
            String quoteJSON = SBQQ.ServiceRouter.load('SBQQ.ContractManipulationAPI.ContractAmender', conId, null);
            QuoteModel qm = (QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class);
            if (qm?.record?.id != null) { 
                quoteIds.add(qm.record.id);
            } 
        } 
        if (!quoteIds.isEmpty()) { 
            results = [SELECT Id, SBQQ__Opportunity2__c FROM SBQQ__Quote__c WHERE Id IN :quoteIds];
        } 
        return results;
    }
}
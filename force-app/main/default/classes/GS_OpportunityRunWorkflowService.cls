public with sharing class GS_OpportunityRunWorkflowService {
    
    public void runBeforeInsertWorkflows(List<Opportunity> newOpportunityList, GS_OpportunityCacheService cache){

        /* cache.loadOppRelatedUser(cache.cachedOwnerIds);
        cache.cachedOwnerIds = null;

        cache.loadOpportunityWithItems(cache.cachedOpportunityIds);
        cache.cachedOpportunityIds = null;
        
        for (Opportunity opp : newOpportunityList){
            Account thisOppAccount = (opp.AccountId != null ? cache.relatedAccountMap.get(opp.AccountId) : new Account());
            User ownerRecord = cache.relatedUserMap.get(opp.OwnerId);

            Opportunity vOpportunity = new Opportunity();
            if(opp.Returning_Opportunity__c != null){
                vOpportunity = cache.loadedOpportunityMap.get(opp.Returning_Opportunity__c);
            }

            GS_OpportunityWorkflowConversion.beforeInsertUpdateMethod(opp, new Opportunity(), vOpportunity, thisOppAccount, ownerRecord);
        } */
    }

    public void runBeforeUpdateWorkflows(Map<Id, Opportunity> oldOpportunityMap, List<Opportunity> newOpportunityList, GS_OpportunityCacheService cache){
        /* cache.loadOppRelatedUser(cache.cachedOwnerIds);
        cache.cachedOwnerIds = null;

        cache.loadOpportunityWithItems(cache.cachedOpportunityIds);
        cache.cachedOpportunityIds = null;
        
        for (Opportunity opp : newOpportunityList){
            Opportunity oldOpp = oldOpportunityMap.get(opp.Id);
            Account thisOppAccount = (opp.AccountId != null ? cache.relatedAccountMap.get(opp.AccountId) : null);
            User ownerRecord = cache.relatedUserMap.get(opp.OwnerId);

            Opportunity vOpportunity = cache.loadedOpportunityMap.get(opp.Id);

            GS_OpportunityWorkflowConversion.beforeInsertUpdateMethod(opp, oldOpp, vOpportunity, thisOppAccount, ownerRecord);
            GS_OpportunityWorkflowConversion.beforeUpdateMethod(opp, oldOpp, ownerRecord);
            
            // Code for new Renewal Process
            //OpportunityProcessBuilderConversion.stampDataForAmendments(opp, thisOppAccount, oldOpp);
        } */
    }
}
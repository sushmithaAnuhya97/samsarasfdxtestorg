public with sharing class GS_OpportunityToUpdateAccountService {
    private GS_OpportunityCacheService cache;
    private Map<Id, GS_OpportunityToUpdateAccountAsync.ConsolidatedAccountUpdateAsyncConditions> conditionsMap =
    new Map<Id, GS_OpportunityToUpdateAccountAsync.ConsolidatedAccountUpdateAsyncConditions>();
    private Set<Id> idSetToRun = new Set<Id>();

    public void runOpportunityToUpdateAccountAsyncFunctions(Map<Id, Opportunity> oldOpportunityMap, List<Opportunity> oppList, GS_OpportunityCacheService cache, String context){
        if (!oppList.isEmpty()){
            this.cache = cache;
            GS_OpportunityToUpdateAccountAsync asyncHandler = new GS_OpportunityToUpdateAccountAsync();
            Opportunity oldOpportunity = new Opportunity();
            Boolean oldOppNull = true;
            Map<Id, Account> oppAccountsRev = new GS_OpportunityService().getAccountsForClosedOrRevenueTypeOppty(cache.relatedAccountMap);

            for (Opportunity newOpp : oppList){

                if(!oldOpportunityMap.isEmpty()){
                    oldOpportunity =  oldOpportunityMap.get(newOpp.Id);
                    oldOppNull = false;
                }
                Account thisOppAccount = (cache.relatedAccountMap.containsKey(newOpp.AccountId) ? cache.relatedAccountMap.get(newOpp.AccountId) : new Account());
                Opportunity vOpportunity = this.cache.loadedOpportunityMap.get(newOpp.Id);
                Account oppRevAccount;

                GS_OpportunityToUpdateAccountAsync.ConsolidatedAccountUpdateAsyncConditions condition;
                switch on context {
                    when 'BEFORE_UPDATE'{
                        condition = asyncHandler.validateRecordForAccountProcessesBeforeUpdate(oldOpportunity, newOpp, vOpportunity, thisOppAccount);
                    }
                    when 'AFTER_UPDATE'{
                        oppRevAccount = (oppAccountsRev.containsKey(newOpp.AccountId) ? oppAccountsRev.get(newOpp.AccountId) : new Account());
                        condition = asyncHandler.validateRecordForAccountProcessesAfterUpdate(oldOpportunity, newOpp, thisOppAccount, oppRevAccount, oldOppNull);
                    }
                }
                
                if (condition != null){
                    conditionsMap.put(newOpp.Id, condition);
                    idSetToRun.add(newOpp.Id);
                } 
            }
        }
    }

    public void runOpportunityToUpdateAccountBeforeUpdate(Map<Id, Opportunity> oldOpportunityMap, List<Opportunity> oppList, GS_OpportunityCacheService cache){
        String context = 'BEFORE_UPDATE';
        this.runOpportunityToUpdateAccountAsyncFunctions(oldOpportunityMap, oppList, cache, context);

        if(!idSetToRun.isEmpty()){
            DMLWrapper.doInsert(new GS_OpportunityToUpdateAccountAsync().prepareAsyncRequests(
            JSON.serialize(new GS_OpportunityToUpdateAccountAsync.Options('BEFORE_UPDATE_OPERATIONS', conditionsMap)),
            idSetToRun
            ));
        }
    }

    public void runOpportunityToUpdateAccountAfterUpdate(Map<Id, Opportunity> oldOpportunityMap, List<Opportunity> oppList, GS_OpportunityCacheService cache){
        String context = 'AFTER_UPDATE';
        this.runOpportunityToUpdateAccountAsyncFunctions(oldOpportunityMap, oppList, cache, context);

        if(!idSetToRun.isEmpty()){
            DMLWrapper.doInsert(new GS_OpportunityToUpdateAccountAsync().prepareAsyncRequests(
            JSON.serialize(new GS_OpportunityToUpdateAccountAsync.Options('AFTER_UPDATE_OPERATIONS', conditionsMap)),
            idSetToRun
            ));
        }
    }

    
}
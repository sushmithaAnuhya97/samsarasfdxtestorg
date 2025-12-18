public with sharing class GS_OpportunityNetSuiteService {

    //Replaces: Push Rev, Promo, Rebate, FT to Netsuite
    //* 12/03/2020 Ron (GTMS-1869) beforeInsertOrUpdate (match CloseDate on Rebate to Rev)
    public void pushInfoToNetsuite(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOppList){
        Map<Id,Opportunity> changedOpptyMap = new Map<Id,Opportunity>();
        Map<Id,Opportunity> asyncChangedMap = new Map<Id,Opportunity>();
        Set<Opportunity> oppsToUpdate = new Set<Opportunity>();

        // Check if trigger.newMap is eligible to push to NS
        for(Opportunity opp : newOppList){

            if(this.checkIfShouldPublishToNetSuiteService(oldOppMap, opp)) {
                if (this.checkIfShouldBeAsync(oldOppMap, opp)){
                    asyncChangedMap.put(opp.Id,opp);
                }else if (this.checkIfShouldBeSync(opp)){
                    changedOpptyMap.put(opp.Id,opp);
                }
            }
        }

        if (changedOpptyMap.size() > 0){
            for (Opportunity opp : changedOpptyMap.values()){
                /* Replaces Node 'Trial Opportunity Push NS' */
                if(opp.Type == 'Free Trial Opportunity'|| opp.Type == 'Work Order'){
                    opp.Retry_TO_to_NS__c = true;  // updated to NOT include opp in beforeTrigger context to update list
                }
                /* Replaces Nodes 'Rev Opportunity Push to NS' and 'Promo Opportunity Push to NS' */
                else if(opp.Type == 'Revenue Opportunity' || opp.Type == 'Promo Opportunity'){
                    opp.netsuite_conn__Push_To_NetSuite__c = true; // updated to NOT include opp in beforeTrigger context to update list
                }
            }
        }

        if (asyncChangedMap.size() > 0){
            DMLWrapper.doInsert(new GS_OpportunityNetSuiteServiceAsync().prepareAsyncRequests(
                JSON.serialize(new GS_OpportunityNetSuiteServiceAsync.Options('RELATED_RECORDS_UPDATE')),
                asyncChangedMap.keySet()
            ));
        }
    }

    private Boolean checkIfShouldPublishToNetSuiteService(Map<Id, Opportunity> oldOppMap, Opportunity newOpp){
        Opportunity oldOpp = (oldOppMap != null ? oldOppMap.get(newOpp.Id) : null);
        return (oldOppMap != null
            && (oldOpp == null || newOpp.StageName != oldOpp.StageName)
            && (newOpp.StageName == 'Ready to Ship' || newOpp.StageName == 'Closed Won'));
    }

    private Boolean checkIfShouldBeAsync(Map<Id, Opportunity> oldOppMap, Opportunity newOpp){
        return newOpp.Type == 'Revenue Opportunity' && newOpp.StageName == 'Closed Won'
            && (oldOppMap != null
                && (oldOppMap.get(newOpp.Id).StageName != newOpp.StageName));
    }

    private Boolean checkIfShouldBeSync(Opportunity newOpp){
        return (newOpp.StageName == 'Ready to Ship');
    }
}
public with sharing class GS_OpportunitySlackService {
    
    // Replaces: Post Closed Won to Slack
    public void postToSlack(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOppList){
        Set<Id> applicableOpptyIds = new Set<Id>();
        for(Opportunity opp : newOppList){
            //System.debug('ACV bookings: ' + opp.ACV_Bookings__c + ' Express Flag: ' + opp.Express_Flag__c);
            if(this.stageHasChanged(oldOppMap, opp) && this.shouldPublishToSlack(opp)){
                applicableOpptyIds.add(opp.Id);
            }
        }

        if (applicableOpptyIds.size() > 0){
            DMLWrapper.doInsert(new GS_OpportunitySlackServiceAsync().prepareAsyncRequests(
                JSON.serialize(new GS_OpportunitySlackServiceAsync.Options('POST_TO_SLACK')),
                applicableOpptyIds
            ));
        }
    }

    private Boolean stageHasChanged(Map<Id, Opportunity> oldOppMap, Opportunity newOpp){
        return (oldOppMap != null && oldOppMap.get(newOpp.Id).StageName != newOpp.StageName);
    }

    private Boolean shouldPublishToSlack(Opportunity newOpp){
        return ( newOpp.StageName == 'Ready to Ship' && newOpp.Type == 'Revenue Opportunity'
        && ((newOpp.ACV_Bookings__c > 833 && newOpp.Express_Flag__c == 1)
            || (newOpp.ACV_Bookings__c > 6250 && newOpp.Express_Flag__c == 0)
            || (newOpp.ACV_Bookings__c > 250 && newOpp.Express_Flag__c == 0)
            || (newOpp.ACV_Bookings__c > 1250 && newOpp.Configuration_Segment__c == 'Non Express')
            || newOpp.Industrial_Oppty__c
        ));
    }
}
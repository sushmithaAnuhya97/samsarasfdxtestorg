/**
 * Created by vikasmishra on 2021-09-16.
 */

public with sharing class GS_DisconnectTrialOppService implements IService {
    SamsaraLoggerService thisLoggerService = new SamsaraLoggerService();
    Map<Id, Opportunity> targetOpportunityIdsForTrialDisconnections = new Map<Id, Opportunity>();
    Map<Id, Opportunity> targetOpportunitiesToUpdateDisconnectionsForTrials = new Map<Id, Opportunity>();
    @TestVisible
    Boolean transactionTypeAsync = true;
    public void shouldRunInSyncMode(){
        transactionTypeAsync = false;
    }

    public void processTrialDisconnectionsOnOpportunityDelete(Map<Id, Opportunity> oldMap){
        collectTargetOpportunitiesForDisconnections(oldMap);
        getTrialOpportunitiesFromTrialResolutionIds(targetOpportunityIdsForTrialDisconnections.keySet());
        if(transactionTypeAsync){
            invokeAsyncTrailOpportunityUpdateProcess();
        }
        else{
            invokeSyncTrailOpportunityUpdateProcess();
        }

    }
    public void updateDisconnectionsForTrials(Map<Id, Opportunity> trialOppMap){
        new DisconnectTrialOppService(trialOppMap).updateDisconnectionsForTrials();
    }
    private void invokeAsyncTrailOpportunityUpdateProcess() {
        DMLWrapper.doInsert (
                (List<SObject>) new GS_AsyncDisconnectTrialOppService()
                        .prepareAsyncRequests(
                                targetOpportunitiesToUpdateDisconnectionsForTrials.keySet()
                        )
        );
    }

    private void invokeSyncTrailOpportunityUpdateProcess() {
        new DisconnectTrialOppService(
                targetOpportunitiesToUpdateDisconnectionsForTrials
        ).updateDisconnectionsForTrials();
    }



    private void getTrialOpportunitiesFromTrialResolutionIds(Set<Id>ids){
        targetOpportunitiesToUpdateDisconnectionsForTrials = new Map<Id, Opportunity>(
                                                                    new GS_OpportunitySelector(true)
                                                                            .checkFatalError()
                                                                            .getTrialOpportunitiesFromTrialResolutionIds(ids)
                                                            );
    }



    private void collectTargetOpportunitiesForDisconnections(Map<Id, Opportunity> opportunitiesByIds) {
        if( opportunitiesByIds == null || opportunitiesByIds.isEmpty()){
            throw new DisconnectTrialOppServiceException(
                    'No element found for Disconnections. This method has been called from before delete context'
            );
        }

        for(Opportunity thisOpp : opportunitiesByIds.values()){
            if(shouldDoTrialDisconnections(thisOpp)){
                collectTargetOpportunitiesIdsForDisconnections(thisOpp);
            }
        }
    }

    private void collectTargetOpportunitiesIdsForDisconnections(Opportunity thisOpp) {
        targetOpportunityIdsForTrialDisconnections.put(thisOpp.Id, thisOpp);
    }

    private Boolean shouldDoTrialDisconnections(Opportunity oldOpp) {
        return oldOpp.Type == 'Revenue Opportunity'
                || oldOpp.Type == 'Free Trial Return'
                || oldOpp.Type == 'Revenue Opportunity - Bill Only';
    }

    public class DisconnectTrialOppService implements IInterService{
        public Map<Id, Opportunity> trialOpportunitiesMap = new Map<Id, Opportunity>();

        public DisconnectTrialOppService(Map<Id, Opportunity> trialOpportunitiesMap ){
            this.trialOpportunitiesMap = trialOpportunitiesMap;
        }

        public void updateDisconnectionsForTrials(){
            for (Opportunity thisTrialOpp : trialOpportunitiesMap.values()) {
                // Clear pointer. Status will be set on resulting update trigger.
                thisTrialOpp.TrialResolutionOppty__c = Null;
                DMLWrapper.doUpdate(thisTrialOpp, new List<SObjectField>{
                        Opportunity.TrialResolutionOppty__c
                });
            }
        }
    }

    public interface IService{
        void shouldRunInSyncMode();
        void processTrialDisconnectionsOnOpportunityDelete(Map<Id, Opportunity> oldMap);
        void updateDisconnectionsForTrials(Map<Id, Opportunity> trialOppMap);
    }

    public interface IInterService{
        void updateDisconnectionsForTrials();
    }
    public class DisconnectTrialOppServiceException extends Exception{}
}
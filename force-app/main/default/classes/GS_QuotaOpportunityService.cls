/**
 * Created by vikasmishra on 2021-09-16.
 */

public with sharing class GS_QuotaOpportunityService implements IService{

    SamsaraLoggerService thisLoggerService = new SamsaraLoggerService();
    public Map<Id, Opportunity> targetOpportunityIdsForQuotaDeletion = new Map<Id, Opportunity>();
    @TestVisible
    Boolean transactionTypeAsync = true;

    public void shouldUpdateInSync(){
        transactionTypeAsync = false;
    }

    public void processQuotaOpportunityDeletion(Map<Id, Quota_Opportunity__c> quotaOpportunitiesByIds){
        new QuotaOpportunityService(quotaOpportunitiesByIds)
                .processQuotaOpportunityDeletion();
    }
    public void processQuotaOpportunityDeletion(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOppList){
        collectTargetOpportunities(oldOppMap, newOppList);
        if(transactionTypeAsync){
            invokeAsyncQuotaDeletionProcess();
        }
        else{
            invokeQuotaDeletionProcess();
        }

    }

    private void invokeQuotaDeletionProcess() {
        processQuotaOpportunityDeletion(
                new Map<Id, Quota_Opportunity__c>(
                        getQuotaOpportunitiesFromOppIds(
                                targetOpportunityIdsForQuotaDeletion.keySet()
                        )
                )
        );
    }
    private List<Quota_Opportunity__c> getQuotaOpportunitiesFromOppIds(Set<Id> ids) {
        return new GS_QuotaOpportunitySelector(true)
                .checkFatalError()
                .getQuotaOpportunitiesFromOpportunityIds(new Set<Id>(ids));
    }

    private void invokeAsyncQuotaDeletionProcess() {
        DMLWrapper.doInsert (
                (List<SObject>) new GS_AsyncQuotaOpportunityDeletionService()
                        .prepareAsyncRequests(
                                targetOpportunityIdsForQuotaDeletion.keySet()
                        )
        );
    }

    private void collectTargetOpportunities(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOppList) {
        Boolean isUpdate = oldOppMap != null && !oldOppMap.isEmpty();
        for(Opportunity thisOpp : newOppList){
            Opportunity oldOpp;
            if(isUpdate){
                if(oldOppMap.containsKey(thisOpp.Id)){
                    oldOpp = oldOppMap.get(thisOpp.Id);
                }
                else{
                    throw new GS_QuotaOpportunityServiceException('No element found in old Map.');
                }
            }
            else {
                throw new GS_QuotaOpportunityServiceException('Old Map is null. This method is only getting called in After Update Context.');
            }
            if (shouldDeleteQuotaOpportunities(thisOpp, oldOpp)){
                collectTargetOpportunityIds(thisOpp);
            }
        }
    }

    private void collectTargetOpportunityIds(Opportunity thisOpp) {
        targetOpportunityIdsForQuotaDeletion.put(thisOpp.Id, thisOpp);
    }

    private Boolean shouldDeleteQuotaOpportunities(Opportunity newOpp, Opportunity oldOpp) {
        return oldOpp.IsWon == true
                && newOpp.IsWon == false;
    }

    public class QuotaOpportunityService implements IInternalService{
        public Map<Id, Quota_Opportunity__c> mapOfQuotaOpportunitiesByIds = new Map<Id, Quota_Opportunity__c>();
        public QuotaOpportunityService( Map<Id, Quota_Opportunity__c> mapOfQuotaOpportunitiesByIds){
            this.mapOfQuotaOpportunitiesByIds = mapOfQuotaOpportunitiesByIds;
        }

        public void processQuotaOpportunityDeletion(){
            DMLWrapper.doDelete(mapOfQuotaOpportunitiesByIds.values());
        }

    }

    public interface IService{
        void shouldUpdateInSync();
        void processQuotaOpportunityDeletion(Map<Id, Quota_Opportunity__c> quotaOpportunitiesByIds);
        void processQuotaOpportunityDeletion(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOppList);
    }

    public interface IInternalService{
        void processQuotaOpportunityDeletion();
    }
    public class GS_QuotaOpportunityServiceException extends Exception{}


}
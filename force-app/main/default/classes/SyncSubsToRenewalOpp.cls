/**
* Created By : Satya Dodda
* @Date Mar 24, 2022
* Test Class: SyncSubsToRenewalOppTest 
* @description : This class will be responsible for handling Async Actions on Contract
* 
**/
public with sharing class SyncSubsToRenewalOpp {
    @InvocableMethod
    public static void syncSubsToRenewalOpps(List<String> contractIds) {
        Set<Id> contIds = new Set<Id>();
        for(Id recordId : contractIds) {
            contIds.add(recordId);
        }
        if(!contIds.isEmpty()) {
            insert new UpdateContractServiceAsync().prepareAsyncRequests(
                JSON.serialize(new UpdateContractServiceAsync.Options('uncheckContract')), 
                contIds
            );
        }
    }
}
/**
* Created By : Groundswell - Flávio Contini
* @Date August 12, 2021
* 
* @description : This class will be responsible for handling all Trial Opportunity Operations
* SFA-10
* 
**/
public with sharing class GS_TrialOpportunityService {
    
    public void runAfterInsertFunctions(List<Opportunity> newOppList){
        Set<Id> asyncRecordsId = new Set<Id>();
        
        GS_TrialOpportunityServiceAsync asyncHandler = new GS_TrialOpportunityServiceAsync();
        for (Opportunity opp : newOppList){
            if (asyncHandler.shouldRunAsyncMethodsForRecord(opp))
                asyncRecordsId.add(opp.Id);
        }
        
        if (!asyncRecordsId.isEmpty()){
            DMLWrapper.doInsert(asyncHandler.prepareAsyncRequests(
                JSON.serialize(new GS_TrialOpportunityServiceAsync.Options('AFTER_INSERT')),
                asyncRecordsId
            ));
        }
    }
    
    public void handleRevenueUpdate(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOpportunityList) {
        
        Set<Id> opptyIds = new Set<Id>();
        Map<Id, Boolean> unclosedTrialOpptyErrorConditionMap = new Map<Id, Boolean>();
        
        // Here's the logic from what was originally the handleRevenueUpdate method combined with the error handling from the trigger
        // Check if we have any opps that meet query criteria. This should be broken out into a method of the opp helper class.
        Boolean isunclosedTrialOppty = FALSE;
        
        for(Opportunity oppty : newOpportunityList) {
            if((oppty.type == 'Revenue Opportunity' || oppty.type == 'Revenue Opportunity - Bill Only') 
               && oppty.StageName != oldOppMap.get(oppty.Id).StageName) {
                opptyIds.add(oppty.Id);
                if(oppty.Probability == 0 && oldOppMap.get(oppty.Id).Probability > 0) isunclosedTrialOppty = TRUE;
                unclosedTrialOpptyErrorConditionMap.put(oppty.Id, isunclosedTrialOppty); 
            }
        }
        
        if(!opptyIds.isEmpty()) {
            DMLWrapper.doInsert(new GS_TrialOpportunityServiceAsync().prepareAsyncRequests(
                JSON.serialize(new GS_TrialOpportunityServiceAsync.Options('BEFORE_UPDATE_OPERATIONS', unclosedTrialOpptyErrorConditionMap)),
                opptyIds
            ));
        }
    }
    
    
    public void handleReturnCreation(List<Id> opportunityIdList){
        if (!opportunityIdList.isEmpty()){
            DMLWrapper.doInsert(new GS_TrialOpportunityServiceAsync().prepareAsyncRequests(
                JSON.serialize(new GS_TrialOpportunityServiceAsync.Options('RETURN_CREATION')),
                new Set<Id>(opportunityIdList)
            ));
        }
    }
    
    /**
* Takes a list of Trial oppties with Stage or Resolution Pointer updates, and updates Trial Status in place
* @param Map<Id,Opportunity> oldOppMap (Trigger.oldMap)
* @param List<Opportunity> newOppList (Trigger.new)
* 
* //QUESTION: How to improve two FORs in this method, as specified in the spreadsheet. 
*/
    public void handleTrialUpdate(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOppList) {    
        List<Id> trialResolutionOppIdSet = new List<Id>();
        List<Opportunity> trialUpdateList = new List<Opportunity>();
        for (Opportunity o : newOppList) {
            if(o.Type == 'Free Trial Opportunity') {
                if (o.TrialResolutionOppty__c == NULL) {
                    // No resolution pointer, set status based on Stage
                    if (o.StageName == 'Closed Won') { 
                        o.Trial_Status__c = 'Open';
                    } else {
                        o.Trial_Status__c = 'Not Shipped';
                    }
                } else if (o.StageName != 'Closed Won') {
                    // ignore resolution pointer if trial hasn't shipped
                    o.Trial_Status__c = 'Not Shipped';
                    
                } else if(oldOppMap != NULL) {
                    if( o.TrialResolutionOppty__c != oldOppMap.get(o.Id).TrialResolutionOppty__c ||
                       o.StageName != oldOppMap.get(o.Id).StageName) {
                           trialUpdateList.add(o);
                           trialResolutionOppIdSet.add(o.TrialResolutionOppty__c);
                       }
                } else {
                    trialUpdateList.add(o);
                    trialResolutionOppIdSet.add(o.TrialResolutionOppty__c);
                }
            }
            
            
            // Groundswell : Tanuj - WFlow Rule - Re Open Trial when End Date Exceeded
            if(oldOppMap != NULL)  {
                if((oldOppMap.get(o.Id).Trial_Number_of_Days_Left__c != o.Trial_Number_of_Days_Left__c
                    || oldOppMap.get(o.Id).Type != o.Type)
                   && (o.Trial_Number_of_Days_Left__c < 0 
                       && o.Type == 'Free Trial Opportunity')
                  ){
                      // Re Open Trial                      
                      o.Trial_Status__c = 'Open';
                  }
            }
        }
        
        Map<ID,Opportunity> resolutions;
        if (trialResolutionOppIdSet != null) {        
            resolutions = new Map<ID,Opportunity>(
                (new GS_OpportunitySelector(false)).getOppForResolutionById(trialResolutionOppIdSet)
            );
        }
        
        for (Opportunity o : trialUpdateList) {
            Opportunity res = resolutions.get(o.TrialResolutionOppty__c);
            if (res != Null) {
                if(o.StageName == 'Closed Won'){
                    o.Trial_Status__c = 'Open';
                }
                
                String newStatus = this.getStatusFromResolution(res);
                o.Trial_Status__c = (String.isNotBlank(newStatus) ? newStatus : o.Trial_Status__c);
            }
        }
    }
    
    /**
* Determines the status from Type, Probability and StageName.
* @param Opportunity opp
* @return String Status
*/
    public String getStatusFromResolution(Opportunity res) {
        // Determines trial status based on resolution state        
        if (res.Type == 'Revenue Opportunity' || res.Type == 'Revenue Opportunity - Bill Only') {
            if (res.StageName == 'Closed Won') {
                return 'Purchased';
            } 
            else{
                return null;
            }
        }else if (res.Type == 'Free Trial Return') {                
            if (res.Probability == 100) {
                return 'Returned';
            } else if (res.Probability > 0) {
                return 'Return In Process';
            }
        }    
        return 'Open';    
    }
    
  /*
   *  Copied over this method to Async - GS_TrialOpportunityServiceAsync
   *  public void welcomeTrialKitProductsOnClosing(List<Opportunity> newOpptyList, GS_OpportunityCacheService cache){
        GS_TrialOpportunityServiceAsync asyncHandler = new GS_TrialOpportunityServiceAsync();
        
        Set<Id> welcomeTrialKitAsyncList = new Set<Id>();
        List<Account> accountsToUpdate = new List<Account>();
        for(Opportunity opp : newOpptyList) {
            // Check if the Opportunity qualifies for a Welcome/Trial Kit, if not skip to the next opp
            if (asyncHandler.shouldRunAsyncMethodsForRecord(opp)) welcomeTrialKitAsyncList.add(opp.Id);
        }
        
        if (welcomeTrialKitAsyncList.size() > 0){
            DMLWrapper.doInsert(new GS_TrialOpportunityServiceAsync().prepareAsyncRequests(
                JSON.serialize(new GS_TrialOpportunityServiceAsync.Options('RETURN_CREATION')),
                welcomeTrialKitAsyncList
            ));
        }
    }*/
    
    
    /**
* This Method executes below methods for Trial Oppty:
* handleReturnUpdate
* welcomeTrialKitProductsOnClosing
*/
    public void consolidatedTrialUpdate(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOpptyList) {
        // Takes a list of Return oppties with Stage changes, and updates any trial oppties that point to them
        Map<Id, Boolean> unclosedTrialOpptyErrorConditionMap = new Map<Id, Boolean>();
        List<Opportunity> updates = new List<Opportunity>();
        List<Opportunity> returnUpdates = new List<Opportunity>();
        Set<Id> opptyIdsSet = new Set<Id>();
        Boolean isFreeTrialOppty = FALSE;
        for(Opportunity o : newOpptyList) {
            opptyIdsSet.add(o.Id);
            if((o.type == 'Free Trial Return') 
               && o.StageName != oldOppMap.get(o.Id).StageName) {
                isFreeTrialOppty = TRUE;
            }
              unclosedTrialOpptyErrorConditionMap.put(o.Id, isFreeTrialOppty);
        }
        
        if (!opptyIdsSet.isEmpty()){
            DMLWrapper.doInsert(new GS_TrialOpportunityServiceAsync().prepareAsyncRequests(
                JSON.serialize(new GS_TrialOpportunityServiceAsync.Options('AFTER_UPDATE_OPERATIONS',unclosedTrialOpptyErrorConditionMap)),
                opptyIdsSet
            ));
        }
    }
    
    
}
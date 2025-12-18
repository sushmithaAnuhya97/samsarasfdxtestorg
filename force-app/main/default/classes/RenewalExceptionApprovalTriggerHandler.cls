/*
*********************************************************
Apex Class Name    : RenewalExceptionApprovalTriggerHandler
Test Class Name    : RenewalExceptionApprovalHandlerTest
Created Date       : Aug 28, 2024
@description       : This is class is used to handle field updates after approval process or record insertion
@author            : Gourav Goyal
Modification Log:
Ver   Date         Author                               Modification
1.0   28-08-2024   Gourav Goyal                        Initial Version
*********************************************************
*/
public with sharing class RenewalExceptionApprovalTriggerHandler extends TriggerHandler{
    private Map<Id, Renewal_Exception_Approval__c> oldRenewalExceptionMap;
    private Map<Id, Renewal_Exception_Approval__c> newRenewalExceptionMap;
    private List<Renewal_Exception_Approval__c> newRenewalExceptionList;
    public static Boolean isProcessing = false;
    public RenewalExceptionApprovalTriggerHandler(){
        this.newRenewalExceptionList = (List<Renewal_Exception_Approval__c>) Trigger.new;
        this.oldRenewalExceptionMap = (Map<Id, Renewal_Exception_Approval__c >) Trigger.oldMap;
        this.newRenewalExceptionMap = (Map<Id, Renewal_Exception_Approval__c >) Trigger.newMap;
    }
    public override void beforeInsert() {
        Set<Id> opportunityIds = new Set<Id>();
        Set<Id> accountExecutiveIds = new Set<Id>();
        Map<Id,Set<Id>> opportunityIdsToAccountExecutiveIds = new Map<Id,Set<Id>>();
        Set<String> closeDateYears = new Set<String>();

        for(Renewal_Exception_Approval__c appoval : newRenewalExceptionList){
            opportunityIds.add(appoval.Opportunity__c);
            accountExecutiveIds.add(appoval.Account_Executive__c);
        }
        Map<Id,Opportunity> opportunities = new Map<Id,Opportunity>([SELECT ID , CloseDate,SBQQ__RenewedContract__c FROM Opportunity WHERE ID IN :opportunityIds]);
        

        for(Opportunity opp : opportunities.values()){
            String currentYear;
            Integer currentMonth = opp.CloseDate.month();
            if(currentMonth == 1){
                currentYear = String.valueOf(opp.CloseDate.year());
            }
            else{
                currentYear = String.valueOf(opp.CloseDate.year() + 1);
            }
            closeDateYears.add(currentYear);
        }

        List<Period> quartersForCurrentYear = [SELECT FiscalYearSettings.Name,StartDate, EndDate , FullyQualifiedLabel FROM Period WHERE Type = 'Quarter' AND 
                                              FiscalYearSettings.Name IN :closeDateYears];

        List<OpportunitySplit> opportunitySplits = [Select Id,SplitOwnerId,OpportunityId from OpportunitySplit WHERE SplitType.DeveloperName='Overlay' AND 
                                                    OpportunityId =:opportunityIds AND SplitOwnerId = :accountExecutiveIds];

        Map<Id,User> userIdToManager = new Map<Id,User>([SELECT ID , ManagerId FROM User WHERE ID IN :accountExecutiveIds]);

        
        for(OpportunitySplit split : opportunitySplits){
            if(opportunityIdsToAccountExecutiveIds.containsKey(split.OpportunityId)){
                Set<Id> existingAEs = opportunityIdsToAccountExecutiveIds.get(split.OpportunityId);
                existingAEs.add(split.SplitOwnerId);
                opportunityIdsToAccountExecutiveIds.put(split.OpportunityId,existingAEs);
            }
            else{
                Set<Id> newAEs = new Set<Id>();
                newAEs.add(split.SplitOwnerId);
                opportunityIdsToAccountExecutiveIds.put(split.OpportunityId,newAEs);
            }
        }

        for(Renewal_Exception_Approval__c approval : newRenewalExceptionList){
            Opportunity opportunity = opportunities.containsKey(approval.Opportunity__c) ? opportunities.get(approval.Opportunity__c) : null;
            if(opportunity != null){
            Boolean isRenewalOpp = opportunity.SBQQ__RenewedContract__c != null ;
                if(isRenewalOpp && (!opportunityIdsToAccountExecutiveIds.containsKey(approval.Opportunity__c))){
                    approval.addError('Warning: The person in "AE Name" is not currently part of the opportunity split for this opportunity. Please confirm that you have entered the correct name in this field before proceeding.');
                }
                else if(opportunityIdsToAccountExecutiveIds.containsKey(approval.Opportunity__c)){
                    if(isRenewalOpp && (!opportunityIdsToAccountExecutiveIds.get(approval.Opportunity__c).contains(approval.Account_Executive__c))){
                        approval.addError('Warning: The person in "AE Name" is not currently part of the opportunity split for this opportunity. Please confirm that you have entered the correct name in this field before proceeding.');
                    }
                }
                for(Period quarter : quartersForCurrentYear){
                    Date closeDate = opportunities.containsKey(approval.Opportunity__c) ? opportunities.get(approval.Opportunity__c).CloseDate : null;
                    String fiscalYearForOpp =  closeDate.month() == 1 ? String.valueOf(closeDate.year()) : String.valueOf(closeDate.year() + 1);
                    if(fiscalYearForOpp == quarter.FiscalYearSettings.Name){
                        if(closeDate >= quarter.StartDate && closeDate <= quarter.EndDate){
                            approval.Fiscal_Quarter__c = quarter.FullyQualifiedLabel;
                            approval.Fiscal_Year__c = fiscalYearForOpp;
                            break;
                        }
                    }
                }
                approval.Account_Executive_Manager__c = userIdToManager.containsKey(approval.Account_Executive__c) ? userIdToManager.get(approval.Account_Executive__c).ManagerId : null;
            }
        }
    }
    
    public override void afterInsert(){
    }


    public override void beforeUpdate() {
        if(isProcessing){
            return;
        }
        isProcessing = true;
        Integer currentMonth = Date.today().month();
        String currentYear;
        if(currentMonth == 1){
            currentYear = String.valueOf(System.today().year());
        }
        else{
            currentYear = String.valueOf(System.today().year() + 1);
        }
        Boolean isInSamePeriod = false;
        List<Period> periodsForCurrentYear = [SELECT FiscalYearSettings.Name,StartDate, EndDate
                                                FROM Period WHERE Type = 'Month' and 
                                                (FiscalYearSettings.name = :currentYear)];

        Map<Id,Date> renewalExceptionIdToOppCloseDate = new Map<Id,Date>();
        Map<Id,Renewal_Exception_Approval__c> renewalApprovals = new Map<Id,Renewal_Exception_Approval__c>([SELECT ID ,Status__c, Sales_Comp_Manual_Adjustment__c ,Approved_Date__c, Opportunity__r.CloseDate,Opportunity__r.Id,Account_Executive__c,
                                                                Opportunity__r.Type,Opportunity__r.Returning_Opportunity__c FROM Renewal_Exception_Approval__c 
                                                                WHERE ID IN :newRenewalExceptionMap.keySet()]);

        Set<Id> accountExecutiveIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        Set<Id> rebateOpportunityIds = new Set<Id>();
        Set<Id> returnOpportunityIds = new Set<Id>();


        for(Renewal_Exception_Approval__c newApproval : newRenewalExceptionMap.values()){
            Renewal_Exception_Approval__c renewal = renewalApprovals.containsKey(newApproval.Id) ? renewalApprovals.get(newApproval.Id) : null;
            if(renewal == null){
                continue;
            }
            if(newApproval.Status__c == 'Approved' && oldRenewalExceptionMap.get(newApproval.Id).Status__c != newRenewalExceptionMap.get(newApproval.Id).Status__c){
                for (Period period : periodsForCurrentYear) {
                    Date today = Date.today();
                    accountExecutiveIds.add(renewal.Account_Executive__c);
                    opportunityIds.add(renewal.Opportunity__r.Id);
                    if(renewal.Opportunity__r.Type == 'Rebate'){
                        rebateOpportunityIds.add(renewal.Opportunity__r.Id);
                        if(renewal.Opportunity__r.Returning_Opportunity__c != null){
                            returnOpportunityIds.add(renewal.Opportunity__r.Returning_Opportunity__c);
                        }
                    }
                    if ((today >= period.StartDate && today <= period.EndDate) &&
                        (renewal.Opportunity__r.CloseDate >= period.StartDate && renewal.Opportunity__r.CloseDate <= period.EndDate)) {
                        newApproval.Sales_Comp_Manual_Adjustment__c = false;
                        newApproval.Approved_Date__c = today;
                        break;
                    }
                    else{
                        newApproval.Sales_Comp_Manual_Adjustment__c = true;
                        newApproval.Approved_Date__c = today;
                    }
                }
            }
        }

        if(accountExecutiveIds.isEmpty() || opportunityIds.isEmpty()){
            return;
        }
        
        List<OpportunitySplit> opportunitySplits = [Select id,SplitPercentage,SplitNote,Split_ACV__c,SplitType.DeveloperName,OpportunityId,Opportunity.Type,Opportunity.Returning_Opportunity__r.OwnerId from 
                                                    OpportunitySplit WHERE SplitOwnerId IN :accountExecutiveIds  AND OpportunityId = :opportunityIds
                                                    AND SplitType.DeveloperName = 'Overlay'];

        List<Opportunity> opportunities = new List<Opportunity>();

        List<OpportunitySplit> splitsToBeUpdated = new List<OpportunitySplit>();
        List<OpportunitySplit> splitsToBeDeleted = new List<OpportunitySplit>();

        
        for (OpportunitySplit split : opportunitySplits) {
            if(split.Opportunity.Type == 'Rebate'){
                splitsToBeDeleted.add(split);
            }
            else{
                split.SplitPercentage = 0;
                split.Split_ACV__c = 0;
                split.SplitNote = 'A4L Approved Exception '+DateTime.now().format('MMM dd yyyy');
                splitsToBeUpdated.add(split);
            }
        }

        String userId = System.label.Enterprise_Strategic_Mexico_Canada_AVP;

        User user;
        if(!String.isBlank(userId)){
         user = [Select id,isActive from user where Id = :userId];
        }

        if(user != null && user.isActive == true){
            for(String returnOppId : returnOpportunityIds) {
                    Opportunity newOpp = new Opportunity();
                    newOpp.Id = returnOppId;
                    newOpp.Overwrite_Validation_Rule__c = true;
                    newOpp.OwnerId = user.Id;
                    opportunities.add(newOpp);
                }
        }

        for (String oppId : opportunityIds) {
            if(rebateOpportunityIds.contains(oppId)){
                continue;
            }
            Opportunity newOpp = new Opportunity();
            newOpp.Id = oppId;
            newOpp.Exclude_from_Forecast__c = true;
            opportunities.add(newOpp);
        }
        
        if(splitsToBeUpdated.size() > 0){
            update opportunitySplits;
        }
        if(splitsToBeDeleted.size() > 0){
            delete splitsToBeDeleted;
        }
        if(opportunities.size() > 0){
            byPassTriggers();
            update opportunities;
        }
    }

    public override void afterUpdate() {  
    }

    public static void byPassTriggers(){
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        TriggerHandler.bypass('ContractTriggerHandler');
        TriggerHandler.bypass('GS_ContactTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        SBQQ.TriggerControl.disable();
    }
}
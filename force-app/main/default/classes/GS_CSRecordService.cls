/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 10, 2021
*
* @description : This class will be responsible for handling all CS Record Operations
* SFA-11
*
**/

public inherited sharing class GS_CSRecordService {
    gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    gslib_ILogger thisLogger = thisModuleLogger.getLogger();
    public GS_CSRecordService() {
        
    }
    
    public void createCSRecords(List<Account> newAccountList){
        Set<Id> accountRecordsIds = (new Map<Id,Account>(newAccountList)).keySet();
        
        //insert csRecords;
        DMLWrapper.doInsert(new GS_CS_RecordServiceAsync().prepareAsyncRequests(
            JSON.serialize(new GS_CS_RecordServiceAsync.Options('Insert')), 
            accountRecordsIds));
    }
    
    public void stampAccountInfoOnCsRecord(Map<Id, Account> oldAccountMap, List<Account> newAccountList) {
        
        Map<Id, Account> accountsToUpdate = new Map<Id,Account>();
        Set<Id> csAccountUpdates = new Set<Id>();
        Set<Id> accountsToQuery = new Set<Id>();
        for (Account newAccount : newAccountList) {
            Account oldAccount = oldAccountMap.get(newAccount.Id);
            
            if((newAccount.Key_Stakeholder_for_CSM__c != oldAccount.Key_Stakeholder_for_CSM__c) ||
               (newAccount.Key_Value_Points__c != oldAccount.Key_Value_Points__c) ||
               (newAccount.Upsell_Opportunity_Products__c != oldAccount.Upsell_Opportunity_Products__c) ||
               (newAccount.AE_to_CSM_handoff_notes__c != oldAccount.AE_to_CSM_handoff_notes__c) ||
               (newAccount.Preparedness_Rating__c != oldAccount.Preparedness_Rating__c) ||
               (newAccount.Self_install_or_Vendor__c != oldAccount.Self_install_or_Vendor__c) ||
               (newAccount.Did_they_Trial__c != oldAccount.Did_they_Trial__c) ||
               (newAccount.Feature_commits_CSM__c != oldAccount.Feature_commits_CSM__c) ||
               (newAccount.Pain_Points_Objections_during_the_trial__c != oldAccount.Pain_Points_Objections_during_the_trial__c) ||
               (newAccount.CS_POC_Email_Address__c != oldAccount.CS_POC_Email_Address__c) ||
               (newAccount.CS_POC_First_Name__c != oldAccount.CS_POC_First_Name__c) ||
               //(GTMS-3070) Create Cs Record in the Update Transaction - Anil Bogadi
               (newAccount.Pre_Sale_IC__c != oldAccount.Pre_Sale_IC__c) ||
               (newAccount.First_Purchase_Value__c != oldAccount.First_Purchase_Value__c && oldAccount.First_Purchase_Value__c == null) ||
               (newAccount.SIC__c != oldAccount.SIC__c) ||
               (newAccount.First_Purchase_Date__c != null && oldAccount.First_Purchase_Date__c != newAccount.First_Purchase_Date__c)){
                   csAccountUpdates.add(newAccount.Id);
               }
        }
        if(!csAccountUpdates.isEmpty()){
            //Update csRecords;
            DMLWrapper.doInsert(new GS_CS_RecordServiceAsync().prepareAsyncRequests(
                JSON.serialize(new GS_CS_RecordServiceAsync.Options('Upsert')), 
                csAccountUpdates));	
        }
    }   
    
    
    
    
    public void deleteCSRecords(List<Account> newAccountList) {
        
        if(!newAccountList.isEmpty()){
            Set<Id> accountIds = new Set<Id>();
            List<CS_Record__c> csRecords = new List<CS_Record__c>();
            for(Account account : newAccountList){
                accountIds.add(account.Id);
            }
            csRecords = new GS_CS_RecordSelector(true).checkFatalError().getCSRecordsByAccountIds(new List<Id>(accountIds));
            if(!csRecords.isEmpty()) {
                Set<Id> csRecordsIds = (new Map<Id,CS_Record__c>(csRecords)).keySet();
                //delete csRecords;
                
                DMLWrapper.doInsert(new GS_CS_RecordServiceAsync().prepareAsyncRequests(
                    JSON.serialize(new GS_CS_RecordServiceAsync.Options('Delete')), 
                    csRecordsIds));
            }
        }        
    }
    
}
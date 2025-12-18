/*
 * Class Created - @Harsha 
 * Test Class - CSRecordHelperTests
 * 8/03/20 Harsha - (GTMS-1073)
 * 1/14/2021 Fields have been commnets as part of deprication of account fields GTMS-2483
 */
public class CSRecordHelper { 
     
    public static void afterUpdateOperations(Map<Id, CS_Record__c> oldCSMap, Map<Id, CS_Record__c> newCSMap){
        List<sObject> updatedRecords = new List<sObject>();
        List<Id> accountIds = new List<Id>();
        Map<Id, Account> queriedAccounts;
            
        for(CS_Record__c newRecord : newCSMap.values()){
            accountIds.add(newRecord.Account__c);
        }
        
        if(accountIds.size() > 0){
            queriedAccounts = new Map<Id, Account>([SELECT Id, Key_Stakeholder_for_CSM__c, Key_Value_Points__c, Upsell_Opportunity_Products__c, 
                                                          AE_to_CSM_handoff_notes__c, Preparedness_Rating__c, Self_install_or_Vendor__c, 
                                                          Did_they_Trial__c, Feature_commits_CSM__c, Pain_Points_Objections_during_the_trial__c,
                                                          CS_POC_First_Name__c, CS_POC_Email_Address__c
                                                FROM Account 
                                                WHERE Id IN: accountIds]);
        
            for(CS_Record__c newRecord : newCSMap.values()){
                CS_Record__c oldRecord = oldCSMap.get(newRecord.Id);
                Account relatedAccount = queriedAccounts.get(newRecord.Account__c);
                if(relatedAccount != null){  //GTMS-7366 : Added Null check on Account
                    Account updateAccount = new Account(id = relatedAccount.Id);
                    Boolean isChanged = false;
                    if(isChanged(newRecord, oldRecord, Schema.CS_Record__c.Key_Stakeholder_for_CSM__c) && newRecord.Key_Stakeholder_for_CSM__c != relatedAccount.Key_Stakeholder_for_CSM__c){
                        updateAccount.Key_Stakeholder_for_CSM__c = newRecord.Key_Stakeholder_for_CSM__c;
                        isChanged = true;
                    }
                    if(isChanged(newRecord, oldRecord, Schema.CS_Record__c.Key_Value_Points__c) && newRecord.Key_Value_Points__c != relatedAccount.Key_Value_Points__c){
                        updateAccount.Key_Value_Points__c = newRecord.Key_Value_Points__c;
                        isChanged = true;
                    }
                    if(isChanged(newRecord, oldRecord, Schema.CS_Record__c.Upsell_Opportunity_Products__c) && newRecord.Upsell_Opportunity_Products__c != relatedAccount.Upsell_Opportunity_Products__c){
                        updateAccount.Upsell_Opportunity_Products__c = newRecord.Upsell_Opportunity_Products__c;
                        isChanged = true;
                    }
                    if(isChanged(newRecord, oldRecord, Schema.CS_Record__c.AE_to_CSM_handoff_notes__c) && newRecord.AE_to_CSM_handoff_notes__c != relatedAccount.AE_to_CSM_handoff_notes__c){
                        updateAccount.AE_to_CSM_handoff_notes__c = newRecord.AE_to_CSM_handoff_notes__c;
                        isChanged = true;
                    }
                    if(isChanged(newRecord, oldRecord, Schema.CS_Record__c.Preparedness_Rating__c) && newRecord.Preparedness_Rating__c != relatedAccount.Preparedness_Rating__c){
                        updateAccount.Preparedness_Rating__c = newRecord.Preparedness_Rating__c;
                        isChanged = true;
                    }
                    if(isChanged(newRecord, oldRecord, Schema.CS_Record__c.Self_install_or_Vendor__c) && newRecord.Self_install_or_Vendor__c != relatedAccount.Self_install_or_Vendor__c){
                        updateAccount.Self_install_or_Vendor__c = newRecord.Self_install_or_Vendor__c;
                        isChanged = true;
                    }
                    if(isChanged(newRecord, oldRecord, Schema.CS_Record__c.Did_they_Trial__c) && newRecord.Did_they_Trial__c != relatedAccount.Did_they_Trial__c){
                        updateAccount.Did_they_Trial__c = newRecord.Did_they_Trial__c;
                        isChanged = true;
                    }
                    if(isChanged(newRecord, oldRecord, Schema.CS_Record__c.Feature_commits_CSM__c) && newRecord.Feature_commits_CSM__c != relatedAccount.Feature_commits_CSM__c){
                        updateAccount.Feature_commits_CSM__c = newRecord.Feature_commits_CSM__c;
                        isChanged = true;
                    }
                    if(isChanged(newRecord, oldRecord, Schema.CS_Record__c.Pain_Points_Objections_during_the_trial__c) && newRecord.Pain_Points_Objections_during_the_trial__c != relatedAccount.Pain_Points_Objections_during_the_trial__c){
                        updateAccount.Pain_Points_Objections_during_the_trial__c = newRecord.Pain_Points_Objections_during_the_trial__c;
                        isChanged = true;
                    }
                    if(isChanged(newRecord, oldRecord, Schema.CS_Record__c.CS_POC_Email_Address__c) && newRecord.CS_POC_Email_Address__c != relatedAccount.CS_POC_Email_Address__c){
                        updateAccount.CS_POC_Email_Address__c = newRecord.CS_POC_Email_Address__c;
                        isChanged = true;
                    }
                    if(isChanged(newRecord, oldRecord, Schema.CS_Record__c.CS_POC_First_Name__c) && newRecord.CS_POC_First_Name__c != relatedAccount.CS_POC_First_Name__c){
                        updateAccount.CS_POC_First_Name__c = newRecord.CS_POC_First_Name__c;
                        isChanged = true;
                    }
                    if(isChanged(newRecord, oldRecord, Schema.CS_Record__c.CSM_Status__c)){
                        updateAccount.CSM_Status__c = newRecord.CSM_Status__c ;
                        isChanged = true;
                    }         
                    if(isChanged(newRecord, oldRecord, Schema.CS_Record__c.CSM_Health_Rating__c)){
                        updateAccount.CSM_Health_Rating__c = newRecord.CSM_Health_Rating__c;
                        isChanged = true;
                    }                
                    if(isChanged(newRecord, oldRecord, Schema.CS_Record__c.CSM_Health_Trend__c)){
                        updateAccount.CSM_Health_Trend__c = newRecord.CSM_Health_Trend__c;
                        isChanged = true;
                    }                
                    if(isChanged(newRecord, oldRecord, Schema.CS_Record__c.Sentiment_Root_Cause__c)){
                        updateAccount.Sentiment_Root_Cause__c = newRecord.Sentiment_Root_Cause__c;
                        isChanged = true;
                    }                
                    if(isChanged(newRecord, oldRecord, Schema.CS_Record__c.Go_to_Green_Plan__c)){
                        updateAccount.Go_to_Green_Plan__c = newRecord.Go_to_Green_Plan__c;
                        isChanged = true;
                    }                
                    if(isChanged(newRecord, oldRecord, Schema.CS_Record__c.CSM_Health_Notes__c)){
                        updateAccount.CSM_Health_Notes__c = newRecord.CSM_Health_Notes__c;
                        isChanged = true;
                    }
                    if(isChanged(newRecord, oldRecord, Schema.CS_Record__c.Upsell_Opportunity_Reason__c)){
                        updateAccount.Upsell_Opportunity_Reason__c = newRecord.Upsell_Opportunity_Reason__c;
                        isChanged = true;
                    }
                    if(isChanged(newRecord, oldRecord, Schema.CS_Record__c.Churn_Risk_Reason__c)){
                        updateAccount.Churn_Risk_Reason__c = newRecord.Churn_Risk_Reason__c;
                        isChanged = true;
                    }  
                    if(isChanged == true){
                        updatedRecords.add(updateAccount);
                    }
                }
            }
            if(updatedRecords.size() > 0){
                update updatedRecords;
            }
        }     
    }
    
    public static Boolean isChanged(CS_Record__c newRecord, CS_Record__c oldRecord, Schema.SObjectField field){
        if(oldRecord == null){
            return true;
        }else if(newRecord.get(field) != oldRecord.get(field)){
            return true;
        }else{
            return false;
        }
    }
    
    // Added for GTMS-30390
    public static void beforeInsertOperations(List<CS_Record__c> newrRecords){
        Set<Id> accountIds = new Set<Id>();
        for(CS_Record__c rec : newrRecords){
            accountIds.add(rec.Account__c);
        }
        Map<Id,CS_Record__c> mapAccountRecords = new Map<Id,CS_Record__c>(); 
        for(CS_Record__c rec : [SELECT Id,Account__c FROM CS_Record__c WHERE Account__c IN : accountIds]){
            mapAccountRecords.put(rec.Account__c,rec);
        }
        
        for(CS_Record__c rec : newrRecords){
            if(mapAccountRecords.containsKey(rec.Account__c)){
                rec.addError('A CS record already exists for this Account.Please update existing record instead of creating new one.');
            }
        }
            
    }
}
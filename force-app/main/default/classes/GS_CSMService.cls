/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 06, 2021
*
* @description : This class will be responsible for handling all CSM Service Operations
* SFA-11
*
**/

public inherited sharing class GS_CSMService {
    public GS_CSMService() {
        
    }
     
    public void setCSMData(Map<Id, Account> oldAccountMap, List<Account> newAccountList){
        // TODO - Move CSM to own object
        for(Account thisAccount : newAccountList){
            
            Account oldAccount = new Account();
            if(oldAccountMap != NULL && oldAccountMap.size() >  0) {
                oldAccount = oldAccountMap.get(thisAccount.Id);
            }
            
            if(oldAccount.CSM_First_30d_Stage__c != thisAccount.CSM_First_30d_Stage__c) {
                populateCsmTimeStampFields(thisAccount);
            }
        }
    }
    
    public void populateCsmTimeStampFields(Account thisAccount){
        Datetime now = Datetime.NOW();
        switch on thisAccount.CSM_First_30d_Stage__c {
            when 'Pending Intro' {		
                thisAccount.CSM_Pending_Intro_Timestamp__c = now;
            }	
            when 'Pending Delivery' {	
                thisAccount.CSM_Pending_Delivery_Timestamp__c = now;
            }
            when 'Attempting Training' {	
                thisAccount.CSM_Attempting_Training_Timestamp__c = now;
            }
            when 'Scheduled Training' {	
                thisAccount.CSM_Scheduled_Training_Timestamp__c = now;
            }
            when 'Health Check' {	
                thisAccount.CSM_Health_Check_Timestamp__c = now;
            }
            when 'Scheduled Additional Training' {	
                thisAccount.CSM_Scheduled_Add_Training_Timestamp__c = now;
            }
            when 'Initial onboarding completed' {	
                thisAccount.CSM_Initial_onboarding_completed_Time__c = now;
            }
            when 'Additional followup needed' {	
                thisAccount.CSM_Additional_followup_needed_TimeStamp__c = now;
            }
        }
        
    }
    
}
/*
 * Class Created - @Harsha 
 * Test Class - AccountTests
 * 03/06/21  Anil   - (GTMS-3070) Create Cs Record in the Update Transaction 
 * 02/18/21 Harsha - (GTMS-2514)checkIfAccountNeedsCsmOrSeOnUpdate (Added logic for Pre_Sale_IC__c)
 * 02/04/21 Harsha -(GTMS-2594) Addded the logic to update First Purchase Date & SIC.
 * 10/01/20 Harsha - (GTMS-1732) updateRecords(Added changes to create CS Records for legacy accounts with them) 
 * 8/03/20 Harsha - (GTMS-1073)
 */
global class UpdateRecordsForCS {
	
    @future
    public static void updateRecords(Set<Id> recordIds){
         List<CS_Record__c> updatedRecords = new List<CS_Record__c>();
         List<Account> accounts = [SELECT Key_Stakeholder_for_CSM__c, Key_Value_Points__c, Upsell_Opportunity_Products__c, 
										  AE_to_CSM_handoff_notes__c, Preparedness_Rating__c, Self_install_or_Vendor__c, SIC__c,
                                          Did_they_Trial__c, Feature_commits_CSM__c, Pain_Points_Objections_during_the_trial__c,
                                   			CS_POC_Email_Address__c, CS_POC_First_Name__c, SIC__r.Name,First_Purchase_Date__c,Pre_Sale_IC__r.Name,
                                   		  (SELECT Id, Key_Stakeholder_for_CSM__c, Key_Value_Points__c, Upsell_Opportunity_Products__c, 
										  	AE_to_CSM_handoff_notes__c, Preparedness_Rating__c, Self_install_or_Vendor__c, First_Purchase_Date__c,
                                          	Did_they_Trial__c, Feature_commits_CSM__c, Pain_Points_Objections_during_the_trial__c,SIC__c,Pre_Sale_IC__c,
                                          	CS_POC_Email_Address__c, CS_POC_First_Name__c FROM CS_Records__r)
                                         FROM Account 
                                         WHERE Id IN :recordIds AND SAM_Number_Undecorated__c != 'C4G5EZWGY6'];
        for(Account account : accounts){
			CS_Record__c relatedRecord = account.CS_Records__r.size() > 0 ? account.CS_Records__r.get(0) : null; 
            CS_Record__c updatedRecord = null;
        	Boolean isChanged = false;
            if(relatedRecord != null){
                updatedRecord = new CS_Record__c(id = relatedRecord.Id);
                if(relatedRecord.Key_Stakeholder_for_CSM__c != account.Key_Stakeholder_for_CSM__c){
                    updatedRecord.Key_Stakeholder_for_CSM__c = account.Key_Stakeholder_for_CSM__c;
                    isChanged = true;
            	}
            	if(relatedRecord.Key_Value_Points__c != account.Key_Value_Points__c){
                    updatedRecord.Key_Value_Points__c = account.Key_Value_Points__c;
                    isChanged = true;
            	}
            	if(relatedRecord.Upsell_Opportunity_Products__c != account.Upsell_Opportunity_Products__c){
                    updatedRecord.Upsell_Opportunity_Products__c = account.Upsell_Opportunity_Products__c;
                    isChanged = true;
            	}
            	if(relatedRecord.AE_to_CSM_handoff_notes__c != account.AE_to_CSM_handoff_notes__c){
                    updatedRecord.AE_to_CSM_handoff_notes__c = account.AE_to_CSM_handoff_notes__c;
                    isChanged = true;
            	}
            	if(relatedRecord.Preparedness_Rating__c != account.Preparedness_Rating__c){
                    updatedRecord.Preparedness_Rating__c = account.Preparedness_Rating__c;
                    isChanged = true;
            	}
            	if(relatedRecord.Self_install_or_Vendor__c != account.Self_install_or_Vendor__c){
                    updatedRecord.Self_install_or_Vendor__c = account.Self_install_or_Vendor__c;
                    isChanged = true;
            	}
            	if(relatedRecord.Did_they_Trial__c != account.Did_they_Trial__c){
                    updatedRecord.Did_they_Trial__c = account.Did_they_Trial__c;
                    isChanged = true;
            	}
            	if(relatedRecord.Feature_commits_CSM__c != account.Feature_commits_CSM__c){
                    updatedRecord.Feature_commits_CSM__c = account.Feature_commits_CSM__c;
                    isChanged = true;
            	}
            	if(relatedRecord.Pain_Points_Objections_during_the_trial__c != account.Pain_Points_Objections_during_the_trial__c){
                    updatedRecord.Pain_Points_Objections_during_the_trial__c = account.Pain_Points_Objections_during_the_trial__c;
                    isChanged = true;
            	}
            	if(relatedRecord.CS_POC_Email_Address__c != account.CS_POC_Email_Address__c){
                    updatedRecord.CS_POC_Email_Address__c = account.CS_POC_Email_Address__c;
                    isChanged = true;
            	}
            	if(relatedRecord.CS_POC_First_Name__c != account.CS_POC_First_Name__c){
                    updatedRecord.CS_POC_First_Name__c = account.CS_POC_First_Name__c;
                    isChanged = true;
            	}  
                if(relatedRecord.First_Purchase_Date__c != account.First_Purchase_Date__c ){
                    updatedRecord.First_Purchase_Date__c = account.First_Purchase_Date__c;
                    isChanged = true;
            	} 
                if(relatedRecord.SIC__c != account.SIC__r.Name){
                    updatedRecord.SIC__c = account.SIC__r.Name;
                    isChanged = true;
            	} 
                if(relatedRecord.Pre_Sale_IC__c != account.Pre_Sale_IC__r.Name){
                    updatedRecord.Pre_Sale_IC__c = account.Pre_Sale_IC__r.Name;
                    isChanged = true;
            	} 
            }
            else if(relatedRecord == null){
            	updatedRecord = new CS_Record__c();
                updatedRecord.Account__c = account.Id;
               //(GTMS-3070) Create Cs Record in the Update Transaction - Anil Bogadi
                updatedRecord.Key_Stakeholder_for_CSM__c = account.Key_Stakeholder_for_CSM__c;
                updatedRecord.Key_Value_Points__c = account.Key_Value_Points__c;
                updatedRecord.Upsell_Opportunity_Products__c = account.Upsell_Opportunity_Products__c;
                updatedRecord.AE_to_CSM_handoff_notes__c = account.AE_to_CSM_handoff_notes__c;
                updatedRecord.Preparedness_Rating__c = account.Preparedness_Rating__c;
                updatedRecord.Self_install_or_Vendor__c = account.Self_install_or_Vendor__c;
                updatedRecord.Did_they_Trial__c = account.Did_they_Trial__c;
                updatedRecord.Feature_commits_CSM__c = account.Feature_commits_CSM__c;
                updatedRecord.Pain_Points_Objections_during_the_trial__c = account.Pain_Points_Objections_during_the_trial__c;
                updatedRecord.CS_POC_Email_Address__c = account.CS_POC_Email_Address__c;
                updatedRecord.CS_POC_First_Name__c = account.CS_POC_First_Name__c;
                updatedRecord.First_Purchase_Date__c = account.First_Purchase_Date__c;
                updatedRecord.SIC__c = account.SIC__c;
                updatedRecord.Pre_Sale_IC__c = account.Pre_Sale_IC__c;
                isChanged = true;
            }
            if(isChanged == true){
               updatedRecords.add(updatedRecord);
            }
        }
        if(updatedRecords.size()>0){
           upsert updatedRecords;
        }
    }
}
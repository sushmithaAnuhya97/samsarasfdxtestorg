global class CSRecordsBatch implements Database.Batchable<sObject> {

    private static final String ACCOUNT_QUERY = 
        'SELECT Id, Name,Key_Stakeholder_for_CSM__c,Key_Value_Points__c,Upsell_Opportunity_Products__c,AE_to_CSM_handoff_notes__c, ' +
		'Preparedness_Rating__c,Self_install_or_Vendor__c,Did_they_Trial__c,Feature_commits_CSM__c,Pain_Points_Objections_during_the_trial__c, ' +
		'CS_POC_Email_Address__c,CS_POC_First_Name__c, First_Purchase_Date__c,SIC__c,Pre_Sale_IC__c ' +
		'FROM Account ' +
        'WHERE Id NOT IN (Select Account__c From CS_Record__c) ' +
        'AND (Customer_ARR__c > 0 OR (Customer_ARR__c <= 0 AND First_Purchase_Date__c = LAST_N_MONTHS:6)  ) AND Quarantine_Enabled__c = false ' +
        'ORDER By Createddate DESC';
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(ACCOUNT_QUERY);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> scope) {
        List<CS_Record__c> recordsToCreate = new List<CS_Record__c>();
        for (Account acc : scope) {
            CS_Record__c createRecord = new CS_Record__c();
            createRecord.Account__c = acc.Id;
            createRecord.Key_Stakeholder_for_CSM__c = acc.Key_Stakeholder_for_CSM__c;
            createRecord.Key_Value_Points__c = acc.Key_Value_Points__c;
            createRecord.Upsell_Opportunity_Products__c = acc.Upsell_Opportunity_Products__c;
            createRecord.AE_to_CSM_handoff_notes__c = acc.AE_to_CSM_handoff_notes__c;
            createRecord.Preparedness_Rating__c = acc.Preparedness_Rating__c;
            createRecord.Self_install_or_Vendor__c = acc.Self_install_or_Vendor__c;
            createRecord.Did_they_Trial__c = acc.Did_they_Trial__c;
            createRecord.Feature_commits_CSM__c = acc.Feature_commits_CSM__c;
            createRecord.Pain_Points_Objections_during_the_trial__c = acc.Pain_Points_Objections_during_the_trial__c;
            createRecord.CS_POC_Email_Address__c = acc.CS_POC_Email_Address__c;
            createRecord.CS_POC_First_Name__c = acc.CS_POC_First_Name__c;
            createRecord.First_Purchase_Date__c = acc.First_Purchase_Date__c;
            createRecord.SIC__c = acc.SIC__c;
            createRecord.Pre_Sale_IC__c = acc.Pre_Sale_IC__c;
            recordsToCreate.add(createRecord);
        } 
        if(!recordsToCreate.IsEmpty()){
            Database.Insert(recordsToCreate,false); // Partial record updates
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }
}
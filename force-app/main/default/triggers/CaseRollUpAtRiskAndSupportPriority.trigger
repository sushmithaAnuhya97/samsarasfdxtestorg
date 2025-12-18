/*
 * 03/04/20 Harsha - (GTMS-2994) Removed the references for Total_Purchased_GW_Count__c
 */
trigger CaseRollUpAtRiskAndSupportPriority on Case (after update, after insert) {
    for (Case current_case : Trigger.new) {
        // only works if Case has related issue associated
        if (current_case.Related_Issue__c <> Null){
            // query the associates issue
             List<Issue__c> issue = [SELECT Id, Case_Count__c, Account_Count__c, Last_Case_Added_Date__c, Total_Purchased_VG_Count__c, Total_Purchased_AG_Count__c, Total_Purchased_CM_Count__c, Total_Purchased_EM_Count__c  FROM Issue__c where Id=: current_case.Related_Issue__c];
             // and all the cases associated with it, this assumes that same company doesn't have 2 cases on same issue
             List<Case> LastCase = [Select Id, CreatedDate from Case where Related_Issue__c =: issue[0].Id order by CreatedDate DESC LIMIT 1];
             List<Case> cases = [SELECT Id, AccountId, Account.AtRisk__c, Case_Account_Priority__c, Total_Purchased_VG_Count__c, Total_Purchased_AG_Count__c, Total_Purchased_CM_Count__c, Total_Purchased_EM_Count__c FROM Case where Related_Issue__c =: issue[0].Id order by AccountId];
             Decimal totalAtRisk = 0;
             String priority = '';
             String AccountInitial = cases[0].AccountId;
             Decimal VG_count = 0;
             Decimal AG_count = 0;
             Decimal CM_count = 0;
             Decimal EM_count = 0;
             //Decimal ELD_count = 0;
             Integer i = 0;
             Integer accountcount = 0;
             if (cases.size() > 0){
                 for (Case c : cases){
                   if(i>0){
                    if(AccountInitial != c.AccountId){
                     VG_count += c.Total_Purchased_VG_Count__c;
                     AG_count += c.Total_Purchased_AG_Count__c;
                     CM_count += c.Total_Purchased_CM_Count__c;
                     EM_count += c.Total_Purchased_EM_Count__c;
                     //ELD_count += c.Total_Purchased_ELD_Cab_Kits__c; 
                     if (c.Account.AtRisk__c <> Null){
                         totalAtRisk += c.Account.AtRisk__c;
                     }
                     if (priority=='s0' || c.Case_Account_Priority__c == 's0'){
                         priority = 's0';
                     } else if (priority=='s1' || c.Case_Account_Priority__c == 's1'){
                         priority = 's1';
                     } else{
                         priority = 's2';
                     }
                     i = i+1;
                     AccountInitial = c.AccountId;
                     accountcount = accountcount + 1;
                   } 
                  }else {
                     VG_count = c.Total_Purchased_VG_Count__c;
                     AG_count = c.Total_Purchased_AG_Count__c;
                     CM_count = c.Total_Purchased_CM_Count__c;
                     EM_count = c.Total_Purchased_EM_Count__c;
                     //ELD_count = c.Total_Purchased_ELD_Cab_Kits__c; 
                     if (c.Account.AtRisk__c <> Null){
                         totalAtRisk += c.Account.AtRisk__c;
                     }
                     if (c.Case_Account_Priority__c == 's0'){
                         priority = 's0';
                     } else if (c.Case_Account_Priority__c == 's1'){
                         priority = 's1';
                     } else{
                         priority = 's2';
                     }
                     i = i+1;
                     accountcount = 1;
                   }
                     
                 }
                 issue[0].Total_Purchased_VG_Count__c = VG_count;
                 issue[0].Total_Purchased_AG_Count__c = AG_count;
                 issue[0].Total_Purchased_CM_Count__c = CM_count;
                 issue[0].Total_Purchased_EM_Count__c = EM_count;
                 //issue[0].Total_Purchased_ELD_Cab_Kits__c = ELD_count;
                 issue[0].Account_Count__c = accountcount;
                 issue[0].AtRisk__c = totalAtRisk;
                 issue[0].Case_Count__c = cases.size();
                 issue[0].Support_Priority__c = priority;
                 issue[0].Last_Case_Added_Date__c = LastCase[0].CreatedDate;
                 update issue[0];
             }
             System.debug(totalAtRisk);
             System.debug(cases);
         }
     }

}
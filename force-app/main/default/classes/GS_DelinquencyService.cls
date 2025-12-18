/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 10, 2021
*
* @description : This class will be responsible for handling all Delinquency Operations
* SFA-11
*
**/

public inherited sharing class GS_DelinquencyService {
    public GS_DelinquencyService() {
        
    }
    
    /**
    *  SET DELINQUENCY STATUS
    */
    
    public void setDelinquencyStatus(Map<Id, Account> oldAccountMap, List<Account> newAccountList){
        
        //* GTMS-2843, GTMS-2992 Update Delinquency Flows in SFDC --> to be deployed on May 6th 
        //* Author - Ron Saavedra --> Documentation: https://samsaradev.atlassian.net/wiki/spaces/BUS/pages/1421771034
       
        for(Account thisAccount : newAccountList){
            
            Account oldAccount = new Account();
            if(oldAccountMap != NULL && oldAccountMap.size() >  0) {
                oldAccount = oldAccountMap.get(thisAccount.Id);
            }
            
            if(thisAccount.Delinquency_Threshold__c != 0){
                Finance_Setting__mdt financeSetting = Finance_Setting__mdt.getInstance(thisAccount.Segment__c.replace(' ', '_'));
                
                if((thisAccount.Segment__c == 'AE1' || thisAccount.Micro_Fleet_Support_Tier__c == TRUE) && thisAccount.Delinquent__c ){
                    thisAccount.Delinquency_Status__c = 'Orders Blocked';
                } else if(financeSetting != null && thisAccount.Delinquency_Threshold__c >= financeSetting.Upper_Delinquency_Threshold__c){
                    if(thisAccount.Segment__c != 'Enterprise') 
                        thisAccount.Delinquency_Status__c = financeSetting.Upper_Delinquency_Status__c;
                    else {
                        if(thisAccount.netsuite_conn__Days_Overdue__c > financeSetting.Days_over_due__c)
                            thisAccount.Delinquency_Status__c = financeSetting.Upper_Delinquency_Status__c;
                        else thisAccount.Delinquency_Status__c = '';
                    }
                } else if(financeSetting != null && thisAccount.Delinquency_Threshold__c >= financeSetting.Lower_Delinquency_Threshold__c){
                    if(thisAccount.Segment__c != 'Enterprise') 
                        thisAccount.Delinquency_Status__c = financeSetting.Lower_Delinquency_Status__c;
                    else {
                        if(thisAccount.netsuite_conn__Days_Overdue__c <= financeSetting.Days_over_due__c)
                            thisAccount.Delinquency_Status__c = financeSetting.Lower_Delinquency_Status__c;   
                        else thisAccount.Delinquency_Status__c = '';    
                    }  
                } else if(financeSetting != null && thisAccount.Delinquency_Threshold__c < financeSetting.Lower_Delinquency_Threshold__c){
                    thisAccount.Delinquency_Status__c = ''; 
                }
            }
            
            if(!thisAccount.Delinquent__c && oldAccount.Delinquent__c != thisAccount.Delinquent__c){
                thisAccount.Delinquency_Status__c = ''; 
            }
        }
    }

    // GTMS-24220 By Anurag Bhatt.
    public void adjustNetTermsPerSegment(Map<Id, Account> oldAccountMap, List<Account> newAccountList){
        
        List<Account> lstAccountsToProcess = new List<Account>();
        Boolean isInsert = oldAccountMap == null ? true : false;
        for (Account acc : newAccountList) {
            if(isInsert || acc.Owner_Role_Text_Stamped__c != oldAccountMap.get(acc.Id).Owner_Role_Text_Stamped__c || acc.Approved_Payment_Type__c != oldAccountMap.get(acc.Id).Approved_Payment_Type__c){
                lstAccountsToProcess.add(acc);
            }
        }
        if(!lstAccountsToProcess.isEmpty()){
            Set<Id> setAccountsWithApprovedIFRs = new Set<Id>();
            Set<Id> setAccountsWithActiveContracts = new Set<Id>();
            if(!isInsert){
                
                for(Internal_Finance_Approval_Request__c ifr: [SELECT Id,Account__c
                                                                    FROM Internal_Finance_Approval_Request__c 
                                                                    WHERE Account__c IN :lstAccountsToProcess 
                                                                    and Payment_Type_Approval_Status__c = 'Approved'
                                                                    AND Request_Type__c = 'Change in Payment Terms']){
                    setAccountsWithApprovedIFRs.add(ifr.Account__c);
                }
                Set<Id> setAccountIds ;
                for (Contract cont : [SELECT Id,AccountId 
                                        FROM Contract
                                        WHERE AccountId IN :lstAccountsToProcess 
                                        AND StartDate <= TODAY and  Enddate >= TODAY]) {
                    setAccountsWithActiveContracts.add(cont.AccountId);
                }
            }
            for (Account acc : lstAccountsToProcess) {
                String ownerRole = acc.Owner_Role__c == null ? '' : acc.Owner_Role__c;
                String approvedPaymentType = acc.Approved_Payment_Type__c == null ? '' : acc.Approved_Payment_Type__c;
                if(!setAccountsWithActiveContracts.contains(acc.Id) && 
                   !setAccountsWithApprovedIFRs.contains(acc.Id)    &&
                   (( 
                        (ownerRole.contains('SEL') || ownerRole.contains('STR') || ownerRole.contains('COR') || ownerRole.contains('MM')) && 
                        (
                            (approvedPaymentType == 'Upfront Payments' || approvedPaymentType == 'Direct Annual')
                        )
                    ) || 
                    (
                        (ownerRole.contains('SEL') || ownerRole.contains('STR')) && approvedPaymentType == 'Direct Monthly'

                    )

                )){
                    acc.Payment_Terms__c = 'Net 30'; // Update the payment term 
                }
        
            }
        }
    }
}
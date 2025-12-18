/**
 * @description       : This class is used to assign Renewal AE user on Account when it is assigned to Renewal AE is blank
 * @group             : 
 * @last modified on  : 11-30-2022
 * @last modified by  : rodrigo.carpio@samsara.com
**/
public with sharing class AssignRenewalAEOnAccountBatch implements Database.Batchable<sObject>, Database.RaisesPlatformEvents {
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        //add query to custom label
        // Select id, billingcountrycode, csm__c, Customer_ARR__c, SLED_Account__c,Renewal_AE__c from account where Renewal_AE__c = nul
        //return Database.getQueryLocator(System.Label.ASSIGN_RENEWAL_AE_ON_ACCOUNT);
        return Database.getQueryLocator(System.Label.ASSIGN_RENEWAL_AE_ON_ACCOUNT);
    }
    
    public void execute(Database.BatchableContext bc, List<Contract> scope) {
        RoundRobinHandler rr = new RoundRobinHandler('Automating Pipeline', 'Account');
        Map<Id, Double> accntContractsACV = new Map<Id, Double>();
        Map<Id, Contract> accntContract = new Map<Id, Contract>();
        Id currAccntId = null;
        Double totalACV = 0;
        
        // loop all contracts
        // 
        FOR (Contract objCon : scope) {
            Double locContractACV = (objCon.Contract_Renewal_ACV__c != null) ? objCon.Contract_Renewal_ACV__c : 0;
            if (currAccntId == null) {
                currAccntId = objCon.AccountId;
                totalACV = locContractACV;
            }
            else {
                if (currAccntId == objCon.AccountId) {
                    totalACV = totalACV + locContractACV;
                }
                else {
                    accntContractsACV.put(currAccntId, totalACV);
                    totalACV = locContractACV;
                    currAccntId = objCon.AccountId;
                }
            }
            accntContract.put(objCon.AccountId, objCon);    
        }
        
        accntContractsACV.put(currAccntId, totalACV);
        List<Account> forUpdateAccount = new List<Account>();
        FOR(Id accntId : accntContract.keySet()) {
            Contract locContract = accntContract.get(accntId);
            Account updAccount = new Account();
            updAccount.Id = locContract.AccountId;
            Double locRenewalACV = accntContractsACV.get(locContract.AccountId);
            String renewalAEId = null;
            renewalAEId = rr.getAssignedUserByAttributes(locContract.AccountId, locContract.Account.SLED_Account__c, 
                                                         locContract.Account.BillingCountryCode, locContract.Account.Customer_ARR__c, locRenewalACV, locContract.Account.Name);
            
            if(renewalAEId != null && renewalAEId.startsWithIgnoreCase('005'))
            	updAccount.Renewal_AE__c = renewalAEId;
            else
                updAccount.Renewal_AE_Queue__c = renewalAEId;
            
            if (renewalAEId != null) 
            	forUpdateAccount.add(updAccount);
		}
        
        if(forUpdateAccount != null && forUpdateAccount.size()>0) {
            TriggerHandler.bypass('GS_AccountTriggerHandler');
            database.update(forUpdateAccount, false);
            rr.updateRuleDetail();
        }
            
        /*for(Account objAccnt : scope) {
            objAccnt.Renewal_AE__c = rr.getAssignedUser(objAccnt);
        }  
        rr.updateRuleDetail(); 
        database.update(scope, false);*/  
    }
    
    public void finish(Database.BatchableContext bc){
        System.debug('finish method');
        //send email from the finish method.
    }
}
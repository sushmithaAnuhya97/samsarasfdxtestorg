/**
* @description       : This class is used to assign Renewal AE user on Opportunity when it is assigned to Renewal Pool user
* @group             : 
* @last modified on  : 12-06-2022
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class AssignRenewalAEOnOpportunityBatch implements Database.Batchable<sObject>, Database.RaisesPlatformEvents {
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        //String query = 'SELECT Id, Account.Renewal_AE__c, AccountId, OwnerId FROM Opportunity WHERE OwnerId =: Label.Renewal_Pool_User';
        //query = query + ' AND Account.Renewal_AE__c != null';
        String renewalPoolUser = System.Label.Renewal_Pool_User;
        //addquery to custom label
        return Database.getQueryLocator(System.Label.ASSIGN_RENEWAL_AE_ON_OPPORTUNITY);
    }
    
    public void execute(Database.BatchableContext bc, List<Opportunity> scope) 
    {
        Map<Id, SBQQ__Quote__c> forUpdQuotes = new Map<Id, SBQQ__Quote__c>(); // added for GTMS-10123
        Set<Id> listOptyIds = new Set<Id>();
        
        for(Opportunity s : scope) {
            listOptyIds.add(s.Id);
        }
        
        List<SBQQ__Quote__c> optyQuotes = new List<SBQQ__Quote__c>();
        if (listOptyIds != null && listOptyIds.size()>0)
        	optyQuotes = [SELECT Id, SBQQ__Opportunity2__c FROM SBQQ__Quote__c WHERE SBQQ__Status__c = 'Draft' AND SBQQ__Opportunity2__c IN: listOptyIds order by SBQQ__Opportunity2__c ];
        
        // collect opty quotes into maps
        Map<Id, Id> quoteIds = new Map<Id, Id>();
        Map<Id, Map<Id, Id>> optyQuoteIds = new Map<Id, Map<Id, Id>>();
        FOR(Id opty : listOptyIds) {
            FOR(SBQQ__Quote__c quoteRec : optyQuotes) {
                if (quoteRec.SBQQ__Opportunity2__c == opty){
                    quoteIds.put(quoteRec.Id, quoteRec.Id);
                }
            }
            if (quoteIds.size()>0)
                optyQuoteIds.put(opty, quoteIds);
        }
        
        for(Opportunity s : scope) {
            s.OwnerId = s.Account.Renewal_AE__c;
            
            Map<Id, Id> quoteIdsLoc = new Map<Id, Id>();
            quoteIdsLoc = optyQuoteIds.get(s.Id);
            if (quoteIdsLoc != null && quoteIdsLoc.size() > 0)
            {
                FOR (Id recId : quoteIdsLoc.values()) {
                    SBQQ__Quote__c forUpd = new SBQQ__Quote__c();
                    forUpd.Id = recId;
                    forUpd.OwnerId = s.Account.Renewal_AE__c;
                    forUpd.SBQQ__SalesRep__c = s.Account.Renewal_AE__c;
                    forUpdQuotes.put(recId, forUpd);
                }
            }
            
            
            if(Test.isRunningTest()) {
                s.Name = null;
            }
        }   
        
        if(forUpdQuotes !=null && forUpdQuotes.size()>0) // added for GTMS-10123 
        {
            SBQQ.TriggerControl.disable();
            update forUpdQuotes.values();
            SBQQ.TriggerControl.enable();
        }
        
        //add code to skip Opportunity trigger
        TriggerHandler.bypass('OpportunityTriggerHandler');
        update scope;
        
        
        
            
    }
    
    public void finish(Database.BatchableContext bc){
        System.debug('finish method');
    }
}
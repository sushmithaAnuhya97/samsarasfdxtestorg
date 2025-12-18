/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 22, 2021
*
* @description : This class will be responsible for saving/querying all Contact related data during Contact Trigger execution
* SFA-14
*
**/
public with Sharing class GS_ContactCacheService {
    public Map<Id, Account> relatedAccountMap;
    public Map<Id, Contact> contactDetailsMap;
    public Set<Id> cachedContactIds;
    public Set<Id> cachedAccountIds;
    public Map<String, Id> poolMap = null;
    public Slack_Enabled_Campaign_Type__mdt slackCampaignTypes;
    
    
    //Loads the related Accounts from the received Id List, updates to be utilized throughout the Class
    public void loadContactRelatedAccounts(Set<Id> accountIds) {
        if(this.relatedAccountMap == null) {
            this.relatedAccountMap = new Map<Id, Account>(
                (new GS_AccountSelector(true)).getAccountsByIds(new List<Id>(accountIds)));
        }
    }
    
    
    //Loads the related Accounts from the received Id List, updates to be utilized throughout the Class
    public void loadContactDetails(Set<Id> contactIds) {
        if(this.contactDetailsMap == null) {
            this.contactDetailsMap = new Map<Id, Contact>(
                (new GS_ContactSelector(true)).getContactDetailsByIds(contactIds));
        }
    }
    
    
        
    public void loadSlackCampaignTypes(){
        if(this.slackCampaignTypes == null){
            this.slackCampaignTypes = [  SELECT   Yo_Yo_Enabled_Campaign_Sources__c,
                                   Campaign_Type_List__c
                                   FROM Slack_Enabled_Campaign_Type__mdt];
        }
    }
    
    
    public void loadPoolUsers() {
        if(poolMap == null) {
            poolMap = new Map<String, Id>();
            for(Business_Unit_User__mdt userMapping : [ SELECT  Id,
                                                       MasterLabel,
                                                       User_Id__c
                                                       FROM Business_Unit_User__mdt]) {
                                                           poolMap.put(userMapping.MasterLabel, userMapping.User_Id__c);
                                                       }
        }
    }
    
    /**
* Caches the related Account & Contract IDs from oppList
* @param List<Opportunity> oppList
*/
    public void cacheRelatedIdsFromContact(List<Contact> newContactList){
        if (this.cachedContactIds != null || this.cachedAccountIds != null) return;
        
        this.cachedAccountIds = new Set<Id>();
        this.cachedContactIds = new Set<Id>();
        for(Contact contact: newContactList){
            if (contact.Id != null)		   this.cachedContactIds.add(contact.Id);
            if (contact.AccountId != null) this.cachedAccountIds.add(contact.AccountId);
        }
    }
}
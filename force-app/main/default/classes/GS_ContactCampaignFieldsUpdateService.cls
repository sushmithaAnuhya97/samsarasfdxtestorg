/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 26, 2021
*
* @description : This class will be responsible to Update Contacts Campaign Fields
* SFA-14
*
**/
public with sharing class GS_ContactCampaignFieldsUpdateService {
    // 7/18/19, Phillip Front - This method updates the Owner At Interaction field for Growth when the owner changes from the pool to another user.
    // Only updates the most recent campaign member, and only if its current Owner At Interaction is null or a pool user.
    // Updates the old text field that was created for some reason to hold the text of the name of the owner at interaction :\
    // Updates the Campaign_Interaction_Date__c to whenever the assignment occurred
    // Updates the Inbound_ADR_Toggle_Status__c with the new owner's toggle status
    public void updateCampaignFieldsFuture(Map<Id, Contact> oldContactMap, Map<Id, Contact> newContactMap) {
        
        // Find contacts who changed
        Set<Id> contactIdsWhoseOwnerChangesFromPool = new Set<Id>();
        for(Contact c : newContactMap.values()) {
            Contact oldContact = oldContactMap.get(c.Id);
            if(oldContact.OwnerId != c.OwnerId 
               && oldContact.Owner_Is_Pool_User__c) {
                   contactIdsWhoseOwnerChangesFromPool.add(c.Id);
               }
        }
        if (!contactIdsWhoseOwnerChangesFromPool.isEmpty()) {
            updateCampaignFieldsFuture(contactIdsWhoseOwnerChangesFromPool);
        }
    }
    
    @Future
    public static void updateCampaignFieldsFuture(Set<Id> contactIds) {
        SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();
        try{
            thisSamsaraLoggerService.logger.logTrace('Entering in GS_ContactCampaignFieldsUpdateService');
            List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
                CampaignMember.SObjectType
                    };
                        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
            List<Contact> contacts = new GS_ContactSelector(true).checkFatalError().getContactsByIds(contactIds);
            updateCampaignFields(contacts, true);
        }catch(Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in GS_ContactCampaignFieldsUpdateService::', new SamsaraLoggerObjectMVP(
                ex, contactIds
        ));
            throw ex;
        }finally{
            thisSamsaraLoggerService.logger.dispatch();
        }
    }
    
    public void updateCampaignFields(Map<Id, Contact> oldContactMap, Map<Id, Contact> newContactMap) {
        
        // Find contacts who changed
        List<Contact> contactOwnerChangesFromPool = new List<Contact>();
        for (Contact thisContact : newContactMap.values()) {
            Contact oldContact = oldContactMap.get(thisContact.Id);
            if (oldContact.OwnerId != thisContact.OwnerId && oldContact.Owner_Is_Pool_User__c) {
                contactOwnerChangesFromPool.add(thisContact);
            }
        }
        if (!contactOwnerChangesFromPool.isEmpty()) {
            updateCampaignFields(contactOwnerChangesFromPool, false);
        }
    }
    public static void updateCampaignFields(List<Contact> contactOwnerChangesFromPool, Boolean async) {
        
        List<CampaignMember> cmUpdateList = new List<CampaignMember>();
        Map<Id, CampaignMember> contactIdToCampaignMember = new Map<Id, CampaignMember>();
        
        // Map campaign members to the contactIds whose owners changed from the pool
        if (contactOwnerChangesFromPool.size() > 0) {
            List<CampaignMember> cmList = new GS_CampaignMemberSelector(true).checkFatalError().getCampaignMemberByAgeDays(contactOwnerChangesFromPool);
            for(CampaignMember cm: cmList) {
                if(!contactIdToCampaignMember.containsKey(cm.ContactId)) {
                    contactIdToCampaignMember.put(cm.ContactId, cm);
                }
            }
            // Loop through contacts that changed and take the first campaign member from each
            for(Contact thisContact : contactOwnerChangesFromPool) {
                if(contactIdToCampaignMember.containsKey(thisContact.Id)) {
                    CampaignMember cm = contactIdToCampaignMember.get(thisContact.Id);
                    if(cm.Owner_at_Interaction_Lookup__c == NULL || cm.Owner_at_Interaction_Lookup__r.RR_Is_Pool_User__c) {
                        cm.Owner_at_Interaction_Lookup__c = thisContact.OwnerId;
                        cm.Owner_At_Interaction__c = thisContact.Owner_Name__c;
                        cm.Inbound_ADR_Toggle_Status__c = thisContact.Owner_Is_Signed_In__c;
                        cm.Campaign_Interaction_Date__c = System.Now();
                        cm.Owner_Role_Copy__c = thisContact.Owner_Role__c;
                        
                        if(cm.Account__r.RR_Assigned_On__c == System.TODAY()){
                            cm.Lead_Funnel_Assignment_Date_Time__c = cm.Account__r.RR_Assigned_On__c;
                        }
                        
                        cmUpdateList.add(cm);
                    }
                }
            }
        }
        if(cmUpdateList.size() > 0) {
            //update cmUpdateList;
            DMLWrapper.doUpdate(cmUpdateList);
            if (async)
                DMLWrapper.publishDML();
        }
    }
}
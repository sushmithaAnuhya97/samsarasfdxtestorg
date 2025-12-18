/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 24, 2021
*
* @description : This class will be responsible to Reset Contact Flag Operations
* SFA-14
*
**/
public with sharing class GS_Contact_ResetFlagService {
    public Map<Id,Account> relatedAccountMap = new Map<Id,Account>();  
    public Map<Id, Contact> contactToUpdateById = new Map<Id, Contact>();
    
    public static Slack_Enabled_Campaign_Type__mdt slackCampaignTypes;
    
    
    public void resetFlagsFuture(List<Contact> contacts, Map<Id, Boolean> yoyoContactMap, Boolean isUpdate, Boolean future){
        String newContactListSerialized = JSON.serialize(contacts);
        String yoyoContactMapSerialized = JSON.serialize(yoyoContactMap);
        
        resetFlagsFuture(newContactListSerialized, yoyoContactMapSerialized, isUpdate, future);
    }
    
    @Future
    public static void resetFlagsFuture(String newContactListSerialized, String yoyoContactMapSerialized, Boolean isUpdate, Boolean future){
         SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();
         List<Contact> newContactList = new List<Contact>();
        try{
            newContactList = (List<Contact>)JSON.deserialize(newContactListSerialized, List<Contact>.class);
            Map<Id, Boolean> yoyoContactMap = (Map<Id, Boolean>)JSON.deserialize(yoyoContactMapSerialized, Map<Id, Boolean>.class);
            GS_Contact_ResetFlagService conResetFlagService =  new GS_Contact_ResetFlagService();
            List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
                Contact.SObjectType
                    };
                        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
            conResetFlagService.resetFlags(newContactList, yoyoContactMap, isUpdate, future);
            DMLWrapper.publishDML();
        }catch(Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in GS_Contact_ResetFlagService::', new SamsaraLoggerObjectMVP(
                ex, newContactList
        ));
            throw ex;
        }finally{
            thisSamsaraLoggerService.logger.dispatch();
        }
        
        
    }
    
    
    public void resetFlags(List<Contact> contacts, Map<Id, Boolean> yoyoContactMap, Boolean isUpdate, Boolean future){
        String hashtag;
        String description;
        String ibform;
        
        GS_ContactService conService = new GS_ContactService();
        
        GS_ContactCacheService contactCache = new GS_ContactCacheService();
        contactCache.cacheRelatedIdsFromContact(contacts);
        contactCache.loadContactRelatedAccounts(contactCache.cachedAccountIds); 
        contactCache.loadSlackCampaignTypes();
        slackCampaignTypes = contactCache.slackCampaignTypes;
        relatedAccountMap = contactCache.relatedAccountMap;
        
        
        for (Contact thisContact : contacts) {
            Account acct = relatedAccountMap.get(thisContact.AccountId);
            Contact contactToUpdate = new Contact(Id = thisContact.Id);
           
            if(yoyoContactMap != null && yoyoContactMap.containsKey(thisContact.Id) && yoyoContactMap.get(thisContact.Id)){
                hashtag = conService.gethashValueToAppend(thisContact);
            } else{
                hashtag = thisContact.Hashtag__c;
            }
            
            if (thisContact.Converted_Contact__c != null) {
                
                // append hashtag
                if (thisContact.Converted_Hashtags_to_Append__c != null){
                    if(hashtag != null){
                        if(!hashtag.contains(thisContact.Converted_Hashtags_to_Append__c)){
                            hashtag = thisContact.Converted_Hashtags_to_Append__c + ' ' + hashtag;
                        }
                    }
                    else {
                        hashtag = thisContact.Converted_Hashtags_to_Append__c;
                    }   
                }
                
                // converted notes to append
                if (thisContact.Converted_Notes_to_Append__c != null && isUpdate) {
                    description = thisContact.Converted_Notes_to_Append__c + ' ' + thisContact.Description;
                }
                else{
                    description = thisContact.Description;
                }
                
                // Append inbound form fill
                if(thisContact.Inbound_Form_Message_to_append__c != null && isUpdate){
                    ibForm = thisContact.Inbound_Form_Message_to_append__c + ' ' + thisContact.Inbound_Form_Message__c;
                }
                else {
                    ibForm = thisContact.Inbound_Form_Message_to_append__c;
                }
                
                contactToUpdate.Converted_Contact__c = null;
                contactToUpdate.Converted_Hashtags_to_Append__c = null;
                contactToUpdate.Converted_Notes_to_Append__c = null;
                contactToUpdate.Inbound_Form_Message_to_append__c = null;
                contactToUpdate.Hashtag__c = hashtag;
                contactToUpdate.Description = description;
                contactToUpdate.Inbound_Form_Message__c = ibForm;
                contactToUpdateById.put(contactToUpdate.Id, contactToUpdate);
            }
            
            if ((thisContact.New_Inbound_Lead__c == true 
                 || thisContact.Channel_Source__c == true)){
                     if(!(thisContact.Most_Recent_Source__c == 'Sites webinar registration form'
                          && acct.Customer_ARR__c > 0 
                          && acct.Quarantine_Enabled__c == False)) contactToUpdate.New_Inbound_Lead__c = false;
                     contactToUpdate.Channel_Source__c = false;
                     contactToUpdate.Referring_Customer_Id__c = null;
                     contactToUpdateById.put(contactToUpdate.Id, contactToUpdate);
                 }
        }
        
        if(!contactToUpdateById.isEmpty()){
            List<Contact> contactList = new List<Contact>();
            contactList.addAll(contactToUpdateById.values());
            contactToUpdateById.clear();
            DMLWrapper.doUpdate(contactList);
        }
    }
    
}
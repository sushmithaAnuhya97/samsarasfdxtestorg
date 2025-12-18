/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 21, 2021
*
* @description : This class will be responsible for handling all Prepolution of fields on Before Contact Trigger Context
* SFA-14
*
**/
public class GS_ContactPrePopulationService {
    private static final String CAMPAIGN_EMAIL = '(Child) Inbound call/email';
    private static final String CAMPAIGN_CHATBOT = '(Child) Intercom';
    private static final String CAMPAIGN_REFERRAL = '(Child) Referral - unpaid';
    private static final String STATUS_EXISTING = 'Existing Customer';
    private static final String TYPE_RESELLER_PARTNER = 'Reseller Partner';
    private static final String TYPE_REFERRAL_PARTNER = 'Referral Partner';
    private static final String LAWFUL_BASIS_CONTRACT = 'Contract';
    private static final String LAWFUL_LEGITIMATE_INTEREST = 'Legitimate Interest';
    private static final String LAWFUL_NOT_APPLICABLE = 'Not Applicable';
    private static final String EMAIL_CAMPAIGN_ID = '7011a000000SI78';
    private static final String CHATBOT_CAMPAIGN_ID = '7011a000000SI7w';
    private static final String REFERRAL_CAMPAIGN_ID = '7011a000000SI6j';
        
    private Map<String, Id> campaignIdByName;
    Map<ID, Schema.RecordTypeInfo> rtMap;
    public Map<Id, Account> relatedAccountMap;
    
    public GS_ContactCacheService contactCache;
    
    
    public void runBeforeInsertService(List<Contact> newContactList, GS_ContactCacheService contactCache){
        this.contactCache = contactCache;
        beforeInsertPrePopulate(newContactList, this.contactCache.relatedAccountMap);
        ensureOwnerMatchesAccount(newContactList, this.contactCache.relatedAccountMap);
    }
    
    
    public void runBeforeUpdateService(List<Contact> newContactList, Map<Id, Contact> oldContactMap, GS_ContactCacheService contactCache){
        this.contactCache = contactCache;
        
        beforeUpdatePrePopulate(oldContactMap, newContactList, this.contactCache.relatedAccountMap, this.contactCache.contactDetailsMap);
        ensureOwnerMatchesAccount(newContactList,oldContactMap); // Process Builder - Mass Action: Account Owner equals Contact Owner (Invocable)
    }
    
    
    public void commonContextPrePopulateHelper(List<Contact> newContactList){
        for(Contact thisContact : newContactList) {
            setExternalCustomerId(thisContact);
            setRecordType(thisContact);
        }
    }
    
    
    public void stampLawfulBasis(Contact thisContact, Account acc){
        String lawfulBasis = thisContact.Associated_Lawful_Basis__c;
        if (acc != null){
            if(HelperClass.euCountryCodes.contains(acc.BillingCountryCode) 
            && (acc.Status__c == STATUS_EXISTING 
                || acc.Type == TYPE_RESELLER_PARTNER 
                || acc.Type == TYPE_REFERRAL_PARTNER)) {
                lawfulBasis = LAWFUL_BASIS_CONTRACT;
            } else if(HelperClass.euCountryCodes.contains(acc.BillingCountryCode)) {
                lawfulBasis = LAWFUL_LEGITIMATE_INTEREST;
            } else {
                lawfulBasis = LAWFUL_NOT_APPLICABLE;
            }
            
            if(thisContact.Associated_Lawful_Basis__c != lawfulBasis) {
                thisContact.Associated_Lawful_Basis__c = lawfulBasis;
            }
        }
    }
    
    public void setCampaignToAddAndManualSource(Contact thisContact, Id emailCampaignId, Id referralCampaignId, Id chatBotCampaignId){
        //Logic to query only if a record matches the criteria and if more than one record matches the criteria it will still query for the first time only.
        if(thisContact.Inbound_Call_Email_Source__c){
            if(emailCampaignId != null){
                thisContact.Campaign_to_Add__c = emailCampaignId;                   
            }else{
                emailCampaignId = getEmailCampaignId();
                thisContact.Campaign_to_Add__c = emailCampaignId;  
            }
            GS_ContactService.manualSource = 'true';
        }            
        
        if(thisContact.Referral_Unpaid_Source__c){
            if(referralCampaignId != null){
                thisContact.Campaign_to_Add__c = emailCampaignId;                   
            }else{
                referralCampaignId = getReferralCampaignId();
                thisContact.Campaign_to_Add__c = referralCampaignId;  
            }
            GS_ContactService.manualSource = 'true';
        }            
        
        if(thisContact.Chatbot_Source__c){
            if(chatBotCampaignId != null){
                thisContact.Campaign_to_Add__c = chatBotCampaignId;                   
            }else{
                chatBotCampaignId = getChatBotCampaignId();
                thisContact.Campaign_to_Add__c = chatBotCampaignId;  
            }
            GS_ContactService.manualSource = 'true';
        }
    }
    
    public void beforeInsertPrePopulate(List<Contact> newContactList, Map<Id, Account> relatedAccountMap){
        Id emailCampaignId ;
        Id referralCampaignId;
        Id chatBotCampaignId;
        loadRTMap();
        
        Boolean stampRecordTypeName = false;
        for(Contact thisContact : newContactList) {
            stampRecordTypeName = true;
            Account acc = relatedAccountMap.get(thisContact.AccountId);
            if(stampRecordTypeName && thisContact.RecordTypeId != NULL) {
                thisContact.Record_Type_Stamp_For_Dupes__c = this.rtMap.get(thisContact.RecordTypeId).getName();
            }
            
            stampLawfulBasis(thisContact, acc);
            setCampaignToAddAndManualSource(thisContact, emailCampaignId, referralCampaignId, chatBotCampaignId);
            /*
* Call Workflow Conversion Class for Conatcts
*/
            ContactWorkflowConversionWS.beforeInsertUpdateRules(thisContact, null, null, null);
        }
    }
    
    public void loadRTMap(){
        if (this.rtMap == null){
            this.rtMap = Contact.sObjectType.getDescribe().getRecordTypeInfosById();
        }
    }
    
    public void beforeUpdatePrePopulate(Map<Id, Contact> oldContactMap, List<Contact> newContactList, Map<Id, Account> relatedAccountMap, Map<Id, Contact> contactDetailsMap){
        loadRTMap();        
        Boolean stampRecordTypeName = false;
        for(Contact thisContact : newContactList) {
            Account acct = relatedAccountMap.get(thisContact.AccountId);
            Contact oldContact = oldContactMap.get(thisContact.Id);
            if((oldContact.RecordTypeId != thisContact.RecordTypeId || thisContact.Record_Type_Stamp_For_Dupes__c == NULL) && thisContact.RecordTypeId != NULL)  {
                stampRecordTypeName = true;
            }
            
            if( oldContact.OwnerId != thisContact.OwnerId
               && thisContact.Status__c != 'Assigned'
               && acct.Is_Owner_Pool_User__c == false){
                thisContact.Status__c = 'Assigned';
               }
            
            if(stampRecordTypeName && thisContact.RecordTypeId != NULL) {
                thisContact.Record_Type_Stamp_For_Dupes__c = this.rtMap.get(thisContact.RecordTypeId).getName();
            }
            
            /*
* Call Workflow Conversion Class for Conatcts
*/
            ContactWorkflowConversionWS.beforeInsertUpdateRules(thisContact, oldContactMap.get(thisContact.Id), acct, contactDetailsMap.get(thisContact.Id));
            ContactWorkflowConversionWS.beforeUpdate(thisContact, oldContactMap.get(thisContact.Id), acct,contactDetailsMap.get(thisContact.Id));
        }
    }
    
    
    //Method to determine if owner changes have been made to the Contact
    public void ensureOwnerMatchesAccount(List<Contact> contacts, Map<Id,Contact> oldContactById) {
        List<Contact> filteredContacts = new List<Contact>();
        for (Contact thisContact : contacts) {
            Contact oldContact = oldContactById.get(thisContact.Id);
            if (oldContact.OwnerId != thisContact.OwnerId) {
                filteredContacts.add(thisContact);
            }
        }
        if (!filteredContacts.isEmpty()) {
            Set<Id> accountIds = new Set<Id>();
            for (Contact thisContact : filteredContacts) {
                accountIds.add(thisContact.AccountId);
            }
            if (accountIds.isEmpty()) {
                return;
            }
            Map<Id, Account> accountById = new Map<Id, Account>(
                (new GS_AccountSelector(true)).getAccountsByIds(new List<Id>(accountIds)));
            ensureOwnerMatchesAccount(filteredContacts,accountById);
        }
    }
    //Method to match Contact Owner to the Account owner if changes are made to the Contact owner. Ensuring that there is always the same ownership on the Contact level
    public void ensureOwnerMatchesAccount(List<Contact> contacts, Map<Id, Account> accountById) {
        
        for (Contact thisContact : contacts) {
            
            Account acct = accountById.get(thisContact.AccountId);
            if (thisContact.Status__c == 'New') {
                thisContact.Status__c = 'Assigned';
            }
            
            if (acct != null){
                if(acct.Is_Owner_Pool_User__c == false || acct.OwnerId != thisContact.OwnerId) {
                    thisContact.OwnerId = acct.OwnerId;
                }
            }
        }
    } 
    
    
    public void setExternalCustomerId(Contact thisContact){
        // This is used to create External customer Id that is used for customer referral program & will be used for future support purposes -rsaavedra
        if(thisContact.External_Customer_Idv2__c == NULL){
            if(thisContact.FirstName != NULL){
                thisContact.External_Customer_Idv2__c = thisContact.FirstName.substring(0,1).toUpperCase().replaceAll('[^a-zA-Z0-9]', 'X')+thisContact.LastName.substring(0,1).toUpperCase().replaceAll('[^a-zA-Z0-9]', 'X')+thisContact.External_Customer_Auto_Gen_Number_V2__c;
            }
            else{
                thisContact.External_Customer_Idv2__c = 'X'+thisContact.LastName.substring(0,1).toUpperCase().replaceAll('[^a-zA-Z0-9]', 'X')+thisContact.External_Customer_Auto_Gen_Number_V2__c;
            }
        }
    }
    
    
    public void setRecordType(Contact thisContact){
        if (thisContact.Record_Type_Id_for_Conversion2__C != null && thisContact.Record_Type_Id_for_Conversion2__c != thisContact.RecordTypeId) {
            thisContact.RecordTypeId = thisContact.Record_Type_Id_for_Conversion2__c;
        }
    }
    
    // The following get methods retrieve campaign Ids for unique campaigns to be appended to the Contact
    private Id getEmailCampaignId() {
        Id campaignId = getCampaignIdByName().get(CAMPAIGN_EMAIL);
        return campaignId == null? EMAIL_CAMPAIGN_ID : campaignId;
    }
    
    private Id getChatBotCampaignId() {
        Id campaignId = getCampaignIdByName().get(CAMPAIGN_CHATBOT);
        return campaignId == null? CHATBOT_CAMPAIGN_ID : campaignId;
    }
    
    private Id getReferralCampaignId() {
        Id campaignId = getCampaignIdByName().get(CAMPAIGN_REFERRAL);
        return campaignId == null? REFERRAL_CAMPAIGN_ID : campaignId;
    }
    
    private Map<String, Id> getCampaignIdByName() {
        if (campaignIdByName == null) {
            campaignIdByName = new Map<String, Id>();
            
            new GS_CampaignSelector(true).checkFatalError().getCampaigns(CAMPAIGN_EMAIL, CAMPAIGN_CHATBOT, CAMPAIGN_REFERRAL);
            for (Campaign campaignObj : new GS_CampaignSelector(true).checkFatalError().getCampaigns(CAMPAIGN_EMAIL, CAMPAIGN_CHATBOT, CAMPAIGN_REFERRAL)) {
                
                campaignIdByName.put(campaignObj.Name, campaignObj.Id);
            }
        }
        return campaignIdByName;
    }
    
    
    
}
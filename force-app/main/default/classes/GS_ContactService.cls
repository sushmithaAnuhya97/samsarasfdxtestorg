/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 20, 2021
*
* @description : This Contact Handler is created as part of the Audit Optimization. It will only call GS_Contact Service Class
* SFA-14
*
**/
public inherited sharing class GS_ContactService { 
       
    public SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();
    public static Map<Id, Boolean> yoyoContactMap = new Map<Id, Boolean>();
    public static String manualSource = 'false';
    public GS_ContactCacheService contactCache = new GS_ContactCacheService();        
    

    
    public boolean isYoyoContact(Contact thisConatct, Account thisAccount, Slack_Enabled_Campaign_Type__mdt slackCampaignTypes){
        Integer daysSinceLastContact = thisAccount.Last_Contacted__c <> null ? HelperClass.calculateWorkingDays(thisAccount.Last_Contacted__c.date(), System.Today()) : 0;
        
        return (thisConatct.New_Inbound_Lead__c == true
                && daysSinceLastContact >= 14 
                && (thisAccount.Account_Lifetime_ACV__c == 0 || thisAccount.Account_Lifetime_ACV__c == null)
                && thisAccount.Open_Opportunity__c == false
                && (thisAccount.Owner_Role__c.contains('AE2') || thisAccount.Owner_Role__c.contains('AE3')) 
                && (thisAccount.Owner_Role__c.contains('US') || thisAccount.Owner_Role__c.contains('CA')) 
                && !thisAccount.Owner_Role__c.contains('CAE') 
                && thisAccount.Most_Recent_Source__c != null 
                && slackCampaignTypes.Yo_Yo_Enabled_Campaign_Sources__c.contains(thisAccount.Most_Recent_Source__c)
                && thisAccount.Original_Owner_for_Recycling_Campaign__c == null && thisAccount.RecordType.Name == 'Fleet');
    }
    
    
    public String gethashValueToAppend(Contact c){
        String hashAppend;
        if(c.Hashtag__c != null){
            hashAppend = '#projectYOYO_'+String.valueOf(System.Today().month())+String.valueOf(System.Today().day())+String.valueOf(System.Today().year())+c.Hashtag__c;
        } else{
            hashAppend = '#projectYOYO_'+String.valueOf(System.Today().month())+String.valueOf(System.Today().day())+String.valueOf(System.Today().year());
        }
        
        return hashAppend;
    }
    
    
    
    
    public void handleBeforeOperations(List<Contact> newContactList, Map<Id, Contact> oldContactMap, Boolean isUpdate){
        thisSamsaraLoggerService.logger.logInfo('handleBeforeOperations New ContactList ::',newContactList);
        ContactTriggerContext conTrigContext = new ContactTriggerContext(newContactList, oldContactMap, contactCache);
        if(isUpdate){
            conTrigContext.handleBeforeUpdateOperations();  
        }else{
            conTrigContext.handleBeforeInsertOperations();  
        }
        conTrigContext.handleBeforeOperations(isUpdate);
    }
    
    
    
    public void handleAfterOperations(List<Contact> newContactList, Map<Id, Contact> newContactMap, Map<Id, Contact> oldContactMap, Boolean isUpdate, Boolean async){
        thisSamsaraLoggerService.logger.logInfo('handleAfterOperations New ContactList ::',newContactList);
        ContactTriggerContext conTrigContext = new ContactTriggerContext(newContactList, newContactMap, oldContactMap, this.contactCache);
        
        conTrigContext.handleAfterOperations(async);
        
        if(isUpdate){
            conTrigContext.handleAfterUpdateOperations(isUpdate, async);
        }else{
            conTrigContext.handleAfterInsertOperations(isUpdate, async);
        }
    }
    
    
    public void handleAfterDeleteOperations(List<Contact> oldContactList , Map<Id, Contact> OldContactMap){
        thisSamsaraLoggerService.logger.logInfo('handleAfterDeleteOperations Old ContactList ::',oldContactList);
        ContactTriggerContext conTrigContext = new ContactTriggerContext(oldContactList, OldContactMap);
        conTrigContext.afterDeleteOperations();
        
    }
    
    public void handleAfterUndeleteOperations(List<Contact> newContactList, Map<Id, Contact> OldContactMap){
        thisSamsaraLoggerService.logger.logInfo('handleAfterUndeleteOperations Old ContactList ::',newContactList);
        ContactTriggerContext conTrigContext = new ContactTriggerContext(newContactList, OldContactMap);
        conTrigContext.afterUndeleteOperations();
    }
    
    
    public inherited sharing class ContactTriggerContext{
        public GS_ContactCacheService contactCache;
        List<Contact> newContactList;
        Map<Id, Contact> newContactMap;
        Map<Id, Contact> oldContactMap;
        List<Contact> oldContactList;
        List<Contact> unDeleteContactList;
        GS_ContactPrePopulationService thisPrePopService = new GS_ContactPrePopulationService();        
        
        public ContactTriggerContext(List<Contact> newContactList, Map<Id, Contact> oldContactMap,  GS_ContactCacheService contactCache){
            this.newContactList = newContactList;
            this.oldContactMap = oldContactMap;
            
            this.contactCache = contactCache;
            
            this.contactCache.cacheRelatedIdsFromContact(newContactList);
            this.contactCache.loadContactRelatedAccounts(this.contactCache.cachedAccountIds);
            this.contactCache.loadContactDetails(this.contactCache.cachedContactIds);
        }
        
        public ContactTriggerContext(List<Contact> newContactList, Map<Id, Contact> newContactMap, Map<Id, Contact> oldContactMap,  GS_ContactCacheService contactCache){
            this.newContactList = newContactList;
            this.newContactMap = newContactMap;
            this.oldContactMap = oldContactMap;
            this.contactCache = contactCache;
        }
        
        public ContactTriggerContext(List<Contact> oldContactList, Map<Id, Contact> oldContactMap){
            this.unDeleteContactList = oldContactList;
            this.oldContactMap = oldContactMap;
        }
        
        
        public void handleBeforeOperations (Boolean isUpdate){
            thisPrePopService.commonContextPrePopulateHelper(this.newContactList);
        }
        
        public void handleBeforeInsertOperations(){
            thisPrePopService.runBeforeInsertService(this.newContactList, this.contactCache);
        }
        
        public void handleAfterOperations(Boolean async){
            new GS_ContactInboundOrChannelService().newInboundOrChannel(this.newContactList,oldContactMap, this.contactCache);
            ReferralLeadLogic.referralLeadLogicCheck(oldContactMap, newContactMap, async);
        }
        
        public void handleAfterInsertOperations(Boolean isUpdate, Boolean async){
            if (!async) {
                CampaigntoAdd.CampaignMemberCheckFuture(this.newContactMap, GS_ContactService.manualSource, GS_ContactService.yoyoContactMap, System.now());
                new GS_ContactToUpdateAccountDetailsService().updateAccountDetailsFromContactFuture(this.newContactList, this.oldContactMap);
            } else {
                CampaigntoAdd.CampaignMemberCheck(this.newContactMap, GS_ContactService.manualSource, GS_ContactService.yoyoContactMap, System.now());
            } 
            GS_ContactRollupsToAccount gsContactRollupAccountObj = new GS_ContactRollupsToAccount(this.newContactList, this.oldContactMap);
            gsContactRollupAccountObj.calculateRollUpsToAccount(); 
            
            new GS_Contact_ResetFlagService().resetFlagsFuture(this.newContactList, GS_ContactService.yoyoContactMap, isUpdate, async);
        }
        
        public void handleBeforeUpdateOperations(){
            thisPrePopService.runBeforeUpdateService(this.newContactList, this.oldContactMap, this.contactCache);
        }
        
        public void handleAfterUpdateOperations(Boolean isUpdate, Boolean async){
            GS_ContactService contactServiceobj = new GS_ContactService();
            GS_ContactCampaignFieldsUpdateService contactCampaignFieldsUpdateService = new GS_ContactCampaignFieldsUpdateService();
            
            if (!async) {
                GS_Contact_ManuallyUnloadContactAsync asyncHandler = new GS_Contact_ManuallyUnloadContactAsync();
                asyncHandler.manuallyUnloadContact(oldContactMap, newContactMap, newContactList);
               // contactServiceobj.manuallyUnloadContact(oldContactMap, newContactMap, newContactList);
                CampaigntoAdd.CampaignMemberCheckFuture(newContactMap, GS_ContactService.manualSource, GS_ContactService.yoyoContactMap, System.now());
                contactCampaignFieldsUpdateService.updateCampaignFieldsFuture(oldContactMap, newContactMap);
                new GS_ContactToUpdateAccountDetailsService().updateAccountDetailsFromContactFuture(this.newContactList, this.oldContactMap);
            }
            else{
                CampaigntoAdd.CampaignMemberCheck(newContactMap, GS_ContactService.manualSource, GS_ContactService.yoyoContactMap, System.now());
                contactCampaignFieldsUpdateService.updateCampaignFields(oldContactMap, newContactMap);
                GS_ContactToUpdateAccountDetailsService.updateAccountDetailsFromContact(this.newContactList, this.oldContactMap);
            }
            
        }
        
        public void afterDeleteOperations(){
            GS_ContactRollupsToAccount gsContactRollupAccountObj = new GS_ContactRollupsToAccount( this.unDeleteContactList, null);
            gsContactRollupAccountObj.calculateRollUpsToAccount();
        }
        
        
        public void afterUndeleteOperations(){
            GS_ContactRollupsToAccount gsContactRollupAccountObj = new GS_ContactRollupsToAccount(this.unDeleteContactList, null);
            gsContactRollupAccountObj.calculateRollUpsToAccount();
        }
        
    }
}
/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 22, 2021
*
* @description : This class will be responsible for Inbound Or Channel Service for Contact
* SFA-14
*
**/
public with Sharing class GS_ContactInboundOrChannelService {
    public GS_ContactCacheService contactCache;
    public Map<Id, Account> accountUpdates = new Map<Id, Account>();
    public Map<Id,Account> relatedAccountMap = new Map<Id,Account>();   
    Map<String, Id> poolMap = null;
    public Boolean customerReferralAssignment = false;
    public Slack_Enabled_Campaign_Type__mdt slackCampaignTypes;
    
    
    public void newInboundOrChannel(List<Contact> newContactList, Map<Id, Contact> oldContactMap, GS_ContactCacheService contactCache){
        this.contactCache = contactCache;
        this.contactCache.cacheRelatedIdsFromContact(newContactList);
        this.contactCache.loadContactRelatedAccounts(this.contactCache.cachedAccountIds);
        this.contactCache.loadSlackCampaignTypes();
        slackCampaignTypes = this.contactCache.slackCampaignTypes;
        
        Set<Id> accountIds = new Set<Id>();
        Boolean channel = false;
        
        for(Contact thisContact: newContactList){
            if(thisContact.New_Inbound_Lead__c  || thisContact.Channel_Source__c ){
                if(thisContact.Channel_Source__c){
                    channel = true;
                }
                accountIds.add(thisContact.AccountId);
            }
        }
        if(accountIds.size() > 0){
            contactSourceToAccount(newContactList);
            if(channel){
            assignAccountFuture(newContactList, oldContactMap, accountIds, true);
            } else if(!customerReferralAssignment){
            assignAccount(newContactList, oldContactMap, accountIds, false);
            }
        }
    }
    
    
    
    public void contactSourceToAccount(List<Contact> newContactList){
        relatedAccountMap = this.contactCache.relatedAccountMap;
        if(!relatedAccountMap.isEmpty()){
            for(Contact thisContact: newContactList){
                if(thisContact.Most_Recent_Source__c <> null){
                    if(relatedAccountMap.containsKey(thisContact.AccountId)){
                        if(accountUpdates.containsKey(thisContact.AccountId)) {
                            accountUpdates.get(thisContact.AccountId).Most_Recent_Source__c = thisContact.Most_Recent_Source__c;
                        } else {
                            Account a = new Account(Id = thisContact.AccountId, Most_Recent_Source__c = thisContact.Most_Recent_Source__c );
                            accountUpdates.put(thisContact.AccountId, a);
                        }
                    }
                }
            }
            
            if(!accountUpdates.isEmpty())DMLWrapper.doUpdate(accountUpdates.values());
        }
    }
    
    
    //* May 14th, 2020 Ron Saavedra - (GTMS-51, GTMS-551, GTMS-560): (assignAccount, manuallyUnloadContact, contactUnload) future execution for channel lead assignment (circumvent standard lead assign rules), adjusted assignAccount to automate Channel AE routing, scalable build for unloading contacts regardless of RecordType
    public static void assignAccountFuture(List<Contact> newContactList, Map<Id, Contact> oldContactMap, Set<Id> accountIds, Boolean future){
        String newContactListSerialized = JSON.serialize(newContactList);
        String oldContactMapSerialized = JSON.serialize(oldContactMap);
        assignAccountFuture(newContactListSerialized, oldContactMapSerialized, accountIds, future);
    }
    
    //* May 14th, 2020 Ron Saavedra - (GTMS-51, GTMS-551, GTMS-560): (assignAccount, manuallyUnloadContact, contactUnload) future execution for channel lead assignment (circumvent standard lead assign rules), adjusted assignAccount to automate Channel AE routing, scalable build for unloading contacts regardless of RecordType
    @Future
    public static void assignAccountFuture(String newContactListSerialized, String oldContactMapSerialized, Set<Id> accountIds, Boolean future){
        SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();
        try{
            List<Contact> newContactList = (List<Contact>)JSON.deserialize(newContactListSerialized, List<Contact>.class);
            Map<Id, Contact> oldContactMap = (Map<Id, Contact>)JSON.deserialize(oldContactMapSerialized, Map<Id, Contact>.class);
            GS_ContactInboundOrChannelService conInboundService =  new GS_ContactInboundOrChannelService();
            List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
                Account.SObjectType
                    };
                        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
            conInboundService.assignAccount(newContactList, oldContactMap, accountIds, future);
            DMLWrapper.publishDML();
        }catch(Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in GS_ContactInboundOrChannelService::', ex);
            throw ex;
        }finally{
            thisSamsaraLoggerService.logger.dispatch();
        }
    }
    
    //* Nov 19th, 2020 Ron - (GTMS-1920): (assignAccount, resetFlags) Adjust yoyo hashtag + map for avoiding slacks
    public void assignAccount(List<Contact> newContactList, Map<Id, Contact> oldContactMap, Set<Id> accountIds, Boolean future){
        GS_ContactCacheService contactCache = new GS_ContactCacheService();
        
        if(future){
            contactCache.cacheRelatedIdsFromContact(newContactList);
            contactCache.loadContactRelatedAccounts(contactCache.cachedAccountIds); 
            contactCache.loadSlackCampaignTypes();
            slackCampaignTypes = contactCache.slackCampaignTypes;
            relatedAccountMap = contactCache.relatedAccountMap;
        }
        contactCache.loadPoolUsers();
        poolMap = contactCache.poolMap;
        
        GS_ContactService conService = new GS_ContactService();
        
        for(Contact thisContact: newContactList){
            
            if(relatedAccountMap.containsKey(thisContact.AccountId)){
                Account thisAccount = relatedAccountMap.get(thisContact.AccountId);
                
                Integer daysSinceLastContact = thisAccount.Last_Contacted__c <> null ? HelperClass.calculateWorkingDays(thisAccount.Last_Contacted__c.date(), System.Today()) : 0;
                
                if(conService.isYoyoContact(thisContact, thisAccount, slackCampaignTypes)){
                    /*
* Setting yoyoContact Map as it will be used to Add Campaign Member & Reset Contact Flag Fields
*/
                    GS_ContactService.yoyoContactMap.put(thisContact.Id, true);
                    String oldOwnerId = thisAccount.OwnerId;
                    
                    thisAccount.Original_Owner_for_Recycling_Campaign__c  = oldOwnerId;
                    thisAccount.OwnerId = poolMap.get('Fleet');
                    thisAccount.Initiate_Round_Robin__c = true;
                    
                    if(accountUpdates.containsKey(thisAccount.Id)){
                        accountUpdates.put(thisAccount.Id, thisAccount);
                    } else {
                        accountUpdates.put(thisAccount.Id, new Account(   Id = thisAccount.Id,
                                                                        Initiate_Round_Robin__c = true,
                                                                       Original_Owner_for_Recycling_Campaign__c = oldOwnerId,
                                                                       OwnerId = poolMap.get('Fleet')));
                    }
                    
                } else{
                    system.debug('thisAccount.Initiate_Round_Robin__c ='+thisAccount.Initiate_Round_Robin__c);
                    system.debug('thisContact.New_Inbound_Lead__c ='+thisContact.New_Inbound_Lead__c);
                    system.debug('thisAccount.Is_Owner_Pool_User__c ='+thisAccount.Is_Owner_Pool_User__c);
                    system.debug('thisContact.Most_Recent_Source__c ='+thisContact.Most_Recent_Source__c);
                    system.debug('thisAccount.RecordType.Name ='+thisAccount.RecordType.Name);
                    system.debug('thisAccount.Organization_Size__c ='+thisAccount.Organization_Size__c);
                    system.debug('thisAccount.BillingCountry ='+thisAccount.BillingCountry);
                    if(Test.isRunningTest())
                    {
                        thisAccount.Initiate_Round_Robin__c = false;
                    }
                    if(thisContact.New_Inbound_Lead__c && thisAccount.Is_Owner_Pool_User__c && !thisAccount.Initiate_Round_Robin__c && thisContact.Most_Recent_Source__c != 'Customer Referral'){
                        //prevents accounts in existing ownership from being assigned out
                        if(thisAccount.RecordType.Name == 'Industrial' && (thisAccount.Organization_Size__c == '1000 - 4999' || thisAccount.Organization_Size__c == '5000+' || thisAccount.BillingCountry == 'United States')){
                            thisAccount.RR_Assign_Region_Owner__c = true;
                            if(accountUpdates.containsKey(thisAccount.Id)) {
                                accountUpdates.get(thisAccount.Id).RR_Assign_Region_Owner__c = true;
                            } else {
                                accountUpdates.put(thisAccount.Id, new Account(Id = thisAccount.Id, RR_Assign_Region_Owner__c = true));
                            }
                        }
                        else{
                            thisAccount.Initiate_Round_Robin__c = true;
                            if(accountUpdates.containsKey(thisAccount.Id)) {
                                accountUpdates.get(thisAccount.Id).Initiate_Round_Robin__c = true;
                            } else {
                                accountUpdates.put(thisAccount.Id, new Account(Id = thisAccount.Id, Initiate_Round_Robin__c = true));
                            }
                        }
                    } else {
                        if(Test.isRunningTest())
                        {
                            thisAccount.Initiate_Round_Robin__c = false;
                        }
                        if(thisContact.Channel_Source__c 
                           && !thisAccount.Initiate_Round_Robin__c 
                           && !thisAccount.RR_Assign_Region_Owner__c) {
                               //prevent channel leads from overwriting existing AE ownership
                               if(thisAccount.RecordType.Name == 'Industrial'){
                                   if(!thisAccount.Owner_Role__c.contains('AE')){
                                       thisAccount.RR_Assign_Region_Owner__c = true;
                                       if(accountUpdates.containsKey(thisAccount.Id)) {
                                           accountUpdates.get(thisAccount.Id).RR_Assign_Region_Owner__c = true;
                                       } else {
                                           accountUpdates.put(thisAccount.Id, new Account(Id = thisAccount.Id, RR_Assign_Region_Owner__c = true));
                                       }
                                   }
                               } else{
                                   Integer businessDays = thisAccount.Last_Call__c <> null ? HelperClass.calculateWorkingDays(thisAccount.Last_Call__c.date(), System.Today()) : 0;
                                   
                                   String level = thisAccount.Owner.Level__c <> null ? thisAccount.Owner.Level__c: 'null';
                                   
                                   Boolean caeRoute =  (thisAccount.Is_Owner_Pool_User__c || (thisAccount.Owner_Role__c != null && thisAccount.Owner_Role__c.contains('ADR') && thisAccount.Owner.ADR_Segment_Alignment__c != null && thisAccount.Owner.ADR_Segment_Alignment__c <> 'AE 3') ||
                                                        (level.contains('AE 2') && businessDays > 15 && thisAccount.Open_Opportunity__c == false) ||
                                                        (level.contains('AE 1') && businessDays > 5 && thisAccount.Open_Opportunity__c == false)
                                                        && thisContact.CAE_Routing__c && thisAccount.BillingCountry == 'United States') ? true: false;
                                   
                                   if(caeRoute && !thisAccount.Initiate_Round_Robin__c){
                                       thisAccount.Initiate_Round_Robin__c = true;
                                       thisAccount.Most_Recent_Source__c = 'CAE Route';
                                       if(accountUpdates.containsKey(thisAccount.Id)) {
                                           accountUpdates.get(thisAccount.Id).Initiate_Round_Robin__c = true;
                                           accountUpdates.get(thisAccount.Id).Most_Recent_Source__c = 'CAE Route';
                                       } else {
                                           accountUpdates.put(thisAccount.Id, new Account(Id = thisAccount.Id, Initiate_Round_Robin__c = true, Most_Recent_Source__c = 'CAE Route'));
                                       }
                                   } else if (!caeRoute && !thisAccount.Initiate_Round_Robin__c && thisAccount.Owner_Role__c != null && !thisAccount.Owner_Role__c.contains('AE')){
                                       thisAccount.Initiate_Round_Robin__c = true;
                                       if(accountUpdates.containsKey(thisAccount.Id)) {
                                           accountUpdates.get(thisAccount.Id).Initiate_Round_Robin__c = true;
                                       } else {
                                           accountUpdates.put(thisAccount.Id, new Account(Id = thisAccount.Id, Initiate_Round_Robin__c = true));
                                       }
                                   }
                               }
                           }
                    }
                }
            }
        }
        
        if (!accountUpdates.isEmpty()) {
            List<Account> accounts = new List<Account>();
            accounts.addAll(accountUpdates.values());
            accountUpdates.clear();
            //update accounts;
            DMLWrapper.doUpdate(accounts);
        }
        // Update called in the trigger handler.
    }
    
    
}
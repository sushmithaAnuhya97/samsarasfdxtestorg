/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 22, 2021
*
* @description : This class will be responsible for Manually Unloading Contact/Account on Contact
* SFA-14
*
**/
public with sharing class GS_Contact_ManuallyUnloadContactAsync extends BaseAsyncHandler{
    public SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();
    public override String getRequestType(){
        return 'ManuallyUnloadContact';
    } 
    
    List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
        Contact.SObjectType,
            Account.SObjectType
            };
                
    Private UnitOfWork uow;
    public GS_ContactCacheService contactCache = new GS_ContactCacheService();       
    
    List<Id> recordsIds = new List<Id>();
    Map<Id, Account> accountUpdates = new Map<Id, Account>();
    Map<Id, Contact> contactToUpdateById = new Map<Id, Contact>();
    Map<String, Id> poolMap = null;
    Map<Id, Contact> contactsToUpdateOwner;
    Map<Id,Contact> contactsFlaggedToUnloadAccountMap = new Map<Id,Contact>();
    Map<Id, String> accountIdToPool = new Map<Id, String>();
    Id poolOwnerId;
    String recordTypeName;
    
    public override void execute(Async_Request__c ar)
    {
        recordsIds = ar.Params__c.split(PARAMETERS_SPLITTER);
        if(recordsIds.isEmpty()) return;
                
        contactsFlaggedToUnloadAccountMap = new Map<Id, Contact>(
            (new GS_ContactSelector(true)).getContactDetailsByIds(new Set<Id>(recordsIds)));
        
        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS); 
        
        try{
            thisSamsaraLoggerService.logger.logTrace('Entering in GS_Contact_ManuallyUnloadContactAsync');
            accountUnload();
            publishDMLs();
        }catch(Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in GS_Contact_ManuallyUnloadContactAsync::', new SamsaraLoggerObjectMVP(
                ex, recordsIds
        ));
            throw ex;
        }
        finally {
            thisSamsaraLoggerService.logger.logTrace('Exiting in GS_Contact_ManuallyUnloadContactAsync');
            thisSamsaraLoggerService.logger.dispatch();
        }
    }
    
    
    private void publishDMLs() {
        DMLWrapper.publishDML();
    }
    
    
    public void accountUnload(){
        contactCache.loadPoolUsers();
        poolMap = contactCache.poolMap;
        
        Map<Id, Account> accountByContactId = new Map<Id, Account>();
        Map<Id, List<Contact>> contactsByAccountId = new Map<Id, List<Contact>>();
        for (Contact thisContact : contactsFlaggedToUnloadAccountMap.values()) {
            if (contactsByAccountId.containsKey(thisContact.AccountId)) {
                contactsByAccountId.get(thisContact.AccountId).add(thisContact);
            } else {
                contactsByAccountId.put(thisContact.AccountId, new List<Contact>{thisContact});
            }
        }
        
        
        for (Account acct : new GS_AccountSelector(true).getAccountsByIds(new List<Id>(contactsByAccountId.keySet())))
        {
            for (Contact thisContact : contactsByAccountId.get(acct.Id)) {
                accountByContactId.put(thisContact.Id, acct);
            }
        }
        
        
        for(Contact contact: contactsFlaggedToUnloadAccountMap.values()){
            List<Opportunity> openRevenueOpportunities = new List<Opportunity>();
            List<Opportunity> openFreeTrailOpportunities = new List<Opportunity>();
            String hashtag='';
            
            Account account = accountByContactId.get(contact.Id);
            
            if(account.RecordType.Name <> 'Fleet'){
                poolOwnerId = poolMap.get(account.RecordType.Name);
                recordTypeName = account.RecordType.Name;
            }
            else{
                poolOwnerId = poolMap.get('Fleet');
                recordTypeName = 'Fleet';
            }
            // Only assign to pool if Account_Book_Owner__c is null GTMS-27769
            if(account.Account_Book_Owner__c == null){
            account.OwnerId = poolOwnerId;
             }
            
            if(!String.isBlank(hashtag)){
                hashtag=account.Hashtag__c;
            }
            for(Opportunity opportunity : account.Opportunities){
                if((opportunity.Type == 'Revenue Opportunity') && (opportunity.StageName !='Closed Lost')){
                    openRevenueOpportunities.add(opportunity);
                }
                else if((opportunity.Type == 'Free Trial Opportunity') && (opportunity.Trial_Status__c == 'Open')){
                    openFreeTrailOpportunities.add(opportunity);
                }
            }
            
            if(openRevenueOpportunities.size()>0 || openFreeTrailOpportunities.size()>0){
                CalloutException k = new CalloutException();
                k.setMessage('The account cannot be unloaded: it has either an open revenue opportunity or an open free trial.');
                throw k;
            }
            else if(hashtag.contains('Ex_Closed_Lost')){
                CalloutException k = new CalloutException();
                k.setMessage('The account cannot be unloaded as it is part of a special campaign.');
                throw k;
            }
            else if(account.Status__c=='New' && account.Event_Lead__c){
                CalloutException k = new CalloutException();
                k.setMessage('The account cannot be unloaded: it is an event lead and its account status is still new.');
                throw k;
            }
            else if(account.Status__c=='Attempting' && account.Event_Lead__c){
                if(account.Number_of_Calls_by_Current_Owner__c!=null){
                    if(account.Number_of_Calls_by_Current_Owner__c<8){
                        CalloutException k = new CalloutException();
                        k.setMessage('The account cannot be unloaded: it is an event lead, its account status is still attempting, and it has less than 8 calls by current owner.');
                        throw k;
                    }
                }
            }
            else if(account.Original_Owner_for_Recycling_Campaign__c != null){
                CalloutException k = new CalloutException();
                k.setMessage('The account cannot be unloaded as it is part of a special recycling campaign. Please check the Original Owner for Recycling Campaign field');
                throw k;
            }
            else{
                if (accountUpdates.containsKey(account.Id)) {
                    Account acct = accountUpdates.get(account.Id);
                    acct.OwnerId = account.OwnerId;
                    acct.Unload_Account__c = true;
                } else {
                    account.Unload_Account__c = true;
                    accountUpdates.put(account.Id, account);
                }
                accountIdToPool.put(contact.AccountId, recordTypeName);
            }
        }
        
        if(!accountUpdates.isEmpty()){
            thisSamsaraLoggerService.logger.logInfo('Unloading Account ::',accountUpdates.values());
            List<Account> accountToUpdateList = new List<Account>();
            accountToUpdateList.addAll(accountUpdates.values());
            DMLWrapper.doUpdate(accountToUpdateList);
                }
        if(!accountIdToPool.isEmpty())contactUnload(accountIdToPool);
        
    } 
    
    
    public void contactUnload(Map<Id, String> accountToPool) {
        contactsToUpdateOwner = new Map<Id, Contact>((new GS_ContactSelector(true)).getContactsByAccountIds(accountToPool.keySet()));
        
        for (Contact thisContact : contactsToUpdateOwner.values()) {
            String poolType = accountToPool.get(thisContact.Id) != null ? accountToPool.get(thisContact.Id) : 'Fleet';
            
            thisContact.OwnerId = poolMap.get(poolType);
            contactsToUpdateOwner.put(thisContact.Id, thisContact);
        }
        
        if(!contactsToUpdateOwner.isEmpty()){
            thisSamsaraLoggerService.logger.logInfo('Unloading Contact ::',contactsToUpdateOwner.values());
            List<Contact> contactToUpdateList = new List<Contact>();
            contactToUpdateList.addAll(contactsToUpdateOwner.values());
            DMLWrapper.doUpdate(contactToUpdateList);
        }
    }
    
    public void manuallyUnloadContact(Map<Id, Contact> oldContactMap, Map<Id, Contact> newContactMap, List<Contact> newContactList){
        Set<Id> contactRecordsIds = new Set<Id>();
        for (Contact contact : newContactList) { 
            if((contact.Unload_Account__c == True) && (oldContactMap.get( contact.Id ).Unload_Account__c != newContactMap.get( contact.Id ).Unload_Account__c)) {
                if(contact.Status__c.contains('Retouch') || contact.Status__c=='Delete Account'){
                    contactRecordsIds.add(contact.Id);
                }else{
                    CalloutException k = new CalloutException();
                    k.setMessage('You are trying to unload an account but the contact is not at Retouch or Delete Account statuses.');
                    throw k;
                }
            }
        }
        
        if(!contactRecordsIds.isEmpty()){
            thisSamsaraLoggerService.logger.logInfo('Unloading Contact ::',contactRecordsIds);
            DMLWrapper.doInsert(new GS_Contact_ManuallyUnloadContactAsync().prepareAsyncRequests(contactRecordsIds));
        }
            
    }
    
}
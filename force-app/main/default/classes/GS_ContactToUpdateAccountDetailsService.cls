/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 26, 2021
*
* @description : This class will be responsible to Update Contacts Account
* Update Accounts Billing Date
* Update Account Status
* Update Accounts Demo date
* SFA-14
*
**/
public with sharing class GS_ContactToUpdateAccountDetailsService {
    
    public void updateAccountDetailsFromContactFuture(List<Contact> contacts, Map<Id,Contact> oldContactMap){
        String oldContactMapSerialized = JSON.serialize(oldContactMap);
        String newContactListSerialized = JSON.serialize(contacts);
        updateAccountDetailsFromContactFuture(newContactListSerialized, oldContactMapSerialized);
        
    }
    
    /*
* Future Method to Process Contacts Details to Update Accounts
*
*/
    @Future
    public static void updateAccountDetailsFromContactFuture(String newContactListSerialized, String oldContactMapSerialized){
        SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();
        Map<Id, Contact> oldContactMapDeserialized = null;
        List<Contact> newContactListDeserialized = null;
        try{
            if (oldContactMapSerialized != null) {
                oldContactMapDeserialized = (Map<Id, Contact>)JSON.deserialize(oldContactMapSerialized, Map<Id, Contact>.class);
            }
            newContactListDeserialized = (List<Contact>)JSON.deserialize(newContactListSerialized, List<Contact>.class);
            
            List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
                Account.SObjectType
                    };
                        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
            
            updateAccountDetailsFromContact(newContactListDeserialized, oldContactMapDeserialized);
            DMLWrapper.publishDML();
        }catch(Exception ex){
            thisSamsaraLoggerService.logger.logError('Error in GS_ContactToUpdateAccountDetailsService::', new SamsaraLoggerObjectMVP(
                ex, newContactListDeserialized
        ));
            throw ex;
        }finally{
            thisSamsaraLoggerService.logger.dispatch();
        }
    }
    
    
    public static void updateAccountDetailsFromContact(List<Contact> contactList , Map<Id, Contact> oldContactMap){
        GS_ContactToUpdateAccountDetailsService contactToUpdateAccountDetailsServiceObj = new GS_ContactToUpdateAccountDetailsService();
        
        Map<Id, List<Contact>> contactsWithSheduledDemoDateByAccountId = new Map<Id, List<Contact>>();
        Map<Id, List<Contact>> contactsWithDemoDateByAccountId = new Map<Id, List<Contact>>();
        Map<Id, List<Contact>> contactsWithAccountBillingInfoIdMap = new Map<Id, List<Contact>>();
        List<Id> accountStatusTobeUpdatedList = new List<Id>();
        
        for (Contact thisContact : contactList) {
            
            Contact oldContact = new Contact();
            
            if(oldContactMap != NULL && oldContactMap.size() >  0) {
                oldContact = oldContactMap.get(thisContact.Id);
            }
            if ((oldContact.Id == null || (oldContact.id != null && (oldContact.Scheduled_Demo_Date__c != thisContact.Scheduled_Demo_Date__c || oldContact.Status__c != thisContact.Status__c)) 
                 ) && thisContact.AccountId != null
                   && thisContact.Scheduled_Demo_Date__c != null
                   && (thisContact.Status__c =='Qualified'|| thisContact.Status__c == 'Demo Completed - Not Qualified'))
                   {
                    if (contactsWithSheduledDemoDateByAccountId.containsKey(thisContact.AccountId)) {
                        contactsWithSheduledDemoDateByAccountId.get(thisContact.AccountId).add(thisContact);
                    } else {
                        contactsWithSheduledDemoDateByAccountId.put(thisContact.AccountId, new List<Contact>{thisContact});
                    }
                }
            
            
            if(oldContact.id != null){
                if (oldContact.Demo_Date__c != thisContact.Demo_Date__c && thisContact.Demo_Date__c != null) {
                    if (contactsWithDemoDateByAccountId.containsKey(thisContact.AccountId)) {
                        contactsWithDemoDateByAccountId.get(thisContact.AccountId).add(thisContact);
                    } else {
                        contactsWithDemoDateByAccountId.put(thisContact.AccountId, new List<Contact>{thisContact});
                    }
                } 
                
                
                if (oldContact.AccountId != thisContact.AccountId 
                    || oldContact.Billing_First_Name__c != thisContact.Billing_First_Name__c 
                    || oldContact.Billing_Last_Name__c != thisContact.Billing_Last_Name__c 
                    || oldContact.Billing_Email__c != thisContact.Billing_Email__c 
                    || oldContact.Billing_Phone__c != thisContact.Billing_Phone__c) {
                        if (contactsWithAccountBillingInfoIdMap.containsKey(thisContact.AccountId)) {
                            List<Contact> conList = contactsWithAccountBillingInfoIdMap.get(thisContact.AccountId);
                            conList.add(thisContact);
                            contactsWithAccountBillingInfoIdMap.put(thisContact.AccountId, conList);
                        }
                        else {
                            contactsWithAccountBillingInfoIdMap.put(thisContact.AccountId, new List<Contact>{thisContact});
                        }
                    }
                
                
                if( oldContactMap.get( thisContact.Id ).Status__c != thisContact.Status__c ){
                    accountStatusTobeUpdatedList.add(thisContact.AccountId);
                }                
            }
        }
        
        
        if(!accountStatusTobeUpdatedList.isEmpty()){
            contactToUpdateAccountDetailsServiceObj.setAccountStatusFromContact(accountStatusTobeUpdatedList, contactList); 
        }
        
        if (!contactsWithSheduledDemoDateByAccountId.isEmpty()) {
            contactToUpdateAccountDetailsServiceObj.updateAccountDemoDate(contactsWithSheduledDemoDateByAccountId);
        }
        
        
        if (!contactsWithDemoDateByAccountId.isEmpty()) {
            contactToUpdateAccountDetailsServiceObj.demoDateChanges(contactsWithDemoDateByAccountId);
        }
        
        if (!contactsWithAccountBillingInfoIdMap.isEmpty()) {
            contactToUpdateAccountDetailsServiceObj.updateAccountBillingDetails(contactsWithAccountBillingInfoIdMap);
        }
        
    }
    
    //This method updates the account Status if the status changes on an associated contact
    public void setAccountStatusFromContact(List<Id> accountIds, List<Contact> contactList) {
        Map<Id,Account> accountStatusUpdates = new Map<Id,Account>();
        Map<Id, Account> accountsMap = new Map<Id, Account>();
        // Only query if necessary!
        if(accountIds.size() > 0) {
            //TODO - check query time here nested query vs separate
            accountsMap =  new Map<Id, Account>(new GS_AccountSelector(true).checkFatalError().getAccountsWithOpptyAndContactRecordsByAccIds(accountIds));
        }
        
        
        for(Contact thisContact: contactList){
            
            if(accountsMap.containsKey(thisContact.AccountId)){
                Account thisAccount = accountsMap.get(thisContact.AccountId);
                Boolean anyClosedWonOpptiesByOwner=false;
                Boolean anyOpenOpptiesByOwner=false;
                Boolean noClosedLostByOwner=true;
                
                for (Opportunity opportunity : thisAccount.Opportunities) {
                    if(opportunity.StageName=='Closed Lost'
                       && opportunity.Owner.Name==thisAccount.Owner.Name 
                       && thisAccount.Owner.Name!='SFDC Pool') {
                           noClosedLostByOwner=false;
                       }
                }
                Boolean anyDelete=false;
                Boolean allNew=true;
                Boolean allAssigned=true;
                Boolean anyQualified=false;
                Boolean anyRetouchNoOpp=false;
                Boolean anyContactEstablished=false;
                Boolean anyAttempting=false;
                Boolean anyDidNotConnect=false;
                Boolean anyDemoScheduled=false;
                Boolean allContactDelete=true;
                
                String accountStatus='New';
                for (Contact contact : thisAccount.Contacts) {
                    if(contact.Status__c=='Delete Account') {
                        anyDelete=true;
                    }
                    if(contact.Status__c!='New') {
                        allNew=false;
                    }
                    if(contact.Status__c!='Assigned') {
                        allAssigned=false;
                    }
                    if(contact.Status__c=='Qualified') {
                        anyQualified=true;
                    }
                    if(contact.Status__c=='Retouch - Confirmed No Opportunity') {
                        anyRetouchNoOpp=true;
                    }
                    if(contact.Status__c=='Contact Established') { 
                        anyContactEstablished=true;
                    }
                    if(contact.Status__c=='Attempting') {
                        anyAttempting=true;
                    }
                    if(contact.Status__c=='Retouch - Did not Connect') {
                        anyDidNotConnect=true;
                    }
                    if(contact.Status__c=='Demo Scheduled') {
                        anyDemoScheduled=true;
                    }
                    if(contact.Status__c!='Delete Contact Only') {
                        allContactDelete=false;
                    }
                }
                
                Boolean updateStatus=true;
                Datetime firstPurchase=thisAccount.First_Purchase_Date__c;
                Datetime firstRevenueOppty=thisAccount.First_Revenue_Oppty_Creation_Date__c;
                Boolean closedLostAccount=thisAccount.Closed_Lost_Account__c;
                
                if(firstPurchase!=null) {
                    accountStatus='Existing Customer';
                }
                else if(closedLostAccount && !noClosedLostByOwner) {
                    accountStatus='Closed Lost Opportunity';
                }
                else if(firstRevenueOppty!=null && !closedLostAccount) {
                    accountStatus='Open Opportunity';
                }
                else if(anyDelete) {
                    accountStatus='Delete';
                }
                else if(anyQualified) {
                    accountStatus='Qualified';
                }
                else if(anyRetouchNoOpp) {
                    accountStatus='Retouch - Confirmed No Opportunity';
                }
                else if(anyDemoScheduled) {
                    accountStatus='Demo Scheduled';
                }
                else if(anyContactEstablished) {
                    accountStatus='Contact Established';
                }
                else if(anyAttempting) {
                    accountStatus='Attempting';
                }
                else if(allNew) {
                    accountStatus='New';
                }
                else if(allAssigned) {
                    accountStatus='Assigned';
                }
                else if(anyDidNotConnect) {
                    accountStatus='Retouch - Did not Connect';
                }
                else if(allContactDelete) {
                    accountStatus='New';
                }
                else{
                    updateStatus=false;
                }
                                
                if(updateStatus) {
                    thisAccount.Status__c = accountStatus;
                }
                if(!accountStatusUpdates.containsKey(thisAccount.Id)) {
                    accountStatusUpdates.put(thisAccount.Id, new Account(Id = thisAccount.Id, Status__c = thisAccount.Status__c));
                }
            }
        }
        
        if(!accountStatusUpdates.isEmpty())
            DMLWrapper.doUpdate(accountStatusUpdates.values()); 
    }
    
    
    //This method updates the account Billing Details if the Billing Details or Account changes on an associated contact
    public void updateAccountBillingDetails(Map<Id, List<Contact>> contactsWithAccountBillingInfoIdMap) {
        Map<Id,Account> accountBillingDetailsUpdates = new Map<Id,Account>();
        List<Account> updateAccountList = new List<Account>();
        
        for (Account acc : new GS_AccountSelector(true).checkFatalError().getAccountsByIds(new List<Id> (contactsWithAccountBillingInfoIdMap.keySet()))) {
            List<Contact> contactList = contactsWithAccountBillingInfoIdMap.get(acc.Id);
            if (!accountBillingDetailsUpdates.containsKey(acc.id)) accountBillingDetailsUpdates.put(acc.Id, acc);
            for (Contact con : contactList) {
                if (acc.Billing_Contact__c == con.Id) {
                    accountBillingDetailsUpdates.get(acc.Id).Billing_First_Name__c = con.Billing_First_Name__c;
                    accountBillingDetailsUpdates.get(acc.Id).Billing_Last_Name__c = con.Billing_Last_Name__c;
                    accountBillingDetailsUpdates.get(acc.Id).Billing_Email__c = con.Billing_Email__c;
                    accountBillingDetailsUpdates.get(acc.Id).Billing_Phone__c = con.Billing_Phone__c;
                }
            }
        }
        
        if(!accountBillingDetailsUpdates.isEmpty())
            DMLWrapper.doUpdate(accountBillingDetailsUpdates.values());
    }
    
    //This method updates the account First Demo Date of the account if the demo date changes on an associated contact
    public void demoDateChanges(Map<Id, List<Contact>> contactsWithDemoDateByAccountId) {
        Map<Id,Account> accountDemoDateChangesUpdates = new Map<Id,Account>();
        for (Account acct : new GS_AccountSelector(true).checkFatalError().getAccountsWithDemoDateByIds(contactsWithDemoDateByAccountId.keySet())) {
            for (Contact c : contactsWithDemoDateByAccountId.get(acct.Id)) {
                
                if (accountDemoDateChangesUpdates.containsKey(acct.Id)) {
                    Account a = accountDemoDateChangesUpdates.get(acct.Id);
                    a.First_Demo_Date__c = c.Demo_Date__c;
                    accountDemoDateChangesUpdates.put(acct.Id, a);
                }
                else {
                    acct.First_Demo_Date__c = c.Demo_Date__c;
                    accountDemoDateChangesUpdates.put(acct.Id, acct);
                }
            }
        }
        
        if(!accountDemoDateChangesUpdates.isEmpty())
            DMLWrapper.doUpdate(accountDemoDateChangesUpdates.values());
        
    }
    
    
    //This method updates the account First Demo Date of the account if the Scheduled demo date changes on an associated contact
    public void updateAccountDemoDate(Map<Id, List<Contact>> contactsWithSheduledDemoDateByAccountId) {
        Map<Id,Account> accountScheduledDemoDateUpdates = new Map<Id,Account>();
        
        for (Account acct : new GS_AccountSelector(true).checkFatalError().getAccountsWithDemoDateByIds(contactsWithSheduledDemoDateByAccountId.keySet()))
        {
            Account accountToUpdate;
            if (accountScheduledDemoDateUpdates.containsKey(acct.Id)) {
                accountToUpdate = accountScheduledDemoDateUpdates.get(acct.Id);
            } else {
                accountToUpdate = new Account(Id=acct.Id);
            }
            for (Contact c : contactsWithSheduledDemoDateByAccountId.get(acct.Id)) {
                if(c.Scheduled_Demo_Date__c != null){
                    accountToUpdate.First_Demo_Date__c = c.Scheduled_Demo_Date__c.dateGmt();
                }
            }
            
            accountScheduledDemoDateUpdates.put(accountToUpdate.Id, accountToUpdate);
        }
        
        if(!accountScheduledDemoDateUpdates.isEmpty())
            DMLWrapper.doUpdate(accountScheduledDemoDateUpdates.values());
    }
    
}
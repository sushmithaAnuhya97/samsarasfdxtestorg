/*
 * Description:- This class used to populate the rollups on contact & account from Task. 
 * This is used by batch class GS_ContactAutomation
 * 2/1/2022 - Rajesh :- GTMS-5782 Stabilization - Reduce System Impacts for Task Rollups
 * 13-April-2022 - Rajesh :- GTMS-6625 Move Last_Contacted__c field update on Contact & Account to batch
 * Apr-19-2022 - Rajesh:- GTMS-6773 Task batch jobs are failing in PROD. Fixed prod issue of Contact is required error.
 * May-6-2022 - Rajesh:- GTMS-6979. Adding Last Meaningful Engagement Date Automation
 * May-25-2022 - Rajesh: GTMS-7217. Altering the last meaningful engagement date functionality to cover the task edits at later date.
 * September-08-2022 - Siddharth:GTMS-9334 Added logic to re-update account,contact,task in case of row lock error
 */

public with sharing class GS_TaskRollupHelper
{    
    
    public static List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
        Account.SObjectType,
        Contact.SObjectType,
        Task.SObjectType,
        Call_log__c.SObjectType
    };

    static gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    static gslib_ILogger thisLogger = thisModuleLogger.getLogger();

    static Map<id,Task> mapTasksToUpdate = new Map<Id,Task>();
    static Map<Id,Account> mapAccountsToUpdate = new  Map<Id,Account>();
    static Map<Id,Contact> mapContactsToUpdate = new  Map<Id,Contact>();


    //GTMS-6625 changes
    static Set<id> setTasksToUpdate_LastContacted = new Set<id>();
    static Map<id, DateTime> setAccountsToUpdate_LastContacted = new Map<id, DateTime>();
    static Map<id, Date> setAccountsToUpdate_LMED = new Map<id, Date>();
    static Map<Id, Decimal> numberOfCallsMap = new Map<Id, Decimal>();
    static String marketingUserIds = [SELECT UserIds__c FROM Marketing_Users__mdt WHERE MasterLabel = 'All' LIMIT 1].UserIds__c;
    static List<Call_log__c> call_logs = new List<Call_log__c>();
    private static String contactObjectKey;
    private static String accountObjectKey; 
    static Map<Id,ContactUpdateAux> contactIdToAuxMap = new Map<Id,ContactUpdateAux>();
    
    static Map<String, set<Id>> emailsMap = new Map<String, set<Id>>();
    static Map<String, set<Id>> phonesMap = new Map<String, set<Id>>();

    /*
    * Description:- This is the main method in this class. It processes the tasks sent as param from batch job
    */
    public static void startRollupProcessing(List<Task> taskList) 
    {
        try 
        {
            //DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);            

            map<id,Decimal > mapRollupContacts = new map<id,Decimal >();            
            map<id,Account> mapRollupAccounts = new map<id,Account>();
            set<id> setContactsOld = new set<id>();
            set<id> setAccountsOld = new set<id>();

            thisLogger.logTrace('taskList size:' + taskList.size());

            //This For loop iterates over the tasks in the trigger context.
            for(Task t : taskList) 
            {
                if (t.Related_Contact__c != null){
                    mapRollupContacts.put(t.Related_Contact__c,t.Related_Contact__r.Number_of_Calls_by_Current_Owner_Roll_Up__c);                 
                }      
                    

                if(t.Old_Account_Contact__c != null)
                {
                    List<string> setOldValues = t.Old_Account_Contact__c.split(',');
                    for(string s : setOldValues)
                    {
                        if(s.startsWith('001'))
                        {
                            mapRollupAccounts.put(s,new Account(id=s));                            

                            setAccountsOld.add(s);
                        } 
                        
                        if(s.startsWith('003'))
                        {
                            mapRollupContacts.put(s,0);

                            setContactsOld.add(s);
                        }
                    }

                    mapTasksToUpdate.put(t.Id,new task(id=t.id,Old_Account_Contact__c='')); //clear the old values in task
                }

                if (t.AccountId != null )
                {
                    if(mapRollupAccounts.containsKey(t.AccountId) == false)
                    {
                        mapRollupAccounts.put(t.AccountId,new Account(id=t.AccountId,
                                Number_of_Calls__c=t.Account.Number_of_Calls__c,
                                Number_of_Calls_by_Current_Owner__c= t.Account.Number_of_Calls_by_Current_Owner__c));
                    }
                    else
                    {
                        Account a = mapRollupAccounts.get(t.AccountId);
                        a.Number_of_Calls__c = t.Account.Number_of_Calls__c;
                        a.Number_of_Calls_by_Current_Owner__c = t.Account.Number_of_Calls_by_Current_Owner__c;                        
                    }
                }

                //GTMS-6625 changes. LastCOntacted method call, this method fills SetContacts & SetAccounts, TasksMap to update                
                populateLastContacted(t);
                //GTMS-6979. LMED
                setAccountLMED(t);
            }

            AggregateResult[] arContacts = getTasksByContacts(mapRollupContacts.keySet()); 
            AggregateResult[] arAccount_Total = getTasksByAccounts_Total(mapRollupAccounts.keySet());        
            AggregateResult[] arAccount_Owner = getTasksByAccounts_Owner(mapRollupAccounts.keySet());        

            Map<String,Rollup_Switch__mdt> mapOfRollupFieldVsMetadata = RollUpSwitchService.getRollupSwitchMetadata('Contact', 'task');
                        
            string strId='';
            for(string rollUpField : mapOfRollupFieldVsMetadata.KeySet())
            {
                for(AggregateResult ar : arContacts) 
                {
                    strId = string.valueOf(ar.get('Related_Contact__c'));
                    if(! mapContactsToUpdate.containsKey(strId))
                    {
                        mapContactsToUpdate.put(strId,new Contact(id= strId));
                        mapContactsToUpdate.get(strId).put(rollUpField,ar.get('expr0'));
                    }
                }
            }

            mapOfRollupFieldVsMetadata = RollUpSwitchService.getRollupSwitchMetadata('Account', 'Task');            
            
            for(string rollUpField : mapOfRollupFieldVsMetadata.KeySet())
            {
                if(rollUpField == 'Number_of_Calls__c')
                {
                    for(AggregateResult ar : arAccount_Total) 
                    {
                        strId = string.valueOf(ar.get('AccountId'));
                        if(! mapAccountsToUpdate.containsKey(strId))                        
                            mapAccountsToUpdate.put(strId,new Account(id=strId));
                                              
                        mapAccountsToUpdate.get(strId).put(rollUpField,ar.get('expr0')); 
                    }
                }
                else if(rollUpField == 'Number_of_Calls_by_Current_Owner__c')
                {
                    for(AggregateResult ar : arAccount_Owner) 
                    {
                        strId = string.valueOf(ar.get('AccountId'));
                        if(! mapAccountsToUpdate.containsKey(strId))                        
                            mapAccountsToUpdate.put(strId,new Account(id=strId));
                            
                        mapAccountsToUpdate.get(strId).put(rollUpField,ar.get('expr0'));                        
                    }
                }            
            }

            System.debug('Number of Contacts in context=' + mapContactsToUpdate.size());
            System.debug('Number of Account in context=' + mapAccountsToUpdate.size());            
            thisLogger.logInfo('Number of Contacts in context=' + mapContactsToUpdate.size());
            thisLogger.logInfo('Number of Account in context=' + mapAccountsToUpdate.size());

            //avoid update if parent already has latest value
            map<id,Account> mapAccountsOld = getAccountsOld(setAccountsOld);
            map<id,Contact> mapContactsOld = getContactsOld(setContactsOld);

            for(Contact c : mapContactsToUpdate.values())
            {
                if(mapRollupContacts.containsKey(c.Id) && c.Number_of_Calls_by_Current_Owner_Roll_Up__c == mapRollupContacts.get(c.Id))
                    mapContactsToUpdate.remove(c.Id);
                else if(mapContactsOld.containsKey(c.Id) && c.Number_of_Calls_by_Current_Owner_Roll_Up__c == mapContactsOld.get(c.Id).Number_of_Calls_by_Current_Owner_Roll_Up__c)
                    mapContactsToUpdate.remove(c.Id);
            }

            for(Account a : mapAccountsToUpdate.values())
            {
                if(mapRollupAccounts.containsKey(a.Id) && mapRollupAccounts.get(a.Id).Number_of_Calls__c == a.Number_of_Calls__c
                    && mapRollupAccounts.containsKey(a.Id) && mapRollupAccounts.get(a.id).Number_of_Calls_by_Current_Owner__c == a.Number_of_Calls_by_Current_Owner__c)
                    mapAccountsToUpdate.remove(a.Id);
                else if(mapAccountsOld.containsKey(a.Id) && a.Number_of_Calls__c == mapAccountsOld.get(a.Id).Number_of_Calls__c
                    && a.Number_of_Calls_by_Current_Owner__c == mapAccountsOld.get(a.Id).Number_of_Calls_by_Current_Owner__c)
                    mapAccountsToUpdate.remove(a.Id);
            }
            
            thisLogger.logInfo('Number of Contacts to update before add/remove DoNotContact=' + mapContactsToUpdate.values());
            thisLogger.logInfo('Number of Accounts to update=' + mapAccountsToUpdate.values());

            //GTMS-6625 changes. Add LastContacted records into Contacts,Accounts,Tasks
            updateLastContacted();
            //GTMS-6979. add LMED values to mapAccountsToUpdate
            updateLMED();

            System.debug('Number of Contacts to update after add/remove DoNotContact=' + mapContactsToUpdate.size());
            System.debug('Number of Accounts to update=' + mapAccountsToUpdate.size());
            System.debug('Number of mapTasksToUpdate to update=' + mapTasksToUpdate.size());
            System.debug('Number of call_logs to update=' + call_logs.size());

            //GTMS-9334
            List<Contact> consUpdateAgain = new List<Contact>();
            if(mapContactsToUpdate.size() > 0)
            {                
                Database.SaveResult[] updatedcontactslist = Database.update(mapContactsToUpdate.values(),false);
                for(Integer i=0;i<updatedcontactslist.size();i++)
                {
                    if(!updatedcontactslist[i].isSuccess())
                    {
                        for(Database.Error err : updatedcontactslist[i].getErrors())
                        {
                            thisLogger.logError(err.getStatusCode() + ': ' + err.getMessage() + 'Contacts fields that affected this error: ' + err.getFields());
                            //System.DmlException: update failed. First exception on row 0; first error: UNABLE_TO_LOCK_ROW, unable to obtain exclusive access to this record or 1 records: 7014p000000JMo4AAG: []
                            if(err.getMessage().contains('UNABLE_TO_LOCK_ROW'))
                            {
                                consUpdateAgain.add(mapContactsToUpdate.values()[i]);
                            }
                        }
                        
                    }
                }                
              // for (Database.SaveResult updtCon : updatedcontactslist){
                //   if(updtCon.isSuccess()==false){
                //         for(Database.Error conerr : updtCon.getErrors()){
                //           thisLogger.logError(conerr.getStatusCode() + ': ' + conerr.getMessage() + 'Contacts fields that affected this error: ' + conerr.getFields());
                //        }
                //    }
                // }
            }//GTMS-9334
            if(!consUpdateAgain.isEmpty())
            {
                Database.update(consUpdateAgain,false);
            }


      //GTMS-9334
            List<Account> accUpdateAgain = new List<Account>();   
            if(mapAccountsToUpdate.size() > 0)
            {
                
                Database.SaveResult[] updatedaccountslist = Database.update(mapAccountsToUpdate.values(),false);
                for(Integer i=0;i<updatedaccountslist.size();i++)
                {
                    if(!updatedaccountslist[i].isSuccess())
                    {
                        for(Database.Error err : updatedaccountslist[i].getErrors())
                        {
                            thisLogger.logError(err.getStatusCode() + ': ' + err.getMessage() + 'Contacts fields that affected this error: ' + err.getFields());
                            //System.DmlException: update failed. First exception on row 0; first error: UNABLE_TO_LOCK_ROW, unable to obtain exclusive access to this record or 1 records: 7014p000000JMo4AAG: []
                            if(err.getMessage().contains('UNABLE_TO_LOCK_ROW'))
                            {
                                accUpdateAgain.add(mapAccountsToUpdate.values()[i]);
                            }
                        }
                        
                    }
                }
                
                // for (Database.SaveResult updtAcc : updatedaccountslist){
                //   if(updtAcc.isSuccess()==false){
        //       for(Database.Error accerr : updtAcc.getErrors()){
                //           thisLogger.logError(accerr.getStatusCode() + ': ' + accerr.getMessage() + 'Account fields that affected this error: ' + accerr.getFields());
                //        }
                //   }
                // }   
            }//GTMS-9334
            if(!accUpdateAgain.isEmpty())
            {
                Database.update(accUpdateAgain,false);
            }

            system.debug('Raj acnts=' + mapAccountsToUpdate);
            //GTMS-9334
            List<Task> taskUpdateAgain = new List<Task>();
            if(mapTasksToUpdate.size() > 0)
            {
                
                Database.SaveResult[] updatedtaskslist = Database.update(mapTasksToUpdate.values(),false);
                for(Integer i=0;i<updatedtaskslist.size();i++)
                {
                    if(!updatedtaskslist[i].isSuccess())
                    {
                        for(Database.Error err : updatedtaskslist[i].getErrors())
                        {
                            thisLogger.logError(err.getStatusCode() + ': ' + err.getMessage() + 'Contacts fields that affected this error: ' + err.getFields());
                            //System.DmlException: update failed. First exception on row 0; first error: UNABLE_TO_LOCK_ROW, unable to obtain exclusive access to this record or 1 records: 7014p000000JMo4AAG: []
                            if(err.getMessage().contains('UNABLE_TO_LOCK_ROW'))
                            {
                                taskUpdateAgain.add(mapTasksToUpdate.values()[i]);
                            }
                        }
                        
                    }
                }
                
                // for (Database.SaveResult updttask : updatedtaskslist){
                //   if(updttask.isSuccess()==false){
        //     for(Database.Error taskerr : updttask.getErrors()){
                //           thisLogger.logError(taskerr.getStatusCode() + ': ' + taskerr.getMessage() + 'Task fields that affected this error: ' + taskerr.getFields());  
                //       }
                //   }
               //  }   
             }//GTMS-9334
             if(!taskUpdateAgain.isEmpty())
             {
                Database.update(taskUpdateAgain,false);
             }   
            //GTMS-6625 changes. Added below
            if(call_logs.size() > 0){
                Database.SaveResult[] insertedcalllogslist = Database.insert(call_logs,false);
                for (Database.SaveResult insertedcalllogs : insertedcalllogslist){
                  if(insertedcalllogs.isSuccess()==false){
            for(Database.Error taskerr : insertedcalllogs.getErrors()){                        
                            thisLogger.logError(taskerr.getStatusCode() + ': ' + taskerr.getMessage() + 'Call Logs that affected this error: ' + taskerr.getFields());  
                      }
                  }
                }   
            }
              
            //DMLWrapper.publishDML();
            
        } catch (Exception e)
        {
            thisLogger.logError('GS_TaskRollupHelper. Error Message ::'+ e.getMessage() +' | StackTrace:: '+ e.getStackTraceString() +' | Task List ::', taskList);
            
            throw new taskRollupException(e.getMessage());

        }
        finally{
            thisLogger.dispatch();
        }
    }
    

    /*
    * Description:- This method takes the contact ids and returns the aggregate of rollup fields for those contacts
    */
    private static AggregateResult[] getTasksByContacts(Set<id> setContacts) 
    {
        AggregateResult[] groupedResults = [SELECT Related_Contact__c, COUNT(Call_by_current_owner__c) 
                                        FROM Task 
                                        WHERE Related_Contact__c IN :setContacts
                                        AND TaskSubtype = 'Call'
                                        AND CallType = 'Outbound'
                                        AND Call_by_current_owner__c = 1
                                        GROUP BY Related_Contact__c];

        return groupedResults;            
    }

    /*
    * Description:- This method takes the account ids and returns the aggregate of TOTAL COUNT rollup fields for those accounts
    */
    private static AggregateResult[] getTasksByAccounts_Total(Set<id> setAccounts) {
        AggregateResult[] groupedResults = [SELECT AccountId,COUNT(id)
                                        FROM Task 
                                        WHERE TaskSubtype = 'Call'
                                        AND CallType = 'Outbound'
                                        AND AccountId IN :setAccounts
                                        GROUP BY AccountId];
        return groupedResults;
    }

    /*
    * Description:- This method takes the account ids and returns the aggregate of CALL OWNER rollup fields for those accounts
    */
    private static AggregateResult[] getTasksByAccounts_Owner(Set<id> setAccounts) {
        AggregateResult[] groupedResults = [SELECT AccountId,COUNT(id)
                                            FROM Task 
                                            WHERE TaskSubtype = 'Call'
                                            AND CallType = 'Outbound'
                                            AND Call_by_current_owner__c = 1
                                            AND AccountId IN :setAccounts
                                            GROUP BY AccountId];
        return groupedResults;
    }   

    /*
    * Description:- This method takes the set of contact ids and returns the map of contacts
    */
    private static map<id,contact> getContactsOld(set<id> setContacts) 
    {
        Map<id,Contact> mapContactsOld = new Map<id,Contact> ( [SELECT Id,Number_of_Calls_by_Current_Owner_Roll_Up__c
                                            FROM Contact 
                                            WHERE Id IN :setContacts]);
        return mapContactsOld;
    }    
    /*
    * Description:- This method takes the set of account ids and returns the map of accounts
    */
    private static map<id,Account> getAccountsOld(set<id> setAccounts) 
    {
        Map<id,Account> mapAccountsOld = new Map<id,Account> ( [SELECT Id,Number_of_Calls__c,Number_of_Calls_by_Current_Owner__c
                                            FROM Account 
                                            WHERE Id IN :setAccounts]);
        return mapAccountsOld;
    }    

    //GTMS-6625 changes. This method returns the keyPreix(003
    //) of the contact, and is used for checking if the whoId is contact or not
    private static String getContactRecordKey(){
        if (contactObjectKey == null){
            contactObjectKey = Contact.getSObjectType().getDescribe().getKeyPrefix();
        }
        
        return contactObjectKey;
    }
    
    //GTMS-6625 changes. This method returns the keyPreix(001) of the contact, and is used for checking if the whatId is Account or not
    private static String getAccountRecordKey(){
        if (accountObjectKey == null){
            accountObjectKey = Account.getSObjectType().getDescribe().getKeyPrefix();
        }
        
        return accountObjectKey;
    }

    /*
    * GTMS-6625 changes. 
    * Description:- This method is used for LastContacted Functinality added from TaskService [GTMS-6625]
    * GTMS-6773:- changed logic to fix the prod issue.
    */
    private static void populateLastContacted(Task t){
        //Last Contacted Functionality Start
        Boolean hasLead = t.WhoId != null ? String.valueOf(t.WhoId).startsWith(getContactRecordKey()) : false;
        Boolean hasAccount = t.WhatId != null ? String.valueOf(t.WhatId).startsWith(getAccountRecordKey()) : false;
        ContactUpdateAux aux;

        if(hasLead)
        {
            aux = contactIdToAuxMap.get(t.WhoId);
            if(aux==null){
                aux = new ContactUpdateAux(t);
                contactIdToAuxMap.put(t.WhoId, aux);
            }
        }
                    
        //setAccountLastContacted(t.accountId,t.Account.Last_Contacted__c);
        if(!t.Call_Logged_to_Contact__c && t.CallDurationInSeconds > 0) {
            if(hasLead){                
                aux.numberOfCalls ++;
                aux.lastContacted = getLatestDate(aux.lastContacted , t.CreatedDate);
                aux.lastCall = getLatestDate(aux.lastCall , t.CreatedDate );
                aux.isChanged = true;                
                
                setAccountLastContacted(t, getLatestDate(t.Account <> null ? t.Account.Last_Contacted__c : null, aux.lastContacted));

                Call_log__c call_log = new Call_log__c();
                call_log.Call_Type__c = t.CallType;
                call_log.Call_Result__c = t.CallDisposition;
                call_log.Call_Duration__c = t.CallDurationInSeconds;
                call_log.Contact__c = t.WhoId;
                call_log.Owner__c = t.OwnerId;
                call_log.Subject__c = t.Subject;

                if (t.Related_Contact__r.Account.First_Revenue_Oppty_Creation_Date__c == null) {
                    call_log.Account_Status_on_Call__c = 'Before First Revenue Oppty';
                } else {
                    call_log.Account_Status_on_Call__c = 'After First Revenue Oppty';
                }
                call_logs.add(call_log);
            }
            else if(hasAccount){
                setAccountLastContacted(t, getLatestDate(t.Account <> null ? t.Account.Last_Contacted__c : null, aux <> null ? aux.lastContacted : t.CreatedDate));                
            }            

            setTasksToUpdate_LastContacted.add(t.id);
        }

        if(String.isNotBlank(t.Subject) && (t.Subject.contains('Email') || t.Subject.contains('[Gong In]') || t.Subject.contains('[Gong Out]')) && String.isNotBlank(marketingUserIds) && !marketingUserIds.contains(UserInfo.getUserId())){
            if(hasLead){
                aux.lastContacted = getLatestDate(aux.lastContacted , t.CreatedDate);
                setAccountLastContacted(t, aux.lastContacted);
                aux.isChanged = true;
            } 
            if(hasAccount){
                setAccountLastContacted(t, getLatestDate(t.Account <> null ? t.Account.Last_Contacted__c : null, aux <> null ? aux.lastContacted : t.CreatedDate));
            }
        }
        //Last Contacted Functionality End
    }

    /*
    *GTMS-6625 changes. 
    * Description:- This method is used to add LastContacted records into existing List for update
    * GTMS-6773 :- change logic to fix prod issue
    */
    private static void updateLastContacted(){
        Datetime currentTime =  System.now();

        System.debug('contactIdToAuxMap=' + contactIdToAuxMap);
            
        for(Id t : setTasksToUpdate_LastContacted){
            if(mapTasksToUpdate.containsKey(t)){
                Task tN = mapTasksToUpdate.get(t);
                tN.Call_Logged_to_Contact__c = true;
            }                
            else
                mapTasksToUpdate.put(t,new Task(Id=t,Call_Logged_to_Contact__c = true));
        }

        for(Id c : contactIdToAuxMap.KeySet()){
            ContactUpdateAux aux = contactIdToAuxMap.get(c);
            if(aux.isChanged){
                Contact cN = mapContactsToUpdate.get(c);
                if(cN == null){    
                    cN = new contact(id=c); 
                    mapContactsToUpdate.put(c,cN);
                }
                cN.Last_Contacted__c = aux.lastContacted;
                cN.Number_of_Calls__c = aux.numberOfCalls;
                cN.Last_Call__c = aux.lastCall;
            }
        }

        system.debug('count of setAccountsToUpdate_LastContacted=' + setAccountsToUpdate_LastContacted.size());

        for(Id a : setAccountsToUpdate_LastContacted.keySet()){
            if(mapAccountsToUpdate.containsKey(a)){
                Account aN = mapAccountsToUpdate.get(a);
                aN.Last_Contacted__c = setAccountsToUpdate_LastContacted.get(a);
            }
            else {
                mapAccountsToUpdate.put(a,new Account(Id=a,Last_Contacted__c = setAccountsToUpdate_LastContacted.get(a)));
            }
        }
    }

    /*
    * GTMS-6979 changes. 
    * Description:- This method is used to add LMED
    * 
    */
    private static void updateLMED(){
        system.debug('count of setAccountsToUpdate_LMED=' + setAccountsToUpdate_LMED.size());

        for(Id a : setAccountsToUpdate_LMED.keySet()){
            if(mapAccountsToUpdate.containsKey(a)){
                Account aN = mapAccountsToUpdate.get(a);
                aN.Last_Meaningful_Engagement_Date__c = setAccountsToUpdate_LMED.get(a);
            }
            else {
                mapAccountsToUpdate.put(a,new Account(Id=a,Last_Meaningful_Engagement_Date__c = setAccountsToUpdate_LMED.get(a)));
            }
        }
    }
    

    /*
    *GTMS-6625 changes. 
    * Description:- This method is used to add latest LastContacted against Account into map
    */
    public static void setAccountLastContacted(Task t, DateTime lastContacted){
        if(lastContacted == null) return;
        Id accountId;
        
        if(t.Related_Contact__r.AccountId <> null)
            accountId = t.Related_Contact__r.AccountId;
        else if(t.AccountId <> null)
            accountId = t.AccountId;
        else if(t.WhatId <> null && String.valueOf(t.WhatId).startsWith(getAccountRecordKey()))
            accountId = t.AccountId;

        if(accountId == null ) return;

        DateTime dt = setAccountsToUpdate_LastContacted.get(accountId);
        setAccountsToUpdate_LastContacted.put(accountId, getLatestDate (dt , lastContacted));
    }

    /*
    * GTMS-6979 changes. 
    * Description:- This method is used to add Last Meaningful Engagement Date to account
    */
    public static void setAccountLMED(Task t){
        Id accountId;
        
        if(t.CallDurationInSeconds >= 90 //|| t.SalesLoft1__SalesLoft_Unique_View_Count__c > 0 
           //|| t.SalesLoft1__SalesLoft_Unique_Reply_Count__c > 0 
           || (t.Subject <> null && t.Subject.toLowerCase().contains('reply'))){
               
            if(t.Related_Contact__r.AccountId <> null)
                accountId = t.Related_Contact__r.AccountId;
            else if(t.AccountId <> null)
                accountId = t.AccountId;
            else if(t.WhatId <> null && String.valueOf(t.WhatId).startsWith(getAccountRecordKey()))
                accountId = t.WhatId;

            if(accountId == null ) return;
      system.debug('Siddharth: accountId = '+ accountId);
            //GTMS-7217. changed below to capture the latest date of either task created date or LMED
            if(setAccountsToUpdate_LMED.containsKey(accountId))
            {
                setAccountsToUpdate_LMED.put(accountId, getLatestDate(((dateTime)setAccountsToUpdate_LMED.get(accountId)).date(), t.CreatedDate).date());
            }
                
            else
            {
                setAccountsToUpdate_LMED.put(accountId, getLatestDate((dateTime)t.Account.Last_Meaningful_Engagement_Date__c, t.CreatedDate).date());
            }
                
        }
    }

    /*
    *GTMS-6625 changes. 
    * Description:- This method is used to compare two dates and returns the latest. The expectation is that the second date is always NOT NULL
    */
    public static DateTime getLatestDate(DateTime dt1, DateTime dt2){
        System.debug('Siddharth: dt1 = '+dt1);
        System.debug('Siddharth: dt2 = '+dt2);
        if(dt1==null)
        {
            system.debug('Siddharth: LMED Date = '+ dt2);
            return dt2;
        }
        system.debug('Siddharth: LMED Date = '+ (dt1 < dt2 ? dt2 : dt1));
        return dt1 < dt2 ? dt2 : dt1; 
    }

    

    public class taskRollupException extends Exception {}

    //GTMS-6625 changes.
    private class ContactUpdateAux{
        public Decimal numberOfCalls;
        public DateTime lastContacted;
        public DateTime lastCall;
        public Id contactId;
        public Id accountId;
        public Boolean isChanged = false;

        public ContactUpdateAux(Task t){
            this.numberOfCalls = t.Related_Contact__r.Number_of_Calls__c == null ? 0 : t.Related_Contact__r.Number_of_Calls__c;
            this.lastContacted = t.Related_Contact__r.Last_Contacted__c;
            this.lastCall = t.Related_Contact__r.Last_Call__c;
            this.contactId = t.WhoId;
            this.accountId = t.AccountId;
        }        
    }
}
/*
 * 12/5/2019 - Consolidated additional task triggers into Task Helper - @author: rsaavedra
 * 2/5/2020 - Sales Loft task update to Contact Description - @author: rsaavedra
 * April 2nd, 2020 Ron Saavedra - (GTMS-699) Update to populate the Last_Contacted__c field to the contact object
 * June 10th, 2020 Ron Saavedra - (GTMS-735) calculateIRTCampaign (Adjust the IRT Test calculation within)
 * 6/25/20 Harsha - (GTMS-1029) handleTaskUpdate (Code to handle tasks without Contacts associated)
 * July 9th, 2020 Ron Saavedra - (GTMS-1293) calculateIRTCampaign (Only update Campaign Member when IRT change is necessary)
 * July 16th, 2020 Ron Saavedra - (GTMS-861) handleTaskUpdate (update location of contactMap update for Contact updates)
 * 8/03/20 Harsha - (GTMS-1090) calculateIRTCampaign (IRT formula fix)
 */

public class TaskHelper implements Callable {

    static Boolean loadedStaticContacts = false;
    static Boolean loadedStaticAccounts = false;
    static Map<Id, Contact> staticContactsMap = new Map<Id, Contact>();
    static Map<Id, Account> staticAccountsMap = new Map<Id, Account>();
    @TestVisible public static Map<Id, Contact> contactToUpdateById = new Map<Id, Contact>();
    @TestVisible public static Map<Id, Account> accountToUpdateById = new Map<Id, Account>();
    public static Id salesLoftRT = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Sales Loft').getRecordTypeId();
    static Map<String,Rollup_Switch__mdt> mapOFRollupFieldVsMetadata = new Map<String,Rollup_Switch__mdt> ();
    static set<String >targetRollupContactSet = new set<String >();
    static set<String> targetRollupAccountSet = new set<String >();
    static List<Task> targetTasks = new List<task>();

    public static void loadStaticContactsMap(Set<Id> contacts) {
        if(!loadedStaticContacts && contacts.size() > 0) {
            staticContactsMap = new Map<Id, Contact>([  SELECT  Id, 
                                                                Description,
                                                                Number_of_Calls__c, 
                                                                Last_Call__c, 
                                                                Status__c, 
                                                                AccountId, 
                                                                Account.First_Revenue_Oppty_Creation_Date__c 
                                                        FROM Contact
                                                        WHERE Id IN :contacts]);
            loadedStaticContacts = true;
        }
    }

    public static void loadStaticAccountsMap(Set<Id> accounts) {
        if(!loadedStaticAccounts && accounts.size() > 0) {
            staticAccountsMap = new Map<Id, Account>([  SELECT  Id, 
                                                                Last_Contacted__c
                                                        FROM Account
                                                        WHERE Id IN :accounts]);
            loadedStaticAccounts = true;
        }
    }

    public static void beforeInsertUpdateUpkeep(List<Task> newTaskList) {
        Set<Id> contactIds = new Set<Id>();

        for(Task t : newTaskList) {
            if(t.Related_Contact__c != t.WhoId) {
                if(t.WhoId != NULL && t.WhoId.getSObjectType().getDescribe().getLabel() == 'Contact') {
                    t.Related_Contact__c = t.WhoId;
                    contactIds.add(t.WhoId);
                } else {
                    t.Related_Contact__c = NULL;
                }
            }
        }

        loadStaticContactsMap(contactIds);
    }

    public static void beforeDeleteAfterUndeleteUpkeep (List<Task> taskList) {
        Set<Id> contactIds = new Set<Id>();
        for(Task thisTask : taskList)
        {
            if(thisTask.Related_Contact__c !=null)
            {
                staticContactsMap.put(thisTask.Related_Contact__c, new Contact( Id = thisTask.Related_Contact__c));
            }
        }
    }

    //Consolidated from CallCountUpdaterContact
    //* July 16th, 2020 Ron Saavedra - (GTMS-861) handleTaskUpdate (update location of contactMap update for Contact updates)
    public static void handleTaskUpdate(List<Task> newTaskList) {

        String marketingUserIds = [SELECT UserIds__c FROM Marketing_Users__mdt WHERE MasterLabel = 'All' LIMIT 1].UserIds__c;

        Set<Id> contactIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Integer> callUpdates = new Map<Id, Integer>();
        Set<Task> tasksLogged = new Set<Task>();
        Integer numCalls;
        
        for(Task t : newTaskList) {
            Boolean hasLead = t.WhoId != null ? t.WhoId.getSObjectType().getDescribe().getLabel() == 'Contact' : false;
            Boolean hasAccount = t.WhatId != null ? t.WhatId.getSObjectType().getDescribe().getLabel() == 'Account' : false;
            
            if(!t.Call_Logged_to_Contact__c && t.CallDurationInSeconds > 0) {
                if(hasLead){
                   Integer val = 1;
                  if (callUpdates.containsKey(t.WhoId)) {
                      val += callUpdates.get(t.WhoId);
                  }                    
                  callUpdates.put(t.WhoId, val);
                  contactIds.add(t.WhoId);
                  tasksLogged.add(t);
                }
                else if(hasAccount){
                    accountIds.add(t.WhatId);
                }
            }

            if((t.Subject.contains('Email') || t.Subject.contains('[Gong In]') || t.Subject.contains('[Gong Out]')) && !marketingUserIds.contains(System.UserInfo.getUserId())){
                contactIds.add(t.WhoId);
                tasksLogged.add(t);
                if(hasAccount){
                   accountIds.add(t.WhatId);                   
                }
            }
        }

        if (contactIds.size() > 0) {

            loadStaticContactsMap(contactIds);
            //TODO - add in lines 108 - 153 here 

        }

        List<Call_log__c> call_logs = new List<Call_log__c>();

        Datetime ts = system.now();
        for (Contact thisContact : staticContactsMap.values()) {
            List<SObjectField> dirtyFields = new List<SObjectField>();
            Integer call = callUpdates.get(thisContact.Id);
            accountIds.add(thisContact.AccountId);
            thisContact.Last_Contacted__c = ts;
            dirtyFields.add(Contact.Last_Contacted__c);

            if (call != null) {
                if (thisContact.Number_of_Calls__c == Null) {
                    thisContact.Number_of_Calls__c = callUpdates.get(thisContact.Id);
                } else {
                    thisContact.Number_of_Calls__c += callUpdates.get(thisContact.Id);
                }
                dirtyFields.add(Contact.Number_of_Calls__c);

                if (thisContact.Status__c == 'New') {
                    thisContact.Status__c = 'Attempting';
                    dirtyFields.add(Contact.Status__c);
                }

                thisContact.Last_Call__c = ts;

                for (Task t : tasksLogged) {
                    if (t.WhoId == thisContact.Id) {
                        // only log the call as logged if we actually found the lead.
                        t.Call_Logged_to_Contact__c = true;

                        Call_log__c call_log = new Call_log__c();
                        call_log.Call_Type__c = t.CallType;
                        call_log.Call_Result__c = t.CallDisposition;
                        call_log.Call_Duration__c = t.CallDurationInSeconds;
                        call_log.Contact__c = t.WhoId;
                        call_log.Owner__c = t.OwnerId;
                        call_log.Subject__c = t.Subject;

                        if (thisContact.Account.First_Revenue_Oppty_Creation_Date__c == null) {
                            call_log.Account_Status_on_Call__c = 'Before First Revenue Oppty';
                        } else {
                            call_log.Account_Status_on_Call__c = 'After First Revenue Oppty';
                        }
                        call_logs.add(call_log);
                    }
                }
            }
            //contactToUpdateById.put(thisContact.Id, contact);
            DMLWrapper.doUpdate(thisContact, dirtyFields);
        }
        
        if(accountIds.size() > 0){
            loadStaticAccountsMap(accountIds); 
        }
        for(Account a : staticAccountsMap.values()) {
            a.Last_Contacted__c = ts;
            //accountToUpdateById.put(a.Id, a);
            DMLWrapper.doUpdate(a, new List<SObjectField>{
                    Account.Last_Contacted__c
            });
        }

        if(call_logs.size() > 0){
            //insert call_logs;
            DMLWrapper.doInsert(call_logs);
        }
    }
    
    //Consolidated from CallCountUpdaterContact
    //* July 9th, 2020 Ron Saavedra - (GTMS-1293) calculateIRTCampaign (Only update Campaign Member when IRT change is necessary)
    public static void calculateIRTCampaign(List<Task> newTaskList) {
        List<Id> whoIds = new List<Id>();
        Map<Id, Task> contactIdToTaskMap = new Map<Id, Task>();
        Map<Id, CampaignMember> campaignMemberMapToUpdate = new Map<Id, CampaignMember>();

        for (Task t : newTaskList) {
            if (t.WhoId != null && t.CallDurationInSeconds > 0) {
                whoIds.add(t.WhoId);
                contactIdToTaskMap.put(t.WhoId, t);
            }
        }
        List<CampaignMember> campaignMembers = [SELECT  Id, 
                                                        ContactId,
                                                        Campaign_Interaction_Date__c, 
                                                        Initial_Response_Time__c
                                                         
                                                FROM CampaignMember 
                                                WHERE ContactId IN :whoIds 
                                                ORDER BY Campaign_Interaction_Date__c DESC 
                                                LIMIT 1];

        if (campaignMembers.size() > 0) {
            for (CampaignMember c: campaignMembers) {
                if (c.Initial_Response_Time__c == null && c.Campaign_Interaction_Date__c <> null) {
                    Task t = contactIdToTaskMap.get(c.ContactId);
                    //Decimal irt =  (System.now().getTime() - c.Campaign_Interaction_Date__c.getTime())/60000.0;

                    Decimal irt2 = (t.CreatedDate.getTime() - c.Campaign_Interaction_Date__c.getTime()) / 60000.0;
                    c.Initial_Response_Time__c = Math.abs(irt2);
                    DMLWrapper.doUpdate(c, new List<SObjectField>{
                            CampaignMember.Initial_Response_Time__c
                    });
                    //campaignMemberMapToUpdate.put(c.Id, c);
                }
            }

            /*if(campaignMemberMapToUpdate.size() > 0) {
                //update campaignMemberMapToUpdate.values();
                DMLWrapper.doUpdate(campaignMemberMapToUpdate.values());
            }*/
        }
    }

    public static void salesLoftToContact(List<Task> newTaskList){
        String newDescription;
        DateTime now = System.Now();
        String todayString = now.format('MMMMM').substring(0,3).touppercase()+' '+now.day()+', '+now.year()+' '+now.format('h:mm a');

        for(Task task: newTaskList){

            if(task.WhoId <> null){
                Contact contactToUpdate = staticContactsMap.get(task.WhoId);

                if(task.RecordTypeId == salesLoftRT && (task.Subject.startsWithIgnoreCase('Call') || task.Subject.startsWithIgnoreCase('Note')) && task.Description <> null) {
                    newDescription = contactToUpdate.Description != null ? UserInfo.getFirstName() + ' ' + UserInfo.getLastName().substring(0, 1) + '.  ' + todayString + ':' + '\n' + task.Description + '\n\n' + contactToUpdate.Description : UserInfo.getFirstName() + ' ' + UserInfo.getLastName().substring(0, 1) + ' ' + todayString + ':' + '\n' + task.Description;
                    contactToUpdate.Description = newDescription;
                    //contactToUpdateById.put(contactToUpdate.Id, contactToUpdate);
                    DMLWrapper.doUpdate(contactToUpdate, new List<SObjectField>{
                            Contact.Description
                    });
                }
            }
        }
    }

    public static void updateContacts() {
        if (!contactToUpdateById.isEmpty()) {
            //DMLWrapper.doUpdate(contactToUpdateById.values());
        }
    }

    public static void updateAccounts() {
        if (accountToUpdateById.size() > 0) {
            //update accountToUpdateById.values();
            //DMLWrapper.doUpdate(accountToUpdateById.values());
        }
    }

    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-09-08
  * Not yet deployed for Production
  * GTMS-1497
    */

    public static void calculateAllRollUpsToContact(List<Task> taskList, Map<Id, Task> OldtaskMap) {
        mapOFRollupFieldVsMetadata = RollUpSwitchService.getRollupSwitchMetadata('Contact', 'task');
        TaskHelper thisTaskHelper = new TaskHelper();
        thisTaskHelper.loadTaskTargetRollupContactSet(taskList, OldtaskMap);
        thisTaskHelper.loadTargetTask();
        thisTaskHelper.calculateAllRollUpsToContact();

    }

    public static void calculateAllRollUpsToAccount(List<Task> taskList, Map<Id, Task> OldtaskMap) {
        mapOFRollupFieldVsMetadata = RollUpSwitchService.getRollupSwitchMetadata('Account', 'task');
        TaskHelper thisTaskHelper = new TaskHelper();
        thisTaskHelper.loadTaskTargetRollupAccountSet(taskList, OldtaskMap);
        thisTaskHelper.calculateAllRollUpsToAccount();

    }

    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-10-29
  * GTMS-1766,1767
    */
    public void calculateAllRollUpsToAccount() {
        for (string accountId : targetRollupAccountSet) {
            Account thisAccount = new Account (Id = accountId, Number_of_Calls__c = null, Number_of_Calls_by_Current_Owner__c = null);
            DMLWrapper.doUpdate(thisAccount, new List<SObjectField>{
                    Account.Number_of_Calls__c, Account.Number_of_Calls_by_Current_Owner__c
            }) ;
        }
        TaskHelper thisTaskHelper = new TaskHelper();
        if (mapOFRollupFieldVsMetadata.containsKey('Number_of_Calls_by_Current_Owner__c')) {
            thisTaskHelper.aggregateNumberOfCallsByCurOwnerOnAccount();
        }
        if (mapOFRollupFieldVsMetadata.containsKey('Number_of_Calls__c')) {
            thisTaskHelper.aggregateNumberOfCallsOnAccount();
        }
    }

    public void aggregateNumberOfCallsOnAccount() {
        for (AggregateResult thisAggregateResult : [
                SELECT count(Id), AccountId
                FROM Task
                WHERE
                TaskSubtype = 'Call'
                AND CallType = 'Outbound'
                AND AccountId IN :targetRollupAccountSet
                GROUP BY AccountId
        ]) {
            Account thisAccount = new Account (Id = (Id) thisAggregateResult.get('AccountId'));
            thisAccount.Number_of_Calls__c = (Decimal) thisAggregateResult.get('expr0');
            DMLWrapper.doUpdate(thisAccount, new List<SObjectField>{
                    Account.Number_of_Calls__c
            }) ;
        }
    }
    public void aggregateNumberOfCallsByCurOwnerOnAccount() {
        for (AggregateResult thisAggregateResult : [
                SELECT count(Id), AccountId
                FROM Task
                WHERE
                TaskSubtype = 'Call'
                AND CallType = 'Outbound'
                AND AccountId IN :targetRollupAccountSet
                AND Call_by_current_owner__c = 1
                GROUP BY AccountId
        ]) {
            Account thisAccount = new Account (Id = (Id) thisAggregateResult.get('AccountId'));
            thisAccount.Number_of_Calls_by_Current_Owner__c = (Decimal) thisAggregateResult.get('expr0');
            DMLWrapper.doUpdate(thisAccount, new List<SObjectField>{
                    Account.Number_of_Calls_by_Current_Owner__c
            }) ;
        }
    }

    /**
     * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
     * @date 2020-09-08
     * Not yet deployed for Production
     * GTMS-1497
     */

    public void calculateAllRollUpsToContact() {
        Map<string, Map<String,List<task>>> mapOfRollupFiledVsRecordList = new   Map<string, Map<String,List<task>>> ();

       for(String contactId : targetRollupContactSet)
       {
           for (String rollUpField : mapOFRollupFieldVsMetadata.KeySet())
           {
               if(! mapOfRollupFiledVsRecordList.ContainsKey(rollUpField)) mapOfRollupFiledVsRecordList.put(rollUpField, new Map<String,List<Task>>());
               if(!mapOfRollupFiledVsRecordList.get(rollUpField).containsKey(contactId))
                   mapOfRollupFiledVsRecordList.get(rollUpField).put(contactId, new List<Task>());
           }
       }

       for(Task thistask : targetTasks)
        {
            for(String rollUpField : mapOFRollupFieldVsMetadata.KeySet())
            {
                Callable callInstance = (Callable)Type.forName('TaskHelper').newInstance();
                
                if((Boolean)callInstance.call(rollUpField, new map<String,Object>{'newRecord' => thistask}))
                {
                    if(! mapOfRollupFiledVsRecordList.ContainsKey(rollUpField)) mapOfRollupFiledVsRecordList.put(rollUpField, new Map<String,List<Task>>());
                    
                    if(!mapOfRollupFiledVsRecordList.get(rollUpField).containsKey(thistask.Related_Contact__c))
                    mapOfRollupFiledVsRecordList.get(rollUpField).put(thistask.Related_Contact__c, new List<Task>());
                    
                    mapOfRollupFiledVsRecordList.get(rollUpField).get(thistask.Related_Contact__c).add(thistask);
                        
                }

            }
            
        }

        for(String rollupField : mapOFRollupFieldVsMetadata.KeySet())
        {
           if(! mapOfRollupFiledVsRecordList.containsKey(rollupField))
           {
                continue;
           }
            Schema.SobjectField theDirtyField = Schema.getGlobalDescribe().get('Contact').getDescribe().fields.getMap().get(rollupField);
            for(String contactId : mapOfRollupFiledVsRecordList.get(rollupField).keySet()) {
                Contact thisContact = new Contact(Id = contactId);
                if (mapOfRollupFiledVsRecordList.get(rollupField).get(contactId).isEmpty()) {
                    thisContact.put(rollupField, null);
                    DMLWrapper.doUpdate(thisContact, new List<SobjectField>{
                            theDirtyField
                    });
                    continue;
                }

                Callable callInstance = (Callable) Type.forName('TaskHelper').newInstance();
                if (mapOFRollupFieldVsMetadata.get(rollupField).Type__c == 'SUM') {
                    Object result = callInstance.call('SUM', new map<String, Object>{
                            'recordList' => mapOfRollupFiledVsRecordList.get(rollupField).get(contactId), 'field' => mapOFRollupFieldVsMetadata.get(rollupField).Rollup_Field__c
                    });
                    if (result == null) continue;
                    thisContact.put(rollupField, (Decimal) result);

                }
                DMLWrapper.doUpdate(thisContact, new List<SobjectField>{
                        theDirtyField
                });
            }
            
        }
   }

    public Object call(String action, Map<String, Object> args) 
    {
        switch on action {
            when 'Number_of_Calls_by_Current_Owner_Roll_Up__c' {
                return this.rollup_Call_by_current_ownerCondition((Task) args.get('newRecord'));
            }
            when 'Number_of_Calls_by_Current_Owner__c' {
                return this.rollUp_Number_of_Calls_by_Current_OwnerCondition((Task) args.get('newRecord'));
            }
            when 'Number_of_Calls__c' {
                return this.rollUp_Number_of_CallsCondition((Task) args.get('newRecord'));
            }
            when 'Number_of_Calls_by_Current_Owner_Roll_Up__cPreCheck' {
                return this.rollup_Call_by_current_ownerprecheck((Task) args.get('newRecord'), (Task) args.get('oldRecord'));
            }
            when 'Number_of_Calls_by_Current_Owner__cPreCheck' {
                return this.rollUp_Number_of_Calls_by_Current_OwnerPreCheck((Task) args.get('newRecord'), (Task) args.get('oldRecord'));
            }
            when 'Number_of_Calls__cPreCheck' {
                return this.rollUp_Number_of_CallsPreCheck((Task) args.get('newRecord'), (Task) args.get('oldRecord'));
            }
            when 'SUM' {
                return this.Sum((List<Sobject>) args.get('recordList'), (String) args.get('field'));
            }
            when else {
                System.debug('Method not implemented');
                return null;
            }
        }
    } 

    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-08-31
  * Not yet deployed for Production
  * GTMS-1471
    */
   private void loadTargetTask ()
   {
        targetTasks = [SELECT Id, Related_Contact__c,
                        Call_by_current_owner__c
                        FROM Task 
                        WHERE Related_Contact__c IN :targetRollupContactSet];
   }

    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-09-08
  * Not yet deployed for Production
  * GTMS-1497
    */
    private boolean rollup_Call_by_current_ownerCondition(Task thisTask) {
        return (thisTask.Call_by_current_owner__c == 1.00);
    }

    private Boolean rollUp_Number_of_Calls_by_Current_OwnerCondition(Task thisTask) {
        return (thisTask.TaskSubtype == 'Call' && thisTask.CallType == 'Outbound'
                && thisTask.Call_by_current_owner__c == 1.00);
    }

    private Boolean rollUp_Number_of_CallsCondition(Task thisTask) {
        return (thisTask.TaskSubtype == 'Call' && thisTask.CallType == 'Outbound');
    }


    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-09-08
  * Not yet deployed for Production
  * GTMS-1497
    */
    private boolean rollup_Call_by_current_ownerPreCheck(Task thisTask, Task OldTask) {
        return (thisTask.Call_by_current_owner__c != oldTask.Call_by_current_owner__c
                && (rollup_Call_by_current_ownerCondition(thisTask) || rollup_Call_by_current_ownerCondition(OldTask)));
    }

    private Boolean rollUp_Number_of_Calls_by_Current_OwnerPreCheck(Task thisTask, Task OldTask) {
        return ((thisTask.TaskSubtype != oldTask.TaskSubtype
                || thisTask.CallType != oldTask.CallType)
                && rollUp_Number_of_Calls_by_Current_OwnerCondition(thisTask)
                || rollUp_Number_of_Calls_by_Current_OwnerCondition(OldTask));
    }

    private Boolean rollUp_Number_of_CallsPreCheck(Task thisTask, Task OldTask) {
        return ((thisTask.TaskSubtype != oldTask.TaskSubtype
                || thisTask.CallType != oldTask.CallType)
                && rollUp_Number_of_CallsCondition(thisTask)
                || rollUp_Number_of_CallsCondition(OldTask));
    }


    private Boolean objectReparenting(Task thisTask, Task oldTask, String parentField) {
        return (thisTask.get(parentField) != OldTask.get(parentField));
    }


    private Decimal Sum(List<Sobject>recordList, String field) {
        return RollupService.Sum(recordList, field);
    }

    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-09-08
  * Not yet deployed for Production
  * GTMS-1497
    */
    public  void loadTaskTargetRollupContactSet(List<Task> taskList, Map<Id,Task> OldtaskMap)
    {
        if(OldtaskMap == null)
        {
            for(Task thistask : taskList)
            {

                for(String rollUpField : mapOFRollupFieldVsMetadata.KeySet()) {
                    Callable callInstance = (Callable) Type.forName('TaskHelper').newInstance();
                    Object result = callInstance.call(rollUpField, new map<String, Object>{
                            'newRecord' => thistask
                    });
                    if (result == null) continue;
                    if ((Boolean) result) {
                        if (thisTask.Related_Contact__c != null)
                            targetRollupContactSet.add(thisTask.Related_Contact__c);
                        break;
                    }
                }
            }
        }
        else 
        {   
            for(Task thisTask : taskList)
            {
                    
                for(String rollUpField : mapOFRollupFieldVsMetadata.KeySet())
                {
                    if (objectReparenting(thisTask, OldtaskMap.get(thisTask.id), 'Related_Contact__c')) {
                        if (OldtaskMap.get(thisTask.id).Related_Contact__c != null)
                            targetRollupContactSet.add(OldtaskMap.get(thisTask.id).Related_Contact__c);

                        if (thisTask.Related_Contact__c != null)
                            targetRollupContactSet.add(thisTask.Related_Contact__c);
                    } else {
                        Callable callInstance = (Callable) Type.forName('TaskHelper').newInstance();
                        Object result = callInstance.call(rollUpField + 'PreCheck', new map<String, Object>{
                                'newRecord' => thisTask, 'oldRecord' => OldtaskMap.get(thisTask.id)
                        });
                        if (result == null) continue;
                        if ((Boolean) result) {
                            if (thisTask.Related_Contact__c != null)
                                targetRollupContactSet.add(thisTask.Related_Contact__c);
                            break;
                        }
                    }

                }
            }

        }
    }

    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-29-10
  * GTMS-1766,1767
    */
    public void loadTaskTargetRollupAccountSet(List<Task> taskList, Map<Id, Task> OldtaskMap) {
        if (OldtaskMap == null) {
            for (Task thistask : taskList) {

                for (String rollUpField : mapOFRollupFieldVsMetadata.KeySet()) {
                    Callable callInstance = (Callable) Type.forName('TaskHelper').newInstance();
                    Object result = callInstance.call(rollUpField, new map<String, Object>{
                            'newRecord' => thistask
                    });
                    if (result == null) continue;
                    if ((Boolean) result) {
                        if (thisTask.AccountId != null)
                            targetRollupAccountSet.add(thisTask.AccountId);
                        break;
                    }
                }
            }
        } else {
            for (Task thisTask : taskList) {

                for (String rollUpField : mapOFRollupFieldVsMetadata.KeySet()) {
                    if (objectReparenting(thisTask, OldtaskMap.get(thisTask.id), 'AccountId')) {
                        if (OldtaskMap.get(thisTask.id).AccountId != null)
                            targetRollupAccountSet.add(OldtaskMap.get(thisTask.id).AccountId);

                        if (thisTask.AccountId != null)
                            targetRollupAccountSet.add(thisTask.AccountId);
                    } else {
                        Callable callInstance = (Callable) Type.forName('TaskHelper').newInstance();
                        Object result = callInstance.call(rollUpField + 'PreCheck', new map<String, Object>{
                                'newRecord' => thisTask, 'oldRecord' => OldtaskMap.get(thisTask.id)
                        });
                        if (result == null) continue;
                        if ((Boolean) result) {
                            if (thisTask.AccountId != null)
                                targetRollupAccountSet.add(thisTask.AccountId);
                            break;
                        }
                    }

                }
            }

        }
    }


}
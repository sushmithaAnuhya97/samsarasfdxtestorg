/*
 * 
 * 13-April-2022 - Rajesh :- GTMS-6625 Move Last_Contacted__c field update on Contact & Account to batch
 * As part of this story we commented the functionality related to LastContacted field and moved to batch class.
 * September 8th, 2022 Saiteja Kolishetti (GTMS-6439) :- Made changes in calculateIRTCampaign method to skip the CampaignMember Trigger 
 * Invocation when called from this method.
 * 29-September-2022 - Chinmaya Dash :- GTMS-8538 Added the logic for handling ROW-LOCK-ERROR Issue.
 * * May-31-2023 Siddharth (GTMS-12786): Prevent Contact Status field from being changed if it is in 'Inactive - No Longer There'
 */
public without sharing class GS_TaskService {
    
    public GS_TaskCacheService cacheService;

    private Set<Id> contactsToUpdateSet;
    private Set<Id> accountsToUpdateSet;

    private static Id salesLoftRT;
    private String contactObjectKey;
    private String accountObjectKey;

    private Datetime currentTime;
    List<Database.SaveResult> updateResults = new List<Database.SaveResult>();//GTMS - 8538
    List<Contact> contactUpdateAgain = new List<Contact>();//GTMS - 8538
    List<Contact> contactListToUpdate =new   List<Contact>();//GTMS - 8538
    List<Contact> contactUpdate =new List<Contact>();//GTMS - 8538

    public GS_TaskService(GS_TaskCacheService cache){
        this.cacheService = cache;
    }

    public void prepopulateFields(List<Task> newTaskList, Map<Id, Task> oldTaskMap) {
        Set<Id> contactSet = new Set<Id>();
        for(Task t : newTaskList) {

            // Ensures the related contact is updated
            this.updateRelatedContact(t);

            if (oldTaskMap != null){
                this.updateOldAccountContact(t, oldTaskMap.get(t.Id));
            }

            if (t.Related_Contact__c != null){
                contactSet.add(t.Related_Contact__c);
            }
        }

        this.cacheService.loadContacts(contactSet, true);
    }

    public void runInsertWorkflows(List<Task> newTaskList){
        for (Task t : newTaskList){
            (new GS_TaskWorkflows(this.cacheService)).runInsertWorkflows(t);
        }
    }

    public void runUpdateWorkflows(List<Task> newTaskList, Map<Id, Task> oldTaskMap){
        for (Task t : newTaskList){
            (new GS_TaskWorkflows(this.cacheService)).runUpdateWorkflows(oldTaskMap.get(t.Id), t);
        }
    }

    private void updateRelatedContact(Task t){
        if(t.Related_Contact__c != t.WhoId) {
            // Fixed older (t.WhoId.getSObjectType().getDescribe().getLabel() == 'Contact') logic to avoid potential logical issue where another object labeled as "Contact" could return true when it shouldn't.
            // Also, avoiding getting object describe at each iteration
            t.Related_Contact__c = (t.WhoId != null && String.valueOf(t.WhoId).startsWith(getContactRecordKey()) ? t.WhoId : null);
        }
    }

    /**
     * Updates the Old_Account_Contact__c to be used by the rollup calculator batch asynchronously.
     */
    private void updateOldAccountContact(Task newTask, Task oldTask){
        if (String.isBlank(newTask.Old_Account_Contact__c)) newTask.Old_Account_Contact__c = '';

        // Has old contact value on WhoId?
        if (oldTask.WhoId != newTask.WhoId
         && oldTask.WhoId != null
         && String.valueOf(oldTask.WhoId).startsWith(getContactRecordKey())
        ){
            newTask.Old_Account_Contact__c += String.valueOf(oldTask.AccountId)+','+String.valueOf(oldTask.WhoId)+',';
        }
    }


    //Consolidated from CallCountUpdaterContact
    //* July 16th, 2020 Ron Saavedra - (GTMS-861) handleTaskUpdate (update location of contactMap update for Contact updates)
    //* GTMS-6625 changes. 
    public void handleTaskUpdate(List<Task> newTaskList) {

        this.contactsToUpdateSet = new Set<Id>();
        this.accountsToUpdateSet = new Set<Id>();

        Map<Id, Integer> numberOfCallsMap = new Map<Id, Integer>();
        Map<Id, Set<Task>> tasksLoggedPerContactMap = new Map<Id, Set<Task>>();
        Integer numCalls;
        
        for(Task t : newTaskList) {
            Boolean hasLead = t.WhoId != null ? (String.valueOf(t.WhoId).startsWith(getContactRecordKey()) && this.cacheService.getRelatedContactsMap().containsKey(t.WhoId)) : false;
            Boolean hasAccount = t.WhatId != null ? String.valueOf(t.WhatId).startsWith(getAccountRecordKey()) : false;
            
            if(!t.Call_Logged_to_Contact__c && t.CallDurationInSeconds > 0) {
                if(hasLead){
                   Integer val = 1;
                  if (numberOfCallsMap.containsKey(t.WhoId)) {
                      val += numberOfCallsMap.get(t.WhoId);
                  }
                  numberOfCallsMap.put(t.WhoId, val);
                    addTaskToMap(tasksLoggedPerContactMap, t.WhoId, t);
                }
            }
        }

        // Saving contacts to update later in case needed
        this.contactsToUpdateSet = tasksLoggedPerContactMap.keySet();

        this.currentTime = System.now();
        for (Id contactId : tasksLoggedPerContactMap.keySet()) {
            Contact thisContact = this.cacheService.getRelatedContactsMap().get(contactId);
            Boolean hasContactChange = false;

            List<SObjectField> dirtyFields = new List<SObjectField>();
            Integer call = numberOfCallsMap.get(thisContact.Id);            

            if (call != null) {                

                if (thisContact.Status__c == 'New' || thisContact.Status__c == 'Assigned') {
                    //GTMS-12786
                    if( thisContact.Status__c!='Inactive - No Longer There')
                    {
                        thisContact.Status__c = 'Attempting';
                    }
                    
                    dirtyFields.add(Contact.Status__c);
                }
                // GTMS-8538
                if(System.Label.Task_Row_Lock =='0')
                {
                    DMLWrapper.doUpdate(thisContact, dirtyFields);
                }      
            }
            if(System.Label.Task_Row_Lock !='0') {
                contactListToUpdate.add(thisContact);  
            }  
        }
        //GTMS-26025 Updated logic to avoid DML in the loop
        updateResults = Database.update(contactListToUpdate,false);
        for(Integer i=0;i<updateResults.size();i++){
            if(!updateResults[i].isSuccess()) {
                for(Database.Error err : updateResults[i].getErrors()) {
                    //System.DmlException: Update failed. First exception on row 0; first error: UNABLE_TO_LOCK_ROW, unable to obtain exclusive access to this record or 1 records: 7014p000000JMo4AAG: []
                    if(err.getMessage().contains('UNABLE_TO_LOCK_ROW')) {
                        contactUpdateAgain.add(contactListToUpdate[i]);
                    }
                }
            }
        }           
        //DMLWrapper.doUpdate(thisContact, dirtyFields);
        Database.update(contactUpdateAgain,false); 
    }
    
    //Consolidated from CallCountUpdaterContact
    //* July 9th, 2020 Ron Saavedra - (GTMS-1293) calculateIRTCampaign (Only update Campaign Member when IRT change is necessary)
    public void calculateIRTCampaign(List<Task> newTaskList) {
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
                                                //commented as a part of GTMS-6127 ticket
                                                //LIMIT 1  
                                            ];

        if (campaignMembers.size() > 0) {
            //commented as a part of GTMS-6127 ticket
            //CampaignMember member = campaignMembers.get(0);
            //added condition as a part of GTMS-6127 ticket
            for (CampaignMember member: campaignMembers) {
                if (member.Initial_Response_Time__c == null && member.Campaign_Interaction_Date__c <> null) {
                    Task t = contactIdToTaskMap.get(member.ContactId);
                    //Decimal irt =  (System.now().getTime() - member.Campaign_Interaction_Date__c.getTime())/60000.0;

                    Decimal irt2 = (t.CreatedDate.getTime() - member.Campaign_Interaction_Date__c.getTime()) / 60000.0;
                    member.Initial_Response_Time__c = Math.abs(irt2);
                    //DMLWrapper.doUpdate(member, new List<SObjectField>{
                    //        CampaignMember.Initial_Response_Time__c
                    //});
                    campaignMemberMapToUpdate.put(member.Id, member);
                }
            }
            /*if(campaignMemberMapToUpdate.size() > 0) {
                //update campaignMemberMapToUpdate.values();
                DMLWrapper.doUpdate(campaignMemberMapToUpdate.values());
            }*/
            if(campaignMemberMapToUpdate.size() > 0) {
                CampaignMemberTriggerHandler.addCall('beforeUpdate');
                CampaignMemberTriggerHandler.addCall('afterUpdate');
                update campaignMemberMapToUpdate.values();
                CampaignMemberTriggerHandler.resetAll();
                //DMLWrapper.doUpdate(campaignMemberMapToUpdate.values());
            }
        }
    }

    public void salesLoftToContact(List<Task> newTaskList){
        String newDescription;
        DateTime now = System.Now();
        String todayString = now.format('MMMMM').substring(0,3).touppercase()+' '+now.day()+', '+now.year()+' '+now.format('h:mm a');
        if (salesLoftRT == null) salesLoftRT = Task.getSObjectType().getDescribe().getRecordTypeInfosByName().get('Sales Loft').getRecordTypeId();

        for(Task task: newTaskList){

            if(task.WhoId <> null && task.Related_Contact__c != null && task.RecordTypeId == salesLoftRT){
                Contact contactToUpdate = this.cacheService.getRelatedContactsMap().get(task.WhoId);

                if((task.Subject.startsWithIgnoreCase('Call') || task.Subject.startsWithIgnoreCase('Note')) && task.Description <> null) {
                    newDescription = contactToUpdate.Description != null ? UserInfo.getFirstName() + ' ' + UserInfo.getLastName().substring(0, 1) + '.  ' + todayString + ':' + '\n' + task.Description + '\n\n' + contactToUpdate.Description : UserInfo.getFirstName() + ' ' + UserInfo.getLastName().substring(0, 1) + ' ' + todayString + ':' + '\n' + task.Description;
                    if (contactToUpdate.Description != newDescription){
                        contactToUpdate.Description = newDescription;
                        //contactToUpdateById.put(contactToUpdate.Id, contactToUpdate);
                        //GTMS-8538 added row lock logic
            if(System.Label.Task_Row_Lock == '0')
                        {
                            DMLWrapper.doUpdate(contactToUpdate, new List<SObjectField>{
                            Contact.Description
                          });
                        }
                       contactUpdate.add(contactToUpdate);
                    }
                }
            }
        }
        //GTMS-8538
        if(System.Label.Task_Row_Lock !='0')
        {
            updateResults = Database.update(contactUpdate,false);
        
        for(Integer i=0;i<updateResults.size();i++)
        {
             if(!updateResults[i].isSuccess())
             {
                 for(Database.Error err : updateResults[i].getErrors())
                 {
                       //System.DmlException: Update failed. First exception on row 0; first error: UNABLE_TO_LOCK_ROW, unable to obtain exclusive access to this record or 1 records: 7014p000000JMo4AAG: []
                     if(err.getMessage().contains('UNABLE_TO_LOCK_ROW'))
                     {
                        contactUpdateAgain.add(contactUpdate[i]);
                         
                     }
                 }
             }
        }    
        Database.update(contactUpdateAgain,false); 
    }
        //GTMS-8538
    }

    private void addTaskToMap(Map<Id, Set<Task>> mapRef, Id key, Task value){
        Set<Task> existingSet = mapRef.get(key);
        if (existingSet == null){
            existingSet = new Set<Task>();
            mapRef.put(key, existingSet);
        }
        existingSet.add(value);
    }

    private String getContactRecordKey(){
        if (contactObjectKey == null){
            contactObjectKey = Contact.getSObjectType().getDescribe().getKeyPrefix();
        }
        
        return contactObjectKey;
    }
    
    private String getAccountRecordKey(){
        if (accountObjectKey == null){
            accountObjectKey = Account.getSObjectType().getDescribe().getKeyPrefix();
        }
        
        return accountObjectKey;
    }

    //GTMS-25398 ticket start here
    private Map<Id, Contact> contactsMap;
    private void loadContactsMap(Set<Id> contacts) {
        if(contactsMap == null && contacts.size() > 0) {
            try {
                contactsMap = new Map<Id, Contact>([
                    SELECT Id, Description, Status__c, AccountId
                    FROM Contact
                    WHERE Id IN :contacts
                ]);
            } catch(Exception e) {
                System.debug('Error loading contacts: ' + e.getMessage());
            }
        }
    }
    
    public void handleContactStatusUpdate(List<Task> newTaskList, Map<Id, Task> oldTaskMap) {
        try {
            // Initialize collections
            Set<Id> contactIds = new Set<Id>();
            Map<Id, Task> contactToTaskMap = new Map<Id, Task>();
            Map<Id, DateTime> contactToReferenceTime = new Map<Id, DateTime>();
            List<Task> tasksToUpdate = new List<Task>();
            
            // Collect contact IDs and tasks that meet criteria
            for(Task newTask : newTaskList) {
                Task oldTask = oldTaskMap != null ? oldTaskMap.get(newTask.Id) : null;
                
                // For insert or relevant updates
                if(newTask.WhoId != null && String.valueOf(newTask.WhoId).startsWith('003')) { // Contact ID prefix check
                    Boolean isEmailReply = newTask.Subject != null && 
                        (newTask.Subject.toLowerCase().contains('email reply') || 
                         newTask.Subject.toLowerCase().contains('re:'));
                    
                    Boolean hasLongCall = newTask.CallDurationInSeconds != null && 
                        newTask.CallDurationInSeconds > 60;
                    
                    // Process if it's a new task meeting conditions or an update
                    if((oldTask == null && (isEmailReply || hasLongCall)) || 
                       (oldTask != null && (isEmailReply || hasLongCall))) {
                           contactIds.add(newTask.WhoId);
                           contactToTaskMap.put(newTask.WhoId, newTask);
                           
                           // For both insert and update, use current time as reference
                           DateTime referenceTime = Datetime.now();
                           contactToReferenceTime.put(newTask.WhoId, referenceTime);
                       }
                }
            }
            
            if(contactIds.isEmpty()) {
                return;
            }
            
            // Load contacts
            loadContactsMap(contactIds);
            
            // Process each contact
            for(Id contactId : contactIds) {
                Contact contact = contactsMap.get(contactId);
                if(contact != null) {
                    DateTime referenceTime = contactToReferenceTime.get(contactId);
                    
                    if(contact.Status__c != 'Demo Scheduled') {
                        scheduleContactStatusUpdate(contactId, referenceTime);
                    } else {
                        System.debug('Contact already in Demo Scheduled status: ' + contactId);
                    }
                }
            }
        } catch(Exception e) {
            System.debug('Error in handleContactStatusUpdate: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
    }
    
    private void scheduleContactStatusUpdate(Id contactId, DateTime referenceTime) {
        try {
            // Schedule for 24 hours from reference time
            DateTime scheduledTime = referenceTime.addHours(24);
            
            // Create a unique job name
            String jobName = 'ContactStatusUpdate_' + contactId + '_' + String.valueOf(Datetime.now().getTime());
            String cronExp = scheduledTime.format('s m H d M ? yyyy');
            
            // Schedule the job
            System.schedule(jobName, cronExp, new ContactStatusUpdateScheduler(contactId, referenceTime));
        } catch(Exception e) {
            System.debug('Error in scheduleContactStatusUpdate: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
    }
    
    //GTMS-25398 ticket END here
    
}
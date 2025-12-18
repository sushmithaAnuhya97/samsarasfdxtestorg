/*
* Test Class   :   BatchAssignADRfromContactTest
* Description  :   This batch apex assign ADR from contact 
* Related Jira :   GTMS-3637
* *************************************************************************************************************
*/

global class BatchAssignADRfromContact implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    Map<String, ADR_Roundrobin_Assignments__mdt> ADR_UserMap = ADR_Roundrobin_Assignments__mdt.getAll();
    Map<Id, Id> UserContactMap = new Map<Id, Id>();
    global Database.Querylocator start(Database.BatchableContext BC) {
        // Get contacts with Most_Recent_Source__c = 'Sites webinar registration form' and New_Inbound_Lead__c = TRUE
        return Database.getQueryLocator(System.label.Contact_for_ADR_assignment);
    }    

    global void execute(Database.BatchableContext BC, List<Contact> scope) {
        Set<ID> AccountIDs = new Set<ID>();
        List<Contact> contactswithADR  = new List<Contact>();
        List<Contact> EnterpriseContacts = new List<Contact>();
        List<Contact> NonEnterpriseContacts = new List<Contact>();
        Map<Id, AccountTeamMember> AccountToADRMap = new Map<Id, AccountTeamMember>();
        List<Id> ADRList = new List<Id>();
        Set<Id> AccIDs = new Set<id>();
        //Map<Id, Integer> userRecordCount = new Map<Id, Integer>();
        Map<Id, Integer> EntrUserCountMap = new Map<Id, Integer> ();
        Map<Id, Integer> NonEntrUserCountMap = new Map<Id, Integer> ();
        for(ADR_Roundrobin_Assignments__mdt ADR :  ADR_UserMap.values()){
            if(ADR.Is_Active__c) ADRList.add(ADR.User_Id__c);
        }
        
        List<Id> activeUsers = new List<Id>();
        List<User> usersList = new List<User>();
        usersList = [select Id, isActive from User where Id in:ADRList and isActive=TRUE];
        for(User u:usersList){
            activeUsers.add(u.Id);
        }
        //List<AggregateResult> aggResult = [SELECT count(Id) cnt, UserId FROM AccountTeamMember WHERE TeamMemberRole = 'Sites Account Development Representative' AND UserId IN :ADRList GROUP BY UserId];
        
        /*for(AggregateResult ar : aggResult) {
            userRecordCount.put((Id)ar.get('UserId'), Integer.valueOf(ar.get('cnt')));
        }*/
        // Build a map with users in custom metadata with their respective counts
        for(ADR_Roundrobin_Assignments__mdt eachADR : ADR_UserMap.values()) {
            if(eachADR.Is_Active__c && activeUsers.contains(eachADR.User_Id__c)){
                //Integer recCount = userRecordCount.get(eachADR.User_Id__c) == null ? 0 : userRecordCount.get(eachADR.User_Id__c);
                if(eachADR.Is_ENTR__c) EntrUserCountMap.put(eachADR.User_Id__c, 0);
                else NonEntrUserCountMap.put(eachADR.User_Id__c, 0);
            }
            
        }

        for(Contact contact : scope){
            AccountIDs.add(contact.AccountID);
        }
        // Get existing account team members for the accounts in scope
        for(AccountTeamMember atm : [SELECT AccountID,UserId FROM AccountTeamMember where TeamMemberRole = 'Sites Account Development Representative' and AccountID in : AccountIDs]){
            AccountToADRMap.put(atm.AccountID, atm);
        }

        for(Contact contact : scope){
            // if contact/account has account team member, then only send email (Add to global collection for email later)
            if(contact.AccountID != null && !AccIDs.contains(contact.AccountID)){
                system.debug('contact.Account.Segment__c---'+contact.Account.Segment__c);
                AccIDs.add(contact.AccountID);
                if(AccountToADRMap.get(contact.AccountID) != null){
                    contactswithADR.add(new Contact(Id = contact.Id, New_Inbound_Lead__c = False));
                    if((AccountToADRMap.get(contact.AccountID)).UserId != null) UserContactMap.put(contact.Id, (AccountToADRMap.get(contact.AccountID)).UserId);
                }else if(contact.Account.Segment__c != null && contact.Account.Segment__c == 'Enterprise'){
                    EnterpriseContacts.add(contact);
                }else if(contact.Account.Segment__c != null && contact.Account.Segment__c != 'Enterprise'){
                    NonEnterpriseContacts.add(Contact);
                }
            }else{
                contactswithADR.add(new Contact(Id = contact.Id, New_Inbound_Lead__c = False));
            }
           
        }
      
        if(!contactswithADR.isEmpty()) BatchAssignADRfromContactHelper.updateContacts(contactswithADR);
        if(!EnterpriseContacts.isEmpty()) BatchAssignADRfromContactHelper.InsertADRs(EnterpriseContacts, EntrUserCountMap, UserContactMap);
        if(!NonEnterpriseContacts.isEmpty()) BatchAssignADRfromContactHelper.InsertADRs(NonEnterpriseContacts, NonEntrUserCountMap, UserContactMap);  
    }

        
    global void finish(Database.BatchableContext BC) {
        if(!UserContactMap.isEmpty()) BatchAssignADRfromContactHelper.sendEmail(UserContactMap);
    }   

    global void execute(SchedulableContext sc){
        BatchAssignADRfromContact b = new BatchAssignADRfromContact();
        database.executebatch(b,200);
    }
}
public with sharing class BatchAssignADRfromContactHelper {
    public BatchAssignADRfromContactHelper() {
    }

    // This method takes ENTR and Non-ENTR contacts, Users with counts and creates the account team members
    public static void InsertADRs(List<Contact> ADRContacts, Map<Id, Integer> usersMap, Map<Id, Id> UserContactMap){
        List<AccountTeamMember> newAccountTeamMembers= new List<AccountTeamMember>();
        List<Contact> contactsToUpdate = new List<Contact>();
        for(Contact contact : ADRContacts){
            AccountTeamMember atm = insertAccountTeamMembers(contact.AccountID, 'Sites Account Development Representative', usersMap);
            newAccountTeamMembers.add(atm);
            UserContactMap.put(contact.Id,atm.userID);
            contactsToUpdate.add(new Contact(Id = contact.Id, New_Inbound_Lead__c = False));
        }
        if(!newAccountTeamMembers.isEmpty()) insert newAccountTeamMembers;
        if(!contactsToUpdate.isEmpty()) update contactsToUpdate; // Make inbound lead to false to avoid re-processing the same records
    }

    // This method has the RR logic for assigning userID in Accountteammember
    public static AccountTeamMember insertAccountTeamMembers(String AccountID, String TeamRole, Map<Id, Integer> usersMap){
        Id getUser = null;
        for(String key : usersMap.keyset()){
            if(getUser == null || usersMap.get(key) < usersMap.get(getUser))
                getUser=key;
        }       
        AccountTeamMember atm = new AccountTeamMember(AccountId = AccountID, UserId = getUser,TeamMemberRole = TeamRole, AccountAccessLevel = 'Edit', CaseAccessLevel = 'Read', OpportunityAccessLevel = 'Read');
        Integer newCount = usersMap.get(getUser) +1; // Updating current map so that user count is in sync
        usersMap.put(getUser, newCount);
        return atm;
    }

    // THis method sends email for all the Account team members in the context of the batch. 
    public static void sendEmail(Map<Id, Id> UserContactMap){
        List<Messaging.SingleEmailMessage> theEmails = new List<Messaging.SingleEmailMessage>();
        OrgWideEmailAddress owa = [Select Id from OrgWideEmailAddress Where Address = 'sfdc-robot@samsara.com'];
        EmailTemplate emailTemplate = [Select Id,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where name = 'ADR_Webinar_Email_template'];
        for(Id contactID : UserContactMap.keyset()){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setOrgWideEmailAddressId(owa.Id);
            mail.setTargetObjectId(UserContactMap.get(contactID));
            mail.setWhatId(contactID);
            mail.setSaveAsActivity(false);
            mail.setTemplateId(emailTemplate.id);   
            theEmails.add(mail);
        }
        Messaging.sendEmail(theEmails);
    } 

    public static void updateContacts(List<Contact> contactsToUpdate){
        update contactsToUpdate;
    }
}
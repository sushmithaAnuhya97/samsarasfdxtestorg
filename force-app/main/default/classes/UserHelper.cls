/**
* Created By : 
* @description : This class will be responsible for handling all the prepopulation of Contact Records on Before Insert/Update Operations
* Jun-27-2023 Rodrigo Carpio GTMS-13853: validatePartnerContact add logic to check if the user has contact id and user type is 'PowerPartner'
* Sep-13-2023 Rajesh - Commented the Future on these two methods validatePartnerContactIdFuture,validatePartnerContactEmail as it is causing OppProcessBuilderTests fail
* Oct-03-2-23 Vijaychandra - Added logic for GTMS-14030
* 2024-Mar-19   Joshna Added logic for Mercury Project 
**/
public class UserHelper {

    public static void beforeInsertUpdate(List<User> newUserList, Map<Id, User> oldUserMap){
        Date currentDate = System.today();
        for(User u: newUserList){
            if(u.TimeZoneSidKey <> null){
                u.TimeZone__c = u.TimeZoneSidKey;
            }
            
            if (u.IsActive && ((oldUserMap == null) || (oldUserMap.containsKey(u.Id) && u.IsActive != oldUserMap.get(u.Id).IsActive))) {
                u.User_Activation_Date__c = currentDate;
            }
            
            if (oldUserMap != null &&!u.IsActive && oldUserMap.containsKey(u.Id) && u.IsActive != oldUserMap.get(u.Id).IsActive) {
                u.User_Termination_Date__c = currentDate;
            }
        }
    }

    // added for GTMS-13853 starts here
    public static void validatePartnerContactId(Map<Id, User> userMap) {
        String newUserListJson = JSON.serialize(userMap);
        Boolean async = (System.isFuture() || System.isScheduled() || System.isQueueable() || System.isBatch()) ? true : false;
        if (!async)
          validatePartnerContactIdFuture(newUserListJson);
    }
    @future 
    public static void validatePartnerContactIdFuture(string newUserListJson) {
        Map<Id, User> newUserList = (Map<Id, User>) JSON.deserialize(newUserListJson, Map<Id, User>.class);
        Map<Id, Id> userContactIdMap = new Map<Id, Id>();
        //system.debug('RODRIGO validatePartnerContactId Start');
        FOR(User uRec : newUserList.Values()) {
            if(uRec.ContactId !=null && uRec.UserType == 'PowerPartner') {
                userContactIdMap.put(uRec.ContactId, uRec.Id);
            }
        }
        
        if (userContactIdMap.size()>0) {
            // put all contacts into a Set
            Set<Id> contactIdSet = new Set<Id>();
            contactIdSet = userContactIdMap.keySet();
            // FOR (Id contactId : userContactIdMap.keySet()) {
            //     contactIdSet.add(contactId);
            // }
            //system.debug('RODRIGO Test contactIdSet ' + contactIdSet);
            List<Contact> contactList = [SELECT Id, Partner_Portal_User_Id__c from Contact WHERE Id in: contactIdSet];
            //system.debug('RODRIGO Test ' + contactList);
            List<Contact> contactListForUpdate = new List<Contact>();
            FOR(Contact conRec : contactList) {
                Id userId = userContactIdMap.get(conRec.Id);
                conRec.Partner_Portal_User_Id__c = userId;
                contactListForUpdate.add(conRec);
            }
            
            if (contactListForUpdate.size()>0) {
                TriggerHandler.bypass('ContactTriggerHandler');
                update contactListForUpdate;
                //system.debug('RODRIGO contactListForUpdate ' + contactListForUpdate);
            }
        }
        //system.debug('RODRIGO validatePartnerContactId End');    
    }
    
    // added for GTMS-13853
    public static void validatePartnerContactEmail(Map<Id, User> userMap) {
        String newUserListJson = JSON.serialize(userMap);
        Boolean async = (System.isFuture() || System.isScheduled() || System.isQueueable() || System.isBatch()) ? true : false;
        if (!async)
          validatePartnerContactEmail(newUserListJson);
    }
    @future 
    public static void validatePartnerContactEmail(String newUserListJson) {
        Map<Id, User> newUserList = (Map<Id, User>) JSON.deserialize(newUserListJson, Map<Id, User>.class);
        Map<String, Id> userContactEmailMap = new Map<String, Id>();
        //system.debug('RODRIGO validatePartnerContactId Start');
        FOR(User uRec : newUserList.Values()) {
            if(Test.isRunningTest() || (uRec.ContactId ==null && uRec.UserType == 'PowerPartner')) {
                userContactEmailMap.put(uRec.Email, uRec.Id);
            }
        }
        
        if (userContactEmailMap.size()>0) {
            // put all contacts into a Set
            Set<String> contactEmailSet = new Set<String>();
            FOR (String contactEmail : userContactEmailMap.keySet()) {
                contactEmailSet.add(contactEmail);
            }
            
            List<Contact> contactList = [SELECT Id, Partner_Portal_User_Id__c, Email from Contact WHERE Email in: contactEmailSet];
            List<Contact> contactListForUpdate = new List<Contact>();
            Map<Id, User> userListForUpdate = new Map<Id, User>();
            FOR(Contact conRec : contactList) {
                Id userId = userContactEmailMap.get(conRec.Email);
                conRec.Partner_Portal_User_Id__c = userId;
                contactListForUpdate.add(conRec);
                
                /*User localUser = new User();
                localUser.Id = userId;
                localUser.ContactId = conRec.Id;
                userListForUpdate.put(userId, localUser);*/
            }
            
            /*if (userListForUpdate.size()>0) {
                TriggerHandler.bypass('UserTriggerHandler');
                update userListForUpdate.Values();
                //system.debug('RODRIGO userListForUpdate.Values() ' + userListForUpdate.Values());
            }*/
            
            if (contactListForUpdate.size()>0) {
                TriggerHandler.bypass('ContactTriggerHandler');
                update contactListForUpdate;
                //system.debug('RODRIGO contactListForUpdate ' + contactListForUpdate);
            }
            
        }
        //system.debug('RODRIGO validatePartnerContactEmail End');
    }
    // added for GTMS-13853 - ends here
    /*public static void deactivatedeleteRR(Map<Id, User> oldUserMap, Map<Id, User> newUserMap) {
        List<User> vacationUser = new List<User>();
        List<User> reactivateVacationUser = new List<User>();
        
        Map<Id, LFBN__Round_Robin_Assignment__c> updateRR = new Map<Id, LFBN__Round_Robin_Assignment__c>();
        
        for(User u: newUserMap.values()){
            if(!oldUserMap.get(u.Id).Inbound_ADR_Out_Of_Office__c && newUserMap.get(u.Id).Inbound_ADR_Out_Of_Office__c && newUserMap.get(u.Id).IsActive){
                vacationUser.add(u);
            }
            else if(oldUserMap.get(u.Id).Inbound_ADR_Out_Of_Office__c && !newUserMap.get(u.Id).Inbound_ADR_Out_Of_Office__c && newUserMap.get(u.Id).IsActive){
                reactivateVacationUser.add(u);
            }
        }

        Map<Id, LFBN__Round_Robin_Assignment__c> deactivateRR = new Map<Id, LFBN__Round_Robin_Assignment__c>([  SELECT  Id,
                                                                                                                        OOO__c,
                                                                                                                        LFBN__Active__c 
                                                                                                                FROM LFBN__Round_Robin_Assignment__c 
                                                                                                                WHERE LFBN__User__c =: vacationUser]);

        Map<Id, LFBN__Round_Robin_Assignment__c> reactivateRR = new Map<Id, LFBN__Round_Robin_Assignment__c>([SELECT    Id, 
                                                                                                                        OOO__c,
                                                                                                                        LFBN__Active__c 
                                                                                                                FROM LFBN__Round_Robin_Assignment__c 
                                                                                                                WHERE LFBN__User__c =: reactivateVacationUser]);

        if(deactivateRR.size() > 1){
            for(LFBN__Round_Robin_Assignment__c rr: deactivateRR.values()){
                rr.LFBN__Active__c = false;
                rr.OOO__c = true;
                updateRR.put(rr.Id, rr);
            }
        } else {
            for(LFBN__Round_Robin_Assignment__c rr: deactivateRR.values()){
                rr.OOO__c = true;
                updateRR.put(rr.Id, rr);
            }
        }
        
        for(LFBN__Round_Robin_Assignment__c rr: reactivateRR.values()){
            rr.LFBN__Active__c = True;
            rr.OOO__c = false;
            updateRR.put(rr.Id, rr);
        }
        update updateRR.values();

    }*/
    public static void UserFieldsPushtoWebstore(List<User> newUserList, Map<Id, User> OldUserMap) {
        if(newUserList==null || newUserList.size()==0 || OldUserMap.isEmpty() || OldUserMap==null){
            return;
        }
        
        Set<id> userList = new set<id>();
        for(User usr:newUserList){
            if((String.isNotBlank(usr.FirstName) && usr.FirstName != OldUserMap.get(usr.id).FirstName) ||
               (String.isNotBlank(usr.LastName) && usr.LastName != OldUserMap.get(usr.id).LastName )) {
                   userList.add(usr.Id);
               }
        }
        if(userList.isEmpty()){
            return;
        }
        List<Account> accountstoUpdate = TrackAccountFieldsToPublishPlatEvents.trackAccountFields(userList,User.sObjectType);
    	If(accountstoUpdate.size() > 0){
         	update accountstoUpdate;
    	}
    }
        /*List<Account> accList= [select id,Name,Current_Owner_Email__c, Which_Written_Language__c,BigCommerce_Id__c,Push_to_Webstore__c,
                             CurrencyIsoCode,Segment__c ,Segment_Text_Stamped__c,SAM_Number_Undecorated__c,SAM_Number_Decorated__c,
                             Billing_Email__c,Billing_First_Name__c ,Billing_Last_Name__c ,BillingCountry,BillingCountryCode, BillingState,BillingStateCode,
                             Latest_Active_Contract__c from Account where Ownerid in: userList];
        
        if(accList.isEmpty()){
            return;
        }
        Toggle_Platform_Event__mdt accountEventToggle = Toggle_Platform_Event__mdt.getInstance('Account_Sync_Webstore_Event');
        Sync_Object_Field_WebStore__mdt [] accountNullCheckFields = [Select Id,Object_Api_Name__c,Field_Api_Name__c,Null_Check_Needed__c from Sync_Object_Field_WebStore__mdt Where Object_Api_Name__c = 'Account' and Null_Check_Needed__c = true];
        List<Account> AccountstoUpdate = New List<Account>();
        for(Account acc : accList){
                Boolean nullFlagCheck = verifyNullCheck(acc,accountNullCheckFields);
                if ((nullFlagCheck || acc.BigCommerce_Id__c != null) && acc.Push_to_Webstore__c == false && accountEventToggle.toggle__c){ 
                     acc.Push_to_Webstore__c = true;
                     Account Accnt = new Account(Id = acc.Id, Push_to_Webstore__c = true);
                      AccountstoUpdate.add(Accnt);
                }
                
            }
            If(AccountstoUpdate.size() > 0){
                 update AccountstoUpdate;
                }
        
    }
    
    public static Boolean verifyNullCheck(Account Acc,Sync_Object_Field_WebStore__mdt [] AccountNullCheckFields){
        for(Sync_Object_Field_WebStore__mdt EachMdtField: AccountNullCheckFields){
            if(Acc.get(EachMdtField.Field_Api_Name__c)==null){
               return false; 
            }
        }
        return true;
    }*/
     
     
    //ZAK: GTMS-4935-AssetLibrary- Oct-12-2021
    //10/3/23 vijaychandra (GTMS-14030) : Uncommeting below method by vijaychandra AMARANENi
    //10/3/23 vijaychandra (GTMS-14030) : Updateing below code logic as per the ticket requirement
    public static void addPartnerUserToLibraryGroup(List<User> newUserList){
//moved soql query to 181
        List<GroupMember> gMemberList = new List<GroupMember>();
        Map<String,String> grpMap = new Map<String,String>();
        List<String> groupNameList = new List<String>{
                  System.Label.Referral_Program_Partner_Group_Id,
                    System.Label.Resale_Program_Partner_Group_Id,
                    System.Label.Insurance_Partner_Group_Id,
                    System.Label.Service_Partner_Group_Id};
                        
                        for(Group grp:[SELECT Id,DeveloperName FROM Group WHERE DeveloperName IN :groupNameList]){
                            grpMap.put(grp.DeveloperName,grp.Id);
                        }                 
    List<User> userNewList = [SELECT Id, Account.RecordType.DeveloperName, Account.Partner_Type__c,Account.Program_Type__c,Account.ServicesIntegration_Program_Type__c,Account.Partner_Description__c FROM User WHERE Id IN: newUserList];
        if(!grpMap.isEmpty()){
        for(User u : userNewList){
            if(u.Account.RecordType.DeveloperName == 'Partner'){
                //10/3/23 vijaychandra (GTMS-14030): Adding logic for GTMS-14030
                if(u.Account.Program_Type__c != null){
                    if(String.valueOf(u.Account.Program_Type__c).contains('Referral') && grpMap.get(System.Label.Referral_Program_Partner_Group_Id) != null){
                        gMemberList.add(new GroupMember(GroupId = grpMap.get(System.Label.Referral_Program_Partner_Group_Id), UserOrGroupId = u.Id));
                    }
                    if(String.valueOf(u.Account.Program_Type__c).contains('Resale') && grpMap.get(System.Label.Resale_Program_Partner_Group_Id) != null){
                        gMemberList.add(new GroupMember(GroupId = grpMap.get(System.Label.Resale_Program_Partner_Group_Id), UserOrGroupId = u.Id));
                    }
                }
                if(grpMap.get(System.Label.Insurance_Partner_Group_Id) != null && u.Account.Partner_Description__c != null && (String.valueOf(u.Account.Partner_Description__c).Contains('Carrier')||String.valueOf(u.Account.Partner_Description__c).Contains('Broker')||String.valueOf(u.Account.Partner_Description__c).Contains('Captive'))){
                    gMemberList.add(new GroupMember(GroupId = grpMap.get(System.Label.Insurance_Partner_Group_Id), UserOrGroupId = u.Id));
                }
                if(grpMap.get(System.Label.Service_Partner_Group_Id) != null && u.Account.ServicesIntegration_Program_Type__c != null && String.isNotBlank(u.Account.ServicesIntegration_Program_Type__c)){
                    gMemberList.add(new GroupMember(GroupId = grpMap.get(System.Label.Service_Partner_Group_Id), UserOrGroupId = u.Id));
                }
                //10/3/23 vijaychandra --END-- (GTMS-14030)
                /*
                if(String.IsNotBlank(u.Account.Partner_Type__c) && u.Account.Partner_Type__c == 'Insurance'){
                    //add the user to All 3 Public groups
                    gMemberList.add(new GroupMember(GroupId = System.Label.GTMS_Insurance_Library_GroupId, UserOrGroupId = u.Id));
                    gMemberList.add(new GroupMember(GroupId = System.Label.GTMS_SamsaraSol_Library_GroupId, UserOrGroupId = u.Id));
                    gMemberList.add(new GroupMember(GroupId = System.Label.GTMS_Partner_Library_GroupId, UserOrGroupId = u.Id));
                } else {
                    //add the user to Samsara&Partner library PublicGroup
                    gMemberList.add(new GroupMember(GroupId = System.Label.GTMS_SamsaraSol_Library_GroupId, UserOrGroupId = u.Id));
                    gMemberList.add(new GroupMember(GroupId = System.Label.GTMS_Partner_Library_GroupId, UserOrGroupId = u.Id));
                }
                */
            } 
        }
        }
        // added for GTMS-8382 - starts here, Moved the Group Member Insertion to future to avoid Mixed DML Exception
        if (gMemberList.size()>0) {
            if(!System.isFuture() && !System.isBatch() && !System.isScheduled() && !System.isQueueable()){
                String jsonString = json.serialize(gMemberList);
                UserHelper.addPartnerUserToLibraryGroupInFuture(jsonString);
            }           
        }
        // added for GTMS-8382 - ends here
    }
    
    // added for GTMS-8382
    //uncommented below code for GTMS-14030 BY vijaychandra AMARANENI 
    @future
    public static void addPartnerUserToLibraryGroupInFuture(String jsonString){
        //deserialize the JSON to the Group Member List
        List<GroupMember> groupMemberList = (List<GroupMember>)Json.deserialize(jsonString,List<GroupMember>.class);
        if(groupMemberList.size()>0){
            Database.SaveResult[] saveResult = Database.Insert(groupMemberList,false);
        }
    }


    
    //Zak-GTMS - 2023 -- once LaneFour is deprecated, this future method will be primary for RRobin
    public static void callPauseAssignment(Map<Id, User> oldUserMap, Map<Id, User> newUserMap){
        //Serialize the params
        pauseAssignmentFromUserFuture(Json.serialize(oldUserMap), Json.serialize(newUserMap));
    }
    //@future
    public static void pauseAssignmentFromUserFuture(String jsonOld, String jsonNew){
        //Deserialize the input
        Map<Id, User> oldUserMap = (Map<Id, User>)Json.deserialize(jsonOld, Map<Id, User>.class);
        Map<Id, User> newUserMap = (Map<Id, User>)Json.deserialize(jsonNew, Map<Id, User>.class);
        
        Map<Id, RR_Assignment_Mapping__c> updateRRMap = new Map<Id, RR_Assignment_Mapping__c>();
        List<User> pauseUsers = new List<User>();
        List<User> unPauseUsers = new List<User>();
       // Removed RoleIdList as part of GTMS-22259
       // List<String> RoleIdList = System.Label.RR_RoleIds.split(','); 
        List<String> RuleIds = System.Label.RR_RuleIds.split(',');
        
        for(User u: newUserMap.values()){
            if((!oldUserMap.get(u.Id).Inbound_ADR_Out_Of_Office__c && newUserMap.get(u.Id).Inbound_ADR_Out_Of_Office__c) || (oldUserMap.get(u.Id).Enable_ADR_Leads__c && !newUserMap.get(u.Id).Enable_ADR_Leads__c)
                    && newUserMap.get(u.Id).IsActive 
               // && RoleIdList.contains(newUserMap.get(u.Id).UserRoleId)
                     ){
                pauseUsers.add(u);
            }
            else if((oldUserMap.get(u.Id).Inbound_ADR_Out_Of_Office__c && !newUserMap.get(u.Id).Inbound_ADR_Out_Of_Office__c) || (!oldUserMap.get(u.Id).Enable_ADR_Leads__c && newUserMap.get(u.Id).Enable_ADR_Leads__c) 
                    && newUserMap.get(u.Id).IsActive
                     //&& RoleIdList.contains(newUserMap.get(u.Id).UserRoleId)
                    ){
                unPauseUsers.add(u);
            }
        }
        Map<Id, RR_Assignment_Mapping__c> pauseRR = new Map<Id, RR_Assignment_Mapping__c>([SELECT Id, Pause_Assignment__c, Assignment_Rule__c
                                                                                                                FROM RR_Assignment_Mapping__c 
                                                                                                                WHERE User__c =: pauseUsers AND Assignment_Rule__c !=: RuleIds]);

        Map<Id, RR_Assignment_Mapping__c> unPauseRR = new Map<Id, RR_Assignment_Mapping__c>([SELECT Id, Pause_Assignment__c, Assignment_Rule__c
                                                                                                                FROM RR_Assignment_Mapping__c 
                                                                                                                WHERE User__c =: unPauseUsers AND Assignment_Rule__c !=: RuleIds]);
        
        if(pauseRR.size() > 0){
            for(RR_Assignment_Mapping__c rr: pauseRR.values()){
                if( !rr.Pause_Assignment__c ) {  //&& !RuleIds.contains(rr.Assignment_Rule__c) 
                    rr.Pause_Assignment__c = true;
                    updateRRMap.put(rr.Id, rr);
                }
            }
        }
        if( unPauseRR.size() > 0){
            for(RR_Assignment_Mapping__c rr: unPauseRR.values()){
                if( rr.Pause_Assignment__c) {
                    rr.Pause_Assignment__c = false;
                    updateRRMap.put(rr.Id, rr);
                }
            }
        }
        update updateRRMap.values();
    }
}
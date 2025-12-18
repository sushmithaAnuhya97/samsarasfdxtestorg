/*
* Nov 19th, 2020 Ron - (GTMS-1920): (assignAccount, resetFlags) Adjust yoyo hashtag + map for avoiding slacks
* 10/20/2020 Ron (DML Framework RE-MERGE)
* 8/18/2020 - Copy of Billing fields from Contact to Account - (GTMS-1121): (updateAccountBillingInfo, updateAccountBillingDetails on afterUpdate)
* May 14th, 2020 Ron Saavedra - (GTMS-51, GTMS-551, GTMS-560): (assignAccount, manuallyUnloadContact, contactUnload) future execution for channel lead assignment (circumvent standard lead assign rules), adjusted assignAccount to automate Channel AE routing, scalable build for unloading contacts regardless of RecordType
* March 11th, 2020 Ron Saavedra - (GTMS-564): (assignAccount, newInboundOrChannel, contactSourceToAccount) adjusted method to run with inputs from newInboundOrChannel method
* 2/1/2020 - Update AssignAccount methods to adjust for Industrial vertical change & Region Assignment. Utilize Lane Four Region based assignment package - @author: rsaavedra
* 12/16/2019 - 1. Remove duplicate CM logic from ContactHelper & shift to CampaigntoAdd class - @author: rsaavedra
*              2. Deprecate normalized phone logic - @author: rsaavedra
* 12/05/2019 - Manual Unload & Hot Transfer optimization for refactor week - @author: rsaavedra
* 02/27/19 - Changed the condition <Type values> in stamplawfulbasis - @author: Harsha
* 01/19/18 - Consolidated the Triggers- @author: Harsha
* May-6-2022 Rajesh: we are bypassing Systems Automation Robot, in order to fix the GS_TaskRollupBatch error
* Sep-8-2022 Rodrigo : added changes for GTMS-9348
* Nov-1-2022 Chinmaya :added changes for GTMS-8518
* May-31-2023 Siddharth (GTMS-12786): Prevent Contact Status field from being changed if it is in 'Inactive - No Longer There'
* June-27-2023 Zakeer - GTMS-13168: assignContact() swap LFBN__Assign_Account__c to ‘Initiate_Round_Robin__c’ to set it true.
* July-18-2023 Rodrigo - GTMS-13853 added validateContactEmailPartnerUser
* Aug-22-2023 Rodrigo - GTMS-15134 add changes to check for Account Owner is RainMaker then move to SFDC Pool
*/

public without sharing class ContactHelper implements Callable {

    static Map<String, Id> poolMap = null;
    @TestVisible static Map<Id, Account> accountUpdates = new Map<Id, Account>();
    @TestVisible public static Map<Id, Contact> contactToUpdateById = new Map<Id, Contact>();
    static Map<Id, Account> staticAccountsMap = new Map<Id, Account>();
    static Map<Id, Contact> contactFieldsMap = null;
    static Boolean loadedStaticAccounts = false;
    @TestVisible public static String manualSource = 'false';

    @TestVisible private static final String CAMPAIGN_EMAIL = '(Child) Inbound call/email';
    @TestVisible private static final String CAMPAIGN_CHATBOT = '(Child) Intercom';
    @TestVisible private static final String CAMPAIGN_REFERRAL = '(Child) Referral - unpaid';
    private static Map<String, Id> campaignIdByName;
    public static Map<Id, Boolean> yoyoContactMap = new Map<Id, Boolean>();
    public static Boolean customerReferralAssignment = false;
    public static Boolean resetFlags = false;
    public static Boolean csmSurveyFlag = false;   //GTMS-8518  
    static Map<String,Rollup_Switch__mdt> mapOFRollupFieldVsMetadata = new Map<String,Rollup_Switch__mdt> ();
    private static Set<String> targetRollupAccountSet = new Set<String> ();
    private static List<Contact> targetContacts = new List<Contact>();
    public static Slack_Enabled_Campaign_Type__mdt slackCampaignTypes = [  SELECT   Yo_Yo_Enabled_Campaign_Sources__c,
                                                                                    Campaign_Type_List__c
                                                                            FROM Slack_Enabled_Campaign_Type__mdt];

    public static void loadPoolUsers() {
        if(poolMap == null) {
            poolMap = new Map<String, Id>();
            for(Business_Unit_User__mdt userMapping : [ SELECT  Id,
                                                                MasterLabel,
                                                                User_Id__c
                                                        FROM Business_Unit_User__mdt]) {
                poolMap.put(userMapping.MasterLabel, userMapping.User_Id__c);
            }
        }
    }

    //Loads static map of Accounts associated with Contact updates to be utilized throughout the Class
    public static void loadStaticAccountsMap(Set<Id> accountIds) {
        //GTMS-12726
        if(!loadedStaticAccounts && accountIds.size() > 0) {
            staticAccountsMap = new Map<Id, Account>([  SELECT  Id,
                                                                Status__c,
                                                                Organization_Size__c,
                                                                BillingCountry,
                                                            OwnerId,
                                                                Owner.Name,
                                                                Owner.Level__c,
                                                                Owner.ADR_Segment_Alignment__c,
                                                                RecordType.Name,
                                                                Most_Recent_Source__c,
                                                                Owner_Role__c,
                                                                Is_Owner_Pool_User__c,
                                                                Original_Owner_for_Recycling_Campaign__c,
                                                                Open_Opportunity__c,
                                                                Last_Contacted__c,
                                                                Last_Call__c,
                                                                Customer_ARR__c,
                                                                Quarantine_Enabled__c,
                                                                Account_Lifetime_ACV__c,
                                                                RecordType.DeveloperName,
                                                      Initiate_Round_Robin__c
                                                        FROM Account
                                                        WHERE Id IN :accountIds]);
            loadedStaticAccounts = true;
        }
    }

    //GTMS-8518   
    @future
    public static void updateCsmSurvey(Set<Id> contactIdList) {
        List<contact> contactList = new List<contact>();
        //ContactHelper contactHelper = new ContactHelper();
        for(Id convalue : contactIdList) {
            Contact con = new Contact();
            con.Id = convalue;
            con.CSM_survey__c = false;
            contactList.add(con);
        }
        if (contactList.size() > 0)
            Database.update(contactList,false); 
    }
    
    // added for GTMS-13853
    public static void validateContactEmailPartnerUser(List<Contact> newContactList) {
        //Set<String> listContactEmail = new Set<String>();
        Map<String, Id> contactEmailMap = new Map<String, Id>();
        
        FOR (Contact conRec : newContactList) {
            if(conRec.Partner_Portal_User_Id__c==null) {
                //listContactEmail.add(conRec.Email);
                contactEmailMap.put(conRec.Email, conRec.Id);
            }
            
        }
        string userType = (Test.isRunningTest()) ? 'Standard' : 'PowerPartner' ;
        List<User> userList = [SELECT Id,ContactId,Email FROM User WHERE UserType =: userType  AND Email IN: contactEmailMap.keySet()];
        Map<Id, User> userListForUpdate = new Map<Id, User>();
        Map<Id, Contact> contactListForUpdate = new Map<Id, Contact>();
        FOR(User userRec : userList) {
            Id contactId = contactEmailMap.get(userRec.Email);
            
            if (userRec.ContactId == null) {
                userRec.ContactId = contactId;
                userListForUpdate.put(userRec.Id, userRec);
            }
            
            Contact conLocal = new Contact();
            conLocal.Id = contactId;
            conLocal.Partner_Portal_User_Id__c = userRec.Id;
            contactListForUpdate.put(contactId, conLocal);
        }
        
        if (contactListForUpdate.size()>0) {
            TriggerHandler.bypass('ContactTriggerHandler');
            update contactListForUpdate.Values();
        }
            
        /*if (userListForUpdate.size()>0) {
            TriggerHandler.bypass('UserTriggerHandler');
            update userListForUpdate.Values();
        }*/
    }
    public static void sendSurveyMail(List<Contact> newContactList) {
        Set<Id> contactToBeUpdate = new Set<id>();
        ContactHelper contactHelper = new ContactHelper();
        List<EmailTemplate> lstEmailTemplates = [SELECT Id, Body, Subject from EmailTemplate where DeveloperName = 'Send_CSAT_survey_Email'];
        List<Messaging.SingleEmailMessage> emailsList = new List<Messaging.SingleEmailMessage>();
        for(Contact cvalue : newContactList) {
             
            if(cvalue.CSM_survey__c==true && cvalue.Email!=NULL&& !csmSurveyFlag)
            {
                csmSurveyFlag=true;
                //GTMS-26025 - Comemnting the below query and retrieving it outside the loop
                //List<EmailTemplate> lstEmailTemplates = [SELECT Id, Body, Subject from EmailTemplate where DeveloperName = 'Send_CSAT_survey_Email'];
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTemplateId(lstEmailTemplates[0].Id);
                mail.setSaveAsActivity(false);
                mail.setTargetObjectId(cvalue.id);// Any contact or User id of your record
                mail.setToAddresses(new list<string>{'1sheskuw@robot.zapier.com'});
                //mail.setWhatId(); // Enter your record Id whose merge field you want to add in template
                //GTMS-26025
                emailsList.add(mail);
                //Messaging.SendEmailResult[] resultMail = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                contactToBeUpdate.add(cvalue.id);
            }
        }
        if (!emailsList.isEmpty()) {
            Messaging.sendEmail(emailsList);
        }
        if( contactToBeUpdate.size()>0)
        { 
            updateCsmSurvey(contactToBeUpdate); 
        }
        
    }
    //GTMS-8518
    public static void beforeInsertUpdate(Map<Id, Contact> oldContactMap, List<Contact> newContactList) {
        Map<ID, Schema.RecordTypeInfo> rtMap = Contact.sObjectType.getDescribe().getRecordTypeInfosById();
        Set<Id> accountIds = new Set<Id>();
       

        ContactHelper contactHelper = new ContactHelper();
        if(oldContactMap != null && !oldContactMap.isEmpty()){
            Map<Id, Contact> newContactMap = new Map<Id, Contact>(newContactList);
            contactHelper.loadContactFields(newContactMap);  
        }

        for(Contact contact: newContactList){
            accountIds.add(contact.AccountId);
        }  

        loadStaticAccountsMap(accountIds);

        for(Contact c : newContactList) {

            Account acct = staticAccountsMap.get(c.AccountId);
            Boolean stampRecordTypeName = false;
        
            if(oldContactMap != NULL && oldContactMap.containsKey(c.Id)) {
                Contact oldContact = oldContactMap.get(c.Id);
                
                if((oldContact.RecordTypeId != c.RecordTypeId || c.Record_Type_Stamp_For_Dupes__c == NULL) && c.RecordTypeId != NULL)  {
                    stampRecordTypeName = true;
                }

                if( oldContact.OwnerId != c.OwnerId
                    && c.Status__c != 'Assigned'
                   && acct.Is_Owner_Pool_User__c == false){
                       //GTMS-12786
                      //Commented as part of GTMS-25351 
                      // if(c.Status__c!='Inactive - No Longer There')
                       if(c.Inbound_Reason_Faulty__c!='Inactive - No Longer There')
                       {
                        //GTMS-14331 - July19-2023 - Zakeer
                           //c.Status__c = 'Demo Scheduled';
                           c.Status__c = 'Assigned';
                       }  
                   }
                
            } else {
                stampRecordTypeName = true;
                String lawfulBasis = c.Associated_Lawful_Basis__c;

                if(HelperClass.euCountryCodes.contains(c.Account.BillingCountryCode) && (c.Account.Status__c == 'Existing Customer' || c.Account.Type == 'Reseller Partner' || c.Account.Type == 'Referral Partner')) {
                    lawfulBasis = 'Contract';
                } else if(HelperClass.euCountryCodes.contains(c.Account.BillingCountryCode)) {
                    lawfulBasis = 'Legitimate Interest';
                } else {
                    lawfulBasis = 'Not Applicable';
                }

                if(c.Associated_Lawful_Basis__c != lawfulBasis) {
                    c.Associated_Lawful_Basis__c = lawfulBasis;
                }

                if(c.Inbound_Call_Email_Source__c){
                    c.Campaign_to_Add__c = getEmailCampaignId();
                    manualSource = 'true';
                }

                if(c.Referral_Unpaid_Source__c){
                    c.Campaign_to_Add__c = getReferralCampaignId();
                    manualSource = 'true';
                }

               /* if(c.Chatbot_Source__c){
                    c.Campaign_to_Add__c = getChatBotCampaignId();
                    manualSource = 'true';
                }*/
            }

            if(stampRecordTypeName && c.RecordTypeId != NULL) {
                c.Record_Type_Stamp_For_Dupes__c = rtMap.get(c.RecordTypeId).getName();
            }

            // This is used to create External customer Id that is used for customer referral program & will be used for future support purposes -rsaavedra
            if(c.External_Customer_Idv2__c == NULL){
                if(c.FirstName != NULL && c.LastName != NULL){
                    if(c.LastName != NULL) // added for GTMS-9907 to avoid NullPointerException
                    c.External_Customer_Idv2__c = c.FirstName.substring(0,1).toUpperCase().replaceAll('[^a-zA-Z0-9]', 'X')+c.LastName.substring(0,1).toUpperCase().replaceAll('[^a-zA-Z0-9]', 'X')+c.External_Customer_Auto_Gen_Number_V2__c;
                }
                else{
                    if(c.LastName != NULL) // added for GTMS-9348 to avoid NullPointerException
                        c.External_Customer_Idv2__c = 'X'+c.LastName.substring(0,1).toUpperCase().replaceAll('[^a-zA-Z0-9]', 'X')+c.External_Customer_Auto_Gen_Number_V2__c;
                }
            }

            if (c.Record_Type_Id_for_Conversion2__C != null && c.Record_Type_Id_for_Conversion2__c != c.RecordTypeId) {
                c.RecordTypeId = c.Record_Type_Id_for_Conversion2__c;
            }
            if(oldContactMap != NULL){
                ContactWorkflowConversionWS.beforeInsertUpdateRules(c, oldContactMap.get(c.Id), acct, contactFieldsMap.get(c.Id));
                ContactWorkflowConversionWS.beforeUpdate(c, oldContactMap.get(c.Id), acct,contactFieldsMap.get(c.Id));
            }else{
                ContactWorkflowConversionWS.beforeInsertUpdateRules(c, null, acct, null);
            }

            //Set New_Inbound_Lead_Set_dt__c to true if the contact is a new inbound lead checked
            if(c.New_Inbound_Lead__c == true && (oldContactMap == null || oldContactMap.get(c.Id).New_Inbound_Lead__c != c.New_Inbound_Lead__c)){
                c.New_Inbound_Lead_Set_dt__c = System.now();
            }
        }
    }
  public static void concatenatePreferenceField(Map<Id, Contact> oldContactMap, List<Contact> newContactList) {
        //Map<ID, Schema.RecordTypeInfo> rtMap = Contact.sObjectType.getDescribe().getRecordTypeInfosById();
        List<Contact_Preferences_Field_Mapping__mdt> fieldMappingList = Contact_Preferences_Field_Mapping__mdt.getAll().values();
        Map<string, string> fieldVarMap = new Map<string, string>();
        String concatenatedPreferenceText;
        for(Contact_Preferences_Field_Mapping__mdt fieldMap : fieldMappingList){
            fieldVarMap.put(fieldMap.Field_Api_Name__c, fieldMap.Label);
        }
        for(Contact newContact : newContactList) {

            if(oldContactMap != NULL && oldContactMap.containsKey(newContact.Id)) {
                Contact oldContact = oldContactMap.get(newContact.Id);
                Boolean preferenceFieldsChanged = isPreferenceFieldValueChanged(newContact, oldContact,fieldMappingList);
                if(preferenceFieldsChanged){
                    //form the concatenated string value
                    concatenatedPreferenceText = constructPrefString(newContact, fieldVarMap);
                    if(oldContact.Preferences_Text_Stamped__c != concatenatedPreferenceText){
                        newContact.Preferences_Text_Stamped__c = concatenatedPreferenceText;}
                }
            } else {
                concatenatedPreferenceText = constructPrefString(newContact,fieldVarMap);
                newContact.Preferences_Text_Stamped__c = concatenatedPreferenceText;
            }
        }
    }
    public static Boolean isPreferenceFieldValueChanged(Contact newContact, Contact oldContact,Contact_Preferences_Field_Mapping__mdt [] fieldMappingList){
        for(Contact_Preferences_Field_Mapping__mdt mdt: fieldMappingList){
            if(newContact.get(mdt.Field_Api_Name__c)!=oldContact.get(mdt.Field_Api_Name__c)){
                return true;
            }
        }
        return false;
    }
    public static String constructPrefString(Contact newContact, Map<String,String> fieldVarMap){
        String prefString='';
        for(String fieldApiName: fieldVarMap.keySet()){
            prefString += fieldVarMap.get(fieldApiName)+':'+ newContact.get(fieldApiName) +';';
        }
        String prefStringT = prefString.replace('true','T');
        String prefStringTF =prefStringT.replace('false','F');
        return prefStringTF;
    }

    //Method to determine if owner changes have been made to the Contact
    public static void ensureOwnerMatchesAccount(List<Contact> contacts, Map<Id,Contact> oldContactById) {
        List<Contact> filteredContacts = new List<Contact>();
        // Allow Samsara Inbound ADRs to change owner when previous owner is specific user
        String inboundAdrProfileIdsStr = System.Label.Samsara_Inbound_ADR_Id;
        
        List<String> inboundAdrProfileIds = new List<String>();
        if (inboundAdrProfileIdsStr != null) {
            inboundAdrProfileIds = inboundAdrProfileIdsStr.split(',');
        }
        String currentProfileId = String.valueOf(UserInfo.getProfileId());
        Boolean isInboundAdrProfile = (!inboundAdrProfileIds.isEmpty() && inboundAdrProfileIds.contains(currentProfileId));
        for (Contact c : contacts) {
            Contact oldContact = oldContactById.get(c.Id);
            if (oldContact.OwnerId != c.OwnerId) {
                if (!(isInboundAdrProfile && oldContact.OwnerId == System.Label.Shark_Tank_User_Id)) {
                    filteredContacts.add(c);
                }
            }
        }
        if (!filteredContacts.isEmpty()) {
            ensureOwnerMatchesAccount(filteredContacts);
        }
    }
    //Method to match Contact Owner to the Account owner if changes are made to the Contact owner. Ensuring that there is always the same ownership on the Contact level
    public static void ensureOwnerMatchesAccount(List<Contact> contacts) {

        Set<Id> accountIds = new Set<Id>();
        for (Contact c : contacts) {
            accountIds.add(c.AccountId);
        }
        if (accountIds.isEmpty()) {
            return;
        }

        Map<Id, Account> accountById = new Map<Id, Account>([   SELECT  Id,
                                                                        OwnerId,owner.isActive,
                                                                        Is_Owner_Pool_User__c
                                                                FROM Account
                                                                WHERE Id IN :accountIds]);
        for (Contact c : contacts) {
            Account acct = accountById.get(c.AccountId);
            //GTMS-25379
       if(c.Last_Marketing_Engagement_Date__c!=null && DateTime.now().isSameDay(c.Last_Marketing_Engagement_Date__c) ){
                continue;
            }
            //GTMS-25379
            if (c.Status__c == 'New') {
                c.Status__c = 'Assigned';
            }

            if(acct!=null && acct.owner.isActive==True){
                if(acct.Is_Owner_Pool_User__c == false || acct.OwnerId != c.OwnerId) {
                    c.OwnerId = acct.OwnerId;
                }
            }      
        }
    }

    public static void updateAccountDemoDate(List<Contact> contacts, Map<Id,Contact> oldContactById) {
        List<Contact> filteredContacts = new List<Contact>();
        for (Contact c : contacts) {
            Contact oldContact = oldContactById.get(c.Id);
            if (oldContact.Scheduled_Demo_Date__c != c.Scheduled_Demo_Date__c || oldContact.Status__c != c.Status__c) {
                filteredContacts.add(c);
            }
        }
        if (!filteredContacts.isEmpty()) {
            updateAccountDemoDate(filteredContacts);
        }
    }
    
    public static void updateAccountBillingInfo(List<Contact> contacts, Map<Id,Contact> oldContactById) {
        Map<Id, List<Contact>> accountIds = new Map<Id, List<Contact>>();
        for (Contact c : contacts) {
            Contact oldContact = oldContactById.get(c.Id);
            if (oldContact.AccountId != c.AccountId || oldContact.Billing_First_Name__c != c.Billing_First_Name__c ||
               oldContact.Billing_Last_Name__c != c.Billing_Last_Name__c || oldContact.Billing_Email__c != c.Billing_Email__c ||
                oldContact.Billing_Phone__c != c.Billing_Phone__c) {
                    if (accountIds.containsKey(c.AccountId)) {
                        List<Contact> contactList = accountIds.get(c.AccountId);
                        contactList.add(c);
                        accountIds.put(c.AccountId, contactList);
                    }
                    else {
                        accountIds.put(c.AccountId, new List<Contact>{c});
                    }
            }
        }
            if (!accountIds.isEmpty()) {
                updateAccountBillingDetails(accountIds);
            }
        
    }
    
    public static void updateAccountBillingDetails(Map<Id, List<Contact>> accountIds) {
        List<Account> updateAccountList = new List<Account>();
        for (Account acc : [select Id, Billing_Contact__c, Billing_First_Name__c, Billing_Last_Name__c, Billing_Phone__c, Billing_Email__c
                            from Account where Id IN : AccountIds.keySet()]) {
            List<Contact> contactList = accountIds.get(acc.Id);
            if (!accountUpdates.containsKey(acc.id)) accountUpdates.put(acc.Id, acc);
            for (Contact con : contactList) {
                if (acc.Billing_Contact__c == con.Id) {
                    //acc.Billing_First_Name__c = con.Billing_First_Name__c;
                    //acc.Billing_Last_Name__c = con.Billing_Last_Name__c;
                    //acc.Billing_Email__c = con.Billing_Email__c;
                    //acc.Billing_Phone__c = con.Billing_Phone__c;
                    //updateAccountList.add(acc);
                    //Centralize DML using UOW
                    accountUpdates.get(acc.Id).Billing_First_Name__c = con.Billing_First_Name__c;
                    accountUpdates.get(acc.Id).Billing_Last_Name__c = con.Billing_Last_Name__c;
                    accountUpdates.get(acc.Id).Billing_Email__c = con.Billing_Email__c;
                    accountUpdates.get(acc.Id).Billing_Phone__c = con.Billing_Phone__c;
                }
            }
        }

        //if (!updateAccountList.isEmpty())
        //update updateAccountList;
        // DMLWrapper.doUpdate(updateAccountList);
    }

    public static void updateAccountDemoDateFuture(List<Contact> contacts) {
        Map<Id,Contact> contactById = new Map<Id,Contact>(contacts);
        updateAccountDemoDateFuture(contactById.keySet());
    }
    @Future
    public static void updateAccountDemoDateFuture(Set<Id> contactIds) {
        List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
                Account.SObjectType
        };
        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
        List<Contact> contacts = [
                SELECT Id,
                        Scheduled_Demo_Date__c,
                        AccountId,
                        Status__c
                FROM Contact
                WHERE Id IN :contactIds
        ];
        Map<Id, Account> accountUpdates = updateAccountDemoDate(contacts);
        List<Account> accountListToUpdate = accountUpdates.values();
        List<Account> accountListToUpdateAgain = accountUpdates.values();
        List<Database.SaveResult> updateResults = new List<Database.SaveResult>();
        
        //update accountUpdates.values();
        if(System.Label.Contact_Row_Lock =='0')//GTMS - 9613
                 {
        DMLWrapper.doUpdate(accountUpdates.values());
        DMLWrapper.publishDML();     
                 }
        if(System.Label.Contact_Row_Lock !='0') 
                 {

            updateResults = Database.update(accountListToUpdate,false);
            for(Integer i=0;i<updateResults.size();i++)
            {
                 if(!updateResults[i].isSuccess())
                 {
                     for(Database.Error err : updateResults[i].getErrors())
                     {
                           //System.DmlException: Update failed. First exception on row 0; first error: UNABLE_TO_LOCK_ROW, unable to obtain exclusive access to this record or 1 records: 7014p000000JMo4AAG: []
                         if(err.getMessage().contains('UNABLE_TO_LOCK_ROW'))
                         {
                            accountListToUpdateAgain.add(accountListToUpdate[i]);
                             
                         }
                     }
                 }
            }    
                        
                Database.update(accountListToUpdateAgain,false);   
                 }
        
        
    }
    public static Map<Id, Account> updateAccountDemoDate(List<Contact> contacts) {

        Map<Id, List<Contact>> contactsByAccountId = new Map<Id, List<Contact>>();
        for (Contact c : contacts) {
            if (c.AccountId != null &&
                c.Scheduled_Demo_Date__c != null &&
                (c.Status__c =='Qualified') || c.Status__c == 'Demo Completed - Not Qualified')
            {
                if (contactsByAccountId.containsKey(c.AccountId)) {
                    contactsByAccountId.get(c.AccountId).add(c);
                } else {
                    contactsByAccountId.put(c.AccountId, new List<Contact>{c});
                }
            }
        }
        if (contactsByAccountId.isEmpty()) {
            return new Map<Id, Account>();
        }
        for (Account acct : [   SELECT  Id,
                                        First_Demo_Date__c
                                FROM Account
                                WHERE Id IN :contactsByAccountId.keySet()
                                AND First_Demo_Date__c = null])
        {
            Account accountToUpdate;
            if (accountUpdates.containsKey(acct.Id)) {
                accountToUpdate = accountUpdates.get(acct.Id);
            } else {
                accountToUpdate = new Account(Id=acct.Id);
            }
            for (Contact c : contactsByAccountId.get(acct.Id)) {
                if(c.Scheduled_Demo_Date__c != null){
                    accountToUpdate.First_Demo_Date__c = c.Scheduled_Demo_Date__c.dateGmt();
                }
            }

            accountUpdates.put(accountToUpdate.Id, accountToUpdate);
        }

        return accountUpdates;
    }

    //This method updates the account First Demo Date of the account if the demo date changes on an associated contact
    public static void demoDateChanges(List<Contact> contacts, Map<Id,Contact> oldContactById) {
        Map<Id, List<Contact>> contactsByAccountId = new Map<Id, List<Contact>>();
        for (Contact c : contacts) {
            Contact oldContact = oldContactById.get(c.Id);
            if (oldContact.Demo_Date__c != c.Demo_Date__c && c.Demo_Date__c != null) {
                if (contactsByAccountId.containsKey(c.AccountId)) {
                    contactsByAccountId.get(c.AccountId).add(c);
                } else {
                    contactsByAccountId.put(c.AccountId, new List<Contact>{c});
                }
            }
        }

        for (Account acct : [   SELECT  Id
                                FROM Account
                                WHERE Id IN :contactsByAccountId.keySet()
                                AND First_Demo_Date__c = null]) {
            for (Contact c : contactsByAccountId.get(acct.Id)) {

                if (accountUpdates.containsKey(acct.Id)) {
                    Account a = accountUpdates.get(acct.Id);
                    a.First_Demo_Date__c = c.Demo_Date__c;
                    accountUpdates.put(acct.Id, a);
                }
                else {
                    acct.First_Demo_Date__c = c.Demo_Date__c;
                    accountUpdates.put(acct.Id, acct);
                }
            }
        }
    }


    // The following get methods retrieve campaign Ids for unique campaigns to be appended to the Contact
    private static Id getEmailCampaignId() {
        Id campaignId = getCampaignIdByName().get(CAMPAIGN_EMAIL);
        return campaignId == null? '7011a000000SI78' : campaignId;
    }
    private static Id getChatBotCampaignId() {
        Id campaignId = getCampaignIdByName().get(CAMPAIGN_CHATBOT);
        return campaignId == null? '7011a000000SI7w' : campaignId;
    }
    private static Id getReferralCampaignId() {
        Id campaignId = getCampaignIdByName().get(CAMPAIGN_REFERRAL);
        return campaignId == null? '7011a000000SI6j' : campaignId;
    }
    private static Map<String, Id> getCampaignIdByName() {
        if (campaignIdByName == null) {
            campaignIdByName = new Map<String, Id>();
            for (Campaign campaign : [  SELECT  Id,
                                                Name
                                        FROM Campaign
                                        WHERE Name IN (:CAMPAIGN_EMAIL, :CAMPAIGN_CHATBOT, :CAMPAIGN_REFERRAL)]) {
                campaignIdByName.put(campaign.Name, campaign.Id);
            }
        }
        return campaignIdByName;
    }

    // triggers customer referral assignment flow
    /* commented Rodrigo
     * public static void customerReferrals(List<Contact> contacts, Map<Id,Contact> oldContactById) {

        Set<Id> contactIds = new Set<Id>();
        Map<String, Object> params = new Map<String, Object>();

        for (Contact c : contacts) {
            if (oldContactById != null){
                Contact oldContact = oldContactById.get(c.Id);
                if(oldContact.Referring_Customer_Id__c != c.Referring_Customer_Id__c && c.Referring_Customer_Id__c != null) {
                    params.put('recordId2', c.Id);
                    params.put('refCustId', c.Referring_Customer_Id__c);
                }
            } else {
                if (c.Referring_Customer_Id__c != null){
                    params.put('recordId2', c.Id);
                    params.put('refCustId', c.Referring_Customer_Id__c);
                }
            }

            if(params.size() > 0){
                Flow.Interview.Customer_Referral_Assignment flow = new Flow.Interview.Customer_Referral_Assignment(params);
                flow.start();
                customerReferralAssignment = Boolean.valueOf(flow.getVariableValue('vReferralAssignmentRan'));
            }
        }
    }*/

    // Inbound Lead = TRUE
    // Clear Channel Source
    public static void resetFlags(List<Contact> contacts, Boolean isUpdate) {

        String hashtag;
        String description;
        String ibform;

        for (Contact c : contacts) {
            Account acct = staticAccountsMap.get(c.AccountId);
            Contact contactToUpdate = new Contact(Id = c.Id);
            contactToUpdate = getLoadedContact(contactToUpdate);
            if(yoyoContactMap != null && yoyoContactMap.containsKey(c.Id) && yoyoContactMap.get(c.Id)){
                hashtag = contactToUpdate.Hashtag__c;
            } else{
                hashtag = c.Hashtag__c;
            }
            
            //GTMS--17283
      if(c.Inbound_Form_Message_to_append__c != null){
                if(c.Inbound_Form_Message__c != null){
                  ibForm = c.Inbound_Form_Message__c + '\n' + c.Inbound_Form_Message_to_append__c;
                }else{
                    ibForm = c.Inbound_Form_Message_to_append__c;
                }
                contactToUpdate.Inbound_Form_Message__c = ibForm;
                contactToUpdate.Inbound_Form_Message_to_append__c = null;
                contactToUpdateById.put(contactToUpdate.Id, contactToUpdate);
            }

            if (c.Converted_Contact__c != null) {

                // append hashtag
                if (c.Converted_Hashtags_to_Append__c != null){
                    if(hashtag != null){
                        if(!hashtag.contains(c.Converted_Hashtags_to_Append__c)){
                            hashtag = c.Converted_Hashtags_to_Append__c + ' ' + hashtag;
                        }
                    }
                    else {
                        hashtag = c.Converted_Hashtags_to_Append__c;
                    }   
                }
                
                // converted notes to append
                if (c.Converted_Notes_to_Append__c != null && isUpdate) {
                    description = c.Converted_Notes_to_Append__c + ' ' + c.Description;
                }
                else{
                    description = c.Description;
                }
                
              contactToUpdate.Converted_Contact__c = null;
                contactToUpdate.Converted_Hashtags_to_Append__c = null;
                contactToUpdate.Converted_Notes_to_Append__c = null;
                contactToUpdate.Hashtag__c = hashtag;
                contactToUpdate.Description = description;
                contactToUpdateById.put(contactToUpdate.Id, contactToUpdate);
            }

            if ((c.New_Inbound_Lead__c == true || c.Channel_Source__c == true) && !resetFlags){
                if(!(c.Most_Recent_Source__c == 'Sites webinar registration form' && acct.Customer_ARR__c > 0 && acct.Quarantine_Enabled__c == False)) contactToUpdate.New_Inbound_Lead__c = false;
                //if(c.Most_Recent_Source__c != 'Sites webinar registration form') contactToUpdate.New_Inbound_Lead__c = false;
                contactToUpdate.Channel_Source__c = false;
                contactToUpdate.Referring_Customer_Id__c = null;
                contactToUpdateById.put(contactToUpdate.Id, contactToUpdate);
                resetFlags = true;
            }
        }
    }

    public static void checkForOptOutDupes(List<Contact> newContactList, Map<Id, Contact> oldContactMap) {
        DiagnosticsInstrumentation.push('ContactHelper.checkForOptOutDupes');
        // First, make sets of all the emails and phones we need to check agains
        Map<String, List<Contact>> emailsMap = new Map<String, List<Contact>>();
        Map<String, List<Contact>> phonesMap = new Map<String, List<Contact>>();
        Boolean changeToOptOut = false;

        //GTMS-6979
        if(Label.SystemsAutomationRobotUserId.contains(UserInfo.getUserId())) return;

        for(Contact c : newContactList) {
            if(oldContactMap != null){
                Contact oldContact = oldContactMap.get(c.Id);
                changeToOptOut = ((!oldContact.Phone_Opt_Out__c && c.Phone_Opt_Out__c)
                                    || (!oldContact.HasOptedOutOfEmail && c.HasOptedOutOfEmail)
                                    || (!oldContact.Sales_Email_Opt_Out__c && c.Sales_Email_Opt_Out__c)) ? true: false;
            }
            
            if(!changeToOptOut){
                if(c.Email != NULL) {
                    if(!emailsMap.containsKey(c.Email)) {
                        List<Contact> cList = new List<Contact>();
                        cList.add(c);
                        emailsMap.put(c.Email, cList);
                    } else {
                        emailsMap.get(c.Email).add(c);
                    }
                    }
                if(c.Phone != NULL) {
                    if(!phonesMap.containsKey(c.Phone)) {
                        List<Contact> cList = new List<Contact>();
                        cList.add(c);
                        phonesMap.put(c.Phone, cList);
                    } else {
                        phonesMap.get(c.Phone).add(c);
                    }
                    }
                if(c.MobilePhone != NULL) {
                    if(!phonesMap.containsKey(c.MobilePhone)) {
                        List<Contact> cList = new List<Contact>();
                        cList.add(c);
                        phonesMap.put(c.MobilePhone, cList);
                    } else {
                        phonesMap.get(c.MobilePhone).add(c);
                    }
                }
            }
        }
        try{
            // Select all opted-out ppl
            //TODO - add limit here for how many records can be queried
            for(Contact optout : [  SELECT  Id,
                                            Opt_Out_Email_Copy__c,
                                            Opt_Out_Mobile_Phone__c,
                                            Opt_Out_Phone__c
                                    FROM Contact
                                    WHERE Opt_Out_Phone__c IN :phonesMap.keySet()
                                    OR Opt_Out_Mobile_Phone__c IN :phonesMap.keySet()
                                    OR Opt_Out_Email_Copy__c IN :emailsMap.keySet()])                                    
             {
                if (GAS_TriggerToggle.triggerStatus('GainSight')) { // condition added for GTMS-10530
                // Throw exception if anything was found
                if(emailsMap.containsKey(optout.Opt_Out_Email_Copy__c)) {
                    //TODO - use size parameter to avoid for loop
                    for(Contact c : emailsMap.get(optout.Opt_Out_Email_Copy__c)) {
                        c.addError('Unable to create/update contact because their Email matches another contact in our "Do Not Contact" list.');
                    }
                }
                if(phonesMap.containsKey(optout.Opt_Out_Mobile_Phone__c)) {
                    //TODO - use size parameter to avoid for loop
                    for(Contact c : phonesMap.get(optout.Opt_Out_Mobile_Phone__c)) {
                        c.addError('Unable to create/update contact because their Mobile Phone matches another contact in our "Do Not Contact" list.');
                    }
                }
                if(phonesMap.containsKey(optout.Opt_Out_Phone__c)) {
                    //TODO - use size parameter to avoid for loop
                    for(Contact c : phonesMap.get(optout.Opt_Out_Phone__c)) {
                        c.addError('Phone number matches another contact on our "do not contact" list, please work with partner contact to enter a valid phone number.');
                        }
                    }
                }
            }
        } catch(Exception e){
            System.debug('There was an error: ' + e);
        }
        DiagnosticsInstrumentation.pop();
    }

    public static void setAccountStatusFromContact(Map<Id, Contact> oldContactMap, Map<Id, Contact> newContactMap) {
        if (oldContactMap == null || oldContactMap.isEmpty() || 
            newContactMap == null || newContactMap.isEmpty()) {
                return;
            }
        
        List<Id> accountIds=new List<Id>();
        Set<Id> contactIdsWithStatusChange = new Set<Id>(); // For task updates

        for(Contact c: newContactMap.values()){
            if( oldContactMap.get( c.Id ).Status__c != newContactMap.get( c.Id ).Status__c ){
                accountIds.add(c.AccountId);
                contactIdsWithStatusChange.add(c.Id);
            }
        }
        
        // Execute task status updates if there are status changes
        if (!contactIdsWithStatusChange.isEmpty()) {
            TaskContactStatusUpdateQueueable.executeQueueable(contactIdsWithStatusChange);
        }
        
        Map<Id, Account> accountsMap = new Map<Id, Account>();
        // Only query if necessary!
        if(accountIds.size() > 0) {
            //TODO - check query time here nested query vs separate
            accountsMap = new Map<Id, Account>([SELECT  Id,
                                                        Status__c,
                                                        Owner.Name,
                                                        First_Purchase_Date__c,
                                                        First_Revenue_Oppty_Creation_Date__c,
                                                        Closed_Lost_Account__c,
                                                        (SELECT Id,
                                                                StageName,
                                                                Type,
                                                                Owner.Name
                                                        FROM Opportunities
                                                        WHERE Type='Revenue Opportunity'),
                                                        (SELECT Id,
                                                                Status__c
                                                        FROM Contacts)
                                                FROM Account
                                                WHERE Id IN :accountIds]);
                                                //AND Is_Owner_Pool_User__c = true]); REVIEW -rsaavedra
        }

        for(Contact c: newContactMap.values()){
            if( oldContactMap.get( c.Id ).Status__c != newContactMap.get( c.Id ).Status__c ){

                if(accountsMap.containsKey(c.AccountId)){
                    Account a = accountsMap.get(c.AccountId);
                    Boolean anyClosedWonOpptiesByOwner=false;
                    Boolean anyOpenOpptiesByOwner=false;
                    Boolean noClosedLostByOwner=true;

                    for (Opportunity opportunity : a.Opportunities) {
                        if(opportunity.StageName=='Closed Lost' && opportunity.Owner.Name==a.Owner.Name && a.Owner.Name!='SFDC Pool') {
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
                    for (Contact contact : a.Contacts) {
                        // System.debug(contact);
                        //Commented as part of GTMS-25352
                        /*if(contact.Status__c=='Delete Account') {
                            anyDelete=true;
                        }*/
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
                        //Commented as part of GTMS-25394
                        /*if(contact.Status__c=='Contact Established') {
                            anyContactEstablished=true;
                        }*/
                        if(contact.Status__c=='Attempting') {
                            anyAttempting=true;
                        }
                        if(contact.Status__c=='Retouch - Did not Connect') {
                            anyDidNotConnect=true;
                        }
                        if(contact.Status__c=='Demo Scheduled') {
                            anyDemoScheduled=true;
                        }
                        //Commented as part of GTMS-25351
                        /*if(contact.Status__c!='Delete Contact Only') {
                            allContactDelete=false;
                        }*/
                    }

                    Boolean updateStatus=true;
                    Datetime firstPurchase=a.First_Purchase_Date__c;
                    Datetime firstRevenueOppty=a.First_Revenue_Oppty_Creation_Date__c;
                    Boolean closedLostAccount=a.Closed_Lost_Account__c;

                    if(firstPurchase!=null) {
                        accountStatus='Existing Customer';
                    }
                    else if(closedLostAccount && !noClosedLostByOwner) {
                        accountStatus='Closed Lost Opportunity';
                    }
                    else if(firstRevenueOppty!=null && !closedLostAccount) {
                        accountStatus='Open Opportunity';
                    }
                    //Commented as part of GTMS-25352
                    /*else if(anyDelete) {
                        accountStatus='Delete';
                    }*/
                    else if(anyQualified) {
                        accountStatus='Qualified';
                    }
                    else if(anyRetouchNoOpp) {
                        accountStatus='Retouch - Confirmed No Opportunity';
                    }
                    else if(anyDemoScheduled) {
                        accountStatus='Demo Scheduled';
                    }
                    //Commented as part of GTMS-25394
                    /*else if(anyContactEstablished) {
                        accountStatus='Contact Established';
                    }*/
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
                   //Commented as part of GTMS-25351
                    /*else if(allContactDelete) {
                        accountStatus='New';
                    }*/
                    else{
                        updateStatus=false;
                    }

                    if(updateStatus) {
                        a.Status__c = accountStatus;
                    }
                    if(!accountUpdates.containsKey(a.Id)) {
                        accountUpdates.put(a.Id, new Account(Id = a.Id, Status__c = a.Status__c));
                    }
                }
            }
        }
    }

    /* Hot Transfer functionality for Inbound transfers.
     Centralized the code and made changes for few quick wins - Harsha
     Note: Need to refactor this method, lot of SOQL's and DML's within for Loop - will get back when there is sometime for this work.*/
    /*
    public static void hotTransfer(Map<Id, Contact> oldContactMap, Map<Id, Contact> newContactMap, List<Contact> newContactList){

        // If the Hot Transfer Field has changed, then update the ADR Transfer fields and change the owner.
        List<Contact> updatedContacts = new List<Contact>();
        List<Account> updatedAccounts = new List<Account>();
        List<ADR_Transfer_Log__c> newAdrTransferLogs = new List<ADR_Transfer_Log__c>();
        List<CampaignMember> newCampaignMembers = new List<CampaignMember>();

        if(contactFieldsMap == NULL){
            contactFieldsMap = new Map<Id, Contact>([SELECT  Id,
                                            Account.Original_Owner_for_Recycling_Campaign__c,
                                            Account.Enterprise_Experiments__c,
                                            Owner.UserRole.Name,
                                            Account.Original_Owner_for_Recycling_Campaign__r.Name,
                                            ADR_Transfer__c,
                                            ADR_Transfer_By__c,
                                            OwnerId,
                                            ADR_Transfer_Date__c,
                                            ADR_Demo_Date__c,
                                            ADR_Transfer_Status__c,
                                            Hot_Transfer_To__c,
                                            AccountId,
                                            (SELECT Id,
                                                    ADR_Transfer__c,
                                                    ADR_Transfer_By__c,
                                                    ADR_Transfer_Status__c
                                            FROM ADR_Transfer_Logs__r
                                            WHERE ADR_Transfer_Date__c = LAST_N_DAYS:30
                                            AND ADR_Transfer__c = false
                                            ORDER BY CreatedDate
                                            DESC limit 1)
                                    FROM Contact WHERE Id IN :newContactMap.keySet()]);
        }
        
        Map<Id,Contact> contactById = new Map<Id,Contact>(contactFieldsMap);

        for(Contact contact: newContactList){

            if ((oldContactMap.get( contact.Id ).Hot_Transfer_To__c != newContactMap.get( contact.Id ).Hot_Transfer_To__c) && (oldContactMap.get( contact.Id ).Hot_Transfer_To__c==null))
            {
                if (!contactById.containsKey(contact.Id)) {
                    continue;
                }
                Contact contactDetails = contactById.get(contact.Id);

                if(contactDetails.Account.Original_Owner_for_Recycling_Campaign__c==null){

                    ADR_Transfer_Log__c adrTransfer = new ADR_Transfer_Log__c();
                    adrTransfer.ADR_Transfer_By__c = UserInfo.getUserId();
                    adrTransfer.ADR_Transfer_Date__c = System.Now();
                    adrTransfer.ADR_Demo_Date__c = System.Now();
                    adrTransfer.ADR_Role_Copy__c = contactDetails.Owner.UserRole.Name;
                    adrTransfer.ADR_Transfer_Status__c = 'Demo Scheduled';
                    adrTransfer.Contact__c = contactDetails.Id;
                    adrTransfer.Account__c = contactDetails.AccountId;
                    adrTransfer.AE_Demo_Transfer_To__c = contact.Hot_Transfer_To__c;
                    adrTransfer.Hot_Transfer__c = True;
                    String transferCopy = contactDetails.Account.Enterprise_Experiments__c == null ? 'Standard' : contactDetails.Account.Enterprise_Experiments__c;
                    adrTransfer.Transfer_Type_At_Transfer_Copy__c = transferCopy;
                    List <ADR_Transfer_Log__c> existingADRTransfers = contactDetails.ADR_Transfer_Logs__r;
                    if (existingADRTransfers.size() == 0) {
                        //newAdrTransferLogs.add(adrTransfer);
                        DMLWrapper.doInsert(adrTransfer);
                    }
                    //contactDetails.OwnerId = contact.Hot_Transfer_To__c;
                    //contactDetails.Status__c = 'Demo Scheduled';
                    //updatedContacts.add(contactDetails);
                    if (!contactToUpdateById.containsKey(contactDetails.Id)) contactToUpdateById.put(contactDetails.Id, contactDetails);

                    contactToUpdateById.get(contactDetails.Id).OwnerId = contact.Hot_Transfer_To__c;
                    contactToUpdateById.get(contactDetails.Id).Status__c = 'Demo Scheduled';

                    if (contactDetails.AccountId != null) {
                        //Account a1 = new Account(Id=contactDetails.AccountId);
                        //a1.OwnerId = contact.Hot_Transfer_To__c;
                        //updatedAccounts.add(a1);
                        if (!accountUpdates.containsKey(contactDetails.AccountId)) accountUpdates.put(contactDetails.AccountId, new Account(Id = contactDetails.AccountId));

                        accountUpdates.get(contactDetails.AccountId).OwnerId = contact.Hot_Transfer_To__c;

                    }
                }
                else{
                    //TODO - review why this isn't being triggered
                    CalloutException k = new CalloutException();
                    k.setMessage('You cannot hot transfer this account. It must be a scheduled demo with '+contactDetails.Account.Original_Owner_for_Recycling_Campaign__r.Name+'. Please use the standard transfer process.');
                    throw k;
                }
            }
        }

        try {
            //Update been handled using Contact and Account Map
            
            //if (newAdrTransferLogs.size() > 0) {
            //insert newAdrTransferLogs;
            // DMLWrapper.doInsert(newAdrTransferLogs);
            //}
            if (newCampaignMembers.size() > 0) {
                //insert newCampaignMembers;
                DMLWrapper.doInsert(newCampaignMembers);
            }
        }
        catch(DmlException e){
            System.debug('The following exception has occurred in the method hotTransfer: ' + e.getMessage());
        }

    }
    */
    //Loads static map of Contacts and its related fields to be utilized throughout the Class
    public void loadContactFields(Map<Id, Contact> newContactMap){
        if (contactFieldsMap == null) {
            contactFieldsMap = new Map<Id, Contact>([SELECT  Id,
                                            Account.Original_Owner_for_Recycling_Campaign__c,
                                            Account.Enterprise_Experiments__c,
                                            Owner.UserRole.Name,
                                            Account.Original_Owner_for_Recycling_Campaign__r.Name,
                                            ADR_Transfer__c,
                                            ADR_Transfer_By__c,
                                            OwnerId,
                                            ADR_Transfer_Date__c,
                                            ADR_Demo_Date__c,
                                            ADR_Transfer_Status__c,
                                            Hot_Transfer_To__c,
                                            AccountId,
                                            (SELECT Id,
                                                    ADR_Transfer__c,
                                                    ADR_Transfer_By__c,
                                                    ADR_Transfer_Status__c
                                            FROM ADR_Transfer_Logs__r
                                            WHERE ADR_Transfer_Date__c = LAST_N_DAYS:30
                                            AND ADR_Transfer__c = false
                                            ORDER BY CreatedDate
                                            DESC limit 1)
                                    FROM Contact WHERE Id IN :newContactMap.keySet()]);}
    }

    /* Manually Unload Contact functionality.
     Centralized the code and made changes for few quick wins - Harsha */
    //* May 14th, 2020 Ron Saavedra - (GTMS-51, GTMS-551, GTMS-560): (assignAccount, manuallyUnloadContact, contactUnload) future execution for channel lead assignment (circumvent standard lead assign rules), adjusted assignAccount to automate Channel AE routing, scalable build for unloading contacts regardless of RecordType
    public static void manuallyUnloadContact(Map<Id, Contact> oldContactMap, Map<Id, Contact> newContactMap, List<Contact> newContactList){

        List<Contact> contactsFlaggedToUnloadAccount = new List<Contact>();
        Map<Id, String> accountIdToPool = new Map<Id, String>();
        Id poolOwnerId;
        String recordTypeName;

        for (Contact c : newContactList) {
            if (c.Unload_Account__c == true) {
                contactsFlaggedToUnloadAccount.add(c);
            }
        }
        if (contactsFlaggedToUnloadAccount.isEmpty()) {
            return;
        }

        if(HelperClass.unloadContactQueryFlag == false){
            loadPoolUsers();
            HelperClass.unloadContactQueryFlag = true;
        }

        Map<Id, Account> accountByContactId = new Map<Id, Account>();
        Map<Id, List<Contact>> contactsByAccountId = new Map<Id, List<Contact>>();
        for (Contact c : contactsFlaggedToUnloadAccount) {
            if (contactsByAccountId.containsKey(c.AccountId)) {
                contactsByAccountId.get(c.AccountId).add(c);
            } else {
                contactsByAccountId.put(c.AccountId, new List<Contact>{c});
            }
        }
        for (Account acct : [   SELECT  Id,
                                        Hashtag__c,
                                        RecordType.Name,
                                        Name,
                                        Status__c,
                                        Number_of_Calls_by_Current_Owner__c,
                                        Event_Lead__c,
                                        Original_Owner_for_Recycling_Campaign__c,
                                   Account_Book_Owner__c,
                                        (SELECT Id,
                                                StageName,
                                                Trial_Status__c,
                                                Type
                                        FROM Opportunities)
                                        FROM Account
                                        WHERE Id IN :contactsByAccountId.keySet()])
        {
            for (Contact c : contactsByAccountId.get(acct.Id)) {
                accountByContactId.put(c.Id, acct);
            }
        }

        for(Contact contact: contactsFlaggedToUnloadAccount){
            List<Opportunity> openRevenueOpportunities = new List<Opportunity>();
            List<Opportunity> openFreeTrailOpportunities = new List<Opportunity>();
            String hashtag='';

            if((contact.Unload_Account__c == True) && (oldContactMap.get( contact.Id ).Unload_Account__c != newContactMap.get( contact.Id ).Unload_Account__c)) {
                if(contact.Status__c != null && (contact.Status__c=='Faulty Lead' || contact.Status__c.contains('Retouch') || contact.Inbound_Reason_Faulty__c=='Delete Account')){ // added null check for GTMS-9348

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
                    accountIdToPool.put(contact.AccountId, recordTypeName);
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
                        contactUnload(accountIdToPool);
                    }
                }
                else{
                    CalloutException k = new CalloutException();
                    k.setMessage('You are trying to unload an account but the contact is not at Retouch or Delete Account statuses.');
                    throw k;
                }
            }
        }
    }

    //* May 14th, 2020 Ron Saavedra - (GTMS-51, GTMS-551, GTMS-560): (assignAccount, manuallyUnloadContact, contactUnload) future execution for channel lead assignment (circumvent standard lead assign rules), adjusted assignAccount to automate Channel AE routing, scalable build for unloading contacts regardless of RecordType
    @Future
    public static void contactUnload(Map<Id, String> accountToPool) {
        List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
                Contact.SObjectType
        };
        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
        Map<Id, Contact> contactsToUpdateOwner = new Map<Id, Contact>([
                SELECT Id,
                        OwnerId
                FROM Contact
                WHERE AccountId IN :accountToPool.keySet()
        ]);
        List<Contact> contactListUpdateAgain = new List<Contact>();
        List<Contact> contactListUpdate = new List<Contact>();
        List<Database.SaveResult> updateresults = new List<Database.SaveResult>();

        loadPoolUsers();

        for (Contact c : contactsToUpdateOwner.values()) {
            String poolType = accountToPool.get(c.Id) != null ? accountToPool.get(c.Id) : 'Fleet';

            c.OwnerId = poolMap.get(poolType);
            contactsToUpdateOwner.put(c.Id, c);
        }
        //update contactsToUpdateOwner.values();
        if(System.Label.Contact_Row_Lock =='0'){ ////GTMS - 9613
            DMLWrapper.doUpdate(contactsToUpdateOwner.values());
            DMLWrapper.publishDML();
        }
        if(System.Label.Contact_Row_Lock !='0' || Test.isRunningTest()){
            
            contactListUpdate = contactsToUpdateOwner.values();
            updateResults = Database.update(contactListUpdate,false);
            for(Integer i=0;i<updateResults.size();i++)
            {
                 if(!updateResults[i].isSuccess())
                 {
                     for(Database.Error err : updateResults[i].getErrors())
                     {
                           //System.DmlException: Update failed. First exception on row 0; first error: UNABLE_TO_LOCK_ROW, unable to obtain exclusive access to this record or 1 records: 7014p000000JMo4AAG: []
                         if(err.getMessage().contains('UNABLE_TO_LOCK_ROW'))
                         {
                            contactListUpdateAgain.add(contactListUpdate[i]);
                             
                         }
                     }
                 }
            }    
                        
                Database.update(contactListUpdateAgain,false);   
            
        }

        
    }

    public static void stampLawfulBasisOnContactCreate(Map<Id, Contact> newContactMap){

        Set<Id> contactIds = newContactMap.keySet();

        if(contactIds.size() > 0){
            for(Contact contact : [ SELECT  Id,
                                            Associated_Lawful_Basis__c,
                                            Account.Type,
                                            Account.BillingCountryCode,
                                            Account.Status__c
                                    FROM Contact
                                    WHERE Id IN :contactIds]) {
                String lawfulBasis = contact.Associated_Lawful_Basis__c;

                if(HelperClass.euCountryCodes.contains(contact.Account.BillingCountryCode) && (contact.Account.Status__c == 'Existing Customer' || contact.Account.Type == 'Reseller Partner' || contact.Account.Type == 'Referral Partner')) {
                    lawfulBasis = 'Contract';
                } else if(HelperClass.euCountryCodes.contains(contact.Account.BillingCountryCode)) {
                    lawfulBasis = 'Legitimate Interest';
                } else {
                    lawfulBasis = 'Not Applicable';
                }

                if(lawfulBasis != contact.Associated_Lawful_Basis__c) {
                    contact = getLoadedContact(contact);
                    contact.Associated_Lawful_Basis__c = lawfulBasis;
                    contactToUpdateById.put(contact.Id, contact);
                }
            }
        }
    }

    // 7/18/19, Phillip Front - This method updates the Owner At Interaction field for Growth when the owner changes from the pool to another user.
    // Only updates the most recent campaign member, and only if its current Owner At Interaction is null or a pool user.
    // Updates the old text field that was created for some reason to hold the text of the name of the owner at interaction :\
    // Updates the Campaign_Interaction_Date__c to whenever the assignment occurred
    // Updates the Inbound_ADR_Toggle_Status__c with the new owner's toggle status
    public static void updateCampaignFieldsFuture(Map<Id, Contact> oldContactMap, Map<Id, Contact> newContactMap) {

        // Find contacts who changed
        Set<Id> contactIdsWhoseOwnerChangesFromPool = new Set<Id>();
        for(Contact c : newContactMap.values()) {
            Contact oldContact = oldContactMap.get(c.Id);
            if(oldContact.OwnerId != c.OwnerId && oldContact.Owner_Is_Pool_User__c) {
                contactIdsWhoseOwnerChangesFromPool.add(c.Id);
            }
        }
        if (!contactIdsWhoseOwnerChangesFromPool.isEmpty()) {
            updateCampaignFieldsFuture(contactIdsWhoseOwnerChangesFromPool);
        }
    }
    @Future
    @testVisible private static void updateCampaignFieldsFuture(Set<Id> contactIds) {
        List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
            CampaignMember.SObjectType
        };
        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
        List<Contact> contacts = [
                SELECT  Id,
                        OwnerId,
                        Owner_Name__c,
                        Owner_Is_Signed_In__c,
                        Owner_Role__c
                FROM Contact
                WHERE Id IN :contactIds
        ];
        updateCampaignFields(contacts, true);
    }
    public static void updateCampaignFields(Map<Id, Contact> oldContactMap, Map<Id, Contact> newContactMap) {

        // Find contacts who changed
        List<Contact> contactOwnerChangesFromPool = new List<Contact>();
        for (Contact c : newContactMap.values()) {
            Contact oldContact = oldContactMap.get(c.Id);
            if (oldContact.OwnerId != c.OwnerId && oldContact.Owner_Is_Pool_User__c) {
                contactOwnerChangesFromPool.add(c);
            }
        }
        if (!contactOwnerChangesFromPool.isEmpty()) {
            updateCampaignFields(contactOwnerChangesFromPool, false);
        }
    }
    private static void updateCampaignFields(List<Contact> contactOwnerChangesFromPool, Boolean async) {

        List<CampaignMember> cmUpdateList = new List<CampaignMember>();
        List<Database.SaveResult> updateResults = new List<Database.Saveresult>();
        List<CampaignMember> cmToUpdateAgain = new List<CampaignMember>();
        Map<Id, CampaignMember> contactIdToCampaignMember = new Map<Id, CampaignMember>();

        // Map campaign members to the contactIds whose owners changed from the pool
        if (contactOwnerChangesFromPool.size() > 0) {
            List<CampaignMember> cmList = new List<CampaignMember>([
                SELECT  Id,
                        Owner_At_Interaction__c,
                        ContactId,
                        Account__r.RR_Assigned_On__c,
                        Owner_at_Interaction_Lookup__r.RR_Is_Pool_User__c ,
                        Campaign_Interaction_Date__c
            FROM CampaignMember
            WHERE ContactId IN: contactOwnerChangesFromPool
            AND ContactId != NULL
            AND Campaign_Member_Age_Days__c <= 2
            ORDER BY CreatedDate DESC]);
            for(CampaignMember cm: cmList) {
                if(!contactIdToCampaignMember.containsKey(cm.ContactId)) {
                    contactIdToCampaignMember.put(cm.ContactId, cm);
                }
            }
            // Loop through contacts that changed and take the first campaign member from each
            for(Contact c : contactOwnerChangesFromPool) {
                if(contactIdToCampaignMember.containsKey(c.Id)) {
                    CampaignMember cm = contactIdToCampaignMember.get(c.Id);
                    if(cm.Owner_at_Interaction_Lookup__c == NULL || cm.Owner_at_Interaction_Lookup__r.RR_Is_Pool_User__c ) {
                        cm.Owner_at_Interaction_Lookup__c = c.OwnerId;
                        cm.Owner_At_Interaction__c = c.Owner_Name__c;
                        cm.Inbound_ADR_Toggle_Status__c = c.Owner_Is_Signed_In__c;
                        cm.Campaign_Interaction_Date__c = System.Now();
                        cm.Owner_Role_Copy__c = c.Owner_Role__c;

                        if(cm.Account__r.RR_Assigned_On__c == System.TODAY()){
                            cm.Lead_Funnel_Assignment_Date_Time__c = cm.Account__r.RR_Assigned_On__c;
                        }

                        cmUpdateList.add(cm);
                    }
                }
            }
        }
        if(cmUpdateList.size() > 0) {
            //update cmUpdateList;
                        if(System.Label.Contact_Row_Lock =='0') //GTMS - 9613
                        {
                                        DMLWrapper.doUpdate(cmUpdateList);
                            if (async)
                DMLWrapper.publishDML();
                        }
            if(System.Label.Contact_Row_Lock !='0')
                        {
                            
            updateResults = Database.update(cmUpdateList,false);
            for(Integer i=0;i<updateResults.size();i++)
            {
                 if(!updateResults[i].isSuccess())
                 {
                     for(Database.Error err : updateResults[i].getErrors())
                     {
                           //System.DmlException: Update failed. First exception on row 0; first error: UNABLE_TO_LOCK_ROW, unable to obtain exclusive access to this record or 1 records: 7014p000000JMo4AAG: []
                         if(err.getMessage().contains('UNABLE_TO_LOCK_ROW'))
                         {
                            cmToUpdateAgain.add(cmUpdateList[i]);
                             
                         }
                     }
                 }
            }    
                        
                Database.update(cmToUpdateAgain,false);   
                        }
            
        }
    }

    //* May 14th, 2020 Ron Saavedra - (GTMS-51, GTMS-551, GTMS-560): (assignAccount, manuallyUnloadContact, contactUnload) future execution for channel lead assignment (circumvent standard lead assign rules), adjusted assignAccount to automate Channel AE routing, scalable build for unloading contacts regardless of RecordType
    //*GTMS- 8501
    public static void newInboundOrChannel(Map<Id, Contact> newContactMap, Map<Id, Contact> oldContactMap){
        Set<Id> accountIds = new Set<Id>();
        Boolean channel = false;

        for(Contact c: newContactMap.values()){
            if(c.New_Inbound_Lead__c  || c.Channel_Source__c || 
               (c.New_Inbound_Lead__c == false && (c.CreatedById==system.label.RainMakerId))){
               if(c.Channel_Source__c){
                   channel = true;
               }
               accountIds.add(c.AccountId);
            }
        }

        if(accountIds.size() > 0){
            loadStaticAccountsMap(accountIds);
            contactSourceToAccount(newContactMap);

            if(channel){
                assignAccountFuture(newContactMap, oldContactMap, accountIds, true);
            } else if(!customerReferralAssignment){
                assignAccount(newContactMap, oldContactMap, accountIds, false);
            }
        }
    }
    
    //*  March 19th, 2020 Ron Saavedra - (GTMS-564): ContactHelper.contactSourceToAccount adjusted method to run with inputs from newInboundOrChannel method
    public static void contactSourceToAccount(Map<Id, Contact> newContactMap){

        if(staticAccountsMap.size() >0){
            
            for(Contact c: newContactMap.values()){
                if(c.Most_Recent_Source__c <> null){
                    if(staticAccountsMap.containsKey(c.AccountId)){
                        if(accountUpdates.containsKey(c.AccountId)) {
                            accountUpdates.get(c.AccountId).Most_Recent_Source__c = c.Most_Recent_Source__c;
                        } else {
                            Account a = new Account(Id = c.AccountId, Most_Recent_Source__c = c.Most_Recent_Source__c );
                            accountUpdates.put(c.AccountId, a);
                        }
                    }
                }
            }
        }
        // Update called in the trigger handler.
    }

    //* May 14th, 2020 Ron Saavedra - (GTMS-51, GTMS-551, GTMS-560): (assignAccount, manuallyUnloadContact, contactUnload) future execution for channel lead assignment (circumvent standard lead assign rules), adjusted assignAccount to automate Channel AE routing, scalable build for unloading contacts regardless of RecordType
    public static void assignAccountFuture(Map<Id, Contact> newContactMap, Map<Id, Contact> oldContactMap, Set<Id> accountIds, Boolean future){
        String newContactMapSerialized = JSON.serialize(newContactMap);
        String oldContactMapSerialized = JSON.serialize(oldContactMap);
        assignAccountFuture(newContactMapSerialized, oldContactMapSerialized, accountIds, future);
    }
    
    //* May 14th, 2020 Ron Saavedra - (GTMS-51, GTMS-551, GTMS-560): (assignAccount, manuallyUnloadContact, contactUnload) future execution for channel lead assignment (circumvent standard lead assign rules), adjusted assignAccount to automate Channel AE routing, scalable build for unloading contacts regardless of RecordType
    @Future
    public static void assignAccountFuture(String newContactMapSerialized, String oldContactMapSerialized, Set<Id> accountIds, Boolean future){
        Map<Id, Contact> newContactMap = (Map<Id, Contact>)JSON.deserialize(newContactMapSerialized, Map<Id, Contact>.class);
        Map<Id, Contact> oldContactMap = (Map<Id, Contact>)JSON.deserialize(oldContactMapSerialized, Map<Id, Contact>.class);
        assignAccount(newContactMap, oldContactMap, accountIds, future);
    }

    //* Nov 19th, 2020 Ron - (GTMS-1920): (assignAccount, resetFlags) Adjust yoyo hashtag + map for avoiding slacks
    public static void assignAccount(Map<Id, Contact> newContactMap, Map<Id, Contact> oldContactMap, Set<Id> accountIds, Boolean future){

        if(future){
            loadStaticAccountsMap(accountIds);
        }
        //RoundRobinHandler.getPilotObjectDetails(newContactMap);
        for(Contact c: newContactMap.values()){

            if(staticAccountsMap.containsKey(c.AccountId)){
                Account a = staticAccountsMap.get(c.AccountId);
                Contact oldContact;
                if(oldContactMap <> null){
                    oldContact = oldContactMap.get(c.Id);
                }

                Integer daysSinceLastContact = a.Last_Contacted__c <> null ? HelperClass.calculateWorkingDays(a.Last_Contacted__c.date(), System.Today()) : 0;
        // added logic for GTMS-15134 starts here
                if (c.New_Inbound_Lead__c == false && (c.CreatedById==system.label.RainMakerId)  && a.OwnerId==system.label.RainMakerId) {
                    a.OwnerId = system.label.SFDC_Pool_User_ID ;
                    if(accountUpdates.get(a.Id) != null)
                      accountUpdates.get(a.Id).OwnerId = system.label.SFDC_Pool_User_ID;
                    else 
                        accountUpdates.put(a.Id, a);
                } // added logic for GTMS-15134 ends here
                else if( c.New_Inbound_Lead__c == true && daysSinceLastContact >= 14 && (a.Account_Lifetime_ACV__c == 0 
                                                                                    || a.Account_Lifetime_ACV__c == null) && a.Open_Opportunity__c == false
                    && (a.Owner_Role__c.contains('AE2') || a.Owner_Role__c.contains('AE3')) && (a.Owner_Role__c.contains('US') || a.Owner_Role__c.contains('CA')) && !a.Owner_Role__c.contains('CAE') 
                    && a.Most_Recent_Source__c != null && slackCampaignTypes.Yo_Yo_Enabled_Campaign_Sources__c.contains(a.Most_Recent_Source__c)
                    && a.Original_Owner_for_Recycling_Campaign__c == null && a.RecordType.Name == 'Fleet'){

                    /*loadPoolUsers();
                    String oldOwnerId = a.OwnerId;
                    yoyoContactMap.put(c.Id, true);

                    // a.Original_Owner_for_Recycling_Campaign__c  = oldOwnerId;// commented for GTMS-7812
                    a.OwnerId = poolMap.get('Fleet');
                    a.Initiate_Round_Robin__c = true;

                    if(accountUpdates.containsKey(a.Id)){
                        accountUpdates.put(a.Id, a);
                    } else {
                        accountUpdates.put(a.Id, new Account(   Id = a.Id,
                                                                Initiate_Round_Robin__c = true,
                                                                // Original_Owner_for_Recycling_Campaign__c = oldOwnerId, // commented for GTMS-7812
                                                                OwnerId = poolMap.get('Fleet')));
                    }
                    String hashAppend;
                    if(c.Hashtag__c != null){
                        hashAppend = '#projectYOYO_'+String.valueOf(System.Today().month())+String.valueOf(System.Today().day())+String.valueOf(System.Today().year())+c.Hashtag__c;
                    } else{
                        hashAppend = '#projectYOYO_'+String.valueOf(System.Today().month())+String.valueOf(System.Today().day())+String.valueOf(System.Today().year());
                    }

                    if(contactToUpdateById.containsKey(c.Id)){
                        contactToUpdateById.get(c.Id).Hashtag__c = hashAppend;
                    } else{
                        contactToUpdateById.put(c.Id, new Contact (Id = c.Id, Hashtag__c = hashAppend));
                    }*/
                } else{
                    if(c.New_Inbound_Lead__c && a.Is_Owner_Pool_User__c && !a.Initiate_Round_Robin__c && c.Most_Recent_Source__c != 'Customer Referral'){
                        //prevents accounts in existing ownership from being assigned out
                        if(a.RecordType.Name == 'Industrial' && (a.Organization_Size__c == '1000 - 4999' || a.Organization_Size__c == '5000+' || a.BillingCountry == 'United States')){
                            a.Initiate_Round_Robin__c = true;
                            if(accountUpdates.containsKey(a.Id)) {
                                accountUpdates.get(a.Id).Initiate_Round_Robin__c = true;
                            } else {
                                accountUpdates.put(a.Id, new Account(Id = a.Id, Initiate_Round_Robin__c = true));
                            }
                        }
                        else if (a.RecordType.Name != 'Partner') {
                            a.Initiate_Round_Robin__c = true;
                            if(accountUpdates.containsKey(a.Id)) {
                                accountUpdates.get(a.Id).Initiate_Round_Robin__c = true;
                            } else {
                                accountUpdates.put(a.Id, new Account(Id = a.Id, Initiate_Round_Robin__c = true));
                            }
                        }
                    } else {
                        if(c.Channel_Source__c && !a.Initiate_Round_Robin__c) {
                            //prevent channel leads from overwriting existing AE ownership
                            if(a.RecordType.Name == 'Industrial'){
                                if(!a.Owner_Role__c.contains('AE')){
                                    a.Initiate_Round_Robin__c = true;
                                    if(accountUpdates.containsKey(a.Id)) {
                                        accountUpdates.get(a.Id).Initiate_Round_Robin__c = true;
                                    } else {
                                        accountUpdates.put(a.Id, new Account(Id = a.Id, Initiate_Round_Robin__c = true));
                                    }
                                }
                            } else{
                                Integer businessDays = a.Last_Call__c <> null ? HelperClass.calculateWorkingDays(a.Last_Call__c.date(), System.Today()) : 0;

                                String level = a.Owner.Level__c <> null ? a.Owner.Level__c: 'null';
                                
                                Boolean caeRoute =  (a.Is_Owner_Pool_User__c || (a.Owner_Role__c.contains('ADR') && a.Owner.ADR_Segment_Alignment__c <> 'AE 3') ||
                                                    (level.contains('AE 2') && businessDays > 15 && a.Open_Opportunity__c == false) ||
                                                    (level.contains('AE 1') && businessDays > 5 && a.Open_Opportunity__c == false)
                                                    && c.CAE_Routing__c && a.BillingCountry == 'United States') ? true: false;
                                                    
                                if(caeRoute && !a.Initiate_Round_Robin__c){
                                    a.Initiate_Round_Robin__c = true;
                                    a.Most_Recent_Source__c = 'CAE Route';
                                    if(accountUpdates.containsKey(a.Id)) {
                                        accountUpdates.get(a.Id).Initiate_Round_Robin__c = true;
                                        accountUpdates.get(a.Id).Most_Recent_Source__c = 'CAE Route';
                                    } else {
                                        accountUpdates.put(a.Id, new Account(Id = a.Id, Initiate_Round_Robin__c = true, Most_Recent_Source__c = 'CAE Route'));
                                    }
                                } else if (!caeRoute && !a.Initiate_Round_Robin__c && !a.Owner_Role__c.contains('AE')){
                                    a.Initiate_Round_Robin__c = true;
                                    if(accountUpdates.containsKey(a.Id)) {
                                        accountUpdates.get(a.Id).Initiate_Round_Robin__c = true;
                                    } else {
                                        accountUpdates.put(a.Id, new Account(Id = a.Id, Initiate_Round_Robin__c = true));
                                    }
                                }
                            }
                        }
                    }
                }
                
                // custom routing logic
                /*if (RoundRobinHandler.customRoutingMap.get(a.Id)==true) {
                    if (a.LFBN__Assign_Account__c == true || a.LFBN__Assign_Region_Owner__c == true) {
                        a.LFBN__Assign_Account__c = false;
                        a.LFBN__Assign_Region_Owner__c = false;
                        a.Initiate_Round_Robin__c = true;
                        accountUpdates.get(a.Id).LFBN__Assign_Account__c = false;
                        accountUpdates.get(a.Id).LFBN__Assign_Region_Owner__c = false;
                        accountUpdates.get(a.Id).Initiate_Round_Robin__c = true;
                    }
                }*/
            }
            
        }

        if (future) {
            List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
                    Account.SObjectType
            };
            DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
            updateAccountsFuture();
        }
        // Update called in the trigger handler.
    }
    //Method to handle future update of accounts
    public static void updateAccountsFuture() {
        if (!accountUpdates.isEmpty()) {
            List<Account> accounts = new List<Account>();
            List<Database.SaveResult> updateResults = new List<Database.SaveResult>();//GTMS - 9613
            List<Account> accountUpdateAgain = new List<Account>();//GTMS - 9613
            
            accounts.addAll(accountUpdates.values());
            accountUpdates.clear();
            //update accounts;
            if(System.Label.Contact_Row_Lock =='0') //GTMS - 9613
            {
                DMLWrapper.doUpdate(accounts);
                DMLWrapper.publishDML();
            }
            if(System.Label.Contact_Row_Lock !='0' || Test.isRunningTest())
            {
                updateResults = Database.update(accounts,false);
                
                for(Integer i=0;i<updateResults.size();i++)
                {
                    if(!updateResults[i].isSuccess())
                    {
                        for(Database.Error err : updateResults[i].getErrors())
                        {
                            //System.DmlException: Update failed. First exception on row 0; first error: UNABLE_TO_LOCK_ROW, unable to obtain exclusive access to this record
                            if(err.getMessage().contains('UNABLE_TO_LOCK_ROW'))
                            {
                                accountUpdateAgain.add(accounts[i]);
                                
                            }
                        }
                    }
                }    
                Database.update(accountUpdateAgain,false); 
            }
        }
    }
    
    public static void updateAccounts() {
        if (!accountUpdates.isEmpty()) {
            List<Account> accounts = new List<Account>();
            List<Database.SaveResult> updateResults = new List<Database.SaveResult>();
            List<Account> accountUpdateAgain = new List<Account>();
            accounts.addAll(accountUpdates.values());
            accountUpdates.clear();
            //update accounts;
            if(System.Label.Contact_Row_Lock =='0') //GTMS - 9613
            {
                DMLWrapper.doUpdate(accounts);
                //DMLWrapper.publishDML();
            }
            if(System.Label.Contact_Row_Lock !='0')
            {
                
                updateResults = Database.update(accounts,false);
                
                for(Integer i=0;i<updateResults.size();i++)
                {
                    if(!updateResults[i].isSuccess())
                    {
                        for(Database.Error err : updateResults[i].getErrors())
                        {
                            //System.DmlException: Update failed. First exception on row 0; first error: UNABLE_TO_LOCK_ROW, unable to obtain exclusive access to this record
                            if(err.getMessage().contains('UNABLE_TO_LOCK_ROW'))
                            {
                                accountUpdateAgain.add(accounts[i]);
                                
                            }
                        }
                    }
                }    
                Database.update(accountUpdateAgain,false);     
            }
        }
    }

    public static Contact getLoadedContact(Contact c) {
        if (contactToUpdateById.containsKey(c.Id)) {
            return contactToUpdateById.get(c.Id);
        }
        return c;
    }

    public static void updateContacts() {
        if (!contactToUpdateById.isEmpty()) {
            List<Contact> cs = new List<Contact>();
            List<Database.SaveResult> updateResults = new List<Database.SaveResult>();
            List<Contact> contactUpdateAgain = new List<Contact>();
            cs.addAll(contactToUpdateById.values());
            contactToUpdateById.clear();
            //System.debug('** contacts to update count: ' + cs.size());
            //update cs;
            if(System.Label.Contact_Row_Lock =='0') //GTMS - 9613
            {
                DMLWrapper.doUpdate(cs);    
            }
            if(System.Label.Contact_Row_Lock !='0')
            {
                
                updateResults = Database.update(cs,false);
                
                for(Integer i=0;i<updateResults.size();i++)
                {
                    if(!updateResults[i].isSuccess())
                    {
                        for(Database.Error err : updateResults[i].getErrors())
                        {
                            //System.DmlException: Update failed. First exception on row 0; first error: UNABLE_TO_LOCK_ROW, unable to obtain exclusive access to this record or 1 records: 7014p000000JMo4AAG: []
                            if(err.getMessage().contains('UNABLE_TO_LOCK_ROW'))
                            {
                                contactUpdateAgain.add(cs[i]);
                                
                            }
                        }
                    }
                }    
                Database.update(contactUpdateAgain,false); 
                
            }
        }
    }

    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * GTMS-2415
    */
    public static void workflowConversionProcess(List<Contact> contactList, Map<Id, Contact> OldContactMap) {
        ContactHelper contactHelper = new ContactHelper();
        contactHelper.processWorkflows(contactList, OldContactMap);
    }

    private void processWorkflows(List<Contact> contactList, Map<Id, Contact> OldContactMap) {
        if (OldContactMap == null) {
            for (Contact thisContact : contactList) {
                if (wfCampaignToAddCondition(thisContact)) {
                    if (!contactToUpdateById.containsKey(thisContact.Id)) {
                        contactToUpdateById.put(thisContact.Id, thisContact.clone(true));
                    }

                    ContactWorkFlowConversion.processCampaignToAdd(contactToUpdateById.get(thisContact.Id));
                }
            }
        } else {
            for (Contact thisContact : contactList) {
                if (wfCampaignToAddPreCheck(thisContact, OldContactMap.get(thisContact.Id))) {
                    if (!contactToUpdateById.containsKey(thisContact.Id)) {
                        contactToUpdateById.put(thisContact.Id, thisContact.clone(true));
                    }

                    ContactWorkFlowConversion.processCampaignToAdd(contactToUpdateById.get(thisContact.Id));
                }
            }
        }

    }

    private Boolean wfCampaignToAddPreCheck(Contact newContact, Contact oldContact) {
        return (wfCampaignToAddCondition(newContact));
    }

    private Boolean wfCampaignToAddCondition(Contact thisContact) {
        return (thisContact.Campaign_to_Add__c != null);
    }


    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-09-09
    * Not yet deployed for Production
    * GTMS-1471
    */
    public static void calculateAllRollUpsToAccount(List<Contact> contactList, Map<Id, Contact> OldContactMap) {
        mapOFRollupFieldVsMetadata = RollUpSwitchService.getRollupSwitchMetadata('Account', 'Contact');
        ContactHelper contacatHelpr = new ContactHelper();
        contacatHelpr.loadContactTargetRollupAccountSet(contactList, OldContactMap);
         contacatHelpr.loadTargetContacts();
         contacatHelpr.calculateAllRollUpsToAccount();
 
    }

    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-09-08
    * Not yet deployed for Production
    * GTMS-1471
    */
    private  void  calculateAllRollUpsToAccount()
    {
        Map<string, Map<String,List<Contact>>> mapOfRollupFiledVsRecordList = new   Map<string, Map<String,List<Contact>>> ();

        Map<String,List<Contact>> mapOfAccountIdVsContactList = new Map<String,List<Contact>>();

        for(String accountId : targetRollupAccountSet)
        {
            if(! mapOfAccountIdVsContactList.ContainsKey(accountId)) mapOfAccountIdVsContactList.put(accountId, new List<Contact>());

        }
        for (String rollUpField : mapOFRollupFieldVsMetadata.KeySet())
        {

            if(!mapOfRollupFiledVsRecordList.containsKey(rollUpField))
                mapOfRollupFiledVsRecordList.put(rollUpField, mapOfAccountIdVsContactList);
        }

        for(integer i = 0 ; i < targetContacts.size() ; i++ )
        {
            for(String rollUpField : mapOFRollupFieldVsMetadata.KeySet())
            {
                Callable callInstance = (Callable)Type.forName('ContactHelper').newInstance();


                if((Boolean)callInstance.call(rollUpField, new map<String,Object>{'newRecord' => targetContacts[i]}))
                {
                    if(! mapOfRollupFiledVsRecordList.ContainsKey(rollUpField)) mapOfRollupFiledVsRecordList.put(rollUpField, new Map<String,List<Contact>>());

                    if(!mapOfRollupFiledVsRecordList.get(rollUpField).containsKey(targetContacts[i].AccountId))
                        mapOfRollupFiledVsRecordList.get(rollUpField).put(targetContacts[i].AccountId, new List<Contact>());

                    mapOfRollupFiledVsRecordList.get(rollUpField).get(targetContacts[i].AccountId).add(targetContacts[i]);

                }
            }

        }

        for (String rollupField : mapOfRollupFiledVsRecordList.keySet()) {
            if (!mapOfRollupFiledVsRecordList.containsKey(rollupField)) {
                continue;
            }
            for(String accountId : mapOfRollupFiledVsRecordList.get(rollupField).keySet())
            {
                if(!accountUpdates.ContainsKey(accountId))
                {
                    accountUpdates.put(accountId, new Account(Id = accountId));
                }

                if (mapOfRollupFiledVsRecordList.get(rollupField).get(accountId).isEmpty()) {
                    accountUpdates.get(accountId).put(rollupField, null);
                    continue;
                }

                //Todo handling the count first last and average using Callable
                Callable callInstance = (Callable) Type.forName('ContactHelper').newInstance();
                if (mapOFRollupFieldVsMetadata.get(rollupField).Type__c == 'SUM') {
                    object result = callInstance.call('SUM', new map<String, Object>{
                            'recordList' => mapOfRollupFiledVsRecordList.get(rollupField).get(accountId), 'field' => mapOFRollupFieldVsMetadata.get(rollupField).Rollup_Field__c
                    });
                    if (result != null)
                        accountUpdates.get(accountId).put(rollupField, (Decimal) result);
                } /*else if (mapOFRollupFieldVsMetadata.get(rollupField).Type__c == 'FIRST') {
                    Contact firstContact = new Contact();
                    object result = callInstance.call('FIRST', new map<String, Object>{
                            'recordList' => mapOfRollupFiledVsRecordList.get(rollupField).get(accountId), 'field' => mapOFRollupFieldVsMetadata.get(rollupField).Rollup_Field__c
                    });
                    if (result == null) continue;
                    firstContact = (Contact) result;
                    if(firstContact == null ) continue;
                    accountUpdates.get(accountId).put(rollupField, firstContact.Id);
                }*/ else if (mapOFRollupFieldVsMetadata.get(rollupField).Type__c == 'LAST') {
                    Contact lastContact = new Contact();
                    object result = callInstance.call('LAST', new map<String, Object>{
                            'recordList' => mapOfRollupFiledVsRecordList.get(rollupField).get(accountId), 'field' => mapOFRollupFieldVsMetadata.get(rollupField).Rollup_Field__c
                    });
                    if (result == null) continue;
                    lastContact = (Contact) result;
                    if (lastContact == null) continue;
                    if (rollupField == 'Last_Call__c') {
                        accountUpdates.get(accountId).put(rollupField, lastContact.Last_Call__c);
                        continue;
                    }
                    if (rollupField == 'Last_Marketing_Engagement_Date__c') {
                        accountUpdates.get(accountId).put(rollupField, lastContact.Last_Marketing_Engagement_Date__c);
                        continue;
                    }
                    accountUpdates.get(accountId).put(rollupField, lastContact.Id);
                }
            }
        }


    }

    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-09-09
    * Not yet deployed for Production
    * GTMS-1471
    */
    public  void loadContactTargetRollupAccountSet(List<Contact> contactList, Map<Id,Contact> OldContactMap)
    {
        if(OldContactMap == null)
        {
            Callable callInstance = (Callable)Type.forName('ContactHelper').newInstance();
            for(integer i = 0 ; i < contactList.size() ; i++) {

                for (String rollUpField : mapOFRollupFieldVsMetadata.KeySet()) {
                    Object result = callInstance.call(rollUpField, new map<String, Object>{
                            'newRecord' => contactList[i]
                    });
                    if (result == null) continue;
                    if ((Boolean) result) {
                        if (contactList[i].AccountId != null)
                            targetRollupAccountSet.add(contactList[i].AccountId);
                        break;
                    }
                }
            }
        }
        else
        {
            for(integer i = 0 ; i < contactList.size() ; i++)
            {
                
                for(String rollUpField : mapOFRollupFieldVsMetadata.KeySet())
                {
                    if(accountReparenting(contactList[i], OldContactMap.get(contactList[i].id)))
                    {
                        if(OldContactMap.get(contactList[i].id).AccountId != null)
                        targetRollupAccountSet.add(OldContactMap.get(contactList[i].id).AccountId);
                        if(contactList[i].AccountId != null)
                        targetRollupAccountSet.add(contactList[i].AccountId);
                    }
                    else {
                        Callable callInstance = (Callable) Type.forName('ContactHelper').newInstance();

                        object result = callInstance.call(rollUpField + 'PreCheck', new map<String, Object>{
                                'newRecord' => contactList[i], 'oldRecord' => OldContactMap.get(contactList[i].id)
                        });
                        if (result == null) continue;

                        if ((Boolean) result) {
                            if (contactList[i].AccountId != null)
                            targetRollupAccountSet.add(contactList[i].AccountId);
                            break;
                        }
                    }
                    
                }
            }

        }
    }

    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-09-09
    * Not yet deployed for Production
    * GTMS-1471
    */
    public Object call(String action, Map<String, Object> args)
    {
        switch on action {
            when 'Active_Growth_Campaigns_on_Account__c' {
                return this.rollup_Active_Growth_Campaigns_CountCondition((Contact) args.get('newRecord'));
            }
            when 'Last_Call__c' {
                return this.Last_CallCondition((Contact) args.get('newRecord'));
            }
            when 'Last_Marketing_Engagement_Date__c' {
                return this.Last_Marketing_Engagement_DateCondition((Contact) args.get('newRecord'));
            }
            when 'Active_Growth_Campaigns_on_Account__cPreCheck' {
                return this.rollup_Active_Growth_Campaigns_CountPreCheck((Contact) args.get('newRecord'), (Contact) args.get('oldRecord'));
            }
            when 'Last_Call__cPreCheck' {
                return this.Last_CallPreCheck((Contact) args.get('newRecord'), (Contact) args.get('oldRecord'));
            }
            when 'Last_Marketing_Engagement_Date__cPreCheck' {
                return this.Last_Marketing_Engagement_DatePreCheck((Contact) args.get('newRecord'), (Contact) args.get('oldRecord'));
            }
            when 'SUM' {
                return this.Sum((List<Sobject>) args.get('recordList'), (String) args.get('field'));
            }
            when 'LAST' {
                return this.last((List<Sobject>) args.get('recordList'), (String) args.get('field'));
            }
            /* when 'FIRST'
            {
                return this.first((List<Sobject>)args.get('recordList'), (String)args.get('field'));
            } */
          when else
          {
           System.debug('Method not implemented');
           return null;
          }
        }
    }
    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-09-09
    * Not yet deployed for Production
    * GTMS-1471
    */
    public Boolean rollup_Active_Growth_Campaigns_CountPreCheck (Contact thisContact, Contact oldContact) {
        return (thisContact.Active_Growth_Campaigns_Count__c != oldContact.Active_Growth_Campaigns_Count__c
                && (rollup_Active_Growth_Campaigns_CountCondition(thisContact) || rollup_Active_Growth_Campaigns_CountCondition(oldContact)));
    }

    public boolean Last_CallPreCheck(Contact thisContact, Contact oldContact) {
        return (thisContact.Last_Call__c != oldContact.Last_Call__c) && (Last_CallCondition(thisContact) || Last_CallCondition(oldContact));
    }

    public Boolean Last_Marketing_Engagement_DatePreCheck(Contact thisContact, Contact oldContact) {
        return (thisContact.Last_Marketing_Engagement_Date__c != oldContact.Last_Marketing_Engagement_Date__c)
                && (Last_Marketing_Engagement_DateCondition(thisContact) || Last_Marketing_Engagement_DateCondition(oldContact));
    }

    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-09-09
    * Not yet deployed for Production
    * GTMS-1471
    */
    public Boolean rollup_Active_Growth_Campaigns_CountCondition(Contact thisContact) {
        return (thisContact.Active_Growth_Campaigns_Count__c > 0);
    }

    public boolean Last_CallCondition(Contact thisContact) {
        return thisContact.Last_Call__c != null;
    }

    public Boolean Last_Marketing_Engagement_DateCondition(Contact thisContact) {
        return thisContact.Last_Marketing_Engagement_Date__c != null;
    }

    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-09-09
    * Not yet deployed for Production
    * GTMS-1471
    */
    public void loadTargetContacts() {
        targetContacts = [
                SELECT Id, AccountId,
                        Active_Growth_Campaigns_Count__c,
                        Last_Call__c,Last_Marketing_Engagement_Date__c
                            FROM Contact
                            WHERE AccountId IN :targetRollupAccountSet];
    }

    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-09-09
    * Not yet deployed for Production
    * GTMS-1471
    */
    private Boolean accountReparenting (Contact thisRecord, Contact oldrecord)
    {
        return (thisRecord.AccountId != oldrecord.AccountId);
    }
    
    /**
    * @author Groundswell - Vikasm - vikas@gscloudsolutions.com
    * @date 2020-09-09
    * Not yet deployed for Production
    * GTMS-1471
    */
    private Decimal Sum (List<Sobject>recordList, String field)
    {
    return RollupService.Sum(recordList, field);
    }
    
    /* private Sobject first (List<Sobject>recordList, String field)
    {
        return RollupService.first(recordList, field);
    } */

    private Sobject last (List<Sobject>recordList, String field)
    {
        return RollupService.last(recordList, field);
    }
    /**
    * @author - Nishita Dhar
    * @date 2023-07-03
    * GTMS-13696
    */
    public static void populateFuncLevel(List<Contact> newContactList,Map<Id, Contact> OldContactMap) {
        Map<String, Contact_Normalized_Title__c> normfunc = Contact_Normalized_Title__c.getAll();
        
        for (Contact contact : newContactList) {
            if (OldContactMap!=null && contact.Normalized_Title__c != OldContactMap.get(contact.Id).Normalized_Title__c ) {
                if(contact.Normalized_Title__c != null){
                List<String> normalizedTitle = contact.Normalized_Title__c.toLowerCase().split(',');
                System.debug(normalizedTitle);
                
                if (contact!= null && normalizedTitle != null) {
                    for(String st: normalizedTitle){
                        System.debug('string-->' + st);
                        // Function logic commented as part of GTMS-29135 after the confirmation with Elli Stavrou
                        /*if(normfunc.get('Function').Operations__c.split(',').contains(st)){
                            Contact.Function__c = 'Operations';
                            System.debug('string-->' + st);
                        }
                        else if((normfunc.get('Function').Fleet__c.split(',').contains(st))){
                            Contact.Function__c = 'Fleet';
                        }
                        else if((normfunc.get('Function').Warehouse__c.split(',').contains(st))){
                            Contact.Function__c = 'Warehouse';
                        }
                        else if((normfunc.get('Function').Safety__c.split(',').contains(st))){
                            Contact.Function__c = 'Safety';
                        }
                        else if((normfunc.get('Function').Logistics__c.split(',').contains(st))){
                            Contact.Function__c = 'Logistics';
                        }
                        else if((normfunc.get('Function').Public_Works__c.split(',').contains(st))){
                            Contact.Function__c = 'Public Works';
                        }
                        else if((normfunc.get('Function').IT__c.split(',').contains(st))){
                            Contact.Function__c = 'IT';
                        }
                        else if((normfunc.get('Function').Compliance__c.split(',').contains(st))){
                            Contact.Function__c = 'Compliance';
                        }
                        else if((normfunc.get('Function').Administration__c.split(',').contains(st))){
                            Contact.Function__c = 'Administration';
                        }
                        else if((normfunc.get('Function').Finance__c.split(',').contains(st))){
                            Contact.Function__c = 'Finance';
                        }
                        else if((normfunc.get('Function').Sales_Marketing__c.split(',').contains(st))){
                            Contact.Function__c = 'Sales & Marketing';
                        }*/
                        if(normfunc.get('Level').Manager__c.split(',').contains(st)){
                            Contact.Level__c = 'Manager';
                        }
                        else if(normfunc.get('Level').IC__c.split(',').contains(st)){
                            Contact.Level__c = 'IC';
                        }
                        else if(normfunc.get('Level').Associate__c.split(',').contains(st)){
                            Contact.Level__c = 'Associate';
                        }
                        else if(normfunc.get('Level').Director__c.split(',').contains(st)){
                            Contact.Level__c = 'Director';
                        }
                        else if(normfunc.get('Level').VP__c.split(',').contains(st)){
                            Contact.Level__c = 'VP';
                        }
                        else if(normfunc.get('Level').Executive__c.split(',').contains(st)){
                            Contact.Level__c = 'Executive';
                        }
                    }
                }
            }
                else{
                    contact.Level__c = '';
                    //contact.Function__c = '';
                }
            }
        }
        
    }
    // Added as part of GTMS-25352 Start here
    public static void setAccountStatusFromContactInbound(Map<Id, Contact> oldContactMap, Map<Id, Contact> newContactMap) {
        Set<Id> accountIds = new Set<Id>();
        for (Contact c: newContactMap.values()) {
            if (oldContactMap.get(c.Id).Inbound_Reason_Faulty__c != newContactMap.get(c.Id).Inbound_Reason_Faulty__c &&
                newContactMap.get(c.Id).Inbound_Reason_Faulty__c == 'Delete Account'){
                    if(c.AccountId!=null){
                        accountIds.add(c.AccountId);
                    }
                }
            
        }
        if (!accountIds.isEmpty()) {
            List<Account> accList = new List<Account>();
            for (Id accId : accountIds) {
                Account acc = new Account();
                acc.Id = accId;
                acc.status__c = 'Delete';
                accList.add(acc);
            }
            update accList;
        }
    }
    //END here
    public static void populateAdrAssignment(List<Contact> newContacts) {
        Set<Id> accountIds = new Set<Id>();
        for (Contact c : newContacts) {
            if (c.AccountId != null) {
                accountIds.add(c.AccountId);
            }
        }
        Map<Id, Account> accounts = new Map<Id, Account>(
            [SELECT Id, AdrAssignment__c FROM Account WHERE Id IN :accountIds]
        );
        for (Contact c : newContacts) {
            if (c.AccountId != null && accounts.containsKey(c.AccountId)) {
                c.Adr_Assignment__c = accounts.get(c.AccountId).AdrAssignment__c;
            }
        }
    }
    //This method added based GTMS-29989
	//GTMS-29989 START
	public static void updateOptoutFields(List<Contact> newRecords, Map<Id, Contact> oldRecordsMap) {
    for (Contact newContact : newRecords) {
        Contact oldContact = oldRecordsMap.get(newContact.Id);
        if (oldContact == null || oldContact.Remove_From_Engage_Flow__c != newContact.Remove_From_Engage_Flow__c) continue;
        Boolean optOutChanged = newContact.HasOptedOutOfEmail != oldContact.HasOptedOutOfEmail ||
                                newContact.Sales_Email_Opt_Out__c != oldContact.Sales_Email_Opt_Out__c;
        Boolean isCurrentlyOptedOut = (newContact.HasOptedOutOfEmail || newContact.Sales_Email_Opt_Out__c);
        Boolean isInFlow = (newContact.Gong__Flow_Status__c == 'In Progress');
        
        if (optOutChanged && isCurrentlyOptedOut && isInFlow && !newContact.Remove_From_Engage_Flow__c) {
            newContact.Remove_From_Engage_Flow__c = true;
        }
    }
}
    //GTMS-29989 END
}
/**
* Created by vikasmishra on 2021-06-17.
* * 05/15/2024 Rodrigo Carpio (GTMS-21034) - add field in LeadSelectorm variable tempDomain and condition to handle logic
*/

public inherited sharing class UserProvisioningService implements IService {
    
    public static final String DEFAULT_USER_TIMEZONE_SIDKEY = 'America/New_York';
    public static final String DEFAULT_USER_LANGUAGE_LOCALE_KEY = 'en_US';
    public static final String DEFAULT_USER_EMAIL_ENCODINGKEY = 'UTF-8';
    public static final String DEFAULT_USER_LOCALE_SIDKEY = 'en_US';
    
    public List<User> userInsertList = new List<User>();
    @TestVisible
    private String defaultProfile ;
    
    @TestVisible
    static IDMLHelper thisUserDMLHelper = new UserDmlHelper();
    @TestVisible
    static ISelector thisLeadSelector = new LeadSelector();
    
    public List<User> doProvisionFromLeadIds(Set<Id> ids){
        return this.doProvisionFromLeads(thisLeadSelector.getLeadsByIds(ids));
    }

    public void setDefaultProfile( Id thisProfileId){
        this.defaultProfile = thisProfileId;
    }
    //Public in order to do the one time user provisioning via script
    public List<User> doProvisionFromLeads (List<Lead> leadList) {
            
        for(Lead thisLead : leadList)
        {
            string emailStr = thisLead.Email;//rodrigo.carpio@samsara.com';
            string tempDomain = String.isNotBlank(emailStr)? emailStr.mid(emailStr.indexOf('@')+1, emailStr.length()-emailStr.indexOf('@')):null;
            if(String.isNotBlank(tempDomain) && String.isNotBlank(thisLead.Email) && (tempDomain== thisLead.Account__r.Domain_Name__c  || 
				(tempDomain != thisLead.Account__r.Domain_Name__c && thisLead.Approved_and_Provision_User_Initiated__c))) { // condition added for GTMS-21034
            
                User thisUser = new User();
                thisUser.FirstName = thisLead.FirstName;
                thisUser.LastName = thisLead.LastName;
                thisUser.Username = thisLead.Email;
                thisUser.Email = thisLead.Email;
                thisUser.ContactId = thisLead.ConvertedContactId;
                thisUser.EmailEncodingKey = DEFAULT_USER_EMAIL_ENCODINGKEY;
                thisUser.LocaleSidKey = DEFAULT_USER_LOCALE_SIDKEY;
                thisUser.TimeZoneSidKey = DEFAULT_USER_TIMEZONE_SIDKEY ;
                thisUser.LanguageLocaleKey = DEFAULT_USER_LANGUAGE_LOCALE_KEY ;
                thisUser.ProfileId = this.defaultProfile;
                thisUser.Alias = thisLead.LastName.left(8);
                //thisUser.UserRoleId = DEFAULT_ROLE_ID;
                thisUser.CommunityNickname = assignUniqueNickName(thisUser);
                userInsertList.add(thisUser);
            }
              // GTMS-21034 added logic to send Contact to Approval if Lead Email Domain name mismatch with Account Domain Name
            else{
                // Get the Contact record you want to submit for approval
                if(String.isNotBlank(thisLead.ConvertedContactId) && String.isNotBlank(thisLead.Account__c)){
               
              Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                    req.setComments('Submitting contact for approval.');
                    req.setObjectId(thisLead.ConvertedContactId); // Set the ID of the Contact record
                    // Specify the API name of the approval process you want to use
                    req.setProcessDefinitionNameOrId('Contact_User_Creation_Process');
                    req.setSkipEntryCriteria(true);
                    // Submit the Contact for approval
              Approval.ProcessResult result = Approval.process(req);
                
                // Check if the Contact was submitted successfully for approval
                if(result.isSuccess()) {
                    System.debug('Contact submitted successfully for approval.');
                } else {
                    System.debug('Failed to submit Contact for approval: ' + result.getErrors()[0].getMessage());
                }
                
            } 
            }
        }
        
        return userInsertList;
        
    }
    //8/6/24 Vijaychandra --START-- (GTMS--22483): Added below code code as part of Partner Application H2 project
    /******************************
     * @Description: This method will fetch the contact data based on the contact Ids
     * @param : ids --> partnerContactIds.
     * @return : userList --> List of Users to be inserted.
     */
    public List<User> doProvisionFromContactIds(Set<Id> ids){
        return this.doProvisionFromContacts(thisLeadSelector.getContactByIds(ids));
    }

    /******************************
     * @Description: This method will  create a Partner User from contact when PAM approves the PR record
     * @param : contactList --> partnerContact from Partner Registration record.
     * @return : userList --> List of Users to be inserted.
     */
    public List<User> doProvisionFromContacts (List<Contact> contactList) {
        for(Contact thiscon : contactList)
        {
            User thisUser = new User();
            thisUser.FirstName = thiscon.FirstName;
            thisUser.LastName = thiscon.LastName;
            thisUser.Username = thiscon.Email;
            thisUser.Email = thiscon.Email;
            thisUser.ContactId = thiscon.Id;
            thisUser.EmailEncodingKey = DEFAULT_USER_EMAIL_ENCODINGKEY;
            thisUser.LocaleSidKey = DEFAULT_USER_LOCALE_SIDKEY;
            thisUser.TimeZoneSidKey = DEFAULT_USER_TIMEZONE_SIDKEY ;
            thisUser.LanguageLocaleKey = DEFAULT_USER_LANGUAGE_LOCALE_KEY ;
            thisUser.ProfileId = this.defaultProfile;
            thisUser.Alias = thiscon.LastName.left(8);
            //thisUser.UserRoleId = DEFAULT_ROLE_ID;
            thisUser.CommunityNickname = assignUniqueNickName(thisUser);
            userInsertList.add(thisUser);
        }

        return userInsertList;
    }
    /******************************
     * @Description: This method will  update the existing Partner Users to Active if they are Inactive
     * @param : userIds --> user Id related to PR Record.
     */
    @InvocableMethod(label='Activate Partner User' description='Patner User Creation')
    public static void activateExistingUser(List<Id> userIds){
        if(!userIds.isEmpty()){
            activateExistingUserFuture(userIds);
        } 
    }
    @future
    public static void activateExistingUserFuture(List<Id> userIds){
        Database.SaveResult[] result = thisUserDMLHelper.updateUsers(new List<User>{new User(Id=userIds[0],isActive=true)},true);
    }
    //8/6/24 Vijaychandra --START-- (GTMS--22483): Added below code code as part of Partner Application H2 project


    public Database.SaveResult[] insertUsers(List<User>users){
        
        return thisUserDMLHelper.insertUsers(users, true);
        //insert users;
        //return null;
    }
    //DEV:Zakeer-->Nov-11-2021: added a new method to Pass FALSE parameter when processing PartnerUsers in LeadConversionRestResourceHelperClass.
    public Database.SaveResult[] insertUsers(List<User>users, Boolean allOrNone){
        return thisUserDMLHelper.insertUsers(users, allOrNone);
    }
    
    public  void assignPermissionSet (Database.SaveResult[] saveResults, String permissionSetName) {
        List<Id> userIds = new List<Id>();
        for(Integer i=0;i<saveResults.size();i++){
            if (saveResults.get(i).isSuccess()){
                userIds.add( saveResults.get(i).getId());
            }
            else if (!saveResults.get(i).isSuccess()){
                // DML operation failed
                Database.Error error = saveResults.get(i).getErrors().get(0);
                String failedDML = error.getMessage();
            }
            
        }
        PermissionSetAssignmentService.asyncAssignPermissionSetByName(userIds, permissionSetName);
        
    }
    
    
    @TestVisible
    private  String assignUniqueNickName (User thisUser ) {
        
        String key = thisUser.FirstName+thisUser.LastName+ GenerateGUID.generateUtil()[0];
        return key.left(36);
    }
    
    public inherited sharing class LeadSelector implements ISelector{
        public List<Lead> getLeadsByIds (Set<Id> ids){
            return [SELECT Id,
                    RecordTypeId,
                    FirstName,
                    LastName,
                    Email,
                    Approved_and_Provision_User_Initiated__c,
                    ConvertedContactId,
                    Account__c,
                    Account__r.Domain_Name__c
                    FROM Lead
                    WHERE Id IN : ids];
        }
        
        public list<Contact> getContactByIds(Set<Id> conIds){
            return [SELECT Id,
                    FirstName,
                    LastName,
                    Email,
                    AccountId,
                    Account.Domain_Name__c
                    FROM Contact
                   	WHERE Id IN : conIds];
        }
    }
    
    public inherited sharing class UserDmlHelper implements IDMLHelper{
        
        public Database.SaveResult[] insertUsers(List<User> userList, Boolean allOrNothing) {
            return Database.insert(userList, allOrNothing);
        }

        public Database.SaveResult[] updateUsers(List<User> userList, Boolean allOrNothing){
            return Database.update(userList,allOrNothing);
        }
        
        
    }
    
    public interface ISelector{
        List<Lead> getLeadsByIds (Set<Id> ids);
        List<Contact> getContactByIds (Set<Id> ids);
    }
    
    public interface IService{
        List<User> doProvisionFromLeadIds(Set<Id> ids);
        List<User> doProvisionFromContactIds(Set<Id> ids);
        List<User> doProvisionFromLeads (List<Lead> leadList);
        List<User> doProvisionFromContacts (List<Contact> contactList);
        void setDefaultProfile(Id thisProfileId);
        Database.SaveResult[] insertUsers(List<User> users);
        //Zak-SPP-147
        Database.SaveResult[] insertUsers(List<User> users, Boolean allOrNone);
        void assignPermissionSet (Database.SaveResult[] saveResults, String permissionSetName);
    }
    public interface IDMLHelper {
        Database.SaveResult[] insertUsers(List<User> users, Boolean allOrNothing);
        Database.SaveResult[] updateUsers(List<User> users, Boolean allOrNothing);
    }
    
}
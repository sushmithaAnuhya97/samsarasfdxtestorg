/**
 * Created by vikasmishra on 2021-06-21.
 */

/**
 * @description :This class is used as helper for the rest resource
 * used by NOTRE DAME for Lead Conversion
 * Responsible for Lead conversion
 * Enable account as partner account Partner
 * Do user provisioning for the Partner application
 * Only first user will be assigned with Login admin license
 * 
 * MODIFICATION History:
 1) * DEV: Zakeer
    * Date: Nov-11-2021
    * Purpose: added logic to append suffix to PartnerUsers when the DUPLICATE_Username error is occured while inserting.
    * Line#: doProcessUserProvisioning() --> 131-154
 2) Please ADD COMMENTS in future.
 */
public inherited sharing class LeadConversionRestResourceHelper implements IHelper{
    @TestVisible
    static LeadConversionService.IService thisLCService = new LeadConversionService();
    @TestVisible
    static ILCService thisInternalLCService = new convertLeadFromPayload();
    @TestVisible
    static UserProvisioningService.IService thisUserProvisioningService = new UserProvisioningService();
    @TestVisible
    static IDMLHelper accountDMLHelper = new AccountDMLHelper();
    @TestVisible
    static IPAService thisPAService = new PartnerAccountService();
    @TestVisible
    static IDRService thisDRService = new DealRegistrationService();
    @TestVisible
    static ISelector thisProfileSelector = new ProfileSelector();

    public static String LEAD_STATUS_TO_UPDATE = 'Application Approved';
    public static final String PAYLOAD_SUCCESS_STATUS = 'success';
    public static final String ADMIN_PORTAL_PROFILE_NAME = 'Samsara Partner Community Login License Admin';
    public static final String USER_PORTAL_PROFILE_NAME = 'Samsara Partner Community Login License User';
    public static boolean Is_Super_User = false;
    public static final Set<Id> recordTypeToProcessUserProvisioning = new Set<Id>{
            LeadConversionService.getRecordTypeId(
                    'Lead',
                    'Partner_Application'
            )
    };
    public static final Set<Id> recordTypeToProcessDealReg = new Set<Id>{
            LeadConversionService.getRecordTypeId(
                    'Lead',
                    'Channel_Registration'
            )
    };
        
    String payload;
    Savepoint initialSavePoint = Database.setSavepoint();
    List<Lead> errorRecords = new List<Lead>();

    /**
     * @description Constructor
     */
    public LeadConversionRestResourceHelper (){

    }

    /**
     *  @param payloadJson : payload received from NOTRE DAME
     * @return : LeadConversionRestResourceHelper returns this instance for the class
     * @description : This method set the payload String from the rest resource
     */
    public LeadConversionRestResourceHelper setPayLoadString(String payloadJson){
        this.payload = payloadJson;
        return this;
    }

    /**
     * @return : LeadConversionRestResourceHelper returns this instance for the class
     * @description This method parse the payload and and calls the Internal Conversion Service
     * Payload.parse(String JSON) used to deserialize the payload in Internal Payload class
     */
    public LeadConversionRestResourceHelper processPayloadForConversion (){
       System.debug('this.payload****'+ this.payload);
        thisInternalLCService.setLeadSFromPayload(
                new Payload()
                        .parse(
                        this.payload
                )
        ).doConversion();
        errorRecords.addAll(thisInternalLCService.getLeadsWithErrors());
        
        return this;
    }
    
    public LeadConversionRestResourceHelper processLeadConversionError (){ // added for GTMS-31636
        if (errorRecords.size()>0) {
            FOR (Lead errLead: errorRecords) {
                Logger.atError()
                    .setClassName('LeadConversionRestResourceHelper')
                    .setMethod('processLeadConversionError')
                    .setRecordId(errLead.Id)
                    .setExceptionOrMessage('FAILED Lead Conversion - ' + errLead.Conversion_Error_Message_tal__c);
                
            }
            thisLCService.rollbackChanges(errorRecords);
        }
        return this;
    }

    /**
     * @return : LeadConversionRestResourceHelper returns this instance for the class
     * @description This method will call Deal registration service
     */
    public LeadConversionRestResourceHelper processDealRegistration(){
        thisDRService.createOppsForDealRegLeads(thisInternalLCService.getSuccessFullyConvertedLead());
        return this;
    }

    /**
     * @return : LeadConversionRestResourceHelper returns this instance for the class
     * @description This method will call the internal service class to enable partner accounts
     * for the successfully converted lead
     */
    public LeadConversionRestResourceHelper updateConvertedAccountAsPartner(){
        thisPAService.prepareAccountFromLeads(thisInternalLCService.getSuccessFullyConvertedLead());
        return this;
    }

    //8/5/24 Vijaychandra --START-- (GTMS-22483): Created as part of Partner Application H2 project
    /******************************
     * @Description: This method will invoke a flow for Partner Registration record creation for Partner_Application
     */
    public LeadConversionRestResourceHelper create_PA_PR_Creation(){
        List<Id> partnerLeadIds = new List<Id>();
        for(Lead thisLead : thisInternalLCService.getSuccessFullyConvertedLead()){
            if(recordTypeToProcessUserProvisioning.contains(thisLead.RecordTypeId)){
                partnerLeadIds.add(thislead.Id);
            }
        }
        if(!partnerLeadIds.isEmpty()){
            
            for(Id leadId: partnerLeadIds){
                Map<String,Object> leadMap = new Map<String, Object >();
                Lead partnerLead = new Lead();
                partnerLead.Id = leadId;
                leadMap.put('leadRecord',partnerLead);
                leadMap.put('RetryCounter',0);
                
                try{ // added try/catch for GTMS-31636
                    Flow.Interview.Create_Partner_Registration_on_Lead_Conversion flowInstance = new Flow.Interview.Create_Partner_Registration_on_Lead_Conversion(leadMap);
                    flowInstance.start();
                    Logger.atInfo()
                        .setClassName('LeadConversionRestResourceHelper')
                        .setMethod('create_PA_PR_Creation')
                        .setRecordId(leadId)
                        .setExceptionOrMessage('SUCCESS PA/PR Creation');// added for GTMS-31636
                    
                }catch (Exception ex){ // added for GTMS-31636
                    partnerLead.Conversion_Error_Message_tal__c = 'LeadConversionRestResourceHelper -> create_PA_PR_Creation -> FAILED PA/PR Creation - ' + ex.getMessage();
               		errorRecords.add(partnerLead);
                }
            }
        }
        return this;
    }
    //8/5/24 Vijaychandra --END-- (GTMS-22483): Created as part of Partner Application H2 project

    

    //8/1/24 Vijaychandra --START-- (GTMS-22483): Created as part of Partner Application H2 project
     /******************************
     * @Description: This method will be invoked from Partner_Registraiton_After_Update flow to create a Partner User from contact when PAM approves the PR record
     * @param : contadIds --> partnerContactId. 
     */
    @InvocableMethod(label='Create Partner User' description='Patner User Creation')
    public static void invokeUserProvision(List<List<Id>> contadIds){
        if(!contadIds.isEmpty()){
            if(!contadIds[0].isEmpty()){
                Set<Id> userSet = new Set<Id>(); 
                List<User> userList = [SELECT Id From User where AccountId IN (Select AccountId from Contact where Id =: contadIds[0])];
                Is_Super_User = userList.size() > 0 ? false : true;    
				If(userList.size() > 0)
                    doProcessUserProvisioning(USER_PORTAL_PROFILE_NAME,new Set<Id>(contadIds[0]));
                Else
                	doProcessUserProvisioning(ADMIN_PORTAL_PROFILE_NAME,new Set<Id>(contadIds[0]));
            }
            
        } 
    }
    /******************************
     * @Description: This method will  create a Partner User from contact when PAM approves the PR record
     * @param : userProfileName -->  ADMIN_PORTAL_PROFILE_NAME
     * @param : contadIds -->  partnerContactId.
     */
    //@future
    public static void doProcessUserProvisioning(string userProfileName, Set<Id> contadIds){
        thisUserProvisioningService.setDefaultProfile(
                thisProfileSelector.getProfileByName(
                        userProfileName
                )?.get(0)?.Id
        );
        List<User> userList = thisUserProvisioningService.doProvisionFromContactIds(contadIds);

       try{
           verifyDupUsername(userList);

       }catch (Exception ex){
           /*Database.rollback(initialSavePoint);
           for(Lead thisLead : successFullyConvertedLeadMap.values()){
               thisLead.Conversion_Error_Message_tal__c = ex.getMessage();
               errorRecords.add(thisLead);
           }*/
       }
        //thisLCService.rollbackChanges(errorRecords);
    }
    //8/1/24 Vijaychandra --END-- (GTMS-22483): Created as part of Partner Application H2 project
    /**
     * @description This method will call the UserProvisioningService methods
     * by passing default profile
     * Set of Ids for successfully converted lead
     * And performing user Provisioning
     */
    public void doProcessUserProvisioning(String userProfileName){
        thisUserProvisioningService.setDefaultProfile(
                thisProfileSelector.getProfileByName(
                        userProfileName
                )?.get(0)?.Id
        );
        Map<Id, Lead> successFullyConvertedLeadMap = new Map<Id, Lead>(
                thisInternalLCService.getSuccessFullyConvertedLead()
        );
        List<User> userList = thisUserProvisioningService.doProvisionFromLeadIds(
                filterLeadForUserProvisioning(successFullyConvertedLeadMap)
        );

       try{
           verifyDupUsername(userList);

       }catch (Exception ex){
           Database.rollback(initialSavePoint);
           for(Lead thisLead : successFullyConvertedLeadMap.values()){
               thisLead.Conversion_Error_Message_tal__c = ex.getMessage();
               errorRecords.add(thisLead);
           }
       }
        thisLCService.rollbackChanges(errorRecords);
    }
    public static void verifyDupUsername(List<User> userList){
        List<User> failedUserRecords = new List<User>();
        List<String> profIds = System.Label.GTMS_Samsara_PartnerUser_ProfileIds.split(',');
        
           List<Database.SaveResult> saveResults = thisUserProvisioningService.insertUsers(userList, false);
           //System.debug('userList>>>> ' +userList);
           thisUserProvisioningService.assignPermissionSet(saveResults, 'Samsara_Partner_Base_Permissions');
           If(Is_Super_User == true) thisUserProvisioningService.assignPermissionSet(saveResults, 'Deligate_External_Admin_To_Partner_User');
            //Zak-SPP147-Nov11thRelease
            for (Integer i = 0; i < saveResults.size(); i++){
                Database.SaveResult sr = saveResults[i];
                if (!sr.isSuccess()){
                    for(Database.Error err : sr.getErrors()) {
                        if(err.getStatusCode() == StatusCode.DUPLICATE_USERNAME){
                            System.debug('userList ');
                            User currentRecord = userList[i];
                            //System.debug('UserNameContains' +currentRecord.Username.contains(System.Label.GTMS_Append_Samsara_PartnerUser));
                            System.debug('ProfileIDContains>> '+profIds.contains(currentRecord.ProfileId));
                            if(!Test.IsRunningTest()){
                               if(!currentRecord.Username.contains(System.Label.GTMS_Append_Samsara_PartnerUser) && profIds.contains(String.ValueOf(currentRecord.ProfileId)) ){
                                    currentRecord.Username += System.Label.GTMS_Append_Samsara_PartnerUser;
                                    failedUserRecords.add(currentRecord);
                                } 
                            }
                            
                        }
                    }
                }
            }
            // Insert again
            if (!failedUserRecords.isEmpty()){
                //Database.SaveResult[] srList = Database.insert(failedUserRecords);
                Database.SaveResult[] srList  = thisUserProvisioningService.insertUsers(userList, false);
                thisUserProvisioningService.assignPermissionSet(srList, 'Samsara_Partner_Base_Permissions');
                If(Is_Super_User == true) thisUserProvisioningService.assignPermissionSet(saveResults, 'Deligate_External_Admin_To_Partner_User');
            }
    }
    
    private Set<Id> filterLeadForUserProvisioning(Map<Id, Lead> mapOfLeadsByIds) {
        Set<Id> filterLeadIds = new Set<Id>();
        for(Lead thisLead : mapOfLeadsByIds.values()){
            if(recordTypeToProcessUserProvisioning.contains(thisLead.RecordTypeId)){
                filterLeadIds.add(thisLead.Id);
            }
        }
        return filterLeadIds;
    }

    /**
     * @description This is the internal class responsible for Partner Account services for converted leads
     * Can be used to add any further responsibilities based on the future requirements
     */
    public inherited sharing class PartnerAccountService implements IPAService{

        /**
         * @param leadList : List of converted lead
         * @description : This method will be used to enable account as partner
         */
        public void prepareAccountFromLeads(List<Lead> leadList){
            Set<Id> accountIds = new Set<Id>();
            for(Lead thisLead : leadList){
                if(recordTypeToProcessUserProvisioning.contains(thisLead.RecordTypeId)){
                    accountIds.add(thisLead.ConvertedAccountId);
                }

            }
            enablePartnerAccount(accountIds);
        }
        /**
         * @param accountIds : Set of account ids
         * This is internal method used to enable IsPartner checkbox
         * perform dml
         */
        private void enablePartnerAccount(Set<Id> accountIds){
            List<Account> accounts = new List<Account>();
            for(Id thisId : accountIds){
                accounts.add(
                        new Account (
                                Id = thisId,
                                IsPartner = true
                        )
                );
            }
            accountDMLHelper.updateObjects(accounts, false);

        }
        
    }
    
    /**
     * @description This is the internal class responsible for Deal Registration services for converted leads
     * Can be used to add any further responsibilities based on the future requirements
     */
    public inherited sharing class DealRegistrationService implements IDRService{

        /**
         * @param leadList : List of converted lead
         * @description : This method will be used to invoke flow that creates opportunities
         */
        public void createOppsForDealRegLeads(List<Lead> leadList){
            //filter the leads of type Channel_Relationship
            List<Lead> dealRegLeads = new List<Lead>();
            for(Lead thisLead : leadList){
                if(recordTypeToProcessDealReg.contains(thisLead.RecordTypeId)){
                    dealRegLeads.add(thisLead);
                }
            }
            
            //Limit to 1 Lead record
            //PE to create opportunity
            if(!dealRegLeads.isEmpty()) {
                /*
                CreateOpportunityEvent__e  event = new CreateOpportunityEvent__e ();
                event.Converted_Lead_Id_t__c  = dealRegLeads.get(0).Id;
                EventBus.publish(event);
				*/
                Map<String,Object> leadMap = new Map<String, Object >();
                    
                Lead leadRecord = new Lead();
                leadRecord.Id = dealRegLeads.get(0).Id;
                leadMap.put('leadRecord', leadRecord); 
                leadMap.put('RetryCounter', 0);
                
				Flow.Interview.Create_Partner_Registration_on_Lead_Conversion flowInstance = new Flow.Interview.Create_Partner_Registration_on_Lead_Conversion(leadMap);
                flowInstance.start();
            }
        }
        
        
    }

    /**
     * @description : Internal class used to perform DML on Account records
     * Methods can be added as per future scope
     */
    public inherited sharing class AccountDMLHelper implements IDMLHelper{

        /**
         * @param accountList : List of Account to perform DML on
         * @param allOrNothing : Flag to set for all or none
         * @return : Database.SaveResult[]
         */
        public Database.SaveResult[] updateObjects(List<Account> accountList, Boolean allOrNothing){
            return Database.update(accountList, allOrNothing);
        }
    }

    /**
     * @description : Internal class used to call the Lead conversion Service
     */
    public inherited sharing class convertLeadFromPayload implements ILCService{
        List<Lead> leadsWithError = new List<Lead>();
        List<Lead> leadsToConvert = new List<Lead>();

        /**
         * @description : This methods separate outs lead records from payload
         * with or without error and hold the temporary list for both
         * @param thisPayLoadList : Deserialized payroll from the rest resource
         * @return : convertLeadFromPayload returns this instance of self
         */
        public convertLeadFromPayload setLeadSFromPayload (List<Payload> thisPayLoadList){
            Set<Id> accountIdSet = new Set<Id>();
            for (Payload thisPayLoad : thisPayLoadList){
                if(String.isNotBlank(thisPayLoad.status)
                        && thisPayLoad.status.toLowerCase().contains(
                        LeadConversionRestResourceHelper.PAYLOAD_SUCCESS_STATUS)
                        ){
                    leadsToConvert.add(instantiateLead(thisPayLoad));
                    accountIdSet.add(thisPayLoad.accountId);
                }
                else{
                    leadsWithError.add(instantiateLead(thisPayLoad));
                }
            }
            
            if(!accountIdSet.isEmpty()) {
                try {
                    Map<Id, Account> accMap = new Map<Id, Account>([Select Id, OwnerId from Account where Id in :accountIdSet]);
                    for(Lead leadRecord : leadsToConvert) {
                        if(leadRecord.ConvertedAccountId != null && accMap.containsKey(leadRecord.ConvertedAccountId)) {
                            leadRecord.OwnerId = accMap.get(leadRecord.ConvertedAccountId).OwnerId;
                        }
                    }
                }
                catch(Exception ex) {
                    System.debug('No accounts found in the org');
                }
            }
            
            return this;
        }

        /**
         * @description : This method call the Lead conversion service
         * to perform lead conversion and collect corresponding errors
         * @return : convertLeadFromPayload returns this instance of self
         */
        public convertLeadFromPayload doConversion() {
            LeadConversionRestResourceHelper.thisLCService.setIdToLeadMap(
                    new Map<Id, Lead>(leadsToConvert)
            );
            LeadConversionRestResourceHelper.thisLCService.processIncomingLeads()
                    .doConversion()
                    .collectConversionErrors(leadsWithError);
            return this;
        }

        /**
         * @description : returns successfully converted lead list
         * @return : List<Lead> returns successfully converted lead list
         */
        public List<Lead> getSuccessFullyConvertedLead(){
            return LeadConversionRestResourceHelper.thisLCService.getConvertedLead();
        }

        public List<Lead> getLeadsWithErrors(){
            return this.leadsWithError;
        }

        /**
         * @description : This method used to set the temporary instance of lead from
         * Payload instance
         * @param thisPayLoad : accepts instance of payload internal class
         * @return : Lead instance of lead by populating contact and Account id for conversion
         */
        private Lead instantiateLead (Payload thisPayLoad){
            return new Lead(
                    Id = thisPayLoad.leadId,
                    ConvertedContactId = thisPayLoad.contactId,
                    ConvertedAccountId = thisPayLoad.accountId,
                    Conversion_Error_Message_tal__c = thisPayLoad.errorMessage,
                    Status = LeadConversionRestResourceHelper.LEAD_STATUS_TO_UPDATE
            );
        }
    }

    /**
     * @description : Internal class to hold the payload received by rest resource from
     * NOTRE DAME
     */
    public class Payload {

        public String leadId;
        public String status;
        public String accountId;
        public String contactId;
        public String errorMessage;

        /**
         * @description : This method accept JSON string and
         * returns the instance of payload after deserialization
         * @param json : accept JSON string
         * @return : returns the instance of payload after deserialization
         */
        public List<LeadConversionRestResourceHelper.Payload> parse(String json) {
            return (List<Payload>) System.JSON.deserialize(json, List<LeadConversionRestResourceHelper.Payload>.class);
        }
    }

    /**
     * @description : Internal Selector class used to query profile
     * More methods can be added to query based on different criteria
     */
    public inherited sharing class ProfileSelector implements ISelector{

        /**
         * @description : This method accepts the profile name and return
         * the queried profile list
         * @param profileName : accepts Name of profile
         * @return : return list of profile with
         */
        public List<Profile> getProfileByName(String profileName){
            return [ SELECT Id FROM Profile WHERE Name = : profileName ];
        }
    }

    public inherited sharing class userProvisioningException extends Exception {}

    /**
     * @description : Internal Interface to hold all the methods for the base class
     * Help with mocking in unit test
     */
    public interface IHelper{
        IHelper setPayLoadString(String payloadJson);
        IHelper processPayloadForConversion ();
        IHelper processLeadConversionError(); // added for GTMS-31636
        IHelper processDealRegistration();
        IHelper updateConvertedAccountAsPartner();
        IHelper create_PA_PR_Creation();
        void doProcessUserProvisioning(String portalProfileName);

    }

    /**
     * @description : Internal Interface to hold all the methods for the DML Helper particular to base class
     * Help with mocking in unit test
     */
    public interface IDMLHelper{
        Database.SaveResult[] updateObjects(List<Account> accountList, Boolean allOrNothing);
    }

    /**
     * @description : Internal Interface to hold all the methods
     * for the Internal Lead conversion Service particular to base class
     * Help with mocking in unit test
     */
    public interface ILCService{
        ILCService setLeadSFromPayload (List<Payload> thisPayLoadList);
        ILCService doConversion();
        List<Lead> getSuccessFullyConvertedLead();
        List<Lead> getLeadsWithErrors();
    }

    /**
     * @description : Internal Interface to hold all the methods
     * for the Internal Partner Account Service particular to base class
     * Help with mocking in unit test
     */
    public interface IPAService {
        void prepareAccountFromLeads(List<Lead> leadList);
    }
    
    /**
     * @description : Internal Interface to hold all the methods
     * for the Internal Deal Registration Service particular to base class
     * Help with mocking in unit test
     */
    public interface IDRService {
        void createOppsForDealRegLeads(List<Lead> leadList);
    }

    /**
     * @description : Internal Interface to hold all the methods
     * for the Internal Profile Selector particular to base class
     * Help with mocking in unit test
     */
    public interface ISelector{
        List<Profile> getProfileByName(String profileName);
    }
}
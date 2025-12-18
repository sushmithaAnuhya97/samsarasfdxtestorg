/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 06, 2021
*
* @description : This class will be responsible for handling all Account Service Operations
* SFA-11
* April-29-2022 Rajesh - (GTMS-6940) Commented calling the flow Delinquent_Opportunity_Creation
*Oct-03-2023 Vijaychandra: (GTMS-14030) Added calling method form Acc_UpdatePartnerGroupCls class in handleAfterUpdateOperations Method.
* Mar-26-2025 Ravindra : GTMS-26842 Renewal quote Payment terms assignment based on the account
**/
public inherited sharing class GS_AccountService {
    static gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    static gslib_ILogger thisLogger = thisModuleLogger.getLogger();
    static final String STATUS_EXISTING = 'Existing Customer';
    static final String TYPE_RESELLER_PARTNER = 'Reseller Partner';
    static final String TYPE_REFERRAL_PARTNER = 'Referral Partner';
    static final String DEACTIVATION_STATUS_APPROVED = 'Approved';
    static final String ASYNC_OPERATION_STAMPLAWFUL = 'StampLawfulBasis';
    //Edit by: Govindaraju Boddu (GTMS-13750) 
    //Edit on: 20th, June 2023
    static final String BYPASS_OPS_SYSTEM_ADMIN_PROFILE_LIST = System.Label.GS_AccountService_Bypass_ProfileList;
    static final String currentUserProfileId = UserInfo.getProfileId();
    //Edit end: 20th, June 2023
    public GS_AccountService() {
        
    }
    
    //TODO - CSM logic to remain in the class but move the enterprise segment to before insert + update
    //Method name can be generic in the future -@Harsha
    public void stampLawfulBasisAndCheckIfAccountNeedsCsmOrSeOnUpdate(Map<Id, Account> oldAccountMap, List<Account> newAccountList) {
        Map<Id, Account> accountsToUpdate = new Map<Id,Account>();
        Map<String, Object> params = new Map<String, Object>();
        Map<String, Object> newparams = new Map<String, Object>();
        Set<Id> accountsToQuery = new Set<Id>();
        for (Account newAccount : newAccountList) {
            Account oldAccount = oldAccountMap.get(newAccount.Id);
            //Groundswell : Nilesh Jain - stampLawfulBasisOnAccountUpdate changes
            if(HelperClass.euCountryCodes.contains(newAccount.BillingCountryCode) 
               && (newAccount.Status__c == STATUS_EXISTING 
                   || newAccount.Type == TYPE_RESELLER_PARTNER 
                   || newAccount.Type == TYPE_REFERRAL_PARTNER)) {
                accountsToQuery.add(newAccount.id);
            }
            
            if (oldAccount.Deactivation_Approval_Status__c != DEACTIVATION_STATUS_APPROVED && newAccount.Deactivation_Approval_Status__c == DEACTIVATION_STATUS_APPROVED) {
                params.put('recordId', newAccount.Id);
            }
            
            //GTMS-3986 Downgrade Email Alert @Anil Bogadi 
            if (oldAccount.CSM_Health_Rating__c !=  newAccount.CSM_Health_Rating__c && newAccount.CSM_Health_Rating__c !=  'Green' && newAccount.CSM_Health_Rating__c != '--' && (oldAccount.CSM_Health_Rating__c != 'Red' && newAccount.CSM_Health_Rating__c !=  'Yellow')) {
                newparams.put('recordId', newAccount.Id);
            }
        }
        //Groundswell : Nilesh Jain - stampLawfulBasisOnAccountUpdate changes
        if(accountsToQuery.size()>0) { 
            thisLogger.logInfo('Stamping Lawful Basis on Contact ::',accountsToQuery);
            DMLWrapper.doInsert(new GS_ContactServiceAsync().prepareAsyncRequests(
            JSON.serialize(new GS_ContactServiceAsync.Options(ASYNC_OPERATION_STAMPLAWFUL)), 
            accountsToQuery));
        }
        //End

        /* GTMS-6940 - Commented below
        if (params.size() > 0) {
            thisLogger.logInfo('Starting Flow to Delinquent Opportunity Creation ::',params);
            Flow.Interview.Delinquent_Opportunity_Creation flow = new Flow.Interview.Delinquent_Opportunity_Creation(params);
            flow.start();
        }*/
        
        //GTMS-3986 Downgrade Email Alert @Anil Bogadi 
        //GTMS-6752 Deactivating email alert and commenting due to gainsight issues @chinmaya Dash
        /*if (newparams.size() > 0) {
            thisLogger.logInfo('Starting Flow to Customer Health Downgraded Email ::',newparams);
            Flow.Interview.Customer_Health_Downgraded_Email flow = new Flow.Interview.Customer_Health_Downgraded_Email(newparams);
            flow.start();
        }*/
        
    }
    

    public inherited sharing class AccountTriggerContext
    {
        List<Account> newAccountList;
        Map<Id, Account> newAccountMap;
        Map<Id, Account> OldAccountMap;
        List<Account> oldAccountList;
        GS_AccountPrePopulationService thisPrePopService = new GS_AccountPrePopulationService();
        GS_CSMService csmService = new GS_CSMService();
        GS_DelinquencyService delinquencyService = new GS_DelinquencyService();
        
        GS_CSRecordService csRecordService = new GS_CSRecordService();
        
         public AccountTriggerContext(Map<Id, Account> oldAccountMap, List<Account> newAccountList, List<Account> oldAccountList,Map<Id, Account> newAccountMap){
            this.newAccountList = newAccountList;
            this.OldAccountMap = OldAccountMap;
            this.oldAccountList = oldAccountList;
            this.newAccountMap = newAccountMap;
        }
        
        public void handleBeforeOperations (){
            thisPrePopService.commonContextPrePopulateHelper(oldAccountMap, newAccountList);
            csmService.setCSMData(oldAccountMap, newAccountList);
            delinquencyService.setDelinquencyStatus(oldAccountMap, newAccountList);
            delinquencyService.adjustNetTermsPerSegment(oldAccountMap, newAccountList);
            GS_AccountValidationService.sitesUnloadAccount(newAccountList);
        }
        
        public void handleBeforeInsertOperations(){
            thisLogger.logDebug('handleBeforeInsertOperations Account List ::', newAccountList);
            thisPrePopService.beforeInsertAccountWorkflowConversion(newAccountList);
            thisPrePopService.insertUltimateAccount(newAccountList);
            AccountBookTriggerHelper.updateAccountBook(oldAccountMap,newAccountList);//GTMS-19301
            AccountHelper.updateADRAssignmentFromBooks(oldAccountMap, newAccountList);
             
           

        }
        
        public void handleAfterInsertOperations(){
            thisLogger.logDebug('handleAfterInsertOperations Account List ::', newAccountList);
            thisPrePopService.performCheckOnCSMRelatedFields(oldAccountMap, newAccountList); // added for GTMS-10383
            csRecordService.createCSRecords(newAccountList);
            thisPrePopService.taskCreation(newAccountList);//GTMS- 11420
            AccountBookTriggerHelper.AddteamMember(oldAccountMap,newAccountList);// GTMS-11943
        }

        public void handleBeforeUpdateOperations(){
            thisLogger.logDebug('handleBeforeUpdateOperations New Account List ::', newAccountList);
            thisLogger.logDebug('handleBeforeUpdateOperations Old Account Map ::', oldAccountMap.values());
            thisPrePopService.updateUltimateAccount(newAccountList,oldAccountMap);
            thisPrePopService.updateAccountStatus(oldAccountMap, newAccountList); // added for Account Status Program
            //Edit by: KAPIL (GTMS-18361)
            thisPrePopService.updateTierDetails(oldAccountMap, newAccountList);
            //Edit by: Govindaraju Boddu (GTMS-13750) 
            //Edit on: 20th, June 2023
            List<String> profileIdList = BYPASS_OPS_SYSTEM_ADMIN_PROFILE_LIST.split(';');
            Set<String> profileIdSet = new Set<String>();
            profileIdSet.addAll(profileIdList);
            //Map<Id,Profile> profileIdVsProfileMap = new Map<Id,Profile>([SELECT Id,Name FROM Profile WHERE Name IN :profileNameList]);
            if(profileIdSet.size() > 0 && !profileIdSet.contains(currentUserProfileId))
            {
            	AccountBookTriggerHelper.checkAccountBookAssignment(oldAccountMap, newAccountList); // added for GTMS-11048 Project Alpha    
            }

            //Edit end: 20th, June 2023
            thisPrePopService.beforeUpdatePrePopulateHelper(oldAccountMap, newAccountList);
            thisPrePopService.beforeUpdateAccountWorkflowConversion(oldAccountMap, newAccountList);
            thisPrePopService.accountsChanged(oldAccountMap, newAccountList);
			AccountBookTriggerHelper.retainTeamMembers(newAccountList,oldAccountMap);
            AccountBookTriggerHelper.updateAccountBook(oldAccountMap,newAccountList); //GTMS-19301
            AccountHelper.updateADRAssignmentFromBooks(oldAccountMap, newAccountList);
            
			
            
        }
        
        public void handleAfterUpdateOperations(){
            thisLogger.logDebug('handleAfterUpdateOperations New Account List ::', newAccountList);
            thisLogger.logDebug('handleAfterUpdateOperations Old Account Map ::', oldAccountMap.values());
            thisPrePopService.performCheckOnCSMRelatedFields(oldAccountMap, newAccountList); // added for GTMS-10383
            csRecordService.stampAccountInfoOnCsRecord(oldAccountMap, newAccountList);
            //GS_AccountPrePopulationService.updateOpportunityOwnerBasedAccOwner(oldAccountMap, newAccountList);
            GS_AccountPrePopulationService.performUserAssignment(newAccountList); // added for GTMS-11254
            GS_AccountPrePopulationService.updateContracts(newAccountList, oldAccountMap);  //added for GTMS-12082
            thisPrePopService.createPlatformEvent();
            thisPrePopService.addtaskupdate(newAccountList,oldAccountMap);// GTMS-13131
            AccountBookTriggerHelper.AddteamMember(oldAccountMap,newAccountList);// GTMS-11943
            GS_AccountPrePopulationService.updateZendeskFlag(newAccountList, oldAccountMap); // added for GTMS-12941
            GS_AccountPrePopulationService.updateContactOwner(newAccountList, oldAccountMap); // added for GTMS-12941
            GS_AccountPrePopulationService.revertRenewalOpportunityOwner(newAccountList, oldAccountMap); //added this method to fix GTMS-7561
            GS_AccountPrePopulationService.updateQuoteBillingDetails(newAccountList,oldAccountMap); // Added this method for GTMS-16585
            GS_AccountPrePopulationService.unlockApprovalRecord(newAccountList, oldAccountMap);
            GS_AccountWorkflowConversionService.handleAccountUpdate(newAccountList, oldAccountMap);// Added as part of GTMS-26848 
            //GTMS-14030 --START--
            	Acc_UpdatePartnerGroupCls.updatePartnerGroup(oldAccountMap,new Map<Id,Account>(newAccountList));
            //GTMS-15030 --END--
            AccountBookTriggerHelper.reinsertTeamMembers(newAccountList,oldAccountMap);
            AccountBookTriggerHelper.quoteSharetonewAccountOwner(oldAccountMap,newAccountMap); //Added for GTMS-14574
            thisPrePopService.updateCSMDetails(oldAccountMap,newAccountList); // Added for GTMS-269
            updateRenewalQuotePaymentTerms(oldAccountMap,newAccountMap); //Added for GTMS-26842
            thisPrePopService.populateGeographySegment(newAccountList, oldAccountMap);
            
        }
        
        public void beforeDeleteOperations(){
            thisLogger.logDebug('beforeDeleteOperations Old Account List ::', oldAccountList);
            csRecordService.deleteCSRecords(oldAccountList);
            thisPrePopService.accountExtensionCleanUp(oldAccountMap);
        }
        //added this method to fix GTMS-7561
        /*public void revertRenewalOpportunityOwner(List<Account> newAccountList, Map<Id, Account> oldAccountMap) {
            Map<Id, Id> mapAccOldOwner = new Map<Id, Id>();
            Map<Id, Id> mapOppOldOwner = new Map<Id, Id>();
            for(Account acc : newAccountList) {
                system.debug('acc.OwnerId---'+acc.OwnerId);
                system.debug('oldAccountMap.get(acc.Id).OwnerId---'+oldAccountMap.get(acc.Id).OwnerId);
                if(acc.OwnerId != oldAccountMap.get(acc.Id).OwnerId) {
                    
                    mapAccOldOwner.put(acc.Id, oldAccountMap.get(acc.Id).OwnerId);
                }
            }
            if(!mapAccOldOwner.isEmpty()) {
                List<Opportunity> oppList = [
                    Select Id, OwnerId, StageName, Type, Renewal__c, AccountId
                    From Opportunity
                    Where IsClosed = false and Renewal__c = TRUE AND Type = 'Revenue Opportunity'
                    AND AccountId IN:mapAccOldOwner.keyset()
                ];
                if(!oppList.isEmpty() && oppList.size() > 0) {
                    for(Opportunity opp : oppList) {
                        mapOppOldOwner.put(opp.Id, mapAccOldOwner.get(opp.AccountId));
                    }
                    system.debug('mapOppOldOwner---'+mapOppOldOwner);
                    revertOpportunityOwner(mapOppOldOwner);
                }
            }
        }*/
        
     /**
     * GTMS-26842
     * @description Updates Payment Terms on Renewal Quotes when Account Payment Terms change
     * @param newMap Map of new Account records
     * @param oldMap Map of old Account records
     */
    public void updateRenewalQuotePaymentTerms(Map<Id, Account> oldMap, Map<Id, Account> newMap) {
        Map<Id, String> accountToNewPaymentTermsMap = new Map<Id, String>();
        
        // Identify accounts where Payment Terms have changed
        for (Id accountId : newMap.keySet()) {
            if (oldMap.get(accountId).Payment_Terms__c != newMap.get(accountId).Payment_Terms__c) {
                accountToNewPaymentTermsMap.put(accountId, newMap.get(accountId).Payment_Terms__c);
            }
        }
        
        // If no accounts with changed Payment Terms, exit
        if (accountToNewPaymentTermsMap.isEmpty()) {
            return;
        }
        
        // Query for all renewal quotes related to these accounts that are not approved
        List<SBQQ__Quote__c> quotesToUpdate = [
            SELECT Id, SBQQ__PaymentTerms__c, SBQQ__Account__c 
            FROM SBQQ__Quote__c 
            WHERE SBQQ__Account__c IN :accountToNewPaymentTermsMap.keySet() 
            AND SBQQ__Opportunity2__r.SBQQ__RenewedContract__c != NULL 
            AND SBQQ__Opportunity2__r.Type = 'Revenue Opportunity'
            AND SBQQ__Status__c != 'Approved'
            AND SBQQ__Primary__c = true
        ];
        
        // Update quotes with Account's new Payment Terms
        for (SBQQ__Quote__c quote : quotesToUpdate) {
            quote.SBQQ__PaymentTerms__c = accountToNewPaymentTermsMap.get(quote.SBQQ__Account__c);
        }
        
        // Update quotes in database
        if (!quotesToUpdate.isEmpty()) {
            try {
                /*  replaced direct DML with FFLIB DML( commmit to DB at the end ) 
                    - HG - GTMS-32141 - 30th Oct, 2025 
                */
                DMLWrapper.doUpdate( quotesToUpdate );
            } catch (Exception ex) {
                System.debug('Error updating renewal quotes: ' + ex.getMessage());
            }
        }
    }

}  
}
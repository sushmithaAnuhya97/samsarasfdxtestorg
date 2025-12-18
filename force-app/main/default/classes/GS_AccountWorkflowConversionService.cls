/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 06, 2021
*
* @description : This Service Class is responsible for Converted Account Workflows
* SFA-11
*
**/
public inherited sharing class GS_AccountWorkflowConversionService {
    gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
    gslib_ILogger thisLogger = thisModuleLogger.getLogger();
   
   public GS_AccountWorkflowConversionService() {

   }
   
   //Query user details if owberIds set not null
    Map<Id, User> mapUsers = new Map<Id, User>();

   /**
    *  BEFORE INSERT WORKFLOW CONVERSIONS
    */

   public Map<Id, User> beforeInsertAccountWorkflowConversion(List<Account> newAccountList){
       thisLogger.logDebug('beforeInsertAccountWorkflowConversion New Account List::', newAccountList);
       Set<Id> ownerIds = new Set<Id>();
       Map<Id, Account> accountsWithCsmChangesMap = new Map<Id, Account>();
       Map<Id, Account> accountUpdateManagerEmail = new Map<Id, Account>();
       Account oldAccount = new Account();
       populateGlobalGeography(newAccountList, null);
       for(Account newAccount : newAccountList) {
           //Goundswell : Nilesh Jain - Stamp CSM Manager Email
           //08/03/2021 - GTMS 4285 Updated the criteria to consider SIC Manager's Email address too. @Apisero team
           if(newAccount.SIC__c != null){
               accountsWithCsmChangesMap.put(newAccount.SIC__c, newAccount);
               ownerIds.add(newAccount.SIC__c);
           }else if(newAccount.SIC__c == null && newAccount.CSM__c != null){
               accountsWithCsmChangesMap.put(newAccount.CSM__c, newAccount);
               ownerIds.add(newAccount.CSM__c);
           }

           //Groundswell : Nilesh Jain - Owner Manager Email workflow changes.
           if(newAccount.OwnerId != null){
               
               // WF Rule - Account: Segment
               //This text field brings in the Segment value from the
               //formula field: Segment (by Current owner) field on the account.
               if(String.isBlank(newAccount.Segment_Text_stamped__c)){
                   newAccount.Segment_Text_stamped__c = newAccount.Segment__c;
               }
               
               accountUpdateManagerEmail.put(newAccount.OwnerId, newAccount);
               ownerIds.add(newAccount.OwnerId);
           }
           AccountWorkflowConversion.beforeInsertRules(newAccount);
           AccountWorkflowConversion.beforeInsertUpdateRules(newAccount, oldAccount);
       }

       //Query user details if owberIds set not null
         if(!ownerIds.isEmpty())
         mapUsers = new GS_UserSelector(true).checkFatalError().getUserMapByIds(ownerIds);
      // mapUsers = new Map<Id, User>(AccountWorkflowConversion.getAccountCsmMap(ownerIds));

       //Groundswell : Nilesh Jain - Stamp CSM Manager Email workflow changes
       if(!accountsWithCsmChangesMap.isEmpty()){
           AccountWorkflowConversion.stampCSMManagerEmail(accountsWithCsmChangesMap, mapUsers);
       }

       //Groundswell : Nilesh Jain - Owner Manager Email workflow changes
       if(!accountUpdateManagerEmail.isEmpty()){
           AccountWorkflowConversion.stampOwnerManagerEmail(accountUpdateManagerEmail, mapUsers);
       }

       return mapUsers;
       
   }



   /**
    *  BEFORE UPDATE WORKFLOW CONVERSIONS
    */

   public Map<Id, User> beforeUpdateAccountWorkflowConversion(Map<Id, Account> oldAccountMap, List<Account> newAccountList){
       thisLogger.logDebug('beforeUpdateAccountWorkflowConversion New Account List::', newAccountList);
       thisLogger.logDebug('beforeUpdateAccountWorkflowConversion Old Account List::', oldAccountMap.values());
       Set<Id> ownerIds = new Set<Id>();
       Map<Id,Account> accountsWithCsmMap = new Map<Id,Account>();
       Map<Id,Account> accountsWithAssignCsmMap = new Map<Id,Account>();
  //   Map<Id, Account> accountsWithSICChanged = new Map<Id, Account>();
       Map<Id, Account> accountsWithCsmChangesMap = new Map<Id, Account>();
       Map<Id, Account> accountUpdateManagerEmail = new Map<Id, Account>();
       Map<Id, Account> accountEscalationOwnerName = new Map<Id, Account>();
       Map<Id, Account> accountToApproveSamsaraPreApprovalMap = new Map<Id, Account>();
       Map<Id, Account> accountToDeclineSamsaraPreApprovalMap = new Map<Id, Account>();
       Map<Id, Account> ownerRoleAccIds = new Map<Id, Account>();

       for(Account newAccount : newAccountList) {

           Account oldAccount = new Account();
           oldAccount = oldAccountMap.get(newAccount.Id);

           if(newAccount.Send_to_My_ADR__c) {
               ownerIds.add(newAccount.OwnerId);
           }
           
           //Groundswell : Nilesh Jain - Owner Manager Email workflow changes.
           if(oldAccount.OwnerId != newAccount.OwnerId && newAccount.OwnerId != null){
               accountUpdateManagerEmail.put(newAccount.OwnerId, newAccount);
               ownerIds.add(newAccount.OwnerId);
               ownerIds.add(oldAccount.OwnerId);
           }
           
           if(newAccount.CSM__c != null){
               accountsWithCsmMap.put(newAccount.CSM__c, newAccount);
               //leveraging existing user set to avoid duplicate queries in the logic below.
               ownerIds.add(newAccount.CSM__c);
           }
           
           //Groundswell : Nilesh Jain - Uncheck Assign CSM workflow changes
           if(oldAccount.Assign_CSM__c != newAccount.Assign_CSM__c && newAccount.Assign_CSM__c && newAccount.CSM__c != null){
               accountsWithAssignCsmMap.put(newAccount.CSM__c, newAccount);
               ownerIds.add(newAccount.CSM__c);
           }
           //End

           //Goundswell : Nilesh Jain - Stamp CSM Manager Email
           //08/03/2021 - GTMS 4285 Updated the criteria to consider SIC Manager's Email address too. @Apisero team
           if((oldAccount.Id != null && oldAccount.SIC__c != newAccount.SIC__c) && newAccount.SIC__c != null){
               System.debug('Updated 1');
               accountsWithCsmChangesMap.put(newAccount.SIC__c, newAccount);
               ownerIds.add(newAccount.SIC__c);
           }else if(newAccount.SIC__c == null && newAccount.CSM__c != null){
               System.debug('Updated 2');
               accountsWithCsmChangesMap.put(newAccount.CSM__c, newAccount);
               ownerIds.add(newAccount.CSM__c);
           }

          /*
           *      //Groundswell :  Nilesh Jain - Stamp CSM Name workflow changes
               if(oldAccount.SIC__c != a.SIC__c && a.CSM__c != null){
                   accountsWithSICChanged.put(a.CSM__c, a);
                   ownerIds.add(a.CSM__c);
               }
               //End
          */
   
   
               //Groundswell : Nilesh Jain - Update Support Escalation Owner Name changes
               if(oldAccount.Support_Escalation_Owner__c != newAccount.Support_Escalation_Owner__c
                       && newAccount.Support_Escalation_Owner__c != null){
                   accountEscalationOwnerName.put(newAccount.Support_Escalation_Owner__c, newAccount);
                   ownerIds.add(newAccount.Support_Escalation_Owner__c);
               }
               //End
               
               //WF Rule - Samsara Pre-Approval - Approve & 
               //WF Rule - Samsara Pre-Approval - Decline
               if(oldAccount.Credit_Pre_Approval_Status__c != newAccount.Credit_Pre_Approval_Status__c){
                   if(newAccount.Credit_Pre_Approval_Status__c == 'Approved'){
                       ownerIds.add(newAccount.OwnerId);
                       accountToApproveSamsaraPreApprovalMap.put(newAccount.OwnerId,newAccount);
                   }else if(newAccount.Credit_Pre_Approval_Status__c == 'Declined' || newAccount.Credit_Pre_Approval_Status__c == 'Pending'){
                       ownerIds.add(newAccount.OwnerId);
                       accountToDeclineSamsaraPreApprovalMap.put(newAccount.OwnerId,newAccount);
                   }
               }
                //Zakeer - GTMS-12328-May24
               if( String.isNotBlank(newAccount.DUNS_Number__c) && newAccount.DUNS_Number__c.length() < 9 ){
                   newAccount.DUNS_Number__c = newAccount.DUNS_Number__c.leftPad(9, '0');
               }

           AccountWorkflowConversion.beforeInsertUpdateRules(newAccount, oldAccount);
       }

       //Query user details if owberIds set not null
       if(!ownerIds.isEmpty())
        mapUsers = new GS_UserSelector(true).checkFatalError().getUserMapByIds(ownerIds);
    //  mapUsers = new Map<Id, User>(AccountWorkflowConversion.getAccountCsmMap(ownerIds));
       //Groundswell : Nilesh Jain - Uncheck Assign CSM workflow changes
       if(!accountsWithAssignCsmMap.isEmpty()){
           AccountWorkflowConversion.uncheckAssignCSM(accountsWithAssignCsmMap, mapUsers);
       }
       //End
       // Groundswell-Tanuj (GTMS-3000)- Changes for Workflow Conversion
       if(!accountsWithCsmMap.isEmpty()){
           AccountWorkflowConversion.completeCsmOnboarding(accountsWithCsmMap, mapUsers);
       }
       // End
       //Groundswell : Nilesh Jain - Stamp CSM Name workflow changes
     /*  if(!accountsWithSICChanged.isEmpty()){
           AccountWorkflowConversion.stampCSMName(accountsWithSICChanged, mapUsers);
       }
       */
       //End
       
       //Groundswell : Nilesh Jain - Stamp CSM Manager Email workflow changes
       if(!accountsWithCsmChangesMap.isEmpty()){
           AccountWorkflowConversion.stampCSMManagerEmail(accountsWithCsmChangesMap, mapUsers);
       }
       //Groundswell : Nilesh Jain - Owner Manager Email workflow changes
       if(!accountUpdateManagerEmail.isEmpty()){
           AccountWorkflowConversion.stampOwnerManagerEmail(accountUpdateManagerEmail, mapUsers);
       }
       if(!accountEscalationOwnerName.isEmpty()){
           AccountWorkflowConversion.stampEscalationOwnerName(accountEscalationOwnerName, mapUsers);
       }
       if(!accountToApproveSamsaraPreApprovalMap.isEmpty()){
           AccountWorkflowConversion.preApproveSamsaraStatus(accountToApproveSamsaraPreApprovalMap, mapUsers);
       }

       if(!accountToDeclineSamsaraPreApprovalMap.isEmpty()){
           AccountWorkflowConversion.declinePreApproveSamsaraStatus(accountToDeclineSamsaraPreApprovalMap, mapUsers);
       }
       populateGlobalGeography(newAccountList, oldAccountMap);
       return mapUsers;
       
   }
    public static void populateGlobalGeography(List<Account> newAccountList, Map<Id, Account> oldAccountMap) {
        // Cache metadata type values
        Map<String, String> countryValuesMap = getCountryCodeMappings();
        Map<String, String> stateValuesMap = getStateCodeMappings();
        
        for(Account newAcc : newAccountList) {
            Account oldAcc = oldAccountMap?.get(newAcc.Id);
            
            if (needsProcessing(newAcc, oldAcc)) {
                processAccountGeography(newAcc, oldAcc, countryValuesMap, stateValuesMap);
            }
        }
    }

    private static Map<String, String> getCountryCodeMappings() {
        Map<String, String> countryValuesMap = new Map<String, String>();
        for(CountryCode_Global_Geography__mdt countryMdtRecord : CountryCode_Global_Geography__mdt.getAll().values()) {
            countryValuesMap.put(countryMdtRecord.developerName, countryMdtRecord.Global_Geography__c);
        }
        return countryValuesMap;
    }

    private static Map<String, String> getStateCodeMappings() {
        Map<String, String> stateValuesMap = new Map<String, String>();
        for(StateCode_Global_Geography__mdt stateCodeMdtRecord : StateCode_Global_Geography__mdt.getAll().values()) {
            String stateCodeVsCountryCode = stateCodeMdtRecord.developerName + '_' + stateCodeMdtRecord.CountryCode__c;
            stateValuesMap.put(stateCodeVsCountryCode, stateCodeMdtRecord.Global_Geography__c);
        }
        return stateValuesMap;
    }

    private static Boolean needsProcessing(Account newAcc, Account oldAcc) {
        return oldAcc == null || // Insert case
               newAcc.BillingCountry != oldAcc.BillingCountry || 
               newAcc.BillingState != oldAcc.BillingState ||
               newAcc.BillingCountryCode != oldAcc.BillingCountryCode ||
               newAcc.BillingStateCode != oldAcc.BillingStateCode ||
               String.isBlank(newAcc.Global_Geography__c);
    }

    private static void processAccountGeography(Account newAcc, Account oldAcc, 
                                              Map<String, String> countryValuesMap, 
                                              Map<String, String> stateValuesMap) {
        // Get billing codes
        String billingCountryCode = getBillingCountryCode(newAcc, oldAcc);
        String billingStateCode = getBillingStateCode(newAcc, oldAcc);

        // Set Global Geography
        newAcc.Global_Geography__c = determineGlobalGeography(billingStateCode, billingCountryCode, 
                                                            countryValuesMap, stateValuesMap);

        // Update billing codes if needed
        updateBillingCodes(newAcc, billingCountryCode, billingStateCode);
    }

    private static String getBillingCountryCode(Account newAcc, Account oldAcc) {
        // Handle new account case
        if (oldAcc == null) {
            return String.isNotBlank(newAcc.BillingCountryCode) 
                ? newAcc.BillingCountryCode 
                : BillingAddressPicklistUtil.getBillingCountryCode(newAcc.BillingCountry);
        }
        
        // Handle existing account case
        if (newAcc.BillingCountryCode != oldAcc.BillingCountryCode && newAcc.BillingCountry == oldAcc.BillingCountry) {
            return newAcc.BillingCountryCode;
        }
        
        if (newAcc.BillingCountry != oldAcc.BillingCountry) {
            return BillingAddressPicklistUtil.getBillingCountryCode(newAcc.BillingCountry);
        }
        
        return newAcc.BillingCountryCode;
    }

    private static String getBillingStateCode(Account newAcc, Account oldAcc) {
        // Handle new account case
        if (oldAcc == null) {
            return String.isNotBlank(newAcc.BillingStateCode) 
                ? newAcc.BillingStateCode 
                : BillingAddressPicklistUtil.getBillingStateCode(newAcc.BillingState);
        }
        
        // Handle existing account case
        if (newAcc.BillingStateCode != oldAcc.BillingStateCode && newAcc.BillingState == oldAcc.BillingState) {
            return newAcc.BillingStateCode;
        }
        
        if (newAcc.BillingState != oldAcc.BillingState) {
            return BillingAddressPicklistUtil.getBillingStateCode(newAcc.BillingState);
        }
        
        return newAcc.BillingStateCode;
    }

    private static String determineGlobalGeography(String billingStateCode, String billingCountryCode,
                                                 Map<String, String> countryValuesMap, 
                                                 Map<String, String> stateValuesMap) {
        if (String.isNotEmpty(billingStateCode) && String.isNotEmpty(billingCountryCode)) {
            String accStateVsCountryCode = billingStateCode + '_' + billingCountryCode;
            if (stateValuesMap.containsKey(accStateVsCountryCode)) {
                return stateValuesMap.get(accStateVsCountryCode);
            }
        }
        
        if (String.isNotEmpty(billingCountryCode) && countryValuesMap.containsKey(billingCountryCode)) {
            return countryValuesMap.get(billingCountryCode);
        }
        
        return 'Other';
    }

    private static void updateBillingCodes(Account acc, String billingCountryCode, String billingStateCode) {
        if (String.isNotBlank(billingCountryCode) && acc.BillingCountryCode != billingCountryCode) {
            acc.BillingCountryCode = billingCountryCode;
        }
        if (String.isNotBlank(billingStateCode) && acc.BillingStateCode != billingStateCode) {
            acc.BillingStateCode = billingStateCode;
        }
    }

    public static void handleAccountUpdate(List<Account> newAccounts, Map<Id,Account> oldAccountMap) {
        // Track Accounts that meet our criteria
        Set<Id> qualifiedAccountIds = new Set<Id>();

        // Check each Account for qualifying changes
        for(Account acc : newAccounts) {
            Account oldAcc = oldAccountMap.get(acc.Id);
            
            // Qualify if purchase date or ACV changed and meets minimum criteria
            if(oldAcc.First_Purchase_Date__c == null && 
                acc.First_Purchase_Date__c != null && 
                acc.Lifetime_ACV_to_USD__c > 0) {
                qualifiedAccountIds.add(acc.Id);
            }
        }
        
        if(!qualifiedAccountIds.isEmpty() && !System.isFuture() && !System.isBatch()) {
            updateContactsForQualifiedAccounts(qualifiedAccountIds);
        }
    }

    @future
    private static void updateContactsForQualifiedAccounts(Set<Id> qualifiedAccountIds) {
        gslib_IModuleLogger thisModuleLogger = gslib_LoggerService.getModuleLogger('GTMS');
        gslib_ILogger thisLogger = thisModuleLogger.getLogger();
        
        try {
            
            // Get all Contacts for qualifying Accounts
            Map<Id, Contact> contactsToUpdateMap = new Map<Id, Contact>();
        
            // Define base field set
            Set<String> fieldApiNames = new Set<String>{
                'Id', 
                'HasOptedOutOfEmail',
                'Email_Resource_Opt_In__c', 
                'Email_Newsletter_Opt_In__c', 
                'Email_Surveys_Opt_In__c', 
                'Email_Using_Samsara_Opt_In__c', 
                'Email_Product_Ann_Updates_Opt_In__c',
                'Preferences_Text_Stamped__c'
            };
            
            // Get field mappings from custom metadata
            List<Contact_Preferences_Field_Mapping__mdt> fieldMappingList = Contact_Preferences_Field_Mapping__mdt.getAll().values();
            Map<String, String> fieldVarMap = new Map<String, String>();
            
            for(Contact_Preferences_Field_Mapping__mdt fieldMap : fieldMappingList) {
                fieldApiNames.add(fieldMap.Field_Api_Name__c);
                fieldVarMap.put(fieldMap.Field_Api_Name__c, fieldMap.Label);
            }
            
            // Build and execute dynamic query
            String queryFields = String.join(new List<String>(fieldApiNames), ',');
            String query = 'SELECT ' + queryFields + 
                        ' FROM Contact ' +
                        ' WHERE AccountId IN :qualifiedAccountIds LIMIT 10000';
            
            for(Contact con : Database.query(query)) {
                Boolean needsUpdate = false;
                
                // Check and update email opt-out fields
                if (con.HasOptedOutOfEmail != false) {
                    con.HasOptedOutOfEmail = false;
                    needsUpdate = true;
                }
                
                if (con.Email_Resource_Opt_In__c != true) {
                    con.Email_Resource_Opt_In__c = true;
                    needsUpdate = true;
                }
                
                if (con.Email_Newsletter_Opt_In__c != true) {
                    con.Email_Newsletter_Opt_In__c = true;
                    needsUpdate = true;
                }
                
                if (con.Email_Surveys_Opt_In__c != true) {
                    con.Email_Surveys_Opt_In__c = true;
                    needsUpdate = true;
                }
                
                if (con.Email_Using_Samsara_Opt_In__c != true) {
                    con.Email_Using_Samsara_Opt_In__c = true;
                    needsUpdate = true;
                }
                
                if (con.Email_Product_Ann_Updates_Opt_In__c != true) {
                    con.Email_Product_Ann_Updates_Opt_In__c = true;
                    needsUpdate = true;
                }
                
                if (needsUpdate) {
                    // Update preferences text
                    String concatenatedPreferenceText = ContactHelper.constructPrefString(con, fieldVarMap);
                    if(con.Preferences_Text_Stamped__c != concatenatedPreferenceText) {
                        con.Preferences_Text_Stamped__c = concatenatedPreferenceText;
                    }
                    
                    contactsToUpdateMap.put(con.Id, con);
                }
            }
            
            // Bulk update modified Contacts
            if(!contactsToUpdateMap.isEmpty()) {
                TriggerHandler.bypass('GS_ContactTriggerHandler');
                TriggerHandler.bypass('ContactTriggerHandler');
                update contactsToUpdateMap.values();
            }
            
        } catch (Exception e) {
            thisLogger.logError(
                'Error updating contacts',
                new SamsaraLoggerObjectMVP(
                    e.getMessage(),
                    'GS_AccountWorkflowConversionService'
                )
            );
            thisLogger.dispatch();
        } finally {
            TriggerHandler.clearBypass('GS_ContactTriggerHandler');
            TriggerHandler.clearBypass('ContactTriggerHandler');
        }
    }
    
}
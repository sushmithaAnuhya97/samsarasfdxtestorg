/* 08/03/2021 - GTMS 4182 Logic added in If condition to cover scenario for 0 value. @Apisero team
 * 07/15/2021 - {GTMS-4069} Added Logic to populate CS POC fields from Biling details
 * 07/12/2021 Lavanya - (GTMS-4221) Separated the logic that updates CS record into a new method "stampAccountInfoOnCsRecord"
 * 06/28/2021 Agamani - (GTMS-4089) Added Account size segment=AE1 condition
 *06/15/2021 Agamani - (GTMS-3951) updated approved payment type logic for Canada
 * 05/12/2021 Agamani - (GTMS-3792) updated Number of vehicle condition to check less than 10 and ARR value less than 5000
 * 4/14/2021 Sai - (GTMS-3405) Configured CS Tier limits in Custom metadata
 * 04/01/21 Harsha - (GTMS-3271) Added logic for NAICS Hold
 * 02/24/21 Groundswell-Tanuj - (GTMS-3000/3006/3007/3008/3009/3010) Workflow Conversion Tickets
 * 08/09/20 Anil   - (GTMS-3070 ) Create Cs Record in the Update Transaction
 * 02/18/20 Harsha - (GTMS-2514)checkIfAccountNeedsCsmOrSeOnUpdate (Added logic for Pre_Sale_IC__c)
 * 09/30/2021 Dipen -(GTMS-4852) Update the criteria for Customer_ARR__c to incorporate Total Open Opp Expected Revenue
 * 09/30/2021 Gaurav -(GTMS-4848) Update Approved_Payment_Type__c as Direct Monthly for CA, AE1 Accounts.
 */
public class AccountHelper {
    static Boolean loadedStaticContacts = false;
    static Boolean updateCSRecord = false;
    static Map<Id, Contact> staticContactsMap = new Map<Id, Contact>();
    static Map<Id, Account> accountsChanged = new Map<Id, Account>();
    static List<Account_Sync_Event__e> accountSyncEvents = new List<Account_Sync_Event__e>();
    public static void afterInsertOperations(Map<Id, Account> oldAccountMap, List<Account> newAccountList){
        List<sObject> records = new List<sObject>();
        for(Account account : newAccountList){
            CS_Record__c CSRecord = new CS_Record__c();
            CSRecord.Account__c = account.Id;
            records.add(CSRecord);
        }
        if(records.size() > 0){
            DMLWrapper.doInsert(records);
        }
    }
    
    public static void beforeInsertUpdateOperations(Map<Id, Account> oldAccountMap, List<Account> newAccountList) {
        Map<ID, Schema.RecordTypeInfo> rt_Map = Account.sObjectType.getDescribe().getRecordTypeInfosById();
        Set<Id> ownerIds = new Set<Id>();
        Map<Id,Account> accountsWithCsmMap = new Map<Id,Account>();
        Map<Id,Account> accountsWithAssignCsmMap = new Map<Id,Account>();
        Map<Id, Account> accountsWithSICChanged = new Map<Id, Account>();
        Map<Id, Account> accountsWithCsmChangesMap = new Map<Id, Account>();
        Map<Id, Account> accountUpdateManagerEmail = new Map<Id, Account>();
        Map<Id, Account> accountEscalationOwnerName = new Map<Id, Account>();
        Map<Id, Account> accountToApproveSamsaraPreApprovalMap = new Map<Id, Account>();
        Map<Id, Account> accountToDeclineSamsaraPreApprovalMap = new Map<Id, Account>();
        Map<Id, Account> ownerRoleAccIds = new Map<Id, Account>();
        Boolean inIteration = false;
        List<Account> accountsChanged = new List<Account>();
        Map<String, NAICS_Code__mdt> nCodes = NAICS_Code__mdt.getAll();
        Map<String, CS_Tier_Limit__mdt> csTierMap = getCSTierlimits();
        Map<String,Shipping_Countries__mdt> countriesMap =  Shipping_Countries__mdt.getAll();
        Map<String, String> currencyMap = new Map<String, String>();
        //Build map with country code and currency
        for(Shipping_Countries__mdt country : countriesMap.values()){
            currencyMap.put(country.BillingCountryCode__c, country.Currency__c);
        }
        Integer counter = 0;
        /*GTMS-4848 Gaurav Sharma : To fetch the Levels of AccountOwners. Start*/
        Set<Id> accountOwnerIds = new Set<Id>();
        for(Account a : newAccountList) {
            accountOwnerIds.add(a.OwnerId);
        }
        Map<Id, User> accountOwners = new Map<Id, User>([
                SELECT Id, Email, FirstName, LastName, ADR_Assignment__c, Level__c
                FROM User
                WHERE Id IN :accountOwnerIds
        ]);
        /*GTMS-4848 Gaurav Sharma : Ends*/
        for(Account a : newAccountList) {
            //partnerAccountStatus(a);
            if(a.SAM_Number_Undecorated__c == null){
                String chars = '23456789ABCDEFGHJKMNPRSTUVWXYZ';
                String sam = 'C'; //All SAM numbers start with C
                for (Integer i=0;i<9; i++) { //generate 9 characters in addition to the beginning C
                    Integer charPos = Math.floor(Math.random() * chars.length()).intValue();
                    sam = sam + chars.substring(charPos,charPos+1);
                }
                a.sam_number_undecorated__c = sam;
            }
            Account oldAccount = new Account();
            if(oldAccountMap != NULL && oldAccountMap.size() >  0) {
                oldAccount = oldAccountMap.get(a.Id);
            }
            /*
            if((oldAccount == NULL && a.NAICS_Code__c != NULL) || a.NAICS_Code__c != oldAccount.NAICS_Code__c){
                String devCode = 'X'+a.NAICS_Code__c;
                if(nCodes.containsKey(devCode)){
                    a.NAICS_Hold__c = TRUE;
                }
                else{
                    a.NAICS_Hold__c = FALSE;                   
                }
            }
            */
            
             // Narmada  GTMS-4069
            If((a.CS_POC_Email_Address__c == null || a.CS_POC_First_Name__c == null || a.CS_POC_Phone__c == null) && a.First_Purchase_Date__c  >= system.today().addDays(-7)
               && (a.Billing_Email__c != NULL || a.Billing_First_Name__c != NULL || a.Billing_Phone__c != NULL) && a.ownerid == System.Label.SmallFleetAccountOwnerId){
                   a.CS_POC_Email_Address__c = a.Billing_Email__c;
                   a.CS_POC_First_Name__c  = a.Billing_First_Name__c; 
                   a.CS_POC_Phone__c  = a.Billing_Phone__c;
            }
            
            if((oldAccount == NULL || oldAccount.BillingCountryCode != a.BillingCountryCode) && a.BillingCountryCode == 'MX' && a.CurrencyISOCode != currencyMap.get(a.BillingCountryCode)) {
                a.CurrencyISOCode = currencyMap.get(a.BillingCountryCode);
            }
           
            
            if((oldAccount == NULL || oldAccount.RecordTypeId != a.RecordTypeId) && a.RecordTypeId != NULL) {
                a.Record_Type_Stamp_for_Dupes__c = rt_Map.get(a.RecordTypeId).getName();
            }
            if(oldAccount == NULL || oldAccount.Phone != a.Phone) {
                a.Normalized_Phone_Text__c = a.Normalized_Phone__c;
            }
            if(a.Send_to_My_ADR__c) {
                accountsChanged.add(a);
                ownerIds.add(a.OwnerId);
            }
            //Groundswell : Nilesh Jain - Owner Manager Email workflow changes.
            if((oldAccount.Id == null && a.OwnerId != null) || (oldAccount.Id != null && oldAccount.OwnerId != a.OwnerId)){
                accountUpdateManagerEmail.put(a.OwnerId, a);
                ownerIds.add(a.OwnerId);
            }
            if(oldAccount == NULL || oldAccount.OwnerId != a.OwnerId) {
                a.Account_Assignment_Date__c = Datetime.NOW();
                if (oldAccount != NULL) {
                    ownerIds.add(a.OwnerId);
                    ownerIds.add(oldAccount.OwnerId);
                    accountsChanged.add(a);
                }
            }
            if(oldAccount == NULL || oldAccount.Status__c != a.Status__c) {
                a.Account_Status_Changed__c = Datetime.NOW();
            }
            if(oldAccount.Credit_Pre_Approval_Status__c != a.Credit_Pre_Approval_Status__c) {
                a.Pre_Approval_Timestamp__c = Datetime.NOW();
            }
            if(oldAccount.Validation_Complete__c != a.Validation_Complete__c) {
                a.DVS_Assignment__c = UserInfo.getUserId();
                a.Validation_Complete_Date__c = Datetime.NOW();
            }
            
            //GTMS - 3179 Check if we can send the ACV value to Totango field when customer ARR is not available.
            //GTMS-4182/GTMS-4858 Condition added if it is 0 then it will allow to update the value
            if(((a.Customer_ARR__c == null && a.Lifetime_ACV_to_USD__c != null) || (a.Customer_ARR__c == 0 && a.Lifetime_ACV_to_USD__c != 0 && (a.First_Purchase_Date__c >= Date.today().addDays(-30) && a.First_Purchase_Date__c <= Date.today())))) {
                a.Customer_ARR__c = a.Lifetime_ACV_to_USD__c;
            }
            //GTMS-3350(Update Approved Payment type for AE1 to Direct Monthly if ARR>5K or no of vehicle>10)
            //GTMS-4852(Update the criteria for Customer_ARR__c to incorporate Total Open Opp Expected Revenue)
            /*Zakeer-GTMS-5394 Modifying the logic to set Type=Upfront*/
            if(a.Account_Size_Segment__c == System.label.AccountSizeSegment_AE1 && 
               (((oldAccount.Number_of_Vehicles__c != a.Number_of_Vehicles__c) && (a.Number_of_Vehicles__c != NULL) || oldAccount.Owner != a.Owner || oldAccount.Sites_Specialist__c != a.Sites_Specialist__c ))){            
               if((a.Sites_Specialist__c != NULL || a.Number_of_Vehicles__c > Integer.valueOf(System.Label.Number_of_Vehicle)) || ((a.Customer_ARR__c != Null) && (a.Customer_ARR__c >= Integer.valueOf(System.Label.Customer_ARR)))){
                   a.Approved_Payment_Type__c = 'Direct Monthly';
               }
               
               else if ((a.OwnerId == System.Label.SmallFleetAccountOwnerId && a.Sites_Specialist__c == NULL) || (a.Number_of_Vehicles__c <= Integer.valueOf(System.Label.Number_of_Vehicle) && a.Sites_Specialist__c == NULL && (a.First_Purchase_Date__c == NULL || a.First_Purchase_Date__c >= Date.valueof(System.label.First_Purchase_Date)))
                            || (a.Sites_Specialist__c == NULL && a.Number_of_Vehicles__c < Integer.valueOf(System.Label.Number_of_Vehicle) && (a.First_Purchase_Date__c == NULL || a.First_Purchase_Date__c >= Date.valueof(System.label.First_Purchase_Date) ))){
                        a.Approved_Payment_Type__c = 'Upfront Payments';
               }
            }
            
            //GTMS-3951
            if(trigger.isInsert && a.BillingCountryCode == 'CA' && a.Number_of_Vehicles__c<=20 ) {
                   a.Approved_Payment_Type__c = 'Direct Monthly';
            }
            //GTMS-4848 : Gaurav Sharma : Update Approved_Payment_Type__c as Direct Monthly for CA, AE1 Accounts. Change Starts
            if(a.BillingCountryCode == 'CA' && a.Account_Size_Segment__c == System.label.AccountSizeSegment_AE1 && accountOwners != Null && accountOwners.get(a.OwnerId).Level__c == 'AE 1'){
                a.Approved_Payment_Type__c = 'Direct Monthly';
            }
            //GTMS-4848 : Gaurav Sharma : Changes Ends
            
            // TODO - Move CSM to own object
            if(oldAccount.CSM_First_30d_Stage__c != a.CSM_First_30d_Stage__c) {
                if(a.CSM_First_30d_Stage__c == 'Pending Intro') {
                    a.CSM_Pending_Intro_Timestamp__c = Datetime.NOW();
                } else if(a.CSM_First_30d_Stage__c == 'Pending Delivery') {
                    a.CSM_Pending_Delivery_Timestamp__c = Datetime.NOW();
                } else if(a.CSM_First_30d_Stage__c == 'Attempting Training') {
                    a.CSM_Attempting_Training_Timestamp__c = Datetime.NOW();
                } else if(a.CSM_First_30d_Stage__c == 'Scheduled Training') {
                    a.CSM_Scheduled_Training_Timestamp__c = Datetime.NOW();
                } else if(a.CSM_First_30d_Stage__c == 'Health Check') {
                    a.CSM_Health_Check_Timestamp__c = Datetime.NOW();
                } else if(a.CSM_First_30d_Stage__c == 'Scheduled Additional Training') {
                    a.CSM_Scheduled_Add_Training_Timestamp__c = Datetime.NOW();
                } else if(a.CSM_First_30d_Stage__c == 'Initial onboarding completed') {
                    a.CSM_Initial_onboarding_completed_Time__c = Datetime.NOW();
                } else if(a.CSM_First_30d_Stage__c == 'Additional followup needed') {
                    a.CSM_Additional_followup_needed_TimeStamp__c = Datetime.NOW();
                }
            }
            if(a.Approved_Payment_Type__c == NULL) {
                a.Approved_Payment_Type__c = 'Direct Annual';
            }
            if(a.Lifetime_Purchases__c < 10000 && a.Lifetime_Purchases__c < oldAccount.Lifetime_Purchases__c && a.Approved_Payment_Type__c != 'Direct Monthly') {
                a.Approved_Payment_Type__c = 'Upfront Payments';
            }
            if(a.Lifetime_Purchases__c >= 10000 && a.Approved_Payment_Type__c == 'Upfront Payments') {
                a.Approved_Payment_Type__c = 'Direct Annual';
            }
             
            if ((a.Total_Purchased_VG_Count__c <=2
                    && a.Total_Purchased_AG_Count__c <=2
                    && a.Total_Purchased_CM_Count__c <=2
                    && a.Total_Purchased_EM_Count__c <=2
                    && (a.Number_of_Vehicles__c == null || a.Number_of_Vehicles__c <=2)
                    && a.Lifetime_Purchases__c > 0
                    && a.Record_Type_Stamp_for_Dupes__c == 'Fleet')
                    && !(oldAccount.Total_Purchased_VG_Count__c <=2
                    && oldAccount.Total_Purchased_AG_Count__c <=2
                    && oldAccount.Total_Purchased_CM_Count__c <=2
                    && oldAccount.Total_Purchased_EM_Count__c <=2
                    && (oldAccount.Number_of_Vehicles__c == null || oldAccount.Number_of_Vehicles__c <=2)
                    && oldAccount.Lifetime_Purchases__c > 0
                    && oldAccount.Record_Type_Stamp_for_Dupes__c == 'Fleet')) {
                a.Micro_Fleet_Support_Tier__c = true;
            } else if ((a.Micro_Fleet_Support_Tier__c
                    && (a.Total_Purchased_VG_Count__c >= 3
                    || a.Total_Purchased_AG_Count__c >= 3
                    || a.Total_Purchased_CM_Count__c >= 3
                    || a.Total_Purchased_EM_Count__c >= 3
                    || a.Number_of_Vehicles__c >= 3))
                    && !(oldAccount.Total_Purchased_VG_Count__c >= 3
                    || oldAccount.Total_Purchased_AG_Count__c >= 3
                    || oldAccount.Total_Purchased_CM_Count__c >= 3
                    || oldAccount.Total_Purchased_EM_Count__c >= 3
                    || oldAccount.Number_of_Vehicles__c >= 3)) {
                a.Micro_Fleet_Support_Tier__c = false;
            }
            
            if(!a.CS_Tier_Override__c) {
                Decimal arr = (a.Customer_ARR__c == 0 || a.Customer_ARR__c == null) ? a.Account_Lifetime_ACV__c : a.Customer_ARR__c;
                if((a.Customer_ARR__c == 0 || a.Customer_ARR__c == null) && (a.Account_Lifetime_ACV__c == 0 || a.Account_Lifetime_ACV__c == null)) {
                    a.CS_Tier__c = '';
                }
                if (arr >= csTierMap.get('Starter_limits').Min_Value__c && arr <= csTierMap.get('Starter_limits').Max_Value__c) {
                    a.CS_Tier__c = 'Starter';
                } else if (arr <= csTierMap.get('Plus_limits').Max_Value__c) {
                    a.CS_Tier__c = 'Plus';
                } else if (arr < csTierMap.get('Premier_Limits').Max_Value__c) {
                    a.CS_Tier__c = 'Premier';
                } else if (arr >= csTierMap.get('Elite_limits').Min_Value__c) {
                    a.CS_Tier__c = 'Elite';
                }
            }
            
            
             //* GTMS-2843, GTMS-2992 Update Delinquency Flows in SFDC --> to be deployed on May 6th 
            //* Author - Ron Saavedra --> Documentation: https://samsaradev.atlassian.net/wiki/spaces/BUS/pages/1421771034
            
            if(a.Delinquency_Threshold__c != 0){
                Finance_Setting__mdt financeSetting = Finance_Setting__mdt.getInstance(a.Segment__c.replace(' ', '_'));

                if((a.Segment__c == 'AE1' || a.Micro_Fleet_Support_Tier__c == TRUE) && a.Delinquent__c ){
                    a.Delinquency_Status__c = 'Orders Blocked';
                } else if(financeSetting != null && a.Delinquency_Threshold__c >= financeSetting.Upper_Delinquency_Threshold__c){
                    if(a.Segment__c != 'Enterprise') 
                        a.Delinquency_Status__c = financeSetting.Upper_Delinquency_Status__c;
                    else {
                        if(a.netsuite_conn__Days_Overdue__c > financeSetting.Days_over_due__c)
                            a.Delinquency_Status__c = financeSetting.Upper_Delinquency_Status__c;
                        else a.Delinquency_Status__c = '';
                    }
                } else if(financeSetting != null && a.Delinquency_Threshold__c >= financeSetting.Lower_Delinquency_Threshold__c){
                    if(a.Segment__c != 'Enterprise') 
                        a.Delinquency_Status__c = financeSetting.Lower_Delinquency_Status__c;
                    else {
                        if(a.netsuite_conn__Days_Overdue__c <= financeSetting.Days_over_due__c)
                            a.Delinquency_Status__c = financeSetting.Lower_Delinquency_Status__c;   
                        else a.Delinquency_Status__c = '';    
                    }  
                } else if(financeSetting != null && a.Delinquency_Threshold__c < financeSetting.Lower_Delinquency_Threshold__c){
                        a.Delinquency_Status__c = ''; 
                }
            }
            
            if(!a.Delinquent__c && oldAccount.Delinquent__c != a.Delinquent__c){
                a.Delinquency_Status__c = ''; 
            }
            
            
            //Groundswell : Nilesh Jain  - Changes done as a part of GTMS-2999 to Remove Account DML from checkIfAccountNeedsCsmOrSeOnUpdate
            if (a.Segment__c == 'Enterprise' && a.Owner_SE__c != null && a.SE_Assignment__c != a.Owner_SE__c) {
                a.SE_Assignment__c = a.Owner_SE__c;
            }
            //End
            // Groundswell-Tanuj (GTMS-3000)- Changes for Workflow Conversion

            // Start

            if(oldAccount.Id != null && a.CSM__c != null){
                accountsWithCsmMap.put(a.CSM__c, a);
                //leveraging existing user set to avoid duplicate queries in the logic below.
                ownerIds.add(a.CSM__c);
            }
            //Groundswell : Nilesh Jain - Uncheck Assign CSM workflow changes
            if(oldAccount.Id != null && oldAccount.Assign_CSM__c != a.Assign_CSM__c && a.Assign_CSM__c && a.CSM__c != null){
                accountsWithAssignCsmMap.put(a.CSM__c, a);
                ownerIds.add(a.CSM__c);
            }
            //End
            //Groundswell :  Nilesh Jain - Stamp CSM Name workflow changes
            if(oldAccount.Id != null && oldAccount.SIC__c != a.SIC__c && a.CSM__c != null){
                accountsWithSICChanged.put(a.CSM__c, a);
                ownerIds.add(a.CSM__c);
            }
            //End

            //Goundswell : Nilesh Jain - Stamp CSM Manager Email
           /* if((oldAccount.Id == null || (oldAccount.Id != null && oldAccount.CSM__c != a.CSM__c)) && a.CSM__c != null){
                accountsWithCsmChangesMap.put(a.CSM__c, a);
                ownerIds.add(a.CSM__c);
            }*/
            
            //Groundswell : Nilesh Jain - Update Support Escalation Owner Name changes
            if(oldAccount.Id != null && oldAccount.Support_Escalation_Owner__c != a.Support_Escalation_Owner__c
                    && a.Support_Escalation_Owner__c != null){
                accountEscalationOwnerName.put(a.Support_Escalation_Owner__c, a);
                ownerIds.add(a.Support_Escalation_Owner__c);
            }
            //End
            
            //Groundswell : Flavio Contini - Ensure Initiate_Round_Robin__c is always false when Account is a Partner
            if (a.Initiate_Round_Robin__c && rt_Map.get(a.RecordTypeId).getDeveloperName() == 'Partner'){
                a.Initiate_Round_Robin__c = false;
            }
            
            //WF Rule - Samsara Pre-Approval - Approve
            if(oldAccount.Id != null && a.OwnerId != null && oldAccount.Credit_Pre_Approval_Status__c != a.Credit_Pre_Approval_Status__c && a.Credit_Pre_Approval_Status__c == 'Approved'){
                ownerIds.add(a.OwnerId);
                accountToApproveSamsaraPreApprovalMap.put(a.OwnerId,a);
            }

            //WF Rule - Samsara Pre-Approval - Decline
            if(oldAccount.Id != null && a.OwnerId != null && oldAccount.Credit_Pre_Approval_Status__c != a.Credit_Pre_Approval_Status__c && (a.Credit_Pre_Approval_Status__c == 'Declined' || a.Credit_Pre_Approval_Status__c == 'Pending')){
                ownerIds.add(a.OwnerId);
                accountToDeclineSamsaraPreApprovalMap.put(a.OwnerId,a);
            }
            
            if(oldAccount.Id == NULL ) {
                AccountWorkflowConversion.beforeInsertRules(a);
            }
            AccountWorkflowConversion.beforeInsertUpdateRules(a, oldAccount);
            //Groundswell: Nilesh Jain - syncAccount changes
            if(oldAccount != null && oldAccount.Id != null){
                syncAccount(a, oldAccount);
            }
            //Groundswell Nilesh Jain : populateBillingDetails method changes
            if (oldAccount != null && oldAccount.Id != null && (a.Owner_Role__c != null) && (a.Owner_Role__c.contains('AE3') || a.Owner_Role__c.contains('AE2') || a.Owner_Role__c.contains('ENT') ||
                    a.Owner_Role__c.contains('IND')) && a.Billing_Contact__c != null &&
                    oldAccount.Billing_Contact__c != a.Billing_Contact__c) {
                ownerRoleAccIds.put(a.Billing_Contact__c, a);
            }
            //End
        }
        //Groundswell Nilesh Jain : populateBillingDetails method changes
        if (!ownerRoleAccIds.isEmpty()) {
            copyBillingInfo(ownerRoleAccIds);
        }
        //Query user details if owberIds set not null
        Map<Id, User> mapUsers = new Map<Id, User>(AccountWorkflowConversion.getAccountCsmMap(ownerIds));
        //Groundswell : Nilesh Jain - Uncheck Assign CSM workflow changes
        if(accountsWithAssignCsmMap != null && accountsWithAssignCsmMap.size() > 0){
            AccountWorkflowConversion.uncheckAssignCSM(accountsWithAssignCsmMap, mapUsers);
        }
        //End
        // Groundswell-Tanuj (GTMS-3000)- Changes for Workflow Conversion
        if(accountsWithCsmMap != null && accountsWithCsmMap.size() > 0){
            AccountWorkflowConversion.completeCsmOnboarding(accountsWithCsmMap, mapUsers);
        }
        // End
        //Groundswell : Nilesh Jain - Stamp CSM Name workflow changes
        if(accountsWithSICChanged != null && accountsWithSICChanged.size() > 0){
            AccountWorkflowConversion.stampCSMName(accountsWithSICChanged, mapUsers);
        }
        //End
        
        //Groundswell : Nilesh Jain - Stamp CSM Manager Email workflow changes
      /*  if(!accountsWithCsmChangesMap.isEmpty()){
            AccountWorkflowConversion.stampCSMManagerEmail(accountsWithCsmChangesMap, mapUsers);
        }*/
        
        //Groundswell : Nilesh Jain - Owner Manager Email workflow changes
        if(accountUpdateManagerEmail.size() > 0){
            AccountWorkflowConversion.stampOwnerManagerEmail(accountUpdateManagerEmail, mapUsers);
        }
        if(accountEscalationOwnerName.size() > 0){
            AccountWorkflowConversion.stampEscalationOwnerName(accountEscalationOwnerName, mapUsers);
        }
        if(accountToApproveSamsaraPreApprovalMap.size() > 0){
            AccountWorkflowConversion.preApproveSamsaraStatus(accountToApproveSamsaraPreApprovalMap, mapUsers);
        }

        if(accountToDeclineSamsaraPreApprovalMap.size() > 0){
            AccountWorkflowConversion.declinePreApproveSamsaraStatus(accountToDeclineSamsaraPreApprovalMap, mapUsers);
        }
        if (oldAccountMap != null) {
            //TODO - will be called recursively
            /*Map<Id, User> users = new Map<Id, User>([
                SELECT Email, FirstName, LastName, ADR_Assignment__c, Level__c
                FROM User
                WHERE Id IN :ownerIds
            ]);*/
            for (Account a : accountsChanged) {
                User u = mapUsers.get(a.OwnerId);
                a.Current_Owner_Email__c = u.Email;
                User oldU = mapUsers.get(oldAccountMap.get(a.Id).OwnerId);

                if (oldU != null) {
                    //TODO - follow-up with Dez or Latham
                    a.Previous_Owner_Email__c = oldU.Email;
                    a.Previous_Owner_Name__c = oldU.FirstName + ' ' + oldU.LastName;

                    if (oldU.LastName == 'Pool' && u.LastName != 'Pool' && a.Status__c != 'Delete') {
                        a.Status__c = 'Assigned';
                    }

                    // TODO - Re-evaluate if this assignment is necessary (check with James Choe)
                    if (a.Segment__c == 'Enterprise' && a.Owner_SE__c != null) {
                        a.SE_Assignment__c = a.Owner_SE__c;
                    }

                    // TODO - Re-evaluate if this assignment is necessary (check with James Choe)
                    if (a.Segment__c != 'Enterprise') {
                        a.SE_Assignment__c = null;
                    }

                    if(oldAccountMap.get(a.Id).Send_to_My_ADR__c != a.Send_to_My_ADR__c && a.Send_to_My_ADR__c) {
                        if(mapUsers.get(a.OwnerId).ADR_Assignment__c != null) {
                            if(a.Owner_Role__c.contains('AE3')) {
                                a.Original_Owner_for_Recycling_Campaign__c  = a.OwnerId;
                                a.ownerId = mapUsers.get(a.OwnerId).ADR_Assignment__c;
                                a.Send_to_My_ADR__c = false;
                            }
                            else if(a.Owner_Role__c.contains('ENT')) {
                                a.ownerId = mapUsers.get(a.OwnerId).ADR_Assignment__c;
                                a.Send_to_My_ADR__c = false;
                            }
                        }
                        else {
                            a.Send_to_My_ADR__c = false;
                        }

                    }
                }
            }
        }
    }
    
    /*public static void populateBillingDetails(Map<Id, Account> oldAccountMap, List<Account> newAccountList) {
        Map<Id, Account> ownerRoleAccIds = new Map<Id, Account>();
        for (Account account: newAccountList) {
            Account oldAccount = oldAccountMap.get(account.Id);
            if ((account.Owner_Role__c != null) && (account.Owner_Role__c.contains('AE3') || account.Owner_Role__c.contains('AE2') || account.Owner_Role__c.contains('ENT') ||
                    account.Owner_Role__c.contains('IND')) && account.Billing_Contact__c != null &&
                    oldAccount.Billing_Contact__c != account.Billing_Contact__c) {
                ownerRoleAccIds.put(account.Billing_Contact__c, account);
            }
        }
        if (!ownerRoleAccIds.isEmpty()) {
            copyBillingInfo(ownerRoleAccIds);
        }
    }*/
    public static void copyBillingInfo(Map<Id, Account> ownerRoleAccIds) {
        for (Contact con : [select Id, FirstName, LastName, Email, Phone from Contact
        where Id IN : ownerRoleAccIds.keySet()]) {
            if (ownerRoleAccIds.containsKey(con.Id)) {
                Account a = ownerRoleAccIds.get(con.Id);
                a.Billing_First_Name__c = con.FirstName;
                a.Billing_Last_Name__c = con.LastName;
                a.Billing_Phone__c = con.Phone;
                a.Billing_Email__c = con.Email;
            }
        }
    }
    
    public static void addAccountTeamMember(Account account, String teamRole){
        DMLWrapper.doInsert(new AccountTeamMember(AccountId=account.Id, UserId=account.Renewal_AE__c, TeamMemberRole=teamRole, AccountAccessLevel='Edit', CaseAccessLevel='None', OpportunityAccessLevel='Edit'));
    }
    
    /*//TODO - make this async (v1) & move to separate class (v2)
    public static void stampLawfulBasisOnAccountUpdate(List<Account> accounts){
        List<Contact> relatedContacts = new List<Contact>();
        List<Contact> contactsToUpdate = new List<Contact>();
        Set<Id> accountsToQuery = new Set<Id>();
        for(Account account : accounts) {
            if(HelperClass.euCountryCodes.contains(account.BillingCountryCode) && (account.Status__c == 'Existing Customer' || account.Type == 'Reseller Partner' || account.Type == 'Referral Partner')) {
                accountsToQuery.add(account.id);
            }
        }
        if(accountsToQuery.size()>0) {
            for (Contact thisContact : [SELECT Id, AccountId FROM Contact WHERE AccountId IN :accountsToQuery AND Associated_Lawful_Basis__c != 'Contract']) {
                thisContact.Associated_Lawful_Basis__c = 'Contract';
                //contactsToUpdate.add(contact);
                DMLWrapper.doUpdate(thisContact, new List<SObjectField>{
                        Contact.Associated_Lawful_Basis__c
                });
            }
        }
        /*try {
            if(contactsToUpdate.size() > 0) {
                update contactsToUpdate;
            }
        } catch(Exception e) {
            System.debug('There was an excetion when trying to update the contacts: ' + e);
        }
    }*/
    //TODO - CSM logic to remain in the class but move the enterprise segment to before insert + update
    //Method name can be generic in the future -@Harsha
    public static void stampLawfulBasisAndCheckIfAccountNeedsCsmOrSeOnUpdate(Map<Id, Account> oldAccountMap, List<Account> newAccountList) {
        Map<Id, Account> accountsToUpdate = new Map<Id,Account>();
        Set<Id> csAccountUpdates = new Set<Id>();
        Map<String, Object> params = new Map<String, Object>();
        Map<String, Object> newparams = new Map<String, Object>();
        Set<Id> accountsToQuery = new Set<Id>();
        for (Account newAccount : newAccountList) {
            Account oldAccount = oldAccountMap.get(newAccount.Id);
            //Groundswell : Nilesh Jain - stampLawfulBasisOnAccountUpdate changes
            if(HelperClass.euCountryCodes.contains(newAccount.BillingCountryCode) && (newAccount.Status__c == 'Existing Customer' || newAccount.Type == 'Reseller Partner' || newAccount.Type == 'Referral Partner')) {
                accountsToQuery.add(newAccount.id);
            }
            //Groundswell : Nilesh Jain  - Changes done as a part of GTMS-2999 to Remove Account DML from checkIfAccountNeedsCsmOrSeOnUpdate and move it to before method
            /*if (newAccount.Segment__c == 'Enterprise' && newAccount.Owner_SE__c != null && newAccount.SE_Assignment__c != newAccount.Owner_SE__c) {
                /*if(accountsToUpdate.containsKey(newAccount.Id)){
                    accountsToUpdate.get(newAccount.Id).SE_Assignment__c = newAccount.Owner_SE__c;
                }
                else{
                    accountsToUpdate.put(newAccount.Id, new Account(Id = newAccount.Id, SE_Assignment__c = newAccount.Owner_SE__c));
                }
                Account thisAccount = new Account(Id = newAccount.Id, SE_Assignment__c = newAccount.Owner_SE__c);
                DMLWrapper.doUpdate(thisAccount, new List<SObjectField>{
                        Account.SE_Assignment__c
                });
            }*/
            //End
            /*if(isChanged(newAccount, oldAccount, Schema.Account.Key_Stakeholder_for_CSM__c) ||
               isChanged(newAccount, oldAccount, Schema.Account.Key_Value_Points__c) ||
               isChanged(newAccount, oldAccount, Schema.Account.Upsell_Opportunity_Products__c) ||
               isChanged(newAccount, oldAccount, Schema.Account.AE_to_CSM_handoff_notes__c) ||
               isChanged(newAccount, oldAccount, Schema.Account.Preparedness_Rating__c) ||
               isChanged(newAccount, oldAccount, Schema.Account.Self_install_or_Vendor__c) ||
               isChanged(newAccount, oldAccount, Schema.Account.Did_they_Trial__c) ||
               isChanged(newAccount, oldAccount, Schema.Account.Feature_commits_CSM__c) ||
               isChanged(newAccount, oldAccount, Schema.Account.Pain_Points_Objections_during_the_trial__c)||
               isChanged(newAccount, oldAccount, Schema.Account.CS_POC_Email_Address__c) ||
               isChanged(newAccount, oldAccount, Schema.Account.CS_POC_First_Name__c) ||
               isChanged(newAccount, oldAccount, Schema.Account.Pre_Sale_IC__c) ||
               (isChanged(newAccount, oldAccount, Schema.Account.First_Purchase_Value__c) && oldAccount.First_Purchase_Value__c == null) ||
               isChanged(newAccount, oldAccount, Schema.Account.SIC__c)){
                csAccountUpdates.add(newAccount.Id);
            }*/
            if (oldAccount.Deactivation_Approval_Status__c != 'Approved' && newAccount.Deactivation_Approval_Status__c == 'Approved') {
                params.put('recordId', newAccount.Id);
            }
            
              //GTMS-3986 Downgrade Email Alert @Anil Bogadi 
           if (oldAccount.CSM_Health_Rating__c !=  newAccount.CSM_Health_Rating__c && newAccount.CSM_Health_Rating__c !=  'Green' && newAccount.CSM_Health_Rating__c != '--' && (oldAccount.CSM_Health_Rating__c != 'Red' && newAccount.CSM_Health_Rating__c !=  'Yellow')) {
                newparams.put('recordId', newAccount.Id);
            }       

        }
        //Groundswell : Nilesh Jain - stampLawfulBasisOnAccountUpdate changes
        if(accountsToQuery.size()>0) {
            for (Contact thisContact : [SELECT Id, AccountId FROM Contact WHERE AccountId IN :accountsToQuery AND Associated_Lawful_Basis__c != 'Contract']) {
                thisContact.Associated_Lawful_Basis__c = 'Contract';
                DMLWrapper.doUpdate(thisContact, new List<SObjectField>{
                        Contact.Associated_Lawful_Basis__c
                });
            }
        }
        //End
        if (params.size() > 0) {
            Flow.Interview.Delinquent_Opportunity_Creation flow = new Flow.Interview.Delinquent_Opportunity_Creation(params);
            flow.start();
        }
        
         //GTMS-3986 Downgrade Email Alert @Anil Bogadi 
         //GTMS-6752 Deactivating email alert and commenting due to gainsight issues @chinmaya Dash
       /* if (newparams.size() > 0) {
            Flow.Interview.Customer_Health_Downgraded_Email flow = new Flow.Interview.Customer_Health_Downgraded_Email(newparams);
            flow.start();
        }*/

        /*if(accountsToUpdate.size() > 0){
            update accountsToUpdate.values();
        }*/
    }
    
    public static void stampAccountInfoOnCsRecord(Map<Id, Account> oldAccountMap, List<Account> newAccountList) {
        Map<Id, Account> accountsToUpdate = new Map<Id,Account>();
        Set<Id> csAccountUpdates = new Set<Id>();
        Set<Id> accountsToQuery = new Set<Id>();
        if(!updateCSRecord){ 
            for (Account newAccount : newAccountList) {
                Account oldAccount = oldAccountMap.get(newAccount.Id);
                
                if((newAccount.Key_Stakeholder_for_CSM__c != oldAccount.Key_Stakeholder_for_CSM__c) ||
                        (newAccount.Key_Value_Points__c != oldAccount.Key_Value_Points__c) ||
                        (newAccount.Upsell_Opportunity_Products__c != oldAccount.Upsell_Opportunity_Products__c) ||
                        (newAccount.AE_to_CSM_handoff_notes__c != oldAccount.AE_to_CSM_handoff_notes__c) ||
                        (newAccount.Preparedness_Rating__c != oldAccount.Preparedness_Rating__c) ||
                        (newAccount.Self_install_or_Vendor__c != oldAccount.Self_install_or_Vendor__c) ||
                        (newAccount.Did_they_Trial__c != oldAccount.Did_they_Trial__c) ||
                        (newAccount.Feature_commits_CSM__c != oldAccount.Feature_commits_CSM__c) ||
                        (newAccount.Pain_Points_Objections_during_the_trial__c != oldAccount.Pain_Points_Objections_during_the_trial__c) ||
                        (newAccount.CS_POC_Email_Address__c != oldAccount.CS_POC_Email_Address__c) ||
                        (newAccount.CS_POC_First_Name__c != oldAccount.CS_POC_First_Name__c) ||
                           //(GTMS-3070) Create Cs Record in the Update Transaction - Anil Bogadi
                        (newAccount.Pre_Sale_IC__c != oldAccount.Pre_Sale_IC__c) ||
                        (newAccount.First_Purchase_Value__c != oldAccount.First_Purchase_Value__c && oldAccount.First_Purchase_Value__c == null) ||
                        (newAccount.SIC__c != oldAccount.SIC__c) ||
                  (newAccount.First_Purchase_Date__c != null && oldAccount.First_Purchase_Date__c != newAccount.First_Purchase_Date__c)){
                    csAccountUpdates.add(newAccount.Id);
                }
                
            }
            if(csAccountUpdates.size() > 0){
                updateCSRecord = true;
                UpdateRecordsForCS.updateRecords(csAccountUpdates);
            }
        }
    }
    public static void updateOpportunityOwnerBasedAccOwner(Map<Id, Account> oldAccountMap, List<Account> newAccountList) {
        if(oldAccountMap != null && oldAccountMap.size() > 0){
            Set<Id> setAccountIds = new Set<Id>();
            for(Account objAccount : newAccountList){
                if(objAccount.Ownerid != oldAccountMap.get(objAccount.Id).Ownerid){
                    setAccountIds.add(objAccount.Id);
                }
            }
            if(setAccountIds != null && setAccountIds.size() > 0){
                List<Opportunity> listOpportunities = new List<Opportunity>();
                for(Opportunity objopp : [Select id,Accountid,
                                                    Ownerid,Account.OwnerId 
                                                    from Opportunity where AccountId in: setAccountIds 
                                                    and (LeadSource='Partner business registration' or LeadSource='Deal Reg Form' or LeadSource='Partner referral')]){
                    if(objopp.Accountid != null && objopp.Ownerid != objopp.Account.Ownerid){
                        objopp.Ownerid = objopp.Account.Ownerid;
                        listOpportunities.add(objopp);
                    }
                }
                if(listOpportunities != null && listOpportunities.size() > 0)
                    Update listOpportunities;
            }
        }
    }
    
    //Method to check if the values are changed -@Harsha
    public static Boolean isChanged(Account newAccount, Account oldAccount, Schema.SObjectField field){
        if(oldAccount == null){
            return true;
        }else if(newAccount.get(field) != oldAccount.get(field)){
            return true;
        }else{
            return false;
        }
    }
    
    //Method returns limits for CS_Tier
    public static Map<String, CS_Tier_Limit__mdt> getCSTierlimits(){
        Map<String, CS_Tier_Limit__mdt> csTierMap = CS_Tier_Limit__mdt.getAll();
        return csTierMap;
    }
    
    // Changes for Mulesoft Project -@Harsha
    /*public static void beforeUpdateOperations(Map<Id, Account> oldAccountMap, List<Account> newAccountList) {
        for (Account account: newAccountList) {
            Account oldAccount = oldAccountMap.get(account.Id);
            syncAccount(account, oldAccount);
        }
    }*/
    public static void syncAccount(Account newAccount, Account oldAccount){
        Boolean changeFlag = criteriaCheck(newAccount, oldAccount);
        if(changeFlag && !((isChanged(newAccount, oldAccount, Schema.Account.Push_to_Netsuite__c) && (isChanged(newAccount, oldAccount, Schema.Account.Sync_in_Progress__c)))) &&
                (oldAccount.Push_to_Netsuite__c == false && oldAccount.Sync_in_Progress__c == false) && (oldAccount.Netsuite_Id__c != null || newAccount.Push_to_Netsuite__c == true)){
            newAccount.Push_to_Netsuite__c = true;
            newAccount.Sync_in_Progress__c = true;
            accountSyncEvents.add(new Account_Sync_event__e(Id__c = newAccount.Id));
        }
    }
    public static void createPlatformEvent(){
        if(accountSyncEvents.size() > 0){
            List<Database.SaveResult> results = EventBus.publish(accountSyncEvents);
        }
    }
    public static Boolean criteriaCheck(Account newAccount, Account oldAccount){
        //Groundwell : Nilesh Jain: Moved from isChanged to direct comparision as apart of GTMS-2874
        if((newAccount.Type != oldAccount.Type) ||
                (newAccount.Name != oldAccount.Name) ||
                (newAccount.OwnerId != oldAccount.OwnerId) ||
                (newAccount.Phone != oldAccount.Phone) ||
                (newAccount.Website != oldAccount.Website) ||
                (newAccount.Industry != oldAccount.Industry) ||
                (newAccount.NumberOfEmployees != oldAccount.NumberOfEmployees) ||
                (newAccount.SAM_Number_Undecorated__c != oldAccount.SAM_Number_Undecorated__c) ||
                (newAccount.Express_Deals_Counter__c != oldAccount.Express_Deals_Counter__c) ||
                (newAccount.Billing_Stripe_Customer_Id__c != oldAccount.Billing_Stripe_Customer_Id__c) ||
                (newAccount.VATId__c != oldAccount.VATId__c) ||
                (newAccount.Tax_Exempt__c != oldAccount.Tax_Exempt__c) ||
                (newAccount.Segment_Text_stamped__c != oldAccount.Segment_Text_stamped__c) ||
                (newAccount.New_Billing_Process_Approved__c != oldAccount.New_Billing_Process_Approved__c) ||
                (newAccount.Billing_Email__c != oldAccount.Billing_Email__c) ||
                (newAccount.First_Purchase_Date__c != oldAccount.First_Purchase_Date__c) ||
                (newAccount.Payment_Token__c != oldAccount.Payment_Token__c) ||
                (newAccount.Which_written_language__c != oldAccount.Which_written_language__c) ||
                (newAccount.CSM_Health_Rating__c != oldAccount.CSM_Health_Rating__c) ||
                (newAccount.CSM_Health_Notes__c != oldAccount.CSM_Health_Notes__c) ||
                (newAccount.Sentiment_Root_Cause__c != oldAccount.Sentiment_Root_Cause__c) ||
                (newAccount.Quarantine_Enabled_At__c != oldAccount.Quarantine_Enabled_At__c) ||
                (newAccount.Quarantine_Enabled__c != oldAccount.Quarantine_Enabled__c) ||
                (newAccount.Organization_Size__c != oldAccount.Organization_Size__c) ||
                (newAccount.Number_of_Students__c != oldAccount.Number_of_Students__c) ||
                (newAccount.Number_of_Citizens__c != oldAccount.Number_of_Citizens__c) ||
                (newAccount.Enterprise_Assignment__c != oldAccount.Enterprise_Assignment__c) ||
                (newAccount.Number_of_Vehicles__c != oldAccount.Number_of_Vehicles__c) ||
                (newAccount.Number_of_Unpowered_Assets__c != oldAccount.Number_of_Unpowered_Assets__c) ||
                (newAccount.Number_of_Powered_Assets__c != oldAccount.Number_of_Powered_Assets__c) ||
                (newAccount.BillingAddress != oldAccount.BillingAddress) ||
                (newAccount.Billing_Contact__c != oldAccount.Billing_Contact__c) ||
                (newAccount.netsuite_conn__Credit_Limit__c != oldAccount.netsuite_conn__Credit_Limit__c) ||
                (newAccount.Push_to_Netsuite__c != oldAccount.Push_to_Netsuite__c)){
            return true;
        }
        else{
            return false;
        }
        /*if((isChanged(newAccount, oldAccount, Schema.Account.Type)) ||
                (isChanged(newAccount, oldAccount, Schema.Account.Name)) ||
                (isChanged(newAccount, oldAccount, Schema.Account.OwnerId)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.Phone)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.Website)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.Industry)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.NumberOfEmployees)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.SAM_Number_Undecorated__c)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.Express_Deals_Counter__c)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.Billing_Stripe_Customer_Id__c)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.VATId__c)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.Tax_Exempt__c)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.Segment_Text_stamped__c)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.New_Billing_Process_Approved__c)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.Billing_Email__c)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.First_Purchase_Date__c)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.Payment_Token__c)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.Which_written_language__c)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.CSM_Health_Rating__c)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.CSM_Health_Notes__c)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.Sentiment_Root_Cause__c)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.Number_of_Vehicles__c)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.Quarantine_Enabled_At__c)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.Quarantine_Enabled__c)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.Quarantine_Enabled_At__c)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.Organization_Size__c)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.Number_of_Students__c)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.Number_of_Citizens__c)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.Enterprise_Assignment__c)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.Number_of_Vehicles__c)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.Number_of_Unpowered_Assets__c)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.Number_of_Powered_Assets__c)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.BillingAddress)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.Billing_Contact__c)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.netsuite_conn__Credit_Limit__c)) ||
            (isChanged(newAccount, oldAccount, Schema.Account.Push_to_Netsuite__c))){
              return true;
          }
          else{
                return false;
          }*/
        //End : Groundwell : Nilesh Jain: Moved from isChanged to direct comparision as apart of GTMS-2874
    }
    public static void beforeDeleteOperations(List<Account> newAccountList) {
        if(newAccountList.size() > 0){
            Set<Id> accountIds = new Set<Id>();
            List<CS_Record__c> csRecords = new List<CS_Record__c>();
            for(Account account : newAccountList){
                accountIds.add(account.Id);
            }
            csRecords = [SELECT Id FROM CS_Record__c WHERE Account__c IN :accountIds];
            if(csRecords.size() > 0) {
                //delete csRecords;
                DMLWrapper.doDelete(csRecords);
            }
        }
    }
    // Logic to update partner fields for Industrial
    //  * 5/19/20 Harsha - (GTMS-776) beforeCopyFields, partnerAccountStatus (Added new functionality to update partner fields for Industrial)
    /* private static void partnerAccountStatus(Account newAccount){
        if((newAccount.Business_Unit__c == 'Industrial') && (newAccount.Record_Type__c == 'Partner')){
            if((newAccount.Partner_Status__c == 'Authorization') &&
               (newAccount.Partner_Agreement_Accepted__c != null) &&
                (newAccount.Resale_Certificate_Date__c != null) &&
                (newAccount.W_9_Date__c != null) &&
                (newAccount.Credit_Authorization_Date__c != null) &&
                (newAccount.Tax_Exempt__c == true)){
                  newAccount.Partner_Status__c = 'Onboarding';
                  newAccount.Partner_Authorization_Date__c = system.today();
            }
            if((newAccount.Partner_Status__c == 'Prospect') &&
                ((newAccount.First_Demo_Date__c != null) ||
                 (newAccount.Application_Submitted__c != null))){
                    newAccount.Partner_Status__c = 'Application';
            }
        }
    }*/
    /*
// load static contacts for use throughout the whole class
public static void loadStaticContactsMap(Set<Id> accounts) {
    if(!loadedStaticContacts && accounts.size() > 0) {
        staticContactsMap = new Map<Id, Contact>([  SELECT  Id,
                                                            OwnerId,
                                                            Account.OwnerId,
                                                            Associated_Lawful_Basis__c
                                                    FROM Contact
                                                    WHERE AccountId IN :accounts]);
        loadedStaticContacts = true;
    }
}
// used multiple times throughout the class - set up method for calling logic
public static void loadAccountOwnerChanged(List<Account> accounts, Map<Id, Account> oldAccountByIdSerialized){
    for(Account a : accounts){
        Account oldAccount = oldAccountByIdSerialized.get(a.Id);
        if(a.OwnerId <> oldAccount.OwnerId){
            accountsChanged.put(a.Id, a);
        }
    }
}
*/
/*
    public static void updateContactOwner(List<Account> accounts, Map<Id,Account> oldAccountById) {
        Map<Id,Account> accountById = new Map<Id,Account>(accounts);
        String oldAccountByIdSerialized = JSON.serialize(oldAccountById);
        if (System.isFuture() || System.isScheduled() || System.isQueueable() || System.isBatch()) {
            AccountHelper.updateContactOwnerSync(accountById.keySet(), oldAccountByIdSerialized);
        } else{
            AccountHelper.updateContactOwnerAsync(accountById.keySet(), oldAccountByIdSerialized);
        }
    }
    @future
    public static void updateContactOwnerAsync(Set<Id> newAccountSet, String oldAccountByIdSerialized){
        List<Account> accounts = [SELECT Id, OwnerId FROM Account WHERE Id IN : newAccountSet];
        List<Contact> contactsToUpdate = new List<Contact>();
        Map<Id,Account> oldAccountById = (Map<Id,Account>)JSON.deserialize(oldAccountByIdSerialized, Map<Id,Account>.class);
        loadStaticContactsMap(newAccountSet);
        loadAccountOwnerChanged(accounts, oldAccountById);
        if(staticContactsMap.size() > 0){
            for(Contact c : staticContactsMap.values()){
                System.debug(LoggingLevel.INFO, 'acctsWhoseOwnerChanged Size = '+accountsWhoseOwnerChanged.size());
                if(accountsWhoseOwnerChanged.size() > 0){
                    if(accountsWhoseOwnerChanged.containsKey(c.AccountId)){
                        c.OwnerId = c.Account.OwnerId;
                        contactsToUpdate.add(c);
                    }
                }
            }
        }
        if(contactsToUpdate.size() > 0){
            update contactsToUpdate;
        }
    }
    public static void updateContactOwnerSync(Set<Id> newAccountSet, String oldAccountByIdSerialized){
        List<Account> accounts = [SELECT Id, OwnerId FROM Account WHERE Id IN : newAccountSet];
        List<Contact> contactsToUpdate = new List<Contact>();
        Map<Id,Account> oldAccountById = (Map<Id,Account>)JSON.deserialize(oldAccountByIdSerialized, Map<Id,Account>.class);
        loadStaticContactsMap(newAccountSet);
        loadAccountOwnerChanged(accounts, oldAccountById);
        if(staticContactsMap.size() > 0){
            for(Contact c : staticContactsMap.values()){
                System.debug(LoggingLevel.INFO, 'acctsWhoseOwnerChanged Size = '+accountsWhoseOwnerChanged.size());
                if(accountsWhoseOwnerChanged.size() > 0){
                    if(accountsWhoseOwnerChanged.containsKey(c.AccountId)){
                        c.OwnerId = c.Account.OwnerId;
                        contactsToUpdate.add(c);
                    }
                }
            }
        }
        if(contactsToUpdate.size() > 0){
            update contactsToUpdate;
        }
    }
    */
    //TODO - deprecate internal finance logic but keep VAT logic (v1)
    // Added the VAT logic to update the Opportunity when ever its changed on the Account.
    /* private static List<Opportunity> oppList;
       public static void updateOpenChildOpportunities(Map<Id, Account> oldAccountMap, Map<Id, Account> newAccountsMap) {
        // Called from Account afterUpdate trigger
        // Updates all open child opportunities, if necessary and if possible
        Account newAccount = new Account();
        Set<Id> accountIdsForSync = new Set<Id>();
        List<Opportunity> oppUpdateList = new List<Opportunity>();
        List <String> currencyList = new List <String> {'USD', 'CAD', 'MXN'};
            if(oldAccountMap != NULL) {
            for(Account a : oldAccountMap.values()) {
                newAccount = newAccountsMap.get(a.Id);
                    system.debug('Account Curreny '+newAccount.CurrencyIsoCode);
                  system.debug('Account VATId__c '+newAccount.VATId__c);
                if(a.VATId__c != newAccount.VATId__c) {
                    accountIdsForSync.add(newAccount.Id);
                }
            }
        }
        if (oppList == null) {
            oppList = new List<Opportunity>([  SELECT   AccountId, VAT_Number__c,
                                              FROM Opportunity
                                              WHERE AccountId IN :accountIdsForSync
                                               AND Probability < 95
                                               AND Type = 'Revenue Opportunity'
                                                AND CurrencyIsoCode not in: currencyList]);
        }
        system.debug(LoggingLevel.INFO, 'oppList size:'+oppList.size());
        for(Opportunity o : oppList) {
            newAccount = newAccountsMap.get(o.AccountId);
            Boolean changeFlag = false;
            if(o.VAT_Number__c != newAccount.VATId__c){
               o.VAT_Number__c =  newAccount.VATId__c;
               changeFlag = true;
            }
            if(changeFlag == true){
               oppUpdateList.add(o);
            }
        }
        if(oppUpdateList.size() > 0) {
            update oppUpdateList;
        }
    }*/
/*
    public static void checkForAccountSync(List<Account> accounts, Map<Id, Account> oldAccountMap) {
       String jobId = System.enqueueJob(new AccountSyncCheck(accounts, oldAccountMap));
       System.debug(jobId);
    }
    public static void syncAccounts(List<Account> accounts) {
        for(Account account: accounts){
            if(account.Sync_in_Progress__c){
                System.debug('sync account ' + account.id);
                integrator_da__.RealTimeExportResult result = integrator_da__.RealTimeExporter.run();
                System.debug(result);
            }
        }
    }
*/
    
    public static void updateADRAssignmentFromBooks(Map<Id, Account> oldAccountMap, List<Account> newAccountList) {
        Set<Id> newBookIds = new Set<Id>();
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
        Set<Id> accountsToProcess = new Set<Id>();
        for (Account newAcc : newAccountList) {
            Account oldAcc = oldAccountMap != null ? oldAccountMap.get(newAcc.Id) : null;
            if (oldAcc == null) {
                if (String.isNotBlank(newAcc.Books_Of_Business__c)) {
                    newBookIds.add(newAcc.Books_Of_Business__c);
                } 
            }
            else if (newAcc.Books_Of_Business__c != oldAcc.Books_Of_Business__c) {
                accountsToProcess.add(newAcc.Id);
                if (String.isNotBlank(newAcc.Books_Of_Business__c)) {
                    newBookIds.add(newAcc.Books_Of_Business__c);
                    accountsToUpdate.put(newAcc.Id, newAcc);
                } else {
                    newAcc.ADRAssignment__c = null;
                }
            }
        }
        if (!newBookIds.isEmpty()) {
            Map<Id, Book_Of_Business__c> bookMap = new Map<Id, Book_Of_Business__c>([
                SELECT Id, ADR__c 
                FROM Book_Of_Business__c 
                WHERE Id IN :newBookIds
            ]);
            for (Account acc :(oldAccountMap == null ? newAccountList: accountsToUpdate.values())) {
                Book_Of_Business__c newBook = bookMap.get(acc.Books_Of_Business__c);
                if (newBook != null) {
                    acc.ADRAssignment__c = newBook.ADR__c;
                } 
            }
        }
        if (!accountsToProcess.isEmpty()) {
            try {if (!System.isBatch() && !System.isFuture() && !System.isQueueable()){
                Database.executeBatch(new ContactADRAssignmentBatch(accountsToProcess), Integer.valueOf(System.Label.ContactADRAssignmentBatchJobSize));
            }
                } catch (Exception e) {
                    System.debug(LoggingLevel.ERROR, 'Error initiating contact update batch: ' + e.getMessage());
                    System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
                }
        } 
    }
}
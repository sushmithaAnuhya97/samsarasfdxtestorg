/*
* Title: AccountWorkflowConversion
* Description: Class to house all the converted Account workflows
* Created: Feb 23, 2021
* May/19 -Zakeer - GTMS-12328 - added logic for DUNS_Number__c
* 02/23/21 Groundswell-Tanuj - (GTMS-3006) Populate default CPQ Managed Package Fields
* 02/23/21 Groundswell-Tanuj - (GTMS-3007) CSM Onboarding Complete(CSM Status is moved to Onboarding Complete, Account Management, or First 30d Stage is marked Initial Onboarding Complete)
* 02/24/21 Groundswell-Tanuj - (GTMS-3008) Delinquent Timestamp
* 02/24/21 Groundswell-Tanuj - (GTMS-3009) Clear Delinquent Timestamp
* 02/24/21 Groundswell-Tanuj - (GTMS-3010) Unload Account True
* 02/24/21 Groundswell-Tanuj - (GTMS-3011) Update Global Geography field based on states / province and billing country
* 08/03/21 Anil Bogadi       - (GTMS 3986) Update CS Downgrade Email Alert
* 10/10/21 Gaurav Sharma     - (GTMS-4792) Added criteria to update the Deactivation date on Current Churn_Payment_Status
* April-29-2022 Rajesh       - (GTMS-6917) Commented Delinquency logic for the field Delinquent_As_Of__c
* November-4-2022 Rodrigo    - (GTMS-9700) added null check
*December-14-2022 Chinmaya   -(GTMS-10718) added null check
*/

public without sharing class AccountWorkflowConversion {

    public static void beforeInsertRules(Account newAccount){
        insertDefaultCPQManagedPackageFields(newAccount);
    }

    public static void beforeInsertUpdateRules(Account newAccount, Account oldAccount){
        combinedWorkflows(newAccount, oldAccount);
        updateSupportPhoneFields(newAccount, oldAccount);
        updateZendeskFields(newAccount, oldAccount);
        allDelinquencyWorkflows(newAccount, oldAccount);
        //Update Global Geography field based on states / province and billing country
        //updateGlobalGeography(newAccount, oldAccount);
    }

    //Populate default CPQ Managed Package Fields
    public static void insertDefaultCPQManagedPackageFields(Account newAccount){
        newAccount.SBQQ__CoTerminationEvent__c = Label.PicklistValueAsNone;
        newAccount.SBQQ__ContractCoTermination__c = Label.PicklistValueAsNone;
        newAccount.SBQQ__RenewalModel__c = Label.ContractBasedValue;
        newAccount.SBQQ__RenewalPricingMethod__c = Label.SameValue;
    }
      // Populate CSM fields once CSM Onboarding Completes
   public static void completeCsmOnboarding(Map<Id,Account> accountsWithCsmMap, Map<Id, User> accountCsmMap){
        //Map<Id, User> accountCsmMap = getAccountCsmMap(accountsWithCsmMap.keyset());
        for(Account newAccount : accountsWithCsmMap.values()){
            if(newAccount.CSM_Initial_onboarding_completed_Time__c == null &&
                    ((newAccount.CSM_Sub_Status__c != null && newAccount.CSM_Sub_Status__c.equals(Label.Onboarding_Complete)) || (newAccount.CSM_Status__c != null && newAccount.CSM_Status__c.equals(Label.Account_Management) && newAccount.CSM_Sub_Status__c != null && (!(newAccount.CSM_Sub_Status__c.equals(Label.UnresponsiveValue) || newAccount.CSM_Sub_Status__c.equals(Label.Disqualified)))) || (newAccount.CSM_First_30d_Stage__c != null && newAccount.CSM_First_30d_Stage__c.equals(Label.Initial_onboarding_complete)))){
                newAccount.CSM_Initial_onboarding_completed_Time__c = system.now();
                newAccount.CSM_who_completed_onboarding__c = accountCsmMap.get(newAccount.CSM__c).Manager.FirstName+' '+accountCsmMap.get(newAccount.CSM__c).Manager.LastName+' - '+accountCsmMap.get(newAccount.CSM__c).FirstName+' '+accountCsmMap.get(newAccount.CSM__c).LastName;
            }
        }
    }

    public static void combinedWorkflows(Account newAccount, Account oldAccount){
        // Get all Metadata records
        Map<String,Shipping_Countries__mdt> countriesMap =  Shipping_Countries__mdt.getAll();
        Map<String, String> languageMap = new Map<String, String>();
        //Build map with country code and language
        for(Shipping_Countries__mdt country : countriesMap.values()){
            languageMap.put(country.BillingCountryCode__c, country.Language__c);
        }

        //Unload Account True
        if(newAccount.Unload_Account__c){
            newAccount.Unload_Account__c = false;
        }

        //Change Sub Industry based on Industry workflow and Industry for Educational workflow
        /* Commenting below as part of GTMS-8148
        if(newAccount.Industry == 'Government' || newAccount.Industry == 'Government - Outside US/CA' || newAccount.Industry == 'Tribe/Nation'){
            newAccount.Sub_Industry__c = 'Government - Unclassified';
        }else if(newAccount.Industry == 'Educational Services'){
            newAccount.Sub_Industry__c = 'Education - Unclassified';
        }*/

        //Suspension Activate Workflow
        if((oldAccount.id == null || (oldAccount.id != null && oldAccount.Quarantine_Enabled__c != newAccount.Quarantine_Enabled__c))
            && newAccount.Quarantine_Enabled__c){
             newAccount.Actual_Deactivate_Date__c = System.today();
        }

        // WF Rule - Territory Field Update
        if(newAccount.Record_Type_Stamp_for_Dupes__c == Label.RecordTypeStampForDupesIndustrial && (newAccount.Industry != oldAccount.Industry || newAccount.BillingPostalCode != oldAccount.BillingPostalCode 
            || newAccount.BillingCountryCode != oldAccount.BillingCountryCode 
            || newAccount.BillingStateCode != oldAccount.BillingStateCode)){
             newAccount.Initiate_Round_Robin__c = true;
         }

         // WF Rule - Account: Segment
         //This text field brings in the Segment value from the
         //formula field: Segment (by Current owner) field on the account.
 
         if(newAccount.OwnerId != oldAccount.OwnerId 
            || String.isBlank(newAccount.Segment_Text_stamped__c)){
             newAccount.Segment_Text_stamped__c = newAccount.Segment__c;
         }

        //Groundswell : Nilesh Jain - Small fleets timestamp workflow changes.
        if((oldAccount.Id == null || (oldAccount.Id != null
                && (oldAccount.Micro_Fleet_Support_Tier__c != newAccount.Micro_Fleet_Support_Tier__c ||
                oldAccount.Small_Fleets_Engagement_Date__c != newAccount.Small_Fleets_Engagement_Date__c)))
                && newAccount.Micro_Fleet_Support_Tier__c && newAccount.Small_Fleets_Engagement_Date__c == null){
            newAccount.Small_Fleets_Engagement_Date__c = System.now();
        }

        // WF Rule - Account: Microfleet new billing
        // This workflow is to automatically check that an account is a part of the new billing process if it is a microf-fleet account
        if((oldAccount.Id != null && oldAccount.Micro_Fleet_Support_Tier__c != newAccount.Micro_Fleet_Support_Tier__c)
           && newAccount.Micro_Fleet_Support_Tier__c == true){
            //Update New Billing Process Approved checkbox
            newAccount.New_Billing_Process_Approved__c = true;
        }
        
        // WF Rule - Enrichment Complete Date Stamp
        // Stamps an account with a date when it meets DVS Enrichment Standards
        if((oldAccount.Id == null || oldAccount.Id != null && oldAccount.Enrichment_Complete__c != newAccount.Enrichment_Complete__c)
            && newAccount.Enrichment_Complete__c == true){
            newAccount.Enrichment_Complete_Date__c = system.today();
        }
        
         //Groundswell : Nilesh Jain - Default US companies to English workflow changes
        //Stamp whichwrittenlanguage from metadata.
        if(languageMap.get(newAccount.BillingCountryCode) != Null && newAccount.Which_written_language__c == null) 
            newAccount.Which_written_language__c = languageMap.get(newAccount.BillingCountryCode);
        //End
        
        //Groundswell : Nilesh Jain - Stamp Date of NPS Change workflow changes
        if(oldAccount.Id != null && oldAccount.DelightedInc__NPS__c != newAccount.DelightedInc__NPS__c){
           newAccount.Stamp_Delighted_Score_Date_Change__c = System.now();    
        }
        //End
        
        // WF Rule - AG Upsell Updates Made?
        if(oldAccount.Id != null && oldAccount.Current_Trailer_Telematics_Provider__c != newAccount.Current_Trailer_Telematics_Provider__c 
            || oldAccount.Current_Construction_Equip_Telematics__c != newAccount.Current_Construction_Equip_Telematics__c
            || oldAccount.Description != newAccount.Description
            || oldAccount.Number_of_Powered_Assets__c != newAccount.Number_of_Powered_Assets__c){
                newAccount.AG_Upsell_Updates__c = true;
            }
        
        // Wf Rule - Switch Account Status to Closed Lost Opportunity   
        if(oldAccount.Id != null 
            && oldAccount.Closed_Lost_Account__c != newAccount.Closed_Lost_Account__c 
            && newAccount.Closed_Lost_Account__c){
                newAccount.Status__c = 'Closed Lost Opportunity';
        }
        //Zakeer - GTMS-12328-May24
        if( String.isNotBlank(newAccount.DUNS_Number__c) && newAccount.DUNS_Number__c.length() < 9 ){
            newAccount.DUNS_Number__c = newAccount.DUNS_Number__c.leftPad(9, '0');
        }
    }

    //Groundswell : Nilesh Jain - Support phone field related workflow changes
    public static void updateSupportPhoneFields(Account newAccount, Account oldAccount){
        //Groundswell : Nilesh Jain - s0 - Set Support Phone number workflow changes.
        if(oldAccount.Id != null && (newAccount.Support_Priority__c == 's0' || newAccount.Support_Priority__c == 's1')){
            newAccount.Support_Phone_Number__c = System.label.Workflow_s0;
        }else if(oldAccount.Id != null && newAccount.Support_Priority__c != 's0' && newAccount.Support_Priority__c != 's1' && newAccount.Segment__c == 'AE1'){
            newAccount.Support_Phone_Number__c = System.label.Workflow_SMB; // SMB workflow
        }else if(oldAccount.Id != null && newAccount.Support_Priority__c != 's0' && newAccount.Support_Priority__c != 's1' && newAccount.Segment__c != 'AE1'){
            newAccount.Support_Phone_Number__c = System.label.Workflow_MidMKT; //Mid Mkt workflow
        }
    }
    //End
    //Groundswell : Nilesh Jain - Zendesk fields related workflow changes
    public static void updateZendeskFields(Account newAccount, Account oldAccount){
        //Groundswell : Nilesh Jain - Generate Zendesk Unique Account Name workflow changes.
        if((oldAccount.Id == null && newAccount.Name != null) || (oldAccount.Id != null && oldAccount.Name != newAccount.Name)){
            String samNumberDecorated = newAccount.SAM_Number_Undecorated__c.left(1) + '-' + newAccount.SAM_Number_Undecorated__c.mid(1,3) + '-' + newAccount.SAM_Number_Undecorated__c.mid(4,3) + '-' + newAccount.SAM_Number_Undecorated__c.mid(7,3);
            newAccount.Zendesk_Account_Name_Text__c = newAccount.Name + '_' + samNumberDecorated;
        }
        //Groundwell : Nilesh Jain - Update Zendesk Tags worfklow changes.
        if(oldAccount.Id == null || (oldAccount.Id != null && (oldAccount.Support_Priority__c != newAccount.Support_Priority__c
                || oldAccount.CSM_Notes__c != newAccount.CSM_Notes__c))){
            //BillingCountry value is not passed in before trigger, only billingCountryCode value is received.
            String billingCountry = BillingCountryCodeUtil.getBillingCountry(newAccount.BillingCountryCode);
            newAccount.Zendesk_Tags__c = 'Account_' + newAccount.Support_Priority__c + ', ' + billingCountry;
        }
    }
    //End
    //Groundswell : Nilesh Jain - Uncheck Assign CSM workflow changes
    public static void uncheckAssignCSM(Map<Id,Account> accountsWithCsmMap, Map<Id, User> accountCsmMap){
        for(Account newAccount : accountsWithCsmMap.values()){
            newAccount.Assign_CSM__c = false;
            newAccount.CSM_Manager_Email__c = accountCsmMap.get(newAccount.CSM__c).Manager.Email;
        }
    }
    //End
    
    //Groundswell : Nilesh Jain - Stamp CSM Manager Email workflow changes 
    // GTMS - 3986: Update CS Downgrade Email Alert - Anil Bogadi
    //08/03/2021 - GTMS 4285 Updated the criteria to consider SIC Manager's Email address too. @Apisero team 
    public static void stampCSMManagerEmail(Map<Id,Account> accountsWithCsmChangesMap, Map<Id, User> accountCsmMap){
        System.debug('accountCsmMap :'+accountCsmMap);
        Map<Id,Id> Acct_CSMUser_Id = new Map<Id,Id> ();
        Map<Id,Id> Acct_SICUser_Id = new Map<Id,Id> ();
        Map<Id,String> User_Csm_Mgr_Mgremail = new Map<Id,String> (); 
        Map<Id,String> User_Sic_Mgr_Mgremail = new Map<Id,String> (); 
        for(Account act : accountsWithCsmChangesMap.values()){
            Acct_CSMUser_Id.put(act.id,act.CSM__c); 
            Acct_SICUser_Id.put(act.id,act.SIC__c);
        }
        for(User usr : accountCsmMap.values()){
            User_Csm_Mgr_Mgremail.put(usr.id,usr.Manager.Manager.email);
            User_Sic_Mgr_Mgremail.put(usr.id,usr.Manager.Manager.email);
        }
        for(Account newAccount : accountsWithCsmChangesMap.values()){ 
            if(newAccount.SIC__c != null){
                if (accountCsmMap.get(newAccount.SIC__c).Manager != null) // GTMS-9700
                  newAccount.CSM_Manager_Email__c = accountCsmMap.get(newAccount.SIC__c).Manager.Email;
                newAccount.CSM_Director_Email__c = User_Sic_Mgr_Mgremail.get(Acct_SICUser_Id.get(newAccount.Id));
                newAccount.CSM_Name_Copy__c  = accountCsmMap.get(newAccount.SIC__c).FirstName + '' + accountCsmMap.get(newAccount.SIC__c).LastName;
            }else if(newAccount.CSM__c != null){
                if (accountCsmMap.get(newAccount.CSM__c).Manager != null) // GTMS-9700
                  newAccount.CSM_Manager_Email__c = accountCsmMap.get(newAccount.CSM__c).Manager.Email;
                newAccount.CSM_Director_Email__c = User_Csm_Mgr_Mgremail.get(Acct_CSMUser_Id.get(newAccount.Id)); 
                newAccount.CSM_Name_Copy__c  = accountCsmMap.get(newAccount.CSM__c).FirstName + '' + accountCsmMap.get(newAccount.CSM__c).LastName;
            }
        }
    }

    //Groundswell : Nilesh Jain - Stamp CSM Name workflow changes
    public static void stampCSMName(Map<Id,Account> accountsWithSICChanged, Map<Id, User> accountCsmMap){
        for(Account newAccount : accountsWithSICChanged.values()){
            newAccount.CSM_Name_Copy__c  = accountCsmMap.get(newAccount.CSM__c).FirstName + '' + accountCsmMap.get(newAccount.CSM__c).LastName;
        }
    }
    //End

    //Groundswell : Nilesh Jain - Owner Manager Email workflow changes
    public static void stampOwnerManagerEmail(Map<Id,Account> accountUpdateManagerEmail, Map<Id, User> accountCsmMap){
        for(Account newAccount : accountUpdateManagerEmail.values()){
            //GTMS-10718 Added Logic for checking Null pointer exception on accountCsmMap
            if (!accountCsmMap.isEmpty() && accountCsmMap.get(newAccount.OwnerId).Manager != null) // GTMS-9700 
              newAccount.Owner_Manager_Email_Copy__c   = accountCsmMap.get(newAccount.OwnerId).Manager.Email;
          }
    }
    //End

    //Groundswell : Nilesh Jain - Update Support Escalation Owner Name
    public static void stampEscalationOwnerName(Map<Id, Account> accountEscalationOwnerName, Map<Id, User> accountCsmMap){
        for(Account newAccount : accountEscalationOwnerName.values()){
            newAccount.Support_Escalation_Owner_Name__c = accountCsmMap.get(newAccount.Support_Escalation_Owner__c).FirstName + '' + accountCsmMap.get(newAccount.Support_Escalation_Owner__c).LastName;
        }
    }
    //End

    //WF Rule - Samsara Pre-Approval - Approve
    public static void preApproveSamsaraStatus(Map<Id, Account> accountToApproveSamsaraPreApprovalMap, Map<Id, User> accountCsmMap){
        for(Account newAccount : accountToApproveSamsaraPreApprovalMap.values()){
            if(accountCsmMap.get(newAccount.OwnerId).Profile.Name != Label.Samsara_Sales_New_System_Pilot){
                newAccount.Samsara_PreApproval_Status__c = Label.SamsaraPreApprovalApproved;
            }
        }
    }

    //WF Rule - Samsara Pre-Approval - Decline
    public static void declinePreApproveSamsaraStatus(Map<Id, Account> accountToDeclineSamsaraPreApprovalMap, Map<Id, User> accountCsmMap){
        for(Account newAccount : accountToDeclineSamsaraPreApprovalMap.values()){
            if(accountCsmMap.get(newAccount.OwnerId).Profile.Name != Label.Samsara_Sales_New_System_Pilot){
                newAccount.Samsara_PreApproval_Status__c = Label.SamsaraPreApprovalDeclined;
            }
        }
    }
    
    // Common Method for all Delinquency Workflows
    public static void allDelinquencyWorkflows(Account newAccount, Account oldAccount){
        
        /*    Commenting below as part of GTMS-6917
        //Delinquent Timestamp
            if(oldAccount.id != null && !oldAccount.Delinquent__c && (newAccount.Delinquent__c || (newAccount.Churn_Payment_Status__c != null && newAccount.Churn_Payment_Status__c.equals('Delinquent')))){
                newAccount.Delinquent_As_Of__c = system.now();
            }
            
            //Clear Delinquent Timestamp
            if(oldAccount.id != null && !newAccount.Delinquent__c){
                newAccount.Delinquent_As_Of__c  = null;
            }*/
            
            //Delinquency or Quarantine Clear
            if((oldAccount.Id != null 
                && (oldAccount.Enable_Delinquency_Process__c != newAccount.Enable_Delinquency_Process__c 
                    || oldAccount.Quarantine_Enabled__c != newAccount.Quarantine_Enabled__c)
                && !newAccount.Enable_Delinquency_Process__c && !newAccount.Quarantine_Enabled__c)){
                    newAccount.Enable_Delinquency_Process__c = false;
                    newAccount.Quarantine_Enabled__c = false; 
                    newAccount.Quarantine_Enabled_At__c = null;
                    newAccount.Suspension_Grace_Days__c  = null;
                }
            
            
            // WF Rule - Delinquency Starter
            if((oldAccount.Id != null 
                && (oldAccount.Account_Size_Segment__c != newAccount.Account_Size_Segment__c 
                    || oldAccount.Churn_Payment_Status__c != newAccount.Churn_Payment_Status__c
                    || oldAccount.New_Billing_Process_Approved__c != newAccount.New_Billing_Process_Approved__c
                    || oldAccount.Delinquent__c != newAccount.Delinquent__c))
               && newAccount.Account_Size_Segment__c == Label.AccountSizeSegment_AE1 
               && ((newAccount.Churn_Payment_Status__c == Label.Churn_Payment_Status_Delinquent && !newAccount.New_Billing_Process_Approved__c) 
                   || (newAccount.Delinquent__c && newAccount.New_Billing_Process_Approved__c))){
                       // Churn Payment - Deliquent
                       newAccount.Churn_Payment_Status__c = Label.Churn_Payment_Status_Delinquent;
                       // Start Delinquency Process
                       newAccount.Enable_Delinquency_Process__c = true;
                   }
            
             // WF Rule - Delinquency Setter
            if(oldAccount.id != null && newAccount.Enable_Delinquency_Process__c && ((newAccount.Enable_Delinquency_Process__c != oldAccount.Enable_Delinquency_Process__c) 
                                                                                     || (newAccount.Suspension_Grace_Days__c!= oldAccount.Suspension_Grace_Days__c))){
                                                                                         // Grace Period Set
                                                                                         newAccount.Suspension_Grace_Days__c = newAccount.Suspension_Grace_Days__c != null ? newAccount.Suspension_Grace_Days__c : Delinquency_Defaults__c.getInstance().Delinquency_Default_Grace_Period__c;
                                                                                         // Suspension Date Set
                                                                                         newAccount.Quarantine_Enabled_At__c = Date.today().AddDays(newAccount.Suspension_Grace_Days__c != null ? Integer.valueOf(newAccount.Suspension_Grace_Days__c) : 60 );
                                                                                     }
                                                                                     
            // WF Rule - Delinquency Unset
            if((oldAccount.Id != null 
                && (oldAccount.Account_Size_Segment__c != newAccount.Account_Size_Segment__c
                    || oldAccount.Churn_Payment_Status__c != newAccount.Churn_Payment_Status__c
                    || oldAccount.New_Billing_Process_Approved__c != newAccount.New_Billing_Process_Approved__c 
                    || oldAccount.Delinquent__c != newAccount.Delinquent__c))
               && newAccount.Churn_Payment_Status__c != 'Renewal'
               && newAccount.Account_Size_Segment__c == Label.AccountSizeSegment_AE1 && 
               ((newAccount.Churn_Payment_Status__c != Label.Churn_Payment_Status_Delinquent && !newAccount.New_Billing_Process_Approved__c) 
                || (!newAccount.Delinquent__c && newAccount.New_Billing_Process_Approved__c))){
                    // Churn Payment - Current
                    newAccount.Churn_Payment_Status__c = Label.Churn_Payment_Status_Current;                    
                    // Clear Enable Delinquency
                    newAccount.Enable_Delinquency_Process__c = false;
                    // Clear Quarantined Enabled
                    newAccount.Quarantine_Enabled__c = false;
                }
            /*GTMS-4792 Gaurav : Added below criteria to update the Deactivation date on Current Churn_Payment_Status*/
            if((oldAccount.Id != null 
                && (oldAccount.Account_Size_Segment__c != newAccount.Account_Size_Segment__c
                    || oldAccount.Churn_Payment_Status__c != newAccount.Churn_Payment_Status__c
                    || oldAccount.New_Billing_Process_Approved__c != newAccount.New_Billing_Process_Approved__c 
                    || oldAccount.Delinquent__c != newAccount.Delinquent__c))
               && (newAccount.Churn_Payment_Status__c == 'Current' || String.isBlank(newAccount.Churn_Payment_Status__c)) && 
               ((newAccount.Churn_Payment_Status__c != Label.Churn_Payment_Status_Delinquent && !newAccount.New_Billing_Process_Approved__c) 
                || (!newAccount.Delinquent__c && newAccount.New_Billing_Process_Approved__c))){
                    newAccount.Quarantine_Enabled_At__c = null;
                }
            /*GTMS-4792 Gaurav : End*/
        }
    
    
    public static Map<Id, User> getAccountCsmMap(Set<Id> userIds){
        Map<Id, User> accountCsmMap  = new Map<Id, User>([SELECT Email, FirstName, LastName, ADR_Assignment__c, Level__c,
                ManagerID, Manager.FirstName, Manager.LastName, Manager.Email,Manager.Manager.email,  Profile.Name FROM User where Id IN : userIds]);
        return accountCsmMap;
    }
}
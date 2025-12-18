/************************************************************************************************************************************
* Date        - Project#     - Developer/ Company           - Description
* -----------------------------------------------------------------------------------------------------------------------------------
* 01/20/2025    - GTMS-25961   - Shivani Rai      - Display Eligible contracts and Active but not eligible contracts in Contract Selection Wizard
*
*/
public class Flex_ControlCenterHelper {
    
    private static final String SUBTYPE_3PL_TO_OEM = '3PL to OEM transfer';
    private static final String SUBTYPE_OEM_TO_CUSTOMER = 'OEM to Customer delivery';
    private static final String FINANCE_PARTNER_REASON = 'Contract has a Finance Partner relationship';
    private static final String RESELLER_REASON = 'Contract has a Partner Reseller relationship';

    public static Flex_Control_Center_Config__c getConfig(String accountId){
        User u = [SELECT Id,Profile.Name,UserRole.Name FROM User WHERE Id = :UserInfo.getUserId()];
        String profileName = u.Profile.Name;
        String userRoleName = u.UserRole.Name;
        Account acct = [SELECT Id, Segment__c, BillingCountry FROM Account WHERE Id = :accountId];
        if(acct.Segment__c == null || acct.BillingCountry == null) return null;

        List<Flex_Control_Center_Config__c> configs = [
            SELECT Active__c, Amendment_Prob_Threshold__c, Contract_Record_Type__c,
            Enable_Cancel_Book__c, Enable_Cancel_Rebook__c, Enable_Term_Overwrite__c,
            Geo_Location__c,
            Max_Active_Contracts__c, Min_Contract_End_Days__c,
                Renewal_Prob_Threshold__c, Segment__c, User_Profile__c, User_Role__c, Max_Eligible_Contracts__c,
             Allow_Non_Co_termed_Contract_Selection__c,Are_OEM_Contracts_allowed__c
            FROM Flex_Control_Center_Config__c 
            WHERE Active__c = TRUE 
            AND User_Profile__c INCLUDES (:profileName)
            AND Geo_Location__c INCLUDES (:acct.BillingCountry)   
            AND Segment__c  INCLUDES (:acct.Segment__c)
            //ORDER BY User_Role__c DESC NULLS LAST
        ];
        if(configs.isEmpty()) return null;
        Flex_Control_Center_Config__c selectedConfig = configs.get(0);
        for(Flex_Control_Center_Config__c config : configs){
            if(String.isNotBlank(config.User_Role__c) && config.User_Role__c.contains(userRoleName)){
                selectedConfig = config;
                break;
            }
        }
        return selectedConfig;
    }
   
    @AuraEnabled(cacheable=true)
    public static ControlCenterConfig getEligibleContracts(Id accountId) {
            List<Contract> lstEligibleContractToProcess = new List<Contract>();
            List<ContractWrapper> lstNonEligibleActiveContracts = new List<ContractWrapper>();
            ControlCenterConfig wrapper = new ControlCenterConfig();
            wrapper.contracts = lstEligibleContractToProcess;
            wrapper.nonEligibleActiveContracts = lstNonEligibleActiveContracts;
        Flex_Control_Center_Config__c selectedConfig = getConfig(accountId); 
        if(selectedConfig == null) return wrapper;
        
        wrapper.config = selectedConfig;
        Integer noOfDays = 0;
        if(selectedConfig.Min_Contract_End_Days__c != null){
            noOfDays = Integer.valueOf(selectedConfig.Min_Contract_End_Days__c);
        }
        Date contractEndDate = Date.today().addDays(noOfDays);
        List<Contract> contracts = [
                SELECT Id, Name, ContractNumber, StartDate, Status, EndDate, CurrencyIsoCode, Contract_Renewable_ACV__c, RecordType.Name, netsuite_conn__Reseller__c,
                    Finance_Partner_Account__c, SBQQ__RenewalOpportunity__c, Contract_C_R_In_Progress__c, SBQQ__RenewalOpportunity__r.Probability,
                    SBQQ__Opportunity__c, SBQQ__Opportunity__r.Type, SBQQ__Opportunity__r.Sub_Type__c, SBQQ__Opportunity__r.StageName,
                (SELECT Id,Type,Sub_Type__c,StageName,isClosed FROM SBQQ__AmendmentOpportunities__r WHERE isClosed = false LIMIT 1)   
                FROM Contract 
                WHERE AccountId = :accountId 
                AND Status = 'Activated'
                    AND EndDate >: Date.today()
                    AND (SBQQ__RenewalOpportunity__c = null OR 
                    SBQQ__RenewalOpportunity__r.isClosed = false)
                //AND Finance_Partner_Account__c = null
                //AND netsuite_conn__Reseller__c = null 
                AND RecordType.DeveloperName = 'Standard_Contract'
                AND Deactivated__c = false
                ];
        
            // Get all closed won amendments for the contracts
            Map<Id, List<Opportunity>> contractToAmendments = new Map<Id, List<Opportunity>>();
            if(!contracts.isEmpty()) {
                List<Opportunity> closedWonAmendments = [
                    SELECT Id, SBQQ__AmendedContract__c, Sub_Type__c 
                    FROM Opportunity 
                    WHERE SBQQ__AmendedContract__c IN :contracts 
                    AND StageName = 'Closed Won'
                ];
                
                for(Opportunity opp : closedWonAmendments) {
                    if(!contractToAmendments.containsKey(opp.SBQQ__AmendedContract__c)) {
                        contractToAmendments.put(opp.SBQQ__AmendedContract__c, new List<Opportunity>());
                    }
                    contractToAmendments.get(opp.SBQQ__AmendedContract__c).add(opp);
                }
            }
            if (contracts.size() > 0 && contracts.size() <= selectedConfig.Max_Active_Contracts__c) {
                for (Contract con : contracts) {
                    List<String> failureReasons = new List<String>(); // Use a list to gather failure reasons
                    // Check failure conditions and add to failureReasons list
                    if (con.EndDate <= contractEndDate) {
                        failureReasons.add('Contract end date cannot be less than '+noOfDays+' days from expiration.');
                    }
                    if (con.SBQQ__RenewalOpportunity__c != null && con.SBQQ__RenewalOpportunity__r.Probability > selectedConfig.Renewal_Prob_Threshold__c) {
                        failureReasons.add('Contracts cannot exceed '+ selectedConfig.Renewal_Prob_Threshold__c+'% probability stage');
                    }
                    if (con.Finance_Partner_Account__c != null) {
                        failureReasons.add(FINANCE_PARTNER_REASON);
                    }
                    if (con.netsuite_conn__Reseller__c != null) {
                        failureReasons.add(RESELLER_REASON);
                    }
                    if (con.Contract_C_R_In_Progress__c) {
                        failureReasons.add('Cancel and Replace (C&R) process is in progress.');
                    }
                    // Check primary opportunity and amendments for 3PL to OEM transfer or OEM to Customer delivery
                    // Only add reason if Are_OEM_Contracts_allowed__c is false
                    if(!selectedConfig.Are_OEM_Contracts_allowed__c) {
                        Boolean has3PLToOEMTransfer = false;
                        Boolean hasOEMToCustomerDelivery = false;
                        
                        if(con.SBQQ__Opportunity__c != null && String.isNotBlank(con.SBQQ__Opportunity__r.Sub_Type__c)) {
                            if(con.SBQQ__Opportunity__r.Sub_Type__c == SUBTYPE_3PL_TO_OEM) {
                                has3PLToOEMTransfer = true;
                            } else if(con.SBQQ__Opportunity__r.Sub_Type__c == SUBTYPE_OEM_TO_CUSTOMER) {
                                hasOEMToCustomerDelivery = true;
                            }
                        }
                        if(contractToAmendments.containsKey(con.Id)) {
                            for(Opportunity amendment : contractToAmendments.get(con.Id)) {
                                if(amendment.Sub_Type__c == SUBTYPE_3PL_TO_OEM) {
                                    has3PLToOEMTransfer = true;
                                } else if(amendment.Sub_Type__c == SUBTYPE_OEM_TO_CUSTOMER) {
                                    hasOEMToCustomerDelivery = true;
                                }
                            }
                        }
                        
                        if(has3PLToOEMTransfer) {
                            failureReasons.add('Contract has 3PL to OEM transfer');
                        }
                        if(hasOEMToCustomerDelivery) {
                            failureReasons.add('Contract has OEM to Customer delivery');
                        }
                    }
                    // If there are no failure reasons, it's eligible, otherwise add to non-eligible list
                    if (failureReasons.isEmpty()) {
                        lstEligibleContractToProcess.add(con);
                    } else {
                        String failureReasonString = String.join(failureReasons, '\n');
                        lstNonEligibleActiveContracts.add(new ContractWrapper(con, failureReasonString));
                    }
                }
            }
            wrapper.contracts = lstEligibleContractToProcess;
            wrapper.nonEligibleActiveContracts = lstNonEligibleActiveContracts;
            return wrapper;                
    }

    public class ControlCenterConfig{
        @AuraEnabled
        public List<Contract> contracts{get;set;}
        @AuraEnabled
        public List<ContractWrapper> nonEligibleActiveContracts { get; set; } // Updated type to ContractWrapper
        @AuraEnabled
        public Flex_Control_Center_Config__c config{get;set;}
        public ControlCenterConfig(){
            this.contracts = new List<Contract>();
            this.nonEligibleActiveContracts = new List<ContractWrapper>();
            this.config = null;
        }
    }

    // Wrapper class to hold contract details and reason for ineligibility
    public class ContractWrapper {
        @AuraEnabled public String Id;
        @AuraEnabled public String ContractNumber;
        @AuraEnabled public Date StartDate;
        @AuraEnabled public Date EndDate;
        @AuraEnabled public String CurrencyIsoCode;
        @AuraEnabled public Decimal ContractRenewableACV;
        @AuraEnabled public String Status;
        @AuraEnabled public Boolean CRInProgress;
        @AuraEnabled public String FailureReason; // Holds the reason why the contract is ineligible
        // Constructor to store contract details and failure reason
        public ContractWrapper(Contract con, String reason) {
            this.Id = con.Id;
            this.ContractNumber = con.ContractNumber;
            this.StartDate = con.StartDate;
            this.EndDate = con.EndDate;
            this.CurrencyIsoCode = con.CurrencyIsoCode;
            this.ContractRenewableACV = con.Contract_Renewable_ACV__c;
            this.Status = con.Status;
            this.CRInProgress = con.Contract_C_R_In_Progress__c;
            this.FailureReason = reason;
        }
    }

    /**
     * Gets the Mid-Contract help text from custom settings
     * @return String
     */
    @AuraEnabled(cacheable=true)
    public static String getMidContractHelpText() {
        FlexConstants__c settings = FlexConstants__c.getInstance();
        // Return the custom setting value if available, otherwise return the hardcoded value
        return settings?.Mid_Contract_help_text_message__c != null ? 
               settings.Mid_Contract_help_text_message__c : 
               'Select this option to initiate a Cancel & Replace (C&R) for one or more customer contracts'; // Fallback value
    }

}
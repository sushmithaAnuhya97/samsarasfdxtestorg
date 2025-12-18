/**
 * @description Invocable Apex class that evaluates opportunity data and generates email alerts based on business rules and related record criteria
 */
 
 /*
 
1.check for fields used in the class if its queried especially opp and account
2. check with quotes with no line items or primary quote
 
 */
public class FlowEvaluatorService{
    
    // ===========================================
    // CONSTANTS
    // ===========================================
    
    public static final String STAGE_CLOSED_WON = 'Closed Won';
    public static final String STAGE_CLOSED_LOST = 'Closed Lost';
    public static final String STAGE_PURCHASE = 'Purchase';
    private static final String STAGE_END_OF_LIFE = 'End of Life with Promo';
    private static final String ACC_COUNTRY = 'Mexico';
    private static final String PRODUCT_SAFETY_PRO = 'Safety Pro';
    private static final Integer ACV_BOOKING_VALUE = 50000;
    
    private static final Set<String> ACCOUNT_TIERS = new Set<String>{
        'Core Basic', 'Core Standard', 'Core High', 'Select Basic', 'Select Standard', 'Select High',
        'Strategic Basic', 'Strategic Standard', 'Strategic High'
    };
    
    private static final Set<String> ACCOUNT_TIMEZONES = new Set<String>{
        'MST', 'PST', 'EST', 'CST', 'TBD'
    };
    
    private static final Set<String> HOLD_TYPES = new Set<String>{
        'Revenue Opportunity', 'Free Trial Opportunity', 'Promo Opportunity'
    };
    
    private static final Set<String> HOLD_CURRENCY = new Set<String>{
        'USD', 'CAD', 'MXN', 'GBP', 'EUR'
    };
    
    private static final Set<String> STAGES_MM = new Set<String>{
         'Refunded - Closed', 'Orders Processing'
    };
    
    private static final Map<String,String> MAP_HR_ALERT = new Map<String,String>{//hold reason codes
        'Confirming FT'      => 'Confirming_FT',
        'Out of stock'       => 'Out_Of_Stock',
        'No PM approval'     => 'No_PM_Approval',
        'Inventory Hold'     => 'Inventory_Hold',
        'Clarification Hold' => 'Clarification_Hold',
    	'Incorrect Quantities'              => 'Incorrect_Quantities',//not decided
        'Missing / Wrong Shipping Address'  => 'Missing_Wrong_Shipping_Address',
        'Requested Later Ship Date'         => 'Requested_Later_Ship_Date'
    };
    private static final Map<String,String> MAP_PV_ALERT = new Map<String,String>{//Product version codes.
        'Carrier Delay'                  => 'Carrier_Delay',
        'Updated Suite/Apt Number'       => 'Updated_Suite_Apt_Number',
        'Receiver Has Moved'             => 'Receiver_Has_Moved'
    };
    
    // ===========================================
    // STATIC VARIABLES
    // ===========================================
    /** Set of opportunity IDs to skip processing - add 'All' to skip all opportunities, or add specific opportunity IDs */
    public static Set<String> oppsToSkip = new Set<String>();

    private static List<EmailAlert> listOfAlerts = new List<EmailAlert>();
    public static Set<Id> csmOppIds = new Set<Id>();
    public static Set<Id> esmOppIds = new Set<Id>();
    public static List<Channel_Relationship__c> crList = new List<Channel_Relationship__c>();
    public static Set<Id> dealRegOppIds = new Set<Id>();
    public static Map<Id, SBQQ__Quote__c> quoteMap = new Map<Id, SBQQ__Quote__c>();
    public static Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
    //added for test class. 
    public static Map<Id, Account> accWithAllFields = new Map<Id,Account>();
    public static Map<Id, Opportunity> oppWithAllFields = new Map<Id, Opportunity>();


    @InvocableMethod(label='EvaluateFlow' description='This method will evaluate the decisions for flow and return list of all emailAlerts applicable')
    public static List<FlowEvaluatorWrapper.OpportunityAlerts> evaluateFlow(List<FlowEvaluatorWrapper.InputWrapper> inputList) {
        FlowEvaluatorWrapper.OpportunityAlerts wrapper = new FlowEvaluatorWrapper.OpportunityAlerts();
        List<FlowEvaluatorWrapper.OpportunityAlerts> results = new List<FlowEvaluatorWrapper.OpportunityAlerts>();
        FlowCpuLogger.startCpuTime = Limits.getCpuTime();
        if(!test.isRunningTest() && OpportunityHelperContext.oppAccounts != null && OpportunityHelperContext.oppFields != null){
            accWithAllFields = OpportunityHelperContext.oppAccounts;
        	oppWithAllFields = OpportunityHelperContext.oppFields;
        }
        
        if (!checkGlobalBypass()) {
            processOpportunityInputs(inputList);
            getRecords();
            processAllEmailAlerts();
            wrapper.byPass = false;
            wrapper.emailAlerts = listOfAlerts;
        }
        
        results.add(wrapper);
        for (Integer i = 1; i < inputList.size(); i++) {
            FlowEvaluatorWrapper.OpportunityAlerts secondaryWrapper = new FlowEvaluatorWrapper.OpportunityAlerts();
            secondaryWrapper.byPass = true;
            results.add(secondaryWrapper);
        }
        return results;
    }
    
    private static void processOpportunityInputs(List<FlowEvaluatorWrapper.InputWrapper> inputList) {
        for (FlowEvaluatorWrapper.InputWrapper input : inputList) {
            if (input.oldOpp!= null && 
                (!oppsToSkip.contains((String) input.newOpp.Id) || (input.newOpp.Bypass_Validation_Rule_DateTime__c == input.oldOpp.Bypass_Validation_Rule_DateTime__c))
                ){
                processOpportunityEmails(input.newOpp, input.oldOpp);
                oppMap.put(input.newOpp.Id, input.newOpp);
            }
        }
    }
    
    private static void processOpportunityEmails(Opportunity newOpp, Opportunity oldOpp) {
        if (oldOpp != null) {
            Opportunity queriedOpp = oppWithAllFields?.get(newOpp.Id);
            Account currentAcc = accWithAllFields?.get(newOpp.AccountId);
			// Process stage changes with if-else statements
            if (newOpp.StageName != oldOpp.StageName) {
                if (newOpp.StageName == STAGE_PURCHASE) {
                    if (isEsmEligible(newOpp, currentAcc)) {
                        esmOppIds.add(newOpp.Id);
                    }
                } else if (newOpp.StageName == STAGE_CLOSED_WON) {
                    if (isCsmEligible(newOpp, currentAcc)) {
                        csmOppIds.add(newOpp.Id);
                    }
                    if (newOpp.Type == 'Revenue Opportunity') {
                        dealRegOppIds.add(newOpp.Id);
                    }
                } else if (newOpp.StageName == STAGE_CLOSED_LOST) {
                    if (newOpp.Type == 'Revenue Opportunity') {
                        dealRegOppIds.add(newOpp.Id);
                    }
                } else if (STAGES_MM.contains(newOpp.StageName)) {
                    if (isMidMarketEligible(newOpp, queriedOpp)) {
                        createClosingAlert(newOpp, queriedOpp);
                    }
                }
            }
            
            // Process overpaying alert
            if (isOverPayingCustomer(newOpp, oldOpp, queriedOpp)) {
                createEmailAlert(newOpp.Id, 'Customer_OverPaying', null, newOpp.Id, null);
            }
            
            // Process hold code alert
            processHoldCodeAlert(newOpp, oldOpp);
        }
    }
    
    private static void processHoldCodeAlert(Opportunity newOpp, Opportunity oldOpp) {
        if (HOLD_TYPES.contains(newOpp.Type) && HOLD_CURRENCY.contains(newOpp.CurrencyIsoCode)){
            Boolean isEmea = (newOpp.CurrencyIsoCode == 'EUR' || newOpp.CurrencyIsoCode == 'GBP');
            if (newOpp.Hold_Reason__c != oldOpp.Hold_Reason__c && MAP_HR_ALERT.containsKey(newOpp.Hold_Reason__c)) {
                String alertName = isEmea ? MAP_HR_ALERT.get(newOpp.Hold_Reason__c) + '_EMEA' : MAP_HR_ALERT.get(newOpp.Hold_Reason__c);
                createEmailAlert(newOpp.Id, alertName, null, newOpp.Id, newOpp.OwnerId);
            } else if (newOpp.Product_Version__c != oldOpp.Product_Version__c && MAP_PV_ALERT.containsKey(newOpp.Product_Version__c)) {
                String alertName = isEmea ? MAP_PV_ALERT.get(newOpp.Product_Version__c) + '_EMEA' : MAP_PV_ALERT.get(newOpp.Product_Version__c);
                createEmailAlert(newOpp.Id, alertName, null, newOpp.Id, newOpp.OwnerId);
            }
        }
    }
    
    // ===========================================
    // Eligibility Checks
    // ===========================================
    
    private static Boolean isEsmEligible(Opportunity newOpp, Account currentAcc) {
        return newOpp.ACV_Bookings__c >= ACV_BOOKING_VALUE && 
            currentAcc?.BillingCountry != ACC_COUNTRY && 
            ACCOUNT_TIMEZONES.contains(currentAcc?.Timezone__c);
    }
    
    private static Boolean isCsmEligible(Opportunity newOpp, Account currentAcc) {
        
        return currentAcc != null && 
            currentAcc.SIC__c != null &&
            (!currentAcc.LIC_CM1_PRO__c || !currentAcc.LIC_CM2_PRO__c) && 
            ACCOUNT_TIERS.contains(currentAcc.CS_Tier__c);
    }
    
    private static Boolean isMidMarketEligible(Opportunity newOpp, Opportunity queriedOpp) {
        return newOpp.Type == 'Revenue Opportunity' && queriedOpp.Owner_Role_Copy__c != null &&
               !queriedOpp?.Owner_Role_Copy__c.contains('EMEA');
    }
    
    private static Boolean isOverPayingCustomer(Opportunity newOpp, Opportunity oldOpp, Opportunity queriedOpp) {
        return newOpp.Went_to_Purchase__c && 
               oldOpp.License_Term__c != newOpp.License_Term__c && queriedOpp?.Owner?.UserRole.Name != null &&
               queriedOpp?.Owner?.UserRole?.Name.contains('AE1');
    }
    
    
    // ===========================================
    // Data Retrieval
    // ===========================================
    
    private static void getRecords() {
        if (!csmOppIds.isEmpty() || !esmOppIds.isEmpty()) {
            Set<Id> allOppIds = new Set<Id>();
            allOppIds.addAll(csmOppIds);
            allOppIds.addAll(esmOppIds);
            
            quoteMap = new Map<Id, SBQQ__Quote__c>([
                SELECT Id, (SELECT Id, SBQQ__Quote__r.SBQQ__Account__c, SBQQ__Quote__r.SBQQ__Opportunity2__r.Id, SBQQ__ProductName__c 
                           FROM SBQQ__LineItems__r) 
                FROM SBQQ__Quote__c  
                WHERE SBQQ__Primary__c = True AND SBQQ__Opportunity2__c IN :allOppIds
            ]);
        }
        
        if (!dealRegOppIds.isEmpty()) {
            crList = [
                SELECT Id, Opportunity__c, Opportunity__r.StageName, Opportunity__r.Owner_Manager_Email_Copy__c, 
                       Channel_Partner_User_lr__r.IsActive, Channel_Partner__r.Partner_Status__c 
                FROM Channel_Relationship__c 
                WHERE Opportunity__c IN :dealRegOppIds 
                AND Channel_Partner_User_lr__r.IsActive = true 
                AND Channel_Partner__r.Partner_Status__c != 'Deactivated'
            ];
        }
    }
    
    // ===========================================
    // Email Alert Processing
    // ===========================================
    
    private static void processAllEmailAlerts() {
        processCsmAlerts();
        processEsmAlerts();
        processDealRegistrationAlerts();
    }
    
    private static void processCsmAlerts() {
        if (csmOppIds.isEmpty()) return;  
        for (Id oppId : csmOppIds) {
            if (oppMap.containsKey(oppId) && quoteMap.containsKey(oppMap.get(oppId).SBQQ__PrimaryQuote__c)) {
                Opportunity currentOpp = oppMap.get(oppId);
                Account currentAcc = accWithAllFields?.get(currentOpp.AccountId);
                if(currentAcc != null && currentAcc.SIC__c != null){
                    SBQQ__Quote__c quote = quoteMap.get(currentOpp.SBQQ__PrimaryQuote__c);
                    for (SBQQ__QuoteLine__c qli : quote.SBQQ__LineItems__r) {
                        if (qli.SBQQ__ProductName__c != null && qli.SBQQ__ProductName__c.contains(PRODUCT_SAFETY_PRO)){
                            createEmailAlert(oppId, 'Send_Email_CSM', null, oppId, currentAcc?.SIC__c);
                            break;
                        }
                    }
                }
            }
        }
    }
    
    private static void processEsmAlerts() {
        if (esmOppIds.isEmpty()) return;
        
        for (Id oppId : esmOppIds) {
            if (oppMap.containsKey(oppId) && quoteMap.containsKey(oppMap.get(oppId).SBQQ__PrimaryQuote__c)) {
                Opportunity currentOpp = oppMap.get(oppId);
                Account currentAcc = accWithAllFields?.get(currentOpp.AccountId);
                if(currentAcc != null && currentAcc.CS_Tier__c != null){
                    SBQQ__Quote__c quote = quoteMap.get(oppMap.get(oppId).SBQQ__PrimaryQuote__c);
                    for (SBQQ__QuoteLine__c qli : quote.SBQQ__LineItems__r) {
                        if (qli.SBQQ__ProductName__c != null && 
                            (!qli.SBQQ__ProductName__c.contains('ACC') || !qli.SBQQ__ProductName__c.contains('CBL'))) {
                            String alertName = getMatchingConfig(currentAcc?.CS_Tier__c);
                            if (alertName == null) break;
                            createEmailAlert(oppId, alertName, null, oppId, null);
                            break;
                        }
                    }
                }
            }
         }
    }
    
    private static void processDealRegistrationAlerts() {
        if (crList.isEmpty()) return;
        for (Channel_Relationship__c cr : crList) {
            String alertName = cr.Opportunity__r.StageName == STAGE_CLOSED_WON ? 'CR_Partner_Won' : 'CR_Partner_Lost';
            createEmailAlert(cr.Id, alertName, cr.Opportunity__r.Owner_Manager_Email_Copy__c, 
                           cr.Opportunity__c, cr.Channel_Partner_User_lr__c);
        }
    }
    
    // ===========================================
    // PRIVATE METHODS - Utility Functions
    // ===========================================
    
    private static Boolean checkGlobalBypass() {
        Global_Automation_Settings__c gas = Global_Automation_Settings__c.getInstance(UserInfo.getUserId());
        return (gas != null && 
               	((gas.Skip_Flow_Automation__c) || 
                 (!String.isBlank(gas.Skip_Specific_Flow__c) && gas.Skip_Specific_Flow__c.containsIgnoreCase('Opportunity')) ||
                 (gas.Opportunity_Flow__c )
                               )) || oppsToSkip.contains('All');
    }
    
    
    private static String getMatchingConfig(String tier) {

        if (tier.startsWith('Core')) return 'Send_ESM_Core';
        if (tier.startsWith('Select')) return 'Send_ESM_Select';
        if (tier.startsWith('Strategic')) return 'Send_ESM_Strategic';
        
        return null;
    }
    
    
    private static void createClosingAlert(Opportunity newOpp, Opportunity queriedOpp) {
        String alertName = queriedOpp?.Owner_Role_Copy__c != null && 
                   queriedOpp.Owner_Role_Copy__c.contains('AE2')
                   ? 'Closing_Alert_for_MM_US_AE2' 
                   : 'Closing_Alert_for_MM_US_AE3';
        createEmailAlert(newOpp.Id, alertName, queriedOpp?.Owner_Manager_Email_Copy__c, newOpp.Id, newOpp.OwnerId);
    }
    
    //this method creates list of alerts for each decision. Alert name corresponds to the metadata developerName. 
    private static EmailAlert createEmailAlert(Id relRecId, String alertName, String addOnRecipients, Id oppId, Id recipientId) {
        EmailAlert emailAlert = new EmailAlert();
        Email_Alert_Configurations__mdt emConfig = Email_Alert_Configurations__mdt.getInstance(alertName);
        if(emConfig != null){
            emailAlert.recipient = new List<String>();
            String recipientsSource = '';
            if (!String.isBlank(emConfig.Email_Recipients__c)) {
                recipientsSource = emConfig.Email_Recipients__c;
            }
            if (!String.isBlank(addOnRecipients)) {
                recipientsSource = String.isBlank(recipientsSource) ? addOnRecipients : recipientsSource + ',' + addOnRecipients;
            }
            if (!String.isBlank(recipientsSource)) {
                emailAlert.recipient.addAll(recipientsSource.split(','));
            }
            recipientId = emConfig.RecipientId__c != null ? emConfig.RecipientId__c : recipientId;
            emailAlert.alertName = emConfig.DeveloperName;
            emailAlert.relRecordId = relRecId;
            emailAlert.ccAddress = emConfig.ccRecipients__c;
            emailAlert.bccAddress = emConfig.bccRecipients__c;
            emailAlert.fromAddress = emConfig.fromAddress__c;
            emailAlert.templateId = emConfig.Template_Id__c;
            emailAlert.AlertType = emConfig.Alert_Type__c;
            emailAlert.recipientId = recipientId;
            emailAlert.opportunityId = oppId;
            emailAlert.senderType = emConfig.fromAddress__c == null ?'CurrentUser' :'OrgWideEmailAddress';
            listOfAlerts.add(emailAlert);
        }
        
        return emailAlert;   
    }
}
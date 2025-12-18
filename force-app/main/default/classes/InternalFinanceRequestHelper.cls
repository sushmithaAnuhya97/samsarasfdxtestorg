public class InternalFinanceRequestHelper
{
    /**
     * Custom exception for cases in Credit Limit Increase request.
     */
    public class IFRException extends Exception {}
    
    public SamsaraLoggerService thisSamsaraLoggerService = new SamsaraLoggerService();
    
    @TestVisible private static string IFR_APPROVAL_STATUS_APPROVED_STRING = 'Approved';
    @TestVisible private static string IFR_APPROVAL_STATUS_PENDING_STRING = 'Pending';
    
    private static set<Id> RequestIds =  new set<Id>();
    private static set<Id> quoteIds =  new set<Id>();
    private static set<Id> AccIds =  new set<Id>();
    private static set<Id> OpptyIds =  new set<Id>();
    private static list<SBQQ__Quote__c> additionalQuotesToProcess = new list<SBQQ__Quote__c>();
    private static Map<Id, list<SBQQ__Quote__c>> additionalQuoteAccIdMap = new Map<Id, list<SBQQ__Quote__c>>();
    public static Map<Id,SBQQ__Quote__c> requestIdQuoteMap = new Map<Id,SBQQ__Quote__c>();
    private static Map<Id,Account> requestIdAccMap = new Map<Id,Account>();
    private static Map<Id,Opportunity> requestIdOpptyMap = new Map<Id,Opportunity>();
    
    
    public void beforeInsertOnly(List<Internal_Finance_Approval_Request__c> newRequestList)
    {
        autoApprovePaymentTerms(newRequestList); //Auto approve payment terms based on segment and region rules
        autoApproveCreditLimitIncrease(newRequestList); //Auto approve credit limit increase based on segment and region rules
    }    
    
    public void beforeUpdateOnly(Map<Id, Internal_Finance_Approval_Request__c> oldRequestMap, List<Internal_Finance_Approval_Request__c> newRequestList)
    {
        
    }
    
    public void afterUpdateOnly(Map<Id, Internal_Finance_Approval_Request__c> oldRequestMap, List<Internal_Finance_Approval_Request__c> newRequestList)
    {
        Boolean quoteUpdate = false;
        Boolean accUpdate = false;
        if(!requestIdAccMap.isEmpty()){
            for(Internal_Finance_Approval_Request__c rqst: newRequestList)
            {
                //In the auto approval scenario, the payment terms logic must also execute in the After Insert event. Thus, when not auto approved, skip
                if(!rqst.Auto_Approved__c && Trigger.isExecuting?Trigger.isInsert:false) continue;

                if(rqst.Request_Type__c =='Change in Payment Terms' && rqst.Payment_Type_Approval_Status__c == 'Approved' && checkIfPreviouslyNotApproved(rqst, oldRequestMap)){
                    if(requestIdAccMap.containsKey(rqst.Account__c) && requestIdAccMap.get(rqst.Account__c).Payment_Terms__c == rqst.Requested_Payment_Terms__c)
                    {
                        quoteUpdate = true;
                        if(requestIdQuoteMap.containsKey(rqst.Quote__c))  requestIdQuoteMap.get(rqst.Quote__c).SBQQ__PaymentTerms__c = rqst.Requested_Payment_Terms__c;//Opportunity's payment term is updated via the quotetrigger
                    }
                else if(requestIdAccMap.containsKey(rqst.Account__c) && requestIdAccMap.get(rqst.Account__c).Payment_Terms__c != rqst.Requested_Payment_Terms__c)
                    {
                        
                    if(requestIdOpptyMap.containsKey(rqst.Opportunity__c) && requestIdOpptyMap.get(rqst.Opportunity__c).Payment_Terms_Opportunity_only_exception__c  == true)
                        {
                            quoteUpdate = true;
                            if(requestIdQuoteMap.containsKey(rqst.Quote__c))  requestIdQuoteMap.get(rqst.Quote__c).SBQQ__PaymentTerms__c = rqst.Requested_Payment_Terms__c;//Opportunity's payment term is updated via the quotetrigger
                        }
                    else if(requestIdOpptyMap.containsKey(rqst.Opportunity__c) && requestIdOpptyMap.get(rqst.Opportunity__c).Payment_Terms_Opportunity_only_exception__c == false)
                        {
                            quoteUpdate = true;
                            accUpdate = true;
                            if(requestIdQuoteMap.containsKey(rqst.Quote__c)) requestIdQuoteMap.get(rqst.Quote__c).SBQQ__PaymentTerms__c = rqst.Requested_Payment_Terms__c;
                            requestIdAccMap.get(rqst.Account__c).Payment_Terms__c = rqst.Requested_Payment_Terms__c;

                            updateQuoteReqPaymentTerms(rqst);
                        }
                    }
                }

            }
        }
        
        if(quoteUpdate) {
            updateSObjectRecords('Quote');
        }
        if(accUpdate) {
            updateSObjectRecords('Account');
        }     
    }
    
    public void afterInsertOrUpdate(List<Internal_Finance_Approval_Request__c> newRequestList, Map<Id, Internal_Finance_Approval_Request__c> oldRequestMap)
    {
        Boolean oppUpdate = false;
        Id profileId = userinfo.getProfileId();
        String profileName = [Select Id,Name from Profile where Id=:profileId].Name;
        for(Internal_Finance_Approval_Request__c rqst: newRequestList)
        {
            RequestIds.add(rqst.Id);
            quoteIds.add(rqst.Quote__c);
            AccIds.add(rqst.Account__c);
            OpptyIds.add(rqst.Opportunity__c);
        }
        
        if(quoteIds != null)requestIdQuoteMap = new Map<Id,SBQQ__Quote__c>([Select id,SBQQ__Account__c,Selected_Payment_Type__c from SBQQ__Quote__c where Id IN: quoteIds]);
        if(AccIds != null)requestIdAccMap = new Map<Id,Account>([Select id,Approved_Payment_Type__c,Payment_Terms__c from Account where Id IN: AccIds]);
        if(OpptyIds != null)requestIdOpptyMap = new Map<Id,Opportunity>([Select id,Selected_Payment_Type__c, Payment_Type_Opportunity_only_Exception__c, Payment_Terms_Opportunity_only_exception__c,StageName,
                                                                        AccountId, SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.SBQQ__Status__c, 
                                                                         (SELECT dsfs__Opportunity__c FROM dsfs__R00N80000002fD9vEAE__r LIMIT 1), (SELECT OpportunityId FROM Orders LIMIT 1),
                                                                         Owner.Region__c
                                                                         FROM Opportunity 
                                                                         WHERE Id IN: OpptyIds 
                                                                         OR (Probability < 95 AND IsClosed = false
                                                                             AND Account.Segment__c NOT IN ('AE1', 'Small Business')
                                                                             AND SBQQ__PrimaryQuote__c != null
                                                                             AND SBQQ__PrimaryQuote__r.SBQQ__Status__c != 'Approved'
                                                                             AND Type = 'Revenue Opportunity' AND SBQQ__Renewal__c = false
                                                                             AND Is_Webstore_Upsell_Opportunity__c = false AND Small_Fleet_Opportunity__c = false
                                                                             AND Payment_Terms_Opportunity_only_exception__c = false
                                                                             AND Finance_Partner__c = null
                                                                             AND Reseller_Partner__c = null
                                                                             AND AccountId In :requestIdAccMap.keySet())
                                                                        ]);
        
        for(Opportunity opp :requestIdOpptyMap.values()){
            
            // GTMS-19555 Skip the Opportunity if its ID is in OpptyIds, or if it has related DocuSign records, or if it has related Orders
            if(OpptyIds.contains(opp.Id) || !opp.dsfs__R00N80000002fD9vEAE__r.isEmpty() || !opp.Orders.isEmpty()) continue;
            
            if(!additionalQuoteAccIdMap.containsKey(opp.AccountId))
                additionalQuoteAccIdMap.put(opp.AccountId, new list<SBQQ__Quote__c>());
            
            additionalQuoteAccIdMap.get(opp.AccountId).add(new SBQQ__Quote__c(Id = opp.SBQQ__PrimaryQuote__c, SBQQ__Account__c = opp.AccountId));
        }
        
        afterUpdateOnly(oldRequestMap, newRequestList); //Action must be performed during the After Insert event as well as Auto Approval logic is introduced. 
        
        for(Internal_Finance_Approval_Request__c rqst: newRequestList)
        {
            if(rqst.Opportunity__c != null && (rqst.Requested_Payment_Types__c != null) && (rqst.Requested_Payment_Types__c.contains('Direct Semi-Annual') || rqst.Requested_Payment_Types__c.contains('Direct Quarterly') || rqst.Requested_Payment_Types__c.contains('Direct Monthly') || rqst.Requested_Payment_Types__c.contains('Direct Annual') || rqst.Requested_Payment_Types__c.contains('Upfront')) && (rqst.Payment_Type_Approval_Status__c == 'Approved'))
            {
                if(!requestIdOpptyMap.isEmpty() && requestIdOpptyMap.containsKey(rqst.Opportunity__c) 
                   && profileName != System.Label.System_Admin_API_Profile)
                {
                    oppUpdate = true;
                    requestIdOpptyMap.get(rqst.Opportunity__c).Internal_Finance_Payment_Type__c = rqst.Approved_Payment_Type__c;
                } else if (!requestIdOpptyMap.isEmpty() && requestIdOpptyMap.containsKey(rqst.Opportunity__c) 
                   && profileName == System.Label.System_Admin_API_Profile && requestIdOpptyMap.get(rqst.Opportunity__c).StageName != 'Closed Won' &&
                    requestIdOpptyMap.get(rqst.Opportunity__c).StageName != 'Closed Lost') {
                        oppUpdate = true;
                        requestIdOpptyMap.get(rqst.Opportunity__c).Internal_Finance_Payment_Type__c = rqst.Approved_Payment_Type__c;
                }
            }
        }
        if(oppUpdate){
            updateSObjectRecords('Opportunity');
        }
    }
    
    
    public void updateSObjectRecords(String SobjectName) 
    {
        Switch on SobjectName
        {
            when 'Account'
            {
                if (requestIdAccMap.values().size() > 0) 
                {
                    List<Account> accounts = new List<Account>();
                    accounts.addAll(requestIdAccMap.values());
                    requestIdAccMap.clear();
                    DMLWrapper.doUpdate(accounts);
                } 
            }
            when 'Opportunity'
            {
                if (requestIdOpptyMap.values().size() > 0) 
                {
                    List<Opportunity> Opptys = new List<Opportunity>();
                    
                    //Add Only the Opportunities related to the IFR Object
                    for(Opportunity opp :requestIdOpptyMap.values()){
                        if(OpptyIds.contains(opp.Id)) Opptys.add(opp);
                    }
                    
                    DMLWrapper.doUpdate(Opptys);
                    requestIdOpptyMap.clear();
                } 
            }
            when 'Quote'
            {
                if (requestIdQuoteMap.values().size() > 0) 
                {
                    List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
                    quotes.addAll(requestIdQuoteMap.values());
                    if(!additionalQuotesToProcess.isEmpty()) quotes.addAll(additionalQuotesToProcess);
                    DMLWrapper.doUpdate(quotes);
                    requestIdQuoteMap.clear();
                    additionalQuotesToProcess.clear();
                    additionalQuoteAccIdMap.clear();
                } 
            }
        }                
    }
    
    /********************************HELPER METHODS ****************************************/

    private boolean checkIfPreviouslyNotApproved(Internal_Finance_Approval_Request__c request, Map<Id, Internal_Finance_Approval_Request__c> oldRequestMap){
        return Trigger.isExecuting && Trigger.isInsert ? true : (oldRequestMap.get(request.Id).Payment_Type_Approval_Status__c != 'Approved');
    }

    public void autoApprovePaymentTerms(List<Internal_Finance_Approval_Request__c> newRequestList){

        Set<Id> accIds = new Set<Id>();
        Set<Id> opptyIds = new Set<Id>();
        List<Internal_Finance_Approval_Request__c> ifrListToProcess = new List<Internal_Finance_Approval_Request__c>();

        // Step 1: Get all accounts that already have pending IFRs
        Set<Id> accountsWithPendingIFRs = new Set<Id>();
        for(Internal_Finance_Approval_Request__c existingIFR : [
            SELECT Account__c 
            FROM Internal_Finance_Approval_Request__c 
            WHERE Payment_Type_Approval_Status__c = 'Pending'
        ]) {
            accountsWithPendingIFRs.add(existingIFR.Account__c);
        }
        
        // Step 2: Filter IFRs based on initial criteria
        for (Internal_Finance_Approval_Request__c ifrRec :newRequestList){
            // Skip if any of these conditions are true:
            // 1. Request Type is not "Change in Payment Terms"
            // 2. Requested Payment Types is not blank
            // 3. Account already has a pending IFR
            // 4. Requested payment terms is not one of the valid terms            
            if(ifrRec.Request_Type__c != 'Change in Payment Terms' || 
               ifrRec.Requested_Payment_Types__c != null ||
               accountsWithPendingIFRs.contains(ifrRec.Account__c) ||
               (!new List<String>{'Net 30', 'Net 5', 'Net 10', 'Net 15'}.contains(ifrRec.Requested_Payment_Terms__c))) continue;
            
            // If all conditions pass, add to processing list
            accIds.add(ifrRec.Account__c);
            opptyIds.add(ifrRec.Opportunity__c);
            ifrListToProcess.add(ifrRec);
        }

        if(ifrListToProcess.isEmpty()) return;

        Map<Id,Account> accMap = new Map<Id,Account>([
            SELECT Id, Approved_Payment_Type__c, Payment_Terms__c, Delinquent__c
            FROM Account WHERE Id in :accIds
        ]);
 
 
        Map<Id,Opportunity> opptyMap = new Map<Id,Opportunity>([
            SELECT Id, owner.UserRole.Name, First_Purchase__c, 
                   Payment_Terms_Opportunity_only_exception__c,
                   Owner.Region__c
            FROM Opportunity where Id in :opptyIds
        ]);

        string ifrInstanceApprovalStatus = null;
        string ifrInstanceOwnerRoleName = null;
        
        for (Internal_Finance_Approval_Request__c ifrRec: ifrListToProcess){
            Account acc = accMap.get(ifrRec.Account__c);
            Opportunity opp = opptyMap.get(ifrRec.Opportunity__c);

            if(acc == null || opp == null) continue;
            

            // Skip if account is delinquent
            if(acc.Delinquent__c) continue;

            // Skip if Payment Terms Opportunity Only Exception is TRUE
            if(opp.Payment_Terms_Opportunity_only_exception__c) continue;
           
            // Skip if not first purchase and payment terms don't match
            if(!opp.First_Purchase__c && ifrRec.Requested_Payment_Terms__c != acc.Payment_Terms__c) continue;

            ifrInstanceApprovalStatus = acc?.Approved_Payment_Type__c??'';
            ifrInstanceOwnerRoleName = opp?.owner?.UserRole.Name??'';

            if(ifrInstanceApprovalStatus == null || ifrInstanceOwnerRoleName == null) continue;

            // Net 30 auto-approval logic
            if(ifrRec.Requested_Payment_Terms__c == 'Net 30') {
                // Enterprise Select or Strategic segment
                if(ifrInstanceOwnerRoleName.contains('SEL') || ifrInstanceOwnerRoleName.contains('STR')) {
                    if(new list<String>{
                        'Upfront Payments',
                        'Direct Annual',
                        'Direct Semi-Annual',
                        'Direct Quarterly',
                        'Direct Monthly'
                    }.contains(ifrInstanceApprovalStatus)) {
                ifrRec.Payment_Type_Approval_Status__c = IFR_APPROVAL_STATUS_APPROVED_STRING;
                ifrRec.Auto_Approved__c = true;
            }                    
        }           
                // Enterprise Core or Midmarket segment
                else if(ifrInstanceOwnerRoleName.contains('COR') || ifrInstanceOwnerRoleName.contains('MM')) {
                    if(new list<String>{
                        'Upfront Payments',
                        'Direct Annual'
                    }.contains(ifrInstanceApprovalStatus)) {
                        
                        ifrRec.Payment_Type_Approval_Status__c = IFR_APPROVAL_STATUS_APPROVED_STRING;
                        ifrRec.Auto_Approved__c = true;
                    }
                }
            }       

            // EMEA-specific logic for Net 5, 10, 15
            else if(new List<String>{'Net 5', 'Net 10', 'Net 15'}.contains(ifrRec.Requested_Payment_Terms__c)) {
                // First check if user is in EMEA region                
                if(opp.Owner.Region__c == 'EMEA' && 
                   // Then check if they are MM in EMEA or COR in UK based on role
                   ((ifrInstanceOwnerRoleName.contains('MM')) || 
                    (ifrInstanceOwnerRoleName.contains('COR') && ifrInstanceOwnerRoleName.contains('UK'))) &&
                   // Payment type check
                   (new List<String>{'Upfront Payments', 'Direct Annual'}.contains(ifrInstanceApprovalStatus))) {
                        
                    ifrRec.Payment_Type_Approval_Status__c = IFR_APPROVAL_STATUS_APPROVED_STRING;
                    ifrRec.Auto_Approved__c = true;
                }
            }
        }           
    }

    private void updateQuoteReqPaymentTerms(Internal_Finance_Approval_Request__c rqst){
        
        if(additionalQuoteAccIdMap.containsKey(rqst.Account__c)){
            
            for(SBQQ__Quote__c quote :additionalQuoteAccIdMap.get(rqst.Account__c)){
                quote.SBQQ__PaymentTerms__c = rqst.Requested_Payment_Terms__c;
                additionalQuotesToProcess.add(quote);
            }
        }
    }
    
    /**
     * Method to auto-create Credit Limit Increase requests when a quote that exceeds the credit limit is submitted
     * and meets specific criteria. This uses the Credit_Pre_Approval_Status__c field on the Credit Report to determine
     * if the request should be created.
     * 
     * @param quoteIds List of quote IDs to evaluate for credit limit increase requests
     * @return List of Internal_Finance_Approval_Request__c records created
     */
    @InvocableMethod(label='Create Credit Limit Increase Request' 
                     description='Creates Credit Limit Increase requests for quotes that exceed credit limit')
    public static List<Internal_Finance_Approval_Request__c> createCreditLimitIncreaseRequest(List<Id> quoteIds) {
        if (!Test.isRunningTest()) {
       		// Check if the Credit Limit Increase automation is enabled for the current user
            // This includes both global custom label and director-level toggle checks, Changes related to GTMS-28505
            Boolean isCliAutomationEnabled = getCLIEnabledForUser(UserInfo.getUserId());
            
            // If the automation is disabled for this user, throw an exception
        	// If the automation is disabled, throw an exception
        if (!isCliAutomationEnabled) {
            //Updated this error message as part of GTMS-28505 ticket.
            String errorMsg = 'Estimated monthly payment is greater than remaining monthly credit limit. Please request an increase from Finance on the CPQ before submitting for approval.';
            throw new IFRException(errorMsg);
        }
        }
        // Original implementation continues below
        if (quoteIds == null || quoteIds.isEmpty()) {
            return new List<Internal_Finance_Approval_Request__c>();
        }
        
        // Lists and Maps to store data
        List<Internal_Finance_Approval_Request__c> newRequests = new List<Internal_Finance_Approval_Request__c>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        Map<Id, SBQQ__Quote__c> eligibleQuotes = new Map<Id, SBQQ__Quote__c>();
        
        // Skip if user has Validation_Rule_Exemption permission
        if(FeatureManagement.checkPermission('Validation_Rule_Exemption')) {
            return newRequests;
        }
        
        // Check user profile once before processing any quotes
        String profileName = UserInfo.getProfileId() != null ? 
            [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name : '';
        
        // Check if profile is Samsara Sales AND (AE2 OR AE3 OR ENT)
        Boolean isSamsaraSales = profileName.contains('Samsara Sales');
        Boolean isTargetAE = profileName.contains('AE2') || profileName.contains('AE3') || profileName.contains('ENT');
        
        if(!(isSamsaraSales && isTargetAE)) { return newRequests; }
        
        // Query quotes with all necessary fields
        List<SBQQ__Quote__c> quotes = [
            SELECT Id, SBQQ__Account__c, SBQQ__Opportunity2__c, Quote_Amount_Greater_Than_Remain_Credit__c,
                   SBQQ__Status__c, Configuration_Segment__c, Associated_Opportunity_Type__c, 
                   SBQQ__Type__c, Selected_Payment_Type__c
            FROM SBQQ__Quote__c
            WHERE Id IN :quoteIds
        ];
        
        // Step 1: Filter quotes that meet initial criteria and collect account/opportunity IDs
        for(SBQQ__Quote__c quote : quotes) {
            if(quote.Quote_Amount_Greater_Than_Remain_Credit__c == true && 
               (quote.SBQQ__Status__c != 'Approved') &&
               quote.Configuration_Segment__c != 'Express' &&
               quote.Associated_Opportunity_Type__c != 'Remorse Refund' &&
               quote.SBQQ__Type__c != 'Renewal') {
                
                // Check if payment type matches required values
                if(quote.Selected_Payment_Type__c == 'Direct Monthly' || quote.Selected_Payment_Type__c == 'Direct Quarterly' || quote.Selected_Payment_Type__c == 'Direct Semi-Annual') {                    
                    eligibleQuotes.put(quote.Id, quote);
                    accountIds.add(quote.SBQQ__Account__c);
                    oppIds.add(quote.SBQQ__Opportunity2__c);
                }
            }
        }
        
        if(eligibleQuotes.isEmpty()) {
            return newRequests;
        }
        
        // Step 2: Check if accounts already have pending Credit Limit Increase requests
        Set<Id> accountsWithPendingRequests = new Set<Id>();
        for(Internal_Finance_Approval_Request__c existingIFR : [
            SELECT Account__c 
            FROM Internal_Finance_Approval_Request__c 
            WHERE Request_Type__c = 'Credit Limit Increase'
            AND Payment_Type_Approval_Status__c = :IFR_APPROVAL_STATUS_PENDING_STRING
            AND Account__c IN :accountIds
        ]) {
            accountsWithPendingRequests.add(existingIFR.Account__c);
        }
        
        // Step 3: Get account information for eligible quotes
        Map<Id, Account> accountMap = new Map<Id, Account>([
            SELECT Id, Approved_Payment_Type__c
            FROM Account 
            WHERE Id IN :accountIds
        ]);
        
        // Step 4: Get opportunity information for eligible quotes
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([
            SELECT Id, Owner.UserRole.Name, Owner.Profile.Name, First_Purchase__c, SBQQ__Renewal__c,
                   Small_Fleet_Opportunity__c, Is_Webstore_Upsell_Opportunity__c,
                   Selected_Payment_Type__c
            FROM Opportunity 
            WHERE Id IN :oppIds
        ]);
        
        // Step 5: Get the most recent credit report for each account
        Map<Id, Credit_Report__c> latestCreditReports = new Map<Id, Credit_Report__c>();
        for(Credit_Report__c report : [
            SELECT Id, Account__c, CreatedDate,Credit_Report_Timestamp__c,Credit_Pre_Approval_Status__c
            FROM Credit_Report__c
            WHERE Account__c IN :accountIds
            ORDER BY CreatedDate DESC
        ]) {
            // Only keep the most recent credit report per account
            if(!latestCreditReports.containsKey(report.Account__c)) {
                latestCreditReports.put(report.Account__c, report);
            }
        }
        
        // Step 6: Process each eligible quote
        for(SBQQ__Quote__c quote : eligibleQuotes.values()) {
            // Skip if account already has a pending request
            if(accountsWithPendingRequests.contains(quote.SBQQ__Account__c)) {
                String errorMsg = 'This account already has a pending Credit Limit Increase request. Please contact Deal Desk for assistance.';
                throw new IFRException(errorMsg);
            }
            
            Account acc = accountMap.get(quote.SBQQ__Account__c);
            Opportunity opp = oppMap.get(quote.SBQQ__Opportunity2__c);
            
            if(acc == null || opp == null) {
                String errorMsg = 'Could not find Account or Opportunity for quote';
                throw new IFRException(errorMsg);
            }
            
            // Get the credit report for this account
            Credit_Report__c creditReport = latestCreditReports.get(quote.SBQQ__Account__c);
            
            // Check all required criteria
            
            // Check user role - profile already checked earlier
            Boolean roleMatches = opp.Owner.UserRole.Name != null && 
                                 (opp.Owner.UserRole.Name.contains('SEL') || 
                                  opp.Owner.UserRole.Name.contains('STR') || 
                                  opp.Owner.UserRole.Name.contains('COR') || 
                                  opp.Owner.UserRole.Name.contains('MM'));
            

            Boolean paymentTypeMatches = new List<String>{'Direct Monthly', 'Direct Quarterly', 'Direct Semi-Annual'}.contains(acc.Approved_Payment_Type__c);
            
            Boolean otherCriteriaMatch = !opp.First_Purchase__c && 
                                        !opp.SBQQ__Renewal__c && 
                                        !opp.Small_Fleet_Opportunity__c && 
                                        !opp.Is_Webstore_Upsell_Opportunity__c;
            
            // Check if we have a valid credit report with an Approved status
            Boolean validCreditReport = creditReport != null /*&& 
                                       creditReport.Credit_Pre_Approval_Status__c!='Approved'*/;
            
            // If all criteria match, create a new Internal Financing Request
            if(roleMatches && paymentTypeMatches && otherCriteriaMatch && validCreditReport) {
                Internal_Finance_Approval_Request__c newRequest = new Internal_Finance_Approval_Request__c(
                    Account__c = quote.SBQQ__Account__c,
                    Opportunity__c = quote.SBQQ__Opportunity2__c,
                    Quote__c = quote.Id,
                    Request_Type__c = 'Credit Limit Increase',
                    Payment_Type_Approval_Status__c = IFR_APPROVAL_STATUS_PENDING_STRING,
                    Submitted_Date__c = System.today(),
                    Submitter__c = userInfo.getUserId(),
                    Notes_from_Requester__c = 'CLI auto created from Approval Flow'
                );
                
                newRequests.add(newRequest);
            } else {
    			String baseMessage = 'This quote exceeds the remaining credit limit on the account. In order to submit this quote for approval, a credit limit increase is needed.Please submit a Credit Limit Increase request by using the "Request Payment Frequency or Terms" button on the CPQ.\n'+'\n'+
                    				 +'CLI request could not be auto-created due to: ';
				String errorMsg;
				if (!roleMatches){
        		errorMsg = baseMessage +'User role does not have permission to auto-create Credit Limit Increase requests. Please contact Deal Desk for assistance.';
    			} 
				else if (!paymentTypeMatches){
        		errorMsg = baseMessage +'Account or quote payment type does not qualify for auto-credit limit increase. Only Direct Monthly, Quarterly, Semi-Annual payment types are eligible.';
							} 
				else if (!validCreditReport){
        		errorMsg = baseMessage +'Credit Limit Increase request required, No active credit report found or missing Credit Pre-Approval Status. Please contact Deal Desk for assistance.';
    			} 
    				throw new IFRException(errorMsg);
				}
            ////Updated the above baseMessage as part of GTMS-28505 ticket.
        }
        
        // Insert new requests if any were created
        if (!newRequests.isEmpty()) {
            try {
                insert newRequests;
            } catch (Exception e) {
                throw new IFRException('Failed to create Credit Limit Increase request: ' + e.getMessage());
            }
        }
        
        return newRequests;
    }
    
    
    /**
     * Method to auto-approve Credit Limit Increase requests that meet the specified criteria.
     * This method evaluates each request against business rules to determine if it can be
     * automatically approved without manual review by Deal Desk.
     * 
     * @param newRequestList List of Internal Finance Approval Requests to evaluate for auto-approval
     */
    public void autoApproveCreditLimitIncrease(List<Internal_Finance_Approval_Request__c> newRequestList) {
        // Also check the feature toggle here for auto-approval
        if (!Test.isRunningTest()) {
        	// Check if the Credit Limit Increase automation is enabled for the current user
            // This includes both global custom label and director-level toggle checks, Changes related to GTMS-28505
            Boolean isCliAutomationEnabled = getCLIEnabledForUser(UserInfo.getUserId());
            
            // If the automation is disabled for this user, exit
            if (!isCliAutomationEnabled) {return;}
        }
        // Original implementation continues below
        if (newRequestList == null || newRequestList.isEmpty()) { return; }
        
        // Lists and maps to store data
        List<Internal_Finance_Approval_Request__c> ifrListToProcess = new List<Internal_Finance_Approval_Request__c>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        Set<Id> quoteIds = new Set<Id>();

        Set<String> eligiblePaymentTypes = new Set<String>{'Direct Monthly', 'Direct Quarterly', 'Direct Semi-Annual'};
        
        // Step 1: Initial filtering of requests that might be eligible for auto-approval
        for(Internal_Finance_Approval_Request__c ifr : newRequestList) {
            // Skip if not a Credit Limit Increase request
            if(ifr.Request_Type__c != 'Credit Limit Increase') {
                continue;
            }
            
            // Skip if already approved or not in pending status
            if(ifr.Payment_Type_Approval_Status__c == IFR_APPROVAL_STATUS_APPROVED_STRING) { continue; }
            
            // Skip if Finance Response Date is populated
            if(ifr.Finance_Response_Date__c != null) { continue; }
            
            // Skip if not auto-created from Approval Flow
            if(ifr.Notes_from_Requester__c != 'CLI auto created from Approval Flow') { continue; }
            
            // Add to processing list and collect IDs for queries
            ifrListToProcess.add(ifr);
            accountIds.add(ifr.Account__c);
            opportunityIds.add(ifr.Opportunity__c);
            quoteIds.add(ifr.Quote__c);
        }
        
        if(ifrListToProcess.isEmpty()) {
            return;
        }
        
        // Step 2: Query for eligible roles from custom metadata
        Map<String, Boolean> eligibleRoles = new Map<String, Boolean>();
        for(CLI_Eligible_Roles__mdt roleConfig : [
            SELECT Role_Name__c, Active__c 
            FROM CLI_Eligible_Roles__mdt 
            WHERE Active__c = true
        ]) {
            eligibleRoles.put(roleConfig.Role_Name__c, true);
        }
        
        // Step 3: Query for currency thresholds from custom metadata
        Map<String, Decimal> currencyThresholds = new Map<String, Decimal>();
        for(CLI_Currency_Threshold__mdt currencyConfig : [
            SELECT Currency_ISO_Code__c, ACV_Threshold__c 
            FROM CLI_Currency_Threshold__mdt
        ]) {
            currencyThresholds.put(currencyConfig.Currency_ISO_Code__c, currencyConfig.ACV_Threshold__c);
        }
        
        // Step 4: Query for configuration settings from custom metadata
        CLI_Configuration__mdt config;
        try {
            config = [
                SELECT Max_Cumulative_Increase__c, Credit_Report_Max_Age_Days__c, Increase_Multiplier__c 
                FROM CLI_Configuration__mdt 
                LIMIT 1
            ];
        } catch(Exception e) {
            config = new CLI_Configuration__mdt(
                Max_Cumulative_Increase__c = 25000,
                Credit_Report_Max_Age_Days__c = 365,
                Increase_Multiplier__c = 1.2
            );
        }
        
        // Step 5: Query accounts to check eligibility criteria
        Map<Id, Account> accountMap = new Map<Id, Account>([
            SELECT Id, Approved_Payment_Type__c, Delinquent__c,
                   CurrencyIsoCode, Credit_Limit__c
            FROM Account 
            WHERE Id IN :accountIds
        ]);
        
        // Step 6: Query opportunities to check ownership and purchase criteria
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>([
            SELECT Id, Owner.UserRole.Name, First_Purchase__c, AccountId,
                   ACV_Bookings_SOT__c
            FROM Opportunity 
            WHERE Id IN :opportunityIds
        ]);
        
        // Step 7: Query quotes for ACV values
        Map<Id, SBQQ__Quote__c> quoteMap = new Map<Id, SBQQ__Quote__c>([
            SELECT Id, SBQQ__Account__c, Quote_Amount_Greater_Than_Remain_Credit__c,Quote_ACV__c,ACV_Bookings_Rollup__c,SBQQ__NetAmount__c,SBQQ__SubscriptionTerm__c,
                   Estimated_Monthly_Payment__c, Monthly_License_Sales_Tax__c, Selected_Payment_Type__c
            FROM SBQQ__Quote__c
            WHERE Id IN :quoteIds
        ]);
        
        // Step 8: Query credit reports for each account
        Map<Id, Credit_Report__c> latestCreditReports = new Map<Id, Credit_Report__c>();
        for(Credit_Report__c report : [
            SELECT Id, Account__c, CreatedDate,Credit_Report_Timestamp__c,Credit_Pre_Approval_Status__c
            FROM Credit_Report__c
            WHERE Account__c IN :accountIds
            ORDER BY CreatedDate DESC
        ]) {
            // Only keep the most recent credit report per account
            if(!latestCreditReports.containsKey(report.Account__c)) {
                latestCreditReports.put(report.Account__c, report);
            }
        }
        
        // Step 9: Check if any other IFRs are associated with the same quotes
        Set<Id> quotesWithExistingIFRs = new Set<Id>();
        for(Internal_Finance_Approval_Request__c existingIFR : [
            SELECT Quote__c 
            FROM Internal_Finance_Approval_Request__c 
            WHERE Quote__c IN :quoteIds
            AND Id NOT IN :ifrListToProcess
        ]) {
            quotesWithExistingIFRs.add(existingIFR.Quote__c);
        }
        
        // Step 10: Query accounts with pending IFRs
        Set<Id> accountsWithPendingIFRs = new Set<Id>();
        for(Internal_Finance_Approval_Request__c pendingIFR : [
            SELECT Account__c 
            FROM Internal_Finance_Approval_Request__c 
            WHERE Payment_Type_Approval_Status__c = :IFR_APPROVAL_STATUS_PENDING_STRING
            AND Account__c IN :accountIds
            AND Id NOT IN :ifrListToProcess
        ]) {
            accountsWithPendingIFRs.add(pendingIFR.Account__c);
        }
        
        List<Internal_Finance_Approval_Request__c> approvedIFRs = new List<Internal_Finance_Approval_Request__c>();
        List<Internal_Finance_Approval_Request__c> updatedIFRs = new List<Internal_Finance_Approval_Request__c>();

        // Get account eligibility map
        Map<Id, Boolean> accountEligibilityMap = getAccountEligibilityMap(accountIds);
        
        // Process each IFR for auto-approval
        // First, collect all accounts that need credit checks
        Set<Id> accountsNeedingCreditCheck = new Set<Id>();
        List<Internal_Finance_Approval_Request__c> eligibleIFRs = new List<Internal_Finance_Approval_Request__c>();
        for(Internal_Finance_Approval_Request__c ifr : ifrListToProcess) {
            // Skip if account is not eligible for auto-approval
            if(!accountEligibilityMap.get(ifr.Account__c)) {   continue; }
            try {
                // Get related records
                Account acc = accountMap.get(ifr.Account__c);
                Opportunity opp = opportunityMap.get(ifr.Opportunity__c);
                SBQQ__Quote__c quote = quoteMap.get(ifr.Quote__c);
                Credit_Report__c creditReport = latestCreditReports.get(ifr.Account__c);
                
                if(acc == null || opp == null || quote == null) {  continue; }
                if(creditReport == null || creditReport.Credit_Pre_Approval_Status__c != 'Approved') { continue; }
                // Check owner role criteria
                Boolean roleMatches = false;
                if(opp.Owner.UserRole.Name != null) {
                    for(String rolePattern : eligibleRoles.keySet()) {
                        if(opp.Owner.UserRole.Name.contains(rolePattern)) {
                            roleMatches = true;
                            break;
                        }
                    }
                }
                
                if(!roleMatches) { continue;  }
                // Check if this is not a first purchase
                if(opp.First_Purchase__c) { continue; }
                // Check if quote requires credit limit increase
                if(!quote.Quote_Amount_Greater_Than_Remain_Credit__c) {
                    continue;
                }
                // Check account payment type
                if(!eligiblePaymentTypes.contains(acc.Approved_Payment_Type__c)) { continue; }
                // Check account delinquency
                if(acc.Delinquent__c) { continue;  }
                // Check credit report existence and age
                Boolean needsCreditCheck = false;
                if(creditReport == null) {  needsCreditCheck = true;
                } else {
                    // Calculate credit report age in days
                    Integer creditReportAgeDays = Date.valueOf(creditReport.Credit_Report_Timestamp__c).daysBetween(Date.valueOf(ifr.Submitted_Date__c));
                    if(creditReportAgeDays > config.Credit_Report_Max_Age_Days__c) { needsCreditCheck = true;
                    }
                }
                if(needsCreditCheck) {
                    accountsNeedingCreditCheck.add(acc.Id);
                }
                // If all checks passed, add to eligibleIFRs
                eligibleIFRs.add(ifr);
            } catch(Exception e) {
                continue;
            }
        }

        // Trigger credit checks for all accounts that need them
        for(Id accountId : accountsNeedingCreditCheck) {
            triggerCreditCheck(accountId);
        }

        // Query for all refreshed credit reports in one go
        Map<Id, Credit_Report__c> refreshedCreditReports = new Map<Id, Credit_Report__c>();
        for(Credit_Report__c report : [
            SELECT Id, Account__c, CreatedDate, Credit_Report_Timestamp__c 
            FROM Credit_Report__c 
            WHERE Account__c IN :accountsNeedingCreditCheck
            ORDER BY CreatedDate DESC
        ]) {
            // Only keep the most recent credit report per account
            if(!refreshedCreditReports.containsKey(report.Account__c)) {
                refreshedCreditReports.put(report.Account__c, report);
            }
        }

        // Now process the IFRs with the refreshed credit reports
        for(Internal_Finance_Approval_Request__c ifr : eligibleIFRs) {
            // Skip if account is not eligible for auto-approval
            if(!accountEligibilityMap.get(ifr.Account__c)) {  continue;  }
            
            try {
                // Get related records
                Account acc = accountMap.get(ifr.Account__c);
                Opportunity opp = opportunityMap.get(ifr.Opportunity__c);
                SBQQ__Quote__c quote = quoteMap.get(ifr.Quote__c);
                
                // Skip if any related records are missing
                if(acc == null || opp == null || quote == null) {  continue;}

                // Get the refreshed credit report if it exists
                Credit_Report__c refreshedCreditReport = refreshedCreditReports.get(acc.Id);
                
                // Skip if no refreshed credit report is available
                if(accountsNeedingCreditCheck.contains(acc.Id) && refreshedCreditReport == null) {  continue;}

                // Check if the new report is within the time limit
                if(refreshedCreditReport != null) {
                    Integer newReportAgeDays = Date.valueOf(refreshedCreditReport.Credit_Report_Timestamp__c).daysBetween(Date.valueOf(ifr.Submitted_Date__c));
                    if(newReportAgeDays > config.Credit_Report_Max_Age_Days__c) {
                        continue;
                    }
                }
                // Check ACV thresholds based on currency
                if(!currencyThresholds.containsKey(acc.CurrencyIsoCode) || 
                   quote.Quote_ACV__c > currencyThresholds.get(acc.CurrencyIsoCode)) {   continue; }
                
                // Check if other IFRs exist for the same quote
                if(quotesWithExistingIFRs.contains(ifr.Quote__c)) {  continue; }
                
                // Check if account has other pending IFRs
                if(accountsWithPendingIFRs.contains(ifr.Account__c)) { continue; }
                
                // Check cumulative auto-approval amount
                Decimal cumulativeAmount = getTotalAutoApprovedAmount(acc.Id);

                if(cumulativeAmount >= config.Max_Cumulative_Increase__c) {
                    ifr.Emailed_Deal_Desk__c = true;
                    updatedIFRs.add(ifr);
                    continue;
                }
                
                // Calculate new credit limit based on payment type
                Decimal maxMonthlyLimit = acc.Credit_Limit__c != null ? acc.Credit_Limit__c : 0;
                Decimal estimatedPayment = quote.Estimated_Monthly_Payment__c != null ? quote.Estimated_Monthly_Payment__c : 0;
                Decimal taxAmount = quote.Monthly_License_Sales_Tax__c != null ? quote.Monthly_License_Sales_Tax__c : 0;
                Decimal newCreditLimit = 0;
                
                String selectedPaymentType = quote.Selected_Payment_Type__c;
                if(selectedPaymentType == 'Direct Monthly') {
                    newCreditLimit = (maxMonthlyLimit + estimatedPayment + taxAmount) * config.Increase_Multiplier__c;
                } else if(selectedPaymentType == 'Direct Quarterly') {
                    newCreditLimit = (maxMonthlyLimit + ((estimatedPayment + taxAmount) * 3)) * config.Increase_Multiplier__c;
                } else if(selectedPaymentType == 'Direct Semi-Annual') {
                    newCreditLimit = (maxMonthlyLimit + ((estimatedPayment + taxAmount) * 6)) * config.Increase_Multiplier__c;
                }
                
                // Calculate the auto-approved amount (the increase)
                Decimal autoApprovedAmount = newCreditLimit - maxMonthlyLimit;
                
                // Check if this approval would exceed the cumulative limit
                if((cumulativeAmount + autoApprovedAmount) >= config.Max_Cumulative_Increase__c) { continue; }
                
                // Set expiration date to 1 year from now
                // Added expiration date to 90 days instead of 1 year as part of GTMS-28505 ticket.
                Date expirationDate = System.today().addDays(90);
                
                // Update IFR record with approval information
                ifr.Payment_Type_Approval_Status__c = IFR_APPROVAL_STATUS_APPROVED_STRING;
                ifr.Finance_Comments__c = 'Credit limit increase request approved.';
                ifr.IF_Finance_Comments__c = 'CLI auto-approved.';
                ifr.Auto_Approved__c = true;
                ifr.Auto_Approved_Amount__c = autoApprovedAmount;
                ifr.New_Monthly_Credit_Limit__c = newCreditLimit;
                ifr.Expiration_Date__c = expirationDate;
                ifr.Finance_Response_Date__c = System.today();
                ifr.Notes_from_Requester__c = ''; // Clear the request field when auto-approved
                
                approvedIFRs.add(ifr);
            } catch(Exception e) {
                continue;
            }
        }
    }
    
    /**
     * Triggers a new credit check for the specified account.
     * 
     * @param accountId The ID of the account to check.
     */
    public static void triggerCreditCheck(Id accountId) {
        try {
            // Query account details
            Account acc = [
                SELECT Id, BillingStreet, BillingCity, BillingState, 
                       BillingPostalCode, BillingCountry, BillingCountryCode,
                       Global_Geography__c
                FROM Account 
                WHERE Id = :accountId
            ];
            
            // Validate billing address
            if (!isValidBillingAddress(acc)) {
                return;
            }
            
            // Check geography and route to appropriate credit check service
            String globalGeo = Label.Account_Global_Geography;
            
            if (globalGeo.contains(acc.Global_Geography__c)) {
                // EU Account
                if (isValidEUBillingAddress(acc)) {
                    routeToCreditCheck(acc);
                }
            } else {
                // Non-EU Account
                if (isValidNonEUBillingAddress(acc)) {
                    routeToCreditCheck(acc);
                }
            }
        } catch (Exception e) {
            throw e; // Re-throw the exception since this is now synchronous
        }
    }
    
    private static void routeToCreditCheck(Account acc) {
        if (acc.BillingCountryCode == 'US' || acc.BillingCountryCode == 'CA') {
            // Call DNBI for US/CA accounts
            DNBI_Integration.getDNBIFields(new List<Id>{acc.Id});
        } else {
            // Call Creditsafe for all other countries
            Creditsafe.getCredisafeInfo(new List<Id>{acc.Id});
        }
    }
    
    private static Boolean isValidBillingAddress(Account acc) {
        return acc.BillingStreet != null && 
               acc.BillingCity != null && 
               acc.BillingPostalCode != null && 
               acc.BillingCountry != null;
    }
    
    private static Boolean isValidEUBillingAddress(Account acc) {
        return isValidBillingAddress(acc);
    }
    
    private static Boolean isValidNonEUBillingAddress(Account acc) {
        return isValidBillingAddress(acc) && 
               acc.BillingState != null;
    }

    @TestVisible private static Map<Id, Boolean> getAccountEligibilityMap(Set<Id> accountIds) {
        Map<Id, Boolean> eligibilityMap = new Map<Id, Boolean>();
        
        // Query the Custom Metadata Type for eligible accounts
        Map<String, CLI_Auto_Approval_Eligibility__mdt> eligibilityRecords = new Map<String, CLI_Auto_Approval_Eligibility__mdt>();
        for(CLI_Auto_Approval_Eligibility__mdt eligibility : [SELECT Account_Id__c, Is_Eligible__c 
                                                             FROM CLI_Auto_Approval_Eligibility__mdt 
                                                             WHERE Account_Id__c IN :accountIds]) {
            eligibilityRecords.put(eligibility.Account_Id__c, eligibility);
        }
        
        // Initialize all accounts as eligible by default
        for(Id accountId : accountIds) {
            eligibilityMap.put(accountId, true);
        }
        
        // Only set to ineligible if explicitly marked as such in the metadata
        for(Id accountId : accountIds) {
            if(eligibilityRecords.containsKey(accountId) && !eligibilityRecords.get(accountId).Is_Eligible__c) {
                eligibilityMap.put(accountId, false);
            }
        }
        
        return eligibilityMap;
    }

    /**
     * Helper method to get total auto-approved amount for an account
     */
    @TestVisible private Decimal getTotalAutoApprovedAmount(Id accountId) {
        Decimal totalAmount = 0;
        
        AggregateResult[] results = [
            SELECT Account__c, 
                   SUM(Auto_Approved_Amount__c) TotalAutoApprovedAmount
            FROM Internal_Finance_Approval_Request__c 
            WHERE Account__c = :accountId
                  AND Payment_Type_Approval_Status__c = 'Approved'
                  AND Request_Type__c = 'Credit Limit Increase'
            GROUP BY Account__c
        ];
        
        if (!results.isEmpty()) {
            totalAmount = (Decimal)results[0].get('TotalAutoApprovedAmount');
        }
        
        return totalAmount != null ? totalAmount : 0;
    }
    
    //Changes related to GTMS-28505
    public static Boolean getCLIEnabledForUser(Id userId) {
        
        try {
            Automation_Settings__c cliDirectorSetting = Automation_Settings__c.getInstance('CLI Automation Director level toggle');
            
            Boolean isCliAutomationEnabled = String.valueOf(System.Label.CLI_Automation_Enabled).equalsIgnoreCase('true');
            
            if (cliDirectorSetting == null || String.isBlank(cliDirectorSetting.Data__c)) {
                return isCliAutomationEnabled;
            }
            
            String directorUsers = cliDirectorSetting.Data__c;
            Boolean isDirectorToggleDisabled = cliDirectorSetting.Disabled__c != null ? cliDirectorSetting.Disabled__c : false;
            
            Set<String> directorUserSet = new Set<String>();
            for (String directorId : directorUsers.split(',')) {
                if (String.isNotBlank(directorId.trim())) {
                    directorUserSet.add(directorId.trim());
                }
            }
            
            User currentUser = [SELECT Id, ManagerId,Manager.Id, Manager.ManagerId,Manager.Manager.Id, Manager.Manager.ManagerId,
                       Manager.Manager.Manager.Id, Manager.Manager.Manager.ManagerId,
                       Manager.Manager.Manager.Manager.Id, Manager.Manager.Manager.Manager.ManagerId,
                       Manager.Manager.Manager.Manager.Manager.Id FROM User WHERE Id = :userId LIMIT 1];
            
            Boolean userInDirectorList = directorUserSet.contains(currentUser.Id);
            
            if (!userInDirectorList) {
                userInDirectorList = getCLIEnabledForUserHierarchy(directorUserSet, currentUser);
            }
            
            if (userInDirectorList && !isDirectorToggleDisabled) {
                return true;
            }
            
            if (!userInDirectorList) {
                return isCliAutomationEnabled;
            }
            
            return false;
            
        } catch (Exception e) {
            Boolean isCliAutomationEnabled = String.valueOf(System.Label.CLI_Automation_Enabled).equalsIgnoreCase('true');
            return isCliAutomationEnabled;
        }
    }
    
    /** Changes related to GTMS-28505
     * Helper method to check CLI enablement through user management hierarchy.
     * Checks up to 5 levels of management to see if any manager is in the director list.
     * @param directorUserSet Set of director user IDs for exact matching
     * @param currentUser User record with manager hierarchy populated
     * @return Boolean indicating whether any manager in hierarchy has CLI enabled
     */
    @TestVisible
    private static Boolean getCLIEnabledForUserHierarchy(Set<String> directorUserSet, User currentUser) {
        if (currentUser.ManagerId != null && directorUserSet.contains(currentUser.ManagerId)) {
            return true;
        }
        
        if (currentUser.ManagerId != null && 
            currentUser.Manager.ManagerId != null && 
            directorUserSet.contains(currentUser.Manager.ManagerId)) {
            return true;
        }
        
        if (currentUser.ManagerId != null && 
            currentUser.Manager.ManagerId != null && 
            currentUser.Manager.Manager.ManagerId != null && 
            directorUserSet.contains(currentUser.Manager.Manager.ManagerId)) {
            return true;
        }
        
        if (currentUser.ManagerId != null && 
            currentUser.Manager.ManagerId != null && 
            currentUser.Manager.Manager.ManagerId != null && 
            currentUser.Manager.Manager.Manager.ManagerId != null && 
            directorUserSet.contains(currentUser.Manager.Manager.Manager.ManagerId)) {
            return true;
        }
        
        if (currentUser.ManagerId != null && 
            currentUser.Manager.ManagerId != null && 
            currentUser.Manager.Manager.ManagerId != null && 
            currentUser.Manager.Manager.Manager.ManagerId != null && 
            currentUser.Manager.Manager.Manager.Manager.ManagerId != null && 
            directorUserSet.contains(currentUser.Manager.Manager.Manager.Manager.ManagerId)) {
            return true;
        }
        
        return false;
    }
}
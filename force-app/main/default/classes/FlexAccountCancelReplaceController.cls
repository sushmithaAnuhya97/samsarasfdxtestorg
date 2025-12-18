/*********************************************************************************************************************************************
 * @Test class: FlexAccountCancelReplaceControllerTest
* Date      	- Project#       - Developer/ Company      	       - Description
* --------------------------------------------------------------------------------------------------------------------------------------------
* 01/06/2025    - GTMS-25705     - Anas Siddiquee/ Accenture 	   - Handles Cancel & Replace Upgraded & Amendment Quotes, QLIs, Opp creation
* 01/20/2025    - GTMS-25970     - Anas Siddiquee/ Accenture 	   - Added Logging for C&R processing
*/

public class FlexAccountCancelReplaceController {

    private static final String ERROR_PREFIX = 'Failed in FlexAccountCancelReplaceController: ';
    
    /**
     * @description Handles the Cancel & Replace amendment process for contracts
     * @param amendContracts Contract amendment details
     * @return FlexAmendResponse Response containing success/failure status
     */
    @AuraEnabled
    public static FlexAmendResponse flexAmendContracts(FlexAmendContractsMsg amendContracts) {
        FlexAmendResponse response = new FlexAmendResponse();
        Savepoint sp;
        try {
            validateInput(amendContracts);

            // Create log records
            insertLogRecords(amendContracts);

            // Set a savepoint to rollback in case of error
            sp = Database.setSavepoint();

            // Set C&R flags
            setFlags(amendContracts);

            // Create replacement records
            ReplacementRecords replacementRecs = createReplacementRecords(amendContracts);

            if (replacementRecs.isValid()) {
                // Update logs with replacement record IDs
                updateLogRecords(replacementRecs.opportunity, replacementRecs.quote, amendContracts);
                
                // Start queueable processing
                enqueueAmendProcess(amendContracts, replacementRecs);
            }

            response.success = true;
        } catch (Exception e) {
            System.debug('Error in flexAmendContracts: ' + e.getMessage() + '\n' + 'Stack Trace: ' + e.getStackTraceString());
            handleError(sp, e, amendContracts, response);
        }

        return response;

    }

    /**
     * @description Handles errors by rolling back and logging
     * @param sp Savepoint to rollback
     * @param e Exception that occurred
     * @param amendContracts Contract amendment details
     * @param response Response object to update
     */
    private static void handleError(Savepoint sp, Exception e, 
                                    FlexAmendContractsMsg amendContracts,
                                    FlexAmendResponse response) {
        Database.rollback(sp);
        
        String errorMsg = ERROR_PREFIX + e.getMessage() + '\n' + e.getStackTraceString();
        
        if (!FlexCancelReplaceHelper.logRecordList.isEmpty()) {
            updateErrorLogs(errorMsg);
            FlexLogNotifier.notifyByEmail(FlexCancelReplaceHelper.logRecordList);
        } else {
            createErrorLog(amendContracts, errorMsg);
        }
        
        response.success = false;
        response.errorMessage = errorMsg;
    }

    /**
     * @description Updates existing logs with error details
     * @param errorMsg Error message to log
     */
    private static void updateErrorLogs(String errorMsg) {
        for (Flex_Log__c log : FlexCancelReplaceHelper.logRecordList) {
            log.Status__c = 'Failed';
            log.ErrorMessage__c = String.isBlank(log.ErrorMessage__c) ? 
                errorMsg : log.ErrorMessage__c + '. \n\n' + errorMsg;
        }
        update FlexCancelReplaceHelper.logRecordList;
    }

    /**
     * @description Creates new error log when no existing logs
     * @param amendContracts Contract amendment details
     * @param errorMsg Error message to log
     */
    private static void createErrorLog(FlexAmendContractsMsg amendContracts, String errorMsg) {
        Flex_Log__c log = new Flex_Log__c(
            AccountId__c = amendContracts.accountId,
            Status__c = 'Failed',
            ContractId__c = amendContracts.contractIds[0],
            ErrorMessage__c = errorMsg
        );
        insert log;
    }

    /**
     * @description Updates log records with replacement record IDs
     * @param opportunity Created replacement opportunity
     * @param quote Created replacement quote  
     */
    private static void updateLogRecords(Opportunity opportunity, SBQQ__Quote__c quote, FlexAmendContractsMsg amendContracts) {
        List<Flex_Log__c> updateRevenueList = new List<Flex_Log__c>();
        List<ContentDocumentLink> cdLinks = new List<ContentDocumentLink>();

        // Create ContentVersion
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Quote Line Data ' + System.now().format();
        cv.PathOnClient = 'QuoteLineData.json';
        // cv.VersionData = Blob.valueOf(JSON.serializePretty(amendContracts.quoteLineData));
        cv.VersionData = Blob.valueOf(JSON.serializePretty(amendContracts));
        cv.IsMajorVersion = true;
        insert cv;

        // Get ContentDocumentId
        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        for (Flex_Log__c log : FlexCancelReplaceHelper.logRecordList) {
            log.RevenueOpportunityId__c = opportunity.Id;
            log.RevenueQuoteId__c = quote.Id;
            updateRevenueList.add(log);
            // Create ContentDocumentLinks for each log record
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = log.Id;
            cdl.ContentDocumentId = cv.ContentDocumentId;
            cdl.ShareType = 'V'; // V = Viewer permission
            cdl.Visibility = 'AllUsers';
            cdLinks.add(cdl);            
        }
        insert cdLinks;
        update updateRevenueList;
    }

    /**
     * @description Creates initial log records for each contract
     * @param amendContracts Contract amendment details
     */
    private static void insertLogRecords(FlexAmendContractsMsg amendContracts) {
        for (String contractId : amendContracts.contractIds) {
            Flex_Log__c log = new Flex_Log__c(
                AccountId__c = amendContracts.accountId,
                ContractId__c = contractId,
                Status__c = 'In Progress'
            );
            FlexCancelReplaceHelper.logRecordList.add(log);
        }
        insert FlexCancelReplaceHelper.logRecordList;
    }

    /**
     * @description Sets C&R flags on Account and Contracts
     * @param amendContracts Contract amendment details
     */
    private static void setFlags(FlexAmendContractsMsg amendContracts) {
        FlexCancelReplaceHelper.updateCNRFlagOnAccount(amendContracts.accountId, amendContracts);
        FlexCancelReplaceHelper.updateCRFlagOnContracts(amendContracts.contractIds);
    }

    /**
     * @description Starts the queueable chain for amendment processing
     * @param amendContracts Contract amendment details
     * @param replacementRecs Created replacement records
     */
    private static void enqueueAmendProcess(FlexAmendContractsMsg amendContracts, 
                                            ReplacementRecords replacementRecs) {
        FlexAmendQueueableParams params = new FlexAmendQueueableParams.Builder()
            .withContractIdList(amendContracts.contractIds)
            .withStartDate(Date.valueOf(amendContracts.startDate))
            .withReplacementQuoteId(replacementRecs.quote.Id)
            .withReplacementOppId(replacementRecs.opportunity.Id)
            .withLogRecordList(FlexCancelReplaceHelper.logRecordList)
            .withCurrentIndex(0)
            .withIsRebook(amendContracts.isRebook)
            .withOriginalAccountFlag(amendContracts.originalAccountFlag)
            .withRetryCount(0)
            .withQuoteRecalcStarted(false)
            .build();
            
        System.enqueueJob(new FlexAmendQueueable(params));
    }

    /**
     * @description Validates input parameters
     * @param amendContracts Contract amendment details to validate
     * @throws IllegalArgumentException if validation fails
     */
    private static void validateInput(FlexAmendContractsMsg amendContracts) {
        if (amendContracts == null || amendContracts.contractIds == null || amendContracts.contractIds.isEmpty()) {
            throw new IllegalArgumentException('Contract IDs are required');
        }
        if (String.isBlank(amendContracts.accountId)) {
            throw new IllegalArgumentException('Account ID is required'); 
        }
        if (String.isBlank(amendContracts.startDate)) {
            throw new IllegalArgumentException('Start date is required');
        }
    }

    /**
     * @description Creates replacement opportunity and quote
     * @param amendContracts Contract amendment details
     * @return ReplacementRecords Wrapper containing created records
     */
    private static ReplacementRecords createReplacementRecords(FlexAmendContractsMsg amendContracts) {

        List<FlexContractOpportunityController.OpportunityWrapper> opportunitiesWithExceptions =
            FlexContractOpportunityController.getOpportunitiesWithExceptions(amendContracts.contractIds);
            
        Boolean hasNoNterms = !opportunitiesWithExceptions.isEmpty();
        
        Opportunity opportunity = FlexCancelReplaceHelper.createReplacementOpp(amendContracts, hasNoNterms);
        SBQQ__Quote__c quote = opportunity != null ? 
            FlexCancelReplaceHelper.createReplacementQuote(amendContracts, opportunity) : null;
  
        if (opportunity != null) {
            FlexCancelReplaceHelper.updateReplacementOpportunityOnContracts(
                amendContracts.contractIds, opportunity.Id);
        }
        
        return new ReplacementRecords(opportunity, quote);
    }

    /**
     * @description Wrapper class for replacement records
     */
    private class ReplacementRecords {
        public Opportunity opportunity { get; private set; }
        public SBQQ__Quote__c quote { get; private set; }
        
        public ReplacementRecords(Opportunity opp, SBQQ__Quote__c qt) {
            this.opportunity = opp;
            this.quote = qt;
        }
        
        public Boolean isValid() {
            return opportunity != null && quote != null;
        }
    }

    public class FlexAmendResponse {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
    }

}
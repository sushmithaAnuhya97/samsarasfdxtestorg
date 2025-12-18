/***********************************************************************************************************************************
 * @Test class: FlexAccountCancelReplaceControllerTest
 * Date      	- Project#          - Developer/ Company      	        - Description
 * ---------------------------------------------------------------------------------------------------------------------------------
 * 01/06/2025    - GTMS-25705        - Anas Siddiquee/ Accenture 	    - Initial creation - Process to amend one quote at a time
 * 01/20/2025    - GTMS-25970        - Anas Siddiquee/ Accenture        - Added Logging for C&R processing
 * 04/01/2025    - GTMS-27264        - Rajat Kundlas/ Accenture         - Added logic for upgraded quote lines
 */

 global without sharing class FlexAmendQueueable implements Queueable, Database.AllowsCallouts {
    private FlexAmendQueueableParams params;
    private static final Integer POST_CONTRACT_WAIT_TIME = Integer.valueOf(FlexConstants__c.getValues('FlexConstants').PostContractAmendmentWaitTime__c != null ? Integer.valueOf(FlexConstants__c.getValues('FlexConstants').PostContractAmendmentWaitTime__c) : 1);
    private static final Integer CONTRACT_PROCESS_TIME = Integer.valueOf(FlexConstants__c.getValues('FlexConstants').ContractAmendmentProcessTime__c != null ? Integer.valueOf(FlexConstants__c.getValues('FlexConstants').ContractAmendmentProcessTime__c) : 2);
    private static final Integer RETRY_ATTEMPT_LIMIT = Integer.valueOf(FlexConstants__c.getValues('FlexConstants').RetryAttemptLimit__c != null ? Integer.valueOf(FlexConstants__c.getValues('FlexConstants').RetryAttemptLimit__c) : 2);
    String quoteRecalculationStatus = '';
    
    public FlexAmendQueueable(FlexAmendQueueableParams params) {
        this.params = params;
    }
    List<Flex_Log__c> logList = new List<Flex_Log__c>();
    public void execute(QueueableContext context) {
        Id queueableJobId = context.getJobId();
        try {
            // Step 1: Invoke the Amender API sequentially for each contract to create cancellation opportunities and quotes
            if (params.currentIndex < params.contractIdList.size()) {
                processContract(queueableJobId);
            }

            // Step 2: After processing all contracts, verify if the Amender API call has finished successfully by checking the AsyncApexJob status.
            // If all contracts have been handled and retry attempts remain, proceed to check the status of the future job.
            if (params.currentIndex >= params.contractIdList.size() && params.retryCount < RETRY_ATTEMPT_LIMIT && !params.quoteRecalcStarted) {
                checkAmendmentFutureStatus();
                return;
            }

            // Step 3: Handle cancellation quote recalculation and snapshot quote creation after successful amendment in the previous step
            if ((params.quoteRecalcStarted && params.retryCount < RETRY_ATTEMPT_LIMIT ) || Test.isRunningTest() ) {
                setPrimaryFlagAndCreateSnapshotQuote();
            }

            // Step 4: Generate upgraded quote lines and perform snapshot quote recalculation
            if (quoteRecalculationStatus == 'Success') {
                Set<Id> logRecordIdSet = new Set<Id>();
                for (Flex_Log__c log : params.logRecordList) {
                    logRecordIdSet.add(log.Id);
                }
                FlexCancelReplaceHelper.createUpgradedQuoteLines(params);
                FlexCancelReplaceHelper.recalculateSnapshotQuote(logRecordIdSet); 
                enqueueQuoteLineJob(params.logRecordList);        
            }
        } catch (Exception e) {
            handleError(e, queueableJobId);
            SBQQ.TriggerControl.enable();
            FlexCancelReplaceHelper.performRollback([SELECT Id, Status__c, AmendFutureMethodId__c, ErrorMessage__c, AccountId__c, ContractId__c, RevenueOpportunityId__c, 
                                                        RevenueQuoteId__c, RevenueQuoteId__r.Flex_Is_Rebook_Quote__c, AmendedOpportunityId__c, AmendedQuoteId__c
                                                        FROM Flex_Log__c WHERE Id IN :params.logRecordList ORDER BY CreatedDate ASC], 
                                                      params.originalAccountFlag);
            List<Flex_Log__c> flexLogList = FlexCancelReplaceHelper.handleError(params.logRecordList, 'Failed : ', e.getMessage() + '\n' + 'Stack Trace: ' + e.getStackTraceString());
            enqueueQuoteLineJob(flexLogList);
        }
    }
    
    /**
     * Checks the status of future amendment jobs and handles the next steps based on their completion status.
     */
    private void checkAmendmentFutureStatus() {
        String futureJobStatus = FlexCancelReplaceHelper.hasFutureJobsCompleted('FlexCancelAndReplaceHandler', 'callAmenderApi', new List<Id>(params.queueableJobIdSet));
        if (futureJobStatus == 'In Progress') {
            params.retryCount++;
            if (params.retryCount < RETRY_ATTEMPT_LIMIT) {
                System.enqueueJob(new FlexAmendQueueable(params), POST_CONTRACT_WAIT_TIME);
            }
        } else if (futureJobStatus == 'Fail') {
            FlexCancelReplaceHelper.updateFutureJobLog(params.logRecordList, params.originalAccountFlag, 'callAmenderApi'); // Future job completed with error
        } else {
            // Verify if amendments were successful and initiate recalculation if they were
            FlexCancelReplaceHelper.updateFutureJobLog(params.logRecordList, params.originalAccountFlag, 'callAmenderApi'); // Future job completed successfully
            // Check if any of the logs were failed
            if(!FlexCancelReplaceHelper.hasFailedLogs(params.logRecordList)){
                params.retryCount = 0; // Reset retry count
                params.quoteRecalcStarted = true;
                System.enqueueJob(new FlexAmendQueueable(params), POST_CONTRACT_WAIT_TIME); // For recalculation of amended quote
            }else{
                enqueueQuoteLineJob(params.logRecordList); // Email notification for failed logs
            }
        }
    }

    /**
     * Processes a single contract amendment as part of a queueable job.
     * This method retrieves the current contract ID from the parameters, calls the amendment API,
     * updates the contract log with the job status, and enqueues the next contract for processing.
     */
    private void processContract(Id queueableJobId) {
        String contractId = params.contractIdList[params.currentIndex];
        FlexCancelAndReplaceHandler.callAmenderApi(contractId, params.startDate, params.replacementOppId, params.isRebook);
        params.queueableJobIdSet.add(queueableJobId);
        updateContractLog(contractId, queueableJobId, 'In Progress', null);
        System.enqueueJob(new FlexAmendQueueable(params.next()), CONTRACT_PROCESS_TIME);
    }

    /**
     * This method initiates the cancellation quote recalculation by setting the primary quote flag & creates a snapshot quote.
     * It checks the status of the asynchronous operation and retries the job if necessary, up to a defined limit.
     * If the operation fails or completes, it updates the job log accordingly.
     *
     * The method uses the following logic:
     * - On the initial attempt, marks the cancellation quote as primary, creates a snapshot quote, and enqueues the next job.
     * - On subsequent attempts, checks if the future job has completed.
     * - Retries the job if still in progress and retry limit is not reached.
     * - Updates the job log if the operation fails or completes.
     */
    private void setPrimaryFlagAndCreateSnapshotQuote() {
        if (params.retryCount == 0) {
            List<Id> logRecordIdList = new List<Id>();
            for (Flex_Log__c log : params.logRecordList) {
                logRecordIdList.add(log.Id);
            }
            FlexCancelReplaceHelper.createSnapShotQuote(logRecordIdList); 
            FlexCancelReplaceHelper.setQuoteFlag(logRecordIdList);
            params.retryCount++;
             System.enqueueJob(new FlexAmendQueueable(params), POST_CONTRACT_WAIT_TIME);
             return;
        }
        String quoteRecalcStatus = FlexCancelReplaceHelper.hasFutureJobsCompleted('FlexCancelReplaceHelper', 'setQuoteFlag', new List<Id>(params.queueableJobIdSet));
        if (quoteRecalcStatus == 'In Progress') {
            params.retryCount++;
            if (params.retryCount < RETRY_ATTEMPT_LIMIT) {
                System.enqueueJob(new FlexAmendQueueable(params), POST_CONTRACT_WAIT_TIME);
            }
        } else if (quoteRecalcStatus == 'Fail') {
            FlexCancelReplaceHelper.updateFutureJobLog(params.logRecordList, params.originalAccountFlag, 'setQuoteFlag');
        } else {
            FlexCancelReplaceHelper.updateFutureJobLog(params.logRecordList, params.originalAccountFlag, 'setQuoteFlag');
            quoteRecalculationStatus = quoteRecalcStatus;
        }
    }

    /**
     * Updates the Flex_Log__c record associated with the given contractId.
     * 
     * This method retrieves the most recent Flex_Log__c record for the specified contract,
     * updates its Queueable_Job_Id__c and Status__c fields, and appends or sets the error message
     * if provided. If an exception occurs during the update, it logs the error details.
     *
     * @param contractId     The Id of the contract whose log needs to be updated.
     * @param queueableJobId The Id of the queueable job to associate with the log.
     * @param status         The new status to set on the log record.
     * @param errorMessage   The error message to append or set on the log record, if any.
     */
    private void updateContractLog(String contractId, String queueableJobId, String status, String errorMessage) {
        try {
            Flex_Log__c log = [SELECT Id, ErrorMessage__c, Status__c, Queueable_Job_Id__c FROM Flex_Log__c WHERE ContractId__c = :contractId ORDER BY CreatedDate DESC LIMIT 1];
            log.Queueable_Job_Id__c = queueableJobId;
            log.Status__c = status;

            if (errorMessage != null) {
                if (log.ErrorMessage__c != null) {
                    log.ErrorMessage__c += '. ' + '\n\n' + 'Failed in FlexAmendQueueable: ' + '\n' + errorMessage;
                } else {
                    log.ErrorMessage__c = 'Failed in FlexAmendQueueable: ' + '\n' + errorMessage;
                }
            }
            update log;
        } catch (Exception e) {
            logDebug('Error updating log for contractId: ' + contractId + ' - ' + e.getMessage() + '\n' + 'Stack Trace: ' + e.getStackTraceString());
        }
    }

    /**
     * Enqueues a FlexQuoteLineQueueable job with the provided list of Flex_Log__c records.
     * @param logRecordList List of Flex_Log__c records to be processed by the queueable job.
     */
    private void enqueueQuoteLineJob(List<Flex_Log__c> logRecordList) {
        try {
            logDebug('Enqueuing FlexQuoteLineQueueable with log IDs: ' + logRecordList);
            System.enqueueJob(new FlexQuoteLineQueueable(logRecordList));
        } catch (Exception e) {
            logDebug('Error enqueuing final job: ' + e.getMessage() + '\n' + 'Stack Trace: ' + e.getStackTraceString());
        }
    }

    /**
     * Handles errors that occur during the execution of the FlexAmendQueueable job.
     * Logs the error details and updates the contract log with the failure status, error message, and stack trace.
     *
     * @param e The exception that was thrown.
     * @param queueableJobId The ID of the queueable job where the error occurred.
     */
    private void handleError(Exception e, String queueableJobId) {
        String contractId = (params.currentIndex < params.contractIdList.size()) ? params.contractIdList[params.currentIndex] : null;
        logDebug('Error in FlexAmendQueueable. JobId: ' + queueableJobId + ', Error: ' + e.getMessage() + '. Stack Trace: ' + e.getStackTraceString());
        if (contractId != null) {
            updateContractLog(contractId, queueableJobId, 'Failed', e.getMessage() + '\n' + 'Stack Trace: ' + e.getStackTraceString());
        }
    }

    private void logDebug(String message) {
        System.debug(message);
    }
}
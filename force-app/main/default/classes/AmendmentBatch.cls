global class AmendmentBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    private static final String RECORD_ID = 'Id';
    private static final String OPPORTUNITY = 'SBQQ__Opportunity2__c';
    private static final String CONTRACT_AMENDER_API = 'SBQQ.ContractManipulationAPI.ContractAmender';
    
    private final Id trackerId;
    private String contractId;
    private String amendmentQuoteId;
    private String amendmentOpportunityId;
    private Request_tracker__c tracker;
    private Integer retryCount = 0;  
    private Datetime startTime;
    private Datetime endTime;
    private Exception rowLockException;

    @TestVisible
    private String response;

    public AmendmentBatch(Id trackerId) {
        this.trackerId = trackerId;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        startTime = System.now(); 
        return Database.getQueryLocator('SELECT Id, Transaction_Type__c, Request__c, Step_Status__c, Error_Details__c, Opportunity_Id__c, Quote_Id__c FROM Request_Tracker__c WHERE Id = :trackerId LIMIT 1');
    }

    global void execute(Database.BatchableContext bc, List<Request_Tracker__c> scope) {
        if (scope.isEmpty()) return;

        tracker = scope[0];
        rowLockException = null;
        //create log for execution start
        OrderUtil.logJob(tracker, OrderUtil.STEP_1+': Info','Amendment process initiated via Apex Batch Job: '+bc.getJobId() + ' at: '+DateTime.now(),startTime, startTime, true);
        
        try {
            processAmendment();
        } catch (Exception e) {
            rowLockException = OrderUtil.isRowLockIssue(e) ? e : null;
            logSuccessJob('Amendment Batch Job completed with errors.'+e.getMessage(),startTime,startTime,true);
            handleException(e);
        }finally{
             OrderUtil.flushLogs();
        }
       
    }

    /*
    global void finish(Database.BatchableContext bc) {
         endTime = System.now(); // Track end time
        if(rowLockException != null) {
            handleRowLockException(rowLockException);
        }  else if (isAmendmentDataValid()) {
            logSuccessJob('Triggered finish method for Account, Opportunity, Quote, and Shipping Address upsert; Quote Lines reinserted post-deletion. Amendment QuoteId:' + amendmentQuoteId + ', Amendment OpportunityId:' + amendmentOpportunityId, false);
            logSuccessJob('Amendement Batch Job Completed.',startTime,endTime,false);
            enqueueAmendmentJob(amendmentQuoteId, amendmentOpportunityId);
        } else {
            logErrorJob('Amendment job could not be enqueued due to missing data. QuoteId: ' + amendmentQuoteId + ', OpportunityId: ' + amendmentOpportunityId, false);
        }
         OrderUtil.flushLogs();
    }*/

    global void finish(Database.BatchableContext bc) {
        endTime = System.now(); // Track end time
        
        // Fetch the job status from AsyncApexJob
        AsyncApexJob job = [SELECT Id, Status, ExtendedStatus, NumberOfErrors FROM AsyncApexJob WHERE Id = :bc.getJobId() LIMIT 1];
        
        if (job.Status == 'Failed' || job.NumberOfErrors > 0 || job.ExtendedStatus!=null || rowLockException != null) {
            // Mark tracker as failed but completed
            tracker.Status__c = 'COMPLETED';
            tracker.Step_Status__c = OrderUtil.STEP_2 + ': Failed';
            update tracker;
            
            handleRowLockException(rowLockException);
            logErrorJob('Amendment Batch Job failed. Errors: ' + job.NumberOfErrors+', Error Details:'+job.ExtendedStatus, false);
            
        } else if (isAmendmentDataValid()) {
            logSuccessJob('Triggered finish method for Account, Opportunity, Quote, and Shipping Address upsert; Quote Lines reinserted post-deletion. Amendment QuoteId:' + amendmentQuoteId + ', Amendment OpportunityId:' + amendmentOpportunityId, false);
            logSuccessJob('Amendment Batch Job Completed.', startTime, endTime, false);
            
            tracker.Status__c = 'COMPLETED';
            tracker.Step_Status__c = OrderUtil.STEP_2 + ': Success';
            update tracker;
            
            enqueueAmendmentJob(amendmentQuoteId, amendmentOpportunityId);
            
        } else {
            tracker.Status__c = 'COMPLETED';
            tracker.Step_Status__c = OrderUtil.STEP_2 + ': Failed';
            update tracker;
            
            logErrorJob('Amendment job could not be enqueued due to missing data. QuoteId: ' + amendmentQuoteId + ', OpportunityId: ' + amendmentOpportunityId, false);
        }
        
        OrderUtil.flushLogs();
    }
    
    
    private void processAmendment() {
        String amendmentResponse = fetchAmendmentResponse();
        processAmendmentResponse(amendmentResponse);
    }

    private void handleException(Exception e) {
        logErrorJob('Non-row-lock error during amendment processing: ' + e.getMessage() + e.getStackTraceString(), false);
    }

    private void handleRowLockException(Exception e) {
        Order_Processing_Settings__mdt orderProcessingSettings = OrderUtil.getOrderProcessingSettings();
        if (retryCount<orderProcessingSettings.Maximum_Retries__c) {
            retryCount++;
            logErrorJob('Row lock issue detected, retry attempt ' + retryCount + ' of ' +orderProcessingSettings.Maximum_Retries__c+' :'+ e.getMessage(), false);
            Database.executeBatch(this, 1);  // Re-run the batch with 1 record at a time for retries
        } else {
            logErrorJob('Max retries ('+orderProcessingSettings.Maximum_Retries__c+') reached for row lock issue: ' + e.getMessage() + e.getStackTraceString(), false);
            OrderPayload payload = (OrderPayload) JSON.deserialize(tracker.Request__c, OrderPayload.class);
            OrderUtil.enqueueJobIfPossible(new OrderResultToWorkatoService(tracker, tracker.Step_Status__c, payload, 3));
        }
    }

    private String fetchAmendmentResponse() {
        OrderPayload payload = deserializePayload(tracker.Request__c);
        contractId = getRelevantContractId(payload.order.is_enterprise, payload.order.account_id);

        if (contractId == null) {
            throw new RequestTrackerException('No active contract found.');
        }

        response = Test.isRunningTest() ?  response : SBQQ.ServiceRouter.load(CONTRACT_AMENDER_API, contractId, null);
        
        if (String.isBlank(response) || response == '{}') {
            throw new RequestTrackerException('Invalid or empty amendment response.');
        }

        logSuccessJob('Amendment response received: ' + response, false);
        return response;
    }

    private void processAmendmentResponse(String response) {
        Map<String, Object> quoteResponse = (Map<String, Object>) JSON.deserializeUntyped(response);
        Map<String, Object> record = (Map<String, Object>) quoteResponse.get('record');

        amendmentQuoteId = (String) record.get(RECORD_ID);
        amendmentOpportunityId = (String) record.get(OPPORTUNITY);

        if (!isAmendmentDataValid()) {
            throw new RequestTrackerException('Missing opportunity or quote ID in amendment response.');
        }
    }

    private Boolean isAmendmentDataValid() {
        return !String.isBlank(amendmentQuoteId) && !String.isBlank(amendmentOpportunityId);
    }

    private void enqueueAmendmentJob(String amendmentQuoteId, String amendmentOpportunityId) {
        updateTrackerFields();
        
        OrderPayload payload = deserializePayload(tracker.Request__c);
        //OrderUtil.enqueueJobIfPossible(createJobChain(payload));
        QueueableChainJob chainJob = createJobChain(payload);

        Order_Processing_Settings__mdt orderProcessingSettings = OrderUtil.getOrderProcessingSettings();
        //A 2-minute delay is included to allow all CPQ Amender API processing, Vertex tax calculations, and associated Opportunity and Quote flows and triggers to complete before proceeding.
        OrderUtil.enqueueJobIfPossibleWithDelay(chainJob,(Integer) orderProcessingSettings.Delay_for_Retry__c);
       
    }

    private void updateTrackerFields() {
        tracker.Quote_Id__c = amendmentQuoteId;
        tracker.Opportunity_Id__c = amendmentOpportunityId;
        tracker.contractId__c = contractId; 
    }

    private QueueableChainJob createJobChain(OrderPayload payload) {
        DeleteQuoteLines deleteQuoteLines = new DeleteQuoteLines(payload, 'Step-3',tracker, 0);
        InsertShippingAddress insertShippingAddress = new InsertShippingAddress(tracker, 'Step-4',payload, 0);
        //UpdateAccount updateAccount = new UpdateAccount(tracker,'Step-5',payload,0);
        UpdateOpportunity updateOpportunity = new UpdateOpportunity(tracker,'Step-5',payload,0);
        UpdateQuote updateQuote = new UpdateQuote(tracker,'Step-6',payload,2);
        InsertQuoteLines insertQuoteLines = new InsertQuoteLines(payload, 'Step-7',tracker, 0);
        QuoteRecalculationJob quoteRecalculationJob = new QuoteRecalculationJob(tracker, 'Step-8',payload, 0);
        OrderResultToWorkatoService workatoService = new OrderResultToWorkatoService(tracker, 'Step-9', payload, 0);
        
        // Proper chaining of queueable jobs
        deleteQuoteLines.setNextJob(insertShippingAddress);
        //insertShippingAddress.setNextJob(updateAccount);
        insertShippingAddress.setNextJob(updateOpportunity);
        updateOpportunity.setNextJob(updateQuote);
        updateQuote.setNextJob(insertQuoteLines);
        insertQuoteLines.setNextJob(quoteRecalculationJob);
        quoteRecalculationJob.setNextJob(workatoService);

        return deleteQuoteLines;
    }

    private Id getRelevantContractId(Boolean isEnterprise, Id accountId) {
        Id contractId = isEnterprise ? queryCustomer360(accountId) : null;
        return String.isBlank(contractId) ? queryLatestContract(accountId)?.Latest_Active_Contract__c : contractId;
    }

    private static Id queryCustomer360(Id accountId) {
        return OrderProcessorSingleton.getInstance().queryCustomer360(accountId);
    }

    private static Account queryLatestContract(Id accountId) {
        return OrderProcessorSingleton.getInstance().queryAccount(accountId);
    }

    private static OrderPayload deserializePayload(String payload) {
        return OrderProcessorSingleton.getInstance().deserializePayload(payload);
    }

    private void logErrorJob(String errorMessage, Boolean isInsert) {
        OrderUtil.logJob(tracker, OrderUtil.STEP_2 + ': Failed', errorMessage, DateTime.now(), DateTime.now(), isInsert);
    }
    
     private void logSuccessJob(String message, Boolean isInsert) {
        OrderUtil.logJob(tracker, OrderUtil.STEP_2 + ': Success', message, DateTime.now(), DateTime.now(), isInsert);
    }
    private void logSuccessJob(String message, DateTime startTime, DateTime endTime, Boolean isInsert) {
        OrderUtil.logJob(tracker, OrderUtil.STEP_2 + ': Success', message, startTime, endTime, isInsert);
    }
}
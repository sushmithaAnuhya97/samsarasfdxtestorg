/**
 * This is the core of the framework. This class will process one request at a time, it will delete successfull requests,
 * and handle errors by updating the "Error_Msg__c" field on the failed ones. 
 * 2022-09-09
 */
public without sharing class AsyncRequestQueueable implements Queueable, Database.AllowsCallouts {

    SamsaraLoggerService thisLoggerService = new SamsaraLoggerService();
    static Decimal RETRY_COUNTER = 0;
    static Decimal RETRY_THRESHOLD = 5;

    public static final Integer MINIMUM_MINUTES_IN_QUEUE_FOR_SCHEDULABLE = 30;

    private Integer minimumMinutesOverride = null;
    private Boolean filterByOwnerId = false;

    public static Boolean ASYNC_FRAMEWORK_IS_QUEUED = false;

    public AsyncRequestQueueable(){
        this(true);
    }

    public AsyncRequestQueueable(Boolean filterByOwnerId){
        this.filterByOwnerId = filterByOwnerId;
        this.minimumMinutesOverride = null;
    }

    public AsyncRequestQueueable(Boolean filterByOwnerId, Integer minimumMinutesOverride){
        this.filterByOwnerId = filterByOwnerId;
        this.minimumMinutesOverride = minimumMinutesOverride;
    }

    /**
     * Add additional request handlers here. 
     * NOTE: Each handler must implement IAsyncRequestHandler interface.
     */
    @TestVisible
    private static Map<String, Type> requestHandlers = new Map<String, Type>{
        new GS_CS_RecordServiceAsync().getRequestType() => GS_CS_RecordServiceAsync.class,
        new GS_ContactServiceAsync().getRequestType() => GS_ContactServiceAsync.class,
        new GS_ContractServiceAsync().getRequestType() => GS_ContractServiceAsync.class,
        new GS_Contact_ManuallyUnloadContactAsync().getRequestType() => GS_Contact_ManuallyUnloadContactAsync.class,
        new GS_ContactCampaignToAddAsync().getRequestType() => GS_ContactCampaignToAddAsync.class,
        new GS_OpportunityServiceAsync().getRequestType() => GS_OpportunityServiceAsync.class,
        new GS_TrialOpportunityServiceAsync().getRequestType() => GS_TrialOpportunityServiceAsync.class,
        new GS_OpportunityToLineItemUpdateAsync().getRequestType() => GS_OpportunityToLineItemUpdateAsync.class,
        new GS_OpportunitySendEmailAsync().getRequestType() => GS_OpportunitySendEmailAsync.class,
        new GS_OpportunityToUpdateAccountAsync().getRequestType() => GS_OpportunityToUpdateAccountAsync.class,
        new GS_AsyncFreeTrialQuoteService().getRequestType() => GS_AsyncFreeTrialQuoteService.class,
        new GS_OpportunityOrderAdminRoundRobinAsync().getRequestType() => GS_OpportunityOrderAdminRoundRobinAsync.class,
        new GS_SBQQQuoteServiceAsync().getRequestType() => GS_SBQQQuoteServiceAsync.class,
        new GS_OpportunityLineItemServiceAsync().getRequestType() => GS_OpportunityLineItemServiceAsync.class,
        new GS_AsyncDisconnectTrialOppService().getRequestType() => GS_AsyncDisconnectTrialOppService.class,
        new GS_AsyncFreeTrialQuoteService().getRequestType() => GS_AsyncFreeTrialQuoteService.class,
        new GS_AsyncQuotaOpportunityDeletionService().getRequestType() => GS_AsyncQuotaOpportunityDeletionService.class,
        new GS_AsyncSBQQQuoteFromOpportunityService().getRequestType() => GS_AsyncSBQQQuoteFromOpportunityService.class,
        new GS_OpportunitySlackServiceAsync().getRequestType() => GS_OpportunitySlackServiceAsync.class,
        new GS_OpportunityNetSuiteServiceAsync().getRequestType() => GS_OpportunityNetSuiteServiceAsync.class,
        new GS_OpportunityReturnProcessServiceAsync().getRequestType() => GS_OpportunityReturnProcessServiceAsync.class,
        new UpdateContractServiceAsync().getRequestType() => UpdateContractServiceAsync.class,
        new OpportunityReturnProcessesAsync().getRequestType() => OpportunityReturnProcessesAsync.class,
        new OpportunityToSELogsServiceAsync().getRequestType() => OpportunityToSELogsServiceAsync.class,
        new ContractUpdateServiceAsync().getRequestType() => ContractUpdateServiceAsync.class,
        new OrderValidationServiceAutomationAsync().getRequestType() => OrderValidationServiceAutomationAsync.class,
        new SlackPublisherAsync().getRequestType() => SlackPublisherAsync.class
    };

    public static void startJob(){
        startJob(true);
    }

    public static void startJob(Boolean filterByOwnerId){
        startJob(filterByOwnerId, null);
    }

    public static void startJob(Boolean filterByOwnerId, Integer minimumMinutesOverride){
        try{
            // this will prevent making 2 queuable jobs from 1 queueable
            //if(Limits.getQueueableJobs() == 0) { System.enqueueJob(new AsyncRequestQueueable(filterByOwnerId, minimumMinutesOverride)); }
            if (!ASYNC_FRAMEWORK_IS_QUEUED && (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs())){
                ASYNC_FRAMEWORK_IS_QUEUED = true;
                System.enqueueJob(new AsyncRequestQueueable(filterByOwnerId, minimumMinutesOverride));
            }
        }catch(Exception ex){
            System.debug(ex.getMessage());
            startJobFuture(filterByOwnerId);
        }
    }

    @future static void startJobFuture(){
        System.enqueueJob(new AsyncRequestQueueable(true));
    }

    @future static void startJobFuture(Boolean filterByOwnerId){
        System.enqueueJob(new AsyncRequestQueueable(filterByOwnerId));
    }

    public void execute(QueueableContext context){

        // Change this Custom Metadata setting to FALSE in case something goes haywire
        if(!Configuration.getAsyncRequestConfig().Is_Async_Request_Processing_Enabled__c) return;
        
        List<Async_Request__c> requests = new List<Async_Request__c>();
        Integer minimumTimeInQueue = (minimumMinutesOverride != null ? minimumMinutesOverride : MINIMUM_MINUTES_IN_QUEUE_FOR_SCHEDULABLE);
        try{
            // making sure to process Requests in the order that they were submitted
            List<Async_Request__c> next;
            if (filterByOwnerId){
                next = [
                    SELECT Id
                      FROM Async_Request__c
                     WHERE Error_Msg__c = null 
                       AND OwnerId = :UserInfo.getUserId()
                     ORDER BY Id ASC
                     LIMIT 1
                ];
            }else{
                next = [
                    SELECT Id
                      FROM Async_Request__c
                     WHERE Error_Msg__c = null 
                       AND TimeInQueue__c >= :minimumTimeInQueue
                     ORDER BY Id ASC
                     LIMIT 1
                ];
            }

            if(next.isEmpty() == false){
                requests = [
                    SELECT Id, Type__c, Error_Msg__c, Params__c, Options__c, CreatedById, Retry_Counter__c
                    FROM Async_Request__c
                    WHERE Id = :next[0].Id 
                    FOR UPDATE
                ]; 
            }
        }catch(System.QueryException ex){
            // It can happen sometimes that a 2nd queueable is started and 
            // it tries to process the same Async_Request__c record.
            // In that case just exit, and the other queueable that has the lock
            // will finish its work and enqueue the next pending request.
            return;
        }

        if(requests.size() == 0) return; // nothing to do, all requests processed

        Async_Request__c request = requests[0];

        if(detectFailedRequests(context))
        {
            // the queueable seems to be failing, and the error is not being catched, so it's probably a governor limit issue
            request.Error_Msg__c = 'Failing due to Governor Limits. Check Apex Jobs in Setup for further details.';
            update request;

        } else {
            
            // all good, process the request
            Savepoint sp;
            try{
                // check if there's a registered handler for this request type
                if(requestHandlers.containsKey(request.Type__c) == false) throw new AsyncRequestException('No registered handlers for this request type');
                
                // execute the request
                IAsyncRequestHandler handler = ((IAsyncRequestHandler) requestHandlers.get(request.Type__c).newInstance());
                if (!handler.isHandlerReadOnly()) sp = Database.setSavepoint();
                handler.execute(request);
            
                // request successfully processed, it's OK to delete it
                delete request;

            }catch(Exception ex){
                RETRY_COUNTER ++;
                thisLoggerService.logger.logError(
                        'This Job retried '+ RETRY_COUNTER,
                        new SamsaraLoggerObjectMVP(ex, request)
                );

                // an error occured. Rollback the changes, and update the request's Error_Msg__c field
                if (sp != null) Database.rollback(sp);
                if(RETRY_THRESHOLD > request.Retry_Counter__c && ex.getMessage().contains('UNABLE_TO_LOCK_ROW')){
                    request.Error_Msg__c = null;
                    request.Retry_Counter__c = request.Retry_Counter__c + 1;
                }
                else{
                    request.Error_Msg__c = ex.getMessage().left(255);

                }
                update request;
            }
            finally {
                thisLoggerService.logger.dispatch();
            }
        }

        

        // check if there is more pending requests, and if there is, start the next job
        if (this.filterByOwnerId){
            requests = [SELECT Id FROM Async_Request__c WHERE Error_Msg__c = null AND OwnerId = :UserInfo.getUserId() limit 1];
        }else{
            requests = [SELECT Id FROM Async_Request__c WHERE Error_Msg__c = null AND TimeInQueue__c >= :minimumTimeInQueue limit 1];
        }
        if(requests.size() > 0) startJob(filterByOwnerId, minimumMinutesOverride);
    } 

    /**
     * Detect requests that failed more than once in a row.TerritoryMgmt
     * This can usually happen due to some sort of Governor Limit exception that couldn't be catched.
     *
     * @param  context Current execution context
     * @return         TRUE - multiple failed requests detected
     */
    private Boolean detectFailedRequests(QueueableContext context){

        List<AsyncApexJob> jobs = [
            SELECT Id, Status, ExtendedStatus, CreatedDate, CompletedDate
            FROM AsyncApexJob
            WHERE JobType = 'Queueable' AND ApexClass.Name = 'AsyncRequestQueueable'
            AND Id != :context.getJobId() ORDER BY CreatedDate DESC LIMIT 2
        ];

        if(jobs.size() < 2) return false;
        for(AsyncApexJob job : jobs){
            if(job.Status != 'Failed') return false;
        }
        return true;
    }

    public interface IAsyncRequestHandler {
    
        /**
        * Prepares the Async_Request__c records by splitting the list of Ids into largest possible batch sizes. 
        *
        * NOTE: If you start hitting limits in request, call an overloaded method instead 
        * by providing a smaller batch size as a second parameter.
        *
        * @param  recordsToProcess set of IDs to be processed by Async Request
        * @param  batchSize        how many ID's to process at once
        *
        * @return                  List of Async_Request__c records ready to be inserted and enqueued 
        */
        List<Async_Request__c> prepareAsyncRequests(Set<Id> recordsToProcess);

        /**
        * Prepares the Async_Request__c records by splitting the list of Ids into 
        * batches of provided size
        *
        * @param  recordsToProcess set of IDs to be processed by Async Request
        * @param  batchSize        how many ID's to process at once
        *
        * @return                  List of Async_Request__c records ready to be inserted and enqueued 
        */
        List<Async_Request__c> prepareAsyncRequests(Set<Id> recordsToProcess, Integer batchSize);
 

        /**
        * Unique name of this Async Request
        */
        String getRequestType();

        
        /**
        * Logic to be executed
        */
        void execute(Async_Request__c ar);

        /**
         * GTMS-11865 - Improved base handler. This method should return "true" if the Handler is likely to perform callouts.
         * By setting this to "true", the async framework disables the rollback to allow callouts, and the handler should have it's own rollback functionality.
         */
        Boolean isHandlerReadOnly();
    }

    public class AsyncRequestException extends Exception { }
}
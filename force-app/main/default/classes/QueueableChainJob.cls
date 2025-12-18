public abstract class QueueableChainJob implements Queueable, Database.AllowsCallouts {
    
    protected Request_Tracker__c tracker;
    protected String stepStatus;
    protected OrdersLogTransactionFinalizer transactionFinalizer;
    
    @testVisible
    protected Order_Processing_Settings__mdt orderProcessingSettings;
    
    private Queueable nextJob;
    protected Integer retryCount;
    
    private DateTime startTime;
    private DateTime endTime;
    
    public QueueableChainJob(Integer retryCount, String stepStatus, Request_Tracker__c tracker) {
        this.retryCount = retryCount;
        this.stepStatus = stepStatus;
        this.tracker = tracker;
        this.transactionFinalizer = new OrdersLogTransactionFinalizer(tracker);
        this.orderProcessingSettings = orderProcessingSettings == null ? OrderUtil.getOrderProcessingSettings() : orderProcessingSettings;
    }
    
    public void setNextJob(Queueable nextJob) {
        this.nextJob = nextJob;
    }
    
    public void execute(QueueableContext context) {
        startTime = DateTime.now();
        String className = this.toString().subStringBefore(':[');
        String jobId = context.getJobId();
        
        System.attachFinalizer(transactionFinalizer);
        logInfo('execution started.', className, jobId);
        
        try {
            tracker.Status__c = 'Processing';
            processJob();
            endTime = DateTime.now();
            logSuccess('execution completed successfully.', className, jobId);
            tracker.Status__c = 'Completed';
            tracker.Step_Status__c = stepStatus + ' Completed';
            if (nextJob != null) {
                if (Limits.getQueueableJobs() >= Limits.getLimitQueueableJobs()) {
                   Database.executeBatch(new DeferredQueueableBatch(nextJob, (Integer) orderProcessingSettings.Delay_for_Retry__c, tracker, stepStatus), 1);
                   return;
                }
                OrderUtil.enqueueJobIfPossibleWithDelay(nextJob,(Integer) orderProcessingSettings.Delay_for_Retry__c); 
                //OrderUtil.enqueueJobIfPossible(nextJob);
            }
        } catch (Exception e) {
            // This block will NEVER be hit for CPU timeout to retry
            tracker.Status__c = 'Error';
            tracker.Step_Status__c =stepStatus+' Failed';
            tracker.Error_Details__c = e.getMessage();
            endTime = DateTime.now();
            transactionFinalizer.handleException(stepStatus + ': Error', e, startTime, endTime);
            handleRetry(e, className, jobId);
        }finally{
            try{
                UPDATE tracker;
            }catch(Exception exp){
                transactionFinalizer.handleException(stepStatus + ': Error', exp, startTime, endTime); 
            }
        }
    }
    
    private void handleRetry(Exception e, String className, String jobId) {
        if (e == null || String.isBlank(e.getMessage()) || tracker == null || orderProcessingSettings == null) {
            logError('Invalid state: Cannot retry due to missing exception or settings.', className, jobId);
            return;
        }
        
        // Enforce max 3 retries
        Integer maxRetry = (Integer) orderProcessingSettings.Maximum_Retries__c;
        Integer retryDelay = (Integer) orderProcessingSettings.Delay_for_Retry__c;
        
        List<String> retryableMessages = orderProcessingSettings?.Retryable_Exception_Messages__c?.split(';') ?? new List<String>();
        if (retryCount >= maxRetry) {
            logError('Maximum retry attempts reached (' + retryCount + '). No further retries.', className, jobId);
            System.enqueueJob(new OrderErrorResultToWorkato(tracker,stepStatus,e.getMessage()));
            return;
        }
        
        // Retry for specific exception types (e.g., CalloutException) 
        if (e instanceof System.CalloutException) {
            logError('CalloutException retry. Attempt: ' + (retryCount + 1), className, jobId);
            enqueueRetryJob(retryCount + 1, retryDelay,className);
            return;
        }
        
        // Retry for matching retryable message fragments
        String errorMessage = e.getMessage();
        for (String fragment : retryableMessages) {
            if (String.isNotBlank(fragment) && errorMessage.contains(fragment.trim())) {
                logError('Retryable error matched fragment: "' + fragment + '". Attempt: ' + (retryCount + 1), className, jobId);
                enqueueRetryJob(retryCount + 1, retryDelay,className);
                return;
            }
        }
        
        logError('Error not eligible for retry. Message: ' + errorMessage, className, jobId);
        Id errorQueueableJobId ;
        try {
            errorQueueableJobId = System.enqueueJob(new OrderErrorResultToWorkato(tracker,stepStatus,e.getMessage())); 
            logError('OrderErrorResultToWorkato Queueable JobId.', className, errorQueueableJobId);
        } catch (Exception ex) {
            logError('OrderErrorResultToWorkato Queueable JobId. Exception Message: ' + ex.getMessage(), className, errorQueueableJobId);
        }
    } 
    
    /*
    @TestVisible
    private void enqueueRetryJob(Integer nextRetryCount, Integer delay,String className) {
        OrderPayload payload = (OrderPayload) JSON.deserialize(tracker.Request__c, OrderPayload.class);
        if('OrderResultToWorkatoService'.equals(className)){
            OrderUtil.enqueueJobIfPossibleWithDelay(new OrderResultToWorkatoService(tracker, tracker.Step_Status__c, payload, nextRetryCount), delay);
        }else{
            OrderUtil.enqueueJobIfPossibleWithDelay(newInstanceWithRetry(nextRetryCount),delay);
        }
    }*/
    
    @TestVisible
    private void enqueueRetryJob(Integer nextRetryCount, Integer delay, String className) {
        OrderPayload payload = (OrderPayload) JSON.deserialize(tracker.Request__c, OrderPayload.class);
        
        Queueable retryJob;
        if ('OrderResultToWorkatoService'.equals(className)) {
            retryJob = new OrderResultToWorkatoService(tracker, tracker.Step_Status__c, payload, nextRetryCount);
        } else {
            retryJob = newInstanceWithRetry(nextRetryCount);
        }
        
        // Preserve the chain link for the retry job
        if (retryJob != null && retryJob instanceof QueueableChainJob) {
            ((QueueableChainJob) retryJob).setNextJob(nextJob);
        }
        
        OrderUtil.enqueueJobIfPossibleWithDelay(retryJob, delay);
    }
    
    private void logInfo(String message, String className, String jobId) {
        transactionFinalizer.createLog(stepStatus + ': Info', className + ' Queueable Job [' + jobId + '] ' + message, startTime, DateTime.now());
    }
    
    private void logSuccess(String message, String className, String jobId) {
        transactionFinalizer.createLog(stepStatus + ': Success', className + ' Queueable Job [' + jobId + '] ' + message, startTime, endTime);
    }
    
    private void logError(String message, String className, String jobId) {
        transactionFinalizer.createLog(stepStatus + ': Error', className + ' Queueable Job [' + jobId + '] ' + message, startTime, endTime);
    }
    
    protected abstract void processJob();
    protected abstract Queueable newInstanceWithRetry(Integer retryCount);
}
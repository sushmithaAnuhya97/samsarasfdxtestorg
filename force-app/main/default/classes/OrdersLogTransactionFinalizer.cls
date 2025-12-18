public class OrdersLogTransactionFinalizer implements Finalizer {
    private final Request_Tracker__c tracker;
    @testVisible private List<Api_Logger__c> logBuffer = new List<Api_Logger__c>();

    public OrdersLogTransactionFinalizer(Request_Tracker__c tracker) {
        this.tracker = tracker;
    }
    
    public void execute(FinalizerContext context) {
        DateTime now = DateTime.now();
        String parentJobId = context.getAsyncApexJobId();
        String stepStatus = context.getResult().name();
        
        try {
            String logMessage = buildLogMessage(parentJobId, context, stepStatus);
            createLog('',logMessage,now,now);
            if(!logBuffer.isEmpty()){
                for(Api_Logger__c logger:logBuffer){
                    logger.Request__c = parentJobId;
                }
            }
        } catch (Exception ex) {
            handleException(stepStatus, ex, now, now);
        } finally{
            UPDATE tracker;
            
            if(!logBuffer.isEmpty()){
                Database.insert(logBuffer,false);
            }
        }
    }
    
    private String buildLogMessage(String jobId, FinalizerContext context, String status) {
        return (status == ParentJobResult.SUCCESS.name())
            ? 'Transaction Finalizer for the parent queueable job [' + jobId + '] completed successfully.'
            : 'Transaction Finalizer for the parent queueable job [' + jobId + '] failed due to unhandled exception: ' + context.getException().getMessage();
    }
    
    public void handleException(String stepStatus, Exception e, DateTime startTime, DateTime endTime) {
        String errorMessage = String.join(new List<String>{'Exception type: ' + e.getTypeName(),'Line number: ' + e.getLineNumber(),'Error: ' + e.getMessage(),'Stack trace: ' + e.getStackTraceString(),'Cause: ' + String.valueOf(e.getCause())}, '\n');
        createLog(stepStatus,errorMessage,startTime,endTime);
    }
    
    public void createLog(String stepStatus, String response, DateTime startTime, DateTime endTime) {
        Api_Logger__c apiLogger = new Api_Logger__c();
        apiLogger.Request_Tracker_Id__c = tracker.Id;
        apiLogger.Transaction_Type__c = tracker.Transaction_Type__c;
        apiLogger.Step_Status__c = stepStatus;
        apiLogger.Start_Time__c = startTime;
        apiLogger.End_Time__c = endTime;
        apiLogger.Response__c = response;
        apiLogger.Duration__c = (startTime != null && endTime != null) ? (endTime.getTime() - startTime.getTime()) : 0;
        logBuffer.add(apiLogger);
    }
}
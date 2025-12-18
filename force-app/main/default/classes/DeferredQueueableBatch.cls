public class DeferredQueueableBatch implements Database.Batchable<SObject>{
    private Queueable nextJob;
    private Integer delayMinutes;
    private Datetime startTime;
    private Request_Tracker__c tracker;
    private String stepStatus;

    public DeferredQueueableBatch(Queueable job, Integer delayMinutes, Request_Tracker__c tracker, String stepStatus) {
        this.nextJob = job;
        this.delayMinutes=delayMinutes;
        this.tracker = tracker;
        this.stepStatus = stepStatus;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        startTime = System.now(); 
        // Dummy query for 1-row batch
        return Database.getQueryLocator([SELECT Id FROM User WHERE IsActive = true LIMIT 1]);
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        //create log for execution start
        OrderUtil.logJob(tracker, OrderUtil.STEP_1+': Info','DeferredQueueableBatch initiated via Apex Batch Job: '+bc.getJobId() + ' at: '+DateTime.now(),startTime, startTime, true);
        
        try {
            System.enqueueJob(nextJob,delayMinutes);
        } catch (Exception e) {
            logErrorJob('Error encoutered in DeferredQueueableBatch job : '+e.getMessage(), false);
        }finally{
            OrderUtil.flushLogs();
        }
       
    }

    public void finish(Database.BatchableContext BC) {
        // Log completion of the batch job
        OrderUtil.logJob(tracker, stepStatus + ': Completed', 
            'DeferredQueueableBatch completed successfully. Job ID: ' + BC.getJobId() + ' at: ' + DateTime.now(), 
            startTime, DateTime.now(), true);
        
        // Flush any remaining logs
        OrderUtil.flushLogs();
    }

    private void logErrorJob(String errorMessage, Boolean isInsert) {
        OrderUtil.logJob(tracker, stepStatus + ': Failed', errorMessage, DateTime.now(), DateTime.now(), isInsert);
    }
}
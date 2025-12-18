public class TaskContactStatusUpdateQueueable implements Queueable {
    private Set<Id> contactIdsToProcess;
    
    // Constructor for execution
    public TaskContactStatusUpdateQueueable(Set<Id> contactIds) {
        this.contactIdsToProcess = contactIds;
    }
    
    public void execute(QueueableContext context) {
        gslib_ILogger logger = gslib_LoggerService.getModuleLogger('GTMS').getLogger();
        
        try {
            // Query tasks and get contact statuses in parallel
            List<Task> tasks = [SELECT Id, Related_Contact__c, Contact_Status_Copy__c 
                                FROM Task WHERE Related_Contact__c IN :contactIdsToProcess LIMIT 10000];
            if (tasks.isEmpty()) return;
            
            // Get current contact statuses
            Map<Id, Contact> contactMap = new Map<Id, Contact>([
                SELECT Id, Status__c FROM Contact 
                WHERE Id IN :contactIdsToProcess
            ]);      
            
            // Identify and update tasks with status changes
            List<Task> tasksToUpdate = new List<Task>();
            for (Task task : tasks) {
                // Determine which contact ID to use for status lookup - with null check
                Id contactId = task.Related_Contact__c != null ? task.Related_Contact__c : task.WhoId;
                
                // Only process when contactId != null
                if (contactId != null && contactMap.containsKey(contactId)) {
                    String newStatus = contactMap.get(contactId).Status__c;
                    if (newStatus != null && newStatus != task.Contact_Status_Copy__c) {
                        task.Contact_Status_Copy__c = newStatus;
                        tasksToUpdate.add(task);
                    }
                }
            }
            
            // Update in chunks if needed
            if (!tasksToUpdate.isEmpty()) {
                updateTasksInChunks(tasksToUpdate);
            } 
            
        } catch (Exception e) {
            logger.logError('TaskContactStatusUpdateQueueable failed', 
                            new SamsaraLoggerObjectMVP(e.getMessage(), 'TaskContactStatusUpdateQueueable'));
            logger.dispatch();
        }
    }
    
    
    // Chunked updates to avoid DML limits
    private void updateTasksInChunks(List<Task> tasksToUpdate) {
        gslib_ILogger logger = gslib_LoggerService.getModuleLogger('GTMS').getLogger();
        TriggerHandler.bypass('GS_TaskTriggerHandler');
        TriggerHandler.bypass('TaskTriggerHandler');
        
        try {
            Integer chunkSize = 200;
            for (Integer i = 0; i < tasksToUpdate.size(); i += chunkSize) {
                List<Task> chunk = new List<Task>();
                Integer endIndex = Math.min(i + chunkSize, tasksToUpdate.size());
                
                for (Integer j = i; j < endIndex; j++) {
                    chunk.add(tasksToUpdate[j]);
                }
                
                if (!chunk.isEmpty()) {
                    Database.SaveResult[] results = Database.update(chunk, false);
                    Integer successCount = 0;
                    for (Integer k = 0; k < results.size(); k++) {
                        if (results[k].isSuccess()) {
                            successCount++;
                        } else {
                            for (Database.Error error : results[k].getErrors()) {
                                logger.logError('Task update failed: ' + chunk[k].Id, 
                                                new SamsaraLoggerObjectMVP(error.getMessage(), 'TaskContactStatusUpdateQueueable'));
                            }
                        }
                    }
                }
            }
        } finally {
            TriggerHandler.clearBypass('GS_TaskTriggerHandler');
            TriggerHandler.clearBypass('TaskTriggerHandler');
        }
    }
    
    // Static method to execute the queueable
    public static void executeQueueable(Set<Id> contactIds) {
        gslib_ILogger logger = gslib_LoggerService.getModuleLogger('GTMS').getLogger();
        // Don't enqueue if: no contacts to process
        if (contactIds == null || contactIds.isEmpty()) {
            return;
        }
        if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
            System.enqueueJob(new TaskContactStatusUpdateQueueable(contactIds));
        } else {
            logger.logError('Maximum queueable stack depth reached. Cannot chain further TaskContactStatusUpdateQueueable jobs.', 
                            new SamsaraLoggerObjectMVP('Queueable limit exceeded', 'TaskContactStatusUpdateQueueable'));
            logger.dispatch();
        }
    }
}
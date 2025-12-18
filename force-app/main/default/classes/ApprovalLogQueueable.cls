public class ApprovalLogQueueable implements Queueable {
    private List<SBAA__Approval__c> approvals;
    private gslib_IModuleLogger moduleLogger;
    private gslib_ILogger logger;
    private static final String CLASS_NAME = 'ApprovalLogQueueable';
    Set<Id> failedRecordIds = new Set<Id>();
    
    public ApprovalLogQueueable(List<SBAA__Approval__c> approvals) {
        this.approvals = approvals;
        this.moduleLogger = gslib_LoggerService.getModuleLogger('GTMS');
        this.logger = moduleLogger.getLogger();
    }
    
    public void execute(QueueableContext context) {
        try {
            Database.SaveResult[] results;
            List<Approval_Log__c> allApprovalLogs = new List<Approval_Log__c>();
            Integer chunkSize = Math.min(
                Limits.getLimitDMLRows() - Limits.getDMLRows(),
                200
            );
            
            for (Integer i = 0; i < approvals.size(); i += chunkSize) {
                List<SBAA__Approval__c> approvalChunk = new List<SBAA__Approval__c>();
                Integer endIndex = Math.min(i + chunkSize, approvals.size());
                
                for (Integer j = i; j < endIndex; j++) {
                    approvalChunk.add(approvals[j]);
                }
                
                if (!approvalChunk.isEmpty()) {
                    List<Approval_Log__c> chunkLogs = ApprovalHelper.createApprovalLogs(approvalChunk);
                    if (!chunkLogs.isEmpty()) {
                        allApprovalLogs.addAll(chunkLogs);
                    }
                }
            }
            
            if (!allApprovalLogs.isEmpty()) {
                results = Database.insert(allApprovalLogs, false);
                handleDMLErrors(results);
            }
        } catch (Exception e) {
            //logger.logError('ApprovalLogQueueable. Approval Log Creation Error Message ::'+ e.getMessage() +' | StackTrace:: '+ e.getStackTraceString() +' | Approval Records ::', failedRecordIds);
            logger.logError(
                'Approval Logging Error',
                new SamsaraLoggerObjectMVP(
                    e,
                    failedRecordIds
                )
            );
            throw e;
        } finally {
            logger.dispatch();
        }
    }
    
    private void handleDMLErrors(Database.SaveResult[] results) {
        List<String> errors = new List<String>();
        Map<String, Object> logParams = new Map<String, Object>();
        List<Object> failedRecords = new List<Object>();
        //Set<Id> failedRecordIds = new Set<Id>();
        
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                // Create error message
                String errorMsg = String.format('Record {0}: {1}', 
                    new String[]{ String.valueOf(i), 
                                results[i].getErrors()[0].getMessage() });
                errors.add(errorMsg);
                
                // Add failed record details to the list
                Map<String, Object> failureDetails = new Map<String, Object>{
                    'recordIndex' => i,
                    'errors' => results[i].getErrors(),
                    'record' => approvals[i],
                    'recordId' => approvals[i].Id
                };
                failedRecords.add(failureDetails);
                failedRecordIds.add(approvals[i].Id);
            }
        }
        
        if (!errors.isEmpty()) {
            String errorLog = String.join(errors, '\n');
            logParams.put('failedRecords', failedRecords);
            logParams.put('errorMessages', errors);
            logParams.put('failedRecordIds', new List<Id>(failedRecordIds));
            /*logger.logError(
                'Failed to insert Approval Logs', 
                errorLog,
                logParams
            );*/
            logger.logError('ApprovalLogQueueable. Failed to insert Approval Logs ::'+ errorLog +' | StackTrace:: '+ logParams +' | Approval Records ::', failedRecordIds);

        }
    }
}
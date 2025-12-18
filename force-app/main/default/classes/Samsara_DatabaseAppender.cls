/**
 * Created by vikasmishra on 2021-05-06.
 */

public with sharing class Samsara_DatabaseAppender implements gslib_ILoggerAppender{

    private List<Log__c> logs;
    public Samsara_DatabaseAppender() {
        logs = new List<Log__c>();
    }
    public Samsara_DatabaseAppender(List<Log__c> logList){
        logs = new List<Log__c>(logList);
    }
    public void log(gslib_Log log, Object obj) {
        Exception ex = obj != null && obj instanceof Exception ? (Exception) obj : null;
        logs.add(
                new Log__c (
                        ClassName__c = log.className,
                        ExceptionMessage__c = ex != null ? ex.getMessage() : null,
                        StackTrace__c = ex != null ? ex.getStackTraceString().left(32768) : log.stackTrace,
                        Exception_Type__c = ex != null ? String.valueOf(ex.getTypeName()) : null,
                        Context_User__c = log.contextUser,
                        Message__c = log.message,
                        Method__c = log.method,
                        SessionKey__c = log.sessionKey,
                        Severity__c = log.severity != null ? log.severity.name() : null,
                        Timestamp__c = System.now(),
                        Type__c = log.type,
                        LogLevel__c = log.logLevel != null ? log.logLevel.name() : null
                )
        );
    }

    public void dispatch() {
        List<Database.SaveResult> saveResult = Database.insert(this.logs, false);
        printStatistics(saveResult, 'Logs');
        System.debug(LoggingLevel.FINEST, '~~~~~ insertLogs() Method End ~~~~~');

    }
    /**
     * @description Prints the log publishing events statistics.
     * @param saveResults The logs publishing save results.
     * @param entity The entity named related with the save results.
     */
    private static void printStatistics(List<Database.SaveResult> saveResults, String entity) {
        Integer totalSuccess = 0;
        Integer totalFailed = 0;
        for (Database.SaveResult saveResult : saveResults) {
            if (saveResult.isSuccess()) {
                totalSuccess++;
            } else {
                for (Database.Error error : saveResult.errors) {
                    System.debug(LoggingLevel.FINE, 'Error on insert log: ' + error.message);
                }
                totalFailed++;
            }
        }
    }

}
/**
 * Created by vikasmishra on 2021-07-14.
 * TODO: Retry logic for failed publish
 */

public with sharing class Samsara_AsyncDatabaseAppender implements gslib_ILoggerAppender{

    List<gslib_Log__e> logs ;
    public Samsara_AsyncDatabaseAppender() {
        logs = new List<gslib_Log__e>();
    }
    public void log(gslib_Log log, Object obj) {
        logs.add(mapGSLIBLogToLogEvent(log, obj));
    }

    public void dispatch() {
        try {
            List<Database.SaveResult> saveResults = EventBus.publish(this.logs);
            logs = new List<gslib_Log__e>();
            // Print debug publishing statistics.
            printStatistics(saveResults);
        } catch (Exception ex) {
            System.debug(LoggingLevel.WARN, 'Logger Framework. Error publishing logs events. Error: ' +
                    ex.getMessage());
        }
    }

    private static void printStatistics(List<Database.SaveResult> saveResults) {
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
        System.debug(LoggingLevel.DEBUG, ' statistics => Success: ' +
                totalSuccess + ' | Failed: ' + totalFailed);
    }

    /**
     * @description Gets the log info list and flushes the log cache.
     * @return The log event instance with data mapped from the given  gslibLog.
     */
    private gslib_Log__e mapGSLIBLogToLogEvent(gslib_Log log, Object obj) {
        Exception ex ;
        Object MVP ;
        if(obj == null){
            //Do nothing
        }
        else if( obj instanceof SamsaraLoggerObjectMVP){
            SamsaraLoggerObjectMVP thisObjectMVP = (SamsaraLoggerObjectMVP) obj;
            ex = thisObjectMVP.exceptionObject != null && thisObjectMVP.exceptionObject instanceof Exception ? (Exception) thisObjectMVP.exceptionObject : null;
            MVP = thisObjectMVP.MVP;
        }
        else if( obj instanceof Exception ){
            ex = obj != null && obj instanceof Exception ? (Exception) obj : null;
        }
        else{
            MVP = obj;
        }

        return new gslib_Log__e(
                Class_Name__c = log.className,
                Method_Name__c = log.method,
                Type__c = log.type,
                Severity__c = String.valueOf(log.severity),
                Message__c = log.message.left(255),
                Response__c = MVP !=null ? String.valueOf(MVP).left(131071) : null,
                Context_User__c = log.contextUser,
                Session_Key__c = log.sessionKey,
                Timestamp__c = System.now(),
                LogLevel__c = log.logLevel.name(),
                Exception_Message__c = ex == null ? null : ex.getMessage(),
                Exception_Type__c = ex == null ? null : String.valueOf(ex),
                Stack_Trace__c = ex == null ? log.stackTrace : ex.getStackTraceString().left(32768)
        );
    }




}
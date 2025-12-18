/**
 * @group Logger
 * @description Exposes an InvocableMethod to add new log entries from flow
 */
public without sharing class FlowRecordLogEntry {
    @TestVisible
    private static final String FLOW_EXCEPTION_TYPE_NAME = 'Flow.FaultError';
    @TestVisible
    private static final String FLOW_FAULT_ERROR_DEFAULT_EXCEPTION_MESSAGE = 'An unknown Flow exception has occurred';
    @TestVisible
    private static final String FLOW_SOURCE_METADATA_TYPE = 'Flow';
    /**
     * @description  Invocable method, that can be called via flow to add new log entries.
     * @param requests requests to process
     */
    @InvocableMethod(
      category='Logger'
      label='Add Log Entry'
      description='Creates a log entry for a flow or process builder'
    )
    public static void logError(List<Request> requests) {
        if (requests.isEmpty()) {
            return;
        }
        
        Logger flowLogger = new Logger();
        List<String> errorMessageList = new List<String>();
        
        for (Request myRequest : requests) {
            String message = String.isNotBlank(myRequest.errorMessage) 
                ? myRequest.errorMessage 
                : FLOW_FAULT_ERROR_DEFAULT_EXCEPTION_MESSAGE;
            
            SamsaraLogEntries__c log = new SamsaraLogEntries__c(
                Message__c = message,
                Exception_Type__c = FLOW_EXCEPTION_TYPE_NAME,
                SourceMetadataType__c = FLOW_SOURCE_METADATA_TYPE,
                sourceApiName__c = myRequest.flowName
            );
            if (String.isNotBlank(myRequest.recordId)) {
                log.RecordId__c = myRequest.recordId;
            }
            
            Logger.LogContext logContext = flowLogger.createLogContext(getLoggingLevel(myRequest.logLevel));
            if (logContext != null) {
                logContext.stageLog(log);
                errorMessageList.add(
                    String.format(
                        'Error for recordId "{0}" : {1}',
                        new List<String>{ myRequest.recordId, message }
                    )
                );
            }
        }
        
        if (requests[0].throwExceptionAfterLogging == true) {
            throw new FlowException(String.join(errorMessageList, ', '));
        }
    }

    public static System.LoggingLevel getLoggingLevel(String loggingLevelName) {
        try {
          return System.LoggingLevel.valueOf(loggingLevelName?.trim().toUpperCase());
        } catch (NoSuchElementException ex) {
          return System.LoggingLevel.ERROR;
        }
      }
  
    /**
     * @description Request to create a log
     */
    public class Request {
      @InvocableVariable(
        label='Flow Name'
        description='API name of the flow calling the action'
        required=true
      )
      public String flowName;        
      @InvocableVariable(
        label='Error/Success Message'
        description='Error/Success Message'
        required=true
      )
      public String errorMessage;
      @InvocableVariable(
        label='Log Level'
        description='ERROR by default. Other possible values are NONE, ERROR, WARN, INFO, DEBUG, FINE, FINER, FINEST'
      )
      public String logLevel;
      @InvocableVariable(label='Record Id' description='Record Id for the error')
      public String recordId;
      @InvocableVariable(
        label='Throw exception after logging ?'
        description='Throw exception after logging (True/False)'
      )
      public Boolean throwExceptionAfterLogging;
    }
  }
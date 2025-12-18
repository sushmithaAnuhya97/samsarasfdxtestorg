/**
 * @group Test
 * @description Tests for FlowErrorLogger
 */
@IsTest(isParallel=true)
public with sharing class FlowErrorLoggerTest {
  private static final String LOG_LEVEL_DEBUG = 'DEBUG';
  private static final String LOG_LEVEL_ERROR = 'ERROR';
  private static final String LOG_LEVEL_FINE = 'FINE';
  private static final String LOG_LEVEL_FINER = 'FINER';
  private static final String LOG_LEVEL_FINEST = 'FINEST';
  private static final String LOG_LEVEL_INFO = 'INFO';
  private static final String LOG_LEVEL_NONE = 'NONE';
  private static final String LOG_LEVEL_WARN = 'WARN';
  private static final String MY_ERROR = 'Test Error Message';
  private static final String MY_FLOW_NAME = 'Test_Flow';
  private static final Id MY_RECORD_ID = '500000000000000000';

  private static FlowRecordLogEntry.Request createTestRequest() {
    FlowRecordLogEntry.Request request = new FlowRecordLogEntry.Request();
    request.flowName = MY_FLOW_NAME;
    request.errorMessage = MY_ERROR;
    request.logLevel = LOG_LEVEL_ERROR;
    request.recordId = MY_RECORD_ID;
    request.throwExceptionAfterLogging = false;
    return request;
  }

  @IsTest
  static void testFlowRecordLogEntry_Success() {
    FlowRecordLogEntry.Request request = createTestRequest();

    Test.startTest();
    FlowRecordLogEntry.logError(new List<FlowRecordLogEntry.Request>{request});
    Logger.insertMasterLogs();
    Test.stopTest();

    List<SamsaraLogEntries__c> entries = [SELECT Message__c, sourceApiName__c, RecordId__c, Level__c FROM SamsaraLogEntries__c];
    System.assertEquals(1, entries.size(), 'One log entry should be created');
    System.assertEquals(MY_ERROR, entries[0].Message__c, 'Error message should match');
    System.assertEquals(MY_FLOW_NAME, entries[0].sourceApiName__c, 'Flow name should match');
    System.assertEquals(MY_RECORD_ID, entries[0].RecordId__c, 'Record ID should match');
    System.assertEquals(LOG_LEVEL_ERROR, entries[0].Level__c, 'Log level should match');
  }

  @IsTest
  static void testFlowRecordLogEntry_ThrowException() {
    FlowRecordLogEntry.Request request = createTestRequest();
    request.throwExceptionAfterLogging = true;

    Test.startTest();
    try {
      FlowRecordLogEntry.logError(new List<FlowRecordLogEntry.Request>{request});
      System.assert(false, 'Exception should have been thrown');
    } catch (Exception e) {
      System.assert(e instanceof FlowException, 'Should throw FlowException');
      System.assert(e.getMessage().contains(MY_ERROR), 'Exception message should contain error message');
      // After catching the exception, persist the logs
      FlowErrorLogger.logError();
    }
    Test.stopTest();

    List<SamsaraLogEntries__c> entries = [SELECT Message__c FROM SamsaraLogEntries__c];
    System.assertEquals(1, entries.size(), 'One log entry should be created despite exception');
  }

  @IsTest
  static void testFlowRecordLogEntry_EmptyRequests() {
    Test.startTest();
    FlowRecordLogEntry.logError(new List<FlowRecordLogEntry.Request>());
    Test.stopTest();

    List<SamsaraLogEntries__c> entries = [SELECT Id FROM SamsaraLogEntries__c];
    System.assertEquals(0, entries.size(), 'No log entries should be created');
  }

  @IsTest
  static void testFlowRecordLogEntry_DefaultMessage() {
    FlowRecordLogEntry.Request request = createTestRequest();
    request.errorMessage = null;

    Test.startTest();
    FlowRecordLogEntry.logError(new List<FlowRecordLogEntry.Request>{request});
    Logger.insertMasterLogs();
    Test.stopTest();

    List<SamsaraLogEntries__c> entries = [SELECT Message__c FROM SamsaraLogEntries__c];
    System.assertEquals(1, entries.size(), 'One log entry should be created');
    System.assertEquals(FlowRecordLogEntry.FLOW_FAULT_ERROR_DEFAULT_EXCEPTION_MESSAGE, entries[0].Message__c, 'Should use default message');
  }

  @IsTest
  static void testFlowRecordLogEntry_LoggingLevels() {
    List<String> levels = new List<String>{
      LOG_LEVEL_DEBUG, LOG_LEVEL_ERROR, LOG_LEVEL_FINE, LOG_LEVEL_FINER,
      LOG_LEVEL_FINEST, LOG_LEVEL_INFO, LOG_LEVEL_NONE, LOG_LEVEL_WARN,
      'INVALID_LEVEL', null, ''
    };

    for(String level : levels) {
      System.LoggingLevel result = FlowRecordLogEntry.getLoggingLevel(level);
      if(String.isBlank(level) || level == 'INVALID_LEVEL') {
        System.assertEquals(LoggingLevel.ERROR, result, 'Invalid or blank level should default to ERROR');
      } else {
        System.assertEquals(LoggingLevel.valueOf(level), result, 'Should return correct logging level');
      }
    }
  }

  @IsTest
  static void testFlowErrorLogger_InsertMasterLogs() {
    FlowRecordLogEntry.Request request = createTestRequest();
    
    FlowRecordLogEntry.logError(new List<FlowRecordLogEntry.Request>{request});
    
    Test.startTest();
    FlowErrorLogger.logError();
    Test.stopTest();

    List<SamsaraLogEntries__c> entries = [SELECT Id FROM SamsaraLogEntries__c];
    System.assertNotEquals(0, entries.size(), 'Log entries should be persisted');
  }

  @IsTest
  static void testFlowErrorLogger_NoLogs() {
    Test.startTest();
    FlowErrorLogger.logError();
    Test.stopTest();

    List<SamsaraLogEntries__c> entries = [SELECT Id FROM SamsaraLogEntries__c];
    System.assertEquals(0, entries.size(), 'No log entries should be created');
  }
}
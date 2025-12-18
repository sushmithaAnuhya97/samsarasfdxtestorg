/**
 * @group Logger
 * @description This class is the base logger for apex, components and flow fluent logging
 */
public without sharing class Logger {
    private static List<SamsaraLogEntries__c> masterLogs = new List<SamsaraLogEntries__c>();
    private static final String ERROR_FORMAT = '{0} of {1} : {2}';
    private static Long startTimeMillis = null; 
    private static Id recordId = null;
    private static Set<Id> recordIds = null;
    private static String primaryObjectName = null;
    private static String functionalityType = null;
    private static String functionalitySubType = null;
    public Logger() {}

    /**
     * @description Publishes log records from the LWC logger component.
     */
    @AuraEnabled
    public static void publish(List<SamsaraLogEntries__c> logRecords, String recordId, String functionalityType, String functionalitySubType, Long startTimeMillis) {
        try {
            if (logRecords != null && logRecords.size() > 0) {
                LoggerUtils.createLogRecords(
                    logRecords,
                    startTimeMillis,
                    recordId,
                    recordIds,
                    primaryObjectName,
                    functionalityType,
                    functionalitySubType,
                    TransactionId.get()
                );
            }
        } catch (Exception e) {
            System.debug('Error publishing logs:' + e);
        }
    }

    /**
     * @description Insert master logs captured during transaction. This method is useful
     * if you want collect logs and insert it later.
     */
    public static void insertMasterLogs() {
        try {
            if (masterLogs != null && masterLogs.size() > 0) {
                if (startTimeMillis == null) {
                    startTimeMillis = System.currentTimeMillis();
                }
                LoggerUtils.createLogRecords(
                    masterLogs,
                    startTimeMillis,
                    recordId,
                    recordIds,
                    primaryObjectName,
                    functionalityType,
                    functionalitySubType,
                    TransactionId.get()
                );
            }
        } catch (Exception e) {
            System.debug('Error inserting master logs: ' + e);
        }
        masterLogs = new List<SamsaraLogEntries__c>();
        startTimeMillis = null;
        recordId = null;
        recordIds = null;
        primaryObjectName = null;
    }

    public static List<SamsaraLogEntries__c> getMasterLogs() {
        return masterLogs;
    }

    public static void setRecordId(Id recordId) {
        Logger.recordId = recordId;
    }

    public static void setRecordIds(Set<Id> recordIds) {
        Logger.recordIds = recordIds;
    }

    public static void setPrimaryObjectName(String primaryObjectName) {
        Logger.primaryObjectName = primaryObjectName;
    }

    public static void setFunctionalityType(String functionalityType) {
        Logger.functionalityType = functionalityType;
    }

    public static void setFunctionalitySubType(String functionalitySubType) {
        Logger.functionalitySubType = functionalitySubType;
    }

    /**
     * @description Creates a LogContext with the specified logging level
     */
    public LogContext createLogContext(System.LoggingLevel level) {
        if (startTimeMillis == null) {
            startTimeMillis = System.currentTimeMillis();
        }
        return new LogContext(level != null ? level : System.LoggingLevel.ERROR);
    }

    public static LogContext atNone() {
        return new Logger().createLogContext(System.LoggingLevel.NONE);
    }

    public static LogContext atError() {
        return new Logger().createLogContext(System.LoggingLevel.ERROR);
    }

    public static LogContext atWarn() {
        return new Logger().createLogContext(System.LoggingLevel.WARN);
    }

    public static LogContext atInfo() {
        return new Logger().createLogContext(System.LoggingLevel.INFO);
    }

    public static LogContext atDebug() {
        return new Logger().createLogContext(System.LoggingLevel.DEBUG);
    }

    public static LogContext atFine() {
        return new Logger().createLogContext(System.LoggingLevel.FINE);
    }

    public static LogContext atFiner() {
        return new Logger().createLogContext(System.LoggingLevel.FINER);
    }

    public static LogContext atFinest() {
        return new Logger().createLogContext(System.LoggingLevel.FINEST);
    }

    /**
     * @description The LogContext inner class is used to create and manage log entries.
     * It provides a fluent interface for setting log properties and adding them to the master logs.
     */
    public class LogContext {
        private Integer lineNumber;
        private LoggingLevel level;
        private String message;
        private String methodName;
        private String className;
        private String recordId;
        private String UUID;
        private DateTime requestTime;
        private DateTime responseTime;
        private DateTime acknowledgementTime;
        private String message2;

        public LogContext(LoggingLevel level) {
            this.level = level;
        }

        private void addLogToMaster(SamsaraLogEntries__c log) {
            String transactionLimits = JSON.serialize(LoggerUtils.loadTransactionLimits());
            log.TransactionLimits__c = transactionLimits;
            masterLogs.add(log);
        }

        /**
         * @description Method to create a log entry for an exception
         */
        public LogContext setExceptionOrMessage(Exception e) {
            if (e == null) return this;

            String extractedMethodName = getMethodNameFromStackTrace(e);
            String extractedClassName = getClassNameFromStackTrace(e);

            SamsaraLogEntries__c log = new SamsaraLogEntries__c(
                sourceApiName__c = String.isNotBlank(this.className) ? this.className : extractedClassName,
                SourceMetadataType__c = 'Apex',
                Exception_Type__c = e.getTypeName(),
                Line_Number__c = e.getLineNumber(),
                Method__c = String.isNotBlank(this.methodName) ? this.methodName : extractedMethodName,
                Level__c = String.valueOf(level),
                Message__c = e.getMessage(),
                RecordId__c = recordId,
                UUID__c = String.isNotBlank(this.UUID) ? this.UUID : null,
                Response_Time__c = responseTime,
                Request_Time__c = requestTime,
                Acknowledgement_Time__c = acknowledgementTime,
                Message2__c = message2,
                Stack_Trace__c = e.getStackTraceString()
            );
            if (String.isNotBlank(message)) {
                log.Message__c = message + ' ' + log.Message__c;
            }
            addLogToMaster(log);
            return this;
        }

        public LogContext setExceptionOrMessage(List<Database.SaveResult> dmlResults) {
            if (dmlResults == null || dmlResults.size() == 0) {
                return this;
            }
            for (Integer i = 0; i < dmlResults.size(); i++) {
                if (!dmlResults[i].isSuccess()) {
                    recordId = dmlResults[i].getId();
                    stageDmlErrors(dmlResults[i].getErrors());
                }
            }
            return this;
        }

        public LogContext setExceptionOrMessage(List<Database.DeleteResult> dmlResults) {
            if (dmlResults == null || dmlResults.size() == 0) {
                return this;
            }
            for (Integer i = 0; i < dmlResults.size(); i++) {
                if (!dmlResults[i].isSuccess()) {
                    recordId = dmlResults[i].getId();
                    stageDmlErrors(dmlResults[i].getErrors());
                }
            }
            return this;
        }

        public LogContext setExceptionOrMessage(List<Database.UndeleteResult> dmlResults) {
            if (dmlResults == null || dmlResults.size() == 0) {
                return this;
            }
            for (Integer i = 0; i < dmlResults.size(); i++) {
                if (!dmlResults[i].isSuccess()) {
                    recordId = dmlResults[i].getId();
                    stageDmlErrors(dmlResults[i].getErrors());
                }
            }
            return this;
        }

        public LogContext setExceptionOrMessage(List<Database.UpsertResult> dmlResults) {
            if (dmlResults == null || dmlResults.size() == 0) {
                return this;
            }
            for (Integer i = 0; i < dmlResults.size(); i++) {
                if (!dmlResults[i].isSuccess()) {
                    recordId = dmlResults[i].getId();
                    stageDmlErrors(dmlResults[i].getErrors());
                }
            }
            return this;
        }

        public LogContext setExceptionOrMessage(List<Messaging.SendEmailResult> sendEmailResults) {
            if (sendEmailResults.isEmpty()) {
                return this;
            }
            for (Integer i = 0; i < sendEmailResults.size(); i++) {
                if (!sendEmailResults[i].isSuccess()) {
                    stageSendEmailErrors(sendEmailResults[i].getErrors());
                }
            }
            return this;
        }

        public LogContext setExceptionOrMessage(Approval.ProcessResult approvalProcessResult) {
            return this.setExceptionOrMessage(new List<Approval.ProcessResult>{ approvalProcessResult });
        }

        public LogContext setExceptionOrMessage(List<Approval.ProcessResult> approvalProcessResults) {
            if (approvalProcessResults.isEmpty()) {
                return this;
            }
            for (Approval.ProcessResult approvalProcessResult : approvalProcessResults) {
                if (!approvalProcessResult.isSuccess()) {
                    stageDmlErrors(approvalProcessResult.getErrors());
                }
            }
            return this;
        }

        public LogContext setExceptionOrMessage(Approval.UnlockResult approvalUnlockResult) {
            return this.setExceptionOrMessage(new List<Approval.UnlockResult>{ approvalUnlockResult });
        }

        public LogContext setExceptionOrMessage(List<Approval.UnlockResult> approvalUnlockResults) {
            if (approvalUnlockResults.isEmpty()) {
                return this;
            }
            for (Approval.UnlockResult approvalUnlockResult : approvalUnlockResults) {
                if (!approvalUnlockResult.isSuccess()) {
                    stageDmlErrors(approvalUnlockResult.getErrors());
                }
            }
            return this;
        }

        public void setExceptionOrMessage(String message) {
            SamsaraLogEntries__c log = new SamsaraLogEntries__c();
            log.Level__c = String.valueOf(level);
            log.sourceApiName__c = className;
            log.SourceMetadataType__c = 'Apex';
            log.Method__c = methodName;
            log.RecordId__c = recordId;
            log.Message__c = message;
            log.UUID__c = String.isNotBlank(this.UUID) ? this.UUID : null;
            log.Response_Time__c = responseTime;
            log.Request_Time__c = requestTime;
            log.Acknowledgement_Time__c = acknowledgementTime;
            log.Message2__c = message2;
            addLogToMaster(log);
        }

        public LogContext setMethod(String methodName) {
            this.methodName = methodName;
            return this;
        }

        public LogContext setClassName(String className) {
            this.className = className;
            return this;
        }

        public LogContext setLineNumber(Integer lineNumber) {
            this.lineNumber = lineNumber;
            return this;
        }

        public LogContext setRecordId(String recordId) {
            this.recordId = recordId;
            return this;
        }
        
        public LogContext setUUID(String uuid) {
            this.UUID = uuid;
            return this;
        }
        
         public LogContext setRequestTime(DateTime requestTime) {
            this.requestTime = requestTime;
            return this;
        }
        
        public LogContext setResponseTime(DateTime responseTime) {
            this.responseTime = responseTime;
            return this;
        }
        
        public LogContext setAcknowledgementTime(DateTime acknowledgementTime) {
            this.acknowledgementTime = acknowledgementTime;
            return this;
        }
        
        public LogContext setMessage2(String message2) {
            this.message2 = message2;
            return this;
        }

        public void stageLog(SamsaraLogEntries__c log) {
            log.Level__c = String.valueOf(level);
            addLogToMaster(log);
        }
        
     

        private String getMethodNameFromStackTrace(Exception e) {
            String trace = e.getStackTraceString();
            if (String.isEmpty(trace) || !trace.startsWith('Class.')) {
                return null;
            } else {
                return trace.substringBefore(':').subStringAfterLast('.');
            }
        }

        private String getClassNameFromStackTrace(Exception e) {
            String trace = e.getStackTraceString();
            if (String.isEmpty(trace) || !trace.startsWith('Class.')) {
                return null;
            } else {
                String fullPath = trace.substringBefore(':').subStringAfter('Class.');
                return fullPath.contains('.') ? fullPath.subStringBeforeLast('.') : fullPath;
            }
        }

        private void stageDmlErrors(List<Database.Error> errs) {
            Integer iCount = 0;
            for (Database.Error err : errs) {
                createLog(
                    err.getStatusCode(),
                    String.format(
                        ERROR_FORMAT,
                        new List<Object>{ iCount, errs.size(), err.getMessage() }
                    )
                );
                iCount++;
            }
        }

        private void stageSendEmailErrors(List<Messaging.SendEmailError> errs) {
            Integer iCount = 1;
            for (Messaging.SendEmailError err : errs) {
                createLog(
                    err.getStatusCode(),
                    String.format(
                        ERROR_FORMAT,
                        new List<Object>{ iCount, errs.size(), err.getMessage() }
                    )
                );
                iCount++;
            }
        }

        /**
         * @description Creates a new Log and adds it to the master logs
         */
        private void createLog(System.StatusCode statusCode, String errorMessage) {
            SamsaraLogEntries__c log = new SamsaraLogEntries__c(
                sourceApiName__c = className,
                SourceMetadataType__c = 'Apex',
                Exception_Type__c = String.valueOf(statusCode),
                Line_Number__c = lineNumber,
                Method__c = methodName,
                RecordId__c = recordId,
                Level__c = String.valueOf(level),
                Message__c = errorMessage,
                UUID__c = String.isNotBlank(this.UUID) ? this.UUID : null,
                Response_Time__c = responseTime,
                Request_Time__c = requestTime,
                Acknowledgement_Time__c = acknowledgementTime,
                Message2__c = message2
            );
            if (String.isNotBlank(message)) {
                log.Message__c = message + ' ' + log.Message__c;
            }
            addLogToMaster(log);
        }
    }
}
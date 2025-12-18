public class LoggerUtils {
    private static Id cachedParentLogId;

    public static Boolean createLogRecords(
        List<SamsaraLogEntries__c> logs, 
        Long startTimeMillis, 
        Id recordId, 
        Set<Id> recordIds, 
        String primaryObjectName, 
        String functionalityType, 
        String functionalitySubType,
        String userTransactionId
    ) {
        if (logs == null || logs.isEmpty()) {
            return false;
        }

        Map<String, Logger_Config__mdt> configs = Logger_Config__mdt.getAll();
        List<SamsaraLogEntries__c> filteredLogs = filterLogs(logs, configs);
        if (filteredLogs.isEmpty()) {
            return false;
        }

        String organizationLimits = System.JSON.serializePretty(loadOrganizationLimits());
        String transactionLimits = System.JSON.serializePretty(loadTransactionLimits());

        Boolean canUseFuture = isFutureAllowedByOrgLimits() && isFutureEnabledInMetadata(configs);
        Boolean canUsePlatformEvent = isPlatformEventAllowedByOrgLimits() && isPlatformEventEnabledInMetadata(configs);
        Boolean canUseSynchronous = isSynchronousEnabledInMetadata(configs);
        Boolean isAsyncContext = isAsyncExecutionContext();

        if (isAsyncContext) {
            if (canUsePlatformEvent) {
                return createLogsUsingPlatformEvent(
                    filteredLogs,
                    organizationLimits,
                    transactionLimits,
                    startTimeMillis,
                    recordId,
                    recordIds,
                    primaryObjectName,
                    functionalityType,
                    functionalitySubType,
                    userTransactionId
                );
            }
            return false; // Do not fallback to synchronous insert in async context
        }

        // Synchronous context
        if (canUseFuture && (Limits.getFutureCalls() < Limits.getLimitFutureCalls() || Limits.getFutureCalls() == 0)) {
            String serializedLogs = JSON.serialize(filteredLogs);
            createLogsUsingFuture(
                serializedLogs,
                organizationLimits,
                transactionLimits,
                startTimeMillis,
                recordId,
                recordIds,
                primaryObjectName,
                functionalityType,
                functionalitySubType,
                userTransactionId
            );
            return true;
        }

        if (canUsePlatformEvent) {
            return createLogsUsingPlatformEvent(
                filteredLogs,
                organizationLimits,
                transactionLimits,
                startTimeMillis,
                recordId,
                recordIds,
                primaryObjectName,
                functionalityType,
                functionalitySubType,
                userTransactionId
            );
        }

        // Synchronous insert as last resort, only in sync context
        if (canUseSynchronous) {
            Long durationMillis = System.currentTimeMillis() - startTimeMillis;
            Id logId = insertLog(
                organizationLimits,
                transactionLimits,
                durationMillis,
                recordId,
                recordIds,
                primaryObjectName,
                functionalityType,
                functionalitySubType,
                userTransactionId
            );
            insertLogEntry(filteredLogs, logId);
            return true;
        }

        return false; // All logging mechanisms are disabled
    }

    private static Boolean isAsyncExecutionContext() {
        return System.isBatch() || System.isQueueable() || System.isFuture();
    }

    private static Boolean createLogsUsingPlatformEvent(
        List<SamsaraLogEntries__c> logs, 
        String organizationLimits, 
        String transactionLimits, 
        Long startTimeMillis, 
        Id recordId, 
        Set<Id> recordIds, 
        String primaryObjectName, 
        String functionalityType, 
        String functionalitySubType,
        String userTransactionId
    ) {
        Map<String, Object> eventData = new Map<String, Object>{
            'logs' => logs,
            'organizationLimits' => organizationLimits,
            'transactionLimits' => transactionLimits,
            'startTimeMillis' => startTimeMillis,
            'primaryObjectName' => primaryObjectName,
            'functionalityType' => functionalityType,
            'functionalitySubType' => functionalitySubType,
            'userTransactionId' => userTransactionId
        };

        if (recordId != null) {
            eventData.put('recordId', recordId);
        }
        if (recordIds != null && !recordIds.isEmpty()) {
            eventData.put('recordIds', new List<Id>(recordIds));
        }

        Log_Message__e event = new Log_Message__e();
        event.Serialized_Logs__c = JSON.serialize(eventData);

        return EventBus.publish(event).isSuccess();
    }

    @future
    public static void createLogsUsingFuture(
        String serializedLogs, 
        String organizationLimits, 
        String transactionLimits, 
        Long startTimeMillis, 
        Id recordId, 
        Set<Id> recordIds, 
        String primaryObjectName, 
        String functionalityType, 
        String functionalitySubType,
        String userTransactionId
    ) {
        if (String.isBlank(serializedLogs)) {
            return;
        }

        List<SamsaraLogEntries__c> logs = deserializeLogs(serializedLogs);
        if (!logs.isEmpty()) {
            Long durationMillis = System.currentTimeMillis() - startTimeMillis;
            Id logId = insertLog(
                organizationLimits, 
                transactionLimits, 
                durationMillis, 
                recordId, 
                recordIds, 
                primaryObjectName, 
                functionalityType, 
                functionalitySubType,
                userTransactionId
            );
            insertLogEntry(logs, logId);
        }
    }

    public static Id insertLog(
        String organizationLimits, 
        String transactionLimits, 
        Long durationMillis, 
        Id recordId, 
        Set<Id> recordIds, 
        String primaryObjectName, 
        String functionalityType, 
        String functionalitySubType,
        String userTransactionId
    ) {
        if (cachedParentLogId != null) {
            return cachedParentLogId;
        }

        // Check if a parent log already exists for this transaction
        List<SamsaraLog__c> existingLogs = [
            SELECT Id FROM SamsaraLog__c WHERE User_Transaction__c = :userTransactionId LIMIT 1
        ];
        if (!existingLogs.isEmpty()) {
            cachedParentLogId = existingLogs[0].Id;
            return existingLogs[0].Id;
        }

        SamsaraLog__c logRecord = new SamsaraLog__c(
            Context_User__c = UserInfo.getUserId(),
            OrganizationLimits__c = organizationLimits,
            TransactionLimits__c = transactionLimits,
            Duration_in_mili_seconds__c = durationMillis,
            User_Transaction__c = userTransactionId
        );

        if (recordId != null) {
            logRecord.RecordId__c = recordId;
        }
        if (recordIds != null && !recordIds.isEmpty()) {
            logRecord.RecordIds__c = String.join(new List<Id>(recordIds), ',');
        }
        if (primaryObjectName != null) {
            logRecord.Primary_Object_Name__c = primaryObjectName;
        }
        if (functionalityType != null) {
            logRecord.Functionality_Type__c = functionalityType;
        }
        if (functionalitySubType != null) {
            logRecord.Functionality_Sub_Type__c = functionalitySubType;
        }

        try {
            upsert logRecord;
            cachedParentLogId = logRecord.Id;
            return logRecord.Id;
        } catch (DmlException ex) {
                //addDelay();
                List<SamsaraLog__c> retryLogs = [
                    SELECT Id FROM SamsaraLog__c WHERE User_Transaction__c = :userTransactionId LIMIT 1
                ];
                if (!retryLogs.isEmpty()) {
                    cachedParentLogId = retryLogs[0].Id;
                    logRecord.Id = retryLogs[0].Id;
                    upsert logRecord;
                    return cachedParentLogId;
                }
            }
            return null;
        }

    public static void insertLogEntry(List<SamsaraLogEntries__c> logs, Id LogId) {
        if (!logs.isEmpty() && LogId != null) {
            for (SamsaraLogEntries__c log : logs) {
                log.SamsaraLog__c = LogId;
            }
            Database.insert(logs);
        }
    }

    private static List<SamsaraLogEntries__c> filterLogs(
        List<SamsaraLogEntries__c> logs, 
        Map<String, Logger_Config__mdt> configs
    ) {
        if(configs == null || configs.isEmpty()) {
            return logs;
        }
        List<SamsaraLogEntries__c> filteredLogs = new List<SamsaraLogEntries__c>();
        for (SamsaraLogEntries__c log : logs) {
            if (isLoggingEnabled(log.sourceApiName__c, log.Level__c, configs)) {
                filteredLogs.add(log);
            }
        }
        return filteredLogs;
    }

    private static Boolean isLoggingEnabled(
        String apiName, 
        String logLevel, 
        Map<String, Logger_Config__mdt> configs
    ) {
        if(configs == null || configs.isEmpty()) {
            return true;
        }
        // Check specific logging configurations
        for (Logger_Config__mdt config : configs.values()) {
            if (!config.Is_Active__c) {
                continue;
            }
            // Check for global bypass
            if (config.Is_Active__c && config.Bypass_Logging__c) {
              return false; // Bypass logging globally if the checkbox is checked
            }
            // Check for user, profile, or component level bypasses
            if (config.Bypass_Level__c == 'User' && config.Bypass_Target__c == UserInfo.getUserId()) {
                return false;
            }
            if (config.Bypass_Level__c == 'Profile' && config.Bypass_Target__c == UserInfo.getProfileId()) {
                return false;
            }
            if ((config.Bypass_Level__c == 'Class' || config.Bypass_Level__c == 'Flow' || config.Bypass_Level__c == 'Aura' || config.Bypass_Level__c == 'LWC') && config.Bypass_Target__c == apiName) {
                return false;
            }

            // Check for logging level bypasses
            if (config.Bypass_Level__c == 'Logging Level' && String.isNotBlank(logLevel) && config.Bypass_Target__c?.equalsIgnoreCase(logLevel)) {
                return false;
            }
        }

        return true; // Logging is enabled if no bypass rule matches
    }

    public static void write(List<Log_Message__e> logEvents) {
        List<SamsaraLogEntries__c> logsToUpsert = new List<SamsaraLogEntries__c>();
        String organizationLimits = null;
        String transactionLimits = null;
        Long startTimeMillis = null;
        Id recordId = null;
        Set<Id> recordIds = null;
        String primaryObjectName = null;
        String functionalityType = null;
        String functionalitySubType = null;
        String userTransactionId = null;

        for (Log_Message__e event : logEvents) {
            Map<String, Object> eventData = (Map<String, Object>) JSON.deserializeUntyped(event.Serialized_Logs__c);
            if (eventData != null) {
                organizationLimits = (String) eventData.get('organizationLimits');
                transactionLimits = (String) eventData.get('transactionLimits');
                startTimeMillis = (Long) eventData.get('startTimeMillis');
                primaryObjectName = (String) eventData.get('primaryObjectName');
                functionalityType = (String) eventData.get('functionalityType');
                functionalitySubType = (String) eventData.get('functionalitySubType');
                userTransactionId = (String) eventData.get('userTransactionId');

                if (eventData.containsKey('recordId')) {
                    recordId = (Id) eventData.get('recordId');
                }
                if (eventData.containsKey('recordIds')) {
                    List<Object> idList = (List<Object>) eventData.get('recordIds');
                    if (idList != null) {
                        recordIds = new Set<Id>();
                        for (Object objId : idList) {
                            recordIds.add((Id) objId);
                        }
                    }
                }

                List<SamsaraLogEntries__c> logs = (List<SamsaraLogEntries__c>) JSON.deserialize(
                    JSON.serialize(eventData.get('logs')),
                    List<SamsaraLogEntries__c>.class
                );
                logsToUpsert.addAll(logs);
            }
        }

        if (!logsToUpsert.isEmpty()) {
            Long durationMillis = System.currentTimeMillis() - startTimeMillis;
            Id logId = insertLog(
                organizationLimits, 
                transactionLimits, 
                durationMillis, 
                recordId, 
                recordIds, 
                primaryObjectName, 
                functionalityType, 
                functionalitySubType,
                userTransactionId
            );
            insertLogEntry(logsToUpsert, logId);
        }
    }

    @TestVisible
    private static Boolean isFutureEnabledInMetadata(Map<String, Logger_Config__mdt> configs) {
      if(configs == null || configs.isEmpty()) {
        return true;
      }
        for (Logger_Config__mdt config : configs.values()) {
            if (config.Is_Active__c && config.Logging_Mechanism__c == 'Future Method') {
                return false;
            }
        }
        return true;
    }

    @TestVisible
    private static Boolean isPlatformEventEnabledInMetadata(Map<String, Logger_Config__mdt> configs) {
      if(configs == null || configs.isEmpty()) {
        return true;
      }
        for (Logger_Config__mdt config : configs.values()) {
            if (config.Is_Active__c && config.Logging_Mechanism__c == 'Platform Events') {
                return false;
            }
        }
        return true;
    }

    @TestVisible
    private static Boolean isSynchronousEnabledInMetadata(Map<String, Logger_Config__mdt> configs) {
      if(configs == null || configs.isEmpty()) {
        return true;
      }
      for (Logger_Config__mdt config : configs.values()) {
            if (config.Is_Active__c && config.Logging_Mechanism__c == 'Synchronous Apex') {
                return false;
            }
        }
        return true;
    }

    private static Boolean isFutureAllowedByOrgLimits() {
        Map<String, System.OrgLimit> orgLimits = System.OrgLimits.getMap();
        if (orgLimits.containsKey('DailyAsyncApexExecutions')) {
            System.OrgLimit asyncApexLimit = orgLimits.get('DailyAsyncApexExecutions');
            Integer asyncApexUsed = asyncApexLimit.getValue();
            Integer asyncApexMax = asyncApexLimit.getLimit();
            Decimal threshold = Decimal.valueOf(System.Label.AsyncLimitThreshold);
            if (asyncApexMax > 0 && asyncApexUsed > 0 && ((Decimal) asyncApexUsed / (Decimal) asyncApexMax) >= threshold) {
                return false;
            }
        }
        return true;
    }

    private static Boolean isPlatformEventAllowedByOrgLimits() {
        Map<String, System.OrgLimit> orgLimits = System.OrgLimits.getMap();
        Boolean dailyDeliveredOk = true;
        Boolean hourlyPublishedOk = true;
        Decimal threshold = Decimal.valueOf(System.Label.PlatformEventThreshold);

        if (orgLimits.containsKey('DailyDeliveredPlatformEvents')) {
            System.OrgLimit dailyDeliveredLimit = orgLimits.get('DailyDeliveredPlatformEvents');
            Integer dailyDeliveredUsed = dailyDeliveredLimit.getValue();
            Integer dailyDeliveredMax = dailyDeliveredLimit.getLimit();
            if (dailyDeliveredMax > 0 && dailyDeliveredUsed > 0 && ((Decimal) dailyDeliveredUsed / (Decimal) dailyDeliveredMax) >= threshold) {
                dailyDeliveredOk = false;
            }
        }
        if (orgLimits.containsKey('HourlyPublishedPlatformEvents')) {
            System.OrgLimit hourlyPublishedLimit = orgLimits.get('HourlyPublishedPlatformEvents');
            Integer hourlyPublishedUsed = hourlyPublishedLimit.getValue();
            Integer hourlyPublishedMax = hourlyPublishedLimit.getLimit();
            if (hourlyPublishedMax > 0 && hourlyPublishedUsed > 0 && ((Decimal) hourlyPublishedUsed / (Decimal) hourlyPublishedMax) >= threshold) {
                hourlyPublishedOk = false;
            }
        }
        return dailyDeliveredOk && hourlyPublishedOk;
    }

    public static List<SamsaraLogEntries__c> deserializeLogs(String serializedLogs) {
        return (List<SamsaraLogEntries__c>) JSON.deserialize(serializedLogs, List<SamsaraLogEntries__c>.class);
    }

    public static List<SerializableLimit> loadOrganizationLimits() {
        List<SerializableLimit> serializableOrganizationLimits = new List<SerializableLimit>();
        Map<String, System.OrgLimit> systemOrgLimits = System.OrgLimits.getMap();

        List<String> systemOrgLimitNames = new List<String>(systemOrgLimits.keySet());
        systemOrgLimitNames.sort();
        for (String systemOrgLimitName : systemOrgLimitNames) {
            System.OrgLimit systemOrgLimit = systemOrgLimits.get(systemOrgLimitName);
            SerializableLimit serializableOrganizationLimit = new SerializableLimit(
                systemOrgLimit.getName(),
                systemOrgLimit.getValue(),
                systemOrgLimit.getLimit()
            );
            serializableOrganizationLimits.add(serializableOrganizationLimit);
        }

        return serializableOrganizationLimits;
    }

    /*private static void addDelay() {
        try {
            datetime myStartDateTime = datetime.now();
                DateTime newDateTime = myStartDateTime.addSeconds(5);
                while (datetime.now() < newDateTime ) {
        		    }
        } catch (Exception e) {
            System.debug('Error adding delay: ' + e.getMessage());
        }
    }*/


    public static List<SerializableLimit> loadTransactionLimits() {
        List<SerializableLimit> transactionLimits = new List<SerializableLimit>();

        transactionLimits.add(new SerializableLimit('Number of SOQL Queries', Limits.getQueries(), Limits.getLimitQueries()));
        transactionLimits.add(new SerializableLimit('Number of Query Rows', Limits.getQueryRows(), Limits.getLimitQueryRows()));
        transactionLimits.add(new SerializableLimit('Number of SOSL Queries', Limits.getSoslQueries(), Limits.getLimitSoslQueries()));
        transactionLimits.add(new SerializableLimit('Number of DML Statements', Limits.getDmlStatements(), Limits.getLimitDmlStatements()));
        transactionLimits.add(new SerializableLimit('Number of DML Rows', Limits.getDmlRows(), Limits.getLimitDmlRows()));
        transactionLimits.add(new SerializableLimit('Max CPU Time', Limits.getCpuTime(), Limits.getLimitCpuTime()));
        transactionLimits.add(new SerializableLimit('Maximum Heap Size', Limits.getHeapSize(), Limits.getLimitHeapSize()));
        transactionLimits.add(new SerializableLimit('Number of Callouts', Limits.getCallouts(), Limits.getLimitCallouts()));
        transactionLimits.add(new SerializableLimit('Number of Future Calls', Limits.getFutureCalls(), Limits.getLimitFutureCalls()));
        transactionLimits.add(new SerializableLimit('Number of Queueable Jobs', Limits.getQueueableJobs(), Limits.getLimitQueueableJobs()));

        return transactionLimits;
    }

    @TestVisible
    private class SerializableLimit {
        public String Name { get; set; }
        public Integer Used { get; set; }
        public Integer Max { get; set; }

        public SerializableLimit(String name, Integer used, Integer max) {
            this.Name = name;
            this.Used = used;
            this.Max = max;
        }
    }
}
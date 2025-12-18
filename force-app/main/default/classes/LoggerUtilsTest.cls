@IsTest
private class LoggerUtilsTest {

    private static final String TEST_COMPONENT_API_NAME = 'TestComponent';

    private static List<SamsaraLogEntries__c> createTestLogEntries(Integer count) {
        List<SamsaraLogEntries__c> entries = new List<SamsaraLogEntries__c>();
        for (Integer i = 0; i < count; i++) {
            entries.add(new SamsaraLogEntries__c(
                Message__c = 'Test Message ' + i,
                Level__c = 'INFO',
                SourceApiName__c = TEST_COMPONENT_API_NAME,
                SourceMetadataType__c = 'Apex'
            ));
        }
        return entries;
    }

    static testMethod void testDeserializeLogs() {
        List<SamsaraLogEntries__c> entries = createTestLogEntries(2);
        String serializedLogs = JSON.serialize(entries);
        
        Test.startTest();
        List<SamsaraLogEntries__c> deserializedLogs = LoggerUtils.deserializeLogs(serializedLogs);
        Test.stopTest();
        
        System.assertEquals(2, deserializedLogs.size());
        System.assertEquals(entries[0].Message__c, deserializedLogs[0].Message__c);
    }
    
    static testMethod void testInsertLog() {
        String transactionLimits = JSON.serialize(LoggerUtils.loadTransactionLimits());
        String organizationLimits = JSON.serialize(LoggerUtils.loadOrganizationLimits());
        Long durationMillis = 1000;
        Id recordId = UserInfo.getUserId();
        Set<Id> recordIds = new Set<Id>{UserInfo.getUserId()};
        String primaryObjectName = 'Account';
        String functionalityType = 'Test';
        String functionalitySubType = 'InsertLog';
        String userTransactionId = 'test-transaction-id';
        
        // Insert a record with same User_Transaction__c to force DML exception
        SamsaraLog__c existingLog = new SamsaraLog__c(
            Context_User__c = UserInfo.getUserId(),
            OrganizationLimits__c = organizationLimits,
            TransactionLimits__c = transactionLimits,
            Duration_in_mili_seconds__c = durationMillis,
            User_Transaction__c = userTransactionId
        );
        insert existingLog;
        
        Test.startTest();
        Id logId = LoggerUtils.insertLog(organizationLimits, transactionLimits, durationMillis, recordId, recordIds, primaryObjectName, functionalityType, functionalitySubType, userTransactionId);
        Test.stopTest();
        
        SamsaraLog__c insertedLog = [SELECT Id, Context_User__c, OrganizationLimits__c, TransactionLimits__c, Duration_in_mili_seconds__c, RecordId__c, RecordIds__c, Primary_Object_Name__c, Functionality_Type__c, Functionality_Sub_Type__c FROM SamsaraLog__c WHERE Id = :logId];
        System.assertEquals(UserInfo.getUserId(), insertedLog.Context_User__c);
        System.assertEquals(organizationLimits, insertedLog.OrganizationLimits__c);
        System.assertEquals(transactionLimits, insertedLog.TransactionLimits__c);
        System.assertEquals(durationMillis, insertedLog.Duration_in_mili_seconds__c);
    }
    
    static testMethod void testInsertLogEntry() {
        String userTransactionId = 'test-transaction-id';
        Id logId = LoggerUtils.insertLog(null, null, null, null, null, null, null, null, userTransactionId);
        List<SamsaraLogEntries__c> entries = createTestLogEntries(2);
        
        Test.startTest();
        LoggerUtils.insertLogEntry(entries, logId);
        Test.stopTest();
        
        List<SamsaraLogEntries__c> insertedEntries = [SELECT Id, SamsaraLog__c FROM SamsaraLogEntries__c WHERE SamsaraLog__c = :logId];
        System.assertEquals(2, insertedEntries.size());
    }
    
    static testMethod void testCreateLogsUsingFuture() {
        List<SamsaraLogEntries__c> entries = createTestLogEntries(2);
        String serializedLogs = JSON.serialize(entries);
        String transactionLimits = JSON.serialize(LoggerUtils.loadTransactionLimits());
        String organizationLimits = JSON.serialize(LoggerUtils.loadOrganizationLimits());
        Long startTimeMillis = System.currentTimeMillis();
        Id recordId = UserInfo.getUserId();
        Set<Id> recordIds = new Set<Id>{UserInfo.getUserId()};
        String primaryObjectName = 'Contact';
        String functionalityType = 'Test';
        String functionalitySubType = 'Future';
        String userTransactionId = 'test-transaction-id';
        
        Test.startTest();
        LoggerUtils.createLogsUsingFuture(
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
        Test.stopTest();
        
        List<SamsaraLogEntries__c> insertedEntries = [SELECT Id FROM SamsaraLogEntries__c];
        System.assertEquals(2, insertedEntries.size());
    }
    
    static testMethod void testWritePlatformEvents() {
        List<SamsaraLogEntries__c> testLogs = new List<SamsaraLogEntries__c>{
            new SamsaraLogEntries__c(Message__c = 'Test Log 1'),
            new SamsaraLogEntries__c(Message__c = 'Test Log 2')
        };
        
        String organizationLimits = JSON.serialize(LoggerUtils.loadOrganizationLimits());
        String transactionLimits = JSON.serialize(LoggerUtils.loadTransactionLimits());
        Long startTimeMillis = System.currentTimeMillis();
        Id recordId = UserInfo.getUserId();
        Set<Id> recordIds = new Set<Id>{UserInfo.getUserId()};
        String primaryObjectName = 'Lead';
        String functionalityType = 'Test';
        String functionalitySubType = 'PlatformEvent';
        String userTransactionId = 'test-transaction-id';
        
        Map<String, Object> eventPayload = new Map<String, Object>{
            'logs' => testLogs,
            'organizationLimits' => organizationLimits,
            'transactionLimits' => transactionLimits,
            'startTimeMillis' => startTimeMillis,
            'recordId' => recordId,
            'recordIds' => new List<Id>(recordIds),
            'primaryObjectName' => primaryObjectName,
            'functionalityType' => functionalityType,
            'functionalitySubType' => functionalitySubType,
            'userTransactionId' => userTransactionId
        };
        
        List<Log_Message__e> events = new List<Log_Message__e>{
            new Log_Message__e(Serialized_Logs__c = JSON.serialize(eventPayload))
        };
        
        Test.startTest();
        EventBus.publish(events);
        Test.getEventBus().deliver();
        Test.stopTest();
        
        List<SamsaraLogEntries__c> insertedEntries = [SELECT Id FROM SamsaraLogEntries__c];
        System.assertEquals(2, insertedEntries.size());
    }
    
    static testMethod void testPublish() {
        List<SamsaraLogEntries__c> entries = createTestLogEntries(2);
        Long startTimeMillis = System.currentTimeMillis();
        Id recordId = UserInfo.getUserId();
        String userTransactionId = 'test-transaction-id';
        
        Test.startTest();
        Boolean result = LoggerUtils.createLogRecords(entries, startTimeMillis, recordId, null, null, null, null, userTransactionId);
        Test.stopTest();
        
        System.assertEquals(true, result);
        List<SamsaraLogEntries__c> publishedEntries = [SELECT Id FROM SamsaraLogEntries__c];
        System.assertEquals(2, publishedEntries.size());
    }
    
    static testMethod void testPublishEmptyList() {
        String userTransactionId = 'test-transaction-id';
        Test.startTest();
        Boolean result = LoggerUtils.createLogRecords(new List<SamsaraLogEntries__c>(), System.currentTimeMillis(), null, null, null, null, null, userTransactionId);
        Test.stopTest();
        
        System.assertEquals(false, result);
    }

    public class TestQueueable implements Queueable {
        private List<SamsaraLogEntries__c> logs;
        private String componentName;
        private Long startTimeMillis;
        private String userTransactionId;
        
        public TestQueueable(List<SamsaraLogEntries__c> logs, String componentName) {
            this.logs = logs;
            this.componentName = componentName;
            this.startTimeMillis = System.currentTimeMillis();
            this.userTransactionId = 'test-transaction-id';
        }
        
        public void execute(QueueableContext qc) {
            LoggerUtils.createLogRecords(logs, startTimeMillis, null, null, null, null, null, userTransactionId);
        }
    }

    static testMethod void testPublish_AsyncContext_PlatformEvent() {
        List<SamsaraLogEntries__c> logs = createTestLogEntries(1);

        Test.startTest();
        System.enqueueJob(new TestQueueable(logs, 'AsyncComponentTest'));
        Test.stopTest();

        List<SamsaraLogEntries__c> insertedEntries = [SELECT Id FROM SamsaraLogEntries__c];
        System.assertEquals(1, insertedEntries.size());
    }

    static testMethod void testPublish_NonAsyncContext_Future() {
        List<SamsaraLogEntries__c> logs = createTestLogEntries(2);
        Long startTimeMillis = System.currentTimeMillis();
        String userTransactionId = 'test-transaction-id';

        Test.startTest();
        Boolean published = LoggerUtils.createLogRecords(logs, startTimeMillis, null, null, null, null, null, userTransactionId);
        Test.stopTest();

        System.assert(published);
        List<SamsaraLogEntries__c> insertedEntries = [SELECT Id FROM SamsaraLogEntries__c];
        System.assertEquals(2, insertedEntries.size());
    }

    static testMethod void testIsFutureEnabled_Default() {
        Boolean result = LoggerUtils.isFutureEnabledInMetadata(null);
        System.assertEquals(true, result, 'isFutureEnabled should return true unless a config disables it');
    }
 
    static testMethod void testIsPlatformEventEnabled_Default() {
        Boolean result = LoggerUtils.isPlatformEventEnabledInMetadata(null);
        System.assertEquals(true, result, 'isPlatformEventEnabled should return true unless a config disables it');
    }

    static testMethod void testIsSynchronousEnabled_Default() {
        Boolean result = LoggerUtils.isSynchronousEnabledInMetadata(null);
        System.assertEquals(true, result, 'isSynchronousEnabled should return true unless a config disables it');
    }

    static testMethod void testTransactionIdGeneration() {
        Test.startTest();
        String randomId = TransactionId.generateRandomId();
        String getMethodId = TransactionId.get();
        String getMethodId2 = TransactionId.get();
        Test.stopTest();

        System.assertNotEquals(null, randomId, 'Random ID should not be null');
        System.assertNotEquals(null, getMethodId, 'Get method ID should not be null');
        System.assertEquals(getMethodId, getMethodId2, 'Subsequent get() calls should return the same ID');
    }
}
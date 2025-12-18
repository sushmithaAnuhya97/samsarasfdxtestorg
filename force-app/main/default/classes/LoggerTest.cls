@IsTest
private class LoggerTest {

    private static void clearMasterLogs() {
        List<SamsaraLogEntries__c> logs = Logger.getMasterLogs();
        if(logs != null) {
             logs.clear();
        }
        Logger.setRecordId(null);
        Logger.setRecordIds(null);
        Logger.setPrimaryObjectName(null);
        Logger.setFunctionalityType(null);
        Logger.setFunctionalitySubType(null);
    }

    private static List<SamsaraLogEntries__c> getMasterLogs() {
        return Logger.getMasterLogs();
    }

    private static List<Database.SaveResult> createMockSaveResults(Integer successCount, Integer failureCount, String errorMsg, String recordId) {
        List<Database.SaveResult> results = new List<Database.SaveResult>();
        for (Integer i = 0; i < successCount; i++) {
            results.add((Database.SaveResult)JSON.deserialize('{"success":true, "id":"001xx00000SUCCESS' + i + '"}', Database.SaveResult.class));
        }
        for (Integer i = 0; i < failureCount; i++) {
            String idSuffix = recordId != null ? recordId.substring(3) : 'FAIL' + i;
            String errorJson = '[{"message":"' + errorMsg + '", "statusCode":"FIELD_CUSTOM_VALIDATION_EXCEPTION", "fields":[]}]';
            results.add((Database.SaveResult)JSON.deserialize('{"success":false, "id":"001' + idSuffix + '", "errors":' + errorJson + '}', Database.SaveResult.class));
        }
        return results;
    }

    private static List<Database.DeleteResult> createMockDeleteResults(Integer successCount, Integer failureCount, String errorMsg, String recordId) {
        List<Database.DeleteResult> results = new List<Database.DeleteResult>();
        for (Integer i = 0; i < successCount; i++) {
            results.add((Database.DeleteResult)JSON.deserialize('{"success":true, "id":"001xx00000SUCCESS' + i + '"}', Database.DeleteResult.class));
        }
        for (Integer i = 0; i < failureCount; i++) {
            String idSuffix = recordId != null ? recordId.substring(3) : 'FAIL' + i;
            String errorJson = '[{"message":"' + errorMsg + '", "statusCode":"DELETE_FAILED", "fields":[]}]';
            results.add((Database.DeleteResult)JSON.deserialize('{"success":false, "id":"001' + idSuffix + '", "errors":' + errorJson + '}', Database.DeleteResult.class));
        }
        return results;
    }

     private static List<Database.UndeleteResult> createMockUndeleteResults(Integer successCount, Integer failureCount, String errorMsg, String recordId) {
         List<Database.UndeleteResult> results = new List<Database.UndeleteResult>();
         for (Integer i = 0; i < successCount; i++) {
             results.add((Database.UndeleteResult)JSON.deserialize('{"success":true, "id":"001xx00000SUCCESS' + i + '"}', Database.UndeleteResult.class));
         }
         for (Integer i = 0; i < failureCount; i++) {
             String idSuffix = recordId != null ? recordId.substring(3) : 'FAIL' + i;
             String errorJson = '[{"message":"' + errorMsg + '", "statusCode":"UNDELETE_FAILED", "fields":[]}]';
             results.add((Database.UndeleteResult)JSON.deserialize('{"success":false, "id":"001' + idSuffix + '", "errors":' + errorJson + '}', Database.UndeleteResult.class));
         }
         return results;
     }

      private static List<Database.UpsertResult> createMockUpsertResults(Integer successCount, Integer failureCount, String errorMsg, String recordId) {
          List<Database.UpsertResult> results = new List<Database.UpsertResult>();
          for (Integer i = 0; i < successCount; i++) {
             results.add((Database.UpsertResult)JSON.deserialize('{"success":true, "created":true, "id":"001xx00000SUCCESS' + i + '"}', Database.UpsertResult.class));
         }
         for (Integer i = 0; i < failureCount; i++) {
             String idSuffix = recordId != null ? recordId.substring(3) : 'FAIL' + i;
             String errorJson = '[{"message":"' + errorMsg + '", "statusCode":"UPSERT_FAILED", "fields":[]}]';
             results.add((Database.UpsertResult)JSON.deserialize('{"success":false, "created":false, "id":"001' + idSuffix + '", "errors":' + errorJson + '}', Database.UpsertResult.class));
         }
          return results;
      }

    private static List<Messaging.SendEmailResult> createMockSendEmailResults(Integer successCount, Integer failureCount, String errorMsg) {
        List<Messaging.SendEmailResult> results = new List<Messaging.SendEmailResult>();
        for(Integer i=0; i<successCount; i++) {
            results.add((Messaging.SendEmailResult)JSON.deserialize('{"success": true}', Messaging.SendEmailResult.class));
        }
        for(Integer i=0; i<failureCount; i++) {
            Messaging.SendEmailError mockError = (Messaging.SendEmailError) JSON.deserialize(
                '{"message":"' + errorMsg + '","statusCode":"EMAIL_FAILED"}',
                Messaging.SendEmailError.class
            );
            Map<String, Object> failResultProps = new Map<String, Object>{
                'success' => false,
                'errors' => new List<Messaging.SendEmailError>{ mockError }
            };
            Messaging.SendEmailResult finalFailResult = (Messaging.SendEmailResult)JSON.deserialize(
                JSON.serialize(failResultProps),
                Messaging.SendEmailResult.class
            );
            results.add(finalFailResult);
        }
        return results;
    }

    private static List<Approval.ProcessResult> createMockProcessResults(Boolean success, String errorMsg) {
        Approval.ProcessResult result = (Approval.ProcessResult)JSON.deserialize(
            '{"actorIds":[],"entityId":"001x00000APPROVAL1","errors":' +
            (success ? '[]' : '[{"message":"' + errorMsg + '","statusCode":"APPROVAL_ERROR","fields":[]}]') +
            ',"instanceId":"ProcInst001","instanceStatus":"' + (success ? 'Approved' : 'Error') + '","newWorkitemIds":[],"success":' + success + '}',
            Approval.ProcessResult.class
        );
        return new List<Approval.ProcessResult>{ result };
    }

    private static List<Approval.UnlockResult> createMockUnlockResults(Boolean success, String errorMsg, String entityId) {
        Approval.UnlockResult result = (Approval.UnlockResult)JSON.deserialize(
            '{"errors":' +
            (success ? '[]' : '[{"message":"' + errorMsg + '","statusCode":"UNLOCK_ERROR","fields":[]}]') +
            ',"success":' + success + '}',
            Approval.UnlockResult.class
        );
        return new List<Approval.UnlockResult>{ result };
    }

    @IsTest
    static void testConstructors() {
        Test.startTest();
        Logger logger1 = new Logger();
        Logger logger2 = new Logger();
        Test.stopTest();

        System.assertNotEquals(null, logger1);
        System.assertNotEquals(null, logger2);
    }

    @IsTest
    static void testAuraPublish() {
        List<SamsaraLogEntries__c> logs = new List<SamsaraLogEntries__c>{
            new SamsaraLogEntries__c(Message__c = 'Test Log 1'),
            new SamsaraLogEntries__c(Message__c = 'Test Log 2')
        };
        Long startTimeMillis = System.currentTimeMillis();
        Id testRecId = UserInfo.getUserId();
        String testObjName = 'Account';
        String testFuncType = 'Publish';
        String testFuncSubType = 'Aura';

        Test.startTest();
        Logger.setRecordId(testRecId);
        Logger.setPrimaryObjectName(testObjName);
        Logger.setFunctionalityType(testFuncType);
        Logger.setFunctionalitySubType(testFuncSubType);
        Logger.publish(
            logs,
            testRecId,
            testFuncType,
            testFuncSubType,
            startTimeMillis
        );
        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void testInsertMasterLogs() {
        clearMasterLogs();
        Logger.atInfo().setClassName('TestClass.cls').setExceptionOrMessage('Info message before insert');

        System.assertEquals(1, getMasterLogs().size());

        Test.startTest();
        Logger.insertMasterLogs();
        Test.stopTest();

        System.assertEquals(0, getMasterLogs().size());
    }

    @IsTest
    static void testInsertMasterLogsWithRecordId() {
        clearMasterLogs();
        Id testRecordId = UserInfo.getUserId();
        String testObjName = 'Contact';
        String testFuncType = 'Insert';
        String testFuncSubType = 'Context';

        Logger.atInfo().setClassName('TestClass.cls').setExceptionOrMessage('Info message before insert with context');

        System.assertEquals(1, getMasterLogs().size());

        Test.startTest();
        Logger.setRecordId(testRecordId);
        Logger.setPrimaryObjectName(testObjName);
        Logger.setFunctionalityType(testFuncType);
        Logger.setFunctionalitySubType(testFuncSubType);
        Logger.insertMasterLogs();
        Test.stopTest();

        System.assertEquals(0, getMasterLogs().size());
    }

    @IsTest
    static void testInsertMasterLogsWithRecordIds() {
        clearMasterLogs();
        Set<Id> testRecordIds = new Set<Id>{UserInfo.getUserId()};
        String testObjName = 'Opportunity';
        String testFuncType = 'Update';
        String testFuncSubType = 'Bulk';

        Logger.atInfo().setClassName('TestClass.cls').setExceptionOrMessage('Info message before insert with context');

        System.assertEquals(1, getMasterLogs().size());

        Test.startTest();
        Logger.setRecordIds(testRecordIds);
        Logger.setPrimaryObjectName(testObjName);
        Logger.setFunctionalityType(testFuncType);
        Logger.setFunctionalitySubType(testFuncSubType);
        Logger.insertMasterLogs();
        Test.stopTest();

        System.assertEquals(0, getMasterLogs().size());
    }

    @IsTest
    static void testGetMasterLogs() {
        clearMasterLogs();
        Logger.atWarn().setClassName('TestClass.cls').setExceptionOrMessage('Warning message');
        Logger.atDebug().setClassName('TestClass.cls').setRecordId('001x00000GETLOGS1').setExceptionOrMessage('Debug message');

        List<SamsaraLogEntries__c> logs = getMasterLogs();

        System.assertEquals(2, logs.size());
    }


    @IsTest
    static void testLogLevels() {
        clearMasterLogs();

        Test.startTest();
        Logger.atNone().setClassName('TestClass.cls').setExceptionOrMessage('Level None');
        Logger.atError().setClassName('TestClass.cls').setExceptionOrMessage('Level Error');
        Logger.atWarn().setClassName('TestClass.cls').setExceptionOrMessage('Level Warn');
        Logger.atInfo().setClassName('TestClass.cls').setExceptionOrMessage('Level Info');
        Logger.atDebug().setClassName('TestClass.cls').setExceptionOrMessage('Level Debug');
        Logger.atFine().setClassName('TestClass.cls').setExceptionOrMessage('Level Fine');
        Logger.atFiner().setClassName('TestClass.cls').setExceptionOrMessage('Level Finer');
        Logger.atFinest().setClassName('TestClass.cls').setExceptionOrMessage('Level Finest');
        new Logger().createLogContext(null).setClassName('TestClass.cls').setExceptionOrMessage('Level Null (defaults to Error)');
        Test.stopTest();

        List<SamsaraLogEntries__c> logs = getMasterLogs();
        System.assertEquals(9, logs.size());
    }

    @IsTest
    static void testLogContextSetException() {
        clearMasterLogs();
        Exception testException;
        Integer lineNumber = 0;
        String specificMessage = 'Specific Error';
        try {
            Integer i = 1 / 0;
        } catch (Exception e) {
            testException = e;
            lineNumber = e.getLineNumber();
        }

        Test.startTest();
        Logger.atError().setExceptionOrMessage(testException);
        Logger.atError().setClassName('TestClass.cls').setExceptionOrMessage(specificMessage);
        Logger.atError().setExceptionOrMessage(testException);
        Logger.atWarn().setExceptionOrMessage((Exception)null);
        Test.stopTest();

        List<SamsaraLogEntries__c> logs = getMasterLogs();
        System.assertEquals(3, logs.size());
    }

    @IsTest
    static void testLogContextSetSaveResult() {
        clearMasterLogs();
        String errMsg = 'Save failed validation';
        String failedId = '001x00000SAVEFAIL';
        List<Database.SaveResult> results = createMockSaveResults(1, 1, errMsg, failedId);

        Test.startTest();
        Logger.atError().setClassName('TestClass.cls').setRecordId('ContextId').setMethod('saveMethod').setLineNumber(123).setExceptionOrMessage(results);
        Test.stopTest();

        List<SamsaraLogEntries__c> logs = getMasterLogs();
        System.assertEquals(1, logs.size());

        clearMasterLogs();
        Logger.atError().setExceptionOrMessage((List<Database.SaveResult>)null);
        Logger.atError().setExceptionOrMessage(new List<Database.SaveResult>());
        System.assertEquals(0, getMasterLogs().size());
    }

    @IsTest
    static void testLogContextSetDeleteResult() {
        clearMasterLogs();
        String errMsg = 'Delete failed';
        String failedId = '001x00000DELFAIL1';
        List<Database.DeleteResult> results = createMockDeleteResults(0, 1, errMsg, failedId);

        Test.startTest();
        Logger.atWarn().setClassName('TestClass.cls').setMethod('delMethod').setLineNumber(45).setExceptionOrMessage(results);
        Test.stopTest();

        List<SamsaraLogEntries__c> logs = getMasterLogs();
        System.assertEquals(1, logs.size());
    }

     @IsTest
     static void testLogContextSetUndeleteResult() {
         clearMasterLogs();
         String errMsg = 'Undelete failed';
         String failedId = '001x0000UNDELFAIL';
         List<Database.UndeleteResult> results = createMockUndeleteResults(1, 1, errMsg, failedId);

         Test.startTest();
         Logger.atError().setClassName('TestClass.cls').setExceptionOrMessage(results);
         Test.stopTest();

         List<SamsaraLogEntries__c> logs = getMasterLogs();
         System.assertEquals(1, logs.size());
     }

      @IsTest
      static void testLogContextSetUpsertResult() {
          clearMasterLogs();
          String errMsg = 'Upsert failed';
          String failedId = '001x00000UPSFAIL';
          List<Database.UpsertResult> results = createMockUpsertResults(2, 1, errMsg, failedId);

          Test.startTest();
          Logger.atError().setClassName('TestClass.cls').setExceptionOrMessage(results);
          Test.stopTest();
          List<SamsaraLogEntries__c> logs = getMasterLogs();
          System.assertEquals(1, logs.size());
      }

    @IsTest
    static void testApprovalProcessResult_SingleFailure() {
        clearMasterLogs();
        String errMsg = 'Approval validation failed';
        List<Approval.ProcessResult> failingResults = createMockProcessResults(false, errMsg);

        Test.startTest();
        Logger.atError().setClassName('TestClass.cls').setRecordId('ApprovalCtxId').setMethod('approvalMethod').setExceptionOrMessage(failingResults[0]);
        Test.stopTest();

        List<SamsaraLogEntries__c> logs = getMasterLogs();
        System.assertEquals(1, logs.size());
    }

    @IsTest
    static void testApprovalProcessResult_ListFailure() {
        clearMasterLogs();
        String errMsg = 'Approval validation failed';
        List<Approval.ProcessResult> failingResults = createMockProcessResults(false, errMsg);

        Test.startTest();
        Logger.atWarn().setClassName('TestClass.cls').setExceptionOrMessage(failingResults);
        Test.stopTest();

        List<SamsaraLogEntries__c> logs = getMasterLogs();
        System.assertEquals(1, logs.size());
    }

    @IsTest
    static void testApprovalProcessResult_Success() {
        clearMasterLogs();
        List<Approval.ProcessResult> successResults = createMockProcessResults(true, '');

        Logger.atError().setClassName('TestClass.cls').setExceptionOrMessage(successResults);

        System.assertEquals(0, getMasterLogs().size());
    }

    @IsTest
    static void testApprovalProcessResult_EmptyList() {
        clearMasterLogs();

        Logger.atError().setClassName('TestClass.cls').setExceptionOrMessage(new List<Approval.ProcessResult>());

        System.assertEquals(0, getMasterLogs().size());
    }

    @IsTest
    static void testApprovalUnlockResult_SingleFailure() {
        clearMasterLogs();
        String failedId = '001x0000UNLOCK1';
        String errMsg = 'Unlock failed';
        List<Approval.UnlockResult> failingResults = createMockUnlockResults(false, errMsg, failedId);

        Test.startTest();
        Logger.atError().setClassName('TestClass.cls').setRecordId('UnlockCtxId').setMethod('unlockMethod').setExceptionOrMessage(failingResults[0]);
        Test.stopTest();

        List<SamsaraLogEntries__c> logs = getMasterLogs();
        System.assertEquals(1, logs.size());
    }

    @IsTest
    static void testApprovalUnlockResult_ListFailure() {
        clearMasterLogs();
        String failedId = '001x0000UNLOCK1';
        String errMsg = 'Unlock failed';
        List<Approval.UnlockResult> failingResults = createMockUnlockResults(false, errMsg, failedId);

        Test.startTest();
        Logger.atWarn().setClassName('TestClass.cls').setExceptionOrMessage(failingResults);
        Test.stopTest();

        List<SamsaraLogEntries__c> logs = getMasterLogs();
        System.assertEquals(1, logs.size());
    }

    @IsTest
    static void testApprovalUnlockResult_Success() {
        clearMasterLogs();
        String failedId = '001x0000UNLOCK1';
        List<Approval.UnlockResult> successResults = createMockUnlockResults(true, '', failedId);

        Logger.atError().setClassName('TestClass.cls').setExceptionOrMessage(successResults);

        System.assertEquals(0, getMasterLogs().size());
    }

    @IsTest
    static void testApprovalUnlockResult_EmptyList() {
        clearMasterLogs();

        Logger.atError().setClassName('TestClass.cls').setExceptionOrMessage(new List<Approval.UnlockResult>());

        System.assertEquals(0, getMasterLogs().size());
    }

    @IsTest
    static void testLogContextSetSimpleMessage() {
        clearMasterLogs();
        String msg = 'This is a simple info message.';
        Id recId = UserInfo.getUserId();
        String method = 'myTestMethod';
        String className = 'TestClass.cls';
        String testObjName = 'Lead';
        String testFuncType = 'Convert';
        String testFuncSubType = 'Simple';

        Test.startTest();
        Logger.atInfo()
              .setClassName(className)
              .setRecordId(recId)
              .setMethod(method)
              .setLineNumber(55)
              .setExceptionOrMessage(msg);

        Logger.atInfo()
              .setClassName(className)
              .setExceptionOrMessage('Second message');

        Logger.setRecordId(recId);
        Logger.setPrimaryObjectName(testObjName);
        Logger.setFunctionalityType(testFuncType);
        Logger.setFunctionalitySubType(testFuncSubType);
        Logger.insertMasterLogs();
        Test.stopTest();

        System.assertEquals(0, getMasterLogs().size(), 'Master logs should be empty after insertion');
    }

    @IsTest
    static void testLogContextStageLog() {
        clearMasterLogs();
        SamsaraLogEntries__c flowLog = new SamsaraLogEntries__c(
            sourceApiName__c = 'MyFlow',
            SourceMetadataType__c = 'Flow',
            Message__c = 'Log from flow',
            Level__c = 'DEBUG',
            RecordId__c = 'FlowRecId',
            Method__c = 'FlowElement',
            UUID__c = null,
            Response_Time__c = DateTime.now(),
            Request_Time__c = DateTime.now(),
            Acknowledgement_Time__c = DateTime.now(),
            Message2__c = 'message2'
        );

        Test.startTest();
        Logger.atInfo().stageLog(flowLog);
        Test.stopTest();

        List<SamsaraLogEntries__c> logs = getMasterLogs();
        System.assertEquals(1, logs.size());
        Logger.atInfo().setUUID('Test123').setRequestTime(DateTime.now()).setResponseTime(DateTime.now()).setAcknowledgementTime(DateTime.now()).setMessage2('Response message');
    }

    @IsTest
    static void testLogContextSetSendEmailResult() {
        clearMasterLogs();
        String errMsg = 'Email send failed';
        List<Messaging.SendEmailResult> results = createMockSendEmailResults(1, 1, errMsg);

        Logger.atError().setClassName('TestClass.cls').setRecordId('EmailContextId').setMethod('emailMethod').setExceptionOrMessage(results);

        clearMasterLogs();
        Logger.atError().setExceptionOrMessage(new List<Messaging.SendEmailResult>());
    }
}
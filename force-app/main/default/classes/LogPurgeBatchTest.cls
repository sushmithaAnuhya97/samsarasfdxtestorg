@isTest
private class LogPurgeBatchTest {
    
    @isTest
    static void testBatchExecution() {
        Integer retentionDays = Integer.valueOf(System.Label.Log_Retention_Days);
        DateTime now = System.now();
        DateTime cutoffDateTime = now.addDays(-retentionDays);
        
        List<SamsaraLog__c> logs = new List<SamsaraLog__c>();
        
        SamsaraLog__c oldLog = new SamsaraLog__c();
        logs.add(oldLog);
        
        SamsaraLog__c newLog = new SamsaraLog__c();
        logs.add(newLog);
        
        insert logs;
        
        Test.setCreatedDate(oldLog.Id, now.addDays(-retentionDays - 1));
        Test.setCreatedDate(newLog.Id, now.addDays(-retentionDays + 1));
   
        Test.startTest();
        LogPurgeBatch batch = new LogPurgeBatch();
        Database.executeBatch(batch);
        Test.stopTest();
    }
    
    @isTest
    static void testSchedulableExecution() {
        Test.startTest();
        LogPurgeBatch batch = new LogPurgeBatch();
        String jobId = System.schedule('Test Log Purge', '0 0 0 * * ?', batch);
        Test.stopTest();
        
        List<CronTrigger> jobs = [SELECT Id FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(1, jobs.size(), 'Should have one scheduled job');
    }
}
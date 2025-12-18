/**
 * Created by vikasmishra on 2021-05-06.
 */

@IsTest
private class Samsara_ClearLogs_Test {

    @IsTest
    static void ShouldDeletionFromLogs() {

        Log__c thisLog = new Log__c();
        thisLog.ClassName__c = 'test';
        thisLog.Method__c = 'method';
        insert thisLog;
        Samsara_ClearLogs thisBatch = new Samsara_ClearLogs();
        thisBatch.query = 'SELECT Id FROM Log__c';
        thisBatch.DAYS_TO_DELETE = 1;
        Test.startTest();
        Database.executeBatch(thisBatch);
        Test.stopTest();
        System.assert([SELECT Id FROM Log__c].size() == 0, 'Should Delete Sobject');

    }

    @IsTest
    static void ShouldDeletionFromLogsWithScheduler() {
        Samsara_ClearLogs thisBatch = new Samsara_ClearLogs();
        thisBatch.query = 'SELECT Id FROM Account';
        thisBatch.DAYS_TO_DELETE = 1;
        String sch='0 5 2 * * ?';
        Test.startTest();
        System.schedule('Clear BMRN logs', sch , thisBatch);
        Test.stopTest();
        System.assert(
                [
                        SELECT ApexClassId, Id, JobItemsProcessed, JobType,
                        Status, NumberOfErrors, MethodName
                        FROM AsyncApexJob
                        WHERE JobType= 'ScheduledApex'
                ].size()>0,
                'Should Schedule one job'
        );

    }
}
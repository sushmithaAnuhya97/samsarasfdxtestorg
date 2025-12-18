@isTest
public class ADRTransferDemoScheduledBatchTest {
    static ADR_Transfer_Log__c createADRTransferLog() {
        
        
    	ADR_Transfer_Log__c ADRLog = new ADR_Transfer_Log__c();
        ADRLog.ADR_Transfer_Status__c = 'Demo Scheduled';
        ADRLog.ADR_Demo_Date__c = System.Today().addDays(-2);
        return ADRLog;
    }
    
    @isTest
    static void testDemoScheduled() {
        Test.startTest();
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User();
        u.Alias = 'test';
        u.Email = 'test@myorg.com'; 
        u.EmailEncodingKey = 'UTF-8';
        u.LastName = 'Testing';
        u.LanguageLocaleKey = 'en_US'; 
        u.LocaleSidKey = 'en_US';
        u.ProfileId = p.Id;
        u.TimeZoneSidKey = 'America/New_York';
        u.UserName = 'testsamsara@myorg.com';
        u.EmployeeNumber = '123';
      	insert u;
        
        ADR_Transfer_Log__c ADRLog =  createADRTransferLog();
        ADRLog.AE_Demo_Transfer_To__c = u.Id;
        insert ADRLog;
        Database.executeBatch(new ADRTransferDemoScheduledBatch(), 1);
        
        ADRTransferDemoScheduled sc = new ADRTransferDemoScheduled();   
        String chron = '0 0 23 * * ?';        
        system.schedule('Test Sched', chron, sc);
        Test.stopTest();
    }
}
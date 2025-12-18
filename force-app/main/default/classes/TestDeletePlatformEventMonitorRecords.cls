@isTest
private class TestDeletePlatformEventMonitorRecords {
    
    @testSetup
    private static void setupEventsData(){
        List<Platform_Events_Monitor__c> lst = new List<Platform_Events_Monitor__c>();
        for(Integer index=0;index<5;index++){
            Platform_Events_Monitor__c p = new Platform_Events_Monitor__c();
            p.New_Value__c='Test'+index;
            p.Old_Value__c='Testing'+index;
            p.RecordId__c='123456789'+index;
            p.Object_Name__c='Account';
            lst.add(p);
        }
        insert lst;
    }
    
    @isTest
    private static void testRunsScheduled() {
        String query = 'Select id,createddate,Object_Name__c from Platform_Events_Monitor__c where createddate<=LAST_N_DAYS:1'; 
        String hour = String.valueOf(Datetime.now().hour());
        String min = String.valueOf(Datetime.now().minute()); 
        String ss = String.valueOf(Datetime.now().second());
        
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
        
        Test.startTest();
        DeletePlatformEventMonitorRecords s = new DeletePlatformEventMonitorRecords(query); 
        Id jobId = System.schedule('Job Started At ' + String.valueOf(Datetime.now()), nextFireTime, s);
        
        CronTrigger cronTrigger = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];
        
        System.assertEquals(nextFireTime, cronTrigger.CronExpression);
        System.assertEquals(0, cronTrigger.TimesTriggered);
        
        Test.stopTest(); 
    }
}
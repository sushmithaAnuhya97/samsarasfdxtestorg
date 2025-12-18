@isTest
public class ScheduledAccountAutomationTest {
    
    @testSetup
    private static void testDataSetup() {
        
        List<Task> tasks = new List<Task>();

		Account a = (Account) TestFactory.createSOBject(new Account(Name = 'Test Account'));
		insert a;
		// Insert contacts with different sources
		Contact c = (Contact) TestFactory.createSOBject(new Contact(Email = 'testymctesterson@email.com', AccountId = a.Id));
		insert c;
		Task taskOne = new Task(WhatId = a.Id, Subject = 'Call', ActivityDate = Date.Today(), CallDurationInSeconds = 100);
		tasks.add(taskOne);
		Task taskTwo = new Task(WhatId = a.Id, Subject = 'Email', ActivityDate = Date.Today(), CallDurationInSeconds = 120);
		tasks.add(taskTwo);

		insert tasks;
    }
    
    @isTest
    static void testScheduledJob(){
        String CRON_EXP = '0 0 0 3 9 ? 2025';
        String jobId = System.schedule('ScheduledAccountAutomation', CRON_EXP, new ScheduledAccountAutomation());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals('2025-09-03 00:00:00', String.valueOf(ct.NextFireTime)); 
    }
    
    @isTest
    static void testAccountAutomation(){
		test.startTest();
        String query = 'SELECT AccountId, Account.Last_Meaningful_Engagement_Date__c, CreatedDate FROM Task WHERE (CallDurationInSeconds > 90) AND AccountId != null AND CreatedDate = N_DAYS_AGO:0';
        Database.executeBatch(new AccountAutomation(query, true, null));
        test.stopTest();
    }

}
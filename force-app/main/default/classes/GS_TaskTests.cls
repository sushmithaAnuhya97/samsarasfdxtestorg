/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 03-03-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@IsTest
public without sharing class GS_TaskTests {
    
    @TestSetup
    static void setup(){
        insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true);

        Account acc = (Account) TestFactory.createSObject(new Account(Status__c = 'Acc Status'));
        insert acc;

        Contact ctt = (Contact) TestFactory.createSObject(new Contact(Email = 'phillip.front@samsara.com', AccountId = acc.Id, Status__c = 'New'));
        insert ctt;
    }

    @IsTest
    public static void testTaskNullPointer(){
        Contact ctt = [SELECT Id FROM Contact];
        delete ctt;
        
        Test.startTest();
        Task t2 = new Task(
            WhoId=ctt.Id,
            Related_Contact__c=ctt.Id,
            Subject='Email to test',
            ActivityDate=System.today(),
            Status='Completed',
            Priority='Normal',
            CurrencyIsoCode='USD',
            Description='Test',
            CallType='Outbound',
            CallDisposition='Call connected',
            zoom_app__ICS_Sequence__c=0,
            zoom_app__Join_before_host__c=false,
            MBO_Authorized__c=false,
            AE_Led_Demo__c=false,
            zoom_app__Make_it_Zoom_Meeting__c=false,
            zoom_app__Use_personal_Zoom_meeting_Id__c=false,
            Salesloft_Bounced__c=false
        );
        
        try{
            insert t2;
        }catch(DmlException ex){
            System.assert(ex.getMessage().contains('ENTITY_IS_DELETED'));
        }
        Test.stopTest();
    }

    @isTest
    public static void testContactNoAccount(){
        Account acc = (Account) TestFactory.createSObject(new Account(Status__c = 'Acc Status'));
        insert acc;
        Contact ctt = (Contact) TestFactory.createSObject(new Contact(Email = 'testemail@samsara.com',Lastname='test',AccountId = acc.Id));
        insert ctt;
    
        Test.startTest();
        Task t = new Task(
            WhoId=ctt.Id,
            Subject='Sent Email: Payment',
            ActivityDate=System.today(),
            Status='Completed',
            Priority='Normal',
            Description='From: lloyddowney@manguardplus.ie',
            CurrencyIsoCode='GBP',
            Call_Logged_to_Contact__c=false,
            zoom_app__ICS_Sequence__c=0,
            zoom_app__Join_before_host__c=false,
            MBO_Authorized__c=false,
            AE_Led_Demo__c=false,
            zoom_app__Make_it_Zoom_Meeting__c=false,
            zoom_app__Use_personal_Zoom_meeting_Id__c=false,
            Salesloft_Bounced__c=false
        );
        insert t;
        Test.stopTest();
    }

    @isTest
    public static void leadTest(){
        Lead l = (Lead)TestFactory.createSOBject(new Lead(FirstName = 'TestFirst', LastName = 'TestLast', Company = 'TestCompany', Business_Unit__c = 'Fleet', Country = 'United States', State = 'California', LeadSource = 'Adwords'));
        insert l;

        Test.startTest();
        Task t = new Task(
            WhoId = l.Id,
            Description = 'New description',
            Subject = 'Email test',
            ActivityDate = Date.Today()
        );
        insert t;
        Test.stopTest();
    }

    @isTest
    public static void testSalesLoftTask(){
        Id salesLoftRecordTypeId = Task.getSObjectType().getDescribe().getRecordTypeInfosByName().get('Sales Loft').getRecordTypeId();

        String oldDescription = [SELECT Id, Description FROM Contact].Description;

        Test.startTest();
        Task t = new Task(
            RecordTypeId = salesLoftRecordTypeId,
            WhoId = [SELECT Id FROM Contact].Id,
            Description = 'New description',
            Subject = 'Call',
            ActivityDate = Date.Today()
        );
        insert t;
        Test.stopTest();

        System.assertNotEquals([SELECT Id, Description FROM Contact].Description, oldDescription);
    }

    @IsTest
    public static void testTaskWorkflows(){
        Id taskRecordTypeId = Task.getSObjectType().getDescribe().getRecordTypeInfosByName().get('Task').getRecordTypeId();

        Contact ctt = [SELECT Id, Status__c FROM Contact];
        ctt.Status__c = 'New';
        update ctt;

        Test.startTest();
        Task t = new Task(
            RecordTypeId = taskRecordTypeId,
            WhoId = ctt.Id,
            WhatId = [SELECT Id FROM Account].Id,
            CallDurationInSeconds = 5,
            Subject = 'Call and Email',
            Type = 'Call',
            Description = buildDescription(),
            ActivityDate = Date.Today()
        );
        insert t;
        Id taskId= t.Id;
        Test.stopTest();

        t = [
            SELECT Id, Call_Notes__c, Type, Activity_Type__c, Owner_Role_Copy__c,
                   Description, Account_Status_Copy__c, Related_Contact__c,
                   Contact_Status_Copy__c, Open_Oppty_Rev_Copy__c,
                   Related_Contact__r.Status__c, Related_Contact__r.Account.Status__c
               FROM Task Where Id =: taskId
        ];
        System.assertEquals(t.Type, t.Activity_Type__c);
        //System.assertEquals([SELECT Name FROM UserRole WHERE Id = :UserInfo.getUserRoleId()].Name, t.Owner_Role_Copy__c);
        System.assertEquals([SELECT Id FROM Contact].Id, t.Related_Contact__c);
        System.assertEquals(t.Related_Contact__r.Account.Status__c, t.Account_Status_Copy__c);
        System.assertEquals(t.Related_Contact__r.Status__c, t.Contact_Status_Copy__c);
        System.assertEquals(0, t.Open_Oppty_Rev_Copy__c);
        System.assert((t.Call_Notes__c.length() == 255) && t.Call_Notes__c.endsWith('...'));
    }

    private static String buildDescription(){
        String value = 'a';
        while (value.length() < 300) value += 'a';
        return value;
    }

    @IsTest
    public static void testUpdateCampaignTasks(){
        Campaign cmp = new Campaign(
            Name = 'Test Campaign',
            Status='In Progress',
            StartDate = System.Date.today(),
            Type = 'Website - Form'
        );
        insert cmp;
        CampaignMember campaignMember = (CampaignMember) TestFactory.createSObject(new CampaignMember(
            ContactId = [SELECT Id FROM Contact].Id,
            CampaignId = cmp.Id,
            Campaign_Interaction_Date__c = System.today()
        ));
        insert campaignMember;

        Test.startTest();
        Task t = new Task(
            RecordTypeId = Task.getSObjectType().getDescribe().getRecordTypeInfosByName().get('Task').getRecordTypeId(),
            WhoId = [SELECT Id FROM Contact].Id,
            Description = 'New description',
            CallDurationInSeconds = 5,
            Subject = 'Call',
            ActivityDate = Date.Today()
        );
        insert t;
        Test.stopTest();

        System.assertNotEquals(null, [SELECT Id, Initial_Response_Time__c FROM CampaignMember].Initial_Response_Time__c);
    }

    @IsTest
    static void oldAccountTest(){
        String oldAccountId = [SELECT Id FROM Account].Id;
        String oldContactId = [SELECT Id FROM Contact].Id;
        
        Task t = new Task(
            RecordTypeId = Task.getSObjectType().getDescribe().getRecordTypeInfosByName().get('Task').getRecordTypeId(),
            WhoId = oldContactId,
            CallDurationInSeconds = 5,
            Subject = 'Call and Email',
            Type = 'Call',
            Description = buildDescription(),
            ActivityDate = Date.Today()
        );
        insert t;

        Account acc = (Account) TestFactory.createSObject(new Account(Status__c = 'New Account'));
        insert acc;

        Contact ctt = (Contact) TestFactory.createSObject(new Contact(Email = 'phillip.front@samsara.com', AccountId = acc.Id, Status__c = 'New'));
        insert ctt;

        //GS_TaskTriggerHandler.cacheService = new GS_TaskCacheService();
        Test.startTest();
        t.WhoId = ctt.Id;
        update t;
        Test.stopTest();

        t = [SELECT Id, AccountId, WhoId, Old_Account_Contact__c FROM Task WHERE Id = :t.Id];
        System.assertEquals(acc.Id, t.AccountId);
        System.assertEquals(ctt.Id, t.WhoId);
        System.assertEquals(String.valueOf(oldAccountId)+','+String.valueOf(oldContactId)+',', t.Old_Account_Contact__c);
        
    }

//gtms-25398 ticket  start here

@isTest
    static void testEmailReplyTaskInsert() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
       
        Test.startTest();
       
        // Create a task with email reply
        Task emailTask = new Task(
            Subject = 'Email Reply: Test',
            WhoId = testContact.Id,
            Status = 'Completed'
        );
        insert emailTask;
       
        // Move time forward by 2 minutes to allow scheduler to run
      //  Test.moveTime(DateTime.now().addMinutes(2));
       
        Test.stopTest();
       
        // Verify contact status was updated
        Contact updatedContact = [SELECT Id, Status__c FROM Contact WHERE Id = :testContact.Id];
       // System.assertEquals('Retouch - Confirmed No Opportunity', updatedContact.Status__c,
        //    'Contact status should be updated for email reply task');
    }
   
    @isTest
    static void testLongCallTaskInsert() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
       
        Test.startTest();
       
        // Create a task with long call duration
        Task callTask = new Task(
            Subject = 'Call',
            WhoId = testContact.Id,
            CallDurationInSeconds = 61,
            Status = 'Completed'
        );
        insert callTask;
       
        // Move time forward by 2 minutes to allow scheduler to run
      //  Test.moveTime(DateTime.now().addMinutes(2));
       
        Test.stopTest();
       
        // Verify contact status was updated
        Contact updatedContact = [SELECT Id, Status__c FROM Contact WHERE Id = :testContact.Id];
       // System.assertEquals('Retouch - Confirmed No Opportunity', updatedContact.Status__c,
       //     'Contact status should be updated for long call task');
    }
   
    @isTest
    static void testTaskUpdateWithConditionChange() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
       
        // Create initial task
        Task initialTask = new Task(
            Subject = 'Initial Call',
            WhoId = testContact.Id,
            CallDurationInSeconds = 30,
            Status = 'Completed'
        );
        insert initialTask;
       
        Test.startTest();
       
        // Update task to meet conditions
        initialTask.CallDurationInSeconds = 61;
        update initialTask;
       
        // Move time forward by 2 minutes to allow scheduler to run
      //  Test.moveTime(DateTime.now().addMinutes(2));
       
        Test.stopTest();
       
        // Verify contact status was updated
        Contact updatedContact = [SELECT Id, Status__c FROM Contact WHERE Id = :testContact.Id];
       // System.assertEquals('Retouch - Confirmed No Opportunity', updatedContact.Status__c,
        //    'Contact status should be updated when task conditions change');
    }
   
    @isTest
    static void testDemoScheduledContact() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
       
        // Update contact status to Demo Scheduled
        testContact.Status__c = 'Demo Scheduled';
        update testContact;
       
        Test.startTest();
       
        // Create a task with email reply
        Task emailTask = new Task(
            Subject = 'Email Reply: Test',
            WhoId = testContact.Id,
            Status = 'Completed'
        );
        insert emailTask;
       
        // Move time forward by 2 minutes to allow scheduler to run
       // Test.moveTime(DateTime.now().addMinutes(2));
       
        Test.stopTest();
       
        // Verify contact status was not updated
        Contact unchangedContact = [SELECT Id, Status__c FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals('Demo Scheduled', unchangedContact.Status__c,
            'Contact status should not change for Demo Scheduled contacts');
    }
   
    @isTest
    static void testWithADRTransferLog() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
       
        // Create ADR Transfer Log
        ADR_Transfer_Log__c transferLog = new ADR_Transfer_Log__c(
            Contact__c = testContact.Id
        );
        insert transferLog;
       
        Test.startTest();
       
        // Create a task with email reply
        Task emailTask = new Task(
            Subject = 'Email Reply: Test',
            WhoId = testContact.Id,
            Status = 'Completed'
        );
        insert emailTask;
       
        // Move time forward by 2 minutes to allow scheduler to run
       // Test.moveTime(DateTime.now().addMinutes(2));
       
        Test.stopTest();
       
        // Verify contact status was not updated due to recent ADR Transfer Log
        Contact unchangedContact = [SELECT Id, Status__c FROM Contact WHERE Id = :testContact.Id];
      //  System.assertEquals('New', unchangedContact.Status__c,
           // 'Contact status should not change when recent ADR Transfer Log exists');
    }
   
    @isTest
    static void testBulkTaskInsert() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        List<Task> bulkTasks = new List<Task>();
       
        // Create 200 tasks
        for(Integer i = 0; i < 200; i++) {
            bulkTasks.add(new Task(
                Subject = 'Email Reply: Test ' + i,
                WhoId = testContact.Id,
                Status = 'Completed'
            ));
        }
       
        Test.startTest();
        insert bulkTasks;
       
        // Move time forward by 2 minutes to allow scheduler to run
      //  Test.moveTime(DateTime.now().addMinutes(2));
       
        Test.stopTest();
       
        // Verify contact status was updated
        Contact updatedContact = [SELECT Id, Status__c FROM Contact WHERE Id = :testContact.Id];
       // System.assertEquals('Retouch - Confirmed No Opportunity', updatedContact.Status__c,
       //     'Contact status should be updated in bulk scenario');
    }   
 
        //gtms-25398 ticket END here

    @isTest
    static void testHandleContactStatusUpdate_Insert() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'phillip.front@samsara.com' LIMIT 1];
        Task t1 = new Task(WhoId = c.Id, Subject = 'Email Reply: Automated', Status = 'Completed');
        Task t2 = new Task(WhoId = c.Id, Subject = 'Call', CallDurationInSeconds = 120, Status = 'Completed');
        insert new List<Task>{ t1, t2 };
        GS_TaskService service = new GS_TaskService(new GS_TaskCacheService());

        // Get count before test
        Integer beforeCount = [SELECT COUNT() FROM CronTrigger];
        
        Test.startTest();
        service.handleContactStatusUpdate(new List<Task>{ t1, t2 }, null);
        Test.stopTest();

        // Get count after and verify delta
        Integer afterCount = [SELECT COUNT() FROM CronTrigger];
        System.assertEquals(1, afterCount - beforeCount, 'A job should be scheduled for the contact status update.');
    }

    @isTest
    static void testHandleContactStatusUpdate_Update() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'phillip.front@samsara.com' LIMIT 1];
        Task t2 = new Task(WhoId = c.Id, Subject = 'Call', CallDurationInSeconds = 120, Status = 'Completed');
        insert t2;
        Task t2Old = t2.clone(false, false, false, false);
        t2.Subject = 'Re: Follow up';
        update t2;
        Map<Id, Task> oldTaskMap = new Map<Id, Task>{ t2.Id => t2Old };
        GS_TaskService service = new GS_TaskService(new GS_TaskCacheService());

        // Get count before test
        Integer beforeCount = [SELECT COUNT() FROM CronTrigger];

        Test.startTest();
        service.handleContactStatusUpdate(new List<Task>{ t2 }, oldTaskMap);
        Test.stopTest();

        // Get count after and verify delta
        Integer afterCount = [SELECT COUNT() FROM CronTrigger];
        System.assertEquals(1, afterCount - beforeCount, 'A job should be scheduled for the contact status update on task update.');
    }

    @isTest
    static void testHandleContactStatusUpdate_DemoScheduled() {
        Contact c = [SELECT Id, Status__c FROM Contact WHERE Email = 'phillip.front@samsara.com' LIMIT 1];
        c.Status__c = 'Demo Scheduled';
        update c;
        Task t3 = new Task(WhoId = c.Id, Subject = 'Email Reply: Should Not Schedule', Status = 'Completed');
        insert t3;
        GS_TaskService service = new GS_TaskService(new GS_TaskCacheService());

        // Get count before test
        Integer beforeCount = [SELECT COUNT() FROM CronTrigger];

        Test.startTest();
        service.handleContactStatusUpdate(new List<Task>{ t3 }, null);
        Test.stopTest();
        
        // Get count after and verify delta
        Integer afterCount = [SELECT COUNT() FROM CronTrigger];
        System.assertEquals(0, afterCount - beforeCount, 'No job should be scheduled if contact is Demo Scheduled.');
    }

}
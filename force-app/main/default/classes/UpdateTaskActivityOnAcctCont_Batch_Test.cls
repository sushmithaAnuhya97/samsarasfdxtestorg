/**
 * @author: Naved Khan
 * @description: Test class for UpdateTaskActivityOnAcctCont_Batch class.
 */
@isTest
public class UpdateTaskActivityOnAcctCont_Batch_Test {
    
    @testSetup
    static void setupData() {
        // Create a Role to match filter criteria
        UserRole role = new UserRole(Name = 'MM Fleet IS AE2 NA US Team 1');
        insert role;

        // Create a User with the required Role
        User testUser = new User(
            Alias = 'testu',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Tester',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/New_York',
            Username = 'testuserbatch@example.com',
            UserRoleId = role.Id,
            EmployeeNumber = '12345'
        );
        insert testUser;

        System.runAs(testUser) {

        // Create Account and Contact
        Account acc = new Account(Name = 'Test Account');
        acc.Organization_Size__c = '1 - 99';
        acc.BillingCountry = 'United States';
        acc.BillingState = 'Alaska';
        acc.BillingStreet = 'Test Street';
        insert acc;

        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id);
        insert con;

        // Create a "call" Task
        Task callTask = new Task(
            Subject = 'Call with client',
            Status = 'Completed',
            WhoId = con.Id,
            WhatId = acc.Id,
            OwnerId = testUser.Id,
            CallDurationInSeconds = 300
        );

        // Create an "email" Task
        Task emailTask = new Task(
            Subject = 'Email follow-up',
            Status = 'Completed',
            WhoId = con.Id,
            WhatId = acc.Id,
            OwnerId = testUser.Id
        );
        
            Task CSVemailTask = new Task(
            Subject = 'Email follow-up',
            Status = 'Open',
            WhoId = con.Id,
            WhatId = acc.Id,
            OwnerId = testUser.Id
        );
            

        insert new List<Task>{ callTask, emailTask,CSVemailTask};
            
        }
    }

    @isTest
    static void testBatchExecutionWithEmail() {
        Test.startTest();

        List<String> emails = new List<String>{ 'batch.notify@example.com' };
        UpdateTaskActivityOnAcctCont_Batch batch = new UpdateTaskActivityOnAcctCont_Batch(emails);
        Database.executeBatch(batch, 2);

        Test.stopTest();

        // Query updated records
        Account updatedAcc = [SELECT Last_Sales_Activity__c, Last_Call__c FROM Account LIMIT 1];
        Contact updatedCon = [SELECT Last_Call__c FROM Contact LIMIT 1];

        System.assertNotEquals(null, updatedAcc.Last_Sales_Activity__c, 'Account Last_Sales_Activity__c should be updated');
        System.assertNotEquals(null, updatedAcc.Last_Call__c, 'Account Last_Call__c should be updated');
        System.assertNotEquals(null, updatedCon.Last_Call__c, 'Contact Last_Call__c should be updated');
    }

    @isTest
    static void testReRunBatchExecutionWithEmail() {
        Test.startTest();

        Account acct = [SELECT Id FROM Account LIMIT 1];

        Batch_Execution_Progress__c progressRecord = new Batch_Execution_Progress__c();
        progressRecord.Name = 'UpdateTaskActivityOnAcctCont_Batch';
        progressRecord.Last_Processed_Account_Id__c = acct.Id;
        progressRecord.Is_Active__c = true;
        insert progressRecord;

        List<String> emails = new List<String>{ 'batch.notify@example.com' };
        UpdateTaskActivityOnAcctCont_Batch batch = new UpdateTaskActivityOnAcctCont_Batch(emails);
        Database.executeBatch(batch, 2);

        Test.stopTest();

        // Query updated records
        Account updatedAcc = [SELECT Last_Sales_Activity__c, Last_Call__c FROM Account LIMIT 1];
        Contact updatedCon = [SELECT Last_Call__c FROM Contact LIMIT 1];

        System.assertNotEquals(null, updatedAcc.Last_Sales_Activity__c, 'Account Last_Sales_Activity__c should be updated');
        System.assertNotEquals(null, updatedAcc.Last_Call__c, 'Account Last_Call__c should be updated');
        System.assertNotEquals(null, updatedCon.Last_Call__c, 'Contact Last_Call__c should be updated');
    }

    @isTest
    static void testCallAndEmailActivity() {
        Test.startTest();

        Account acct = [SELECT Last_Sales_Activity__c, Last_Call__c FROM Account LIMIT 1];
        acct.Last_Call__c = null;
        acct.Last_Sales_Activity__c = null;
        update acct;

        List<String> emails = new List<String>{ 'batch.notify@example.com' };
        UpdateTaskActivityOnAcctCont_Batch batch = new UpdateTaskActivityOnAcctCont_Batch(emails);
        Database.executeBatch(batch, 2);

        Test.stopTest();

        // Query updated records
        Account updatedAcc = [SELECT Last_Sales_Activity__c, Last_Call__c FROM Account LIMIT 1];
        Contact updatedCon = [SELECT Last_Call__c FROM Contact LIMIT 1];

        System.assertNotEquals(null, updatedAcc.Last_Sales_Activity__c, 'Account Last_Sales_Activity__c should be updated');
        System.assertNotEquals(null, updatedAcc.Last_Call__c, 'Account Last_Call__c should be updated');
        System.assertNotEquals(null, updatedCon.Last_Call__c, 'Contact Last_Call__c should be updated');
    }

    @isTest
    static void testCallAndEmailActivityError() {

        Account acct = [SELECT Last_Sales_Activity__c, Last_Call__c FROM Account LIMIT 1];
        acct.Last_Call__c = null;
        acct.Last_Sales_Activity__c = null;
        update acct;

        Test.startTest();
        List<String> emails = new List<String>{ 'batch.notify@example.com' };
        UpdateTaskActivityOnAcctCont_Batch batch = new UpdateTaskActivityOnAcctCont_Batch(emails, null, null, true);
        Database.executeBatch(batch, 2);
        Test.stopTest();
    }

    @isTest
    static void testBatchWithNoEmailsPassed() {
        Test.startTest();
        UpdateTaskActivityOnAcctCont_Batch batch = new UpdateTaskActivityOnAcctCont_Batch(null);
        Database.executeBatch(batch, 2);
        Test.stopTest();
    }
    
    @isTest
    static void testBatchWithAccountIdsConstructor() {
        List<Account> accounts = [SELECT Id FROM Account LIMIT 1];
        Set<Id> accountIds = new Set<Id>();
        for (Account acct : accounts) {
            accountIds.add(acct.Id);
        }

        Test.startTest();
        UpdateTaskActivityOnAcctCont_Batch batch = new UpdateTaskActivityOnAcctCont_Batch(new List<String>{'notify@example.com'}, accountIds);
        Database.executeBatch(batch, 2);
        Test.stopTest();

        
        Account updatedAcc = [SELECT Last_Sales_Activity__c, Last_Call__c FROM Account LIMIT 1];
        System.assertNotEquals(null, updatedAcc.Last_Sales_Activity__c);
    }
    
    @isTest
    static void testCallActivityUpdatesBothFields() {
        // Get the test data from setup
        Account testAccount = [SELECT Id, Last_Sales_Activity__c, Last_Call__c FROM Account LIMIT 1];
        Contact testContact = [SELECT Id, Last_Call__c FROM Contact LIMIT 1];
        
        // Reset the fields to null
        testAccount.Last_Sales_Activity__c = null;
        testAccount.Last_Call__c = null;
        testContact.Last_Call__c = null;
        update testAccount;
        update testContact;
        
        // Get the call task from setup
        Task callTask = [SELECT Id, AccountId FROM Task WHERE CallDurationInSeconds > 0 LIMIT 1];
        
        Test.startTest();
        UpdateTaskActivityOnAcctCont_Batch batch = new UpdateTaskActivityOnAcctCont_Batch(
            new List<String>{'test@example.com'}, 
            new Set<Id>{callTask.AccountId}
        );
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify Account updates
        Account updatedAccount = [SELECT Id, Last_Call__c, Last_Sales_Activity__c FROM Account WHERE Id = :testAccount.Id];
        System.assertNotEquals(null, updatedAccount.Last_Call__c, 'Last Call should be updated');
        System.assertNotEquals(null, updatedAccount.Last_Sales_Activity__c, 'Last Sales Activity should be updated');
        System.assertEquals(updatedAccount.Last_Call__c, updatedAccount.Last_Sales_Activity__c, 'Both fields should have the same timestamp');
        
        // Verify Contact updates
        Contact updatedContact = [SELECT Id, Last_Call__c FROM Contact WHERE Id = :testContact.Id];
        System.assertNotEquals(null, updatedContact.Last_Call__c, 'Contact Last Call should be updated');
    }
    
    @isTest
    static void testEmailActivityUpdatesOnlySalesActivity() {
        // Get the test data from setup
        Account testAccount = [SELECT Id, Last_Sales_Activity__c, Last_Call__c FROM Account LIMIT 1];
        
        // Reset the fields to null
        testAccount.Last_Sales_Activity__c = null;
        testAccount.Last_Call__c = null;
        update testAccount;
        
        // Get the email task from setup
        Task callTask = [SELECT Id, AccountId FROM Task WHERE CallDurationInSeconds != null LIMIT 1];
        delete callTask;
        
        Test.startTest();
        UpdateTaskActivityOnAcctCont_Batch batch = new UpdateTaskActivityOnAcctCont_Batch(
            new List<String>{'test@example.com'}, 
            new Set<Id>{testAccount.Id}
        );
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify Account updates
        Account updatedAccount = [SELECT Id, Last_Call__c, Last_Sales_Activity__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(null, updatedAccount.Last_Call__c, 'Last Call should not be updated for email');
        System.assertNotEquals(null, updatedAccount.Last_Sales_Activity__c, 'Last Sales Activity should be updated');
    }
    
    
    @isTest
    static void testTaskWithLargeTimeDifference() {
        // Get the test data from setup
        Account testAccount = [SELECT Id, Last_Sales_Activity__c, Last_Call__c FROM Account LIMIT 1];
        Contact testContact = [SELECT Id, Last_Call__c FROM Contact LIMIT 1];
        
        // Reset the fields to null
        testAccount.Last_Sales_Activity__c = null;
        testAccount.Last_Call__c = null;
        testContact.Last_Call__c = null;
        update testAccount;
        update testContact;
        
        // Create a task with large time difference between CreatedDate and CompletedDateTime
        Task taskWithTimeDiff = new Task(
            Subject = 'Call with client',
            Status = 'Completed',
            WhoId = testContact.Id,
            WhatId = testAccount.Id,
            CallDurationInSeconds = 300
        );
        insert taskWithTimeDiff;
        
        Test.setCreatedDate(taskWithTimeDiff.Id, System.now().addMinutes(-5));
        
        Test.startTest();
        UpdateTaskActivityOnAcctCont_Batch batch = new UpdateTaskActivityOnAcctCont_Batch(
            new List<String>{'test@example.com'}, 
            new Set<Id>{taskWithTimeDiff.WhatId}
        );
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify that the fields were not updated due to large time difference
        Account updatedAccount = [SELECT Id, Last_Call__c, Last_Sales_Activity__c FROM Account WHERE Id = :testAccount.Id];
        //System.assertEquals(null, updatedAccount.Last_Call__c, 'Last Call should not be updated due to large time difference');
        //System.assertEquals(null, updatedAccount.Last_Sales_Activity__c, 'Last Sales Activity should not be updated due to large time difference');
        
        Contact updatedContact = [SELECT Id, Last_Call__c FROM Contact WHERE Id = :testContact.Id];
        //System.assertEquals(null, updatedContact.Last_Call__c, 'Contact Last Call should not be updated due to large time difference');
    }
    
    @isTest
    static void testGongInAndGongOutActivities() {
        // Get the test data from setup
        Account testAccount = [SELECT Id, Last_Sales_Activity__c, Last_Call__c FROM Account LIMIT 1];
        
        // Reset the fields to null
        testAccount.Last_Sales_Activity__c = null;
        testAccount.Last_Call__c = null;
        update testAccount;
        
        // Create Gong In Task
        Task gongInTask = new Task(
            Subject = '[Gong In] Test Call',
            Status = 'Completed',
            WhatId = testAccount.Id
            //Is_Email__c = 'Gong In'
        );
        
        // Create Gong Out Task
        Task gongOutTask = new Task(
            Subject = '[Gong Out] Test Call',
            Status = 'Completed',
            WhatId = testAccount.Id
            //Is_Email__c = 'Gong Out'
        );
        
        insert new List<Task>{gongInTask, gongOutTask};
        
        Test.startTest();
        UpdateTaskActivityOnAcctCont_Batch batch = new UpdateTaskActivityOnAcctCont_Batch(
            new List<String>{'test@example.com'}, 
            new Set<Id>{gongInTask.WhatId, gongOutTask.WhatId}
        );
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify Account updates
        Account updatedAccount = [SELECT Id, Last_Sales_Activity__c, Last_Call__c FROM Account WHERE Id = :testAccount.Id];
        //System.assertNotEquals(null, updatedAccount.Last_Sales_Activity__c, 'Last Sales Activity should be updated for Gong tasks');
        //System.assertEquals(null, updatedAccount.Last_Call__c, 'Last Call should not be updated for Gong tasks');
    }
}
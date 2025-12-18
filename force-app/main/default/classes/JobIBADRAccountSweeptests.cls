/**
* @description       : https://samsaradev.atlassian.net/browse/GTMS-12819
* @author            : nishita.dhar@samsara.com
* @group             : 
* @last modified on  : 28-11-2023
* @last modified by  : 
**/
@isTest
public class JobIBADRAccountSweeptests {
    @testSetup
    private static void testDataSetup() {
        
        List<Account> newAccounts = new List<Account>();
        List<Contact> newContacts = new List<Contact>();
        
        
        
        User u = [SELECT Id FROM User WHERE id != '0051a000002W9InAAK' and UserRole.name = 'Fleet ADR IB NA MX Team 13' LIMIT 1];
        
        Account accountOne = (Account) TestFactory.createSObject(new Account(Name = 'Nish1',
                                                                             BillingState='California',
                                                                             BillingCountry = 'United States',
                                                                             Organization_Size__c = '100 - 499',
                                                                             Account_Assignment_Date__c = System.today()-23,
                                                                             Industry = 'Other',
                                                                             Ownerid =u.id));
        newAccounts.add(accountOne);
        Account accountTwo = (Account) TestFactory.createSObject(new Account(Name = 'Nish2',
                                                                             BillingState='California',
                                                                             BillingCountry = 'United States',
                                                                             Organization_Size__c = '100 - 499',
                                                                             Account_Assignment_Date__c = System.today().addDays(-21),                                            
                                                                             Industry = 'Other',
                                                                             Ownerid =u.id));
        newAccounts.add(accountTwo);
        insert newAccounts;
        
        Contact contactOne = (Contact) TestFactory.createSObject(new Contact(AccountId = accountOne.Id, Email = 'test123@test.com', Status__c ='New'));
        newContacts.add(contactOne);
        Contact contactTwo = (Contact) TestFactory.createSObject(new Contact(AccountId = accountTwo.Id, Email = 'test@test.com', Status__c ='Contact Established'));
        newContacts.add(contactTwo);
        insert newContacts;
        List<Task> newTasks = new List<Task>();
        Task task1 = new Task(WhoId=contactTwo.id , Subject='Other');
        newTasks.add(task1);
        insert newTasks;
        
    }
    public static DateTime now {
        get {
            return (now == null) ? DateTime.now() : now;
        }
        set;
    }
    @isTest
    static void testEndOfMonthSchedule() {
        Test.startTest();
        
        Date accountAssignmentDate = System.today().addDays(-20);
        Account acc = [SELECT Id, Days_from_Account_Assignment_Date__c FROM Account WHERE Name = 'Nish1' LIMIT 1];
        acc.Account_Assignment_Date__c = accountAssignmentDate;
        System.debug('acc.Account_Assignment_Date__c-->' + acc.Account_Assignment_Date__c);
        update acc;
        
        // Query the updated Account to get the value of Days_from_Account_Assignment_Date__c
        
        now = DateTime.now().addDays(-31);
        System.debug('now-->' + now);
        Account accountOne = [SELECT Id,Days_from_Account_Assignment_Date__c FROM Account WHERE Name='Nish1' LIMIT 1];
        System.debug('accountOne-->' + accountOne);
        JobIBADRAccountSweep batch = new JobIBADRAccountSweep();
        
        Database.executeBatch(batch);
        
        Test.stopTest();
        
    }
    
    @isTest
    static void testEndOfQuarterSchedule() {
        Test.startTest();
        Date accountAssignmentDate = System.today().addDays(-20);
        Account acc = [SELECT Id, Days_from_Account_Assignment_Date__c FROM Account WHERE Name='Nish2' LIMIT 1];
        acc.Account_Assignment_Date__c = accountAssignmentDate;
        System.debug('acc.Account_Assignment_Date__c-->' + acc.Account_Assignment_Date__c);
        update acc;
        Account accountOne = [SELECT Id,Days_from_Account_Assignment_Date__c FROM Account WHERE Name='Nish2' LIMIT 1];
        Contact contactTwo = [SELECT Id FROM Contact WHERE Email = 'test@test.com'];
        Task task1 = [SELECT Id From Task WHERE Subject ='Other'];
        task1.CallDurationInSeconds =100;
        task1.Related_Contact__c = contactTwo.id;
        update task1;
        JobIBADRAccountSweep batch = new JobIBADRAccountSweep();
        Database.executeBatch(batch);
        
        Test.stopTest();
    }
    @isTest
    static void errorhandling() {
            Test.startTest();

        // Mock an exception during batch processing
        Test.setMock(Database.BatchableContext.class, new MockBatchableContext());
        
        // Create an instance of JobIBADRAccountSweep
        JobIBADRAccountSweep job = new JobIBADRAccountSweep();

        // Call the sendErrorEmail method directly
        job.sendErrorEmail('Test error message');

        Test.stopTest();

        // Check if the error email is sent
        // Here, you can add assertions to verify that the error email is sent correctly.
        // For example, you can check if the email is sent to the correct recipient or if the subject and body are correct.
        // If you have any specific logic to validate the email sending, you can include it here.
    }

    // Mock implementation for Database.BatchableContext
    public class MockBatchableContext implements Database.BatchableContext {
        public Id getJobId() {
            return '707'; // Mocking a job ID
        }

        // Implementing the method
        public Id getChildJobId() {
            return null;
        }
    }
    }
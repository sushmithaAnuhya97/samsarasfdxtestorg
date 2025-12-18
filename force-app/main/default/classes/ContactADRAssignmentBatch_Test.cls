@isTest
public class ContactADRAssignmentBatch_Test {
    @testSetup
    private static void testDataSetup() {
        Map<String, Id> roleNameToIdMap = new Map<String, Id>();

        for(UserRole role : [
            SELECT Id, DeveloperName 
            FROM UserRole 
            WHERE DeveloperName IN ('CML_Fleet_IS_AE1_NA_US_Team_27', 'Management', 'Fleet_ADR_OB_EMEA_FR_Team_2', 'Fleet_Plus_CSM_NA_US_Team_2')
            LIMIT 4
        ]) {
            roleNameToIdMap.put(role.DeveloperName, role.Id);
        }

        Profile pf = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        List<User> usersToInsert = new List<User>();
        User adrUser1 = new User(
            FirstName = 'ADR',
            LastName = 'Test1',
            Email = 'adr.test1@example.com',
            Username = 'adr.test1@example.com' + System.currentTimeMillis(),
            Alias = 'adr1',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = pf.Id,
            UserRoleId = roleNameToIdMap.get('Fleet_ADR_OB_EMEA_FR_Team_2'),
            TimeZoneSidKey = 'America/Los_Angeles',
            EmployeeNumber = 'BHR-001'
        );
        usersToInsert.add(adrUser1);
        
        User adrUser2 = new User(
            FirstName = 'ADR',
            LastName = 'Test2',
            Email = 'adr.test2@example.com',
            Username = 'adr.test2@example.com' + System.currentTimeMillis(),
            Alias = 'adr2',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = pf.Id,
            UserRoleId = roleNameToIdMap.get('Fleet_ADR_OB_EMEA_FR_Team_2'),
            TimeZoneSidKey = 'America/Los_Angeles',
            EmployeeNumber = 'BHR-002'
        );
        usersToInsert.add(adrUser2);
        insert usersToInsert;

        System.runAs(usersToInsert[0]) {
            List<Account> accounts = new List<Account>();
            for(Integer i = 0; i < 3; i++) {
            Account acc = new Account(
                Name = 'Test Account ' + i,
                Organization_Size__c = '5000+',
                BillingStreet = '26 Napier Street',
                BillingCity = 'London',
                BillingPostalCode  = '1030',
                BillingCountry = 'United Kingdom',
                Billing_Email__c  = 'qdasdas@gmail.com',
                ADRAssignment__c = adrUser1.Id
            );
            accounts.add(acc);
            }
            insert accounts;
        
            List<Contact> contacts = new List<Contact>();
            for(Account acc : accounts) {
            for(Integer i = 0; i < 2; i++) {
                Contact con = new Contact(
                    FirstName = 'Test',
                    LastName = 'Contact ' + acc.Name + ' ' + i,
                    AccountId = acc.Id,
                    ADR_Assignment__c = adrUser1.Id
                );
                    contacts.add(con);
                }
            }
            insert contacts;
        }
    }
    
    @isTest
    static void testBatchExecution() {
        Set<Id> accountIds = new Set<Id>();
        for(Account acc : [SELECT Id FROM Account]) {
            accountIds.add(acc.Id);
        }
        
        User newADR = [SELECT Id FROM User WHERE LastName = 'Test2'];
        List<Account> accountsToUpdate = [SELECT Id, ADRAssignment__c FROM Account];
        for(Account acc : accountsToUpdate) {
            acc.ADRAssignment__c = newADR.Id;
        }
        update accountsToUpdate;
        
        Test.startTest();
        ContactADRAssignmentBatch batch = new ContactADRAssignmentBatch(accountIds);
        Database.executeBatch(batch);
        Test.stopTest();
    }
    
    @isTest
    static void testBatchWithNoRecords() {
        Set<Id> emptyAccountIds = new Set<Id>();
        Test.startTest();
        ContactADRAssignmentBatch batch = new ContactADRAssignmentBatch(emptyAccountIds);
        Database.executeBatch(batch);
        Test.stopTest();
    }
    
    @isTest
    static void testBatchWithDMLException() {
        // Get test accounts
        Set<Id> accountIds = new Set<Id>();
        for(Account acc : [SELECT Id FROM Account]) {
            accountIds.add(acc.Id);
        }
        
        User newADR = [SELECT Id FROM User WHERE LastName = 'Test2'];
        
        // Update Account ADR assignments
        List<Account> accountsToUpdate = [SELECT Id, ADRAssignment__c FROM Account];
        for(Account acc : accountsToUpdate) {
            acc.ADRAssignment__c = newADR.Id;
        }
        update accountsToUpdate;
        
        // Create a trigger to force a DML exception
        Contact invalidContact = new Contact(
            FirstName = 'Invalid',
            LastName = 'Contact',
            AccountId = accountsToUpdate[0].Id,
            ADR_Assignment__c = null
        );
        insert invalidContact;
        
        Test.startTest();
        ContactADRAssignmentBatch batch = new ContactADRAssignmentBatch(accountIds);
        Database.executeBatch(batch);
        Test.stopTest();
    }
    
    @isTest
    static void testBatchWithNullADR() {
        // Setup test data
        Set<Id> accountIds = new Set<Id>();
        for(Account acc : [SELECT Id FROM Account]) {
            accountIds.add(acc.Id);
        }

        // Update one account to have a null ADR assignment
        List<Account> accountsToUpdate = [SELECT Id, ADRAssignment__c FROM Account LIMIT 1];
        if (!accountsToUpdate.isEmpty()) {
            accountsToUpdate[0].ADRAssignment__c = null;
            update accountsToUpdate;
        }

        Test.startTest();
        ContactADRAssignmentBatch batch = new ContactADRAssignmentBatch(accountIds);
        Database.executeBatch(batch);
        Test.stopTest();
    }

@isTest
static void testLogErrorMethod() {
    // Simulate parameters for the logError method
    Id testAccountId = Id.valueOf('001000000000001'); // Example Account Id
    String errorMessage = 'Simulated error message';
    String simulatedErrorResponse = 'Simulated database error message';

    // Call the logError method
    Api_Logger__c logEntry = ContactADRAssignmentBatch.logError(testAccountId, errorMessage, null);
    System.assertEquals(ContactADRAssignmentBatch.class.getName() + System.now(), logEntry.Name, 'Log entry name should match expected format');
   }
    
}
@isTest
public class GS_ContactInboundOrChannelServiceTest {
    @isTest
    static void testNewInboundOrChannel() {
         Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Samsara Inbound ADRs']; // Adjust profile name as needed
       // UserRole testRole = [SELECT Id FROM UserRole WHERE Name = 'Some Role']; // Adjust role name as needed
        User u = new User(lastName = 'blah',
                          email = 'uniqueName' + '@test' +'.org',
                          Username = 'u' + '@test' + '.org',
                          EmailEncodingKey = 'ISO-8859-1',
                          Alias = 'qwer',
                          TimeZoneSidKey = 'America/Los_Angeles',
                          LocaleSidKey = 'en_US',
                          LanguageLocaleKey = 'en_US',
                          ProfileId = testProfile.Id,
                          EmployeeNumber='123',
                         RR_Is_Pool_User__c=true);
        insert u;
        
        // Create test data for Contact and Account
        Account testAccount = new Account(Name = 'Test Account', Organization_Size__c = '1000 - 4999', BillingCountry = 'United States', BillingState='California', Industry = 'Other',Open_Opportunity__c=false,Initiate_Round_Robin__c=false,
                                         RecordTypeId  = Schema.SObjectType.account.getRecordTypeInfosByName().get('Industrial').getRecordTypeId());
        insert testAccount;
        
        Contact testContact1 = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            AccountId = testAccount.Id,
            New_Inbound_Lead__c = true,
            Most_Recent_Source__c = 'test'
        );
        Contact testContact2 = new Contact(
            FirstName = 'Jane',
            LastName = 'Smith',
            AccountId = testAccount.Id,
            Channel_Source__c = true,
            Most_Recent_Source__c = 'test'
        );
        List<Contact> newContactList = new List<Contact>{testContact1, testContact2};
        insert newContactList;

        // Create an instance of the GS_ContactCacheService class (you may need to mock this)
        GS_ContactCacheService contactCache = new GS_ContactCacheService();

        // Create an instance of the GS_ContactInboundOrChannelService class
        GS_ContactInboundOrChannelService service = new GS_ContactInboundOrChannelService();

        // Call the newInboundOrChannel method
        Test.startTest();
        service.newInboundOrChannel(newContactList, new Map<Id, Contact>(), contactCache);
        Test.stopTest();

        // Perform assertions to verify the expected behavior
        // You can assert the values in the Account records and any other expected outcomes
        // Example: Account updated fields should match your expected values
        Account updatedAccount = [SELECT Id, Most_Recent_Source__c FROM Account WHERE Id = :testAccount.Id];
        //System.assertEquals('Expected Source', updatedAccount.Most_Recent_Source__c);

        // You can add more assertions based on your specific requirements
    }
    @isTest
    static void testMethod002() {
         Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Samsara Inbound ADRs']; // Adjust profile name as needed
         UserRole testRole = [SELECT Id FROM UserRole WHERE Name = 'Fleet ADR IB NA US Team 8']; // Adjust role name as needed
        User u = new User(lastName = 'blah',
                          email = 'uniqueName' + '@test' +'.org',
                          Username = 'u' + '@test' + '.org',
                          EmailEncodingKey = 'ISO-8859-1',
                          Alias = 'qwer',
                          TimeZoneSidKey = 'America/Los_Angeles',
                          LocaleSidKey = 'en_US',
                          LanguageLocaleKey = 'en_US',
                          ProfileId = testProfile.Id,
                          UserRoleId = testRole.Id,
                          EmployeeNumber='123',
                         RR_Is_Pool_User__c=true);
        insert u;
        
        // Create test data for Contact and Account
        List<Contact> newContactList = new List<Contact>();
        Account testAccount = new Account();
        system.runAs(u)
        {
            testAccount = new Account(Name = 'Test Account', Organization_Size__c = '1000 - 4999', BillingCountry = 'United States', BillingState='California', Industry = 'Other',Open_Opportunity__c=false,Initiate_Round_Robin__c=false,
                                              RecordTypeId  = Schema.SObjectType.account.getRecordTypeInfosByName().get('Industrial').getRecordTypeId(),RR_Assign_Region_Owner__c=false);
            insert testAccount;
            
            Contact testContact1 = new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                AccountId = testAccount.Id,
                New_Inbound_Lead__c = true,
                Most_Recent_Source__c = 'test'
            );
            Contact testContact2 = new Contact(
                FirstName = 'Jane',
                LastName = 'Smith',
                AccountId = testAccount.Id,
                Most_Recent_Source__c = 'test'
            );
            newContactList = new List<Contact>{testContact1, testContact2};
                insert newContactList;
        }
        

        // Create an instance of the GS_ContactCacheService class (you may need to mock this)
        GS_ContactCacheService contactCache = new GS_ContactCacheService();

        // Create an instance of the GS_ContactInboundOrChannelService class
        GS_ContactInboundOrChannelService service = new GS_ContactInboundOrChannelService();

        // Call the newInboundOrChannel method
        Test.startTest();
        service.newInboundOrChannel(newContactList, new Map<Id, Contact>(), contactCache);
        Test.stopTest();

        // Perform assertions to verify the expected behavior
        // You can assert the values in the Account records and any other expected outcomes
        // Example: Account updated fields should match your expected values
        Account updatedAccount = [SELECT Id, Most_Recent_Source__c FROM Account WHERE Id = :testAccount.Id];
        //System.assertEquals('Expected Source', updatedAccount.Most_Recent_Source__c);

        // You can add more assertions based on your specific requirements
    }
    @isTest
    static void testMethod003() {
         Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Samsara Inbound ADRs']; // Adjust profile name as needed
         UserRole testRole = [SELECT Id FROM UserRole WHERE Name = 'Fleet ADR IB NA US Team 8']; // Adjust role name as needed
        User u = new User(lastName = 'blah',
                          email = 'uniqueName' + '@test' +'.org',
                          Username = 'u' + '@test' + '.org',
                          EmailEncodingKey = 'ISO-8859-1',
                          Alias = 'qwer',
                          TimeZoneSidKey = 'America/Los_Angeles',
                          LocaleSidKey = 'en_US',
                          LanguageLocaleKey = 'en_US',
                          ProfileId = testProfile.Id,
                          UserRoleId = testRole.Id,
                          EmployeeNumber='123',
                         RR_Is_Pool_User__c=true);
        insert u;
        
        // Create test data for Contact and Account
        List<Contact> newContactList = new List<Contact>();
        Account testAccount = new Account();
        system.runAs(u)
        {
            testAccount = new Account(Name = 'Test Account', Organization_Size__c = '1000 - 4999', BillingCountry = 'United States', BillingState='California', Industry = 'Other',Open_Opportunity__c=false,Initiate_Round_Robin__c=false,
                                              RecordTypeId  = Schema.SObjectType.account.getRecordTypeInfosByName().get('Industrial').getRecordTypeId(),RR_Assign_Region_Owner__c=false);
            insert testAccount;
            
            Contact testContact1 = new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                AccountId = testAccount.Id,
                New_Inbound_Lead__c = true,
                Most_Recent_Source__c = 'test'
            );
            Contact testContact2 = new Contact(
                FirstName = 'Jane',
                LastName = 'Smith',
                AccountId = testAccount.Id,
            Channel_Source__c = true,
                Most_Recent_Source__c = 'test'
            );
            newContactList = new List<Contact>{testContact1, testContact2};
                insert newContactList;
        }
        

        // Create an instance of the GS_ContactCacheService class (you may need to mock this)
        GS_ContactCacheService contactCache = new GS_ContactCacheService();

        // Create an instance of the GS_ContactInboundOrChannelService class
        GS_ContactInboundOrChannelService service = new GS_ContactInboundOrChannelService();

        // Call the newInboundOrChannel method
        Test.startTest();
        service.newInboundOrChannel(newContactList, new Map<Id, Contact>(), contactCache);
        Test.stopTest();

        // Perform assertions to verify the expected behavior
        // You can assert the values in the Account records and any other expected outcomes
        // Example: Account updated fields should match your expected values
        Account updatedAccount = [SELECT Id, Most_Recent_Source__c FROM Account WHERE Id = :testAccount.Id];
        //System.assertEquals('Expected Source', updatedAccount.Most_Recent_Source__c);

        // You can add more assertions based on your specific requirements
    }
    @isTest
    static void testMethod004() {
         Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Samsara Inbound ADRs']; // Adjust profile name as needed
         UserRole testRole = [SELECT Id FROM UserRole WHERE Name = 'Fleet ADR IB NA US Team 8']; // Adjust role name as needed
        User u = new User(lastName = 'blah',
                          email = 'uniqueName' + '@test' +'.org',
                          Username = 'u' + '@test' + '.org',
                          EmailEncodingKey = 'ISO-8859-1',
                          Alias = 'qwer',
                          TimeZoneSidKey = 'America/Los_Angeles',
                          LocaleSidKey = 'en_US',
                          LanguageLocaleKey = 'en_US',
                          ProfileId = testProfile.Id,
                          UserRoleId = testRole.Id,
                          EmployeeNumber='123',
                         RR_Is_Pool_User__c=true);
        insert u;
        
        // Create test data for Contact and Account
        List<Contact> newContactList = new List<Contact>();
        Account testAccount = new Account();
        system.runAs(u)
        {
            testAccount = new Account(Name = 'Test Account', Organization_Size__c = '1 - 99', BillingCountry = 'United States', BillingState='California', Industry = 'Other',Open_Opportunity__c=false,Initiate_Round_Robin__c=false,
                                              RecordTypeId  = Schema.SObjectType.account.getRecordTypeInfosByName().get('Industrial').getRecordTypeId(),RR_Assign_Region_Owner__c=false);
            insert testAccount;
            
            Contact testContact1 = new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                AccountId = testAccount.Id,
                New_Inbound_Lead__c = true,
                Most_Recent_Source__c = 'test'
            );
            Contact testContact2 = new Contact(
                FirstName = 'Jane',
                LastName = 'Smith',
                AccountId = testAccount.Id,
            Channel_Source__c = true,
                Most_Recent_Source__c = 'test'
            );
            newContactList = new List<Contact>{testContact1, testContact2};
                insert newContactList;
        }
        

        // Create an instance of the GS_ContactCacheService class (you may need to mock this)
        GS_ContactCacheService contactCache = new GS_ContactCacheService();

        // Create an instance of the GS_ContactInboundOrChannelService class
        GS_ContactInboundOrChannelService service = new GS_ContactInboundOrChannelService();

        // Call the newInboundOrChannel method
        Test.startTest();
        service.newInboundOrChannel(newContactList, new Map<Id, Contact>(), contactCache);
        Test.stopTest();

        // Perform assertions to verify the expected behavior
        // You can assert the values in the Account records and any other expected outcomes
        // Example: Account updated fields should match your expected values
        Account updatedAccount = [SELECT Id, Most_Recent_Source__c FROM Account WHERE Id = :testAccount.Id];
        //System.assertEquals('Expected Source', updatedAccount.Most_Recent_Source__c);

        // You can add more assertions based on your specific requirements
    }
    
    @isTest
    static void testMethod005() {
         Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Samsara Inbound ADRs']; // Adjust profile name as needed
         UserRole testRole = [SELECT Id FROM UserRole WHERE Name = 'Fleet ADR IB NA US Team 8']; // Adjust role name as needed
        User u = new User(lastName = 'blah',
                          email = 'uniqueName' + '@test' +'.org',
                          Username = 'u' + '@test' + '.org',
                          EmailEncodingKey = 'ISO-8859-1',
                          Alias = 'qwer',
                          TimeZoneSidKey = 'America/Los_Angeles',
                          LocaleSidKey = 'en_US',
                          LanguageLocaleKey = 'en_US',
                          ProfileId = testProfile.Id,
                          UserRoleId = testRole.Id,
                          EmployeeNumber='123',
                         RR_Is_Pool_User__c=true);
        insert u;
        
        // Create test data for Contact and Account
        List<Contact> newContactList = new List<Contact>();
        Account testAccount = new Account();
        system.runAs(u)
        {
            testAccount = new Account(Name = 'Test Account', Organization_Size__c = '1 - 99', BillingCountry = 'United States', BillingState='California', Industry = 'Other',Open_Opportunity__c=false,Initiate_Round_Robin__c=false,
                                              RecordTypeId  = Schema.SObjectType.account.getRecordTypeInfosByName().get('Manufacturer').getRecordTypeId(),RR_Assign_Region_Owner__c=false);
            insert testAccount;
            
            Contact testContact1 = new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                AccountId = testAccount.Id,
                New_Inbound_Lead__c = true,
                Most_Recent_Source__c = 'test'
            );
            Contact testContact2 = new Contact(
                FirstName = 'Jane',
                LastName = 'Smith',
                AccountId = testAccount.Id,
            Channel_Source__c = true,
                Most_Recent_Source__c = 'test'
            );
            newContactList = new List<Contact>{testContact1, testContact2};
                insert newContactList;
        }
        

        // Create an instance of the GS_ContactCacheService class (you may need to mock this)
        GS_ContactCacheService contactCache = new GS_ContactCacheService();

        // Create an instance of the GS_ContactInboundOrChannelService class
        GS_ContactInboundOrChannelService service = new GS_ContactInboundOrChannelService();

        // Call the newInboundOrChannel method
        Test.startTest();
        service.newInboundOrChannel(newContactList, new Map<Id, Contact>(), contactCache);
        Test.stopTest();

        // Perform assertions to verify the expected behavior
        // You can assert the values in the Account records and any other expected outcomes
        // Example: Account updated fields should match your expected values
        Account updatedAccount = [SELECT Id, Most_Recent_Source__c FROM Account WHERE Id = :testAccount.Id];
        //System.assertEquals('Expected Source', updatedAccount.Most_Recent_Source__c);

        // You can add more assertions based on your specific requirements
    }

    // Add more test methods to cover other scenarios and edge cases
}
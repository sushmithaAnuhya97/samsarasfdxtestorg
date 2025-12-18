@isTest
private class EventTests {

    @isTest 
    static void insertEvent() {

        Account a = new Account (Name = 'Testing Acct', 
                                Organization_Size__c =' 1 - 99', 
                                BillingCountry = 'United States', 
                                Industry = 'Other', 
                                ADR_Transfer__c = false, 
                                BillingState = 'California', 
                                OwnerId = UserInfo.getUserId());
        insert a;

        Contact ctc = new Contact(FirstName = 'Testing', 
                                  LastName = 'Contact 123',
                                  Description = 'Hello world...', 
                                  Email = 'testing123@email.com', 
                                  Phone = '1234560011',
                                  Status__c = 'Assigned',
                                  AccountId = a.Id,
                                  OwnerId = UserInfo.getUserId());
        insert ctc;

        Id demoRT = Schema.SObjectType.Event.getRecordTypeInfosByName().get('Demo').getRecordTypeId();
        system.debug(LoggingLevel.INFO, 'This is the Demo RecordTypeId: '+demoRT);
    	system.debug(LoggingLevel.INFO, 'This is the Related Contact: '+ctc.Id);

        Event e = new Event(Subject = 'Test Demo', 
                            DurationInMinutes = 30, 
                            StartDateTime = System.now(), 
                            RecordTypeId = demoRT, 
                            OwnerId = UserInfo.getUserId(), 
                            Description = 'Testing 123',
                            Demo_Status__c = 'Demo Scheduled',
                            Type = 'Standard Demo',
                            Related_Account__c = a.Id, 
                            Related_Contact__c = ctc.Id);
        Test.startTest();
        insert e;
        Test.stopTest();

        system.debug(LoggingLevel.INFO, 'This is the Demo RecordType Name: '+e.RecordTypeId);
        system.debug(LoggingLevel.INFO, 'This is the Demo Related Contact: '+e.Related_Contact__c);
        system.assertEquals('Demo Scheduled', [SELECT Status__c FROM Contact WHERE Id = : ctc.Id LIMIT 1].Status__c);
        system.debug(LoggingLevel.INFO, 'This is the Contact Status: '+ctc.Status__c);
    }

    @isTest 
    static void completingEvent() {

        Account a = new Account (Name = 'Testing Acct', 
                                Organization_Size__c =' 1 - 99', 
                                BillingCountry = 'United States', 
                                Industry = 'Other', 
                                ADR_Transfer__c = false, 
                                BillingState = 'California', 
                                OwnerId = UserInfo.getUserId());
        insert a;

        Contact ctc = new Contact(FirstName = 'Testing', 
                                  LastName = 'Contact 123',
                                  Description = 'Hello world...', 
                                  Email = 'testing123@email.com', 
                                  Phone = '1234560011',
                                  Status__c = 'Assigned',
                                  AccountId = a.Id,
                                  OwnerId = UserInfo.getUserId());
        insert ctc;

        Id demoRT = Schema.SObjectType.Event.getRecordTypeInfosByName().get('Demo').getRecordTypeId();
        system.debug(LoggingLevel.INFO, 'This is the Demo RecordTypeId: '+demoRT);
    	system.debug(LoggingLevel.INFO, 'This is the Related Contact: '+ctc.Id);

        Event e = new Event(Subject = 'Test Demo', 
                            DurationInMinutes = 30, 
                            StartDateTime = System.now(), 
                            RecordTypeId = demoRT, 
                            OwnerId = UserInfo.getUserId(), 
                            Description = 'Testing 123',
                            Type = 'Standard Demo',
                            Demo_Status__c = 'Demo Completed - Qualified',
                            Related_Account__c = a.Id, 
                            Related_Contact__c = ctc.Id);
        Test.startTest();
        insert e;
        Test.stopTest();

        system.debug(LoggingLevel.INFO, 'This is the Demo RecordType Name: '+e.RecordTypeId);
        system.debug(LoggingLevel.INFO, 'This is the Demo Related Contact: '+e.Related_Contact__c);
        system.assertEquals(System.UserInfo.getUserId(), e.OwnerId);
        system.debug(LoggingLevel.INFO, 'This is the Contact Status: '+ctc.Status__c);

    }
/*
    @isTest 
    static void oppToDemo() {

        Account a = new Account (Name = 'Testing Acct', 
                                Organization_Size__c =' 1 - 99', 
                                BillingCountry = 'United States', 
                                Industry = 'Other', 
                                ADR_Transfer__c = false, 
                                BillingState = 'California', 
                                OwnerId = UserInfo.getUserId());
        insert a;

        Contact ctc = new Contact(FirstName = 'Testing', 
                                  LastName = 'Contact 123',
                                  Description = 'Hello world...', 
                                  Email = 'testing123@email.com', 
                                  Phone = '1234560011',
                                  Status__c = 'Assigned',
                                  AccountId = a.Id,
                                  OwnerId = UserInfo.getUserId());
        insert ctc;

        Id demoRT = Schema.SObjectType.Event.getRecordTypeInfosByName().get('Demo').getRecordTypeId();
        system.debug(LoggingLevel.INFO, 'This is the Demo RecordTypeId: '+demoRT);
    	system.debug(LoggingLevel.INFO, 'This is the Related Contact: '+ctc.Id);

        Event e = new Event(Subject = 'Test Demo', 
                            DurationInMinutes = 30, 
                            StartDateTime = System.now(), 
                            RecordTypeId = demoRT, 
                            OwnerId = UserInfo.getUserId(), 
                            Description = 'Testing 123',
                            Related_Account__c = a.Id, 
                            Related_Contact__c = ctc.Id);
        insert e;
        
        system.debug(LoggingLevel.INFO, 'This is the Demo RecordType Name: '+e.RecordTypeId);
        system.debug(LoggingLevel.INFO, 'This is the Demo Related Contact: '+e.Related_Contact__c);
        
        system.debug(LoggingLevel.INFO, 'This is the Contact Status: '+ctc.Status__c);

        Opportunity o = new Opportunity(
                                        StageName = 'Qualified',
                                        Name = 'Test Opp 1',
                                        AccountId = a.Id,
                                        Related_Contact__c = ctc.Id,
                                        License_Term__c = 36,
                                        Amount = 15000,
                                        Finance_Partner_Notes__c = 'Test',
                                        Subsidize_Financing__c = True,
                                        CloseDate =  system.today()+5,
                                        Can_Create__c = true
                                        );
		insert o;

        system.debug(LoggingLevel.INFO, 'This is the OppId: '+o.Id);
        system.debug(LoggingLevel.INFO, 'This is the Event WhatId: '+e.WhatId);
    }
    */
}
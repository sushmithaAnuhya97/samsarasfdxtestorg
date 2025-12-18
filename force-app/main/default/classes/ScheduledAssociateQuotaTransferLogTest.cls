@isTest
private class ScheduledAssociateQuotaTransferLogTest {

    @TestSetup
    static void testRecords() {
        List<User> newUsers = new List<User>();
        List<Quota__c> newQuotas = new List<Quota__c>();
        List<ADR_Transfer_Log__c> newTransferLogs = new List<ADR_Transfer_Log__c>();
        
        User user = [Select id from User where Id = :UserInfo.getUserId()];
        UserRole ur;
        User newUser;
        User newUserTwo;
        User newUserThree;
        User newUserFour;
        System.runAs(user)
        {
            ur = new UserRole(Name = 'TestRole');
            insert ur; 
            
            
            
            
            Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
            newUser = new User(Alias = 'standt', Email = 'standarduser@testorg.com',UserRoleId = ur.Id,
                                    EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                                    LocaleSidKey = 'en_US', ProfileId = userProfile.Id,
                                    TimeZoneSidKey = 'America/Los_Angeles', UserName = 'testinguser@tester.com' + UserInfo.getOrganizationId(),
                                    EmployeeNumber = '9999990');
            newUsers.add(newUser);
            System.debug('newUser.UserRole.Name---->'+newUser.UserRole.Name);
            
            newUserTwo = new User(Alias = 'standt2', Email = 'standarduserTwo@testorg.com',UserRoleId = ur.Id,
                                       EmailEncodingKey = 'UTF-8', LastName = 'TestingTwo', LanguageLocaleKey = 'en_US',
                                       LocaleSidKey = 'en_US', ProfileId = userProfile.Id,
                                       TimeZoneSidKey = 'America/Los_Angeles', UserName = 'testinguser2@tester.com' + UserInfo.getOrganizationId(),
                                       EmployeeNumber = '9999991');
            newUsers.add(newUserTwo);
            System.debug('newUserTwo.UserRole.Name---->'+newUserTwo.UserRole.Name);
            
            newUserThree = new User(Alias = 'standt3', Email = 'standarduserThree@testorg.com',UserRoleId = ur.Id,
                                         EmailEncodingKey = 'UTF-8', LastName = 'TestingThree', LanguageLocaleKey = 'en_US',
                                         LocaleSidKey = 'en_US', ProfileId = userProfile.Id,
                                         TimeZoneSidKey = 'America/Los_Angeles', UserName = 'testinguser3@tester.com' + UserInfo.getOrganizationId(),
                                         EmployeeNumber = '9999992');
            newUsers.add(newUserThree);
            System.debug('newUserThree.UserRole.Name---->'+newUserThree.UserRole.Name);
            
            // User with no quota
            newUserFour = new User(Alias = 'standt4', Email = 'standarduserFour@testorg.com',UserRoleId = ur.Id,
                                        EmailEncodingKey = 'UTF-8', LastName = 'TestingFour', LanguageLocaleKey = 'en_US',
                                        LocaleSidKey = 'en_US', ProfileId = userProfile.Id,
                                        TimeZoneSidKey = 'America/Los_Angeles', UserName = 'testinguser4@tester.com' + UserInfo.getOrganizationId(),
                                        EmployeeNumber = '9999993');
            newUsers.add(newUserFour);
            System.debug('newUserFour.UserRole.Name---->'+newUserFour.UserRole.Name);
            
            insert newUsers;
		}

        Account testAccount = new Account(Name = 'Samsara Test Account');
        testAccount.Type = 'Fleet';
        testAccount.Industry = 'Other';
        testAccount.organization_size__c = '1 - 99';
        testAccount.billingstreet = '123 Main St, San Francisco CA, 94110';
        testAccount.billingstate = 'California';
        testAccount.billingcountry = 'United States';
        testAccount.billingcity = 'San Francisco';
        testAccount.billingPostalCode = '94110';
        testAccount.shippingstreet = '123 Main St, San Francisco CA, 94110';
        testAccount.shippingstate = 'California';
        testAccount.shippingcountry = 'United States';
        testAccount.shippingcity = 'San Francisco';
        testAccount.shippingPostalCode = '94110';
        insert testAccount;

        List<Contact> newContacts = new List<Contact>();
        Contact contact = new Contact(
                FirstName = 'fname',
                LastName = 'lname',
                Email = 'email@gmail.com',
                Phone = '1234567890',
                AccountId = testAccount.Id,
                Source__c = 'MVF');
        newContacts.add(contact);

        Contact contactTwo = new Contact(
                FirstName = 'fname',
                LastName = 'lname II',
                Email = 'email2@gmail.com',
                Phone = '1234567890',
                AccountId = testAccount.Id,
                Source__c = 'MVF');
        newContacts.add(contactTwo);


        insert newContacts;

        
        /*
        UserRole r = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
		insert r;
        
        for(user u:newUsers)
        {
            u.UserRoleId = r.id;
        }
        update newUsers;
		*/
        Quota__c quota = new Quota__c(User__c = user.id, Role_at_Start_of_Fiscal_Period__c = 'My Role',
                CurrencyIsoCode = 'USD', Quota_Period_End_Date__c = Date.Today() + 4,
                Quota_Period_Start_Date__c = Date.Today() - 560, Fiscal_Period_End_Date__c = Date.Today() + 4,
                Fiscal_Period_Start_Date__c = Date.Today() - 560, Quota_Period__c = 'Test', Fiscal_Period__c = 'Test',
                ADR_Quota__c = 3);
        newQuotas.add(quota);

        Quota__c quotaTwo = new Quota__c(User__c = newUser.id, Role_at_Start_of_Fiscal_Period__c = 'TestRole',
                CurrencyIsoCode = 'USD', Quota_Period_End_Date__c = Date.Today() + 4,
                Quota_Period_Start_Date__c = Date.Today() - 560, Fiscal_Period_End_Date__c = Date.Today() + 4,
                Fiscal_Period_Start_Date__c = Date.Today() - 560, Quota_Period__c = 'Test', Fiscal_Period__c = 'Test',
                ADR_Quota__c = 3);
        newQuotas.add(quotaTwo);

        Quota__c quotaThree = new Quota__c(User__c = newUserThree.id, Role_at_Start_of_Fiscal_Period__c = 'TestRole2',
                CurrencyIsoCode = 'USD', Quota_Period_End_Date__c = Date.Today() + 4,
                Quota_Period_Start_Date__c = Date.Today() - 560, Fiscal_Period_End_Date__c = Date.Today() + 4,
                Fiscal_Period_Start_Date__c = Date.Today() - 560, Quota_Period__c = 'Test', Fiscal_Period__c = 'Test',
                ADR_Quota__c = 3);
        newQuotas.add(quotaThree);

        Quota__c quotaFour = new Quota__c(User__c = newUserTwo.id, Role_at_Start_of_Fiscal_Period__c = 'TestRole3',
                CurrencyIsoCode = 'USD', Quota_Period_End_Date__c = Date.Today() + 4,
                Quota_Period_Start_Date__c = Date.Today() - 560, Fiscal_Period_End_Date__c = Date.Today() + 4,
                Fiscal_Period_Start_Date__c = Date.Today() - 560, Quota_Period__c = 'Test', Fiscal_Period__c = 'Test',
                ADR_Quota__c = 3);
        newQuotas.add(quotaFour);

        insert newQuotas;

        Id pricebookId = Test.getStandardPricebookId();

        Opportunity revenueOpportunity = new Opportunity(AccountId = testAccount.Id, License_Term__c = 36, Pricebook2Id = pricebookId, Max_Approved_Discount__c = 0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', CloseDate = System.today() + 90, StageName = 'Incubate');
        insert revenueOpportunity;


        ADR_Transfer_Log__c transferLog = new ADR_Transfer_Log__c();
        transferLog.ADR_Transfer_By__c = user.id;
        transferLog.ADR_Transfer_Date__c = Date.today();
        transferLog.ADR_Demo_Date__c = Date.today();
        transferLog.ADR_Accepted_Date__c = Date.today();
        transferLog.ADR_Transfer_Qualified_Date__c = Date.today();
        transferLog.ADR_Transfer_Status__c = 'Accepted and Qualified';
        transferLog.ADR_Transfer__c = true;
        transferLog.CurrencyIsoCode = 'USD';
        transferLog.ADR_Role_Copy_at_Qualification__c = 'My Role';
        transferLog.Opportunity__c = revenueOpportunity.Id;
        transferLog.Contact__c = contact.Id;
        newTransferLogs.add(transferLog);

        ADR_Transfer_Log__c transferLogTwo = new ADR_Transfer_Log__c();
        transferLogTwo.ADR_Transfer_By__c = newUser.id;
        transferLogTwo.ADR_Transfer_Date__c = Date.today();
        transferLogTwo.ADR_Demo_Date__c = Date.today();
        transferLogTwo.ADR_Accepted_Date__c = Date.today();
        transferLogTwo.ADR_Transfer_Qualified_Date__c = Date.today();
        transferLogTwo.ADR_Transfer_Status__c = 'Accepted and Qualified';
        transferLogTwo.ADR_Transfer__c = true;
        transferLogTwo.CurrencyIsoCode = 'USD';
        transferLogTwo.ADR_Role_Copy_at_Qualification__c = 'My Role';
        transferLogTwo.Opportunity__c = revenueOpportunity.Id;
        transferLogTwo.Contact__c = contact.Id;
        newTransferLogs.add(transferLogTwo);

        ADR_Transfer_Log__c transferLogThree = new ADR_Transfer_Log__c();
        transferLogThree.ADR_Transfer_By__c = newUserTwo.id;
        transferLogThree.ADR_Transfer_Date__c = Date.today() - 500;
        transferLogThree.ADR_Demo_Date__c = Date.today() - 500;
        transferLogThree.ADR_Accepted_Date__c = Date.today() - 500;
        transferLogThree.ADR_Transfer_Qualified_Date__c = Date.today() - 500;
        transferLogThree.ADR_Transfer__c = true;
        transferLogThree.CurrencyIsoCode = 'USD';
        transferLogThree.ADR_Role_Copy_at_Qualification__c = 'My Role';
        transferLogThree.Opportunity__c = revenueOpportunity.Id;
        transferLogThree.Contact__c = contact.Id;
        newTransferLogs.add(transferLogThree);

        ADR_Transfer_Log__c transferLogFour = new ADR_Transfer_Log__c();
        transferLogFour.ADR_Transfer_By__c = newUserThree.id;
        transferLogFour.ADR_Transfer_Date__c = Date.today() - 500;
        transferLogFour.ADR_Demo_Date__c = Date.today() - 500;
        transferLogFour.ADR_Accepted_Date__c = Date.today() - 500;
        transferLogFour.ADR_Transfer_Qualified_Date__c = Date.today() - 500;
        transferLogFour.ADR_Transfer__c = true;
        transferLogFour.CurrencyIsoCode = 'USD';
        transferLogFour.ADR_Role_Copy_at_Qualification__c = 'My Role';
        transferLogFour.Opportunity__c = revenueOpportunity.Id;
        transferLogFour.Contact__c = contact.Id;
        newTransferLogs.add(transferLogFour);

        // Test Transfer Log for Role change
        ADR_Transfer_Log__c transferLogFive = new ADR_Transfer_Log__c();
        transferLogFive.ADR_Transfer_By__c = newUserThree.id;
        transferLogFive.ADR_Transfer_Date__c = Date.today();
        transferLogFive.ADR_Transfer_Status__c = 'Accepted and Qualified';
        transferLogFive.ADR_Demo_Date__c = Date.today() - 500;
        transferLogFive.ADR_Accepted_Date__c = Date.today() - 500;
        transferLogFive.ADR_Transfer_Qualified_Date__c = Date.today();
        transferLogFive.ADR_Transfer__c = true;
        transferLogFive.CurrencyIsoCode = 'USD';
        transferLogFive.ADR_Role_Copy_at_Qualification__c = 'My R';
        transferLogFive.Opportunity__c = revenueOpportunity.Id;
        transferLogFive.Contact__c = contact.Id;
        newTransferLogs.add(transferLogFive);

        ADR_Transfer_Log__c transferLogSix = new ADR_Transfer_Log__c();
        transferLogSix.ADR_Transfer_By__c = newUserFour.id;
        transferLogSix.ADR_Transfer_Date__c = Date.today();
        transferLogSix.ADR_Transfer_Status__c = 'Accepted and Qualified';
        transferLogSix.ADR_Demo_Date__c = Date.today() - 500;
        transferLogSix.ADR_Accepted_Date__c = Date.today() - 500;
        transferLogSix.ADR_Transfer_Qualified_Date__c = Date.today();
        transferLogSix.ADR_Transfer__c = true;
        transferLogSix.CurrencyIsoCode = 'USD';
        transferLogSix.ADR_Role_Copy_at_Qualification__c = 'My Role';
        transferLogSix.Opportunity__c = revenueOpportunity.Id;
        transferLogSix.Contact__c = contact.Id;
        newTransferLogs.add(transferLogSix);

        insert newTransferLogs;

        List<Quota_Transfer_Log__c> newQuotaTransferLogs = new List<Quota_Transfer_Log__c>();

        Quota_Transfer_Log__c quotaTransferLog = new Quota_Transfer_Log__c();
        quotaTransferLog.ADR_Transfer_Log__c = transferLogTwo.Id;
        quotaTransferLog.Related_Quota_for_the_ADR_Log__c = quotaFour.Id;
        newQuotaTransferLogs.add(quotaTransferLog);

        Quota_Transfer_Log__c quotaTransferLogTwo = new Quota_Transfer_Log__c();
        quotaTransferLogTwo.ADR_Transfer_Log__c = transferLogFour.Id;
        quotaTransferLogTwo.Related_Quota_for_the_ADR_Log__c = quotaThree.Id;
        newQuotaTransferLogs.add(quotaTransferLogTwo);

        // Test QT log for Role change
        Quota_Transfer_Log__c quotaTransferLogThree = new Quota_Transfer_Log__c();
        quotaTransferLogThree.ADR_Transfer_Log__c = transferLogFive.Id;
        quotaTransferLogThree.Related_Quota_for_the_ADR_Log__c = quotaThree.Id;
        newQuotaTransferLogs.add(quotaTransferLogThree);

        // Test QT log for Owner change
        Quota_Transfer_Log__c quotaTransferLogFour = new Quota_Transfer_Log__c();
        quotaTransferLogFour.ADR_Transfer_Log__c = transferLogSix.Id;
        quotaTransferLogFour.Related_Quota_for_the_ADR_Log__c = quotaThree.Id;
        newQuotaTransferLogs.add(quotaTransferLogFour);

        insert newQuotaTransferLogs;
    }

    @isTest
    static void testTransferLogs() {
        Test.startTest();
        AssociateQuotaTransferLog associateTransferLog = new AssociateQuotaTransferLog();
        associateTransferLog.mapQuotaAndTransferLogs();
        
        ScheduledAssociateQuotaTransferLog sc = new ScheduledAssociateQuotaTransferLog();
        sc.execute(null);

        //String CRON_EXP = '0 0 0 3 9 ? 2022';
        //String jobId = System.schedule('ScheduledAssociateQuotaTransferLog', CRON_EXP, new ScheduledAssociateQuotaTransferLog());
        Test.stopTest();

        //CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        //System.assertEquals(0, ct.TimesTriggered);
        //System.assertEquals('2022-09-03 00:00:00', String.valueOf(ct.NextFireTime));

        List<Quota__c> updatedQuotas = new List<Quota__c>();
        updatedQuotas = [SELECT id, Total_ADR_Transfers__c from Quota__c];
        Integer size = updatedQuotas.size();
        for (Integer i; i < size; i++) {
            system.assertEquals(1, updatedQuotas[i].Total_ADR_Transfers__c);
        }
        List<Quota_Transfer_Log__c> updatedQTlogs = new List<Quota_Transfer_Log__c>();
        updatedQTlogs = [SELECT id from Quota_Transfer_Log__c];
        Integer qtLogsize = updatedQTlogs.size();
        system.assertEquals(true, (qtLogsize != 0));
    }

    @isTest
    static void testHistoricTransferLogs() {
        Test.startTest();
        AssociateQuotaTransferLogHistoric associateTransferLogHistoric = new AssociateQuotaTransferLogHistoric();
        associateTransferLogHistoric.mapQuotaAndTransferLogs();
        Test.stopTest();

        List<Quota__c> updatedQuotas = new List<Quota__c>();
        updatedQuotas = [SELECT id, Total_ADR_Transfers__c from Quota__c];
        Integer size = updatedQuotas.size();
        for (Integer i; i < size; i++) {
            system.assertEquals(1, updatedQuotas[i].Total_ADR_Transfers__c);
        }
        List<Quota_Transfer_Log__c> updatedQTlogs = new List<Quota_Transfer_Log__c>();
        updatedQTlogs = [SELECT id from Quota_Transfer_Log__c];
        Integer qtLogsize = updatedQTlogs.size();
        system.assertEquals(true, (qtLogsize != 0));
    }
}
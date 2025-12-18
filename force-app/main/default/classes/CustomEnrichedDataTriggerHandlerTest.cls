@isTest
public class CustomEnrichedDataTriggerHandlerTest {

    @TestSetup
    static void makeData(){
        Set<String> profiles = new Set<String>();
        profiles.add('Sales Ops Profile');
        profiles.add('Marketing User');
        Profile salesOpsProfile;
        Profile marketingProfile;
        for (Profile p : [SELECT Id, Name FROM Profile WHERE Name IN :profiles LIMIT 2]) {
            if(p.Name == 'Sales Ops Profile'){
                salesOpsProfile = p;

            }else {
                marketingProfile = p;
            }
        }

        List<User> users = new List<User>();

        User tempUser = new User(
            FirstName = 'salesOps',
            LastName = 'user',
            email = 'salesOps' + '@testsamsara.org',
            Username = 'salesOps.samsaretest@testsamsara.org',
            EmailEncodingKey = 'ISO-8859-1',
            Alias = 'salesOps',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            EmployeeNumber = '12345',
            ProfileId = salesOpsProfile.Id,
            IsActive = true
        );

        users.add(tempUser);
        User tempUser2 = new User(
            FirstName = 'marketing',
            LastName = 'user',
            email = 'marketing' + '@testsamsara.org',
            Username = 'marketing.samsaretest@testsamsara.org',
            EmailEncodingKey = 'ISO-8859-1',
            Alias = 'salesOps',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            EmployeeNumber = '12348',
            ProfileId = marketingProfile.Id,
            IsActive = true
        );
        users.add(tempUser2);

        insert users;

        System.runAs(tempUser2){
            Account acc = new Account(Name='Test Account', Organization_Size__c='1 - 99', BillingCountry='Belgium', BillingCountryCode = 'BE', Record_Type_Stamp_for_Dupes__c = 'Fleet',Industry = 'Unknown',Enable_Delinquency_Process__c = false, Current_Telematics_Provider__c = 'Azuga', Number_of_Vehicles__c= 101);
            insert acc;
        }
       
    }

    @isTest
    static void testAfterInsertWithSalesOpsProfile() {
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1];
        User u = [SELECT Id FROM User WHERE Username = 'salesOps.samsaretest@testsamsara.org' LIMIT 1];

        System.runAs(u){
            Test.startTest();
            Custom_Enriched_Data__c ced = new Custom_Enriched_Data__c(
                Related_Account__c = acc.Id,
                Source__c = 'RigDig', /** Valid source values for account information (IHS US Fleet List, FMCSA, RigDig, EDA, GovSpend, Leadspace, OSHA, ZoomInfo, D&B Hoovers, Lusha). */
                Sub_Type__c = 'Account Origination' /** Valid subtype values for account information (Website, LinkedIn, Billing Address, NAICS Code, SIC Code, Organization Size, Employee Count, Annual Revenue, Vehicle Validation, Smart Trailer Validation, Powered Connected Equipment Validation, Unpowered Connected Equipment Validation, Citizens Validation, Students Validation, Current Telematics Provider, DUNS Number, US DOT, Phone Number, Estimated Workers, Estimated Drivers, Account Origination, Fortune Ranking, Forbes Global Ranking). */
            );
            insert ced;
            Test.stopTest();
        }
        Account updatedAcc = [SELECT Fleet_Seek_Number__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('RigDig', updatedAcc.Fleet_Seek_Number__c, 'Test case failure.');
    }

    @isTest
    static void testAfterUpdate() {
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1];

        Custom_Enriched_Data__c ced = new Custom_Enriched_Data__c(
            Related_Account__c = acc.Id,
            Source__c = 'RigDig',
            Sub_Type__c = 'Account Origination'
        );
        insert ced;

        Test.startTest();
        ced.Source__c = 'EDA';
        update ced;
        Test.stopTest();

        Account updatedAcc = [SELECT Fleet_Seek_Number__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('EDA', updatedAcc.Fleet_Seek_Number__c, 'Test case failure.');
    }

    @isTest
    static void testAfterDelete() {
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1];

        Custom_Enriched_Data__c ced = new Custom_Enriched_Data__c(
            Related_Account__c = acc.Id,
            Source__c = 'RigDig',
            Sub_Type__c = 'Account Origination'
        );
        insert ced;

        Test.startTest();
        delete ced;
        Test.stopTest();

        Account updatedAcc = [SELECT Fleet_Seek_Number__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(null, updatedAcc.Fleet_Seek_Number__c, 'Test case failure.');
    }

    @isTest
    static void testAfterUndelete() {
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1];

        Custom_Enriched_Data__c ced = new Custom_Enriched_Data__c(
            Related_Account__c = acc.Id,
            Source__c = 'RigDig',
            Sub_Type__c = 'Account Origination'
        );
        insert ced;

        delete ced;

        Test.startTest();
        undelete ced;
        Test.stopTest();

        Account updatedAcc = [SELECT Fleet_Seek_Number__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('RigDig', updatedAcc.Fleet_Seek_Number__c, 'Test case failure.');
    }

    @isTest
    static void testChangeNonAccountOriginationCED() {
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Custom_Enriched_Data__c ced = new Custom_Enriched_Data__c(
            Related_Account__c = acc.Id,
            Source__c = 'RigDig',
            Sub_Type__c = 'Account Origination'
        );
        insert ced;

        Test.startTest();
        ced.Sub_Type__c = 'Billing Address';
        update ced;
        Test.stopTest();

        Account updatedAcc = [SELECT Id, Fleet_Seek_Number__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(null, updatedAcc.Fleet_Seek_Number__c, 'Test case failure.');


    }

    @IsTest
    private static void testUpdateOriginationSourceAccount_SaveResultFailure() {
        // Create test data
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1];

        Custom_Enriched_Data__c ced = new Custom_Enriched_Data__c(
            Related_Account__c = acc.Id,
            Sub_Type__c = 'Account Origination',
            Source__c = 'RigDig'
        );
        
        try {
            Test.startTest();
            CustomEnrichedDataTriggerHelper.IS_MOCK_SOURCE_VALUE = true;
            insert ced;
            Test.stopTest();
            
        } catch (Exception e) {
            System.assert( e.getMessage().contains(System.Label.ADR_Incentive_LWC_Generic_error), 'Expected error on CED record');
        }
    }
}
@isTest
private class GetPSAProjectTest {

    @testSetup
    static void setupTestData() {
        Account testAccount = new Account(
            Name = 'Test Account', 
            Organization_Size__c = '5000+', 
            Industry = 'Retail Trade', 
            Bypass_Validation_Rules__c = TRUE);
        insert testAccount;

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = testAccount.Id
        );
        insert testOpportunity;
        
        pse__Region__c testRegion = new pse__Region__c(
            Name = 'Test Region'
        );
        insert testRegion;
        
        List<pse__Proj__c> projects = new List<pse__Proj__c>();
        for (Integer i = 0; i < 3; i++) {
            projects.add(new pse__Proj__c(
                Name = 'Test Project ' + i,
                pse__Stage__c = 'Discovery',
                Engagement_Type__c = 'Initial Implementation',
                pse__Opportunity__c = testOpportunity.id,
                pse__Account__c = testAccount.id,
                pse__Region__c = testRegion.id,
                pse__Project_Type__c = 'Customer Project',
                BVS_Survey__c = 'Ready to Send',
                TSM_survey__c = 'Ready to Send',
                Services_Survey__c = 'Ready to Send',
                pse__Start_Date__c = Date.today(),
                pse__End_Date__c = Date.today().addDays(10),
                Expected_End_Date__c = Date.today().addDays(10)
            ));
        }
        insert projects;
    }

    private static User createUserWithProfile(Id profileId, String aliasPrefix) {
        String tsStr = DateTime.now().format('yyyyMMddHHmmssSSS');
        String aliasVal = (aliasPrefix != null ? aliasPrefix : 'usr') + '01'; // <= 8 chars
        if (aliasVal.length() > 8) {
            aliasVal = aliasVal.substring(0, 8);
        }
        User u = new User(
            ProfileId = profileId,
            Alias = aliasVal,
            Email = aliasVal + '.' + tsStr + '@example.com',
            Username = aliasVal + '.' + tsStr + '@example.com',
            LastName = 'Test',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            EmployeeNumber = tsStr, // Bamboo HR Id requirement in validation rule
            IsActive = true
        );
        return u;
    }

    @isTest
    static void testMondayGetProjects() {
        Test.startTest();
        GetPSAProject.testClassWeekDay = 'Monday';
        List<pse__Proj__History> results = GetPSAProject.getProjects('Update BVS');
        Test.stopTest();

    }
    
    @isTest
    static void testTuesdayGetProjects() {
        Test.startTest();
        GetPSAProject.testClassWeekDay = 'Tuesday';
        List<pse__Proj__History> results = GetPSAProject.getProjects('Update TSM');
        Test.stopTest();

    }
	@isTest
    static void testWednesdayGetProjects() {
        Test.startTest();
        GetPSAProject.testClassWeekDay = 'Wednesday';
        List<pse__Proj__History> results = GetPSAProject.getProjects('Update Services');
        Test.stopTest();

    }
    @isTest
    static void testThursdayGetProjects() {
        Test.startTest();
        GetPSAProject.testClassWeekDay = 'Thursday';
        List<pse__Proj__History> results = GetPSAProject.getProjects('Update BVS');
        Test.stopTest();

    }
    @isTest
    static void testFridayGetProjects() {
        Test.startTest();
        GetPSAProject.testClassWeekDay = 'Friday';
        List<pse__Proj__History> results = GetPSAProject.getProjects('Update TSM');
        Test.stopTest();

    }
    @isTest
    static void testSaturdayGetProjects() {
        Test.startTest();
        GetPSAProject.testClassWeekDay = 'Saturday';
        List<pse__Proj__History> results = GetPSAProject.getProjects('Update Services');
        Test.stopTest();

    }
    @isTest
    static void testSundayGetProjects() {
        Test.startTest();
        GetPSAProject.testClassWeekDay = 'Sunday';
        List<pse__Proj__History> results = GetPSAProject.getProjects('Update TSM');
        Test.stopTest();

    }

    
    
    @isTest
    static void testUpdateBVSSurvey_BVS() {
        List<pse__Proj__c> projects = [SELECT Id FROM pse__Proj__c LIMIT 2];
        List<Id> ids = new List<Id>();
        for (pse__Proj__c p : projects) {
            ids.add(p.Id);
        }

        // Set fields to satisfy any validations that may restrict BVS updates
        List<pse__Proj__c> prepBvs = [
            SELECT Id, pse__Stage__c, pse__Start_Date__c, pse__End_Date__c, Engagement_Type__c,
                   pse__Credited_Non_Billable_Internal_Hours__c
            FROM pse__Proj__c WHERE Id IN :ids
        ];
        for (pse__Proj__c pr : prepBvs) {
            pr.pse__Stage__c = 'BVS Deliverables Complete';
            pr.pse__Start_Date__c = Date.today().addDays(-10);
            pr.pse__End_Date__c = Date.today().addDays(-1);
            pr.Engagement_Type__c = 'BVS Engagement';
            pr.pse__Credited_Non_Billable_Internal_Hours__c = 6;
        }
        update prepBvs;

        User admin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        // Ensure visibility with sharing by transferring ownership to the runAs user
        List<pse__Proj__c> toReassignBvs = [SELECT Id, OwnerId FROM pse__Proj__c WHERE Id IN :ids];
        for (pse__Proj__c rec : toReassignBvs) { rec.OwnerId = admin.Id; }
        update toReassignBvs;

        System.runAs(admin) {
            Test.startTest();
            GetPSAProject.updateBVSSurvey(ids, 'Survey Sent', 'Update BVS');
            Test.stopTest();

            List<pse__Proj__c> updated = [SELECT BVS_Survey__c FROM pse__Proj__c WHERE Id IN :ids];
            for (pse__Proj__c pr : updated) {
                System.assertEquals('Survey Sent', pr.BVS_Survey__c);
            }
        }
    }

    @isTest
    static void testUpdateBVSSurvey_SSAT() {
        List<pse__Proj__c> projects = [SELECT Id FROM pse__Proj__c LIMIT 2];
        List<Id> ids = new List<Id>();
        for (pse__Proj__c p : projects) {
            ids.add(p.Id);
        }

        // Set fields to satisfy any validations that may restrict Services updates
        List<pse__Proj__c> prepSvc = [
            SELECT Id, pse__Stage__c, pse__Start_Date__c, pse__End_Date__c, Engagement_Type__c
            FROM pse__Proj__c WHERE Id IN :ids
        ];
        for (pse__Proj__c pr : prepSvc) {
            pr.pse__Stage__c = 'Completed';
            pr.pse__Start_Date__c = Date.today().addDays(-10);
            pr.pse__End_Date__c = Date.today().addDays(-1);
            pr.Engagement_Type__c = 'Initial Implementation';
        }
        update prepSvc;

        User admin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        // Ensure visibility with sharing by transferring ownership to the runAs user
        List<pse__Proj__c> toReassignSvc = [SELECT Id, OwnerId FROM pse__Proj__c WHERE Id IN :ids];
        for (pse__Proj__c rec : toReassignSvc) { rec.OwnerId = admin.Id; }
        update toReassignSvc;

        System.runAs(admin) {
            Test.startTest();
            GetPSAProject.updateBVSSurvey(ids, 'Survey Sent', 'Update Services');
            Test.stopTest();

            List<pse__Proj__c> updated = [SELECT Services_Survey__c FROM pse__Proj__c WHERE Id IN :ids];
            for (pse__Proj__c pr : updated) {
                System.assertEquals('Survey Sent', pr.Services_Survey__c);
            }
        }
    }

    @isTest
    static void testUpdateBVSSurvey_TSM() {
        List<pse__Proj__c> projects = [SELECT Id, TSM_survey__c FROM pse__Proj__c LIMIT 2];
        List<Id> ids = new List<Id>();
        for (pse__Proj__c p : projects) {
            ids.add(p.Id);
        }

        // Set fields to satisfy any validations that may restrict TSM updates
        List<pse__Proj__c> prepTsm = [
            SELECT Id, pse__Stage__c, pse__Start_Date__c, pse__End_Date__c, pse__Group__c
            FROM pse__Proj__c WHERE Id IN :ids
        ];
        for (pse__Proj__c pr : prepTsm) {
            pr.pse__Stage__c = 'Completed';
            pr.pse__Start_Date__c = Date.today().addDays(-10);
            pr.pse__End_Date__c = Date.today().addDays(-1);
            // pr.pse__Group__c is a lookup; leave unchanged in tests
            // If your org has TSM attrs/hours fields, set them here as needed
        }
        update prepTsm;

        User admin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        // Ensure visibility with sharing by transferring ownership to the runAs user
        List<pse__Proj__c> toReassignTsm = [SELECT Id, OwnerId FROM pse__Proj__c WHERE Id IN :ids];
        for (pse__Proj__c rec : toReassignTsm) { rec.OwnerId = admin.Id; }
        update toReassignTsm;

        System.runAs(admin) {
            Test.startTest();
            GetPSAProject.updateBVSSurvey(ids, 'Survey Sent', 'Update TSM');
            Test.stopTest();

			// No assertion required for TSM per request
        }
    }

    @isTest
    static void testUpdateBVSSurvey_EarlyReturn() {
        // Empty ids and blank surveyType should trigger early return without error
        List<Id> emptyIds = new List<Id>();

        Test.startTest();
        GetPSAProject.updateBVSSurvey(emptyIds, 'Survey Sent', '');
        Test.stopTest();

        // Verify an arbitrary record remains unchanged for BVS when not included
        pse__Proj__c sample = [SELECT Id, BVS_Survey__c FROM pse__Proj__c LIMIT 1];
        System.assertEquals('Ready to Send', sample.BVS_Survey__c);
    }

    @isTest
    static void testUpdateBVSSurvey_NoChangeBranch_BVS() {
        // Passing selectedSurvey equal to current value should not update
        List<pse__Proj__c> projects = [SELECT Id, BVS_Survey__c FROM pse__Proj__c LIMIT 1];
        List<Id> ids = new List<Id>();
        ids.add(projects[0].Id);

        Test.startTest();
        GetPSAProject.updateBVSSurvey(ids, 'Ready to Send', 'Update BVS');
        Test.stopTest();

        pse__Proj__c after = [SELECT BVS_Survey__c FROM pse__Proj__c WHERE Id = :projects[0].Id];
        System.assertEquals('Ready to Send', after.BVS_Survey__c);
    }
}
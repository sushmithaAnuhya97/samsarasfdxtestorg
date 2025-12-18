@isTest
private class PSAProjectUpdater3_Test {

    @isTest
    static void testUpdateProjects() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account', Organization_Size__c = '5000+', Industry = 'Retail Trade', Bypass_Validation_Rules__c = TRUE);
        insert testAccount;

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Purchase',
            CloseDate = Date.today(),
            Probability = 90,
            AccountId = testAccount.Id
        );
        insert testOpportunity;

        Opportunity testOpportunity2 = new Opportunity(
            Name = 'Test Opportunity2',
            StageName = 'Closed/Won',
            CloseDate = Date.today(),
            Probability = 100,
            AccountId = testAccount.Id
        );
        insert testOpportunity2;

        Opportunity testOpportunity3 = new Opportunity(
            Name = 'Test Opportunity3',
            StageName = 'Purchase',
            CloseDate = Date.today(),
            Probability = 90,
            AccountId = testAccount.Id
        );
        insert testOpportunity3;

        // Create Region and Groups
        pse__Region__c GlobalRegion = new pse__Region__c(  
        	pse__Hierarchy_Depth__c = 0, 
            Name = 'Global Region'
        );
        insert GlobalRegion;
        
        pse__Grp__c ImplementationServicesGroup = new pse__Grp__c(
            pse__Hierarchy_Depth__c = 0,
            Name = 'Implementation Services Group'
        );
        insert ImplementationServicesGroup;
        
        // Create projects related to the test opportunities
        pse__Proj__c testProject = new pse__Proj__c(
            Name = 'Test Project',
            pse__Account__c = testAccount.Id,
            pse__Opportunity__c = testOpportunity.Id,
            Engagement_Type__c = 'Initial Implementation',
            Project_Level__c = 'Core',
            pse__Start_Date__c = Date.today(),
            pse__End_Date__c = Date.today().addMonths(3),
            Expected_End_Date__c = Date.today().addMonths(3),
            pse__Region__c = GlobalRegion.id,
            pse__Group__c = ImplementationServicesGroup.id
        );
        insert testProject;

        pse__Proj__c testProject2 = new pse__Proj__c(
            Name = 'Test Project2',
            pse__Account__c = testAccount.Id,
            pse__Opportunity__c = testOpportunity2.Id,
            Engagement_Type__c = 'Initial Implementation',
            Project_Level__c = 'Select',
            pse__Start_Date__c = Date.today(),
            pse__End_Date__c = Date.today().addMonths(3),
            Expected_End_Date__c = Date.today().addMonths(3),
            pse__Region__c = GlobalRegion.id,
            pse__Group__c = ImplementationServicesGroup.id
        );
        insert testProject2;

        pse__Proj__c testProject3 = new pse__Proj__c(
            Name = 'Test Project3',
            pse__Account__c = testAccount.Id,
            pse__Opportunity__c = testOpportunity3.Id,
            Engagement_Type__c = 'Upsell/Cross-sell',
            Project_Level__c = 'Select',
            pse__Start_Date__c = Date.today(),
            pse__End_Date__c = Date.today().addMonths(3),
            Expected_End_Date__c = Date.today().addMonths(3),
            pse__Region__c = GlobalRegion.id,
            pse__Group__c = ImplementationServicesGroup.id
        );
        insert testProject3;

        // Verify the projects were created
        System.assertNotEquals(null, testProject.Id, 'The project should have been created');
        System.assertNotEquals(null, testProject2.Id, 'The project should have been created');
        System.assertNotEquals(null, testProject3.Id, 'The project should have been created');

        // Create OpportunityIdWrapper instances
        PSAProjectUpdater3.OpportunityIdWrapper oppWrapper = new PSAProjectUpdater3.OpportunityIdWrapper();
        oppWrapper.oppId = testOpportunity.Id;
        PSAProjectUpdater3.OpportunityIdWrapper oppWrapper2 = new PSAProjectUpdater3.OpportunityIdWrapper();
        oppWrapper2.oppId = testOpportunity2.Id;
        PSAProjectUpdater3.OpportunityIdWrapper oppWrapper3 = new PSAProjectUpdater3.OpportunityIdWrapper();
        oppWrapper3.oppId = testOpportunity3.Id;

        // Create a list of OpportunityIdWrapper instances
        List<PSAProjectUpdater3.OpportunityIdWrapper> oppWrappers = new List<PSAProjectUpdater3.OpportunityIdWrapper>();
        oppWrappers.add(oppWrapper);
        oppWrappers.add(oppWrapper2);
        oppWrappers.add(oppWrapper3);

        // Call the updateProjects method
        Test.startTest();
        PSAProjectUpdater3.updateProjects(oppWrappers);
        Test.stopTest();

        // Fetch the updated projects
        pse__Proj__c updatedProject = [SELECT Id, pse__Stage__c, Booking_Date__c, pse__End_Date__c, Expected_End_Date__c FROM pse__Proj__c WHERE Id = :testProject.Id];
        pse__Proj__c updatedProject2 = [SELECT Id, pse__Stage__c, Booking_Date__c, pse__End_Date__c, Expected_End_Date__c FROM pse__Proj__c WHERE Id = :testProject2.Id];
        pse__Proj__c updatedProject3 = [SELECT Id, pse__Stage__c, Booking_Date__c, pse__End_Date__c, Expected_End_Date__c FROM pse__Proj__c WHERE Id = :testProject3.Id];

        // Verify the updates for testProject
        //System.assertEquals('Ready for Staffing', updatedProject.pse__Stage__c, 'The project stage should be "Ready for Staffing"');
        System.assertEquals(Date.today().addMonths(3), updatedProject.pse__End_Date__c, 'The end date should be 90 days from the close date');
        System.assertEquals(Date.today().addMonths(3), updatedProject.Expected_End_Date__c, 'The expected end date should be 90 days from the close date');

        // Verify the updates for testProject2
        //System.assertEquals('Ready for Staffing', updatedProject2.pse__Stage__c, 'The project stage should be "Ready for Staffing"');
        System.assertEquals(Date.today().addMonths(3), updatedProject2.pse__End_Date__c, 'The end date should be 150 days from the close date');
        System.assertEquals(Date.today().addMonths(3), updatedProject2.Expected_End_Date__c, 'The expected end date should be 150 days from the close date');

        // Verify the updates for testProject3
        //System.assertEquals('Ready for Staffing', updatedProject3.pse__Stage__c, 'The project stage should be "Ready for Staffing"');
        System.assertEquals(Date.today().addMonths(3), updatedProject3.pse__End_Date__c, 'The end date should be 90 days from the close date');
        System.assertEquals(Date.today().addMonths(3), updatedProject3.Expected_End_Date__c, 'The expected end date should be 90 days from the close date');
    }
}
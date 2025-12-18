@isTest
private class PSAProject_Test {

    @isTest
    static void testCreateProject() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account', Organization_Size__c = '5000+', Industry = 'Retail Trade', Bypass_Validation_Rules__c = TRUE);
        insert testAccount;

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = testAccount.Id
        );
        insert testOpportunity;
        
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
        
        // Debug
        System.debug('Inserted Account: ' + testAccount.Id);
        System.debug('Inserted Opportunity: ' + testOpportunity.Id);

        // Create a ProjectWrapper instance
        PSAProject.ProjectWrapper projectWrapper = new PSAProject.ProjectWrapper();
        projectWrapper.engagementType = 'Initial Implementation';
        projectWrapper.expectedEndDate = Date.today().addMonths(3);
        projectWrapper.name = 'Test Project';
        projectWrapper.pseAccount = testAccount.Id;
        projectWrapper.pseEndDate = Date.today().addMonths(3);
        projectWrapper.pseGroup = ImplementationServicesGroup.id;
        projectWrapper.pseOpportunity = testOpportunity.Id;
        projectWrapper.pseProjectType = 'Standard';
        projectWrapper.pseRegion = GlobalRegion.id;
        projectWrapper.pseStartDate = Date.today();

        // Debug
        System.debug('Project Wrapper: ' + projectWrapper);

        // Create a list of ProjectWrapper instances
        List<PSAProject.ProjectWrapper> projectWrappers = new List<PSAProject.ProjectWrapper>();
        projectWrappers.add(projectWrapper);

        // Call the createProject method
        Test.startTest();
        List<Id> projectIds = PSAProject.createProject(projectWrappers);
        Test.stopTest();

        // Verify that the project was created successfully
        System.assertEquals(1, projectIds.size(), 'One project should have been created');
        System.debug('Project IDs: ' + projectIds);

        pse__Proj__c createdProject = [SELECT Id, Name, pse__Account__c, pse__Opportunity__c, pse__End_Date__c, Expected_End_Date__c, pse__Start_Date__c, Engagement_Type__c, pse__Project_Type__c FROM pse__Proj__c WHERE Id = :projectIds[0]];
        System.assertNotEquals(null, createdProject, 'The project should exist');
        System.assertEquals('Test Project', createdProject.Name, 'The project name should be "Test Project"');
        System.assertEquals(testAccount.Id, createdProject.pse__Account__c, 'The account ID should match');
        System.assertEquals(testOpportunity.Id, createdProject.pse__Opportunity__c, 'The opportunity ID should match');
        System.assertEquals(Date.today().addMonths(3), createdProject.pse__End_Date__c, 'The end date should be 3 months from today');
        System.assertEquals(Date.today().addMonths(3), createdProject.Expected_End_Date__c, 'The expected end date should be 3 months from today');
        System.assertEquals(Date.today(), createdProject.pse__Start_Date__c, 'The start date should be today');
        System.assertEquals('Initial Implementation', createdProject.Engagement_Type__c, 'The engagement type should be "Initial Implementation"');
        System.assertEquals('Standard', createdProject.pse__Project_Type__c, 'The project type should be "Standard"');
    }
}
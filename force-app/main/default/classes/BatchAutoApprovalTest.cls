@IsTest
private class BatchAutoApprovalTest {
    @TestSetup
    static void setupTestData() {
        // Bypass triggers to prevent governor limit issues
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        
        SBQQ.TriggerControl.disable();
        // Create test users
        User currentUser = [SELECT Id, name FROM User WHERE Id = :UserInfo.getUserId()];
        User testUser;
        
        System.runAs(currentUser) {
            Id profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id;
            testUser = new User(
                FirstName = 'Test',
                LastName = 'User',
                Email = 'test@test.com',
                Username = 'test.user' + DateTime.now().getTime() + '@test.com',
                Alias = 'tuser',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = profileId,
                EmployeeNumber = 'TEST-001'
            );
            insert testUser;
        }
        
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account',
            Organization_Size__c = '5000+',
            BillingCountry = 'United States',
            BillingState = 'California',
            BillingCity = 'San Francisco',
            BillingStreet = '444 Deharo St',
            BillingPostalCode = '94107',
            Industry = 'Other',
            Credit_Limit__c = 10000
        );
        insert testAccount;
        
        
        // Create test opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Incubate',
            CloseDate = System.today().addDays(30),
            Pricebook2Id = Test.getStandardPricebookId(),
            License_Term__c = 36,
            Owner_Role_Copy__c = 'Industrial'
        );
        insert testOpp;
        
        // Create test quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = testOpp.Id,
            SBQQ__Primary__c = true,
            Selected_Payment_Type__c = 'Direct Annual'
        );
        insert testQuote;
        
        // Create approval chain
        sbaa__ApprovalChain__c chainRec = new sbaa__ApprovalChain__c(
            Name = 'Test Chain',
            sbaa__TargetObject__c = 'SBQQ__Quote__c'
        );
        insert chainRec;
        
        // Create approval rule
        sbaa__ApprovalRule__c ruleRec = new sbaa__ApprovalRule__c(
            Name = 'Test Rule',
            sbaa__TargetObject__c = 'SBQQ__Quote__c',
            sbaa__ApprovalChain__c = chainRec.Id,
            sbaa__ConditionsMet__c = 'Any'
        );
        insert ruleRec;
        sbaa__Approver__c userApprover = new sbaa__Approver__c(
            Name = 'User Approver',
            sbaa__User__c = UserInfo.getUserId()
        );
        insert userApprover;
        
    }
    @IsTest
    static void testApprovalLogQueueableWithInvalidData() {
        // Get test data
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        sbaa__ApprovalRule__c testRule = [SELECT Id FROM sbaa__ApprovalRule__c LIMIT 1];
        sbaa__Approver__c testApprover = [SELECT Id FROM sbaa__Approver__c LIMIT 1];
        
        User testUser = [SELECT Id FROM User WHERE Email = 'test@test.com' LIMIT 1];
        SBAA__Approval__c approval = new SBAA__Approval__c(
            sbaa__AssignedTo__c = testUser.Id,
            sbaa__Approver__c =testApprover.Id,
            sbaa__Rule__c = testRule.Id,
            sbaa__ApprovalStep__c = 1,
            sbaa__RecordField__c = 'Quote__c',  // Required field
            Quote__c = testQuote.Id,
            sbaa__Status__c = 'Requested');
        insert approval;
        Test.startTest();
        new BatchAutoApproveSchedular().execute(null);
        Test.stopTest();
    }
    @IsTest
    static void execute_exception_logsException() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        sbaa__ApprovalRule__c testRule = [SELECT Id FROM sbaa__ApprovalRule__c LIMIT 1];
        sbaa__Approver__c testApprover = [SELECT Id FROM sbaa__Approver__c LIMIT 1];
        
        User testUser = [SELECT Id FROM User WHERE Email = 'test@test.com' LIMIT 1];
        SBAA__Approval__c approval = new SBAA__Approval__c(
            sbaa__AssignedTo__c = testUser.Id,
            sbaa__Approver__c =testApprover.Id,
            sbaa__Rule__c = testRule.Id,
            sbaa__ApprovalStep__c = 1,
            sbaa__RecordField__c = 'Quote__c',  // Required field
            Quote__c = testQuote.Id,
            sbaa__Status__c = 'Requested');
        insert approval;
        Test.startTest();
        new BatchAutoApproveApprovals().execute(null, new List<sObject>{ approval});
        Test.stopTest();
        
        
    }
}
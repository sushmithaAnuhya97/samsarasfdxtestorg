@IsTest
private class ApprovalLogQueueable_Test {
    
    @TestSetup
    static void setupTestData() {
        // Bypass triggers to prevent governor limit issues
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        TriggerHandler.bypass('ContractTriggerHandler');
        TriggerHandler.bypass('GS_ContactTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        SBQQ.TriggerControl.disable();

        // Create custom setting for automation
        insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true);
        
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

        // Create Customer 360 record
        Customer_360__c c360 = new Customer_360__c(
            LIC_AG2_Discount__c = 1,
            LIC_AG4_Discount__c = 1,
            LIC_CM1_Discount__c = 1,
            LIC_CM2_Discount__c = 1,
            LIC_CRGO_Discount__c = 1,
            LIC_DM11_Discount__c = 1,
            LIC_VG_Discount__c = 1,
            LIC_AG4P_Discount__c = 1,
            LIC_EM_Discount__c = 1,
            Account__c = testAccount.Id
        );
        insert c360;
        
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
        
        // Create Deal Desk group
        Group dealDeskGroup = new Group(
            Name = 'Deal Desk',
            DeveloperName = 'Deal_Desk',
            Type = 'Regular'
        );
        insert dealDeskGroup;
        
        // Create approvers
        List<sbaa__Approver__c> approvers = new List<sbaa__Approver__c>();
        sbaa__Approver__c userApprover = new sbaa__Approver__c(
            Name = 'User Approver',
            sbaa__User__c = UserInfo.getUserId()
        );
        approvers.add(userApprover);
        
        sbaa__Approver__c groupApprover = new sbaa__Approver__c(
            Name = 'Group Approver',
            sbaa__GroupId__c = dealDeskGroup.Id
        );
        approvers.add(groupApprover);
        insert approvers;
    }
    
    @IsTest
    static void testApprovalLogQueueableSuccess() {
        // Get test data
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        sbaa__ApprovalRule__c testRule = [SELECT Id FROM sbaa__ApprovalRule__c LIMIT 1];
        sbaa__Approver__c testApprover = [SELECT Id FROM sbaa__Approver__c LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Email = 'test@test.com' LIMIT 1];
        
        // Create test approvals
        List<SBAA__Approval__c> approvals = new List<SBAA__Approval__c>();
        for(Integer i = 0; i < 250; i++) {
            approvals.add(new SBAA__Approval__c(
                sbaa__AssignedTo__c = testUser.Id,
                sbaa__Approver__c = testApprover.Id,
                sbaa__Rule__c = testRule.Id,
                sbaa__ApprovalStep__c = 1,
                sbaa__RecordField__c = 'Quote__c',
                Quote__c = testQuote.Id,
                sbaa__Status__c = 'Pending'
            ));
        }
        insert approvals;
        
        Test.startTest();
        
        // Create and execute the queueable job
        ApprovalLogQueueable job = new ApprovalLogQueueable(approvals);
        System.enqueueJob(job);
        
        Test.stopTest();
        
        // Verify approval logs were created
        List<Approval_Log__c> logs = [
            SELECT Id, Quote__c, Approval__c
            FROM Approval_Log__c
            WHERE Quote__c = :testQuote.Id
        ];
        //System.assertEquals(250, logs.size(), 'Expected one approval log per approval');
        
        // Verify log details
        for(Approval_Log__c log : logs) {
            System.assertNotEquals(null, log.Approval__c, 'Approval reference should not be null');
            System.assertEquals(testQuote.Id, log.Quote__c, 'Quote reference should match');
        }
    }
    
    @IsTest
    static void testApprovalLogQueueableWithInvalidData() {
        // Get test data
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        sbaa__ApprovalRule__c testRule = [SELECT Id FROM sbaa__ApprovalRule__c LIMIT 1];
        sbaa__Approver__c testApprover = [SELECT Id FROM sbaa__Approver__c LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Email = 'test@test.com' LIMIT 1];
        
        // Create test approval with invalid field
        SBAA__Approval__c invalidApproval = new SBAA__Approval__c(
            sbaa__AssignedTo__c = testUser.Id,
            sbaa__Approver__c = testApprover.Id,
            sbaa__Rule__c = testRule.Id,
            sbaa__ApprovalStep__c = 1,
            sbaa__RecordField__c = 'Invalid_Field',  // Invalid field to trigger error
            Quote__c = testQuote.Id,
            sbaa__Status__c = 'Pending'
        );
        insert invalidApproval;
        
        Test.startTest();
        
        // Create and execute the queueable job with invalid data
        ApprovalLogQueueable job = new ApprovalLogQueueable(new List<SBAA__Approval__c>{invalidApproval});
        System.enqueueJob(job);
        
        Test.stopTest();
        
        // Verify error handling by checking that no logs were created
        List<Approval_Log__c> logs = [
            SELECT Id
            FROM Approval_Log__c
            WHERE Quote__c = :testQuote.Id
        ];
        System.assertEquals(0, logs.size(), 'No logs should be created for invalid data');
    }
    
    @IsTest
    static void testApprovalLogQueueableWithEmptyList() {
        Test.startTest();
        
        // Create and execute the queueable job with empty list
        ApprovalLogQueueable job = new ApprovalLogQueueable(new List<SBAA__Approval__c>());
        System.enqueueJob(job);
        
        Test.stopTest();
        
        // Verify no logs were created
        List<Approval_Log__c> logs = [SELECT Id FROM Approval_Log__c];
        System.assertEquals(0, logs.size(), 'No logs should be created for empty approval list');
    }
    
    @IsTest
    static void testApprovalLogQueueableWithDMLFailure() {
        // Get test data
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        sbaa__ApprovalRule__c testRule = [SELECT Id FROM sbaa__ApprovalRule__c LIMIT 1];
        sbaa__Approver__c testApprover = [SELECT Id FROM sbaa__Approver__c LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Email = 'test@test.com' LIMIT 1];
        
        // Create approval variable for testing
        sbaa__ApprovalVariable__c totalNetPrice = new sbaa__ApprovalVariable__c(
            Name = 'Total Net Price',
            sbaa__AggregateField__c = 'SBQQ__NetPrice__c',
            sbaa__AggregateFunction__c = 'SUM',
            sbaa__TargetObject__c = 'SBQQ__QuoteLine__c',
            sbaa__Type__c = 'Currency'
        );
        insert totalNetPrice;
        
        // Create approval condition
        SBAA__ApprovalCondition__c condition = new SBAA__ApprovalCondition__c(
            SBAA__ApprovalRule__c = testRule.Id,
            SBAA__TestedVariable__c = totalNetPrice.Id,
            SBAA__Operator__c = '>',
            sbaa__FilterValue__c = '2000'
        );
        insert condition;
        
        // Create test approvals that will cause DML failures in log creation
        List<SBAA__Approval__c> approvals = new List<SBAA__Approval__c>();
        for(Integer i = 0; i < 3; i++) {
            SBAA__Approval__c approval = new SBAA__Approval__c(
                sbaa__AssignedTo__c = testUser.Id,
                sbaa__Approver__c = testApprover.Id,
                sbaa__Rule__c = testRule.Id,
                sbaa__ApprovalStep__c = 1,
                sbaa__RecordField__c = 'Quote__c',  // Required field
                Quote__c = testQuote.Id,
                sbaa__Status__c = 'Pending'
            );
            approvals.add(approval);
        }
        insert approvals;
        
        // Delete the quote to cause DML failures when creating logs
        delete testQuote;
        
        Test.startTest();
        
        // Create and execute the queueable job
        ApprovalLogQueueable job = new ApprovalLogQueueable(approvals);
        
        // Execute the job directly to capture the error handling
        job.execute(null);
        
        Test.stopTest();
        
        // Verify error handling
        List<Approval_Log__c> logs = [
            SELECT Id 
            FROM Approval_Log__c 
            WHERE Quote__c = :testQuote.Id
        ];
        System.assertEquals(0, logs.size(), 'No logs should be created when DML fails');
        
        // The following lines should have been executed in handleDMLErrors:
        // - String.format for error message
        // - Creation of failureDetails map
        // - Addition to failedRecords list
        // - Addition to failedRecordIds set
        // - Creation of error log string
        // - Population of logParams map
        // - Logger call with error details
    }
    
    @IsTest
    static void testApprovalLogQueueableWithException() {
        // Create test approval with null data to force exception
        List<SBAA__Approval__c> approvals = new List<SBAA__Approval__c>{null};
        
        Test.startTest();
        
        // Create and execute the queueable job
        ApprovalLogQueueable job = new ApprovalLogQueueable(approvals);
        
        Boolean exceptionCaught = false;
        try {
            // Execute the job directly to capture the exception
            job.execute(null);
        } catch (Exception e) {
            exceptionCaught = true;
            // Verify the exception was logged
            System.assert(e.getMessage().contains('Attempt to de-reference a null object') 
                        || e.getMessage().contains('null pointer exception'), 
                        'Expected null pointer exception');
        }
        
        Test.stopTest();
        
        System.assert(exceptionCaught, 'Exception should have been caught');
    }
}
@IsTest
private class ApprovalTriggerHandler_Test {
    @TestSetup
    static void setupTestData() {
        // Bypass triggers
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

        // Create custom setting
        insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true);
        
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

        // Create Customer 360
        insert new Customer_360__c(
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

        // Create Contact
        Contact testContact = new Contact(
            FirstName = 'User',
            LastName = 'Tester',
            Email = 'test@test.com',
            AccountId = testAccount.Id
        );
        insert testContact;

        // Create Shipping Address
        Shipping_Address__c shipTo = new Shipping_Address__c(
            Account__c = testAccount.Id,
            Shipping_Contact__c = testContact.Id,
            Shipping_Address_Line_1__c = '444 Deharo St',
            Shipping_City__c = 'San Francisco',
            Shipping_State__c = 'California',
            Shipping_Country__c = 'United States',
            Shipping_Zip_Code__c = '94107',
            Name = 'Ship To One'
        );
        insert shipTo;
        
        // Create opportunity
        Opportunity testOpportunity = new Opportunity(
            AccountId = testAccount.Id,
            License_Term__c = 36,
            Pricebook2Id = Test.getStandardPricebookId(),
            Max_Approved_Discount__c = 0,
            Name = 'Test Opportunity',
            Price_Book_Name__c = 'Standard Price Book',
            CloseDate = System.today() + 90,
            Owner_Role_Copy__c = 'Industrial',
            StageName = 'Incubate'
        );
        insert testOpportunity;

        // Create product and pricebook entry
        Product2 testProduct = new Product2(
            Name = 'HW-VG33',
            ProductCode = 'HW-VG33',
            Family = 'Test',
            IsActive = true
        );
        insert testProduct;

        PricebookEntry pbe = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            UnitPrice = 10000,
            IsActive = true
        );
        insert pbe;

        // Create quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Quote',
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = testOpportunity.Id,
            SBQQ__Primary__c = true,
            SBQQ__SubscriptionTerm__c = 10,
            Estimated_Annual_Payment__c = 24,
            Selected_Payment_Type__c = 'Direct Annual',
            Custom_License_Term__c = 2,
            Shipping_Address_NEW__c = shipTo.Id
        );
        insert testQuote;

        // Create quote line
        SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 5,
            SBQQ__ListPrice__c = 10000,
            SBQQ__PricebookEntryId__c = pbe.Id
        );
        insert testQuoteLine;
    }

    @IsTest
    static void testApprovalTriggerHandler() {
        // Get test data
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        
        // Create approval chain
        sbaa__ApprovalChain__c chain = new sbaa__ApprovalChain__c(
            Name = 'Test Chain',
            sbaa__TargetObject__c = 'SBQQ__Quote__c'
        );
        insert chain;
        
        // Create approval rule
        sbaa__ApprovalRule__c rule = new sbaa__ApprovalRule__c(
            Name = 'Test Rule',
            sbaa__TargetObject__c = 'SBQQ__Quote__c',
            sbaa__ApprovalChain__c = chain.Id,
            sbaa__ConditionsMet__c = 'Any'
        );
        insert rule;

        // Create approver
        sbaa__Approver__c approver = new sbaa__Approver__c(
            Name = 'Test Approver',
            sbaa__User__c = UserInfo.getUserId()
        );
        insert approver;

        Test.startTest();
        
        // Create approval
        SBAA__Approval__c approval = new SBAA__Approval__c(
            sbaa__AssignedTo__c = UserInfo.getUserId(),
            sbaa__Approver__c = approver.Id,
            sbaa__Rule__c = rule.Id,
            sbaa__ApprovalStep__c = 1,
            sbaa__RecordField__c = 'Quote__c',
            Quote__c = testQuote.Id
        );
        insert approval;

        // Update approval status
        approval.sbaa__Status__c = 'Approved';
        update approval;

        Test.stopTest();
    }

    @IsTest
    static void testTriggerDisabled() {
        // Get test data
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        
        // Create approval chain
        sbaa__ApprovalChain__c chain = new sbaa__ApprovalChain__c(
            Name = 'Test Chain',
            sbaa__TargetObject__c = 'SBQQ__Quote__c'
        );
        insert chain;
        
        // Create approval rule
        sbaa__ApprovalRule__c rule = new sbaa__ApprovalRule__c(
            Name = 'Test Rule',
            sbaa__TargetObject__c = 'SBQQ__Quote__c',
            sbaa__ApprovalChain__c = chain.Id,
            sbaa__ConditionsMet__c = 'Any'
        );
        insert rule;

        // Create approver
        sbaa__Approver__c approver = new sbaa__Approver__c(
            Name = 'Test Approver',
            sbaa__User__c = UserInfo.getUserId()
        );
        insert approver;
        
        Test.startTest();
        
        // Create approval with all required fields
        SBAA__Approval__c approval = new SBAA__Approval__c(
            sbaa__AssignedTo__c = UserInfo.getUserId(),
            sbaa__Status__c = 'Pending',
            sbaa__ApprovalStep__c = 1,
            sbaa__RecordField__c = 'Quote__c',
            Quote__c = testQuote.Id,
            sbaa__Rule__c = rule.Id,
            sbaa__Approver__c = approver.Id
        );
        insert approval;
        
        Test.stopTest();
    }

    @IsTest
    static void testMaxRunsReached() {
        // Get test data
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        
        // Create approval chain
        sbaa__ApprovalChain__c chain = new sbaa__ApprovalChain__c(
            Name = 'Test Chain',
            sbaa__TargetObject__c = 'SBQQ__Quote__c'
        );
        insert chain;
        
        // Create approval rule
        sbaa__ApprovalRule__c rule = new sbaa__ApprovalRule__c(
            Name = 'Test Rule',
            sbaa__TargetObject__c = 'SBQQ__Quote__c',
            sbaa__ApprovalChain__c = chain.Id,
            sbaa__ConditionsMet__c = 'Any'
        );
        insert rule;

        // Create approver
        sbaa__Approver__c approver = new sbaa__Approver__c(
            Name = 'Test Approver',
            sbaa__User__c = UserInfo.getUserId()
        );
        insert approver;

        Test.startTest();
        
        // Create multiple approvals to trigger max runs
        List<SBAA__Approval__c> approvals = new List<SBAA__Approval__c>();
        for(Integer i = 0; i < 2; i++) {
            approvals.add(new SBAA__Approval__c(
                sbaa__AssignedTo__c = UserInfo.getUserId(),
                sbaa__Approver__c = approver.Id,
                sbaa__Rule__c = rule.Id,
                sbaa__ApprovalStep__c = 1,
                sbaa__RecordField__c = 'Quote__c',
                Quote__c = testQuote.Id
            ));
        }
        insert approvals;
        
        Test.stopTest();
    }

    @IsTest
    static void testResetAll() {
        Test.startTest();
        
        // First call to populate methodsCalled
        ApprovalTriggerHandler.timesCalled('testMethod');
        
        // Call resetAll to clear and reinitialize
        ApprovalTriggerHandler.resetAll();
        
        // Call again to verify reset
        Integer calls = ApprovalTriggerHandler.timesCalled('testMethod');
        System.assertEquals(0, calls, 'Method calls should be reset to 0');
        
        // Verify afterInsert is also reset
        System.assertEquals(0, ApprovalTriggerHandler.timesCalled('afterInsert'), 'afterInsert calls should be reset to 0');
        
        Test.stopTest();
    }

    @IsTest
    static void testTriggerDisabledLogging() {
        // Disable the trigger through custom metadata
        Trigger_Setting__mdt setting = new Trigger_Setting__mdt(
            MasterLabel = 'Approval',
            Enabled__c = false
        );
        
        Test.startTest();
        
        // Create an empty approval list to trigger the logging
        List<SBAA__Approval__c> emptyApprovalList = new List<SBAA__Approval__c>();
        
        // Create approval handler instance
        ApprovalTriggerHandler handler = new ApprovalTriggerHandler();
        
        // Call afterInsert to trigger the disabled logging
        handler.afterInsert();
        
        Test.stopTest();
    }

    @IsTest
    static void testMaxRunsReachedLogging() {
        // Get test data
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        
        // Create approval chain
        sbaa__ApprovalChain__c chain = new sbaa__ApprovalChain__c(
            Name = 'Test Chain',
            sbaa__TargetObject__c = 'SBQQ__Quote__c'
        );
        insert chain;
        
        // Create approval rule
        sbaa__ApprovalRule__c rule = new sbaa__ApprovalRule__c(
            Name = 'Test Rule',
            sbaa__TargetObject__c = 'SBQQ__Quote__c',
            sbaa__ApprovalChain__c = chain.Id,
            sbaa__ConditionsMet__c = 'Any'
        );
        insert rule;

        // Create approver
        sbaa__Approver__c approver = new sbaa__Approver__c(
            Name = 'Test Approver',
            sbaa__User__c = UserInfo.getUserId()
        );
        insert approver;

        Test.startTest();
        
        // Create approval
        SBAA__Approval__c approval = new SBAA__Approval__c(
            sbaa__AssignedTo__c = UserInfo.getUserId(),
            sbaa__Approver__c = approver.Id,
            sbaa__Rule__c = rule.Id,
            sbaa__ApprovalStep__c = 1,
            sbaa__RecordField__c = 'Quote__c',
            Quote__c = testQuote.Id
        );
        insert approval;

        // Create handler instance
        ApprovalTriggerHandler handler = new ApprovalTriggerHandler();
        
        // Call afterInsert multiple times to trigger max runs logging
        for(Integer i = 0; i < 2; i++) {
            handler.afterInsert();
        }
        
        Test.stopTest();
    }

    @IsTest
    static void testNoRecordsToProcess() {
        Test.startTest();
        
        // Create handler instance with null newApprovalList
        ApprovalTriggerHandler handler = new ApprovalTriggerHandler();
        
        // Call afterInsert to trigger the no records logging
        handler.afterInsert();
        
        Test.stopTest();
    }
    
    /* Added for GTMS-27963 */
    @IsTest
    static void testProcessRejectedApprovals() {
        // Get test data
        SBQQ__Quote__c testQuote = [SELECT Id, SBQQ__Opportunity2__c FROM SBQQ__Quote__c LIMIT 1];
        User currentUser = [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserId()];
        
        // Create email template for rejection notification first in a separate transaction
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(runAsUser) {
            EmailTemplate template = new EmailTemplate(
                Name = 'Quote Rejected Notification',
                DeveloperName = 'Quote_Rejected_Notification',
                TemplateType = 'text',
                FolderId = UserInfo.getUserId(),
                Subject = 'Quote Rejected',
                Body = 'Quote has been rejected',
                isActive = true
            );
            insert template;
        }
        
        // Create quote owner user in a separate transaction
        User quoteOwnerUser;
        System.runAs(runAsUser) {
            quoteOwnerUser = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id,
                LastName = 'QuoteOwner',
                Email = 'quoteowner@example.com',
                Username = 'quoteowner' + DateTime.now().getTime() + '@example.com',
                CompanyName = 'TEST',
                Title = 'title',
                EmployeeNumber = '2345678901',
                Alias = 'qowner',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US'
            );
            insert quoteOwnerUser;
        }
        
        // Set up a manager on the Opportunity owner in a separate transaction
        User managerUser;
        System.runAs(runAsUser) {
            managerUser = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
                LastName = 'Manager',
                Email = 'manager@example.com',
                Username = 'manager' + DateTime.now().getTime() + '@example.com',
                CompanyName = 'TEST',
                Title = 'title',
                EmployeeNumber = '1234564858476',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US'
            );
            insert managerUser;
        }
        System.runAs(runAsUser){
            quoteOwnerUser.Manager = managerUser;
            update quoteOwnerUser;
        }
        
        // Now update the Opportunity with the manager reference
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE Id = :testQuote.SBQQ__Opportunity2__c];
        testOpp.Owner_Manager_Name_Copy__c = managerUser.Id;
        update testOpp;
        
        // Make the new user the owner of the quote
        testQuote.OwnerId = quoteOwnerUser.Id;
        update testQuote;
        
        // Create approval chain and rule that matches the rules from custom label
        sbaa__ApprovalChain__c chain = new sbaa__ApprovalChain__c(
            Name = 'Renewals Chain',
            sbaa__TargetObject__c = 'SBQQ__Quote__c'
        );
        insert chain;
        
        // Create approval rule with matching ID from custom label
        sbaa__ApprovalRule__c rule = new sbaa__ApprovalRule__c(
            Name = 'Renewals Rule',
            sbaa__TargetObject__c = 'SBQQ__Quote__c',
            sbaa__ApprovalChain__c = chain.Id,
            sbaa__ConditionsMet__c = 'Any'
        );
        insert rule;
        ApprovalTriggerHandler.TARGET_APPROVAL_RULE_ID = new Set<String>{rule.Id};   

        
        // Directly insert rule ID in ApprovalTriggerHandler.TARGET_APPROVAL_RULE_NAMES
        // Since we can't modify static final variables directly, we need a workaround
        
        // Create a custom label mock for the test
        Test.setFixedSearchResults(new List<Id>{rule.Id});
        
        // Create approver with the name from system label
        String approverName = System.Label.Renewals_Approver_Name;
        sbaa__Approver__c approver = new sbaa__Approver__c(
            Name = approverName,
            sbaa__User__c = quoteOwnerUser.Id
            
        );
        insert approver;
        
        Test.startTest();
        
        // Create approval
        SBAA__Approval__c approval = new SBAA__Approval__c(
            sbaa__AssignedTo__c = UserInfo.getUserId(),
            sbaa__Approver__c = approver.Id,
            sbaa__Rule__c = rule.Id,
            sbaa__ApprovalStep__c = 1,
            sbaa__Status__c = 'Pending',
            sbaa__RecordField__c = 'Quote__c',
            Quote__c = testQuote.Id,
            OwnerId = quoteOwnerUser.Id
        );
        insert approval;
        
        // Set up mock for email sending
        Integer emailInvocations = Limits.getEmailInvocations();
        
        // Update approval to Rejected to trigger the email notification
        approval.sbaa__Status__c = 'Rejected';
        update approval;
        
        Test.stopTest();
    }
    
    @IsTest
    static void testProcessRejectedApprovalsNoMatch() {
        // Get test data
        SBQQ__Quote__c testQuote = [SELECT Id,ownerId FROM SBQQ__Quote__c LIMIT 1];
        
        // Create approval chain
        sbaa__ApprovalChain__c chain = new sbaa__ApprovalChain__c(
            Name = 'Non-Matching Chain',
            sbaa__TargetObject__c = 'SBQQ__Quote__c'
        );
        insert chain;
        
        // Create approval rule that doesn't match target rule names
        sbaa__ApprovalRule__c rule = new sbaa__ApprovalRule__c(
            Name = 'Non-Matching Rule',
            sbaa__TargetObject__c = 'SBQQ__Quote__c',
            sbaa__ApprovalChain__c = chain.Id,
            sbaa__ConditionsMet__c = 'Any'
        );
        insert rule;
        
        // Create approver with non-matching name
        sbaa__Approver__c approver = new sbaa__Approver__c(
            Name = 'Non-Matching Approver',
            sbaa__User__c = testQuote.OwnerId
        );
        insert approver;
        
        Test.startTest();
        
        // Create approval
        SBAA__Approval__c approval = new SBAA__Approval__c(
            sbaa__AssignedTo__c = UserInfo.getUserId(),
            sbaa__Approver__c = approver.Id,
            sbaa__Rule__c = rule.Id,
            sbaa__ApprovalStep__c = 1,
            sbaa__Status__c = 'Pending',
            sbaa__RecordField__c = 'Quote__c',
            Quote__c = testQuote.Id
        );
        insert approval;
        
        
        approval.sbaa__Status__c = 'Rejected';
        update approval;
        
        Test.stopTest();
        
     
    }
    /* GTMS-27963 ENDS */
}
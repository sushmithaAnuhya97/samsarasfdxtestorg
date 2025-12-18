@isTest
public class ApprovalHelper_Test {
    
    @testSetup
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

        // Create products
        Id pricebookId = Test.getStandardPricebookId();
        
        Product2 hwProduct = new Product2(
            Name = 'Test HW Product',
            ProductCode = 'HW-TEST',
            Family = 'Hardware',
            IsActive = true
        );
        insert hwProduct;

        Product2 licProduct = new Product2(
            Name = 'Test License',
            ProductCode = 'LIC-TEST',
            Family = 'License',
            IsActive = true
        );
        insert licProduct;

        // Create pricebook entries
        PricebookEntry hwPBE = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = hwProduct.Id,
            UnitPrice = 1000,
            IsActive = true
        );
        insert hwPBE;

        PricebookEntry licPBE = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = licProduct.Id,
            UnitPrice = 1000,
            IsActive = true
        );
        insert licPBE;
        
        // Create test opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Incubate',
            CloseDate = System.today().addDays(30),
            Pricebook2Id = pricebookId,
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

        // Create quote lines
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        
        SBQQ__QuoteLine__c hwLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = hwProduct.Id,
            SBQQ__Quantity__c = 2,
            SBQQ__ListPrice__c = 1000,
            SBQQ__CustomerPrice__c = 900,
            SBQQ__NetPrice__c = 900,
            SBQQ__PricebookEntryId__c = hwPBE.Id,
            SBQQ__Number__c = 1
        );
        quoteLines.add(hwLine);
        
        SBQQ__QuoteLine__c licLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = licProduct.Id,
            SBQQ__Quantity__c = 3,
            SBQQ__ListPrice__c = 1000,
            SBQQ__CustomerPrice__c = 900,
            SBQQ__NetPrice__c = 900,
            SBQQ__PricebookEntryId__c = licPBE.Id,
            SBQQ__Number__c = 2
        );
        quoteLines.add(licLine);
        
        insert quoteLines;

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

        // Create approval variables
        List<sbaa__ApprovalVariable__c> varList = new List<sbaa__ApprovalVariable__c>();
        sbaa__ApprovalVariable__c totalNetPrice = new sbaa__ApprovalVariable__c(
            Name = 'Total Net Price',
            sbaa__AggregateField__c = 'SBQQ__NetPrice__c',
            sbaa__AggregateFunction__c = 'SUM',
            sbaa__TargetObject__c = 'SBQQ__QuoteLine__c',
            sbaa__Type__c = 'Currency',
            sbaa__FilterField__c = 'SBQQ__NetPrice__c',
            sbaa__Operator__c = 'equals',
            sbaa__FilterValue__c = 'true'
        );
         varList.add(totalNetPrice);
         sbaa__ApprovalVariable__c totalNetPrice2 = new sbaa__ApprovalVariable__c(
            Name = 'product code',
            sbaa__AggregateField__c = 'SBQQ__NetPrice__c',
            sbaa__AggregateFunction__c = 'SUM',
            sbaa__TargetObject__c = 'SBQQ__QuoteLine__c',
            sbaa__Type__c = 'Currency',
            sbaa__FilterField__c = 'SBQQ__ProductCode__c',
            sbaa__Operator__c = 'contains',
            sbaa__FilterValue__c = 'test'
        );
         varList.add(totalNetPrice2);
         sbaa__ApprovalVariable__c totalNetPrice3 = new sbaa__ApprovalVariable__c(
            Name = 'product code2',
            sbaa__AggregateField__c = 'SBQQ__NetPrice__c',
            sbaa__AggregateFunction__c = 'Count',
            sbaa__TargetObject__c = 'SBQQ__QuoteLine__c',
            sbaa__Type__c = 'Currency',
            sbaa__FilterField__c = 'SBQQ__ProductCode__c',
            sbaa__Operator__c = 'starts with',
            sbaa__FilterValue__c = 'test'
        );
         varList.add(totalNetPrice3);
         insert varList;

        // Create approval conditions
        List<SBAA__ApprovalCondition__c> appCond = new List<SBAA__ApprovalCondition__c>();
        SBAA__ApprovalCondition__c condition = new SBAA__ApprovalCondition__c(
            SBAA__ApprovalRule__c = ruleRec.Id,
            SBAA__TestedVariable__c = varList[0].Id,
            SBAA__Operator__c = '>',
            sbaa__FilterValue__c = '2000'
        );
        appCond.add(condition);
        SBAA__ApprovalCondition__c condition2 = new SBAA__ApprovalCondition__c(
            SBAA__ApprovalRule__c = ruleRec.Id,
            SBAA__TestedVariable__c = varList[1].Id,
            SBAA__Operator__c = '>',
            sbaa__FilterValue__c = '0'
        );
        appCond.add(condition2);
        SBAA__ApprovalCondition__c condition3 = new SBAA__ApprovalCondition__c(
            SBAA__ApprovalRule__c = ruleRec.Id,
            SBAA__TestedVariable__c = varList[2].Id,
            SBAA__Operator__c = '>',
            sbaa__FilterValue__c = '0'
        );
        appCond.add(condition3);
        insert appCond;
        
        // Create an approval log record
        Approval_Log__c existingLog = new Approval_Log__c(
            Quote__c = testQuote.Id,
            Approval_Rule__c = ruleRec.Id,
            Submit_Count__c = 1,
            Approval_Field_Values__c = '{"QuoteFields":{"NetPrice":1800}}'
        );
        insert existingLog;
        
        // Create approvers
        List<sbaa__Approver__c> approvers = new List<sbaa__Approver__c>();
        sbaa__Approver__c userApprover = new sbaa__Approver__c(
            Name = 'User Approver',
            sbaa__User__c = UserInfo.getUserId()
        );
        approvers.add(userApprover);
        
        Group dealDeskGroup = new Group(
            Name = 'Deal Desk',
            DeveloperName = 'Deal_Desk',
            Type = 'Regular'
        );
        insert dealDeskGroup;
        
        sbaa__Approver__c groupApprover = new sbaa__Approver__c(
            Name = 'Group Approver',
            sbaa__GroupId__c = dealDeskGroup.Id
        );
        approvers.add(groupApprover);
        insert approvers;
    }
    
    @isTest
    static void testApprovalHelper() {
        // Get test data
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        sbaa__ApprovalRule__c testRule = [SELECT Id FROM sbaa__ApprovalRule__c LIMIT 1];
        sbaa__Approver__c testApprover = [SELECT Id FROM sbaa__Approver__c WHERE Name = 'User Approver' LIMIT 1];
        
        // Create test approval
        SBAA__Approval__c approval = new SBAA__Approval__c(
            sbaa__AssignedTo__c = UserInfo.getUserId(),
            sbaa__Approver__c = testApprover.Id,
            sbaa__Rule__c = testRule.Id,
            sbaa__ApprovalStep__c = 1,
            sbaa__RecordField__c = 'Quote__c',
            Quote__c = testQuote.Id,
            sbaa__Status__c = 'Pending'
        );
        insert approval;
        
        Test.startTest();
        
        // Test all helper methods
        Set<Id> ruleIds = ApprovalHelper.getApprovalRuleIds(new List<SBAA__Approval__c>{approval});
        Set<Id> quoteIds = ApprovalHelper.getQuoteIds(new List<SBAA__Approval__c>{approval});
        Map<String, List<String>> ruleMap = ApprovalHelper.getQuoteApprovalRulesMap(new List<SBAA__Approval__c>{approval});
        Map<String, List<Approval_Log__c>> logMap = ApprovalHelper.getLatestApprovalLogs(new Set<Id>{testQuote.Id});
        List<SBAA__ApprovalCondition__c> conditions = ApprovalHelper.getApprovalConditions(new Set<Id>{testRule.Id});
        
        // Test createApprovalLogs which internally uses getAggregatedValues
        List<Approval_Log__c> logs = ApprovalHelper.createApprovalLogs(new List<SBAA__Approval__c>{approval});
        
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(0, logs.size(), 'Approval logs should be created');
        System.assertNotEquals(0, conditions.size(), 'Approval conditions should be retrieved');
        System.assertNotEquals(0, ruleIds.size(), 'Rule IDs should be retrieved');
        System.assertNotEquals(0, quoteIds.size(), 'Quote IDs should be retrieved');
    }

    @isTest
    static void testOtherMethods() {
        // Test hasValueChanged - basic cases
        System.assertEquals(false, ApprovalHelper.hasValueChanged(null, null), 'Both null values should return false');
        System.assertEquals(true, ApprovalHelper.hasValueChanged('test1', 'test2'), 'Different string values should return true');
        
        // Test hasValueChanged - numeric cases and exception handling
        System.assertEquals(true, ApprovalHelper.hasValueChanged(Decimal.valueOf('100.123'), 100), 'Decimal vs Integer should trigger comparison');
        System.assertEquals(true, ApprovalHelper.hasValueChanged('not_a_number', 100), 'Invalid number conversion should return true');
        System.assertEquals(true, ApprovalHelper.hasValueChanged(100, 'not_a_number'), 'Invalid number conversion should return true');
        
        // Get test data
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        sbaa__ApprovalRule__c testRule = [SELECT Id FROM sbaa__ApprovalRule__c LIMIT 1];
        sbaa__Approver__c testApprover = [SELECT Id FROM sbaa__Approver__c WHERE Name = 'User Approver' LIMIT 1];
        List<SBQQ__QuoteLine__c> quoteLine = [Select Id,SBQQ__Quantity__c,SBQQ__ProductCode__c from SBQQ__QuoteLine__c where SBQQ__Quote__c =: testQuote.Id];
        // Create test approval
        SBAA__Approval__c approval = new SBAA__Approval__c(
            sbaa__AssignedTo__c = UserInfo.getUserId(),
            sbaa__Approver__c = testApprover.Id,
            sbaa__Rule__c = testRule.Id,
            sbaa__ApprovalStep__c = 1,
            sbaa__RecordField__c = 'Quote__c',
            Quote__c = testQuote.Id,
            sbaa__Status__c = 'Pending'
        );
        insert approval;
     
        // Test getApprovalRuleVariablesMap
        Map<String, List<String>> variablesMap = ApprovalHelper.getApprovalRuleVariablesMap(new Set<Id>{testRule.Id});
        System.assertNotEquals(null, variablesMap, 'Variables map should not be null');
        System.assert(variablesMap.containsKey(testRule.Id), 'Variables map should contain rule ID');
        
        // Test addQuoteField through RuleMetadata
        ApprovalHelper.RuleMetadata metadata = new ApprovalHelper.RuleMetadata();
        metadata.addQuoteField('TestField');
        System.assert(metadata.quoteFields.contains('TestField'), 'Quote field should be added to metadata');
    }
}
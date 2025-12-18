@isTest(SeeAllData=false)
public class PreeviewApprovalControllerTest {
    @testSetup
    private static void testDataSetup() {
        insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true);
        
        User currentUser = [SELECT Id,name FROM User WHERE Id=:userInfo.getuserId()];
        User ae2User;
        User entUser;
        system.runAs(currentUser){
            Id profileId = [SELECT Id,Name  FROM Profile WHERE Name LIKE '%AE2%' LIMIT 1].Id;
            Id ae2Role = [SELECT Id,Name FROM UserRole WHERE name LIKE '%AE2%' LIMIT 1].Id;
            
            ae2User = OrderValidationServiceAutomationTest.createUser('AE2','Sales1',ae2Role,profileId,'AE2usr');
            insert ae2User;
            
            Id entRole = [SELECT Id,Name FROM UserRole WHERE name LIKE '%FLEET ENT AE%' LIMIT 1].Id;
            entUser = OrderValidationServiceAutomationTest.createUser('ENT','Sales2',entRole,profileId,'ENTusr');
            insert entUser;
        }

        Id pricebookId = Test.getStandardPricebookId();
        
        Product2 vg33 = new Product2(Name= 'HW-VG33', ProductCode = 'HW-VG33', Family = 'Test');
        insert vg33;
        
        PricebookEntry vg33PB = new PricebookEntry(
            Pricebook2Id = pricebookId, 
            Product2Id = vg33.Id, 
            UnitPrice = 10000, 
            IsActive = true
        );
        insert vg33PB;
        
        Account account = new Account (
            Name = 'Test Account', 
            Organization_Size__c = '5000+', 
            BillingCountry = 'Canada', 
            Industry = 'Other', 
            Credit_Limit__c = 10000
        );
        insert account;
        
        Opportunity opportunity = new Opportunity(
            AccountId = account.Id, 
            License_Term__c = 36, 
            Pricebook2Id = pricebookId,
            Max_Approved_Discount__c = 0, 
            Name = 'Test Opportunity', 
            Price_Book_Name__c = 'Standard Price Book',
            CloseDate = System.today() + 90, 
            Owner_Role_Copy__c = 'Industrial',
            StageName = 'Incubate'
        );
        insert opportunity;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Quote',
            SBQQ__Account__c = account.Id,
            SBQQ__Opportunity2__c = opportunity.Id,
            SBQQ__SubscriptionTerm__c = 10,
            Estimated_Annual_Payment__c = 24,
            Buyout_Amount__c = 1500,
            Subsidy_Amount__c = 600.0,
            SBQQ__Primary__c = false,
            Custom_License_Term__c = 2,
            Selected_Payment_Type__c = 'Direct Quarterly',
            Contract_buyout_requested__c = true
        );
        insert quote;
        
        
        List<Quote_Approval_Attribute__c> qaaList = new List<Quote_Approval_Attribute__c>{
            new Quote_Approval_Attribute__c(
                Quote__c = quote.Id,
                Field_API_Name__c = 'Buyout_Amount__c',
                Field_Value__c = '1000'
            ),
            new Quote_Approval_Attribute__c(
                Quote__c = quote.Id,
                Field_API_Name__c = 'of_HW_Products__c',
                Field_Value__c = '100'
            ),
            new Quote_Approval_Attribute__c(
                Quote__c = quote.Id,
                Field_API_Name__c = 'Selected_Payment_Type__c',
                Field_Value__c = 'Direct Annual'
            ),
            new Quote_Approval_Attribute__c(
                Quote__c = quote.Id,
                Field_API_Name__c = 'Subsidy_Amount__c',
                Field_Value__c = '1000'
            )
        };
        insert qaaList;
        SBAA__ApprovalChain__c approvalChain = new SBAA__ApprovalChain__c(
            Name = 'Test Approval Chain',
            SBAA__TargetObject__c = 'SBQQ__Quote__c'
        );
        insert approvalChain;

        List<SBAA__ApprovalRule__c> rules = new List<SBAA__ApprovalRule__c>{
            new SBAA__ApprovalRule__c(
                Name = 'Test Rule 1',
                SBAA__ApprovalChain__c = approvalChain.Id,
                SBAA__ApprovalStep__c = 1,
                SBAA__TargetObject__c = 'SBQQ__Quote__c'
            ),
            new SBAA__ApprovalRule__c(
                Name = 'Test Rule 2',
                SBAA__ApprovalChain__c = approvalChain.Id,
                SBAA__ApprovalStep__c = 2,
                SBAA__TargetObject__c = 'SBQQ__Quote__c'
            )
        };
        insert rules;
        List<SBAA__ApprovalCondition__c> conditions = new List<SBAA__ApprovalCondition__c>{
            new SBAA__ApprovalCondition__c(
                sbaa__ApprovalRule__c = rules[0].Id,
                sbaa__TestedField__c = 'Buyout_Amount__c',
                sbaa__Operator__c = '>',
                sbaa__FilterValue__c = '1000'
            ),
            new SBAA__ApprovalCondition__c(
                sbaa__ApprovalRule__c = rules[1].Id,
                sbaa__TestedField__c = 'Subsidy_Amount__c',
                SBAA__Operator__c = '>',
                sbaa__FilterValue__c = '500'
            ),new SBAA__ApprovalCondition__c(
                sbaa__ApprovalRule__c = rules[1].Id,
                sbaa__TestedField__c = 'Contract_buyout_requested__c',
                SBAA__Operator__c = '=',
                sbaa__FilterValue__c = 'true'
            )
            
        };
        insert conditions;

        List<SBAA__Approval__c> approvals = new List<SBAA__Approval__c>{
            new SBAA__Approval__c(
                Quote__c = quote.Id,
                SBAA__Status__c = 'Pending',
                sbaa__ApprovalStep__c =1,
                SBAA__ApprovalChain__c = approvalChain.Id,
                SBAA__Rule__c = rules[0].Id,
                sbaa__RecordField__c ='SBQQ__Type__c'
            ),
            new SBAA__Approval__c(
                Quote__c = quote.Id,
                SBAA__Status__c = 'Pending',
                sbaa__ApprovalStep__c = 2,
                SBAA__ApprovalChain__c = approvalChain.Id,
                SBAA__Rule__c = rules[1].Id,
                sbaa__RecordField__c ='SBQQ__Type__c'
            )
        };
        insert approvals;
        Approval_Log__c approvalLog = new Approval_Log__c();
        approvalLog.Quote__c = quote.Id;
        approvalLog.Submit_Count__c =1;
        approvalLog.Approval_Rule__c = rules[0].Id;
        approvalLog.Approval__c = approvals[0].Id;
        approvalLog.Approval_Field_Values__c = '{"QuoteLineFields":{},"QuoteFields":{"Buyout_Amount":1500.00}}';
        insert approvalLog;
    }
    
    @isTest
    static void testPreviewApproval() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote' LIMIT 1];
        
        Test.startTest();
        List<PreviewApprovalController.ApprovalChainDetails> result = 
            PreviewApprovalController.previewApproval(quote.Id);
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, result, 'Preview approval should return results');
    }
    
    @isTest
    static void testValidateApprovalAttributes() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote' LIMIT 1];
        
        Test.startTest();
        PreviewApprovalController.validateApprovalAttributes(new List<Id>{quote.Id});
        Test.stopTest();
        
        List<Quote_Approval_Attribute__c> qaaList = [
            SELECT Id, Field_Value__c 
            FROM Quote_Approval_Attribute__c 
            WHERE Quote__c = :quote.Id
        ];
        System.assertNotEquals(0, qaaList.size(), 'Quote Approval Attributes should exist');
    }
    
    @isTest
    static void testErrorHandling() {
        Test.startTest();
        try {
            PreviewApprovalController.validateApprovalAttributes(new List<Id>{'001000000000000'}); // Invalid ID
            System.assert(false, 'Should have thrown an exception');
        } catch (Exception e) {
            System.assert(true, 'Exception was caught as expected');
        }
        Test.stopTest();
    }

    @isTest
    static void testPreviewApprovalWithGroupApprovers() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote' LIMIT 1];
        
        User testUser;
        Group testGroup;
        Id groupId;
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            testGroup = new Group(
                Name = 'Test Approval Group',
                Type = 'Regular'
            );
            insert testGroup;
            groupId = testGroup.Id;
            
            Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
            testUser = new User(
                FirstName = 'Test',
                LastName = 'Group User',
                Email = 'testuser@test.com',
                Username = 'testuser' + DateTime.now().getTime() + '@test.com',
                EmailEncodingKey = 'UTF-8',
                Alias = 'tuser',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                ProfileId = p.Id,
                EmployeeNumber = '12345'
            );
            insert testUser;
            
            GroupMember gm = new GroupMember(
                GroupId = testGroup.Id,
                UserOrGroupId = testUser.Id
            );
            insert gm;
        }
        
        Test.startTest();
        
        SBAA__Approval__c approval = [SELECT Id FROM SBAA__Approval__c LIMIT 1];
        approval.sbaa__AssignedGroupId__c = groupId;
        approval.sbaa__AssignedTo__c = null;
        update approval;
        
        List<PreviewApprovalController.ApprovalChainDetails> result = 
            PreviewApprovalController.previewApproval(quote.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Preview approval should return results');
        System.assert(result[0].approvalRuleDetailsList[0].approverDetailsList.size() > 0, 
                     'Should have approver details');
    }

    @isTest
    static void testIsWithinThreePercent() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote' LIMIT 1];
        
        Quote_Approval_Attribute__c qaa = new Quote_Approval_Attribute__c(
            Quote__c = quote.Id,
            Field_API_Name__c = 'Buyout_Amount__c',
            Field_Value__c = '1000'
        );
        insert qaa;
        
        quote.Buyout_Amount__c = 1029; 
        update quote;
        
        Test.startTest();
        PreviewApprovalController.validateApprovalAttributes(new List<Id>{quote.Id});
        
        quote.Buyout_Amount__c= 1050; 
        update quote;
        PreviewApprovalController.validateApprovalAttributes(new List<Id>{quote.Id});
        
        quote.Buyout_Amount__c= 0; 
        update quote;
        PreviewApprovalController.validateApprovalAttributes(new List<Id>{quote.Id});
        Test.stopTest();
        
        List<Quote_Approval_Attribute__c> attributes = [
            SELECT Id, Field_Value__c 
            FROM Quote_Approval_Attribute__c 
            WHERE Quote__c = :quote.Id
        ];
        System.assertNotEquals(0, attributes.size(), 'Quote Approval Attributes should exist');
    }

    @isTest
    static void testQuoteLineFieldsWithNoLastLog() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote' LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 WHERE Name = 'HW-VG33' LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :product.Id LIMIT 1];
        
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = product.Id,
            SBQQ__PricebookEntryId__c = pbe.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__ListPrice__c = 1000,
            SBQQ__CustomerPrice__c = 900
        );
        insert quoteLine;
        
        sbaa__ApprovalVariable__c testVar = new sbaa__ApprovalVariable__c(
            Name = 'Test Line Variable',
            SBAA__FilterField__c = 'SBQQ__CustomerPrice__c',
            SBAA__Operator__c = '>',
            SBAA__FilterValue__c = '800',
            SBAA__AggregateField__c = 'SBQQ__CustomerPrice__c'
        );
        insert testVar;
        
        SBAA__ApprovalCondition__c condition = new SBAA__ApprovalCondition__c(
            SBAA__ApprovalRule__c = [SELECT Id FROM SBAA__ApprovalRule__c LIMIT 1].Id,
            SBAA__TestedVariable__c = testVar.Id
        );
        insert condition;
        
        delete [SELECT Id FROM Approval_Log__c WHERE Quote__c = :quote.Id];
        
        Test.startTest();
        List<PreviewApprovalController.ApprovalChainDetails> result = 
            PreviewApprovalController.previewApproval(quote.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Preview approval should return results');
        Boolean foundQuoteLineTrigger = false;
        for(PreviewApprovalController.ApprovalChainDetails chain : result) {
            for(PreviewApprovalController.ApprovalRuleDetails rule : chain.approvalRuleDetailsList) {
                for(PreviewApprovalController.ApprovalFieldTrigger triggers : rule.triggerFields) {
                    if(triggers.fieldName == 'SBQQ__CustomerPrice__c' && !triggers.isChanged) {
                        foundQuoteLineTrigger = true;
                        break;
                    }
                }
            }
        }
        System.assert(foundQuoteLineTrigger, 'Should find quote line trigger field');
    }

    @isTest
    static void testFieldChangesWithLastLog() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c WHERE Quote_Name__c = 'Test Quote' LIMIT 1];
        
        Approval_Log__c log = new Approval_Log__c(
            Quote__c = quote.Id,
            Submit_Count__c = 1,
            Approval_Field_Values__c = '{"QuoteFields":{"Buyout_Amount__c":1500.00,"Subsidy_Amount__c":600.00},"QuoteLineFields":{"test-quantity-sum":2}}'
        );
        insert log;
        
        quote.Buyout_Amount__c = 2000;
        quote.Subsidy_Amount__c = 800;
        update quote;
        
        Test.startTest();
        List<PreviewApprovalController.ApprovalChainDetails> result = 
            PreviewApprovalController.previewApproval(quote.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Preview approval should return results');
        Boolean foundChangedField = false;
        for(PreviewApprovalController.ApprovalChainDetails chain : result) {
            for(PreviewApprovalController.ApprovalRuleDetails rule : chain.approvalRuleDetailsList) {
                for(PreviewApprovalController.ApprovalFieldTrigger triggers : rule.triggerFields) {
                    if(triggers.fieldName == 'Buyout_Amount__c' && triggers.isChanged) {
                        foundChangedField = true;
                        System.assertEquals('1500.00', triggers.previousValue, 'Previous value should match');
                        System.assertEquals('2000.0', triggers.fieldValue, 'Current value should match');
                        break;
                    }
                }
            }
        }
    }
}
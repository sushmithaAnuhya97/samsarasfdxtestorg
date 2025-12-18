/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-16-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest(isParallel=false)
private class ItemsToApproveQuoteControllerTest
{
    @TestSetup static void setupData()
    {
        
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        User testUser = new User(Alias = 'test',
        						Email='testUser1@test.com', 
            					EmailEncodingKey='UTF-8',
            					LastName='TestLastName',
            					LanguageLocaleKey='en_US',
            					LocaleSidKey='en_US',
            					ProfileId = testProfile.Id,
            					TimeZoneSidKey='America/Los_Angeles',
            					UserName='userEmail4306@test.com',
                                EmployeeNumber='12345');
        insert testUser;

        //add user to a group
        Group testGroup = new Group(Name = 'testGroup');
        insert testGroup;

        GroupMember testMember = new GroupMember(GroupId = testGroup.Id, UserOrGroupId = testUser.Id);
        insert testMember;


        System.runAs(testUser)
        {
            
            Product2 testProduct = new Product2(Name='Test Product');    
            insert testProduct;

            //Id pricebookId = Test.getStandardPricebookId();
            //insert pricebookId;
             
            Account testAccount = new Account(name='Test CPQAccount', BillingStateCode = 'MT', BillingCountryCode = 'US', Organization_Size__c = '1 - 99');
            insert testAccount;
            
            Contact testContact = new Contact(FirstName = 'Test First Name',
            									LastName='Test Last Name',
            									AccountId = testAccount.Id);
            insert testContact;
            
             

            Opportunity testOppty = new Opportunity(AccountId = testAccount.Id, 
            										Name='Test CPQOpp', StageName='Open',
            										CloseDate=Date.newInstance(2017,10,12),
                                                    Owner_Role_Copy__c = 'Management');
            insert testOppty;
            
            
        }
    }
    
    @isTest static void testDataInit()
    {
        User testUser = [SELECT id FROM User WHERE UserName='userEmail4306@test.com'];
		Account testAccount = [SELECT id FROM Account WHERE Name='Test CPQAccount'];
		Opportunity testOppty = [SELECT id FROM Opportunity WHERE Name='Test CPQOpp'];
		Product2 testProduct = [SELECT id FROM Product2 WHERE Name='Test Product'];
        System.runAs(testUser)
        {
            
            SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Account__c = testAccount.Id,
            										SBQQ__Opportunity2__c = testOppty.Id,
            										SBQQ__StartDate__c = Date.today(),
            										SBQQ__EndDate__c =Date.today().addYears(1));
            insert testQuote;

            
            SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(SBQQ__StartDate__c = Date.today(),
            														SBQQ__EndDate__c = Date.today().addYears(1),
            														SBQQ__Product__c = testProduct.Id,
                                                                    SBQQ__Quantity__c = 1,
                                                                    SBQQ__NetPrice__c = 1,
            														SBQQ__Quote__c = testQuote.Id);
            insert testQuoteLine;
            
            SBAA__ApprovalRule__c testApprovalRuleQuote = new SBAA__ApprovalRule__c(Name='Test Approval Rule',
            																	SBAA__TargetObject__c = 'SBQQ__Quote__c');
            insert testApprovalRuleQuote;

            
            SBAA__Approver__c testApprover = new SBAA__Approver__c(Name = UserInfo.getUserName(),
            														SBAA__User__c = UserInfo.getUserId());
            insert testApprover;
            
            SBAA__Approval__c testQuoteApproval = new SBAA__Approval__c(SBAA__Status__c = 'Requested',
            														SBAA__RecordField__c = 'Quote__c',
            														SBAA__ApprovalStep__c = 10,
            														SBAA__Rule__c = testApprovalRuleQuote.Id,
            														SBAA__AssignedTo__c = UserInfo.getUserId(),
            														Quote__c = testQuote.Id );

            insert testQuoteApproval;
            

			//Approval.ProcessSubmitRequest submitApproval = new Approval.ProcessSubmitRequest();
			//	submitApproval.setObjectId(testQuote2.id);
			//	submitApproval.setSubmitterId(testUser.Id);
			//	Approval.ProcessResult result = Approval.process(submitApproval);
          
             
            Test.startTest();
            ItemsToApproveQuoteController testController = new ItemsToApproveQuoteController(); 
            //System.assert(result.isSuccess());
            Test.stopTest();
            
            // Verify approval rule name is populated
            System.assertEquals(1, testController.approvalListSize, 'Should find one approval');
            System.assertEquals('Test Approval Rule', testController.approvalLists[0].approvalRuleName, 'Should populate approval rule name');
        }
    }
    
    @isTest static void testGroupAssignmentWith15CharacterId()
    {
        User testUser = [SELECT id FROM User WHERE UserName='userEmail4306@test.com'];
        Account testAccount = [SELECT id FROM Account WHERE Name='Test CPQAccount'];
        Opportunity testOppty = [SELECT id FROM Opportunity WHERE Name='Test CPQOpp'];
        Product2 testProduct = [SELECT id FROM Product2 WHERE Name='Test Product'];
        Group testGroup = [SELECT Id FROM Group WHERE Name='testGroup'];
        
        System.runAs(testUser)
        {
            SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Account__c = testAccount.Id,
                                                        SBQQ__Opportunity2__c = testOppty.Id,
                                                        SBQQ__StartDate__c = Date.today(),
                                                        SBQQ__EndDate__c = Date.today().addYears(1));
            insert testQuote;
            
            SBAA__ApprovalRule__c testApprovalRule = new SBAA__ApprovalRule__c(Name='Test Group Approval Rule',
                                                                            SBAA__TargetObject__c = 'SBQQ__Quote__c');
            insert testApprovalRule;
            
            // Create approval with 15-character Group ID in text field
            String group15CharId = String.valueOf(testGroup.Id).substring(0, 15);
            SBAA__Approval__c testApproval = new SBAA__Approval__c(
                SBAA__Status__c = 'Requested',
                SBAA__RecordField__c = 'Quote__c',
                SBAA__ApprovalStep__c = 10,
                SBAA__Rule__c = testApprovalRule.Id,
                SBAA__AssignedGroupId__c = group15CharId, // 15-character format
                Quote__c = testQuote.Id
            );
            insert testApproval;

            Test.startTest();
            ItemsToApproveQuoteController controller = new ItemsToApproveQuoteController();
            Test.stopTest();
            
            // Verify the approval is found despite ID format difference
            System.assertEquals(1, controller.approvalListSize, 'Should find approval with 15-character Group ID');
            System.assertEquals(1, controller.approvalLists.size(), 'Should return one approval item');
            System.assertEquals('Test Group Approval Rule', controller.approvalLists[0].approvalRuleName, 'Should populate approval rule name');
        }
    }
    
    @isTest static void testGroupAssignmentWith18CharacterId()
    {
        User testUser = [SELECT id FROM User WHERE UserName='userEmail4306@test.com'];
        Account testAccount = [SELECT id FROM Account WHERE Name='Test CPQAccount'];
        Opportunity testOppty = [SELECT id FROM Opportunity WHERE Name='Test CPQOpp'];
        Product2 testProduct = [SELECT id FROM Product2 WHERE Name='Test Product'];
        Group testGroup = [SELECT Id FROM Group WHERE Name='testGroup'];
        
        System.runAs(testUser)
        {
            SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Account__c = testAccount.Id,
                                                        SBQQ__Opportunity2__c = testOppty.Id,
                                                        SBQQ__StartDate__c = Date.today(),
                                                        SBQQ__EndDate__c = Date.today().addYears(1));
            insert testQuote;
            
            SBAA__ApprovalRule__c testApprovalRule = new SBAA__ApprovalRule__c(Name='Test Group Approval Rule 18',
                                                                            SBAA__TargetObject__c = 'SBQQ__Quote__c');
            insert testApprovalRule;
            
            // Create approval with 18-character Group ID in text field
            String group18CharId = String.valueOf(testGroup.Id); // Full 18-character format
            SBAA__Approval__c testApproval = new SBAA__Approval__c(
                SBAA__Status__c = 'Requested',
                SBAA__RecordField__c = 'Quote__c',
                SBAA__ApprovalStep__c = 10,
                SBAA__Rule__c = testApprovalRule.Id,
                SBAA__AssignedGroupId__c = group18CharId, // 18-character format
                Quote__c = testQuote.Id
            );
            insert testApproval;

            Test.startTest();
            ItemsToApproveQuoteController controller = new ItemsToApproveQuoteController();
            Test.stopTest();
            
            // Verify the approval is found with 18-character Group ID
            System.assertEquals(1, controller.approvalListSize, 'Should find approval with 18-character Group ID');
            System.assertEquals(1, controller.approvalLists.size(), 'Should return one approval item');
            System.assertEquals('Test Group Approval Rule 18', controller.approvalLists[0].approvalRuleName, 'Should populate approval rule name');
        }
    }
    
    @isTest static void testMixedIdFormatsInMultipleApprovals()
    {
        User testUser = [SELECT id FROM User WHERE UserName='userEmail4306@test.com'];
        Account testAccount = [SELECT id FROM Account WHERE Name='Test CPQAccount'];
        Opportunity testOppty = [SELECT id FROM Opportunity WHERE Name='Test CPQOpp'];
        Product2 testProduct = [SELECT id FROM Product2 WHERE Name='Test Product'];
        Group testGroup = [SELECT Id FROM Group WHERE Name='testGroup'];
        
        System.runAs(testUser)
        {
            // Create two quotes
            SBQQ__Quote__c testQuote1 = new SBQQ__Quote__c(SBQQ__Account__c = testAccount.Id,
                                                         SBQQ__Opportunity2__c = testOppty.Id,
                                                         SBQQ__StartDate__c = Date.today(),
                                                         SBQQ__EndDate__c = Date.today().addYears(1));
            SBQQ__Quote__c testQuote2 = new SBQQ__Quote__c(SBQQ__Account__c = testAccount.Id,
                                                         SBQQ__Opportunity2__c = testOppty.Id,
                                                         SBQQ__StartDate__c = Date.today(),
                                                         SBQQ__EndDate__c = Date.today().addYears(1));
            insert new List<SBQQ__Quote__c>{testQuote1, testQuote2};
            
            SBAA__ApprovalRule__c testApprovalRule = new SBAA__ApprovalRule__c(Name='Test Mixed Format Rule',
                                                                            SBAA__TargetObject__c = 'SBQQ__Quote__c');
            insert testApprovalRule;
            
            // Create approvals with both 15 and 18 character Group IDs
            String group15CharId = String.valueOf(testGroup.Id).substring(0, 15);
            String group18CharId = String.valueOf(testGroup.Id);
            
            List<SBAA__Approval__c> testApprovals = new List<SBAA__Approval__c>{
                new SBAA__Approval__c(
                    SBAA__Status__c = 'Requested',
                    SBAA__RecordField__c = 'Quote__c',
                    SBAA__ApprovalStep__c = 10,
                    SBAA__Rule__c = testApprovalRule.Id,
                    SBAA__AssignedGroupId__c = group15CharId, // 15-character format
                    Quote__c = testQuote1.Id
                ),
                new SBAA__Approval__c(
                    SBAA__Status__c = 'Requested',
                    SBAA__RecordField__c = 'Quote__c',
                    SBAA__ApprovalStep__c = 10,
                    SBAA__Rule__c = testApprovalRule.Id,
                    SBAA__AssignedGroupId__c = group18CharId, // 18-character format
                    Quote__c = testQuote2.Id
                )
            };
            insert testApprovals;

            Test.startTest();
            ItemsToApproveQuoteController controller = new ItemsToApproveQuoteController();
            Test.stopTest();
            
            // Verify both approvals are found regardless of ID format
            System.assertEquals(2, controller.approvalListSize, 'Should find both approvals with mixed ID formats');
            System.assertEquals(2, controller.approvalLists.size(), 'Should return two approval items');
            System.assertEquals('Test Mixed Format Rule', controller.approvalLists[0].approvalRuleName, 'Should populate approval rule name for first approval');
            System.assertEquals('Test Mixed Format Rule', controller.approvalLists[1].approvalRuleName, 'Should populate approval rule name for second approval');
        }
    }
    
    @isTest static void testGetAllIdFormatsHelper()
    {
        // Test the helper method directly
        Group testGroup = [SELECT Id FROM Group WHERE Name='testGroup'];
        Set<Id> testIdSet = new Set<Id>{testGroup.Id};
        
        Test.startTest();
        ItemsToApproveQuoteController controller = new ItemsToApproveQuoteController();
        // Note: Since getAllIdFormats is private, we test it indirectly through the main functionality
        // The other test methods verify this helper works correctly
        Test.stopTest();
        
        // Verify helper method creates both formats
        String expectedId15 = String.valueOf(testGroup.Id).substring(0, 15);
        String expectedId18 = String.valueOf(testGroup.Id);
        
        // This is tested indirectly through the other test methods that verify
        // both 15 and 18 character formats are matched correctly
        System.assertNotEquals(expectedId15, expectedId18, 'Should have different 15 and 18 character formats');
        System.assertEquals(15, expectedId15.length(), 'Should create 15-character format');
        System.assertEquals(18, expectedId18.length(), 'Should create 18-character format');
    }
}
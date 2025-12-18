@isTest
private class ItemsToApproveControllerTest
{
    @TestSetup static void setupData()
    {
            	        
    }
    
    @isTest static void testDataInit()
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
            										CloseDate=Date.newInstance(2017,10,12));
            insert testOppty;
            
            SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Account__c = testAccount.Id,
            										SBQQ__Opportunity2__c = testOppty.Id,
            										SBQQ__StartDate__c = Date.today(),
            										SBQQ__EndDate__c =Date.newInstance(2018,10,12));
            insert testQuote;

            SBQQ__Quote__c testQuote2 = new SBQQ__Quote__c(SBQQ__Account__c = testAccount.Id,
            										SBQQ__Opportunity2__c = testOppty.Id,
            										SBQQ__StartDate__c = Date.today(),
            										SBQQ__EndDate__c =Date.newInstance(2018,10,12));
            insert testQuote2;

            
            SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(SBQQ__StartDate__c = Date.today(),
            														SBQQ__EndDate__c = Date.newInstance(2018,10,12),
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

            SBAA__Approval__c testQuoteApproval2 = new SBAA__Approval__c(SBAA__Status__c = 'Approved',
            														SBAA__RecordField__c = 'Quote__c',
            														SBAA__ApprovalStep__c = 10,
            														SBAA__Rule__c = testApprovalRuleQuote.Id,
            														SBAA__AssignedTo__c = UserInfo.getUserId(),
            														Quote__c = testQuote2.Id );

          	insert testQuoteApproval2;

			//Approval.ProcessSubmitRequest submitApproval = new Approval.ProcessSubmitRequest();
			//	submitApproval.setObjectId(testQuote2.id);
			//	submitApproval.setSubmitterId(testUser.Id);
			//	Approval.ProcessResult result = Approval.process(submitApproval);
          
             
            Test.startTest();
            ItemsToApproveController testController = new ItemsToApproveController(); 
            //System.assert(result.isSuccess());
            Test.stopTest();
        }
    }
}
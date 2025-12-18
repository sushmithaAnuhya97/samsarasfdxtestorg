@isTest
private class CaseTests {
    
    @TestSetup 
    static void testRecords(){
        
         
        
         insert new Hardcoded_Id__c (Name = 'Samsara Account' , Id__c = '0011P00000tsGOmQAM ');
        
         Group owner = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Customer Returns' LIMIT 1][0];
        
		 Profile userProfile = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        
         //String orgId = UserInfo.getOrganizationId();
    	 //String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
    	 //Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
    	 //String uniqueName = orgId + dateString + randomInt;
        
         List<User> newUsers = new List<User>();
        
         User newUser = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            	           EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            	           LocaleSidKey='en_US', ProfileId = userProfile.Id, 
            	           TimeZoneSidKey='America/Los_Angeles', UserName = 'testinguser@tester.com',
                                 EmployeeNumber ='9999999', Support_Round_Robin__c = True);
         newUsers.add(newUser);
        
        User newUserTwo = new User(Alias = 'standt2', Email='standarduserTwo@testorg.com', 
            	           EmailEncodingKey='UTF-8', LastName='TestingTwo', LanguageLocaleKey='en_US', 
            	           LocaleSidKey='en_US', ProfileId = userProfile.Id, 
            	           TimeZoneSidKey='America/Los_Angeles', UserName = 'testinguser21@tester.com',
                                 EmployeeNumber ='99999991');
         newUsers.add(newUserTwo);
        
         insert newUsers;
        
        List<Account> newAccounts = new List<Account>();
        
         Account testAccount = new Account(Name='Samsara Test Account');
            testAccount.Type = 'Fleet';
            testAccount.Industry = 'Other';
            testAccount.organization_size__c = '1 - 99';
            testAccount.billingstreet = '123 Main St, San Francisco CA, 94110';
            testAccount.billingstate = 'California';
            testAccount.billingcountry = 'United States';
            testAccount.billingcity = 'San Francisco';
            testAccount.billingPostalCode = '94110';
            testAccount.shippingstreet = '123 Main St, San Francisco CA, 94110';
            testAccount.shippingstate = 'California';
            testAccount.shippingcountry = 'United States';
            testAccount.shippingcity = 'San Francisco';
            testAccount.shippingPostalCode = '94110';
        	testAccount.Support_Escalation__c = true;
        	testAccount.Support_Escalation_Owner__c = UserInfo.getUserId();
         	newAccounts.add(testAccount);
        
        Account testAccountTwo = new Account(Name='Samsara Test Account II');
            testAccountTwo.Type = 'Fleet';
            testAccountTwo.Industry = 'Other';
            testAccountTwo.organization_size__c = '1 - 99';
            testAccountTwo.billingstreet = '123 Main St, San Francisco CA, 94110';
            testAccountTwo.billingstate = 'California';
            testAccountTwo.billingcountry = 'United States';
            testAccountTwo.billingcity = 'San Francisco';
            testAccountTwo.billingPostalCode = '94110';
            testAccountTwo.shippingstreet = '123 Main St, San Francisco CA, 94110';
            testAccountTwo.shippingstate = 'California';
            testAccountTwo.shippingcountry = 'United States';
            testAccountTwo.shippingcity = 'San Francisco';
            testAccountTwo.shippingPostalCode = '94110';
        	testAccountTwo.Support_Escalation__c = true;
        	newAccounts.add(testAccountTwo);
        
         Account testAccountThree = new Account(Name='Samsara Test Account III');
            testAccountThree.Type = 'Fleet';
            testAccountThree.Industry = 'Other';
            testAccountThree.organization_size__c = '1 - 99';
            testAccountThree.billingstreet = '123 Main St, San Francisco CA, 94110';
            testAccountThree.billingstate = 'California';
            testAccountThree.billingcountry = 'United States';
            testAccountThree.billingcity = 'San Francisco';
            testAccountThree.billingPostalCode = '94110';
            testAccountThree.shippingstreet = '123 Main St, San Francisco CA, 94110';
            testAccountThree.shippingstate = 'California';
            testAccountThree.shippingcountry = 'United States';
            testAccountThree.shippingcity = 'San Francisco';
            testAccountThree.shippingPostalCode = '94110';
        	testAccountThree.Support_Escalation__c = false;
        	newAccounts.add(testAccountThree);
        
        insert newAccounts;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        Opportunity revenueOpportunity = new Opportunity(AccountId = testAccount.Id, License_Term__c =36, Pricebook2Id = pricebookId, Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', CloseDate = System.today() + 90, StageName = 'Incubate');            
        insert revenueOpportunity;
        
        Opportunity queriedOpportunity = [SELECT Order_Number__c FROM Opportunity WHERE Name='Revenue Opportunity' LIMIT 1];
        
        List<Case> newCaseList = new List<Case>();
         
        for(Integer i = 0; i<=5; i++){
            Case newCase = new Case();
            newCase.Origin = 'Escalations';
            newCase.Samsara_Dashboard_Email__c = 'poweruser@test.com';
            newCase.Subject = 'Testing the Case Trigger '+i+' '+queriedOpportunity.Order_Number__c;
            newCase.AccountId = testAccount.id;  
        	newCase.OwnerId = owner.Id;   
            newCaseList.add(newCase);
        }
        
            Case newCaseForRoundRobin = new Case();
            newCaseForRoundRobin.Origin = 'Dashboard';
            newCaseForRoundRobin.Samsara_Dashboard_Email__c = 'poweruser@test.com';
            newCaseForRoundRobin.Subject = 'Testing the Case Trigger '+queriedOpportunity.Order_Number__c;
            newCaseForRoundRobin.AccountId = testAccountTwo.id;  
        	newCaseForRoundRobin.OwnerId = owner.Id;   
            newCaseList.add(newCaseForRoundRobin);
        
            Case newCaseForRoundRobinTwo = new Case();
            newCaseForRoundRobinTwo.Origin = 'Dashboard';
            newCaseForRoundRobinTwo.Samsara_Dashboard_Email__c = 'poweruser@test.com';
            newCaseForRoundRobinTwo.Subject = 'Testing the Case Trigger '+queriedOpportunity.Order_Number__c;
            newCaseForRoundRobinTwo.AccountId = testAccountThree.id;  
        	newCaseForRoundRobinTwo.OwnerId = owner.Id;   
            newCaseList.add(newCaseForRoundRobinTwo);
        
            Case newCaseForRoundRobinThree = new Case();
            newCaseForRoundRobinThree.Origin = 'Dashboard';
            newCaseForRoundRobinThree.Samsara_Dashboard_Email__c = 'poweruser@test.com';
            newCaseForRoundRobinThree.Subject = 'Testing the Case Trigger '+queriedOpportunity.Order_Number__c;
            newCaseForRoundRobinThree.AccountId = testAccountThree.id;  
        	newCaseForRoundRobinThree.OwnerId = owner.Id;   
            newCaseList.add(newCaseForRoundRobinThree);
        
            Case newCaseForRoundRobinFour = new Case();
            newCaseForRoundRobinFour.Origin = 'Dashboard';
            newCaseForRoundRobinFour.Samsara_Dashboard_Email__c = 'poweruser@test.com';
            newCaseForRoundRobinFour.Subject = 'Testing the Case Trigger '+queriedOpportunity.Order_Number__c;
            newCaseForRoundRobinFour.AccountId = testAccount.id;  
        	newCaseForRoundRobinFour.OwnerId = owner.Id;   
            newCaseList.add(newCaseForRoundRobinFour);
        
        insert newCaseList;
    }
    
    @isTest
    static void testReturnPolicyDays(){
        Test.startTest();
        List<Case> listOfCases = new List<Case>([SELECT Id FROM Case WHERE Subject LIKE '%Testing the Case Trigger%']);
        update listOfCases;
        Test.stopTest();
    }
    
    @isTest
    static void testCaseAssignToRoundRobin(){
        Test.startTest();
        List<Case> listOfCases = new List<Case>([SELECT Id FROM Case WHERE Subject LIKE '%Testing the Case Trigger%']);
        update listOfCases;
        Test.stopTest();
    }
}
@IsTest
public class FR_Related_Ops_Update_Batch_Test {
	
    @TestSetup
    private static void testDataSetup() {
        
        Id profileId = [SELECT Id,Name  FROM Profile WHERE Name LIKE '%Samsara - Product Management%' LIMIT 1].Id;
        Id ae2Role = [SELECT Id,Name FROM UserRole WHERE name LIKE '%AE2%' LIMIT 1].Id;
        
        User pmUser = createUser('PM','User1',ae2Role,profileId,'pmUser');
        insert pmUser;
        
        
	}
    
    public static User createUser(string firstName, string lastName, string roleId, string profileId, string alias){
        User activeUser = new User(
                LastName = firstName,
                FirstName = lastName,
                Email = firstName+'.'+lastname+'@samsara.com',
                Username = firstName+'.'+lastname+'@samsara.com.test',
                ManagerId = UserInfo.getUserId(),
                UserRoleId = roleId,
                CompanyName = 'TEST',
                Title = 'title',
                Alias = alias,
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = profileId,
                EmployeeNumber = 'abcdefg',
                IsActive = true   
        );
        return activeUser;
    }
    
    public static Account createAccount(String accountName, string userId){
        Account testAccount = new Account();
        testAccount.Name = accountName;
        testAccount.Industry = 'Biotechnology';
        testAccount.Organization_Size__c = '500 - 999';
        testAccount.BillingStreet = '123 main';
        testAccount.BillingCity = 'Missoula';
        testAccount.BillingState = 'California';
        testAccount.BillingCountry = 'United States';
        testAccount.BillingPostalCode = '59801';
        testAccount.Billing_Email__c = 'foo@bar.com';
        testAccount.Approved_Payment_Type__c = 'Direct Monthly';
     	testAccount.ownerid = userId;
        return testAccount;
    }

    public static Contact createContact(Id accountId) {
        Contact testContact = new Contact();
        testContact.FirstName = 'Test';
        testContact.LastName = 'Contact';
        testContact.AccountId = accountId;
        testContact.Source__c = 'Adwords';
        testContact.Email = 'test@test.com';
        return testContact;
    }
    
    public static Shipping_Address__c createShippingAddress(Id accountId, Id contactId) {
        Shipping_Address__c shippingAddress = new Shipping_Address__c();
        shippingAddress.Account__c = accountId;
        shippingAddress.Shipping_Contact__c = contactId;
        shippingAddress.Shipping_Address_Line_1__c = '111 Test Drive';
        shippingAddress.Shipping_City__c = 'Testington';
        shippingAddress.Shipping_Country__c = 'Canada';
        shippingAddress.Name = 'Test';

        return shippingAddress;
    }
    
    public static Opportunity createOpportunity(string oppName, Id accId, string ownerId, string pTerms){
         Opportunity opp = new Opportunity(
             Name = oppName, 
             StageName = 'Purchase',
             CloseDate = Date.today(),
             Custom_Schedule__c = false,
             Type = 'Revenue Opportunity',
             Is_Webstore_Upsell_Opportunity__c = false,
             SBQQ__Renewal__c = false,
             Selected_Payment_Type__c = 'Upfront Payments',
             AccountId = accId,
             Payment_Terms__c = pTerms,
             Initial_Payment_Terms__c = pTerms,
             OwnerId = ownerId
        );
        return Opp;
    }
    @IsTest
    private static void batchExecutionTest(){
        
        User pmUser = [SELECT Id FROM User WHERE alias = 'pmUser'];
        
        acideasULT__brZone__c ideaZone = new acideasULT__brZone__c ();
        ideaZone.name = 'Samsara Default FR Zone';
        ideaZone.acideasULT__CommunityName__c = 'Samsara Partnersy';
        insert ideaZone;
        
        Feature_Request_Category_Owner__c pmOwner = new Feature_Request_Category_Owner__c();
        pmOwner.Category__c = 'Video-Based Safety';
        pmOwner.Sub_Category__c = 'Safety Scoring';
        pmOwner.PM_Owner__c = pmUser.Id;
        
        insert pmOwner;
        
        Id recordTypeId = Schema.SObjectType.acideasULT__brIdea__c.getRecordTypeInfosByDeveloperName().get('Internal_Feature_Request').getRecordTypeId();
        
        acideasULT__brIdea__c idea1 = new acideasULT__brIdea__c ();
        idea1.Name = 'Idea 1';
        idea1.Business_Unit__c = 'Video-Based Safety';
        idea1.Product_Area__c = 'Safety Scoring';
        idea1.acideasULT__Description__c = 'Test Description';
        idea1.PM_Comments__c = 'comments';
		idea1.RecordTypeId = recordTypeId;
		idea1.acideasULT__brZone__c = ideaZone.id;        
        insert idea1;
        
        Account testAcc = createAccount('testAccount', userinfo.getUserId());
        Insert testAcc;
        
        Contact testCon = createContact(testAcc.Id);
        insert testCon;
        
        Shipping_Address__c shpngAddrs= createShippingAddress(testAcc.Id, testCon.Id);
        insert shpngAddrs;
        
        opportunity testopp = createOpportunity('testOppty',testAcc.Id,userinfo.getUserId(), 'Due In Advance');
        testOpp.Amount_Received__c = 100;
        Insert testOpp;
        
        Opportunity_Idea_Assignment__c relatedOpp = new Opportunity_Idea_Assignment__c();
        relatedOpp.AC_Idea__c = idea1.Id;
        relatedOpp.Opportunity__c = testOpp.Id;
        
        insert relatedOpp;
        
        insert new Last_FR_Total_ACV_Batch_Run_Date__c(SetupOwnerId=UserInfo.getOrganizationId(), Last_Run_Date__c='');
        
        Test.startTest();
        	FR_Related_Opps_Update_Batch.executeFR_ACV_Batch();
        Test.stopTest();
    }
    @IsTest
    private static void batchExecutionTest2(){
        
        User pmUser = [SELECT Id FROM User WHERE alias = 'pmUser'];
        
        acideasULT__brZone__c ideaZone = new acideasULT__brZone__c ();
        ideaZone.name = 'Samsara Default FR Zone';
        ideaZone.acideasULT__CommunityName__c = 'Samsara Partnersy';
        insert ideaZone;
        
        Feature_Request_Category_Owner__c pmOwner = new Feature_Request_Category_Owner__c();
        pmOwner.Category__c = 'Video-Based Safety';
        pmOwner.Sub_Category__c = 'Safety Scoring';
        pmOwner.PM_Owner__c = pmUser.Id;
        
        insert pmOwner;
        
        Id recordTypeId = Schema.SObjectType.acideasULT__brIdea__c.getRecordTypeInfosByDeveloperName().get('Internal_Feature_Request').getRecordTypeId();
        
        acideasULT__brIdea__c idea1 = new acideasULT__brIdea__c ();
        idea1.Name = 'Idea 1';
        idea1.Business_Unit__c = 'Video-Based Safety';
        idea1.Product_Area__c = 'Safety Scoring';
        idea1.acideasULT__Description__c = 'Test Description';
        idea1.PM_Comments__c = 'comments';
		idea1.RecordTypeId = recordTypeId;
		idea1.acideasULT__brZone__c = ideaZone.id;         
        insert idea1;
        
        Account testAcc = createAccount('testAccount', userinfo.getUserId());
        Insert testAcc;
        
        Contact testCon = createContact(testAcc.Id);
        insert testCon;
        
        Shipping_Address__c shpngAddrs= createShippingAddress(testAcc.Id, testCon.Id);
        insert shpngAddrs;
        
        opportunity testopp = createOpportunity('testOppty',testAcc.Id,userinfo.getUserId(), 'Due In Advance');
        testOpp.Amount_Received__c = 100;
        Insert testOpp;
        
        Opportunity_Idea_Assignment__c relatedOpp = new Opportunity_Idea_Assignment__c();
        relatedOpp.AC_Idea__c = idea1.Id;
        relatedOpp.Opportunity__c = testOpp.Id;
        
        insert relatedOpp;
        
        insert new Last_FR_Total_ACV_Batch_Run_Date__c(SetupOwnerId=UserInfo.getOrganizationId(), Last_Run_Date__c='');
        
        Test.startTest();
        	Id jobId = Database.executebatch(new FR_Related_Opps_Update_Batch(),50);
        	new FR_Related_Opps_Update_Batch().sendEmailMethod(jobId);
        Test.stopTest();
    }
}
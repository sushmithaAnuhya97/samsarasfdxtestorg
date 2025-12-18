@isTest
public class GS_CampaignMemberTests {

    @TestSetup static void setupRecords(){
       insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true); 
    }


    @isTest
    static void websiteVisitorCreateTest(){

        Campaign c1 = new Campaign(Name = '(Child) Kickfire', Type = 'Website - Form');
        insert c1;

        Account a = new Account (Name = 'Stark Corp', Organization_Size__c = '1 - 99', BillingCountry = 'United States', BillingState = 'California', Industry = 'Other');
        insert a;

        // Create a contact with owner = Alex Fisher
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Ned', LastName = 'Stark', email = 'ned@stark.com', OwnerId = '0051a00000154rfAAA', Campaign_to_Add__c = c1.Id,
                Campaign_Member_Status__c = 'Responded');
        Test.startTest();
        insert cntc;

        Test.stopTest();
        System.assertEquals(true, [SELECT Id, Is_Website_Visitor_Lead__c FROM Account WHERE name = 'Stark Corp' LIMIT 1].Is_Website_Visitor_Lead__c);
    }

    @isTest
    static void websiteVisitorAssignedTest() {

        Campaign c1 = new Campaign(Name = '(Child) Kickfire', Type = 'Website - Form');
        insert c1;

        DateTime dt = System.now().addDays(-1);

        Account a = new Account(Name = 'Stark Corp', Organization_Size__c = '1 - 99', BillingCountry = 'United States', BillingState = 'California', Industry = 'Other',
                CreatedDate = dt);
        insert a;

        Account aa = [SELECT Id FROM Account WHERE Name = 'Stark Corp' LIMIT 1];
        //aa.OwnerId = '0051a00000154rfAAA';

        update aa;

        Test.startTest();
        // Create a contact with owner = Alex Fisher
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Ned', LastName = 'Stark', email = 'ned@stark.com', Campaign_to_Add__c = c1.Id,
                Campaign_Member_Status__c = 'Responded');

        insert cntc;
        Test.stopTest();

        System.assertEquals(true, [SELECT Is_Website_Visitor_Lead__c FROM Account WHERE name = 'Stark Corp' LIMIT 1].Is_Website_Visitor_Lead__c);
    }

    @isTest
    static void First_Touch_CampaignInsertUpdateDeleteUndeleteTest() {
        Campaign c1 = new Campaign(Name = '(Child) Kickfire', Type = 'Website - Form');
        insert c1;

        Account a = new Account (Name = 'Stark Corp', Organization_Size__c = '1 - 99', BillingCountry = 'United States', BillingState = 'California', Industry = 'Other');
        insert a;
        Test.startTest();
        // Create a contact with owner = Alex Fisher
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Ned', LastName = 'Stark', email = 'ned@stark.com', OwnerId = UserInfo.getUserId(), Campaign_to_Add__c = c1.Id,
                Campaign_Member_Status__c = 'Responded');
        insert cntc;
        Test.stopTest();
        CampaignMember thisCampaignMember = [SELECT Id, CampaignId, ContactId, Status FROM CampaignMember LIMIT 1];
        cntc = [SELECT ID,First_Touch_Campaign__c FROM Contact WHERE email = 'ned@stark.com' LIMIT 1];
        system.assertEquals(cntc.First_Touch_Campaign__c, thisCampaignMember.CampaignId);

        delete c1;
        cntc = [SELECT ID,First_Touch_Campaign__c FROM Contact WHERE email = 'ned@stark.com' LIMIT 1];
        system.assertEquals(cntc.First_Touch_Campaign__c, null);

        Campaign[] savedCms = [SELECT Id FROM Campaign ALL ROWS];
        undelete savedCms;


        cntc = [SELECT ID,First_Touch_Campaign__c FROM Contact WHERE email = 'ned@stark.com' LIMIT 1];
        system.assertEquals(cntc.First_Touch_Campaign__c, savedCms[0].id);

    }

    @isTest
    static void First_Touch_Campaign_Date_TimeInsertUpdateDeleteUndeleteTest() {
        Campaign c1 = new Campaign(Name = '(Child) Kickfire', Type = 'Website - Form');
        insert c1;

        Account a = new Account (Name = 'Stark Corp', Organization_Size__c = '1 - 99', BillingCountry = 'United States', BillingState = 'California', Industry = 'Other');
        insert a;

        // Create a contact with owner = Alex Fisher
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Ned', LastName = 'Stark', email = 'ned@stark.com', OwnerId = UserInfo.getUserId(), Campaign_to_Add__c = c1.Id,
                Campaign_Member_Status__c = 'Responded');
        Test.startTest();
        insert cntc;
        Test.stopTest();
        CampaignMember thisCampaignMember = [SELECT Id, CampaignId, ContactId,Campaign_Interaction_Date__c, Status FROM CampaignMember LIMIT 1];
        cntc = [SELECT ID,First_Touch_Campaign_Date_Time__c FROM Contact WHERE email = 'ned@stark.com' LIMIT 1];
        system.assertEquals(cntc.First_Touch_Campaign_Date_Time__c, thisCampaignMember.Campaign_Interaction_Date__c);

        delete thisCampaignMember;
        delete c1;
        cntc = [SELECT ID,First_Touch_Campaign_Date_Time__c FROM Contact WHERE email = 'ned@stark.com' LIMIT 1];
        system.assertEquals(cntc.First_Touch_Campaign_Date_Time__c, null);



    }

    @isTest
    static void Concatenated_CampaignIdInsertUpdateDeleteUndeleteTest() {
        Campaign c1 = new Campaign(Name = '(Child) Kickfire', Type = 'Website - Form');
        insert c1;

        Account a = new Account (Name = 'Stark Corp', Organization_Size__c = '1 - 99', BillingCountry = 'United States', BillingState = 'California', Industry = 'Other');
        insert a;

        // Create a contact with owner = Alex Fisher
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Ned', LastName = 'Stark', email = 'ned@stark.com', OwnerId = UserInfo.getUserId(), Campaign_to_Add__c = c1.Id,
                Campaign_Member_Status__c = 'Responded');
        Test.startTest();
        insert cntc;
        Test.stopTest();
        CampaignMember thisCampaignMember = [SELECT Id, CampaignId, ContactId,Campaign_Interaction_Date__c, Status FROM CampaignMember LIMIT 1];
        cntc = [SELECT ID,Concatenated_CampaignId__c FROM Contact WHERE email = 'ned@stark.com' LIMIT 1];
        system.assertEquals(cntc.Concatenated_CampaignId__c, thisCampaignMember.CampaignId);

        delete thisCampaignMember;
        delete c1;
        cntc = [SELECT ID,Concatenated_CampaignId__c FROM Contact WHERE email = 'ned@stark.com' LIMIT 1];
        system.assertEquals(cntc.Concatenated_CampaignId__c, null);


    }

    @isTest
    static void Last_Marketing_Engagement_DateInsertUpdateDeleteUndeleteTest() {
        Campaign c1 = new Campaign(Name = '(Child) Kickfire', Type = 'Website - Form');
        insert c1;

        Account a = new Account (Name = 'Stark Corp', Organization_Size__c = '1 - 99', BillingCountry = 'United States', BillingState = 'California', Industry = 'Other');
        insert a;

        // Create a contact with owner = Alex Fisher
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Ned', LastName = 'Stark', email = 'ned@stark.com', OwnerId = UserInfo.getUserId(), Campaign_to_Add__c = c1.Id,
                Campaign_Member_Status__c = 'Responded');
        Test.startTest();
        insert cntc;
        Test.stopTest();
        CampaignMember thisCampaignMember = [SELECT Id, CampaignId, ContactId,Campaign_Interaction_Date__c, Status FROM CampaignMember LIMIT 1];
        cntc = [SELECT ID,Last_Marketing_Engagement_Date__c FROM Contact WHERE email = 'ned@stark.com' LIMIT 1];
        system.assertEquals(cntc.Last_Marketing_Engagement_Date__c, thisCampaignMember.Campaign_Interaction_Date__c);


        delete thisCampaignMember;
        delete c1;
        cntc = [SELECT ID,Last_Marketing_Engagement_Date__c FROM Contact WHERE email = 'ned@stark.com' LIMIT 1];
        system.assertEquals(cntc.Last_Marketing_Engagement_Date__c, null);


    }

    @isTest
    static void First_Touch_Campaign_StatusInsertUpdateDeleteUndeleteTest() {
        Campaign c1 = new Campaign(Name = '(Child) Kickfire', Type = 'Website - Form');
        insert c1;

        Account a = new Account (Name = 'Stark Corp', Organization_Size__c = '1 - 99', BillingCountry = 'United States', BillingState = 'California', Industry = 'Other');
        insert a;

        // Create a contact with owner = Alex Fisher
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Ned', LastName = 'Stark', email = 'ned@stark.com', OwnerId = UserInfo.getUserId(), Campaign_to_Add__c = c1.Id,
                Campaign_Member_Status__c = 'Responded');

        Test.startTest();
        insert cntc;
        Test.stopTest();
        CampaignMember thisCampaignMember = [SELECT Id, CampaignId, ContactId,Campaign_Interaction_Date__c, Status FROM CampaignMember LIMIT 1];
        cntc = [SELECT ID,First_Touch_Campaign_Status__c FROM Contact WHERE email = 'ned@stark.com' LIMIT 1];
        system.assertEquals(cntc.First_Touch_Campaign_Status__c, thisCampaignMember.Status);

        delete thisCampaignMember;
        delete c1;
        cntc = [SELECT ID,First_Touch_Campaign_Status__c FROM Contact WHERE email = 'ned@stark.com' LIMIT 1];
        system.assertEquals(cntc.First_Touch_Campaign_Status__c, null);


    }

    @isTest
    static void Active_Growth_Campaigns_CountInsertUpdateDeleteUndeleteTest() {
        Campaign c1 = new Campaign(Name = '(Child) Kickfire', Type = 'Website - Form', Growth_Campaign__c = true, IsActive = true);
        insert c1;

        Account a = new Account (Name = 'Stark Corp', Organization_Size__c = '1 - 99', BillingCountry = 'United States', BillingState = 'California', Industry = 'Other');
        insert a;

        // Create a contact with owner = Alex Fisher
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Ned', LastName = 'Stark', email = 'ned@stark.com', OwnerId = UserInfo.getUserId(), Campaign_to_Add__c = c1.Id,
                Campaign_Member_Status__c = 'Responded');
        Test.startTest();
        insert cntc;
        Test.stopTest();
        CampaignMember thisCampaignMember = [SELECT Id, CampaignId, ContactId,Campaign_Interaction_Date__c, Status FROM CampaignMember LIMIT 1];
        cntc = [SELECT ID,Active_Growth_Campaigns_Count__c FROM Contact WHERE email = 'ned@stark.com' LIMIT 1];
        system.assertEquals(cntc.Active_Growth_Campaigns_Count__c, 1);

        delete thisCampaignMember;
        delete c1;
        cntc = [SELECT ID,Active_Growth_Campaigns_Count__c FROM Contact WHERE email = 'ned@stark.com' LIMIT 1];
        system.assertEquals(cntc.Active_Growth_Campaigns_Count__c, null);


    }

    @isTest
    static void wfUpdate_Owner_Role_CopyTest() {
        Campaign c1 = new Campaign(Name = '(Child) Kickfire', Type = 'Website - Form', Growth_Campaign__c = true, IsActive = true);
        insert c1;

        Account a = new Account (Name = 'Stark Corp', Organization_Size__c = '1 - 99', BillingCountry = 'United States', BillingState = 'California', Industry = 'Other');
        insert a;

        // Create a contact with owner = Alex Fisher
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Ned', LastName = 'Stark', email = 'ned@stark.com', OwnerId = UserInfo.getUserId(), Campaign_to_Add__c = c1.Id,
                Campaign_Member_Status__c = 'Responded');
        Test.startTest();
        insert cntc;
        Test.stopTest();
        CampaignMember thisCampaignMember = [SELECT Id, CampaignId, Owner_Role_Copy__c, ContactId,Campaign_Interaction_Date__c, Status FROM CampaignMember LIMIT 1];
        system.assertNotEquals(thisCampaignMember.Owner_Role_Copy__c, null);
        cntc = [
                SELECT Id, Account.Owner.FirstName, Account.Owner.LastName,
                        Account.Owner.UserRole.Name
                FROM Contact
                WHERE Id = :cntc.Id
        ];
        system.assertEquals(thisCampaignMember.Owner_Role_Copy__c, cntc.Account.Owner.UserRole.Name);
        thisCampaignMember.Owner_Role_Copy__c = null;
        update thisCampaignMember;
        system.assertEquals(thisCampaignMember.Owner_Role_Copy__c, null);

    }

    @isTest
    static void wfUpdate_Owner_At_InteractionTest() {
        Campaign c1 = new Campaign(Name = '(Child) Kickfire', Type = 'Website - Form', Growth_Campaign__c = true, IsActive = true);
        insert c1;

        Account a = new Account (Name = 'Stark Corp', Organization_Size__c = '1 - 99', BillingCountry = 'United States', BillingState = 'California', Industry = 'Other');
        insert a;

        // Create a contact with owner = Alex Fisher
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Ned', LastName = 'Stark', email = 'ned@stark.com', OwnerId = UserInfo.getUserId(), Campaign_to_Add__c = c1.Id,
                Campaign_Member_Status__c = 'Responded');
        Test.startTest();
        insert cntc;
        Test.stopTest();
        CampaignMember thisCampaignMember = [SELECT Id, CampaignId, Owner_Role_Copy__c, ContactId,Campaign_Interaction_Date__c, Owner_At_Interaction__c, Status FROM CampaignMember LIMIT 1];
        system.assertNotEquals(thisCampaignMember.Owner_At_Interaction__c, null);
        Contact thisContact = [
                SELECT Id, Account.Owner.FirstName, Account.Owner.LastName,
                        Account.Owner.UserRole.Name
                FROM Contact
                WHERE Id = :cntc.Id
        ];
        system.assertEquals(thisCampaignMember.Owner_At_Interaction__c, thisContact.Account.Owner.FirstName + ' ' + thisContact.Account.Owner.LastName);
        thisCampaignMember.Owner_At_Interaction__c = null;
        update thisCampaignMember;
        thisCampaignMember = [SELECT Id, CampaignId, Owner_Role_Copy__c, ContactId,Campaign_Interaction_Date__c, Owner_At_Interaction__c, Status FROM CampaignMember LIMIT 1];
        system.assertNotEquals(thisCampaignMember.Owner_At_Interaction__c, null);
        system.assertEquals(thisCampaignMember.Owner_At_Interaction__c, thisContact.Account.Owner.FirstName + ' ' + thisContact.Account.Owner.LastName);

    }
    
    
     @isTest
     static void createRepeatCampaignTest(){
        Map<Id, Campaign> campaignNamesToBeAddedMap = new Map<Id, Campaign>();
	 	Map <Id, String> contactIdToCampaignNameMap = new  Map <Id, String>();
        Campaign c1 = new Campaign(Name = '(Child) Kickfire', Type = 'Website - Form');
        insert c1;
		campaignNamesToBeAddedMap.put(c1.id, c1);
         
        Account a = new Account (Name = 'Stark Corp', Organization_Size__c = '1 - 99', BillingCountry = 'United States', BillingState = 'California', Industry = 'Other');
        insert a;

        // Create a contact with owner = Alex Fisher
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Ned', LastName = 'Stark', email = 'ned@stark.com', OwnerId = '0051a00000154rfAAA', Campaign_to_Add__c = c1.Id,
                Campaign_Member_Status__c = 'Responded');
        Test.startTest();
        insert cntc;

        CampaigntoAdd.createRepeatCampaign(campaignNamesToBeAddedMap, contactIdToCampaignNameMap);
     }
    
     @isTest
     static void CampaigntoAddInvalid(){
        Map<Id, Campaign> campaignNamesToBeAddedMap = new Map<Id, Campaign>();
	 	Map <Id, String> contactIdToCampaignNameMap = new  Map <Id, String>();
        Campaign c1 = new Campaign(Name = '(Child) Kickfire', Type = 'Website - Form');
        insert c1;
		campaignNamesToBeAddedMap.put(c1.id, c1);
         
        Account a = new Account (Name = 'Stark Corp', Organization_Size__c = '1 - 99', BillingCountry = 'United States', BillingState = 'California', Industry = 'Other');
        insert a;

        // Create a contact with owner = Alex Fisher
        Contact cntc = new Contact(AccountId = a.Id, FirstName = 'Ned', LastName = 'Stark', email = 'ned@stark.com', 
                                   OwnerId = '0051a00000154rfAAA', Campaign_to_Add__c = 'Invalid',
                Campaign_Member_Status__c = 'Responded');
        Test.startTest();
        insert cntc;

        CampaigntoAdd.createRepeatCampaign(campaignNamesToBeAddedMap, contactIdToCampaignNameMap);
     }
    
        
     @isTest
     static void CampaignMemberCheckFutureTest(){
         Map<Id, Contact> oldContactById = new Map<Id, Contact>();
         Map<Id, Contact> newContactMap = new Map<Id, Contact>();
         Map<Id, Boolean> yoyoContactMap = new Map<Id, Boolean>();
         CampaigntoAdd.CampaignMemberCheckFuture(oldContactById, newContactMap, 'manualSource', yoyoContactMap, System.now());
     }
    
    
    
    @isTest
     static void rowLockErrorCheckTest(){
         Campaign testCampaign = new Campaign(Name = '(Child) Kickfire', Type = 'Website - Form');
         insert testCampaign;
         Account testAccount = new Account(Name = 'Sites only ISA', Organization_Size__c ='1000 - 4999', BillingCountry = 'United States', Industry = 'Other', ADR_Transfer__c = false, BillingState = 'California',Inside_Sales_Assignment__c='Tyler McGrath');
         insert testAccount;
         List<Contact> testContacts = new List<Contact>();
         for(integer i=0;i<50;i++)
         {
             Contact con = new Contact(AccountId = testAccount.Id, FirstName = 'Frank'+i, LastName = 'Sinatra'+i, ADR_Transfer_Status__c = 'Demo Scheduled');
             testContacts.add(con);
         }
         Insert testContacts;
         List<CampaignMember> testCMs = new List<CampaignMember>();
         for(integer i=0;i<50;i++)
         {
             CampaignMember cm= new CampaignMember(CampaignId=testCampaign.Id,ContactId=testContacts[i].Id,Status='Sent');
             testCMs.add(cm);
         }
         Insert testCMs;
         
         
     }
    
}
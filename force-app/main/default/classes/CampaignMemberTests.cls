@isTest(SeeAllData=false)
public class CampaignMemberTests {
    @testSetup
    static void setupTestData() {
        // Create Campaign
        Campaign c1 = new Campaign(Name = '(Child) Kickfire', Type = 'Website - Form', Growth_Campaign__c = true, IsActive = true);
        insert c1;

        // Create Account
        Account a = new Account(Name = 'Stark Corp', Organization_Size__c = '1 - 99', BillingCountry = 'United States', BillingState = 'California', Industry = 'Other');
        insert a;

        // Create Contact
        Contact cntc = new Contact(
            AccountId = a.Id,
            FirstName = 'Ned',
            LastName = 'Stark',
            Email = 'ned@stark.com',
            Campaign_to_Add__c = c1.Id,
            Campaign_Member_Status__c = 'Responded'
        );
        insert cntc;

        // Create Campaign Member
        CampaignMember cm = new CampaignMember(
            CampaignId = c1.Id,
            ContactId = cntc.Id,
            Status = 'Responded'
        );
        insert cm;

        // Create Lead Tier Custom Setting
        Campaign_Member_Lead_Tier_Automation__c leadTierSetting = new Campaign_Member_Lead_Tier_Automation__c(
            Name = 'Test Setting',
            Campaign_Type__c = 'Website - Form',
            Campaign_Member_Status__c = 'Responded',
            Lead_Tier__c = 'Not Tiered'
        );
        insert leadTierSetting;
    }

    @isTest
    static void testRestrictedProfileDeleteAccess() {
        // Get test data
        CampaignMember cm = [SELECT Id FROM CampaignMember LIMIT 1];

        Test.startTest();
        try {
            delete cm;
            //System.assert(false, 'Expected an error to be thrown');
        } catch (DMLException e) {
            System.assert(e.getMessage().contains('You do not have permission to delete Campaign Member records'));
        }
        Test.stopTest();
    }

    @isTest
    static void testHandleCampaignMemberInsert() {
        // Use a new Campaign for this test
        Campaign c2 = new Campaign(Name = 'Test Campaign 2', Type = 'Website - Form', IsActive = true);
        insert c2;
        Contact cntc = [SELECT Id FROM Contact LIMIT 1];

        CampaignMember cm = new CampaignMember(
            CampaignId = c2.Id,
            ContactId = cntc.Id,
            Status = 'Responded',
            Lead_Follow_Up_Status__c = 'No Follow-up Required'
        );

        Test.startTest();
        insert cm;
        Test.stopTest();

        cm = [SELECT Id, Lead_Follow_Up_Status__c FROM CampaignMember WHERE Id = :cm.Id];
        System.assertEquals('No Follow-up Required', cm.Lead_Follow_Up_Status__c);
    }

    @isTest
    static void testBeforeUpdateInsertWithUTMFields() {
        // Use a new Contact for this test
        Account a = [SELECT Id FROM Account LIMIT 1];
        Campaign c1 = [SELECT Id FROM Campaign LIMIT 1];
        Contact cntc2 = new Contact(
            AccountId = a.Id,
            FirstName = 'Test2',
            LastName = 'User2',
            Email = 'test2@example.com'
        );
        insert cntc2;

        CampaignMember cm = new CampaignMember(
            CampaignId = c1.Id,
            ContactId = cntc2.Id,
            Status = 'Responded',
            utm_campaign__c = 'test_campaign',
            utm_source__c = 'test_source,test_source2'
        );

        Test.startTest();
        insert cm;
        Test.stopTest();

        cm = [SELECT Id, utm_campaign_first_copy__c, utm_campaign_last_copy__c, utm_source_last_v2__c 
              FROM CampaignMember WHERE Id = :cm.Id];
        System.assertEquals('test_campaign', cm.utm_campaign_first_copy__c);
        //System.assertEquals('test_source2', cm.utm_source_last_v2__c);
    }

    @isTest
    static void testBeforeUpdateInsertWithLeadTier() {
        // Use a new Contact for this test
        Account a = [SELECT Id FROM Account LIMIT 1];
        Campaign c1 = [SELECT Id FROM Campaign LIMIT 1];
        Contact cntc3 = new Contact(
            AccountId = a.Id,
            FirstName = 'Test3',
            LastName = 'User3',
            Email = 'test3@example.com'
        );
        insert cntc3;

        CampaignMember cm = new CampaignMember(
            CampaignId = c1.Id,
            ContactId = cntc3.Id,
            Status = 'Responded'
        );

        Test.startTest();
        insert cm;
        Test.stopTest();

        cm = [SELECT Id, Lead_Tier__c FROM CampaignMember WHERE Id = :cm.Id];
        System.assertEquals('Not Tiered', cm.Lead_Tier__c);
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
        //system.assertEquals(cntc.First_Touch_Campaign__c, null);


        cntc = [SELECT ID,First_Touch_Campaign__c FROM Contact WHERE email = 'ned@stark.com' LIMIT 1];
        //system.assertEquals(cntc.First_Touch_Campaign__c, savedCms[0].id);

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
        //system.assertEquals(cntc.First_Touch_Campaign_Date_Time__c, null);



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
        //system.assertEquals(cntc.Concatenated_CampaignId__c, thisCampaignMember.CampaignId);

        delete thisCampaignMember;
        delete c1;
        cntc = [SELECT ID,Concatenated_CampaignId__c FROM Contact WHERE email = 'ned@stark.com' LIMIT 1];
        //system.assertEquals(cntc.Concatenated_CampaignId__c, null);


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
        //system.assertEquals(cntc.Last_Marketing_Engagement_Date__c, null);


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
        //system.assertEquals(cntc.First_Touch_Campaign_Status__c, null);


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
     static void CampaignMemberCheckFutureTest(){
         Map<Id, Contact> oldContactById = new Map<Id, Contact>();
         Map<Id, Contact> newContactMap = new Map<Id, Contact>();
         Map<Id, Boolean> yoyoContactMap = new Map<Id, Boolean>();
         CampaigntoAdd.CampaignMemberCheckFuture(oldContactById, newContactMap, 'manualSource', yoyoContactMap, System.now());
     }
}
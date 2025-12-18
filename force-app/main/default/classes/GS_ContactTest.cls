/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 14, 2021
*
* @description : This class is to Cover GS Related Code used for Contact Optimizations, for Original Contact Coverage use ContactTests
* SFA-14
*
**/

// Modified the class and broke the test cases(as per RT) to make sure that we are not hitting the soql limits.
@isTest
public class GS_ContactTest {

@TestSetup static void setupRecords(){


        insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true);

        //Transferred from ContactHelperTestClass: 12/5/2019 - @author: rsaavedra
        List<Account> newAccounts = new List<Account>();
        List<Contact> newContacts = new List<Contact>();
                  
        Account industrialAccount = new Account (Name = 'Acme Industry', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingState='California', Industry = 'Other', Hashtag__c='Ex_Closed_Lost', 
                                                 RecordTypeId  = Schema.SObjectType.account.getRecordTypeInfosByName().get('Industrial').getRecordTypeId());
		newAccounts.add(industrialAccount);
         
        Account machineVisionAccount = new Account (Name = 'Acme Industry MV', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingState='California', Industry = 'Other', 
                                                 RecordTypeId  = Schema.SObjectType.account.getRecordTypeInfosByName().get('Machine Vision').getRecordTypeId(), Status__c = 'New', Event_Lead__c = True);
		newAccounts.add(machineVisionAccount);
         
        Account account = new Account (Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingState='California', Industry = 'Other');
        newAccounts.add(account);
         
        Account accountWithOriginalOwner = new Account (Name = 'AcmeTwo Co', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingState='California', Industry = 'Other', Original_Owner_for_Recycling_Campaign__c= UserInfo.getUserId());
        newAccounts.add(accountWithOriginalOwner);
         
        Account exsistingCustomerAccount = new Account (Name = 'AcmeTwo Exsisting', Status__c = 'Existing Customer', Organization_Size__c = '5000+', BillingCountry = 'United Kingdom', Industry = 'Other');
        newAccounts.add(exsistingCustomerAccount);

        insert newAccounts;

        Campaign mvf = new Campaign(Name = '(Parent) MVF', Type = 'Website - Form');
        insert mvf;

        Contact duplicateCampaignContact = (Contact)TestFactory.createSOBject(new Contact( FirstName = 'Testy',
                                                                    LastName = 'McTesterson',
                                                                    Email = 'testymctesterson@samsaratesting.com',
                                                                    AccountId = account.Id,
                                                                    Campaign_to_Add__c = mvf.Id,
                                                                    New_Inbound_Lead__c = true,
                                                                    Campaign_Member_Status__c = 'Responded',
                                                                    Source__c = 'Partner Referral'));

        newContacts.add(duplicateCampaignContact);
         
        Contact contactForStampfulBasis = new Contact (FirstName = 'TestClass', LastName = 'TesterLawfulBasis', Email = 'ttesterstampfulbasis@a.com', AccountId=exsistingCustomerAccount.Id);
        newContacts.add(contactForStampfulBasis);
        
        Contact contactForHashTagEx = new Contact (FirstName = 'TestClass', LastName = 'TesterHashTag', Email = 'ttesterhashtag@a.com', AccountId=industrialAccount.Id);
        newContacts.add(contactForHashTagEx);
         
        Contact contactForCalls = new Contact (FirstName = 'TestClass', LastName = 'TesterCalls', Email = 'ttestercall@a.com', AccountId=machineVisionAccount.Id);
        newContacts.add(contactForCalls);
         
        Contact contact = new Contact (FirstName = 'TestClass', LastName = 'Tester', Email = 'ttester@a.com', AccountId=account.Id);
        newContacts.add(contact);
         
        Contact contactWithOriginalOwner = new Contact (FirstName = 'TestClass', LastName = 'TesterPlus', Email = 'ttesterp@a.com', AccountId=accountWithOriginalOwner.Id);
        newContacts.add(contactWithOriginalOwner);

        insert newContacts; 
         
        Campaign adrCampaign = new Campaign(Name = '(Child) Hot ADR transfer', IsActive = True, Type = 'Sales - ADR Outbound');
        insert adrCampaign;
        }

    @isTest static void testStampfulBasisOnContact(){
           Test.startTest();
        		List<Contact> contactList = [SELECT Id, Name, Associated_Lawful_Basis__c from Contact WHERE Email = 'ttesterstampfulbasis@a.com'];
        		system.assertEquals('Contract',contactList[0].Associated_Lawful_Basis__c);
       	   Test.stopTest();
    }
    @isTest static void testUpdateCampaignFields() {
        Test.startTest();
          List<User> poolUsers = new List<User>([SELECT Id FROM User WHERE RR_Is_Pool_User__c = TRUE LIMIT 1]);
          List<User> nonPoolUsers = new List<User>([SELECT Id FROM User WHERE RR_Is_Pool_User__c = FALSE LIMIT 1]);
          Contact c = [SELECT Id, Name, Unload_Account__c from Contact WHERE Email = 'ttester@a.com' LIMIT 1][0];
          c.OwnerId = poolUsers[0].Id;
          update c;
          Campaign camp = new Campaign(Name = 'test campaign', Type = 'Website - Form');
          insert camp;
          insert new CampaignMember(CampaignId = camp.Id, ContactId = c.Id, Status = 'Sent');
          c.OwnerId = nonPoolUsers[0].Id;
          update c;
        Test.stopTest();
    }

    @isTest private static void testOptOutError() {
        Test.startTest();
        Trigger_Setting__mdt thisTrigger = new List<Trigger_Setting__mdt>([SELECT Enabled__c FROM Trigger_Setting__mdt WHERE MasterLabel = 'Contact' LIMIT 1])[0];
        // Create an opt-out contact
        Account a = (Account)TestFactory.createSOBject(new Account());
        insert a;
        insert (Contact)TestFactory.createSOBject(new Contact(AccountId = a.Id, Sales_Email_Opt_Out__c = TRUE, Phone_Opt_Out__c = TRUE, Email = 'abc@def.ghi', MobilePhone = '111-111-1111', Phone = '222-222-2222'));
        // Now try to insert a dupe
        Contact dupe = (Contact)TestFactory.createSObject(new Contact(Email = 'abc@def.ghi', MobilePhone = '111-111-1111', Phone = '222-222-2222'));
        try {
            insert dupe;
        } catch(exception e) {
            System.debug('Exception thrown: ' + e);
        }
        if(thisTrigger.Enabled__c) {
            // Make sure dupe Id is null (it wasn't inserted)
            System.assertEquals(NULL, dupe.Id);
        }

        List<Contact> dupes = new List<Contact>();

        // Try bulk
        dupes = (Contact[])TestFactory.createSObjectList(new Contact(AccountId = a.Id, Email = 'abc@def.ghi', MobilePhone = '111-111-1111', Phone = '222-222-2222'), 10);

        try{
            insert dupes;
        } catch(exception e) {
            System.debug('Exception thrown: ' + e);
        }

        // 0 dupes should be inserted
        Integer numberOfDupes = [SELECT Id FROM Contact WHERE Email = 'abc@def.ghi'].size();
        if(thisTrigger.Enabled__c) {
            System.assertEquals(0, numberOfDupes);
        }
        Test.stopTest();
    }


    @isTest private static void testnewContact(){
        User u = [SELECT Id, Enable_Inbound_Leads__c, UserRoleId, UserRole.Name FROM User WHERE IsActive = TRUE AND RR_Is_Pool_User__c = true][0];
        Campaign mvf = new Campaign(Name = '(Parent) MVF', Type = 'Website - Form');
        insert mvf;
        Account a = (Account)TestFactory.createSOBject(new Account(OwnerId = u.Id, RecordTypeId = '0121a000000VeLe'));
        insert a;
        Contact c = (Contact)TestFactory.createSOBject(new Contact(Email = 'testymctesterson@samsaratesting.com',
                                                                   AccountId = a.Id,
                                                                   OwnerId = u.Id,
                                                                   New_Inbound_Lead__c = true,
                                                                   Campaign_to_Add__c = mvf.Id,
                                                                   Campaign_Member_Status__c = 'Responded',
                                                                   Source__c = 'Partner Referral',
                                                                   Most_Recent_Source__c = 'Partner Referral'));
        Test.startTest();
        insert c;
        Test.stopTest();
    }

    @isTest private static void testUpdateContactProjectYOYO(){
        User u = [SELECT Id, Enable_Inbound_Leads__c, UserRoleId, UserRole.Name FROM User WHERE IsActive = TRUE AND RR_Is_Pool_User__c = false AND UserRole.Name LIKE '%AE2%' AND UserRole.Name LIKE '%US%'][0];
        Campaign mvf = new Campaign(Name = '(Parent) MVF', Type = 'Website - Form');
        insert mvf;
        Account a = (Account)TestFactory.createSOBject(new Account(OwnerId = u.Id, RecordTypeId = '0121a000000VeLe', Last_Contacted__c = System.Now().addDays(-20), Account_Lifetime_ACV__c = 0, Most_Recent_Source__c = 'Adwords'));
        insert a;
        Contact c = (Contact)TestFactory.createSOBject(new Contact(Email = 'testymctesterson@samsaratesting.com',
                                                                   AccountId = a.Id,
                                                                   OwnerId = u.Id,
                                                                   New_Inbound_Lead__c = true,
                                                                   Campaign_to_Add__c = mvf.Id,
                                                                   Campaign_Member_Status__c = 'Responded',
                                                                   Source__c = 'Adwords',
                                                                   Most_Recent_Source__c = 'Adwords'));
        Test.startTest();
        insert c;
        Test.stopTest();
    }

    @isTest private static void testnewContactUpdateOwner(){
        User u = [SELECT Id, Enable_Inbound_Leads__c, UserRoleId, UserRole.Name FROM User WHERE IsActive = TRUE AND RR_Is_Pool_User__c = true][0];
        User u2 = [SELECT Id, Enable_Inbound_Leads__c, UserRoleId, UserRole.Name FROM User WHERE IsActive = TRUE AND RR_Is_Pool_User__c = false][1];
        Campaign mvf = new Campaign(Name = '(Parent) MVF', Type = 'Website - Form');
        insert mvf;
        Account a = (Account)TestFactory.createSOBject(new Account(OwnerId = u.Id, RecordTypeId = '0121a000000VeLe'));
        insert a;
        Contact c = (Contact)TestFactory.createSOBject(new Contact(Email = 'testymctesterson@samsaratesting.com',
                                                                   AccountId = a.Id,
                                                                   OwnerId = u.Id,
                                                                   New_Inbound_Lead__c = true,
                                                                   Campaign_to_Add__c = mvf.Id,
                                                                   Campaign_Member_Status__c = 'Responded',
                                                                   Source__c = 'Partner Referral'));
        insert c;

        c = [SELECT Id, OwnerId FROM Contact WHERE Id = :c.Id];
        c.OwnerId = u2.Id;
        Test.startTest();
        update c;
        Test.stopTest();
    }
    @isTest private static void testnewChannelContact(){
        User u = [SELECT Id, Enable_Inbound_Leads__c, UserRoleId, UserRole.Name FROM User WHERE IsActive = TRUE AND RR_Is_Pool_User__c = false and UserRole.Name = 'Management'][0];
        Campaign mvf = new Campaign(Name = '(Parent) MVF', Type = 'Website - Form');
        insert mvf;
        Account a = (Account)TestFactory.createSOBject(new Account(OwnerId = u.Id, RecordTypeId = '0121a000000VeLe'));
        insert a;
        Contact c = (Contact)TestFactory.createSOBject(new Contact(Email = 'testymctesterson@samsaratesting.com',
                                                                    AccountId = a.Id,
                                                                    OwnerId = u.Id,
                                                                    Channel_Source__c = true,
                                                                    Campaign_to_Add__c = mvf.Id,
                                                                    Campaign_Member_Status__c = 'Responded',
                                                                    Source__c = 'Partner Referral'));
        Test.startTest();
        insert c;
        Test.stopTest();
    }

  
     @isTest private static void testDuplicateCampaign(){
        //User u = [SELECT Id, UserRoleId, UserRole.Name FROM User WHERE IsActive = TRUE AND UserRole.Name = 'Management'][0];

        Campaign mvf = [SELECT Id FROM Campaign WHERE Name = : '(Parent) MVF' LIMIT 1];
        Contact ctc = [SELECT Id, Campaign_to_Add__c, CreatedDate FROM Contact WHERE Email =: 'testymctesterson@samsaratesting.com'];

        CampaignMember cm = [SELECT Id, CreatedDate FROM CampaignMember WHERE ContactId = : ctc.Id LIMIT 1];
        Test.setCreatedDate(ctc.Id, DateTime.newInstance(2019, 7, 27));
        Test.setCreatedDate(cm.Id, DateTime.newInstance(2019, 7, 27));

        CampaignMember cm2 = [SELECT Id, CreatedDate FROM CampaignMember WHERE ContactId = : ctc.Id LIMIT 1];

        ctc.Campaign_to_Add__c = mvf.Id;

        Test.startTest();
        update ctc;
        Test.stopTest();

        List<CampaignMember> totalCampaignMembers = [SELECT Id, CreatedDate FROM CampaignMember WHERE ContactId = : ctc.Id AND Campaign.Campaign_Name_without_Iteration__c = : '(Parent) MVF'];
        
        //System.assertEquals(2, totalCampaignMembers.size());

    }

    static User createUser() {

        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Samsara Inbound ADRs'];
        User u = new User(lastName = 'blah',
                email = uniqueName + '@test' + orgId + '.org',
                Username = uniqueName + '@test' + orgId + '.org',
                EmailEncodingKey = 'ISO-8859-1',
                Alias = uniqueName.substring(18, 23),
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                ProfileId = p.Id,
                RR_Is_Pool_User__c = false,
                EmployeeNumber='123');
        insert u;

        return u;
    }

    @IsTest
    static void ensureOwnerMatchesAccountTest_Insert() {

        User u = [SELECT Id FROM User WHERE UserRole.Name LIKE '%Management%' AND IsActive = True LIMIT 1];
        Account a = new Account(Name='blah', Organization_Size__c='1 - 99', BillingCountry='Canada', OwnerId = u.Id);
        insert a;

        Contact c = new Contact(LastName='blah', Status__c='New', AccountId=a.Id);
        System.assertNotEquals(a.OwnerId, c.OwnerId, 'Owner Ids already match - test data is not good');

        Test.startTest();
        insert c;
        Test.stopTest();

        c = [SELECT OwnerId, Status__c FROM Contact where Id = :c.Id];
        System.assertEquals(a.OwnerId, c.OwnerId, 'Owner Id from Account was not copied to Contact');
        System.assertEquals('Assigned', c.Status__c);
    }
/*
    @IsTest
    static void ensureOwnerMatchesAccountTest_Update() {

        User u = [SELECT Id FROM User WHERE UserRole.Name LIKE '%Management%' AND IsActive = True LIMIT 1];
        Account a = new Account(Name='blah', Organization_Size__c='1 - 99', BillingCountry='Canada', Owner);
        insert a;

        Contact c = new Contact(LastName='blah', Status__c='New', AccountId=a.Id);
        insert c;

        Test.startTest();
        c.OwnerId = setupUser.Id;
        update c;
        Test.stopTest();

        c = [select OwnerId, Status__c FROM Contact where Id = :c.Id];
        a = [select OwnerId from Account where Id = :a.Id];
        System.assertEquals(a.OwnerId, c.OwnerId, 'Owner Id from Account was not copied to Contact');
        System.assertEquals('Assigned', c.Status__c);
    }
*/
    @isTest
    static void accountSheduledDemoDateTest_Insert() {
        Account a = new Account(Name='blah', Organization_Size__c='1 - 99', BillingCountry='Canada');
        a.First_Demo_Date__c = null;
        insert a;

        a = [select First_Demo_Date__c from Account where Id = :a.Id];
        System.assertEquals(null, a.First_Demo_Date__c, 'First_Demo_Date__c should be empty - test data inaccurate');

        Contact c = new Contact(LastName='blah', AccountId=a.Id);
        c.Scheduled_Demo_Date__c = Datetime.now();
        c.Status__c = 'Qualified'; // or Demo Completed - Not Qualified

        System.Test.startTest();
        insert c;
        System.Test.stopTest();

        a = [select First_Demo_Date__c from Account where Id = :a.Id];
        System.assertEquals(c.Scheduled_Demo_Date__c.dateGmt(), a.First_Demo_Date__c, 'Date value was not copied to Account from Contact');
    }

    @isTest
    static void accountSheduledDemoDateTest_Update() {

        Contact contactObj = [SELECT Id, AccountId, Name, Unload_Account__c, Status__c from Contact WHERE Email = 'ttester@a.com' LIMIT 1][0];
        contactObj.Scheduled_Demo_Date__c = Datetime.now();
        contactObj.Status__c = 'Qualified'; // or Demo Completed - Not Qualified
        
        Account a = [select First_Demo_Date__c from Account where Id = :contactObj.AccountId];
        System.assertEquals(null, a.First_Demo_Date__c, 'First_Demo_Date__c should be empty - test data inaccurate');
        update contactObj;
        System.Test.startTest();
        
        contactObj = [SELECT Scheduled_Demo_Date__c, Status__c FROM Contact where Id = :contactObj.Id];
        a = [select First_Demo_Date__c from Account where Id = :a.Id];
        System.Test.stopTest();
        
        Account updatedAccount = [select First_Demo_Date__c from Account where Id = :a.Id];
        System.assertEquals(contactObj.Scheduled_Demo_Date__c.dateGmt(), updatedAccount.First_Demo_Date__c, 'Date value was not copied to Account from Contact');
    }


    @isTest
    static void accountDemoDateTest() {

        Contact contactObj = [SELECT Id, AccountId, Demo_Date__c, Name, Unload_Account__c, Status__c from Contact WHERE Email = 'ttester@a.com' LIMIT 1][0];
        contactObj.Demo_Date__c = System.today();
        
        Account a = [select First_Demo_Date__c from Account where Id = :contactObj.AccountId];
        System.assertEquals(null, a.First_Demo_Date__c, 'First_Demo_Date__c should be empty - test data inaccurate');
        update contactObj;
        System.Test.startTest();
        
        contactObj = [SELECT Demo_Date__c, Status__c FROM Contact where Id = :contactObj.Id];
        a = [select First_Demo_Date__c from Account where Id = :a.Id];
        System.Test.stopTest();
        
        Account updatedAccount = [select First_Demo_Date__c from Account where Id = :a.Id];
        System.assertEquals(contactObj.Demo_Date__c, updatedAccount.First_Demo_Date__c, 'Date value was not copied to Account from Contact');
    }
    
    
    @isTest
    static void accountBillingDetailsTest() {
        Contact contactObj = [SELECT Id, AccountId, Billing_First_Name__c, Billing_Last_Name__c, Billing_Email__c, Billing_Phone__c from Contact WHERE Email = 'ttester@a.com' LIMIT 1][0];
       Account a = [select Billing_Contact__c from Account where Id = :contactObj.AccountId];
        a.Billing_Contact__c = contactObj.Id;
        
        update a;
        
        contactObj.Billing_First_Name__c = 'Billing_First_Name__c';
        contactObj.Billing_Last_Name__c = 'Billing_Last_Name__c';
        contactObj.Billing_Email__c = 'ttesterBilling@a.com';
        contactObj.Billing_Phone__c = '111-111-1111';
        
        update contactObj;
        System.Test.startTest();
        
        contactObj = [SELECT AccountId, Billing_First_Name__c,Billing_Last_Name__c, Billing_Email__c, Billing_Phone__c, Status__c FROM Contact where Id = :contactObj.Id];
         a = [select Billing_First_Name__c from Account where Id = :contactObj.AccountId];
        System.Test.stopTest();
        
        Account updatedAccount = [select Billing_First_Name__c, Billing_Last_Name__c, Billing_Email__c, Billing_Phone__c from Account where Id = :a.Id];
        System.assertEquals(contactObj.Billing_First_Name__c, updatedAccount.Billing_First_Name__c);
        System.assertEquals(contactObj.Billing_Last_Name__c, updatedAccount.Billing_Last_Name__c);
        System.assertEquals(contactObj.Billing_Email__c, updatedAccount.Billing_Email__c);
        System.assertEquals(contactObj.Billing_Phone__c, updatedAccount.Billing_Phone__c);
    }
    
    
    @isTest
    static void accountStatusTest() {
        Contact contactObj = [SELECT Id, AccountId, Status__c from Contact WHERE Email = 'ttester@a.com' LIMIT 1][0];
        
        Account thisAccount = [select First_Purchase_Date__c, Closed_Lost_Account__c from Account where Id = :contactObj.AccountId];
        
        contactObj.Status__c = 'Retouch - Confirmed No Opportunity';
        update contactObj;
        
        contactObj.Status__c = 'Qualified';
        update contactObj;
        
        contactObj.Status__c = 'Retouch - Confirmed No Opportunity';
        update contactObj;
        
        System.Test.startTest();
        
        //contactObj.Status__c = 'Contact Established';
        //update contactObj;
        
        contactObj.Status__c = 'Attempting';
        update contactObj;
        
        contactObj.Status__c = 'Retouch - Did not Connect';
        update contactObj;
        System.Test.stopTest();
        
        contactObj.Status__c = 'Demo Scheduled';
        
        update contactObj;
        
    }
    
    
    
    
    @isTest
    static void inboundCallEmailSourceTest() {

        Campaign camp = new Campaign();
        camp.Name = ContactHelper.CAMPAIGN_EMAIL;
        camp.Type = 'Website - Form';
        insert camp;

        Account a = new Account(Name='blah', Organization_Size__c='1 - 99', BillingCountry='Canada');
        a.First_Demo_Date__c = null;
        insert a;

        Contact c = new Contact(LastName='blah', AccountId=a.Id);
        c.Source__c = 'Inbound call / email'; // => c.Inbound_Call_Email_Source__c = true;
        c.Concatenated_CampaignId__c = 'some-id';

        System.Test.startTest();
        insert c;
        System.Test.stopTest();

        c = [select Inbound_Call_Email_Source__c, Concatenated_CampaignId__c from Contact where Id = :c.Id];
        System.assertEquals(true, c.Inbound_Call_Email_Source__c, 'Formula field Inbound_Call_Email_Source__c should be true - test data is inaccurate');
        System.assertNotEquals('7011a000000SI78', c.Concatenated_CampaignId__c, 'test data is inaccurate');

        List<CampaignMember> members = [select Id from CampaignMember];
        //System.assertEquals(2, members.size(), 'Campaign Member was not created');
    }

    @isTest
    static void chatbotSourceTest() {

        Campaign camp = new Campaign();
        camp.Name = ContactHelper.CAMPAIGN_CHATBOT;
        camp.Type = 'Website - Form';
        insert camp;

        Account a = new Account(Name='blah', Organization_Size__c='1 - 99', BillingCountry='Canada');
        insert a;

        Contact c = new Contact(LastName='blah', AccountId=a.Id, Source__c = 'Chatbot');

        System.Test.startTest();
        insert c;
        System.Test.stopTest();

        c = [select Chatbot_Source__c from Contact where Id = :c.Id];
        System.assertEquals(true, c.Chatbot_Source__c, 'Formula field Chatbot_Source__c should be true - test data is inaccurate');

        List<CampaignMember> members = [select Id from CampaignMember];
        //System.assertEquals(2, members.size(), 'Campaign Member was not created');
    }

    @isTest
    static void referralUnpaidSourceTest() {

        Campaign camp = new Campaign();
        camp.Name = ContactHelper.CAMPAIGN_REFERRAL;
        camp.Type = 'Website - Form';
        insert camp;

        Account a = new Account(Name='blah', Organization_Size__c='1 - 99', BillingCountry='Canada');
        insert a;

        Contact c = new Contact(LastName='blah', AccountId=a.Id);
        c.Source__c = 'Referral (Unpaid)'; // => c.Referral_Unpaid_Source__c = true;

        System.Test.startTest();
        insert c;
        System.Test.stopTest();

        c = [select Referral_Unpaid_Source__c from Contact where Id = :c.Id];
        System.assertEquals(true, c.Referral_Unpaid_Source__c, 'Formula field Referral_Unpaid_Source__c should be true - test data is inaccurate');

        List<CampaignMember> members = [select Id from CampaignMember];
        //System.assertEquals(2, members.size(), 'Campaign Member was not created');
    }

    @isTest
    static void convertedContactNotNullTest() {
        Account a = new Account(Name='blah', Organization_Size__c='1 - 99', BillingCountry='Canada');
        a.First_Demo_Date__c = null;
        insert a;

        Contact c = new Contact(LastName='blah', AccountId=a.Id);
        c.Converted_Contact__c = 'converted-contact';
        c.Converted_Hashtags_to_Append__c = 'converted-hashtag';

        System.Test.startTest();
        insert c;
        System.Test.stopTest();

        Contact fetchedContact = [select Hashtag__c, Converted_Hashtags_to_Append__c from Contact where Id = :c.Id];
        System.assertEquals(c.Converted_Hashtags_to_Append__c, fetchedContact.Hashtag__c, 'Converted_Hashtags_to_Append__c was not populated with Hashtag__c');
        System.assertEquals(null, fetchedContact.Converted_Hashtags_to_Append__c, 'Converted_Hashtags_to_Append__c should be blanked out after populating Hashtag__c');
    }

    @isTest
    static void ownershipChangesFromPoolToXTest() {

        User u1 = [SELECT Id, Name FROM User WHERE UserRole.Name LIKE '%Management%' AND IsActive = True AND RR_Is_Pool_User__c = false LIMIT 1];
        User u2 = [SELECT Id, Name FROM User WHERE Name = 'SFDC Pool' LIMIT 1];

        Campaign cmp = new Campaign(Name = 'Test Campaign', Type = 'Website - Form');
        insert cmp;

        Account a = new Account(Name='blah', Organization_Size__c='1 - 99', BillingCountry='Canada', OwnerId = u2.Id);
        a.First_Demo_Date__c = null;
        insert a;

        Contact c = new Contact(LastName='blah', AccountId=a.Id, OwnerId = u2.Id, Campaign_to_Add__c = cmp.Id);
        c.Status__c = 'New';
        insert c;

        System.Test.startTest();
        a.OwnerId = u1.Id;
        update a;

        System.Test.stopTest();

        Contact ctc = [SELECT Id FROM Contact WHERE Id = :c.Id];
        CampaignMember cmpMb = [SELECT Owner_At_Interaction__c FROM CampaignMember WHERE ContactId = : ctc.Id];
        //System.assertEquals(u1.Name, cmpMb.Owner_At_Interaction__c, 'Owner At Interaction Updated');
    }

    @isTest //todo: test flow results or move flow logic to trigger?
    static void customerReferralsTest() {
        Account a = new Account(Name='blah', Organization_Size__c='1 - 99', BillingCountry='Canada');
        a.First_Demo_Date__c = null;
        insert a;

        Contact c = new Contact(LastName='blah', AccountId=a.Id);
        insert c;

        System.Test.startTest();
        c.Referring_Customer_Id__c = 'referring-customer-id';
        update c;
        System.Test.stopTest();

        // should call flow Customer_Referral_Assignment
    }

    @isTest
    static void campaignToAddManualSource() {

        Campaign camp = new Campaign(Name = '(Child) Inbound call/email', Type = 'Website - Form');
        insert camp;

        Account a = new Account(Name='blah', Organization_Size__c='1 - 99', BillingCountry='Canada');
        insert a;

        Contact c = new Contact(LastName='blah', AccountId=a.Id);
        c.Campaign_to_Add__c = camp.Id;
        c.Campaign_Member_Status__c = 'my-status';

        System.Test.startTest();
        insert c;
        System.Test.stopTest();

        List<CampaignMember> cmpMb = [SELECT Id FROM CampaignMember WHERE CampaignId = :camp.Id];
        System.assertEquals(1, cmpMb.size(), 'Campaign Member Added');
    }

    // TODO - Need a test that contains CampaignMembers already to cycle through existing ones

    @isTest
    static void contactWithCampaignMembersDifferent(){
        
        Campaign camp = new Campaign(Name = '(Child) Inbound call/email', Type = 'Website - Form');
        insert camp;
        Campaign camp1 = new Campaign(Name = 'Test Campaign');
        insert camp1;

        Account a = new Account(Name='blah', Organization_Size__c='1 - 99', BillingCountry='Canada');
        insert a;

        Contact c = new Contact(LastName='blah', AccountId=a.Id);
        c.Campaign_to_Add__c = camp.Id;
        c.Campaign_Member_Status__c = 'my-status';
        System.Test.startTest();
        insert c;

        Contact ctc = [SELECT Id, Campaign_to_Add__c FROM Contact WHERE Id = : c.Id];

        List<CampaignMember> cmem = [SELECT Id FROM CampaignMember WHERE ContactId = : ctc.Id];

        ctc.Campaign_to_Add__c = camp1.Id;
        update ctc;

        System.Test.stopTest();
         System.debug(LoggingLevel.INFO, 'CampaignMembers:'+cmem.size());
    }

    @isTest
    static void contactWithCampaignMembersSame(){

        Campaign camp = new Campaign(Name = '(Child) Inbound call/email', Type = 'Website - Form');
        insert camp;        
        Campaign camp1 = new Campaign(Name = 'Test Campaign', Type = 'Website - Form');
        insert camp1;

        Account a = new Account(Name='blah', Organization_Size__c='1 - 99', BillingCountry='Canada');
        insert a;

        Contact c = new Contact(LastName='blah', AccountId=a.Id);
        c.Campaign_to_Add__c = camp.Id;
        c.Campaign_Member_Status__c = 'my-status';
        insert c;

        Contact ctc = [SELECT Id, Campaign_to_Add__c FROM Contact WHERE Id = : c.Id];

        System.Test.startTest();
        ctc.Campaign_to_Add__c = camp.Id;
        update ctc;
        System.Test.stopTest();
    }

    @isTest
    static void clearChannelSourceTest() {
        Account a = new Account(Name='blah', Organization_Size__c='1 - 99', BillingCountry='Canada');
        insert a;

        Contact c = new Contact(LastName='blah', AccountId=a.Id);
        c.Channel_Source__c = true;

        System.Test.startTest();
        insert c;
        System.Test.stopTest();

        c = [select Channel_Source__c from Contact where Id = :c.Id];
        System.assertEquals(false, c.Channel_Source__c, 'Channel Source was not cleared');
    }

    @isTest
    static void rollup_Active_Growth_CampaignsTest()
    {
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('rollup_Active_Growth_Campaigns');
        insert acc;

        Contact Con = new Contact();
        con = TestFactory.initializeContact('rollup_Active_Growth_Campaigns');
        con.AccountId = acc.Id;
        con.Active_Growth_Campaigns_Count__c =50;
        insert con;

        acc = [Select id, Active_Growth_Campaigns_on_Account__c FROM Account WHERE Name LIKE 'rollup_Active_Growth_Campaigns%' LIMIT 1];
        system.assertEquals(acc.Active_Growth_Campaigns_on_Account__c, 50);
        Test.startTest();
        con.Active_Growth_Campaigns_Count__c =500;
        update con;
        acc = [Select id, Active_Growth_Campaigns_on_Account__c FROM Account WHERE Name LIKE 'rollup_Active_Growth_Campaigns%' LIMIT 1];
        system.assertEquals(acc.Active_Growth_Campaigns_on_Account__c, 500);

        delete con;
        acc = [Select id, Active_Growth_Campaigns_on_Account__c FROM Account WHERE Name LIKE 'rollup_Active_Growth_Campaigns%' LIMIT 1];
        system.assertEquals(acc.Active_Growth_Campaigns_on_Account__c, null);
        test.stopTest();
    }

    @IsTest
    static void rollup_Active_Growth_CampaignsTestReparenting()
    {
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('rollupLastCallTestReparenting');
        insert acc;

        Contact Con = new Contact();
        con = TestFactory.initializeContact('rollupLastCallTestReparenting');
        con.AccountId = acc.Id;
        con.Active_Growth_Campaigns_Count__c =50;
        insert con;

        acc = [Select id, Active_Growth_Campaigns_on_Account__c FROM Account WHERE Name LIKE 'rollupLastCallTestReparenting%' LIMIT 1];
        system.assertEquals(acc.Active_Growth_Campaigns_on_Account__c, 50);
        Test.startTest();
        Account acc2 = new Account ();
        acc2 = TestFactory.initializeAccount('rollupLastCallTestReparenting2');
        insert acc2;
        con.accountId = acc2.Id;
        update con;
        List<Account> accList = [Select id, Name, Active_Growth_Campaigns_on_Account__c FROM Account WHERE Name LIKE 'rollupLastCallTestReparenting%' ORDER BY Name DESC LIMIT 2];
        system.assertEquals(accList[0].Active_Growth_Campaigns_on_Account__c, 50);
        system.assertEquals(accList[1].Active_Growth_Campaigns_on_Account__c, null);
        Test.stopTest();

    }

    @IsTest
    static void rollupLastCallTestInsertUpdateDelete()
    {
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('rollup_Active_Growth_Campaigns');
        insert acc;

        Contact Con = new Contact();
        con = TestFactory.initializeContact('rollup_Active_Growth_Campaigns');
        con.AccountId = acc.Id;
        con.Last_Call__c = system.now().addHours(-2);
        insert con;
        acc = [Select id, Last_Call__c FROM Account WHERE Name LIKE 'rollup_Active_Growth_Campaigns%' LIMIT 1];
        
        con.Last_Call__c = system.now().addHours(-3);
        update con;
        acc = [Select id, Last_Call__c FROM Account WHERE Name LIKE 'rollup_Active_Growth_Campaigns%' LIMIT 1];
        

        Test.startTest();
        delete con;
        acc = [Select id, Last_Call__c FROM Account WHERE Name LIKE 'rollup_Active_Growth_Campaigns%' LIMIT 1];
        

        Contact[] savedContacts = [SELECT Id, Last_Call__c FROM Contact WHERE Name LIKE 'rollup_Active_Growth_Campaigns%' ALL ROWS ];
        undelete savedContacts;

        acc = [Select id, Last_Call__c FROM Account WHERE Name LIKE 'rollup_Active_Growth_Campaigns%' LIMIT 1];
        
        Test.stopTest();
    }
    @IsTest
    static void rollupLastCallTestReparenting()
    {
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('rollupLastCallTestReparenting');
        insert acc;

        Contact Con = new Contact();
        con = TestFactory.initializeContact('rollupLastCallTestReparenting');
        con.AccountId = acc.Id;
        con.Last_Call__c = system.now().addHours(-2);
        insert con;

        acc = [Select id, Last_Call__c FROM Account WHERE Name LIKE 'rollupLastCallTestReparenting%' LIMIT 1];
        
        Test.startTest();
        Account acc2 = new Account ();
        acc2 = TestFactory.initializeAccount('rollupLastCallTestReparenting2');
        insert acc2;
        con.accountId = acc2.Id;
        update con;
        List<Account> accList = [Select id, Name, Last_Call__c FROM Account WHERE Name LIKE 'rollupLastCallTestReparenting%' ORDER BY Name DESC LIMIT 2];
        
        Test.stopTest();

    }

    //tested for combination 20 Accounts with 40 contacts
    @IsTest
    static void rollupLastCallTestBulk()
    {
        List<Account> accList = new List<Account>();
        for(integer i = 0; i < 2; i++)
        {
            Account acc = new Account ();
            acc = TestFactory.initializeAccount('rollupLastCallTestReparenting'+'i');
            accList.add(acc);
        }

        insert accList;

        Test.startTest();
        List<Contact> conList = new List<Contact>();
        integer j = 0;
        for(integer i = 0; i < 2; i++)
        {
            if(j == 2) j=0;
            Contact Con = new Contact();
            con = TestFactory.initializeContact('rollupLastCallTestReparenting' + i);
            con.AccountId = accList[j].Id;
            con.Last_Call__c = system.now().addHours(-i);
            conList.add(con);
            j++;
        }

        insert conList;

        accList = [Select id, Last_Call__c FROM Account WHERE Name LIKE 'rollupLastCallTestReparenting%' ORDER BY Name ASC LIMIT 1];
        Test.stopTest();
    }

    @IsTest
    static void rollupLast_Marketing_Engagement_DateTestInsertUpdateDelete() {
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('Last_Marketing_Engagement_Date');
        insert acc;

        Contact Con = new Contact();
        con = TestFactory.initializeContact('Last_Marketing_Engagement_Date');
        con.AccountId = acc.Id;
        con.Last_Marketing_Engagement_Date__c = system.now().addHours(-2);
        insert con;
        acc = [Select id, Last_Marketing_Engagement_Date__c FROM Account WHERE Name LIKE 'Last_Marketing_Engagement_Date%' ORDER BY Name ASC LIMIT 1];
        system.assertEquals(acc.Last_Marketing_Engagement_Date__c, con.Last_Marketing_Engagement_Date__c);

        test.startTest();
        con.Last_Marketing_Engagement_Date__c = system.now().addHours(2);
        update con;
        acc = [Select id, Last_Marketing_Engagement_Date__c FROM Account WHERE Name LIKE 'Last_Marketing_Engagement_Date%' ORDER BY Name ASC LIMIT 1];
        system.assertEquals(acc.Last_Marketing_Engagement_Date__c, con.Last_Marketing_Engagement_Date__c);
        delete con;
        acc = [Select id, Last_Marketing_Engagement_Date__c FROM Account WHERE Name LIKE 'Last_Marketing_Engagement_Date%' LIMIT 1];
        system.assertEquals(acc.Last_Marketing_Engagement_Date__c, null);

        Contact[] savedContacts = [SELECT Id, Last_Marketing_Engagement_Date__c FROM Contact WHERE Name LIKE 'Last_Marketing_Engagement_Date%' ALL ROWS];
        undelete savedContacts;

        acc = [Select id, Last_Marketing_Engagement_Date__c FROM Account WHERE Name LIKE 'Last_Marketing_Engagement_Date%' LIMIT 1];
        system.assertEquals(acc.Last_Marketing_Engagement_Date__c, savedContacts[0].Last_Marketing_Engagement_Date__c);
        test.stopTest();

    }

    @IsTest
    static void rollupLast_Marketing_Engagement_DateTestReparenting() {
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('rollupReparenting');
        insert acc;

        Contact Con = new Contact();
        con = TestFactory.initializeContact('rollupReparenting');
        con.AccountId = acc.Id;
        con.Last_Marketing_Engagement_Date__c = system.now().addHours(-2);
        insert con;

        acc = [Select id, Last_Marketing_Engagement_Date__c FROM Account WHERE Name LIKE 'rollupReparenting%' LIMIT 1];
        system.assertEquals(acc.Last_Marketing_Engagement_Date__c, con.Last_Marketing_Engagement_Date__c);
        Test.startTest();
        Account acc2 = new Account ();
        acc2 = TestFactory.initializeAccount('rollupReparenting');
        insert acc2;
        con.accountId = acc2.Id;
        update con;
        List<Account> accList = [Select id, Name, Last_Marketing_Engagement_Date__c FROM Account WHERE Name LIKE 'rollupReparenting%' ORDER BY Name DESC LIMIT 2];
        system.assertEquals(acc.Last_Marketing_Engagement_Date__c, con.Last_Marketing_Engagement_Date__c);
        //system.assertEquals(accList[0].Last_Marketing_Engagement_Date__c, con.Last_Marketing_Engagement_Date__c);
        //system.assertEquals(accList[1].Last_Marketing_Engagement_Date__c, null);
        Test.stopTest();

    }

    //tested for combination 20 Accounts with 40 contacts
    @IsTest
    static void rollupLast_Marketing_Engagement_DateTestBulk() {
        List<Account> accList = new List<Account>();
        for (integer i = 0; i < 2; i++) {
            Account acc = new Account ();
            acc = TestFactory.initializeAccount('Last_Marketing_EngagementBulk' + 'i');
            accList.add(acc);
        }

        insert accList;

        Test.startTest();
        List<Contact> conList = new List<Contact>();
        integer j = 0;
        for (integer i = 0; i < 2; i++) {
            if (j == 2) j = 0;
            Contact Con = new Contact();
            con = TestFactory.initializeContact('Last_Marketing_EngagementBulk' + i);
            con.AccountId = accList[j].Id;
            con.Last_Marketing_Engagement_Date__c = system.now().addHours(-i);
            conList.add(con);
            j++;
        }

        insert conList;

        accList = [Select id, Last_Marketing_Engagement_Date__c FROM Account WHERE Name LIKE 'Last_Marketing_EngagementBulk%' ORDER BY Name ASC LIMIT 1];
        system.assertEquals(accList[0].Last_Marketing_Engagement_Date__c, conList[0].Last_Marketing_Engagement_Date__c);
        Test.stopTest();
    }

     @isTest
    static void workflowScenarioTest(){
        List<Contact> lstContact = new List<Contact>();
        Account acc = TestFactory.initializeAccount('WorkflowChangesScenario1');
        //    acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Industrial').getRecordTypeId();
        insert acc;
        test.startTest();
        Contact objCon = TestFactory.initializeContact('WorkflowChangesScenario1');
        objCon.AccountId = acc.Id;
        insert objCon;
        
        objCon.Status__c = 'Demo Completed - Not Qualified';
        update objCon;
        objCon.Status__c = 'Demo Scheduled';
        objCon.Source__c = 'List Import (no prior engagement)';
       // Update Phone and Email Opt Out workflow changes  
        objCon.Opt_Out_Request__c = 'GDPR';
            
        update objCon;
        lstContact = [Select Id, Source__c, Contact_Status_Changed__c, Scheduled_Demo_Date__c, Demo_Date__c, Phone_Opt_Out__c, Sales_Email_Opt_Out__c, Opt_Out_Email_Copy__c, Email from Contact where Id =: objCon.Id]; 
        
        
        
        objCon.Number_of_Calls_by_Current_Owner_Roll_Up__c = 1;
        objCon.Status__c = 'Assigned';
        objCon.Email = 'testOne@test.com';
        
        //Update Phone Opt Out workflow changes
        objCon.Phone_Opt_Out__c = false;
        objCon.Opt_Out_Request__c = 'Phone';
        
        update objCon;
        lstContact = [Select Id, Status__c, Phone_Opt_Out__c from Contact where Id =: objCon.Id]; 
        
         

        
        objCon.Number_of_Calls_by_Current_Owner_Roll_Up__c = 3;
        //objCon.Status__c = 'Contact Established';
        
        // Update Email Opt Out workflow
        objCon.Opt_Out_Request__c = 'Email';
        
        update objCon; 
        lstContact = [Select Id, Status__c, HasOptedOutOfEmail, Sales_Email_Opt_Out__c, Opt_Out_Email_Copy__c, Email, MobilePhone, Opt_Out_Mobile_Phone_Copy__c, Phone, Opt_Out_Phone_Copy__c, Opt_Out_Phone__c, Opt_Out_Mobile_Phone__c, Phone_Opt_Out__c from Contact where Id =: objCon.Id]; 
        
        
        objCon.Registered_on_TPS__c = true;
        objCon.Email = 'testTwo@test.com';
        
        update objCon; 
        lstContact = [Select Id, Status__c, Opt_Out_Email_Copy__c, Email, MobilePhone, Opt_Out_Mobile_Phone_Copy__c, Phone, Opt_Out_Phone_Copy__c, Opt_Out_Phone__c, Opt_Out_Mobile_Phone__c from Contact where Id =: objCon.Id]; 
        
       
        
        
        test.stopTest();
    }

    @isTest
    static void testUpdateContactStatusToDemoScheduledMethod(){
        List<Contact> lstContact = new List<Contact>();
        Account acc = TestFactory.initializeAccount('WorkflowChangesScenario1');
        
        test.startTest();
        
        Id pId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id;
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        UserRole smbTeam = new UserRole();
        
        User userRecordWithSmbTeamRole = new User();
        
        system.runAs(thisUser){

            smbTeam = new UserRole(Name = Label.ExpressSegment);
            insert smbTeam;
            
            userRecordWithSmbTeamRole = (User)
                TestFactory.createSObject(new User(ProfileId = pId,
                                                   EmployeeNumber = '123',
                                                   LastName = 'last',
                                                   Email = 'puser000@amamama.com',
                                                   Username = 'puser000@amamama.com' + Math.random() + System.currentTimeMillis(),
                                                   CompanyName = 'TEST',
                                                   Title = 'title',
                                                   Alias = 'alias',
                                                   TimeZoneSidKey = 'America/Los_Angeles',
                                                   EmailEncodingKey = 'UTF-8',
                                                   LanguageLocaleKey = 'en_US',
                                                   LocaleSidKey = 'en_US',
                                                   Order_Admin_Fallback_User__c = TRUE,
                                                   isActive = TRUE,
                                                   Business_Unit__c = 'Industrial',
                                                   Segment__c = 'Enterprise',
                                                   Entity__c = 'Samsara UK',
                                                   Territory__c  = 'West',
                                                   UserRoleId = smbTeam.Id));
            insert userRecordWithSmbTeamRole;
            
        }
        
        acc.OwnerId = userRecordWithSmbTeamRole.id;
            
        insert acc;
        
        Contact objCon = TestFactory.initializeContact('WorkflowChangesScenario1');
        objCon.OwnerId = userRecordWithSmbTeamRole.id;
        objCon.AccountId = acc.Id;
        insert objCon;
        
        lstContact = [Select Id, Owner.UserRole.Name, Owner.Username, OwnerId, Status__c from Contact where Id =: objCon.Id];
       
        objCon.Scheduled_Demo_Date__c = system.today().addDays(1);
        objCon.ADR_Transfer_By__c = null;
        objCon.Hot_Transfer_To__c = null;
        objCon.Source__c = 'List Import (no prior engagement)';
        
        update objCon;
        
        lstContact = [Select Id, Status__c from Contact where Id =: objCon.Id]; 
        system.assertEquals(lstContact[0].Status__c, 'Demo Scheduled');
        
        test.stopTest();
        
    }


}
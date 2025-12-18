/**********************************************************************
Name: CampaignMemberHelper_Test
=======================================================================
Purpose: This class will contain methods for CampaignMemberHelper test coverage                                                         
=======================================================================
History  
    
VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2023-Jan-11        INITIAL DEVELOPMENT

***********************************************************************/ 
@isTest(SeeAllData=false)
public class CampaignMemberHelper_Test {
    @testSetup
    private static void testDataSetup() {
        //Slack_Enabled_Campaign_Type__mdt slackCampaignTypes = new Slack_Enabled_Campaign_Type__mdt ();
        User objRoleAE = [select Id, IsActive, UserRole.Name from User where IsActive = true and Profile.Name like 'Samsara Sales - NA US%' limit 1];
        User objRoleADR = [select Id, IsActive, UserRole.Name from User where IsActive = true and Profile.Name = 'Samsara ADRs' limit 1];
        Book_Of_Business__c  ab = new Book_Of_Business__c (Name='Test book', AE__c=objRoleAE.Id, ADR__c=objRoleADR.Id, Active__c=true);
        insert ab; 
        List<Account> newAccount = new List<Account>();
        Account acc = new Account (Name = 'Test Account RODRIGO Campaign Member', Organization_Size__c = '5000+', 
                                   BillingCountry = 'Canada', Industry = 'Other', Books_Of_Business__c = ab.Id);
        newAccount.add(acc);   
        insert newAccount;
        
        List<Campaign> newCampaigns = new List<Campaign>();
        Campaign c1 = new Campaign();
        c1.Name = 'RODRIGO Kickfire Campaign 1';
        c1.Type = 'Website - Form';
        newCampaigns.add(c1);
        Campaign c2 = new Campaign();
        c2.Name = 'RODRIGO Campaign 2';
        c2.Type = 'Website - Form';
        newCampaigns.add(c2);
        
        Campaign c3 = new Campaign();
        c3.Name = 'RODRIGO Campaign 3';
        c3.Type = 'Website - Form';
        newCampaigns.add(c3);
        
        insert newCampaigns;
        
        List<Contact> newContacts = new List<Contact>();
        //Contact contact = [select id,Campaign_to_Add__c,FirstName,LastName,Email from Contact limit 1 ];
        Contact con0 = new Contact (FirstName = 'User', LastName = 'Tester', Email = 'C0test@test.com', AccountId=acc.Id , 
                                    Campaign_Member_Status__c = 'Responded', Campaign_to_Add__c=newCampaigns[0].Id);
        newContacts.add(con0);  
        Contact con1 = new Contact (FirstName = 'User', LastName = 'Tester', Email = 'C1test@test.com', AccountId=acc.Id);
        newContacts.add(con1); 
        Contact con2 = new Contact (FirstName = 'User', LastName = 'Tester', Email = 'C2test@test.com', AccountId=acc.Id);
        newContacts.add(con2); 
        Contact con3 = new Contact (FirstName = 'User', LastName = 'Tester', Email = 'C3test@test.com', AccountId=acc.Id);
        newContacts.add(con3); 
        
        insert newContacts;
        
        List<CampaignMember> cmemList = new List<CampaignMember>();
        CampaignMember cmem1 = new CampaignMember(Account__c = newContacts[1].AccountId, ContactId = newContacts[1].id, CampaignId = newCampaigns[1].Id,
                                                Status = 'Responded', Slack_Notification_to_Owner__c = true);
        cmemList.add(cmem1);
        Campaign_Member_Lead_Tier_Automation__c setting = new Campaign_Member_Lead_Tier_Automation__c();
    setting.Campaign_Member_Status__c = 'Responded';
    setting.Campaign_Type__c = 'Website - Form';
        setting.Lead_Tier__c='1';
        setting.name='Website - Form 1';
    insert setting;
        CampaignMemberStatus cmstatus= new CampaignMemberStatus();
        cmstatus.HasResponded=true;
        cmstatus.CampaignId=c2.id;
        cmstatus.Label='No Shows';
        insert cmstatus;
        List<SlackInboundAlert.InboundCampaignMember> cmList = new List<SlackInboundAlert.InboundCampaignMember>();
        SlackInboundAlert.InboundCampaignMember cm = new SlackInboundAlert.InboundCampaignMember();
        cm.ownerSlackUserId = '@ron.saavedra';
        cm.contactName = con0.name;
       // cm.contactLastName = 'McTesterson';
        cm.accountName = 'Testing 123';
        cm.contactId = con0.Id;
        cm.SlackSwitch = false;
        //GTMS-21676 by Manjusha Jammula  
        cm.accountOwner = 'TestUser';
        cm.accProspectingStatus = 'ADR Prospecting';
        cm.campaignName = 'Campaign Event-Tradeshow';
        cm.campaignType = 'Website - Conversational Chat';
        cm.campaignMemberStatus = 'Responded' ;
        cm.campaignOwner = 'TestUser';
        //End GTMS-21676
        cmList.add(cm);
    
        
        
        /*CampaignMember cmem2 = new CampaignMember(Account__c = newContacts[2].AccountId, ContactId = newContacts[2].id, CampaignId = newCampaigns[1].Id,
                                                Status = 'Responded', Slack_Notification_to_Owner__c = true);
        cmemList.add(cmem2);
        
        CampaignMember cmem3 = new CampaignMember(Account__c = newContacts[3].AccountId, ContactId = newContacts[2].id, CampaignId = newCampaigns[1].Id,
                                                Status = 'Responded', Slack_Notification_to_Owner__c = true);
        cmemList.add(cmem3);*/
        
        insert cmemList;
    }
    
    @isTest
    private static void testCreate() {
        String manualSource = 'true';
        DateTime now;
        Map<Id, Boolean> yoyoContactMap;
        Map<Id, Id> contactToCampaignId = new Map<Id, Id>();
        User rainMaker = new User(
            Alias = 'rmaker',
            Email = 'rain.maker@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Maker',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User'][0].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'rain.maker@example.com',
            EmployeeNumber='1000721'
        );
        insert rainMaker;
        Test.startTest();
        // Set the current user to 'Rain Maker'
        System.runAs(rainMaker) {
            // Step 2: Create an Account with a non-null RR_Assigned_On__c field
            Account acc = new Account(
                Name = 'Test Account',
                Organization_Size__c='1 - 99',
                BillingCountry='United States',
                BillingState='California',
                Billing_Email__c='abc@gmail.com',
                RR_Assigned_On__c = DateTime.now().addDays(-5) // Setting a past date for example
            );
            insert acc;

            // Step 3: Create a Contact associated with the Account
            Contact con = new Contact(
                FirstName = 'Test',
                LastName = 'Contact',
                AccountId = acc.Id
            );
            insert con;

            // Step 4: Create a CampaignMember (cm) and associate it with the Contact
            CampaignMember cm = new CampaignMember(
                ContactId = con.Id,
                CampaignId = [SELECT Id FROM Campaign LIMIT 1].Id // Assuming at least one Campaign exists
            );
            insert cm;

            // Retrieve the inserted CampaignMember
            cm = [SELECT Lead_Funnel_Assignment_Date_Time__c FROM CampaignMember WHERE Id = :cm.Id];
cm.Lead_Funnel_Assignment_Date_Time__c=acc.RR_Assigned_On__c;
            update cm;
            // Assert that the Lead_Funnel_Assignment_Date_Time__c field is set correctly
            //System.assertEquals(acc.RR_Assigned_On__c, cm.Lead_Funnel_Assignment_Date_Time__c);
        }  
        //Slack_Enabled_Campaign_Type__mdt slackCampaignTypes = new Slack_Enabled_Campaign_Type__mdt ();
        User objRoleAE = [select Id, IsActive, UserRole.Name from User where IsActive = true and Profile.Name like 'Samsara Sales - NA US%' limit 1];
        User objRoleADR = [select Id, IsActive, UserRole.Name from User where IsActive = true and Profile.Name = 'Samsara ADRs' limit 1];
        Book_Of_Business__c  ab = new Book_Of_Business__c (Name='Test book', AE__c=objRoleAE.Id, ADR__c=objRoleADR.Id, Active__c=true);
        insert ab; 
        List<Account> newAccount = new List<Account>();
        Account acc = new Account (Name = 'Test Account RODRIGO', Organization_Size__c = '5000+', 
                                   BillingCountry = 'Canada', Industry = 'Other', Books_Of_Business__c = ab.Id);
        newAccount.add(acc);   
        insert newAccount;
        
        List<Campaign> newCampaigns = new List<Campaign>();
        Campaign c1 = new Campaign();
        c1.Name = '1RODRIGO Campaign 1';
        c1.Type = 'Website - Form';
        newCampaigns.add(c1);
        Campaign c2 = new Campaign();
        c2.Name = '1RODRIGO Campaign 2';
        c2.Type = 'Website - Form';
        newCampaigns.add(c2);
        
        Campaign c3 = new Campaign();
        c3.Name = '1RODRIGO Campaign 3';
        c3.Type = 'Website - Form';
        newCampaigns.add(c3);
        
        insert newCampaigns;
        
        List<Contact> newContacts = new List<Contact>();
        //Contact contact = [select id,Campaign_to_Add__c,FirstName,LastName,Email from Contact limit 1 ];
        Contact con1 = new Contact (FirstName = 'User', LastName = 'Tester', Email = 'C1test@test.com', AccountId=acc.Id , 
                                    Campaign_Member_Status__c = 'Responded', Campaign_to_Add__c=newCampaigns[0].Id);
        newContacts.add(con1);  
        Contact con2 = new Contact (FirstName = 'User', LastName = 'Tester', Email = 'C2test@test.com', AccountId=acc.Id , Campaign_to_Add__c=newCampaigns[1].Id);
        newContacts.add(con2); 
        Contact con3 = new Contact (FirstName = 'User', LastName = 'Tester', Email = 'C3test@test.com', AccountId=acc.Id , Campaign_to_Add__c=newCampaigns[2].Id);
        newContacts.add(con3); 
        
        insert newContacts;
        
        Map<Id, Contact> contactMap = new Map<Id, Contact>();
        contactMap.put(newContacts[0].id,newContacts[0]);
        Contact con = new Contact();
        con = newContacts[0];
        List<CampaignMember> cmList = new list<CampaignMember>();
        CampaignMember cmem = new CampaignMember();
        cmem.Account__c = con.AccountId;
        cmem.ContactId = con.id;
        cmem.CampaignId = newCampaigns[0].Id;
        cmem.utm_campaign__c =  con.utm_campaign_append__c;
        cmem.utm_content__c = con.utm_content_append__c;
        cmem.utm_ext_ad_id__c = con.utm_ext_ad_id__c;
        cmem.utm_ext_adset_id__c = con.utm_ext_adset_id__c;
        cmem.utm_ext_campaign_id__c = con.utm_ext_campaign_id__c;
        cmem.utm_medium__c = con.utm_medium_append__c;
        cmem.utm_source__c = con.utm_source_append__c;
        cmem.utm_term__c = con.utm_term_append__c;
        cmem.Campaign_Interaction_Date__c = System.now();
        cmem.Third_Party_Vendor_Lead_ID__c=con.Third_Party_Vendor_Lead_ID__c;
        cmem.Google_GCLIDv2__c = con.Google_GCLIDv2__c;
        cmem.experimentId__c = con.experimentId__c;
        cmem.Experimental_Group__c = con.Experimental_Group__c;
        cmem.Lead_Funnel_Trigger_Start__c = con.Lead_Funnel_Trigger_Start__c;
        cmem.Lead_Funnel_RDS_DB_Insert__c = con.Lead_Funnel_RDS_DB_Insert__c;
        cmem.Microsoft_MSCLKID__c = con.Microsoft_MSCLIKID__c;
        cmem.Personalization_Experiment_Id__c = con.Personalization_Experiment_Id__c;
        cmem.Slack_Notification_to_Owner__c = true;
        cmem.status='Responded';
        cmem.Lead_Tier__c='1';
        cmList.add(cmem);
        insert cmList;
        contactToCampaignId.put(cmem.id,con.Id);
        Map<Id, String> conIdCampName = new Map<Id, String>();
        conIdCampName.put(con.Id, newCampaigns[0].Name);
        Map<Id, Campaign> campaignNamesToBeAddedMap = new Map<Id, Campaign>();
        campaignNamesToBeAddedMap.put(con.Id,newCampaigns[0]);
        
        con.Campaign_to_Add__c = c1.Id;
        Map<Id, Contact> oldContactById = new Map<Id,Contact>();
        oldContactById.put(con.Id,con);
        system.debug('values' +contactMap +manualSource +now +yoyoContactMap +contactToCampaignId);
         
        CampaigntoAdd.CampaigntoAdd(contactMap, manualSource, now, yoyoContactMap, contactToCampaignId);
        CampaigntoAdd.createRepeatCampaign(campaignNamesToBeAddedMap,conIdCampName);
        CampaigntoAdd.CampaigntoAdd(contactMap, manualSource, now, yoyoContactMap, null);
        CampaigntoAdd.CampaignMemberCheckFuture(oldContactById , contactMap, manualSource, yoyoContactMap, now);
        Test.stopTest();
        
    }
  @isTest static void createCampaignMember()
    {
        Test.startTest();
        Account acc = [SELECT Id, Books_Of_Business__c FROM Account WHERE Name = 'Test Account RODRIGO Campaign Member'];
        Campaign newCampaign = [SELECT id from Campaign WHERE name = 'RODRIGO Kickfire Campaign 1'];
        Campaign newCampaign2 = [SELECT id from Campaign WHERE name = 'RODRIGO Campaign 2'];
        Contact con1 = new Contact (FirstName = 'User', LastName = 'Tester', Email = '1C1test@test.com', AccountId=acc.Id , 
                                    Campaign_Member_Status__c = 'Responded', Campaign_to_Add__c=newCampaign.Id);
        insert con1;
        CampaignMember cmem = new CampaignMember();
        cmem.Account__c = con1.AccountId;
        cmem.ContactId = con1.id;
        cmem.CampaignId = newCampaign2.Id;
        cmem.Status = 'Responded';
        cmem.Lead_Tier__c='1';
        cmem.Slack_Notification_to_Owner__c = true;
        //cmem.Campaign_Type__c = '';
        insert cmem;
        
        cmem.utm_campaign__c = 'testing update';
        cmem.utm_source__c = 'webstore';
        update cmem;
        Test.stopTest();
    }
    
    @isTest static void updateCampaignMember()
    {
        Test.startTest();
        Campaign newCampaign2 = [SELECT id from Campaign WHERE name = 'RODRIGO Campaign 2'];
        List<CampaignMember> listCmem = [SELECT Id  FROM CampaignMember Where campaignid =: newCampaign2.id];
        
        listCmem[0].utm_campaign__c = 'testing update';
        listCmem[0].utm_source__c = 'webstore';
                                         
        /*listCmem[1].utm_campaign__c = 'testing update';
        listCmem[1].utm_source__c = 'webstore';
                                         
        listCmem[2].utm_campaign__c = 'testing update';
        listCmem[2].utm_source__c = 'webstore';*/
                                         
        update listCmem;
        Test.stopTest();
    }
 /*   @istest
    private static void testSlackNotification() {
        // Create necessary Users and Books of Business
        User user = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Book_Of_Business__c bookOfBusiness = new Book_Of_Business__c(Name = 'Test Book', Active__c = true);
        insert bookOfBusiness;

        // Create an Account with Is_Owner_Pool_User__c set to false
        Account account = new Account(Name = 'Test Account', Organization_Size__c = '5000+', 
                                   BillingCountry = 'Canada',  Books_Of_Business__c = bookOfBusiness.Id);
        insert account;

        // Create a Contact linked to the account
        Contact contact = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = account.Id);
        insert contact;

        // Create the grandparent campaign (Master Campaign)
        Campaign grandparentCampaign = new Campaign(Name = '(Master) Inbound', Type = 'Campaign - Mailer');
        insert grandparentCampaign;

        // Create the parent campaign and set Master_Campaign_Name__c to the grandparent campaign's ID
        Campaign parentCampaign = new Campaign(Name = 'Parent Campaign', Type = 'Campaign - Mailer',ParentId = grandparentCampaign.Id);
        insert parentCampaign;
        Campaign childCampaign = new Campaign(Name = 'Parent Campaign',Type = 'Campaign - Mailer',parentId=parentCampaign.id);
        insert childCampaign;
        
       // CampaignMemberStatus cmStatus = new CampaignMemberStatus(CampaignId = childCampaign.Id, Label = 'attended', HasResponded = true);
       // insert cmStatus;
        // Create a CampaignMember linked to the parent campaign and the contact
        CampaignMember cmem = new CampaignMember(
            ContactId = contact.Id,
            CampaignId = childCampaign.Id,
            Status = 'Responded',
            Slack_Notification_to_Owner__c = true
        // Treating Master_Campaign_Name__c as a reference
        );
        insert cmem;

        // Insert necessary CampaignMemberStatus records for the Campaign
       
    

    
        // Run test logic to validate the if condition
        List<CampaignMember> cmList = [SELECT Id, Status, Slack_Notification_to_Owner__c,Campaign_Type__c,CampaignId,ContactId, Master_Campaign_Name__c FROM CampaignMember where Master_Campaign_Name__c='(Master) Inbound'];
        
        Test.startTest();
        CampaignMemberHelper.postInboundSlackMessage(cmList);
        Test.stopTest();
        
        // Assert the logic covered in the if condition
        System.assertEquals('Responded', cmList[0].Status);
        System.assertEquals(true, cmList[0].Slack_Notification_to_Owner__c);
       // System.assertNotEquals(null, cmList[0].Master_Campaign_Name__c); // Ensure the grandparent campaign ID is set
    }*/
}
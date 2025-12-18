@isTest  (SeeAllData=false)
public class CampaigntoAdd_Test {
    /*@testSetup
    private static void testDataSetup() {
        Slack_Enabled_Campaign_Type__mdt mdt = new Slack_Enabled_Campaign_Type__mdt(Campaign_Member_Update_Types__c='Website - Form,Partner');
    }*/
     @isTest
    private static void test1() {
        String manualSource = 'true';
        DateTime now;
         Map<Id, Boolean> yoyoContactMap;
         Map<Id, Id> contactToCampaignId = new Map<Id, Id>();
             
   List<Account> newAccount = new List<Account>();
        Account acc = new Account (Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
        newAccount.add(acc);   
        insert newAccount;

   List<Contact> newContacts = new List<Contact>();
   Campaign c = new Campaign();
   c.Name = 'TestCampaign TestCampaign TestCampai';
   c.Type = 'Website - Form';
   insert c;
   Campaign c1 = new Campaign();
   c1.Name = 'TestCampaign TestCampaign TestCampai';
   c1.Type = 'Website Field Event';
   insert c1;
        Map<Id, Contact> contactMap = new Map<Id, Contact>();
       //Contact contact = [select id,Campaign_to_Add__c,FirstName,LastName,Email from Contact limit 1 ];
        Contact con = new Contact (FirstName = 'User', LastName = 'Tester', Email = 'test@test.com', AccountId=acc.Id , Campaign_to_Add__c=c.Id);
        newContacts.add(con);  
        Contact con1 = new Contact (FirstName = 'User1', LastName = 'Tester1', Email = 'test1@test.com', AccountId=acc.Id , Campaign_to_Add__c='1234567890');
        newContacts.add(con1);
        insert newContacts;
        contactMap.put(con.id,con);
    	//contactMap.put(con1.id,con1);
    List<CampaignMember> cmList = new list<CampaignMember>();
     CampaignMember cmem = new CampaignMember();
    cmem.Account__c = con.AccountId;
    cmem.ContactId = con.id;
    cmem.CampaignId = c.Id;
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

                cmList.add(cmem);
        
        CampaignMember cmem1 = new CampaignMember();
    cmem1.Account__c = con.AccountId;
    cmem1.ContactId = con.id;
    cmem1.CampaignId = c1.Id;
        cmem1.utm_campaign__c =  con.utm_campaign_append__c;
                cmem1.utm_content__c = con.utm_content_append__c;
                cmem1.utm_ext_ad_id__c = con.utm_ext_ad_id__c;
                cmem1.utm_ext_adset_id__c = con.utm_ext_adset_id__c;
                cmem1.utm_ext_campaign_id__c = con.utm_ext_campaign_id__c;
                cmem1.utm_medium__c = con.utm_medium_append__c;
                cmem1.utm_source__c = con.utm_source_append__c;
                cmem1.utm_term__c = con.utm_term_append__c;
                cmem1.Campaign_Interaction_Date__c = System.now();
                cmem1.Third_Party_Vendor_Lead_ID__c=con.Third_Party_Vendor_Lead_ID__c;
                cmem1.Google_GCLIDv2__c = con.Google_GCLIDv2__c;
                cmem1.experimentId__c = con.experimentId__c;
                cmem1.Experimental_Group__c = con.Experimental_Group__c;
                cmem1.Lead_Funnel_Trigger_Start__c = con.Lead_Funnel_Trigger_Start__c;
                cmem1.Lead_Funnel_RDS_DB_Insert__c = con.Lead_Funnel_RDS_DB_Insert__c;
                cmem1.Microsoft_MSCLKID__c = con.Microsoft_MSCLIKID__c;
                cmem1.Personalization_Experiment_Id__c = con.Personalization_Experiment_Id__c;

                cmList.add(cmem1);
        
        insert cmList;
        contactToCampaignId.put(cmem.id,con.Id);
        contactToCampaignId.put(cmem1.id,con.Id);
        Map<Id, String> conIdCampName = new Map<Id, String>();
        conIdCampName.put(con.Id, c.Name);
        Map<Id, Campaign> campaignNamesToBeAddedMap = new Map<Id, Campaign>();
        campaignNamesToBeAddedMap.put(con.Id,c);
        
        con.Campaign_to_Add__c = c1.Id;
        Map<Id, Contact> oldContactById = new Map<Id,Contact>();
        oldContactById.put(con.Id,con);
        //system.debug('values' +contactMap +manualSource +now +yoyoContactMap +contactToCampaignId);
         Test.startTest(); 
        CampaigntoAdd.CampaigntoAdd(contactMap, manualSource, now, yoyoContactMap, contactToCampaignId);
        CampaigntoAdd.createRepeatCampaign(campaignNamesToBeAddedMap,conIdCampName);
        CampaigntoAdd.CampaignMemberCheckFuture(oldContactById , contactMap, manualSource, yoyoContactMap, now);
        CampaigntoAdd.CampaigntoAdd(contactMap, manualSource, now, yoyoContactMap, null);
        
         Test.stopTest();
     
    }
    
	@isTest
    private static void test2() {
        String manualSource = 'true';
        DateTime now;
         Map<Id, Boolean> yoyoContactMap;
         Map<Id, Id> contactToCampaignId = new Map<Id, Id>();
             
   List<Account> newAccount = new List<Account>();
        Account acc = new Account (Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
        newAccount.add(acc);   
        insert newAccount;

   List<Contact> newContacts = new List<Contact>();
   Campaign c = new Campaign();
   c.Name = 'TestCampaign TestCampaign TestCampai';
   c.Type = 'Website Field Event';
   insert c;
   Campaign c1 = new Campaign();
   c1.Name = 'TestCampaign TestCampaign TestCampai';
   c1.Type = 'Field Event';
   insert c1;
        Map<Id, Contact> contactMap = new Map<Id, Contact>();
       //Contact contact = [select id,Campaign_to_Add__c,FirstName,LastName,Email from Contact limit 1 ];
        Contact con = new Contact (FirstName = 'User', LastName = 'Tester', Email = 'test@test.com', AccountId=acc.Id , Campaign_to_Add__c=c.Id);
        newContacts.add(con);  
        Contact con1 = new Contact (FirstName = 'User1', LastName = 'Tester1', Email = 'test1@test.com', AccountId=acc.Id , Campaign_to_Add__c='1234567890');
        newContacts.add(con1);
        insert newContacts;
        contactMap.put(con.id,con);
    	//contactMap.put(con1.id,con1);
    List<CampaignMember> cmList = new list<CampaignMember>();
     CampaignMember cmem = new CampaignMember();
    cmem.Account__c = con.AccountId;
    cmem.ContactId = con.id;
    cmem.CampaignId = c.Id;
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

                cmList.add(cmem);
        insert cmList;
        contactToCampaignId.put(cmem.id,con.Id);
        Map<Id, String> conIdCampName = new Map<Id, String>();
        conIdCampName.put(con.Id, c.Name);
        Map<Id, Campaign> campaignNamesToBeAddedMap = new Map<Id, Campaign>();
        campaignNamesToBeAddedMap.put(con.Id,c);
        
        con.Campaign_to_Add__c = c1.Id;
        Map<Id, Contact> oldContactById = new Map<Id,Contact>();
        oldContactById.put(con.Id,con);
        //system.debug('values' +contactMap +manualSource +now +yoyoContactMap +contactToCampaignId);
         Test.startTest(); 
        CampaigntoAdd.CampaigntoAdd(contactMap, manualSource, now, yoyoContactMap, contactToCampaignId);
        CampaigntoAdd.createRepeatCampaign(campaignNamesToBeAddedMap,conIdCampName);
        CampaigntoAdd.CampaignMemberCheckFuture(oldContactById , contactMap, manualSource, yoyoContactMap, now);
        CampaigntoAdd.CampaigntoAdd(contactMap, manualSource, now, yoyoContactMap, null);
        
         Test.stopTest();
     
    }
    
    @isTest
    private static void test3() {
        String manualSource = 'true';
        DateTime now;
         Map<Id, Boolean> yoyoContactMap;
         Map<Id, Id> contactToCampaignId = new Map<Id, Id>();
             
   List<Account> newAccount = new List<Account>();
        Account acc = new Account (Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
        newAccount.add(acc);   
        insert newAccount;

   List<Contact> newContacts = new List<Contact>();
   Campaign c = new Campaign();
   c.Name = 'TestCampaign TestCampaign TestCampai';
   c.Type = 'Field Event';
   insert c;
   Campaign c1 = new Campaign();
   c1.Name = 'TestCampaign TestCampaign TestCampai';
   c1.Type = 'Website - Form';
   insert c1;
        Map<Id, Contact> contactMap = new Map<Id, Contact>();
       //Contact contact = [select id,Campaign_to_Add__c,FirstName,LastName,Email from Contact limit 1 ];
        Contact con = new Contact (FirstName = 'User', LastName = 'Tester', Email = 'test@test.com', AccountId=acc.Id , Campaign_to_Add__c=c.Id);
        newContacts.add(con);  
        Contact con1 = new Contact (FirstName = 'User1', LastName = 'Tester1', Email = 'test1@test.com', AccountId=acc.Id , Campaign_to_Add__c='1234567890');
        newContacts.add(con1);
        insert newContacts;
        contactMap.put(con.id,con);
    	//contactMap.put(con1.id,con1);
    List<CampaignMember> cmList = new list<CampaignMember>();
     CampaignMember cmem = new CampaignMember();
    cmem.Account__c = con.AccountId;
    cmem.ContactId = con.id;
    cmem.CampaignId = c.Id;
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

                cmList.add(cmem);
        insert cmList;
        contactToCampaignId.put(cmem.id,con.Id);
        Map<Id, String> conIdCampName = new Map<Id, String>();
        conIdCampName.put(con.Id, c.Name);
        Map<Id, Campaign> campaignNamesToBeAddedMap = new Map<Id, Campaign>();
        campaignNamesToBeAddedMap.put(con.Id,c);
        
        con.Campaign_to_Add__c = c1.Id;
        Map<Id, Contact> oldContactById = new Map<Id,Contact>();
        oldContactById.put(con.Id,con);
        //system.debug('values' +contactMap +manualSource +now +yoyoContactMap +contactToCampaignId);
         Test.startTest(); 
        CampaigntoAdd.CampaigntoAdd(contactMap, manualSource, now, yoyoContactMap, contactToCampaignId);
        CampaigntoAdd.createRepeatCampaign(campaignNamesToBeAddedMap,conIdCampName);
        CampaigntoAdd.CampaignMemberCheckFuture(oldContactById , contactMap, manualSource, yoyoContactMap, now);
        CampaigntoAdd.CampaigntoAdd(contactMap, manualSource, now, yoyoContactMap, null);
        
         Test.stopTest();
     
    }
}
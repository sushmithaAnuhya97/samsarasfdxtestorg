/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 30, 2021
*
* @description : This class will be responsible to Cover GS_ContactCampaignFieldsUpdateService Class
* SFA-14
*
**/

@isTest
public class GS_ContactCampaignFieldsUpdateTest {
    
    @TestSetup static void setupRecords(){
        insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true);
        List<Account> newAccounts = new List<Account>();
        List<Contact> newContacts = new List<Contact>();
        List<User> poolUsers = new List<User>([SELECT Id, name FROM User WHERE IsActive = TRUE  AND RR_Is_Pool_User__c = TRUE LIMIT 1]);
        List<User> nonPoolUsers = new List<User>([SELECT Id FROM User WHERE RR_Is_Pool_User__c = FALSE LIMIT 1]);
        Account industrialAccount = new Account (Name = 'Acme Industry', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingState='California', Industry = 'Other', Hashtag__c='Ex_Closed_Lost', 
                                                 OwnerId = poolUsers[0].Id, RecordTypeId  = Schema.SObjectType.account.getRecordTypeInfosByName().get('Industrial').getRecordTypeId());
        newAccounts.add(industrialAccount);
        
        insert newAccounts;
        
        Campaign mvf = new Campaign(Name = '(Parent) MVF', Type = 'Website - Form');
        insert mvf;
        
        Contact c1 = (Contact)TestFactory.createSOBject(new Contact(Email = 'Test1@samsaratesting.com',
                                                                   AccountId = industrialAccount.Id,
                                                                   New_Inbound_Lead__c = true,
                                                                   OwnerId = poolUsers[0].Id,
                                                                   Campaign_to_Add__c = mvf.Id,
                                                                   Campaign_Member_Status__c = 'Responded',
                                                                   Source__c = 'Partner Referral',
                                                                   Most_Recent_Source__c = 'Partner Referral'));
        
        insert c1;
        
        Contact c2 = (Contact)TestFactory.createSOBject(new Contact(Email = 'Test2@samsaratesting.com',
                                                                   AccountId = industrialAccount.Id,
                                                                   New_Inbound_Lead__c = true,
                                                                   OwnerId = nonPoolUsers[0].Id,
                                                                   Campaign_to_Add__c = mvf.Id,
                                                                   Campaign_Member_Status__c = 'Responded',
                                                                   Source__c = 'Partner Referral',
                                                                   Most_Recent_Source__c = 'Partner Referral'));
        
        insert c2;
        
        
    }
    @isTest static void updateCampaignFields(){
        Test.startTest();
        Set<Id> contactSetId = new Set<Id>();        
        List<Contact> conList = new List<Contact>();
        Map<Id, Contact> oldContactMap = new Map<Id, Contact>();
        Map<Id, Contact> newContactMap = new Map<Id, Contact>();

        List<User> nonPoolUsers = new List<User>([SELECT Id FROM User WHERE RR_Is_Pool_User__c = FALSE LIMIT 1]);
        List<User> poolUsers = new List<User>([SELECT Id, name FROM User WHERE IsActive = TRUE  AND RR_Is_Pool_User__c = TRUE LIMIT 1]);

        Campaign camp = new Campaign(Name = 'test campaign', Type = 'Website - Form');
        insert camp;
        
        Contact c = [SELECT Id, Name, OwnerId, Owner.Name, Owner_Is_Pool_User__c, Unload_Account__c from Contact WHERE Email = 'Test1@samsaratesting.com' LIMIT 1][0];
        insert new CampaignMember(CampaignId = camp.Id, ContactId = c.Id, Status = 'Sent');
        
        c.OwnerId = nonPoolUsers[0].Id;
        update c;
        c = [SELECT Id, Name, OwnerId, Owner.Name, Owner_Is_Signed_In__c, Owner_Role__c, Owner_Name__c, Owner_Is_Pool_User__c, Unload_Account__c from Contact WHERE id =: c.Id];
        contactSetId.add(c.Id);
        conList.add(c);
        oldContactMap.put(c.Id, c);
        newContactMap.put(c.Id, c);
        new GS_ContactCampaignFieldsUpdateService().updateCampaignFields(oldContactMap, newContactMap);
        GS_ContactCampaignFieldsUpdateService.updateCampaignFieldsFuture(contactSetId);
        List<Schema.SObjectType> MY_SOBJECTS = new List<Schema.SObjectType>{
                CampaignMember.SObjectType
                    };
                        DMLWrapper.intializeUnitOfWork(MY_SOBJECTS);
        GS_ContactCampaignFieldsUpdateService.updateCampaignFields(conList, true);
        Test.stopTest();
       
        List<CampaignMember> cmember = [Select Owner_Role_Copy__c, Inbound_ADR_Toggle_Status__c, Owner_at_Interaction_Lookup__c , Owner_At_Interaction__c from CampaignMember where ContactId =: c.Id];
        system.assertEquals(c.OwnerId, cmember[0].Owner_at_Interaction_Lookup__c);

    }
     @isTest static void updateCampaignFieldsFuture()
     {
         Contact c1 = [SELECT Id, Name, OwnerId, Owner.Name, Owner_Is_Pool_User__c, Unload_Account__c from Contact WHERE Email = 'Test1@samsaratesting.com' LIMIT 1][0];
         Contact c2 = [SELECT Id, Name, OwnerId, Owner.Name, Owner_Is_Pool_User__c, Unload_Account__c from Contact WHERE Email = 'Test2@samsaratesting.com' LIMIT 1][0];
         Map<Id, Contact> oldMap=new Map<Id, Contact>();
         //oldMap.put(c1.Id,C1);
         Map<Id, Contact> newMap=new Map<Id, Contact>();
         //newMap.put(c2.Id,C2);
         Test.startTest();
         GS_ContactCampaignFieldsUpdateService obj = new GS_ContactCampaignFieldsUpdateService();
         obj.updateCampaignFieldsFuture(oldMap,newmap);
         Test.StopTest();
     }
    
}
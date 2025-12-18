/**
 * Created by vikasmishra on 2020-12-07.
 */
@isTest
private class GS_ContactWorkFlowConversionTests {
    
    @TestSetup static void setupRecords(){
       insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true); 
    }
    
    @isTest static void testCampaignToAdd() {
        Campaign c1 = new Campaign(Name = '(Child) Kickfire', Type = 'Website - Form');
        insert c1;
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('wfCampaignToAdd');
        insert acc;

        Contact Con = new Contact();
        con = TestFactory.initializeContact('wfCampaignToAdd');
        con.AccountId = acc.Id;
        con.Campaign_to_Add__c = c1.Id;
        con.Campaign_Member_Status__c = 'Responded';

        test.startTest();
        insert con;
        test.stopTest();

        con = [SELECT Id, Campaign_to_Add__c, Campaign_Member_Status__c FROM Contact WHERE Id = :con.Id LIMIT 1];
        system.assertEquals(con.Campaign_to_Add__c, null);
        system.assertEquals(con.Campaign_Member_Status__c, null);
    }

    @isTest static void testCampaignToAddFieldUpdate() {
        Campaign c1 = new Campaign(Name = '(Child) Kickfire', Type = 'Website - Form');
        insert c1;
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('wfCampaignToAdd');
        insert acc;

        Contact thisContact = new Contact();
        thisContact = TestFactory.initializeContact('wfCampaignToAdd');
        thisContact.AccountId = acc.Id;
        thisContact.Campaign_to_Add__c = c1.Id;
        thisContact.Campaign_Member_Status__c = 'Responded';
        //Google GCLID clear
        thisContact.Google_GCLIDv2__c = 'GCLIDV';
        //utm campaign append clear
        thisContact.utm_campaign__c = 'utm_campaign';
        //utm content append clear
        thisContact.utm_content__c = 'utm_Content';
        //utm ext ad id clear
        thisContact.utm_ext_ad_id__c = 'utm_ext';
        //utm ext adset id clear
        thisContact.utm_ext_adset_id__c = 'utm_ext_adset';
        //utm medium append clear
        thisContact.utm_medium__c = 'utm_medium';
        //utm source append clear
        thisContact.utm_source__c = 'utm_Source';
        //utm term append clear
        thisContact.utm_term__c = 'utm_term';
        test.startTest();
        insert thisContact;
        test.stopTest();

        thisContact = [
                SELECT Id, Campaign_to_Add__c, Google_GCLIDv2__c, utm_campaign__c, utm_content__c, utm_ext_ad_id__c,
                        utm_ext_adset_id__c, utm_medium__c,utm_source__c, utm_term__c, Campaign_Member_Status__c
                FROM Contact
                WHERE Id = :thisContact.Id
                LIMIT 1
        ];
        system.assertEquals(thisContact.Campaign_to_Add__c, null);
        system.assertEquals(thisContact.Campaign_Member_Status__c, null);
        system.assertEquals(thisContact.Google_GCLIDv2__c, null);
        system.assertEquals(thisContact.utm_campaign__c, null);
        system.assertEquals(thisContact.utm_content__c, null);
        system.assertEquals(thisContact.utm_ext_ad_id__c, null);
        system.assertEquals(thisContact.utm_ext_adset_id__c, null);
        system.assertEquals(thisContact.utm_medium__c, null);
        system.assertEquals(thisContact.utm_source__c, null);
        system.assertEquals(thisContact.utm_term__c, null);

    }
}
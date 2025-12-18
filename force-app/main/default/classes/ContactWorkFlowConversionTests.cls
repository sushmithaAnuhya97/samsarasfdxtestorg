/**
 * Created by vikasmishra on 2020-12-07.
 */
@isTest
private class ContactWorkFlowConversionTests {
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
        //system.assertEquals(con.Campaign_to_Add__c, null);
        //system.assertEquals(con.Campaign_Member_Status__c, null);
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
        /*system.assertEquals(thisContact.Campaign_to_Add__c, null);
        system.assertEquals(thisContact.Campaign_Member_Status__c, null);
        system.assertEquals(thisContact.Google_GCLIDv2__c, null);
        system.assertEquals(thisContact.utm_campaign__c, null);
        system.assertEquals(thisContact.utm_content__c, null);
        system.assertEquals(thisContact.utm_ext_ad_id__c, null);
        system.assertEquals(thisContact.utm_ext_adset_id__c, null);
        system.assertEquals(thisContact.utm_medium__c, null);
        system.assertEquals(thisContact.utm_source__c, null);
        system.assertEquals(thisContact.utm_term__c, null);
*/
    }
    @isTest
    static void testBeforeUpdate() {
        Contact newContact = new Contact(Status__c = 'New', Number_of_Calls_by_Current_Owner_Roll_Up__c = 1);
        Contact oldContact = new Contact(Status__c = 'Assigned', Number_of_Calls_by_Current_Owner_Roll_Up__c = 0);
        Account accountDetails = new Account();
        Contact contactDetails = new Contact();
        
        
        Test.startTest();
        ContactWorkflowConversionWS.beforeUpdate(newContact, oldContact, accountDetails, contactDetails);
        Test.stopTest();
        
    }
    @isTest
    static void updateContactForPhoneOpt() {
        Contact newContact = new Contact(Status__c = 'New',Phone_Opt_Out__c=true,MobilePhone='123456',Phone='123644');
        Contact oldContact;
        
        Test.startTest();
        ContactWorkflowConversionWS.updateContactForPhoneOpt(newContact, null);
        Test.stopTest();
        
    }
    
    @isTest
    static void testBeforeUpdate1() {
        Contact newContact = new Contact(Status__c = 'New', Number_of_Calls_by_Current_Owner_Roll_Up__c = 1);
        Contact oldContact = new Contact(Status__c = 'Assigned', Number_of_Calls_by_Current_Owner_Roll_Up__c = 1);
        Account accountDetails = new Account();
        Contact contactDetails = new Contact();
        
        Test.startTest();
        ContactWorkflowConversionWS.beforeUpdate(newContact, oldContact, accountDetails, contactDetails);
        Test.stopTest();
        
    }
    /*@isTest
    static void updateContactStatusToDemoScheduled() {
        Contact newContact = new Contact(Status__c = 'New', Scheduled_Demo_Date__c = System.today(),ADR_Transfer_By__c=null,Hot_Transfer_To__c=null,Source__c='List Import (no prior engagement)');
        Contact oldContact = new Contact(Status__c = 'Assigned', Scheduled_Demo_Date__c = System.today().addDays(1));
        UserRole expressSegmentRole = new UserRole(Name = 'User Role AE1'); 
        insert expressSegmentRole; 
        
        User expressSegmentUser = new User( FirstName = 'JohnnyTest', LastName = 'Test1234Doe',Territory__c  = 'West', Username = 'JohnnyTestTest1234Doe@example.com', Email = 'JohnnyTestTest1234Doe@test.com', Alias = 'jdoe', ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id, UserRoleId = expressSegmentRole.Id,EmailEncodingKey = 'ISO-8859-1',TimeZoneSidKey = 'America/Los_Angeles',LocaleSidKey = 'en_US',LanguageLocaleKey = 'en_US',EmployeeNumber='134523' ); 
        insert expressSegmentUser;
        
        Contact contactDetails = new Contact(ownerId=expressSegmentUser.Id);
        
        
        Test.startTest();
        //ContactWorkflowConversionWS.updateContactStatusToDemoScheduled(newContact, oldContact, contactDetails);
        Test.stopTest();
        
    }*/
     @isTest
    static void outboundSourceForListImport() {
        Contact newContact = new Contact(Source__c='List Import (no prior engagement)',status__c='Qualified');
        Contact oldContact = new Contact();
        
        Test.startTest();
        ContactWorkflowConversionWS.updatePhoneAndEmailOptOut(newContact, oldContact);
        Test.stopTest();
        
    }
    @isTest
    static void updatePhoneAndEmailOptOut() {
        Contact newContact = new Contact(Opt_Out_Request__c='GDPR');
        Contact oldContact = new Contact();
        
        Test.startTest();
        ContactWorkflowConversionWS.updatePhoneAndEmailOptOut(newContact, oldContact);
        Test.stopTest();
        
    }
    @isTest
    static void updatePhoneOptOut() {
        Contact newContact = new Contact(Opt_Out_Request__c='Phone');
        Contact oldContact = new Contact();
        
        Test.startTest();
        ContactWorkflowConversionWS.updatePhoneOptOut(newContact, oldContact);
        Test.stopTest();
        
    }
    @isTest
    static void updateEmailOptOut() {
        Contact newContact = new Contact(Opt_Out_Request__c='Email');
        Contact oldContact = new Contact();
        
        Test.startTest();
        ContactWorkflowConversionWS.updateEmailOptOut(newContact, oldContact);
        Test.stopTest();
        
    }
    @isTest
    static void updateContactForDoNotContact() {
        Contact newContact = new Contact(LastName='Test Email',Email='donotcontact@samsara.com');
        Contact oldContact = new Contact();
        
        Test.startTest();
        ContactWorkflowConversionWS.updateContactForEmailOpt(newContact, oldContact);
        Test.stopTest();
        
    }
    @isTest
    static void updateContactForEmailOpt() {
        Contact newContact = new Contact(Opt_Out_Request__c='Email',Sales_Email_Opt_Out__c=true,Email='test@test.com');
        Contact oldContact = new Contact();
        
        Test.startTest();
        ContactWorkflowConversionWS.updateContactForEmailOpt(newContact, oldContact);
        Test.stopTest();
        
    }
    @isTest
    static void testBeforeInsertUpdateRules() {
        Contact newContact = new Contact(Status__c = 'New');
        Contact oldContact = null;
        Account accountDetails = new Account();
        Contact contactDetails = new Contact();
        
        Test.startTest();
        ContactWorkflowConversionWS.beforeInsertUpdateRules(newContact, oldContact, accountDetails, contactDetails);
        Test.stopTest();
    }
}
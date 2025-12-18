// Modified the class and broke the test cases(as per RT) to make sure that we are not hitting the soql limits.
@isTest
public class ContactTests {

@TestSetup static void setupRecords(){


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

       /* 
        //Revenue Opportunity
        List<Opportunity> newOpportunities = new List<Opportunity>(); 
        Opportunity revenueOpportunity = new Opportunity(Owner_Role_Copy__c = 'My Role', AccountId = industrialAccount.Id, Name = 'Revenue Opportunity', CloseDate = System.today() + 90, StageName = 'Incubate', type = 'Revenue Opportunity');
    newOpportunities.add(revenueOpportunity);

        insert revenueOpportunity;        
      
        //Trail Opportunity
        Opportunity freeTrailOpportunity = new Opportunity(Owner_Role_Copy__c = 'My Role', AccountId = industrialAccount.Id, Name = 'Free Trial', CloseDate = System.today() + 90, 
                                        RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(), 
                          Probability = 0, StageName = 'Ready To Ship', Trial_Status__c = 'Open', type = 'Free Trial Opportunity', 
                                        Planned_Trial_Installation_Date__c = System.today()+5, 
                          Trial_Goal_1__c  = 'Test', Trial_Period__c=30, Trial_Start_Date__c=System.today());
    newOpportunities.add(freeTrailOpportunity);        

        insert freeTrailOpportunity;
        */
        }
    
    //Transferred from ContactHelperTestClass: 12/5/2019 - @author: rsaavedra
  /* @isTest static void testHotTransfer(){
           
            
            Map<Id,Contact> oldMap = new Map<Id, Contact>([SELECT Account.Original_Owner_for_Recycling_Campaign__c, Owner.UserRole.Name,  Account.Original_Owner_for_Recycling_Campaign__r.Name, ADR_Transfer__c, ADR_Transfer_By__c, 
                        OwnerId, ADR_Transfer_Date__c, ADR_Demo_Date__c, ADR_Transfer_Status__c, Hot_Transfer_To__c, AccountId from Contact WHERE Email = 'ttester@a.com']);
            List<Contact> contactList = [SELECT Account.Original_Owner_for_Recycling_Campaign__c, Owner.UserRole.Name,  Account.Original_Owner_for_Recycling_Campaign__r.Name, ADR_Transfer__c, ADR_Transfer_By__c, 
                        OwnerId, ADR_Transfer_Date__c, ADR_Demo_Date__c, ADR_Transfer_Status__c, Hot_Transfer_To__c, AccountId from Contact WHERE Email = 'ttester@a.com'];
          Test.startTest();
            contactList[0].Hot_Transfer_To__c = UserInfo.getUserId();
           update contactList[0];
        
          contactList[0].Status__c = 'Delete Account';
           update contactList[0];
        
            contactList[0].Status__c = 'Qualified';
          contactList[0].Phone  = '123456789';
            contactList[0].MobilePhone  = '12345679';
      update contactList[0];
        
            contactList[0].Status__c = 'Retouch - Confirmed No Opportunity';
           update contactList[0];
        
            contactList[0].Status__c = 'Contact Established';
           update contactList[0];
        
            contactList[0].Status__c = 'Attempting';
           update contactList[0];
        
            contactList[0].Status__c = 'Retouch - Did not Connect';
          contactList[0].Opt_Out_Email_Copy__c  = 'ttester@a.com';
           update contactList[0];

            contactList[0].Status__c = 'Delete Contact Only';
          try{
              update contactList[0];
          }
          catch(Exception e){
              system.assertEquals(true, e.getMessage().contains('Unable to create/update contact because their Email matches another contact'));
          }      
        
          Map<Id,Contact> newMap = new Map<Id, Contact>([SELECT Account.Original_Owner_for_Recycling_Campaign__c, Owner.UserRole.Name,  Account.Original_Owner_for_Recycling_Campaign__r.Name, ADR_Transfer__c, ADR_Transfer_By__c, 
                        OwnerId, ADR_Transfer_Date__c, ADR_Demo_Date__c, ADR_Transfer_Status__c, Hot_Transfer_To__c, AccountId from Contact WHERE Email = 'ttester@a.com']);
    
            ContactHelper.hotTransfer(oldMap, newMap, contactList);
            Test.stopTest();

            List <ADR_Transfer_Log__c> adrTransfer = [SELECT Id FROM ADR_Transfer_Log__c WHERE Contact__c =: contactList[0].Id];
          system.assertEquals(1, adrTransfer.size());
    }  */
    
    @isTest static void methodCall_Test() {
        
        Test.startTest();
        List<Contact> contactList = [SELECT Account.Original_Owner_for_Recycling_Campaign__c, Owner.UserRole.Name,  Account.Original_Owner_for_Recycling_Campaign__r.Name, ADR_Transfer__c, ADR_Transfer_By__c, 
                                                OwnerId, Email, ADR_Transfer_Date__c, ADR_Demo_Date__c, ADR_Transfer_Status__c, Hot_Transfer_To__c, AccountId from Contact WHERE Email = 'ttesterp@a.com'];
        Set<Id> conIdList = new Set<Id>();
        conIdList.add(contactList[0].Id);
        contacthelper.updateCsmSurvey(conIdList);
        contacthelper.updateCampaignFieldsFuture(conIdList);
        contactList[0].CSM_survey__c=true;
        contacthelper.sendSurveyMail(contactList);
        contacthelper.updateCampaignFieldsFuture(conIdList);
        Test.stopTest();
    }
    //Transferred from ContactHelperTestClass: 12/5/2019 - @author: rsaavedra
    @isTest static void testHotTransferCatchCase(){
        Test.startTest();
        List<Contact> contactList = [SELECT Account.Original_Owner_for_Recycling_Campaign__c, Owner.UserRole.Name,  Account.Original_Owner_for_Recycling_Campaign__r.Name, ADR_Transfer__c, ADR_Transfer_By__c, 
                        OwnerId, ADR_Transfer_Date__c, ADR_Demo_Date__c, ADR_Transfer_Status__c, Hot_Transfer_To__c, AccountId from Contact WHERE Email = 'ttesterp@a.com'];
        contactList[0].Hot_Transfer_To__c = UserInfo.getUserId();    
        try{
            update contactList[0];
      } 
        catch(Exception e){
            system.assertEquals(true, e.getMessage().contains('You cannot hot transfer this account. It must be a scheduled demo with'));
        }
        Test.stopTest();
    }

    //Transferred from ContactHelperTestClass: 12/5/2019 - @author: rsaavedra
     @isTest static void testManuallyUnloadContact(){
           Test.startTest();
            List<Contact> contactList = [SELECT Id, Name, Unload_Account__c, Status__c from Contact WHERE Email = 'ttester@a.com'];
        contactList[0].Status__c = 'Retouch - Did Not Connect'; 
            contactList[0].Unload_Account__c  = true; 
                update contactList[0];
           Test.stopTest();
    }
    
    //Transferred from ContactHelperTestClass: 12/5/2019 - @author: rsaavedra
    @isTest static void testManuallyUnloadContactOpenOppException(){
           Test.startTest();
            List<Contact> contactList = [SELECT Id, Name, Unload_Account__c, Status__c from Contact WHERE Email = 'ttesterhashtag@a.com'];
        contactList[0].Status__c = 'Retouch - Did Not Connect'; 
            contactList[0].Unload_Account__c  = true; 
            try{
                update contactList[0];
        } 
            catch(Exception e){
             }           
            Test.stopTest();
    }

    //Transferred from ContactHelperTestClass: 12/5/2019 - @author: rsaavedra
    @isTest static void testManuallyUnloadContactCallsException(){
           Test.startTest();
            List<Contact> contactList = [SELECT Id, Name, Unload_Account__c, Status__c from Contact WHERE Email = 'ttestercall@a.com'];
        contactList[0].Status__c = 'Retouch - Did Not Connect'; 
            contactList[0].Unload_Account__c  = true; 
            try{
                update contactList[0];
        } 
            catch(Exception e){
                system.assertEquals(true, e.getMessage().contains('The account cannot be unloaded: it is an event lead and its account status is still new.'));
             }           
            Test.stopTest();
    }

    //Transferred from ContactHelperTestClass: 12/5/2019 - @author: rsaavedra
    @isTest static void testManuallyUnloadContactStatusException(){
           Test.startTest();
            List<Contact> contactList = [SELECT Id, Name, Unload_Account__c from Contact WHERE Email = 'ttester@a.com'];
            contactList[0].Unload_Account__c  = true; 
            try{
                update contactList[0];
        } 
            catch(Exception e){
                system.assertEquals(true, e.getMessage().contains('You are trying to unload an account but the contact is not at Retouch or Delete Account statuses.'));
             }           
            Test.stopTest();
    }

    @isTest static void manualUnloadContactTransferCheck(){
           Test.startTest();
            List<Contact> contactList = [SELECT Id, Owner.Name, Name, Unload_Account__c, Status__c from Contact WHERE Email = 'ttester@a.com'];
        contactList[0].Status__c = 'Retouch - Did Not Connect'; 
            contactList[0].Unload_Account__c  = true; 
                update contactList[0];
           Test.stopTest();

           Contact c = [SELECT Id, Owner.Name FROM Contact WHERE Email = 'ttester@a.com' LIMIT 1];

           System.assertEquals(c.Owner.Name.contains('Pool'), true);
    }
    
    @isTest static void testStampfulBasisOnContact(){
           Test.startTest();
            List<Contact> contactList = [SELECT Id, Name, Associated_Lawful_Basis__c from Contact WHERE Email = 'ttesterstampfulbasis@a.com'];
            system.assertEquals('Contract',contactList[0].Associated_Lawful_Basis__c);
            Test.stopTest();
    }
    @isTest static void testUpdateCampaignFields() {
        Test.startTest();
          List<User> poolUsers = new List<User>([SELECT Id FROM User WHERE RR_Is_Pool_User__c  = TRUE LIMIT 1]);
          List<User> nonPoolUsers = new List<User>([SELECT Id FROM User WHERE RR_Is_Pool_User__c  = FALSE LIMIT 1]);
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
        User u = [SELECT Id, Enable_Inbound_Leads__c, UserRoleId, UserRole.Name FROM User WHERE IsActive = TRUE AND RR_Is_Pool_User__c  = true][0];
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
        User u = [SELECT Id, Enable_Inbound_Leads__c, UserRoleId, UserRole.Name FROM User WHERE IsActive = TRUE AND RR_Is_Pool_User__c  = true][0];
        User u2 = [SELECT Id, Enable_Inbound_Leads__c, UserRoleId, UserRole.Name FROM User WHERE IsActive = TRUE AND RR_Is_Pool_User__c  = false][1];
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
        Test.setCreatedDate(ctc.Id, DateTime.newInstance(2019, 7, 27));
         CampaignMember[] cm = [SELECT Id, CreatedDate FROM CampaignMember WHERE ContactId = : ctc.Id LIMIT 1];
         if (!cm.isEmpty()) {
             CampaignMember campm = cm[0];
             Test.setCreatedDate(campm.Id, DateTime.newInstance(2019, 7, 27));
         }

        CampaignMember[] cm2 = [SELECT Id, CreatedDate FROM CampaignMember WHERE ContactId = : ctc.Id];
         if (!cm2.isEmpty()) {
             CampaignMember campm2 = cm2[0];
             Test.setCreatedDate(campm2.Id, DateTime.newInstance(2019, 7, 27));
         }

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
        //System.assertEquals('Assigned', c.Status__c);
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
    static void accountDemoDateTest_Insert() {
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
    static void accountDemoDateTest_Update() {
        Account a = new Account(Name='blah', Organization_Size__c='1 - 99', BillingCountry='Canada');
        a.First_Demo_Date__c = null;
        insert a;

        a = [select First_Demo_Date__c from Account where Id = :a.Id];
        System.assertEquals(null, a.First_Demo_Date__c, 'First_Demo_Date__c should be empty - test data inaccurate');

        Contact c = new Contact(LastName='blah', Demo_Date__c=null, AccountId=a.Id);
        c.Scheduled_Demo_Date__c = Datetime.now();
        c.Status__c = 'New';
        insert c;

        c.Status__c = 'Qualified'; // or Demo Completed - Not Qualified
        c.Demo_Date__c = Date.Today();

        System.Test.startTest();
        update c;
        System.Test.stopTest();

        a = [select First_Demo_Date__c from Account where Id = :a.Id];
        //System.assertEquals(c.Scheduled_Demo_Date__c.dateGmt(), a.First_Demo_Date__c, 'Date value was not copied to Account from Contact');
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
        //System.assertEquals(1, members.size(), 'Campaign Member was not created');
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
        //System.assertEquals(1, members.size(), 'Campaign Member was not created');
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
        //System.assertEquals(1, members.size(), 'Campaign Member was not created');
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
        Account a = new Account(Name='blah', Organization_Size__c='1 - 99', BillingCountry='Canada', SAM_Number_Undecorated__c = 'referring');
        a.First_Demo_Date__c = null;
        insert a;

        Contact c = new Contact(LastName='blah', AccountId=a.Id);
        insert c;

        System.Test.startTest();
        c.Referring_Customer_Id__c = 'referring';
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
        Campaign camp1 = new Campaign(Name = 'Test Campaign', Type = 'Website - Form');
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
        //system.assertEquals(lstContact[0].Status__c, 'Demo Scheduled');
        test.stopTest();
        
    } 
    @IsTest
    static void testfunclevel() {
        test.startTest();
        Contact_Normalized_Title__c setting1 = new Contact_Normalized_Title__c();
        setting1.Name = 'Function';
        setting1.Operations__c = 'operations,production,manufacturing,maintenance, quality';
        setting1.Fleet__c = 'fleet,fleet operations,field services,equipment,transportation,dispatch,driver ';
        setting1.Warehouse__c = 'warehouse,plant,branch,facilities,shop'; 
        setting1.Safety__c = 'safety,food safety,health,safety,environment';
        setting1.Logistics__c = 'logistics,supply chain,shipping,distribution,packaging';
        setting1.Public_Works__c = 'water,public works,utilities';
        setting1.IT__c = 'IT,IT operations,systems,technical,technology';
        setting1.Compliance__c = 'compliance,security,risk';
        setting1.Administration__c = 'administration,admin,office,reception,HR,human resources,payroll,client services,customer service';
        setting1.Finance__c = 'purchasing,finance,billing,controller,estimator,procurement,accounting,bookkeeper';
        setting1.Sales_Marketing__c = 'account,product,sales,marketing,biz,dev,business development';
        insert setting1;
        
        Contact_Normalized_Title__c setting2 = new Contact_Normalized_Title__c();
        setting2.Name = 'Level';
        setting2.IC__c = 'assistant,executive assistant,secretary,receptionist,asst';
        setting2.Manager__c = 'GM,senior manager,project manager,superintendent,manager';
        setting2.Associate__c = 'associate,architect,technician,operator,analyst,engineer,specialist,coordinator,administrator,supervisor';
        setting2.Director__c='director,managing director';
        setting2.VP__c = 'VP,SVP,Vice President';
        setting2.Executive__c='executive,owner,head,founder,principal,partner,CEO,CIO,CPO,COO,chief,co-founder';
        insert setting2;
        
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('testfunclevel');
        insert acc;
        
        Contact Con = new Contact();
        con = TestFactory.initializeContact('testfunclevel');
        con.AccountId = acc.Id;
        con.Normalized_Title__c = '';
        //con.Function__c ='';
        con.Level__c ='';
        insert con;
        
        con.Normalized_Title__c = 'production,asst';
        update con;
        con.Normalized_Title__c = 'fleet operations,manager';
        update con;
        con.Normalized_Title__c = 'security,director';
        update con;
        con.Normalized_Title__c = 'purchasing,vp';
        update con;
        con.Normalized_Title__c = 'account,executive';
        update con;
        
        test.stopTest();
    }
    @IsTest
    static void testfunclevel2() {
        test.startTest();
        Contact_Normalized_Title__c setting1 = new Contact_Normalized_Title__c();
        setting1.Name = 'Function';
        setting1.Operations__c = 'operations,production,manufacturing,maintenance, quality';
        setting1.Fleet__c = 'fleet,fleet operations,field services,equipment,transportation,dispatch,driver ';
        setting1.Warehouse__c = 'warehouse,plant,branch,facilities,shop'; 
        setting1.Safety__c = 'safety,food safety,health,safety,environment';
        setting1.Logistics__c = 'logistics,supply chain,shipping,distribution,packaging';
        setting1.Public_Works__c = 'water,public works,utilities';
        setting1.IT__c = 'IT,IT operations,systems,technical,technology';
        setting1.Compliance__c = 'compliance,security,risk';
        setting1.Administration__c = 'administration,admin,office,reception,HR,human resources,payroll,client services,customer service';
        setting1.Finance__c = 'purchasing,finance,billing,controller,estimator,procurement,accounting,bookkeeper';
        setting1.Sales_Marketing__c = 'account,product,sales,marketing,biz,dev,business development';
        insert setting1;
        
        Contact_Normalized_Title__c setting2 = new Contact_Normalized_Title__c();
        setting2.Name = 'Level';
        setting2.IC__c = 'assistant,executive assistant,secretary,receptionist,asst';
        setting2.Manager__c = 'GM,senior manager,project manager,superintendent,manager';
        setting2.Associate__c = 'associate,architect,technician,operator,analyst,engineer,specialist,coordinator,administrator,supervisor';
        setting2.Director__c='director,managing director';
        setting2.VP__c = 'VP,SVP,Vice President';
        setting2.Executive__c='executive,owner,head,founder,principal,partner,CEO,CIO,CPO,COO,chief,co-founder';
        insert setting2;
        
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('testfunclevel');
        insert acc;
        
        Contact Con = new Contact();
        con = TestFactory.initializeContact('testfunclevel');
        con.AccountId = acc.Id;
        con.Normalized_Title__c = '';
        //con.Function__c ='';
        con.Level__c ='';
        insert con;
        
        con.Normalized_Title__c = 'plant,associate';
        update con;
        con.Normalized_Title__c = 'sales,VP';
        update con;
        test.stopTest();
    }
  @isTest
    static void testUpdateContactStatusToAssignedMethod(){
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
    @isTest
    static void testupdateCsmSurvey()
    {
        Account acc = TestFactory.initializeAccount('testupdateCsmSurvey');
        insert acc;
        Contact objCon = TestFactory.initializeContact('testupdateCsmSurvey');
        objCon.AccountId = acc.Id;
        objCon.CSM_survey__c = true;
        insert objCon;
        
        Set<Id> contactIdList = new set<id>();
        contactIdList.add(objCon.id);
        
        test.startTest();
        
        Contacthelper.updateCsmSurvey(contactIdList);
        Contact objCon2 = [Select Id, CSM_survey__c from Contact where Id =: objCon.Id]; 
        system.assertEquals(objCon2.CSM_survey__c,False);
        test.stopTest();
        
    }
    @isTest
    static void testLast_CallCondition(){
        ContactHelper ch = new ContactHelper();
        Account acc = TestFactory.initializeAccount('testupdateCsmSurvey');
        insert acc;
        Contact objCon = TestFactory.initializeContact('testupdateCsmSurvey');
        objCon.AccountId = acc.Id;
        objCon.Last_Call__c = System.Today();
        insert objCon;
        test.startTest();
        ch.Last_CallCondition(objCon);
        test.stopTest();
    }
    @isTest
    static void testLast_CallPreCheck(){
        ContactHelper ch = new ContactHelper();
        Account acc = TestFactory.initializeAccount('testupdateCsmSurvey1');
        insert acc;
        Contact oldCon = TestFactory.initializeContact('testupdateCsmSurvey1');
        oldCon.AccountId = acc.Id;
        oldCon.Last_Call__c = System.Today();
        insert oldCon;
        Contact newCon = TestFactory.initializeContact('testupdateCsmSurvey2');
        newCon.AccountId = acc.Id;
        newCon.Last_Call__c = System.Today();
        insert newCon;
        test.startTest();
        ch.Last_CallPreCheck(oldCon, newCon);
        test.stopTest();
    }
    @isTest
	static void testPopulateAdrAssignment() {
    Profile pf = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
    
    User adrUser1 = new User(
        FirstName = 'ADR',
        LastName = 'Test1',
        Email = 'adr.test1@example.com',
        Username = 'adr.test1@example.com' + System.currentTimeMillis(),
        Alias = 'adr1',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = pf.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        EmployeeNumber = 'BHR-001'
    );
    insert adrUser1;
    
    User adrUser2 = new User(
        FirstName = 'ADR',
        LastName = 'Test2',
        Email = 'adr.test2@example.com',
        Username = 'adr.test2@example.com' + System.currentTimeMillis(),
        Alias = 'adr2',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = pf.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        EmployeeNumber = 'BHR-002'
    );
    insert adrUser2;

    
    List<Book_Of_Business__c> books = new List<Book_Of_Business__c>();
        Book_Of_Business__c book1 = new Book_Of_Business__c(
            Name = 'Test Book 1',
            ADR__c = adrUser1.Id,
            Active__c = true
        );
        books.add(book1);
        
        Book_Of_Business__c book2 = new Book_Of_Business__c(
            Name = 'Test Book 2',
            ADR__c = adrUser1.Id,
            Active__c = true
        );
        books.add(book2);
        
        insert books;
    List<Account> accounts = new List<Account>();
        for(Integer i = 0; i < 3; i++) {
            Account acc = new Account(
                Name = 'Test Account ' + i,
                Organization_Size__c = '5000+',
                BillingStreet = '26 Napier Street',
                BillingCity = 'London',
                BillingPostalCode  = '1030',
                BillingCountry = 'United Kingdom',
                Billing_Email__c  = 'qdasdas@gmail.com',
                ADRAssignment__c = books[0].adr__c
            );
            accounts.add(acc);
        }
        insert accounts;
    
    List<Contact> contacts = new List<Contact>();
    
    Contact con1 = TestFactory.initializeContact('TestContact1');
    con1.AccountId = accounts[0].Id;
    contacts.add(con1);
    
    Contact con2 = TestFactory.initializeContact('TestContact2');
    con2.AccountId = accounts[1].Id;
    contacts.add(con2);
    
    Contact con3 = TestFactory.initializeContact('TestContact3');
    contacts.add(con3);
    
    Test.startTest();
    ContactHelper.populateAdrAssignment(contacts);
    Test.stopTest();
}
	//This method added based GTMS-29989
	//GTMS-29989 START
   @isTest
static void testUpdateOptOutFields() {
    Contact c = [
        SELECT Id, Email, HasOptedOutOfEmail, Sales_Email_Opt_Out__c,
               Gong__Flow_Status__c, Remove_From_Engage_Flow__c
        FROM Contact
        WHERE Email = 'ttester@a.com'
        LIMIT 1
    ];
    c.Gong__Flow_Status__c = 'In Progress';
    c.HasOptedOutOfEmail = false;
    c.Sales_Email_Opt_Out__c = false;
    c.Remove_From_Engage_Flow__c = false;
    update c;
    Contact oldContact = c.clone(false, true);
    c.HasOptedOutOfEmail = true;
    Test.startTest();
        ContactHelper.updateOptoutFields(
            new List<Contact>{ c },
            new Map<Id, Contact>{ c.Id => oldContact }
        );
    Contact oldContactChanged = c.clone(false, true);
    oldContactChanged.Remove_From_Engage_Flow__c = true;
    c.HasOptedOutOfEmail = true;
    c.Remove_From_Engage_Flow__c = false;
        ContactHelper.updateOptoutFields(
            new List<Contact>{ c },
            new Map<Id, Contact>{ c.Id => oldContactChanged }
        );
    Test.stopTest();
}
//GTMS-29989 END

}
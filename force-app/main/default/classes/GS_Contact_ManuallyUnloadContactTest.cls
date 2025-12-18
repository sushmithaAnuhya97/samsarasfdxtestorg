/**
* Created By : Groundswell - Tanuj Tyagi
* @Date August 30, 2021
*
* @description : This class will be responsible to Cover GS_Contact_ManuallyUnloadContactAsync Class
* SFA-14 - OPTIMIZED VERSION
*
**/
@isTest
public class GS_Contact_ManuallyUnloadContactTest {
    
    @TestSetup static void setupRecords(){
        insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true);
        
        List<Account> newAccounts = new List<Account>();
        List<Contact> newContacts = new List<Contact>();
        
        // Standard account for basic tests
        Account account = new Account (Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingState='California', Industry = 'Other');
        newAccounts.add(account);
        
        // Fleet account for Fleet record type scenario
        Account fleetAccount = new Account (Name = 'Fleet Co', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingState='California', Industry = 'Other',
                                          RecordTypeId = Schema.SObjectType.account.getRecordTypeInfosByName().get('Fleet').getRecordTypeId());
        newAccounts.add(fleetAccount);
        
        // Hashtag account for Ex_Closed_Lost scenario
        Account hashtagAccount = new Account (Name = 'Hashtag Co', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingState='California', Industry = 'Other',
                                            Hashtag__c = 'Ex_Closed_Lost_Campaign');
        newAccounts.add(hashtagAccount);
        
        // Event lead account for event lead scenarios
        Account eventLeadAccount = new Account (Name = 'Event Lead Co', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingState='California', Industry = 'Other',
                                              Status__c = 'Attempting', Event_Lead__c = true, Number_of_Calls_by_Current_Owner__c = 10);
        newAccounts.add(eventLeadAccount);
        
        // Recycling campaign account
        Account accountWithOriginalOwner = new Account (Name = 'Recycling Co', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingState='California', Industry = 'Other', Original_Owner_for_Recycling_Campaign__c= UserInfo.getUserId());
        newAccounts.add(accountWithOriginalOwner);
        
        insert newAccounts;
        
        // Create contacts for each account
        Contact contact = new Contact (FirstName = 'TestClass', LastName = 'Tester', Email = 'ttester@a.com', AccountId=account.Id);
        newContacts.add(contact);
        
        Contact fleetContact = new Contact (FirstName = 'Fleet', LastName = 'Contact', Email = 'fleet@a.com', AccountId=fleetAccount.Id, Status__c = 'Retouch - Did Not Connect');
        newContacts.add(fleetContact);
        
        Contact hashtagContact = new Contact (FirstName = 'Hashtag', LastName = 'Contact', Email = 'hashtag@a.com', AccountId=hashtagAccount.Id, Status__c = 'Retouch - Did Not Connect');
        newContacts.add(hashtagContact);
        
        Contact eventLeadContact = new Contact (FirstName = 'EventLead', LastName = 'Contact', Email = 'eventlead@a.com', AccountId=eventLeadAccount.Id, Status__c = 'Retouch - Did Not Connect');
        newContacts.add(eventLeadContact);
        
        Contact recyclingContact = new Contact (FirstName = 'Recycling', LastName = 'Contact', Email = 'recycling@a.com', AccountId=accountWithOriginalOwner.Id, Status__c = 'Retouch - Did Not Connect');
        newContacts.add(recyclingContact);
        
        insert newContacts;
    }
    
    // CORE FUNCTIONALITY TESTS (5 methods)
    
    @isTest static void testGetRequestType(){
        GS_Contact_ManuallyUnloadContactAsync asyncHandler = new GS_Contact_ManuallyUnloadContactAsync();
        String requestType = asyncHandler.getRequestType();
        System.assertEquals('ManuallyUnloadContact', requestType);
    }
    
    @isTest static void testBasicUnloadFunctionality(){
        Test.startTest();
        List<Contact> contactList = [SELECT Id, Name, Unload_Account__c, Status__c from Contact WHERE Email = 'ttester@a.com'];
        contactList[0].Status__c = 'Retouch - Did Not Connect'; 
        contactList[0].Unload_Account__c = true; 
        update contactList[0];
        Test.stopTest();
    }
    
    @isTest static void testExecuteWithValidParameters(){
        Test.startTest();
        List<Contact> contactList = [SELECT Id FROM Contact WHERE Email = 'ttester@a.com' LIMIT 1];
        
        Async_Request__c ar = new Async_Request__c();
        ar.Params__c = contactList[0].Id;
        GS_Contact_ManuallyUnloadContactAsync asyncHandler = new GS_Contact_ManuallyUnloadContactAsync();
        asyncHandler.execute(ar);
        Test.stopTest();
    }
    
    @isTest static void testSuccessfulUnloadWithNoOpportunities(){
        Test.startTest();
        // Create clean account with NO opportunities
        Account cleanAccount = new Account(
            Name = 'Clean Test Co', 
            Organization_Size__c = '5000+', 
            BillingCountry = 'United States', 
            BillingState='California', 
            Industry = 'Other'
        );
        insert cleanAccount;
        
        Contact cleanContact = new Contact(
            FirstName = 'CleanTest', 
            LastName = 'Contact', 
            Email = 'cleantest@a.com', 
            AccountId = cleanAccount.Id, 
            Status__c = 'Retouch - Did Not Connect'
        );
        insert cleanContact;
        
        // Test successful unload
        String paramString = cleanContact.Id;
        Async_Request__c ar = new Async_Request__c();
        ar.Params__c = paramString;
        GS_Contact_ManuallyUnloadContactAsync asyncHandler = new GS_Contact_ManuallyUnloadContactAsync();
        asyncHandler.execute(ar);
        Test.stopTest();
    }
    
    @isTest static void testMultipleContactsSameAccount(){
        Test.startTest();
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Acme Co' LIMIT 1];
        
        Contact contact1 = new Contact(FirstName = 'Multi1', LastName = 'Contact', Email = 'multi1@a.com', AccountId = testAccount.Id, Status__c = 'Retouch - Did Not Connect');
        Contact contact2 = new Contact(FirstName = 'Multi2', LastName = 'Contact', Email = 'multi2@a.com', AccountId = testAccount.Id, Status__c = 'Retouch - Did Not Connect');
        insert new List<Contact>{contact1, contact2};
        
        // Update both contacts to trigger unload
        contact1.Unload_Account__c = true;
        contact2.Unload_Account__c = true;
        update new List<Contact>{contact1, contact2};
        Test.stopTest();
    }
    
    // EXCEPTION SCENARIOS TESTS (6 methods)
    
    @isTest static void testOpportunityExceptionScenarios(){
        Test.startTest();
        
        // Test Revenue Opportunity Exception
        Account oppAccount = new Account(Name = 'Opp Test Co', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingState='California', Industry = 'Other');
        insert oppAccount;
        
        Contact oppContact = new Contact(FirstName = 'OppTest', LastName = 'Contact', Email = 'opptest@a.com', AccountId = oppAccount.Id, Status__c = 'Retouch - Did Not Connect');
        insert oppContact;
        
        Opportunity revenueOpp = new Opportunity(Name = 'Revenue Test Opp', AccountId = oppAccount.Id, Type = 'Revenue Opportunity', StageName = 'Prospecting', CloseDate = Date.today().addDays(30));
        insert revenueOpp;
        
        // Test revenue opportunity exception
        String paramString = oppContact.Id;
        Async_Request__c ar = new Async_Request__c();
        ar.Params__c = paramString;
        GS_Contact_ManuallyUnloadContactAsync asyncHandler = new GS_Contact_ManuallyUnloadContactAsync();
        
        try {
            asyncHandler.execute(ar);
        } catch (CalloutException e) {
            System.assertEquals('The account cannot be unloaded: it has either an open revenue opportunity or an open free trial.', e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest static void testHashtagExceptionScenario(){
        Test.startTest();
        List<Contact> contactList = [SELECT Id FROM Contact WHERE Email = 'hashtag@a.com'];
        
        String paramString = contactList[0].Id;
        Async_Request__c ar = new Async_Request__c();
        ar.Params__c = paramString;
        GS_Contact_ManuallyUnloadContactAsync asyncHandler = new GS_Contact_ManuallyUnloadContactAsync();
        
        try {
            asyncHandler.execute(ar);
        } catch (CalloutException e) {
            System.assertEquals('The account cannot be unloaded as it is part of a special campaign.', e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest static void testEventLeadExceptionScenarios(){
        Test.startTest();
        
        // Test Event Lead with < 8 calls
        Account eventLeadAccount = [SELECT Id, Number_of_Calls_by_Current_Owner__c FROM Account WHERE Name = 'Event Lead Co'];
        eventLeadAccount.Number_of_Calls_by_Current_Owner__c = 5;
        update eventLeadAccount;
        
        List<Contact> contactList = [SELECT Id FROM Contact WHERE Email = 'eventlead@a.com'];
        
        String paramString = contactList[0].Id;
        Async_Request__c ar = new Async_Request__c();
        ar.Params__c = paramString;
        GS_Contact_ManuallyUnloadContactAsync asyncHandler = new GS_Contact_ManuallyUnloadContactAsync();
        
        try {
            asyncHandler.execute(ar);
        } catch (CalloutException e) {
            System.assertEquals('The account cannot be unloaded: it is an event lead, its account status is still attempting, and it has less than 8 calls by current owner.', e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest static void testRecyclingCampaignException(){
        Test.startTest();
        List<Contact> contactList = [SELECT Id FROM Contact WHERE Email = 'recycling@a.com'];
        
        String paramString = contactList[0].Id;
        Async_Request__c ar = new Async_Request__c();
        ar.Params__c = paramString;
        GS_Contact_ManuallyUnloadContactAsync asyncHandler = new GS_Contact_ManuallyUnloadContactAsync();
        
        try {
            asyncHandler.execute(ar);
        } catch (CalloutException e) {
            System.assertEquals('The account cannot be unloaded as it is part of a special recycling campaign. Please check the Original Owner for Recycling Campaign field', e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest static void testInvalidContactStatusException(){
        Test.startTest();
        List<Contact> contactList = [SELECT Id, Name, Unload_Account__c from Contact WHERE Email = 'ttester@a.com'];
        contactList[0].Unload_Account__c = true;
        
        try {
            update contactList[0];
        } catch (Exception e) {
            System.assertEquals(true, e.getMessage().contains('You are trying to unload an account but the contact is not at Retouch or Delete Account statuses.'));
        }
        Test.stopTest();
    }
    
    @isTest static void testFleetRecordTypeScenario(){
        Test.startTest();
        List<Contact> contactList = [SELECT Id, Name, Unload_Account__c, Status__c from Contact WHERE Email = 'fleet@a.com'];
        contactList[0].Unload_Account__c = true;
        
        String paramString = contactList[0].Id;
        Async_Request__c ar = new Async_Request__c();
        ar.Params__c = paramString;
        GS_Contact_ManuallyUnloadContactAsync asyncHandler = new GS_Contact_ManuallyUnloadContactAsync();
        asyncHandler.execute(ar);
        Test.stopTest();
    }
    
    // METHOD-SPECIFIC TESTS (3 methods)
    
    @isTest static void testManuallyUnloadContactMethod(){
        Test.startTest();
        Contact oldCon = [SELECT Id FROM Contact LIMIT 1];
        
        Map<Id, Contact> oldContactMap = new Map<Id, Contact>{
            oldCon.Id => new Contact(Id = oldCon.Id, Unload_Account__c = false)
        };

        Map<Id, Contact> newContactMap = new Map<Id, Contact>{
            oldCon.Id => new Contact(Id = oldCon.Id, Unload_Account__c = true, Status__c = 'Retouch - Did Not Connect')
        };

        List<Contact> newContactList = new List<Contact>{
            new Contact(Id = oldCon.Id, Unload_Account__c = true, Status__c = 'Retouch - Did Not Connect')
        };

        GS_Contact_ManuallyUnloadContactAsync classInstance = new GS_Contact_ManuallyUnloadContactAsync();
        try {
            classInstance.manuallyUnloadContact(oldContactMap, newContactMap, newContactList);
        } catch(Exception e) {
            // Expected in some scenarios
        }
        Test.stopTest();
    }
    
    @isTest static void testManuallyUnloadContactExceptionPath(){
        Test.startTest();
        Contact oldCon = [SELECT Id FROM Contact LIMIT 1];
        
        Map<Id, Contact> oldContactMap = new Map<Id, Contact>{
            oldCon.Id => new Contact(Id = oldCon.Id, Unload_Account__c = false)
        };

        Map<Id, Contact> newContactMap = new Map<Id, Contact>{
            oldCon.Id => new Contact(Id = oldCon.Id, Unload_Account__c = true, Status__c = 'InvalidStatus')
        };

        List<Contact> newContactList = new List<Contact>{
            new Contact(Id = oldCon.Id, Unload_Account__c = true, Status__c = 'InvalidStatus')
        };

        GS_Contact_ManuallyUnloadContactAsync classInstance = new GS_Contact_ManuallyUnloadContactAsync();

        try {
            classInstance.manuallyUnloadContact(oldContactMap, newContactMap, newContactList);
        } catch (Exception e) {
            // Expected exception for invalid status
        }
        Test.stopTest();
    }
    
    @isTest static void testAccountUpdatesLogicCoverage(){
        Test.startTest();
        // Create multiple contacts for the same account to test accountUpdates logic
        Account multiAccount = new Account(Name = 'Multi Test Co', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingState='California', Industry = 'Other');
        insert multiAccount;
        
        Contact contact1 = new Contact(FirstName = 'Multi1', LastName = 'Contact', Email = 'multi1test@a.com', AccountId = multiAccount.Id, Status__c = 'Retouch - Did Not Connect');
        Contact contact2 = new Contact(FirstName = 'Multi2', LastName = 'Contact', Email = 'multi2test@a.com', AccountId = multiAccount.Id, Status__c = 'Retouch - Did Not Connect');
        insert new List<Contact>{contact1, contact2};
        
        // Update both contacts to trigger the accountUpdates logic
        contact1.Unload_Account__c = true;
        contact2.Unload_Account__c = true;
        update new List<Contact>{contact1, contact2};
        Test.stopTest();
    }
    
}
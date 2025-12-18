@isTest
private class GS_ContactHotTransferByFlowTest {
    @TestSetup static void setupRecords(){
        
        insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true);
        
        List<Account> newAccounts = new List<Account>();
        List<Contact> newContacts = new List<Contact>();
        
        Account machineVisionAccount = new Account (Name = 'Acme Industry MV', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingState='California', Industry = 'Other', 
                                                    RecordTypeId  = Schema.SObjectType.account.getRecordTypeInfosByName().get('Machine Vision').getRecordTypeId(), Status__c = 'New', Event_Lead__c = True);
        newAccounts.add(machineVisionAccount);
        
        Account accountWithOriginalOwner = new Account (Name = 'AcmeTwo Co', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingState='California', Industry = 'Other', Original_Owner_for_Recycling_Campaign__c= UserInfo.getUserId());
        newAccounts.add(accountWithOriginalOwner);
        
        Account account = new Account (Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingState='California', Industry = 'Other');
        newAccounts.add(account);
        
        Account account2 = new Account (Name = 'Acme Co2', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingState='California', Industry = 'Other');
        newAccounts.add(account2);
        
        
        insert newAccounts;
        
        Contact contact = new Contact (FirstName = 'TestClass', LastName = 'Tester', Email = 'ttester@a.com', AccountId=account.Id);
        newContacts.add(contact);
        
        Contact contact2 = new Contact (FirstName = 'TestClass', LastName = 'Tester2', Email = 'ttester@a2.com', AccountId=account2.Id);
        newContacts.add(contact2);
        
        Contact contactForCalls = new Contact (FirstName = 'TestClass', LastName = 'TesterCalls', Email = 'ttestercall@a.com', AccountId=machineVisionAccount.Id);
        newContacts.add(contactForCalls);
        
        Contact contactWithOriginalOwner = new Contact (FirstName = 'TestClass', LastName = 'TesterPlus', Email = 'ttesterp@a.com', AccountId=accountWithOriginalOwner.Id);
        newContacts.add(contactWithOriginalOwner);
        
        
        insert newContacts;
    }
    
    
    @isTest static void testHotTransfer(){
        
        
        GS_ContactHotTransferByFlow.ContactInputs conInput = new GS_ContactHotTransferByFlow.ContactInputs();
        
        List<GS_ContactHotTransferByFlow.ContactInputs> conInputList = new List<GS_ContactHotTransferByFlow.ContactInputs>();
        
        Map<Id,Contact> oldMap = new Map<Id, Contact>([SELECT Account.Original_Owner_for_Recycling_Campaign__c, Owner.UserRole.Name,  Account.Original_Owner_for_Recycling_Campaign__r.Name, ADR_Transfer__c, ADR_Transfer_By__c, 
                                                       OwnerId, ADR_Transfer_Date__c,Account.Owner_Role__c,Account.OwnerId, ADR_Demo_Date__c, ADR_Transfer_Status__c, Hot_Transfer_To__c, AccountId from Contact WHERE Email = 'ttester@a.com']);
        List<Contact> contactList = [SELECT Account.Original_Owner_for_Recycling_Campaign__c, Owner.UserRole.Name,  Account.Original_Owner_for_Recycling_Campaign__r.Name, ADR_Transfer__c, ADR_Transfer_By__c, 
                                     OwnerId, ADR_Transfer_Date__c,Account.Owner_Role__c,Account.OwnerId, ADR_Demo_Date__c, ADR_Transfer_Status__c, Hot_Transfer_To__c, AccountId from Contact WHERE Email = 'ttester@a.com'];
        Test.startTest();
        
        conInput.contactId = contactList[0].Id;
        conInput.hotTransferTo = UserInfo.getUserId();
        conInputList.add(conInput);             
        
      GS_ContactHotTransferByFlow.getContactForHotTransfer(conInputList);    
        
        Test.stopTest();
        
        List <ADR_Transfer_Log__c> adrTransfer = [SELECT Id FROM ADR_Transfer_Log__c WHERE Contact__c =: contactList[0].Id];
        
    }
    
    //Transferred from ContactHelperTestClass: 12/5/2019 - @author: rsaavedra
    @isTest static void testHotTransferCatchCase(){
        Test.startTest();
        GS_ContactHotTransferByFlow.ContactInputs conInput = new GS_ContactHotTransferByFlow.ContactInputs();
        
        List<GS_ContactHotTransferByFlow.ContactInputs> conInputList = new List<GS_ContactHotTransferByFlow.ContactInputs>();
        
        List<Contact> contactList = [SELECT Account.Original_Owner_for_Recycling_Campaign__c, Owner.UserRole.Name,  Account.Original_Owner_for_Recycling_Campaign__r.Name, ADR_Transfer__c, ADR_Transfer_By__c, 
                                     OwnerId, ADR_Transfer_Date__c,Account.Owner_Role__c,Account.OwnerId, ADR_Demo_Date__c, ADR_Transfer_Status__c, Hot_Transfer_To__c, AccountId from Contact WHERE Email = 'ttesterp@a.com'];
        conInput.contactId = contactList[0].Id;
        conInput.hotTransferTo = UserInfo.getUserId();
        conInputList.add(conInput);          
        try{
           GS_ContactHotTransferByFlow.getContactForHotTransfer(conInputList);   
        } 
        catch(Exception e){
            system.assertEquals(true, e.getMessage().contains('You cannot hot transfer this account. It must be a scheduled demo with'));
        }
        Test.stopTest();
    }
    
    @isTest static void testHotTransferFleetAE(){
        
        Profile p = [SELECT Id FROM Profile WHERE Name LIKE 'Samsara Sales - NA%' LIMIT 1];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        User u = new User(lastName = 'test',
                          firstName = 'user',
                          email = uniqueName + '@test' + orgId + '.org',
                          Username = uniqueName + '@test' + orgId + '.org',
                          EmailEncodingKey = 'ISO-8859-1',
                          Alias = uniqueName.substring(18, 23),
                          TimeZoneSidKey = 'America/Los_Angeles',
                          LocaleSidKey = 'en_US',
                          LanguageLocaleKey = 'en_US',
                          ProfileId = p.Id,
                          EmployeeNumber='123');
        u.UserRoleId=[select Id from UserRole where Name LIKE 'Fleet IS AE2%' LIMIT 1].Id;
        insert u;
        
        GS_ContactHotTransferByFlow.ContactInputs conInput = new GS_ContactHotTransferByFlow.ContactInputs();
        
        List<GS_ContactHotTransferByFlow.ContactInputs> conInputList = new List<GS_ContactHotTransferByFlow.ContactInputs>();
        
        List<Account> accList = [Select Id, OwnerId from Account Where Name = 'Acme Co2'];
        
        List<Contact> contactList = [SELECT Account.Original_Owner_for_Recycling_Campaign__c, Owner.UserRole.Name,  Account.Original_Owner_for_Recycling_Campaign__r.Name, ADR_Transfer__c, ADR_Transfer_By__c, 
                                     OwnerId, ADR_Transfer_Date__c,Account.Owner_Role__c,Account.OwnerId, ADR_Demo_Date__c, ADR_Transfer_Status__c, Hot_Transfer_To__c, AccountId from Contact WHERE Email = 'ttester@a2.com'];
        Test.startTest();
        /*system.runAs(u){
        	Account a = accList[0];
        	a.OwnerId = u.Id;
        	update a;
    	}*/
        
        
        
        conInput.contactId = contactList[0].Id;
        conInput.hotTransferTo = UserInfo.getUserId();
        conInputList.add(conInput);             
        
        GS_ContactHotTransferByFlow.getContactForHotTransfer(conInputList);    
        
        Test.stopTest();
        
        
        /*List<Account> acc = [select ID, OwnerId from Account Where Id =: contactList[0].AccountId];
       system.assertNotEquals(acc[0].OwnerId, UserInfo.getUserId());*/
    }
    
    @isTest
    static void testContactSelectorMethods() {
        // Create test data
        Account account1 = new Account(Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingState='California', Industry = 'Other');
        Account account2 = new Account(Name = 'Acme Co', Organization_Size__c = '5000+', BillingCountry = 'United States', BillingState='California', Industry = 'Other');
        
        Contact contact1 = new Contact(FirstName = 'test1', LastName = 'ABC');
        Contact contact2 = new Contact(FirstName = 'test2', LastName = 'DEF');
        Contact contact3 = new Contact(FirstName = 'test3', LastName = 'GHI', Opt_Out_Phone__c = '1234567890');
        Contact contact4 = new Contact(FirstName = 'test4', LastName = 'JKL', AccountId = account1.Id, Associated_Lawful_Basis__c = 'Legitimate Interest');
        
        insert new List<SObject>{ contact1, contact2, contact3, contact4, account1, account2 };
            
            Set<Id> contactIds = new Set<Id>{ contact1.Id, contact2.Id };
                Set<String> phoneIds = new Set<String>{ '1234567890' };
                    Set<String> emailIds = new Set<String>{ 'test@gmail.com' };
                        List<Id> accountIds = new List<Id>{ account1.Id };
                            Set<Id> accountIdsSet = new Set<Id>{ account1.Id, account2.Id };
        Test.startTest();                        
        // Test getContactsByIds method
        GS_ContactSelector contactSelector = new GS_ContactSelector(true);
        List<Contact> result = contactSelector.getContactsByIds(contactIds);
        System.assertEquals(2, result.size());
        
        // Test getContactsByAccountIds method
        result = contactSelector.getContactsByAccountIds(accountIdsSet);
        System.assertEquals(0, result.size());
        
        // Test getContactsToCheckDupesByIds method
        result = contactSelector.getContactsToCheckDupesByIds(phoneIds,emailIds);
        System.assertEquals(1, result.size());
        
        // Test getContactsToStampLawfulBasisOnContactByAccountIds method
        result = contactSelector.getContactsToStampLawfulBasisOnContactByAccountIds(accountIds);
        System.assertEquals(0, result.size());
        
        // Test getContactDetailsByIds method
        GS_ContactSelector contactSelectorNoQuery = new GS_ContactSelector(false);
        result = contactSelectorNoQuery.getContactDetailsByIds(contactIds);
        System.assertEquals(2, result.size());
        Test.stopTest();
    }

    
}
@isTest
public class OpportunityAutomationNotesCtrlTest {
    @testSetup
    private static void testDataSetup() {
        
        
        //Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        
        //Create Products
        List<Product2> products = new List<Product2>();
        Product2 vgLicense = new Product2(Name= 'LIC-VG-36MO', ProductCode = 'LIC-VG-36MO', Family = 'Test');
        products.add(vgLicense); 
        Product2 vgLicense1 = new Product2(Name= 'LIC-WIFI-VG-36MO', ProductCode = 'LIC-WIFI-VG-36MO', Family = 'Test');
        products.add(vgLicense1);  
        insert products;
        
        //Create PriceBookEntries
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();        
        PricebookEntry vgLicensePB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vgLicense.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vgLicensePB);
        PricebookEntry vgLicensePB1 = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vgLicense1.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vgLicensePB1);
        insert pricebookEntries;
        
        // Create account
        List<Account> newAccount = new List<Account>();
        Account account = new Account (Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
        newAccount.add(account);
        
        insert newAccount;
        
        Contract cont = new Contract(
            AccountId = newAccount[0].Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            Status = 'Draft'
        );
        insert cont;
        cont.Status = 'Activated';
        update cont;
        
        // Create Contact
        List<Contact> newContacts = new List<Contact>();
        Contact contact = new Contact (FirstName = 'User', LastName = 'Tester', Email = 'test@test.com', AccountId=account.Id);
        newContacts.add(contact);
        
        insert newContacts;
        
        list<SBQQ__Subscription__c> subList = new List<SBQQ__Subscription__c>();
        SBQQ__Subscription__c sub1 = new SBQQ__Subscription__c(
            SBQQ__Quantity__c = 1,
            SBQQ__RenewalPrice__c = 100,
            SBQQ__CustomerPrice__c = 100,
            SBQQ__Contract__c = cont.id,
            SBQQ__Account__c = newAccount[0].id,
            SBQQ__Product__c = vgLicense.id
            
        );
        SBQQ__Subscription__c sub2 = new SBQQ__Subscription__c(
            SBQQ__Quantity__c = 1,
            SBQQ__RenewalPrice__c = 100,
            SBQQ__CustomerPrice__c = 100,
            SBQQ__Contract__c = cont.id,
            SBQQ__Account__c = newAccount[0].id,
            SBQQ__Product__c = vgLicense.id
            
        );
        subList.add(sub2);
        insert subList;
        
        //Create Shipping Address
        List<Shipping_Address__c> shippingAddresses = new  List<Shipping_Address__c>();
        
        Shipping_Address__c shipTo = new Shipping_Address__c(Account__c = account.Id, Shipping_Contact__c = contact.Id, Shipping_Address_Line_1__c = '444 Deharo St'
                                                             , Shipping_City__c = 'San Francisco', Shipping_State__c = 'California', Shipping_Country__c ='United States'
                                                             , Shipping_Zip_Code__c = '95054', Name = 'Ship To One');
        shippingAddresses.add(shipTo);   
        
        insert shippingAddresses;
        
        //Create Opportunity
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity revenueOpportunity = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90, StageName = 'Orders Processing', Owner_Role_Copy__c='EMEA'); 
        newOpportunities.add(revenueOpportunity);
        insert newOpportunities;
        
         /*pse__Grp__c ImplementationServicesGroup = new pse__Grp__c(
            pse__Hierarchy_Depth__c = 0,
            Name = 'Implementation Services Group'
        );
        insert ImplementationServicesGroup;
        
        // Create projects related to the test opportunities
        pse__Proj__c testProject = new pse__Proj__c(
            Name = 'Test Project',
            pse__Account__c = account.Id,
            pse__Opportunity__c = revenueOpportunity.Id,
            Engagement_Type__c = 'Initial Implementation'
        );
        insert testProject;*/
        
        
    }
    
    @isTest
    static void shouldTestWIFIAutomationNotes() {
        
        Test.startTest();
        Profile financeProfile = [SELECT Id FROM Profile WHERE Name = 'Order Operations Admin' LIMIT 1];
        
        // Create the test user, including the required EmployeeNumber field
        User financeUser = new User(
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Email = 'testuser@example.com',
            Alias = 'testuser',
            ProfileId = financeProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            UserPermissionsOfflineUser = false,
            EmployeeNumber = '12345',
            LastName = 'Test'
        );
        insert financeUser;
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        System.runAs(financeUser) {
            
            List<PriceBookEntry> vgLicensePB = [SELECT Id, UnitPrice  FROM PriceBookEntry LIMIT 2];
            Opportunity queriedOpp = [SELECT Id, StageName, Automation_Notes__c FROM Opportunity LIMIT 1];
            
            List<OpportunityLineItem> oppLineItem = new List<OpportunityLineItem>();
            OpportunityLineItem li = new OpportunityLineItem (Quantity=5, OpportunityId= queriedOpp.Id, PriceBookEntryId=vgLicensePB[0].Id, UnitPrice = vgLicensePB[0].UnitPrice);
            OpportunityLineItem li1 = new OpportunityLineItem (Quantity=5, OpportunityId= queriedOpp.Id, PriceBookEntryId=vgLicensePB[1].Id, UnitPrice = vgLicensePB[1].UnitPrice);
            oppLineItem.add(li);
            oppLineItem.add(li1);
            
            insert oppLineItem;
            queriedOpp.StageName = 'Purchase';
            
            update queriedOpp;
            Test.stopTest();
            Opportunity queriedOpp1 = [SELECT Id, StageName, Automation_Notes__c FROM Opportunity WHERE StageName = 'Purchase' LIMIT 1];
            queriedOpp1.StageName = 'Orders Processing';
            
            update queriedOpp1;
            TriggerHandler.clearAllBypasses();
            Opportunity queriedOpp2 = [SELECT Id, StageName, Automation_Notes__c FROM Opportunity LIMIT 1];
            System.debug('queriedOpp1.Automation_Notes__c '+queriedOpp2.Automation_Notes__c);
            
        }
    }
    
   
    @isTest
    static void testReadyToShipStage() {
        
        Test.startTest();
        Profile financeProfile = [SELECT Id FROM Profile WHERE Name = 'Order Operations Admin' LIMIT 1];
        
        // Create the test user, including the required EmployeeNumber field
        User financeUser = new User(
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Email = 'testuser@example.com',
            Alias = 'testuser',
            ProfileId = financeProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            UserPermissionsOfflineUser = false,
            EmployeeNumber = '12345',
            LastName = 'Test'
        );
        insert financeUser;
        System.runAs(financeUser) {
            
            List<PriceBookEntry> vgLicensePB = [SELECT Id, UnitPrice  FROM PriceBookEntry LIMIT 2];
            Opportunity queriedOpp = [SELECT Id, StageName, Automation_Notes__c FROM Opportunity LIMIT 1];
            
            List<OpportunityLineItem> oppLineItem = new List<OpportunityLineItem>();
            OpportunityLineItem li = new OpportunityLineItem (Quantity=5, OpportunityId= queriedOpp.Id, PriceBookEntryId=vgLicensePB[0].Id, UnitPrice = vgLicensePB[0].UnitPrice);
            OpportunityLineItem li1 = new OpportunityLineItem (Quantity=5, OpportunityId= queriedOpp.Id, PriceBookEntryId=vgLicensePB[1].Id, UnitPrice = vgLicensePB[1].UnitPrice);
            oppLineItem.add(li);
            oppLineItem.add(li1);
            
            insert oppLineItem;
            TriggerHandler.bypass('OpportunityTriggerHandlerContext');
            queriedOpp.StageName = 'Orders Processing';
            queriedOpp.Automation_Notes__c = 'Test Automation';
            
            update queriedOpp;
            TriggerHandler.clearAllBypasses();
            Test.stopTest();
            Opportunity queriedOpp1 = [SELECT Id, StageName, Automation_Notes__c FROM Opportunity WHERE StageName = 'Orders Processing' LIMIT 1];
            queriedOpp1.StageName = 'Ready To Ship';
            
            update queriedOpp1;
            Opportunity queriedOpp2 = [SELECT Id, StageName, Automation_Notes__c FROM Opportunity LIMIT 1];
            System.debug('queriedOpp1.Automation_Notes__c '+queriedOpp2.Automation_Notes__c);
            
        }
    }
    
}
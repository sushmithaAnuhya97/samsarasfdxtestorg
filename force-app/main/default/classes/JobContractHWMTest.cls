/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-02-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest(SeeAllData=false)
public class JobContractHWMTest {
    
    @testSetup
    private static void testDataSetup() {
        List<Opportunity> newOpportunities = new List<Opportunity>();
        List<Account> newAccounts = new List<Account>();
        List<Contact> newContacts = new List<Contact>();
        List<Shipping_Address__c> shippingAddressList = new List<Shipping_Address__c>();
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs (thisUser) {
            List<User> testUsers = new List<User>{
                new User(lastName = 'Tyler McGrath',
                         Alias = 'test1',
                         Email = 'tuser@test1.com',
                         Username = 'tuser@test001tests.com',
                         CommunityNickname = 'User16529768062775798018',
                         UserRoleId = [select Id,name from UserRole where name like '%AE3%' limit 1].id,
                         ProfileId = [select Id,name from Profile where name like '%Samsara Sales Management - New System%' limit 1].id,
                         EmployeeNumber = '9000134',
                         Territory__c = 'North America',
                         TimeZone__c = 'America/Los_Angeles',
                         TimeZoneSidKey = 'America/Los_Angeles',
                         LocaleSidKey = 'en_US',
                         LanguageLocaleKey = 'en_US',
                         EmailEncodingKey = '   ISO-8859-1')
                    
                    };
                        Insert testUsers;
            Account accountOne = new Account(Name = 'Testers 1 Inc',
                                             BillingStreet = '26 Napier Street',
                                             BillingCity = 'London',
                                             BillingPostalCode  = '1030',
                                             BillingCountry = 'United Kingdom',
                                             ownerId = testUsers[0].Id,
                                             Billing_Email__c  = 'qdasdas@gmail.com',
                                             Organization_Size__c = '100 - 499',
                                             Renewal_AE__c =   testUsers[0].Id, 
                                             Industry = 'Other');
            newAccounts.add(accountOne);
            
            Account accountTwo = new Account(Name = 'Testers 6 Inc',
                                             BillingState='California',
                                             BillingCountry = 'United States',
                                             BillingStreet = '26 Napier Street',
                                             BillingCity = 'London',
                                             BillingPostalCode  = '1030',
                                             ownerId = testUsers[0].Id,
                                             Billing_Email__c  = 'qdasdas@gmail.com',
                                             Organization_Size__c = '100 - 499',
                                             Renewal_AE__c =   testUsers[0].Id,
                                             Approved_Payment_Type__c = 'Direct Monthly',
                                             Industry = 'Other');
            newAccounts.add(accountTwo);
            
            insert newAccounts;
            
            Contract cont = new Contract(
                AccountId = accountOne.Id,
                StartDate = System.today(),
                EndDate   = System.today().addDays(30),
                ContractTerm = 1,   
                HWM_Value__c = 4000,
                HWM_Threshold__c = 10.0, 
                Auto_Renewal__c = true,
                Status = 'Draft'
            );
            
            insert cont;
            cont.Status = 'Activated';
            update cont;
            Contact contactOne = (Contact) TestFactory.createSObject(new Contact(AccountId = accountOne.Id));
            newContacts.add(contactOne);
            
            Contact contactTwo = (Contact) TestFactory.createSObject(new Contact(AccountId = accountTwo.Id, Email = 'test@test.com'));
            newContacts.add(contactTwo);
            
            insert newContacts;
            
            Shipping_Address__c sa = new Shipping_Address__c(Shipping_Zip_Code__c = '94105', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='1 Dolores, Dallas', Shipping_City__c='Dallas', Shipping_Country__c='United States', Shipping_State__c='Texas', Name='Test', Account__c = accountOne.Id);
            shippingAddressList.add(sa);
            Shipping_Address__c sa2 = new Shipping_Address__c(Shipping_Zip_Code__c = '2030', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='Scheldelaan 417', Shipping_City__c='Antwerpen', Shipping_Country__c='Belgium', Name='Test Belgium', Account__c = accountOne.Id);
            shippingAddressList.add(sa2);
            Shipping_Address__c sa3 = new Shipping_Address__c(Shipping_Zip_Code__c = 'C.P. 45610', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='Adolf B Horn 1737-1', Shipping_City__c='San Pedro Tlaquepaque, Jal', Shipping_Country__c='Mexico', Name='Test Mexico', Account__c = accountOne.Id);
            shippingAddressList.add(sa3);
            
            insert shippingAddressList;
            
            
        }
        
    }
    //Revenue Opportunity - closed won
    @isTest static void TestJobContractHWMMethod1() {
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Contact contactOne = [select id from contact limit 1];
        Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
        Contract contrct = [select id from Contract limit 1 ];
        
        
        Opportunity opportunityOne = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 1 Inc',
                                                      StageName = 'Closed Won',
                                                       CloseDate = Date.today(),
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Split_New_ACV__c = 100.00,
                                                      License_Term__c =12,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      SBQQ__RenewedContract__c = contrct.Id,
                                                      Send_Invoice__c = false));
        newOpportunities.add(opportunityOne); 
        
        insert newOpportunities; 
        test.startTest();
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=newOpportunities[0].Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
        insert li;

        
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        
        SBQQ__Subscription__c sub = new SBQQ__Subscription__c();
        sub.SBQQ__Contract__c= contrct.id;
        sub.SBQQ__Quantity__c = 1;
        sub.Prior_OppId_Legacy__c = newOpportunities[0].id;
        insert sub;
        String query1='Select Id From Contract where  RecordTypeName__c!=\'Free Trial\' AND Account.Segment__c IN (\'Enterprise\',\'AE3\') AND Account.CurrencyIsoCode IN (\'USD\',\'CAD\',\'MXN\')  AND SBQQ__Opportunity__c!=null AND Account.Exclude_HWM__c=false ';
        JobContractHWM jcop = new JobContractHWM(query1,null);
        Database.executeBatch(jcop);
        test.stopTest();
    }
    //Rebate Opportunity - stage - Closed won and contract id is null passed to batch
    @isTest static void TestJobContractHWMMethod2() {
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Contact contactOne = [select id from contact limit 1];
        Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
        Contract contrct = [select id from Contract limit 1 ];
         test.startTest();
         Opportunity opportunityreturning = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'Opp Testers 1 Inc',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      SBQQ__RenewedContract__c = contrct.Id,
                                                      Send_Invoice__c = false));
        insert opportunityreturning;
        Opportunity opportunityOne = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Rebate',
                                                      Name = 'Opp Testers 1 Inc',
                                                      Rebate_Type__c = 'Delinquent',
                                                      Returning_Opportunity__c = opportunityreturning.id,
                                                      StageName = 'Closed Won',
                                                       CloseDate = Date.today(),
                                                      Amount_Received__c = -150.00,
                                                      Amount =-150.00,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      Send_Invoice__c = false));
        newOpportunities.add(opportunityOne); 
       
        insert newOpportunities; 
        
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=newOpportunities[0].Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
        insert li;

        
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        
        SBQQ__Subscription__c sub = new SBQQ__Subscription__c();
        sub.SBQQ__Contract__c= contrct.id;
        sub.SBQQ__Quantity__c = 1;
        sub.Prior_OppId_Legacy__c = newOpportunities[0].id;
        insert sub;
        
        String query1='Select Id From Contract where  RecordTypeName__c!=\'Free Trial\' AND Account.Segment__c IN (\'Enterprise\',\'AE3\') AND Account.CurrencyIsoCode IN (\'USD\',\'CAD\',\'MXN\')  AND SBQQ__Opportunity__c!=null AND Account.Exclude_HWM__c=false';
        JobContractHWM jcop = new JobContractHWM(query1,null);
        Database.executeBatch(jcop);
        test.stopTest();
    }
    //Rebate Opportunity - stage - Closed won
    @isTest static void TestJobContractHWMMethod3() {
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Contact contactOne = [select id from contact limit 1];
        Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
        Contract contrct = [select id from Contract limit 1 ];
         test.startTest();
         Opportunity opportunityreturning = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'Opp Testers 1 Inc',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      SBQQ__RenewedContract__c = contrct.Id,
                                                      Send_Invoice__c = false));
        insert opportunityreturning;
        Opportunity opportunityOne = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Rebate',
                                                      Name = 'Opp Testers 1 Inc',
                                                      Rebate_Type__c = 'Delinquent',
                                                      Returning_Opportunity__c = opportunityreturning.id,
                                                      StageName = 'Closed Won',
                                                       CloseDate = Date.today(),
                                                      Amount_Received__c = -150.00,
                                                      Amount =-150.00,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      Send_Invoice__c = false));
        newOpportunities.add(opportunityOne); 
       
        insert newOpportunities; 
        
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=newOpportunities[0].Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
        insert li;

        
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        
        SBQQ__Subscription__c sub = new SBQQ__Subscription__c();
        sub.SBQQ__Contract__c= contrct.id;
        sub.SBQQ__Quantity__c = 1;
        sub.Prior_OppId_Legacy__c = newOpportunities[0].id;
        insert sub;
        String query = 'Select Id From Contract where id != null';
        JobContractHWM jcop = new JobContractHWM(query,null);
        Database.executeBatch(jcop);
        test.stopTest();
    }
    @isTest static void TestJobContractHWMMethod3a() {
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Contact contactOne = [select id from contact limit 1];
        Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
        Contract contrct = [select id from Contract limit 1 ];
         test.startTest();
         Opportunity opportunityreturning = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'Opp Testers 1 Inc',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      Send_Invoice__c = false));
        insert opportunityreturning;
        Opportunity opportunityOne = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Rebate',
                                                      Name = 'Opp Testers 1 Inc',
                                                      Rebate_Type__c = 'Delinquent',
                                                      Returning_Opportunity__c = opportunityreturning.id,
                                                      StageName = 'Closed Won',
                                                       CloseDate = Date.today(),
                                                      Amount_Received__c = -150.00,
                                                      Amount =-150.00,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      Send_Invoice__c = false));
        newOpportunities.add(opportunityOne); 
       
        insert newOpportunities; 
        
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=opportunityreturning.Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
        insert li;

        
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        
        SBQQ__Subscription__c sub = new SBQQ__Subscription__c();
        sub.SBQQ__Contract__c= contrct.id;
        sub.SBQQ__Quantity__c = 1;
        sub.Prior_OppId_Legacy__c = newOpportunities[0].id;
        insert sub;
        String query = 'Select Id From Contract where id != null';
        JobContractHWM jcop = new JobContractHWM(query,null);
        Database.executeBatch(jcop);
        test.stopTest();
    }
    @isTest static void TestJobContractHWMMethod3b() {
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Contact contactOne = [select id from contact limit 1];
        Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
        Contract contrct = [select id from Contract limit 1 ];
         test.startTest();
         Opportunity opportunityreturning = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'Opp Testers 1 Inc',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      Send_Invoice__c = false));
        insert opportunityreturning;
        Opportunity opportunityOne = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Rebate',
                                                      Name = 'Opp Testers 1 Inc',
                                                      Rebate_Type__c = 'Delinquent',
                                                      Returning_Opportunity__c = null,
                                                      StageName = 'Closed Won',
                                                       CloseDate = Date.today(),
                                                      Amount_Received__c = -150.00,
                                                      Amount =-150.00,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      Send_Invoice__c = false));
        newOpportunities.add(opportunityOne); 
       
        insert newOpportunities; 
        
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=newOpportunities[0].Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
        insert li;

        
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        
        SBQQ__Subscription__c sub = new SBQQ__Subscription__c();
        sub.SBQQ__Contract__c= contrct.id;
        sub.SBQQ__Quantity__c = 1;
        sub.Prior_OppId_Legacy__c = newOpportunities[0].id;
        insert sub;
        String query = 'Select Id From Contract where id != null';
        JobContractHWM jcop = new JobContractHWM(query,null);
        Database.executeBatch(jcop);
        test.stopTest();
    }
    //Rebate Opportunity - stage - Closed won and close date is 120 days from today
    @isTest static void TestJobContractHWMMethod4() {
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Contact contactOne = [select id from contact limit 1];
        Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
        Contract contrct = [select id from Contract limit 1 ];
         test.startTest();
         Opportunity opportunityreturning = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'Opp Testers 1 Inc',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      Send_Invoice__c = false));
        insert opportunityreturning;
        Opportunity opportunityOne = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Rebate',
                                                      Name = 'Opp Testers 1 Inc',
                                                      Rebate_Type__c = 'Delinquent',
                                                      Returning_Opportunity__c = opportunityreturning.id,
                                                      StageName = 'Closed Won',
                                                      Amount_Received__c = -150.00,
                                                      Amount =-150.00,
                                                      License_Term__c = 12,
                                                       CloseDate = Date.today().adddays(120),
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      Send_Invoice__c = false));
        newOpportunities.add(opportunityOne); 
       
        insert newOpportunities; 
        
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=newOpportunities[0].Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
        insert li;

        
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        
        SBQQ__Subscription__c sub = new SBQQ__Subscription__c();
        sub.SBQQ__Contract__c= contrct.id;
        sub.SBQQ__Quantity__c = 1;
        sub.Prior_OppId_Legacy__c = newOpportunities[0].id;
        insert sub;
        String query = 'Select Id From Contract where id != null';
        JobContractHWM jcop = new JobContractHWM(query,null);
        Database.executeBatch(jcop);
        test.stopTest();
    }
    //Rebate Opportunity - stage - Closed won and closeddate is today
    @isTest static void TestJobContractHWMMethod5() {
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Contact contactOne = [select id from contact limit 1];
        Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
        Contract contrct = [select id from Contract limit 1 ];
         test.startTest();
         Opportunity opportunityreturning = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'Opp Testers 1 Inc',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      Send_Invoice__c = false));
        insert opportunityreturning;
        Opportunity opportunityOne = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Rebate',
                                                      Name = 'Opp Testers 1 Inc',
                                                      Rebate_Type__c = 'Delinquent',
                                                      Returning_Opportunity__c = opportunityreturning.id,
                                                      StageName = 'Closed Won',
                                                       CloseDate = Date.today(),
                                                      Amount_Received__c = -150.00,
                                                      Amount =-150.00,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      Send_Invoice__c = false));
        newOpportunities.add(opportunityOne); 
       
        insert newOpportunities; 
        
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=newOpportunities[0].Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
        insert li;

        
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        
        SBQQ__Subscription__c sub = new SBQQ__Subscription__c();
        sub.SBQQ__Contract__c= contrct.id;
        sub.SBQQ__Quantity__c = 1;
        sub.Prior_OppId_Legacy__c = newOpportunities[0].id;
        insert sub;
        String query = 'Select Id From Contract where id != null';
        JobContractHWM jcop = new JobContractHWM(query,contrct.Id);
        Database.executeBatch(jcop);
        test.stopTest();
    }
    //Rebate Opportunity - stage - Closed won and close date is date.newInstance(2022, 11, 21),
    @isTest static void TestJobContractHWMMethod6() {
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Contact contactOne = [select id from contact limit 1];
        Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
        Contract contrct = [select id from Contract limit 1 ];
         test.startTest();
         Opportunity opportunityreturning = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'Opp Testers 1 Inc',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      Send_Invoice__c = false));
        insert opportunityreturning;
        Opportunity opportunityOne = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Rebate',
                                                      Name = 'Opp Testers 1 Inc',
                                                      Rebate_Type__c = 'Delinquent',
                                                      Returning_Opportunity__c = opportunityreturning.id,
                                                      StageName = 'Closed Won',
                                                      Amount_Received__c = -150.00,
                                                      Amount =-150.00,
                                                       CloseDate = date.newInstance(2022, 11, 21),
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      Send_Invoice__c = false));
        newOpportunities.add(opportunityOne); 
       
        insert newOpportunities; 
        
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=newOpportunities[0].Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
        insert li;

        
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        
        SBQQ__Subscription__c sub = new SBQQ__Subscription__c();
        sub.SBQQ__Contract__c= contrct.id;
        sub.SBQQ__Quantity__c = 1;
        sub.Prior_OppId_Legacy__c = newOpportunities[0].id;
        insert sub;
        String query = 'Select Id From Contract where id != null';
        JobContractHWM jcop = new JobContractHWM(query,contrct.Id);
        Database.executeBatch(jcop);
        test.stopTest();
    }
    //Remorse Refund Opportunity - stage - Closed won and contract id !=null
     @isTest static void TestJobContractHWMMethod7() {
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Contact contactOne = [select id from contact limit 1];
        Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
        Contract contrct = [select id from Contract limit 1 ];
         test.startTest();
         Opportunity opportunityreturning = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'Opp Testers 1 Inc',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Split_New_ACV__c = 100.00,
                                                      Send_Invoice__c = false));
        insert opportunityreturning;
        Opportunity opportunityOne = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Remorse Refund',
                                                      Name = 'Opp Testers 1 Inc',
                                                      Rebate_Type__c = 'Delinquent',
                                                      Returning_Opportunity__c = opportunityreturning.id,
                                                      StageName = 'Closed Won',
                                                       CloseDate = Date.today(),
                                                      Amount_Received__c = -150.00,
                                                      Amount =-150.00,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      Send_Invoice__c = false));
        newOpportunities.add(opportunityOne); 
       
        insert newOpportunities; 
        
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=newOpportunities[0].Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
        insert li;

        
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        
        SBQQ__Subscription__c sub = new SBQQ__Subscription__c();
        sub.SBQQ__Contract__c= contrct.id;
        sub.SBQQ__Quantity__c = 1;
        sub.Prior_OppId_Legacy__c = newOpportunities[0].id;
        insert sub;
        String query = 'Select Id From Contract where id != null';
        JobContractHWM jcop = new JobContractHWM(query,contrct.Id);
        Database.executeBatch(jcop);
        test.stopTest();
    }
     //Remorse Refund Opportunity - stage - Closed won and scheduled batch job
    @isTest static void TestJobContractHWMMethod8() {
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Contact contactOne = [select id from contact limit 1];
        Account accountOne =[select id, name from account where Name = 'Testers 1 Inc'];
        Contract contrct = [select id from Contract limit 1 ];
         test.startTest();
         Opportunity opportunityreturning = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'Opp Testers 1 Inc',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Split_New_ACV__c = 100.00,
                                                      Send_Invoice__c = false));
        insert opportunityreturning;
        Opportunity opportunityOne = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id, 
                                                      Type = 'Remorse Refund',
                                                      Name = 'Opp Testers 1 Inc',
                                                      Rebate_Type__c = 'Delinquent',
                                                      Returning_Opportunity__c = opportunityreturning.id,
                                                      StageName = 'Closed Won',
                                                       CloseDate = Date.today(),
                                                      Amount_Received__c = -150.00,
                                                      Amount =-150.00,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      Split_New_ACV__c = 100.00,
                                                      Split_Renewal_ACV__c = 100.00,
                                                      Send_Invoice__c = false));
        newOpportunities.add(opportunityOne); 
       
        insert newOpportunities; 
        
        Product2 prod = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        
        OpportunityLineItem li = new OpportunityLineItem (Quantity=1, OpportunityId=newOpportunities[0].Id, PriceBookEntryId=standardPrice.Id, UnitPrice = 10000);
        insert li;

        
        contrct.SBQQ__Opportunity__c = newOpportunities[0].id;
        update contrct;
        
        SBQQ__Subscription__c sub = new SBQQ__Subscription__c();
        sub.SBQQ__Contract__c= contrct.id;
        sub.SBQQ__Quantity__c = 1;
        sub.Prior_OppId_Legacy__c = newOpportunities[0].id;
        insert sub;
        JobContractHWM jcop = new JobContractHWM(null,contrct.Id);
        Database.executeBatch(jcop);
        JobContractHWM m = new JobContractHWM(null,null);
        String seconds = '0'; //Execute at Zero Seconds
        String minutes = '0'; //Execute at every 0 minute of hour
        String hours = '6,18'; // Execute at 1 AM
        String dayOfMonth = '?'; // Execute Every Day of the Month
        String month = '*'; //Execute every Month
        String dayOfWeek = '*'; //Execute on all 7 days of the Week
        
        //Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
        String sch = seconds + ' ' + minutes + ' ' + hours + ' ' + dayOfMonth + ' ' + month + ' ' + dayOfWeek;
        //String sch = '0 0 01 * * ?';
        system.schedule('JobContractHWM Run Every Day at 7:15 am 7:15pm', sch, m);
        String query = 'Select Id From Contract where id != null';
        JobContractHWM jcop1 = new JobContractHWM(query,contrct.Id);
        Database.executeBatch(jcop1);
        test.stopTest();
    }
   
  /*@isTest
  public static void testStep2() {
    JobContractHWM.testCoverage();
  }*/     
}
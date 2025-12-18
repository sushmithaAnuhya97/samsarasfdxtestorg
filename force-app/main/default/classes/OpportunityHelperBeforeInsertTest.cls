/**********************************************************************
Name: OpportunityHelperBeforeInsertTest

Purpose: This class will contain test methods related to OpportunityHelperBeforeInsert Context                                                       

History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2025-Apr-11        INITIAL DEVELOPMENT 

***********************************************************************/
@isTest(SeeAllData=false)
public class OpportunityHelperBeforeInsertTest {
    @testSetup
    private static void testDataSetup() {
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        insert new Global_Automation_Settings__c(Name = 'Automation_Settings',Allow_Handler_Selection__c = true);
        List<Opportunity> newOpportunities = new List<Opportunity>();
        List<Account> newAccounts = new List<Account>();
        List<Contact> newContacts = new List<Contact>();
        List<Shipping_Address__c> shippingAddressList = new List<Shipping_Address__c>();
        Account accountOne = new Account(Name = 'Testers 1 Inc',
                                         BillingStreet = '26 Napier Street',
                                         BillingCity = 'London',
                                         BillingPostalCode  = '1030',
                                         BillingCountry = 'United Kingdom',
                                         Billing_Email__c  = 'qdasdas@gmail.com',
                                         Organization_Size__c = '100 - 499',
                                         Renewal_AE__c =UserInfo.getUserId(),
                                         Industry = 'Other');
        newAccounts.add(accountOne);
        Account accountTwo = new Account(Name = 'Testers 6 Inc',
                                         BillingState='California',
                                         BillingCountry = 'United States',
                                         BillingStreet = '26 Napier Street',
                                         BillingCity = 'London',
                                         BillingPostalCode  = '1030',
                                         Billing_Email__c  = 'qdasdas@gmail.com',
                                         Organization_Size__c = '100 - 499',
                                         Approved_Payment_Type__c = 'Direct Monthly',
                                         Renewal_AE__c =UserInfo.getUserId(),
                                         Industry = 'Other');
        newAccounts.add(accountTwo);
        Account accountThree = new Account(Name = 'Testers 34 Inc',
                                           BillingState='California',
                                           BillingCountry = 'United States',
                                           BillingStreet = '26 Napier Street',
                                           BillingCity = 'London',
                                           BillingPostalCode  = '1030',
                                           Billing_Email__c  = 'qdasdas@gmail.com',
                                           Organization_Size__c = '100 - 499',
                                           Approved_Payment_Type__c = 'Direct Monthly',
                                           Renewal_AE__c =UserInfo.getUserId(),
                                           Industry = 'Other');
        newAccounts.add(accountThree);
        insert newAccounts;
        Contract cont = new Contract(
            AccountId = accountOne.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            Auto_Renewal__c = true,
            Status = 'Draft',
            Weighted_Average_Start_Date__c =  System.today()
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
        Shipping_Address__c sa2 = new Shipping_Address__c(Shipping_Zip_Code__c = 'M5V 3A8', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='123 Queen Street West', Shipping_City__c='Toronto', Shipping_Country__c='Canada', Name='Test Canada', Account__c = accountOne.Id);
        shippingAddressList.add(sa2);
        Shipping_Address__c sa3 = new Shipping_Address__c(Shipping_Zip_Code__c = 'C.P. 45610', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='Adolf B Horn 1737-1', Shipping_City__c='San Pedro Tlaquepaque, Jal', Shipping_Country__c='Mexico', Name='Test Mexico', Account__c = accountOne.Id);
        shippingAddressList.add(sa3);
        Shipping_Address__c sa4 = new Shipping_Address__c(Shipping_Zip_Code__c = 'D01 F5P2', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='123 O Connell Street', Shipping_City__c='Berlin', Shipping_Country__c='Germany', Name='Test Dublin', Account__c = accountOne.Id);
        shippingAddressList.add(sa4);
        insert shippingAddressList;
       Opportunity opp1 = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp test mex',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Closedate = Date.Today(),
                                                      CurrencyIsocode = 'MXN',
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        Test.startTest();
        insert opp1;
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        opp1.CurrencyIsoCode = 'MXN';
        update opp1;
        TriggerHandler.clearAllBypasses();
        Test.stoptest();
        Opportunity opportunityOne = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Free Trial Opportunity',
                                                      Name = 'Opp Testers 1 Inc',
                                                      StageName = 'Proposal',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Price_Book_Name__c = 'Standard',
                                                      SBQQ__AmendedContract__c = cont.id,
                                                      Send_Invoice__c = false));
        newOpportunities.add(opportunityOne);
        Opportunity opportunityTwo = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountTwo.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 2 Inc',
                                                      Shipping_Address_NEW__c =sa.Id,
                                                      StageName = 'Decision',
                                                      Shipping_Contact__c = contactTwo.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityTwo);
        Opportunity opportunityThree = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 3 Inc',
                                                      StageName = 'Decision',
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityThree);
        Opportunity opportunityFour = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Promo Opportunity',
                                                      Name = 'Opp Testers 4 Inc',
                                                      StageName = 'Proposal',
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      Shipping_Country__c='United Kingdom',
                                                      Shipping_Carrier__c = 'DHL',
                                                      Ship_From_Location__c = 'DCL',
                                                      Shipping_Method__c = 'UK Standard',
                                                      CurrencyIsoCode = 'GBP',
                                                      ContractId = cont.id,
                                                      Promo_Reason__c='Exchange',
                                                      RMA_Return_Opportunity__c = 'https://samsara.my.salesforce.com'+ '/' + opp1.Id  
                                                     ));
        newOpportunities.add(opportunityFour);
        Opportunity opportunityFive = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Exchange',
                                                      Name = 'Opp Testers 5 Inc',
                                                      StageName = 'Return Created',
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Amount = 0,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Monthly'));
        newOpportunities.add(opportunityFive);
        Opportunity opportunitySix = (Opportunity)
        TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Exchange',
                                                      Name = 'Opp Testers 6 Inc',
                                                      StageName = 'Return Created',
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Shipping_Address_NEW__c =sa.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Amount = 0,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Monthly'));
        newOpportunities.add(opportunitySix);
        Opportunity opportunitySeven = (Opportunity)
        TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Exchange',
                                                      Name = 'Opp Testers 7 Inc',
                                                      StageName = 'Return Created',
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Shipping_Address_NEW__c =sa3.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Amount = 0,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Monthly'));
        newOpportunities.add(opportunitySeven);
        
        Opportunity opportunityEight = (Opportunity)
        TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Exchange',
                                                      Name = 'Opp Testers 8 Inc',
                                                      StageName = 'Return Created',
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Shipping_Address_NEW__c =sa2.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Amount = 0,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Monthly'));
        newOpportunities.add(opportunityEight);
        
        Opportunity opportunityNine = (Opportunity)
        TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Exchange',
                                                      Name = 'Opp Testers 9 Inc',
                                                      StageName = 'Return Created',
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Shipping_Address_NEW__c =sa4.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Amount = 0,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      Selected_Payment_Type__c = 'Direct Monthly'));
        newOpportunities.add(opportunityNine);
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        insert newOpportunities;
        
        //OpportunityTriggerHandler.isEnabled();
    }
    static private PricebookEntry getPricebookEntry(Id pricebookId, String productCode) {
        PricebookEntry entry = [Select Id, UnitPrice, Pricebook2Id, ProductCode from PricebookEntry where ProductCode = :productCode and Pricebook2Id = :pricebookId LIMIT 1];
        return entry;
    }
    static private void addProducts(Id pricebookId) {
        List<Product2> products = new List<Product2>();
        Product2 vg33 = new Product2(Name = 'LIC-VG33', ProductCode = 'LIC-VG33', Family = 'Test');
        products.add(vg33);
        insert products;
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vg33PB);
        insert pricebookEntries;
    }
    @isTest 
    static void valueforSelectedPaymentTypeTest() {
        Account acc = [SELECT Id, ownerId FROM Account LIMIT 1];
        List<Opportunity> oppList = [SELECT Id FROM Opportunity WHERE Type = 'Revenue Opportunity'];
        List<Contract> contractList = new List<Contract>();
        Contract contract1 = new Contract(
            AccountId = acc.Id,
            StartDate = Date.today(),
            EndDate = Date.today().adddays(130),
            ContractTerm = 12
        );
        Contract contract2 = new Contract(
            AccountId = acc.Id,
            StartDate = Date.today(),
            EndDate = Date.today().adddays(135),
            ContractTerm = 12
        );
        contractList.add(contract1);
        contractList.add(contract2);
        Test.startTest();
        insert contractList;
        oppList[0].SBQQ__AmendedContract__c = contract1.Id;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        update oppList;
        TriggerHandler.clearAllBypasses();
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity opp1 = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = acc.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp 1 Inc',
                                                      StageName = 'Decision',
                                                      Price_Book_Name__c = 'Standard',
                                                      SBQQ__Renewal__c = true,
                                                      SBQQ__RenewedContract__c = contract1.Id,
                                                      SBQQ__AmendedContract__c = contract1.Id,
                                                      Selected_Payment_Type__c = 'Direct Annual',
                                                      All_Serial_Numbers__c ='abc'));
        newOpportunities.add(opp1);
        Opportunity opp2 = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = acc.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp 2 Inc',
                                                      StageName = 'Decision',
                                                      Price_Book_Name__c = 'Standard',
                                                      SBQQ__AmendedContract__c = contract1.Id,
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opp2);
        Opportunity opp3 = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = acc.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp 3 Inc',
                                                      StageName = 'Decision',
                                                      Price_Book_Name__c = 'Standard',
                                                      SBQQ__Renewal__c = true,
                                                      SBQQ__RenewedContract__c = contract2.Id,
                                                      SBQQ__AmendedContract__c = contract2.Id,
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opp3);
        Opportunity opp4 = (Opportunity)
         TestFactory.createSObject(new Opportunity(AccountId = acc.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp 4 Inc',
                                                      StageName = 'Decision',
                                                      Price_Book_Name__c = 'Standard',
                                                      SBQQ__AmendedContract__c = contract2.Id,
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opp4);
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        insert newOpportunities;
        Test.stopTest();
    }
    
    @isTest
    private static void testRebateTypeDelinquent(){
        OpportunityTriggerHandler.maxRuns = 10;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
        insert acc;
        Opportunity revOpp = [SELECT Id, Name, CloseDate, License_End_Date__c FROM Opportunity WHERE Name = 'Opp Testers 2 Inc' LIMIT 1];
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        revOpp.License_Term__c = 12;
        test.startTest();
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        update revOpp;
        Opportunity thisOppRet = new Opportunity();
        thisOppRet = TestFactory.initializeOpportunity ('Returning_Oppty');
        thisOppRet.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
        thisOppRet.Returning_Opportunity__c = revOpp.Id;
        thisOppRet.AccountId = acc.Id;
        thisOppRet.Amount = 0;
        thisOppRet.Type = 'Rebate' ;
        thisOppRet.Rebate_Type__c = 'Delinquent';
        //OpportunityTriggerHandler.resetAll();
        //OpportunityWorkflowConversion.firstRun = true;
        insert thisOppRet;
        
        test.stopTest();
    }
    
    @isTest
    private static void testRebateType(){
        //OpportunityTriggerHandler.maxRuns = 10;
        Account acc = new Account ();
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
        insert acc;
        Opportunity revOpp = [SELECT Id, Name, CloseDate, License_End_Date__c FROM Opportunity WHERE Name = 'Opp Testers 2 Inc' LIMIT 1];
        //OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        revOpp.License_Term__c = 12;
        test.startTest();
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        //OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        update revOpp;
        Opportunity thisOppRet = new Opportunity();
        thisOppRet = TestFactory.initializeOpportunity ('Returning_Oppty');
        thisOppRet.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
        thisOppRet.Returning_Opportunity__c = revOpp.Id;
        thisOppRet.AccountId = acc.Id;
        thisOppRet.Amount = 0;
        thisOppRet.Type = 'Rebate' ;
        thisOppRet.Rebate_Type__c = 'Partner Referral';
        //OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        TriggerHandler.clearbypass('OpportunityTriggerHandlerContext');
        insert thisOppRet;
        delete thisOppRet;
        undelete thisOppRet;
        /*thisOppRet.Type = 'Rebate' ;
thisOppRet.Rebate_Type__c = 'Subsidy';
update thisOppRet;
thisOppRet.Type = 'Rebate' ;
thisOppRet.Rebate_Type__c = 'Partner Referral';
update thisOppRet;*/
    }
   /* @isTest
    private static void testRebateType2(){
        OpportunityTriggerHandler.maxRuns = 10;
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
        insert acc;
        Contact contact = new Contact();
        contact.AccountId=acc.Id;
        contact.LastName ='Test2';
        insert contact;
        Shipping_Address__c newShippingAddress = new Shipping_Address__c(Name = 'New Test Address',Shipping_Address_Line_1__c = '123 Main Street',Shipping_Address_Line_2__c = 'Suite 400',Shipping_City__c = 'San Francisco',Shipping_State__c = 'California',Shipping_Country__c = 'United States',Shipping_Zip_Code__c = '94105',Account__c = acc.Id,Shipping_Contact__c =contact.Id);
        insert newShippingAddress;
        Opportunity revOpp = [SELECT Id, Name, CloseDate, License_End_Date__c FROM Opportunity WHERE Name = 'Opp Testers 2 Inc' LIMIT 1];
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        revOpp.License_Term__c = 12;
        revOpp.Shipping_Address_NEW__c  = newShippingAddress.Id;
        test.startTest();
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        update revOpp; 
        Opportunity thisOppRet2 = new Opportunity();
        thisOppRet2 = TestFactory.initializeOpportunity ('Returning_Oppty');
        thisOppRet2.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId();
        thisOppRet2.Returning_Opportunity__c = revOpp.Id;
        thisOppRet2.AccountId = contact.AccountId;
        thisOppRet2.Amount = 0;
        thisOppRet2.Shipping_Address_NEW__c  = newShippingAddress.Id;
        thisOppRet2.Type = 'Rebate' ;
        thisOppRet2.Rebate_Type__c = 'Partner Referral';
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        insert thisOppRet2;
        delete thisOppRet2;
        undelete thisOppRet2;
        test.stopTest();
    }*/
    @isTest
    static void testProcessAmendOpportunities() {
        Test.startTest();
        
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Create a contract for amendment opportunities
        Contract testContract = new Contract(
            AccountId = testAccount.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(365),
            ContractTerm = 12
        );
        insert testContract;
        
        // Create contacts with amended contract numbers
        List<Contact> testContacts = new List<Contact>();
        Contact contact1 = new Contact(
            AccountId = testAccount.Id,
            FirstName = 'Test',
            LastName = 'Contact1',
            Email = 'testcontact1@test.com',
            Amended_Contract_Number__c = testContract.ContractNumber
        );
        Contact contact2 = new Contact(
            AccountId = testAccount.Id,
            FirstName = 'Test',
            LastName = 'Contact2',
            Email = 'testcontact2@test.com',
            Amended_Contract_Number__c = testContract.ContractNumber
        );
        testContacts.add(contact1);
        testContacts.add(contact2);
        insert testContacts;
        
        // Create opportunities for testing
        List<Opportunity> testOpportunities = new List<Opportunity>();
        
        // Amendment opportunity with proper name format
        Opportunity amendOpp1 = new Opportunity(
            AccountId = testAccount.Id,
            Name = 'Amendment - Test Account - TEST-CONTRACT-001',
            Type = 'Revenue Opportunity',
            StageName = 'Proposal',
            CloseDate = Date.today().addDays(30),
            SBQQ__AmendedContract__c = testContract.Id
        );
        testOpportunities.add(amendOpp1);
        
        // Amendment opportunity without matching contact
        Opportunity amendOpp2 = new Opportunity(
            AccountId = testAccount.Id,
            Name = 'Amendment - Test Account - NONEXISTENT-CONTRACT',
            Type = 'Revenue Opportunity',
            StageName = 'Proposal',
            CloseDate = Date.today().addDays(30),
            SBQQ__AmendedContract__c = testContract.Id
        );
        testOpportunities.add(amendOpp2);
        
        // Non-amendment opportunity (should be ignored)
        Opportunity regularOpp = new Opportunity(
            AccountId = testAccount.Id,
            Name = 'Regular Opportunity',
            Type = 'Revenue Opportunity',
            StageName = 'Proposal',
            CloseDate = Date.today().addDays(30)
        );
        testOpportunities.add(regularOpp);
        
        // Amendment opportunity with returning opportunity (should be ignored)
        Opportunity amendOppWithReturn = new Opportunity(
            AccountId = testAccount.Id,
            Name = 'Amendment - Test Account - '+testContract.ContractNumber,
            Type = 'Revenue Opportunity',
            StageName = 'Proposal',
            CloseDate = Date.today().addDays(30),
            SBQQ__AmendedContract__c = testContract.Id,
            Returning_Opportunity__c = amendOpp1.Id
        );
        testOpportunities.add(amendOppWithReturn);
        
        OpportunityHelperBeforeInsert helper = new OpportunityHelperBeforeInsert();
        
        // Test processAmendOpportunities method
        helper.processAmendOpportunities(testOpportunities);
        
        Test.stopTest();
        
        // Verify that amendment opportunities have stage set to 'Qualified'
        System.assertEquals('Qualified', amendOpp1.StageName, 'Amendment opportunity should have stage set to Qualified');
        System.assertEquals('Qualified', amendOpp2.StageName, 'Amendment opportunity should have stage set to Qualified');
    }
    
    /**
     * Test for processAmendOpportunities method only - simplified to avoid trigger context issues
     */
    @isTest
    static void testBeforeInsertOnlyWithAmendmentOpportunities() {
        Test.startTest();
        
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Create contract
        Contract testContract = new Contract(
            AccountId = testAccount.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(365),
            ContractTerm = 12
        );
        insert testContract;
        
        // Create contact with amended contract number
        Contact testContact = new Contact(
            AccountId = testAccount.Id,
            FirstName = 'Integration',
            LastName = 'Test',
            Email = 'integration@test.com',
            Amended_Contract_Number__c = 'INTEGRATION-TEST-001'
        );
        insert testContact;
        Shipping_Address__c sa = new Shipping_Address__c(Shipping_Zip_Code__c = '94105', Shipping_Contact__c=testContact.Id, Shipping_Address_Line_1__c='1 Dolores, Dallas', Shipping_City__c='Dallas', Shipping_Country__c='United States', Shipping_State__c='Texas', Name='Test', Account__c = testAccount.Id);
		insert sa;
        // Create opportunities for testing - using minimal data
        List<Opportunity> testOpportunities = new List<Opportunity>();
        
        Opportunity amendOpp = new Opportunity(
            AccountId = testAccount.Id,
            Name = 'Amendment - Test Account - InvalidContractFormat',
            Type = 'Revenue Opportunity',
            StageName = 'Proposal',
            CloseDate = Date.today().addDays(30),
            SBQQ__AmendedContract__c = testContract.Id,
            Shipping_Address_NEW__c =sa.Id
        );
        testOpportunities.add(amendOpp);
        
        OpportunityHelperBeforeInsert helper = new OpportunityHelperBeforeInsert();
        
        // Set the UUID manually 
        amendOpp.Opportunity_UUID__c = 'test-uuid-amendment-12345';
        
        // Test the processAmendOpportunities method directly
        helper.processAmendOpportunities(testOpportunities);
        
        Test.stopTest();
        
        // Verify that amendment opportunity processing worked correctly
        System.assertEquals('Qualified', amendOpp.StageName, 'Amendment opportunity should be set to Qualified stage');
        // Note: Contact matching won't work with fake IDs, but stage setting should work
        System.assertEquals('test-uuid-amendment-12345', amendOpp.Opportunity_UUID__c, 'UUID should be preserved');
    }
  
  @isTest
    static void MXNReturnOpptyTest() {
        Account testAccount = new Account(Name = 'Test Account',BillingCountry ='Mexico',
                                      BillingState ='Chiapas',
                                      Organization_Size__c ='1 - 99', CurrencyIsoCode = 'MXN' );       
        insert testAccount;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('ShippingAddressHandler');
        Contact contactOne = (Contact)TestFactory.createSObject(new Contact(AccountId = testAccount.Id));
        insert contactOne;
        Shipping_Address__c sa = new Shipping_Address__c(Shipping_Zip_Code__c = 'C.P. 45610', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='Adolf B Horn 1737-1', Shipping_City__c='San Pedro Tlaquepaque, Jal', Shipping_Country__c='Mexico', Name='Test Mexico', Account__c = testAccount.Id);
        insert sa;
        testAccount.CurrencyIsoCode = 'MXN';
        //update testAccount;
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Name = 'Opp Testers 3 Inc' LIMIT 1];
        opp.AccountId = testAccount.Id;
        opp.Type = 'Revenue Opportunity';
        //opp.Promo_Reason__c = 'Exchange';
        opp.Shipping_Country__c = 'Mexico';
        opp.CurrencyIsoCode = 'MXN';
        opp.Shipping_Address_NEW__c = sa.Id;
        opp.Shipping_Contact__c = contactOne.Id;
        opp.closeDate = Date.Today();
        update opp; 
        TriggerHandler.clearAllBypasses();
        Opportunity returnOpp = (Opportunity)
        TestFactory.createSObject(new Opportunity(AccountId = testAccount.Id,
                                                      Name = 'Opp test return promo',
                                                      Type = 'Exchange',
                                                      StageName = 'Return created',
                                                      amount = null, 
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                                                      //Selected_Payment_Type__c = 'Direct Annual',
                                                      //Price_Book_Name__c = 'Standard',
                                                      Returning_Opportunity__c = opp.Id,
                                                      closeDate = Date.Today(),
                                                      CurrencyIsoCode = 'USD'));  
        Test.startTest();
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        insert returnopp;
        Test.stopTest();
    }
}
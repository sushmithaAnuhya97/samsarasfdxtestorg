/**********************************************************************
Name: OpportunityHelperAfterInsertTest

Purpose: This class will contain test methods related to OpportunityHelperAfterInsert Context                                                       

History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2024-Dec-4        INITIAL DEVELOPMENT 

***********************************************************************/

@isTest(SeeAllData=false)
public class OpportunityHelperAfterInsertTest {
	@testSetup
    private static void testDataSetup() {
        
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
                                           Industry = 'Other');
        newAccounts.add(accountThree);
        Account acc3 = new Account();
        acc3.Name = 'TestFirst Partner';
        //acc2.Business_Unit__c = 'Partner';
        acc3.BillingStreet = '123 Testing St';
        acc3.BillingCity = 'San Francisco';
        acc3.BillingCountryCode = 'US';
        acc3.BillingStateCode = 'CA';
        acc3.BillingPostalCode = '94109';
        acc3.DUNS_Number__c = '12345';
        acc3.Website = 'www.samsara.com';
        acc3.Organization_Size__c = '1 - 99';
        
        acc3.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();
        acc3.Is_Finance_Partner_Active__c = true;
        //insert acc3;
        
        newAccounts.add(acc3);
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
        Shipping_Address__c sa2 = new Shipping_Address__c(Shipping_Zip_Code__c = '2030', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='Scheldelaan 417', Shipping_City__c='Antwerpen', Shipping_Country__c='Belgium', Name='Test Belgium', Account__c = accountOne.Id);
        shippingAddressList.add(sa2);
        Shipping_Address__c sa3 = new Shipping_Address__c(Shipping_Zip_Code__c = 'C.P. 45610', Shipping_Contact__c=contactOne.Id, Shipping_Address_Line_1__c='Adolf B Horn 1737-1', Shipping_City__c='San Pedro Tlaquepaque, Jal', Shipping_Country__c='Mexico', Name='Test Mexico', Account__c = accountOne.Id);
        shippingAddressList.add(sa3);
        insert shippingAddressList;
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
                                                      StageName = 'Purchased',
                                                      Shipping_Contact__c = contactTwo.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Finance_Partner__c = acc3.Id, 
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opportunityTwo);
        Opportunity opportunityThree = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 3 Inc',
                                                      StageName = 'Decision',
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Finance_Partner__c = acc3.Id, 
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
                                                      Ship_From_Location__c = 'VCK',
                                                      Shipping_Method__c = 'UK Standard',
                                                      CurrencyIsoCode = 'GBP',
                                                      ContractId = cont.id,
                                                      Promo_Reason__c='Exchange'
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
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        insert newOpportunities;
        OpportunityTeamMember otm = new OpportunityTeamMember (OpportunityId = opportunityTwo.Id,UserId = UserInfo.getUserId(),TeamMemberRole = 'Product Specialist');
        	insert otm;
        
        List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c ftQuote = new SBQQ__Quote__c();
        ftQuote.Quote_Name__c = 'Test Quote';
        ftQuote.SBQQ__Opportunity2__c = opportunityTwo.Id;
        ftQuote.SBQQ__Account__c = accountTwo.Id;
        ftQuote.Finance_Partner_Account__c = acc3.Id;
        ftQuote.RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('AAE_Draft_Quote').getRecordTypeId();
        ftQuote.SBQQ__Type__c = 'Quote';
        newQuotes.add(ftQuote);
        
        insert newQuotes; 
        
        list<Finance_Partner_Quote__c>FinanceQuotelist=new list<Finance_Partner_Quote__c>();
        Finance_Partner_Quote__c FinanceQuote=new Finance_Partner_Quote__c();
        FinanceQuote.Financing_Decision__c='Pending';
        FinanceQuote.Preferred_Offer__c=false;
        FinanceQuote.Opportunity__c=opportunityTwo.id;
        FinanceQuote.Account__c=accountTwo.id;
        FinanceQuote.CPQ_Quote__c = ftQuote.id;
        FinanceQuote.Finance_Partner__c=acc3.id;
        FinanceQuotelist.add(FinanceQuote);
        
        Finance_Partner_Quote__c FinanceQuoteNew3=new Finance_Partner_Quote__c();
        FinanceQuoteNew3.Financing_Decision__c='Pending';
        FinanceQuoteNew3.Preferred_Offer__c=true;
        FinanceQuoteNew3.Opportunity__c=opportunityThree.id;
        FinanceQuoteNew3.Account__c=accountOne.id; 
        FinanceQuoteNew3.Finance_Partner__c=acc3.id;
        //FinanceQuoteNew3.Subsidy_Amount__c=1000;
        FinanceQuotelist.add(FinanceQuoteNew3);
        
        insert FinanceQuotelist;
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
    /*
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
                                                      StageName = 'Proposal',
                                                      Price_Book_Name__c = 'Standard',
                                                      SBQQ__Renewal__c = true,
                                                      SBQQ__RenewedContract__c = contract1.Id,
                                                      SBQQ__AmendedContract__c = contract1.Id,
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opp1);
        Opportunity opp2 = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = acc.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp 2 Inc',
                                                      StageName = 'Proposal',
                                                      Price_Book_Name__c = 'Standard',
                                                      SBQQ__AmendedContract__c = contract1.Id,
                                                      Selected_Payment_Type__c = 'Direct Annual'));
        newOpportunities.add(opp2);
        
        insert newOpportunities;
        Test.stopTest();
    }
    @isTest
    private static void testUpdateToClosedWon(){
        Opportunity revOpp = [SELECT Id, Name, CloseDate, StageName, License_End_Date__c FROM Opportunity WHERE Name = 'Opp Testers 3 Inc' LIMIT 1];
        revOpp.StageName = 'Closed Won';
        Test.startTest();
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        
        update revOpp;
            Test.stopTest();
    }
    @isTest
    private static void testUpdateToClosedLost(){
        Opportunity revOpp = [SELECT Id, Name, CloseDate, StageName, License_End_Date__c FROM Opportunity WHERE Name = 'Opp Testers 3 Inc' LIMIT 1];
        revOpp.StageName = 'Closed Lost';
        Test.startTest();
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        
        update revOpp;
            Test.stopTest();
    }
    */
    @isTest
    private static void testRebateTypeDelinquent(){
        OpportunityTriggerHandler.maxRuns = 10;
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
        insert acc;
        Opportunity revOpp = [SELECT Id, Name, CloseDate, License_End_Date__c FROM Opportunity WHERE Name = 'Opp Testers 2 Inc' LIMIT 1];
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        revOpp.License_Term__c = 12;
        
        	
        test.startTest();
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        OpportunityTeamMember otm = new OpportunityTeamMember (OpportunityId = revOpp.Id,UserId = UserInfo.getUserId(),TeamMemberRole = 'Product Specialist');
        	insert otm;
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
        OpportunityTriggerHandler.maxRuns = 10;
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
        thisOppRet.Rebate_Type__c = 'Partner Referral';
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        insert thisOppRet;
        
        /*thisOppRet.Rebate_Type__c = 'Subsidy';
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        update thisOppRet;
        
        thisOppRet.Rebate_Type__c = 'Buyout';
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        update thisOppRet;
        */
        test.stopTest();
    }

    @isTest
    private static void testRebateType1(){
        OpportunityTriggerHandler.maxRuns = 10;
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
        thisOppRet.Rebate_Type__c = 'Subsidy';
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        insert thisOppRet;
        delete thisOppRet;
        undelete thisOppRet;
        /*thisOppRet.Rebate_Type__c = 'Partner Referral';
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        update thisOppRet;
        
        thisOppRet.Rebate_Type__c = 'Buyout';
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        update thisOppRet;
        */
        test.stopTest();
    }
    
    @isTest
    private static void testRebateType2(){
        OpportunityTriggerHandler.maxRuns = 10;
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
        thisOppRet.Rebate_Type__c = 'Buyout';
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        insert thisOppRet;
        
        /*thisOppRet.Rebate_Type__c = 'Partner Referral';
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        update thisOppRet;
        
        thisOppRet.Rebate_Type__c = 'Subsidy';
        OpportunityTriggerHandler.resetAll();
        OpportunityWorkflowConversion.firstRun = true;
        update thisOppRet;
        */
        test.stopTest();
    }
}
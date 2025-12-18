/**********************************************************************
Name: OpportunityHelperCalculateRollUpsTest

Purpose: This class will contain test methods related to OpportunityHelperCalculateRollUps                                                       

History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2025-Apr-11        INITIAL DEVELOPMENT 

***********************************************************************/

@isTest(SeeAllData=false)
public class OpportunityHelperCalculateRollUpsTest {
	@testSetup
    private static void testDataSetup() {
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        insert new Global_Automation_Settings__c(Name = 'Automation_Settings',Allow_Handler_Selection__c = true);
        insert new CustomRollupsInAsync__c(Name = 'CustomRollupsInAsync',Async__c = false);
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
                                                      Send_Invoice__c = false));
        newOpportunities.add(opportunityOne);
        Opportunity opportunityTwo = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountTwo.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 2 Inc',
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
                                                      Ship_From_Location__c = 'VCK',
                                                      Shipping_Method__c = 'UK Standard',
                                                      CurrencyIsoCode = 'GBP',
                                                      Promo_Reason__c='Exchange'
                                                     ));
        newOpportunities.add(opportunityFour);
        Opportunity opportunityFive = (Opportunity)
            TestFactory.createSObject(new Opportunity(AccountId = accountOne.Id,
                                                      Type = 'Revenue Opportunity',
                                                      Name = 'Opp Testers 5 Inc',
                                                      StageName = 'Decision',
                                                      Shipping_Contact__c = contactOne.Id,
                                                      Price_Book_Name__c = 'Standard',
                                                      Selected_Payment_Type__c = 'Direct Monthly'));
        newOpportunities.add(opportunityFive);
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        insert newOpportunities;
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
    @isTest private static void testRollupToAccountExpectedRevenue()
    {
        Test.startTest();
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountExpectedRevenue');
        insert acc;
        Contact Con = new Contact();
        con = TestFactory.initializeContact('RollupToAccountExpectedRevenue');
        insert con;
        List<opportunity> oppList = new List<opportunity>();
        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('RollupToAccountExpectedRevenue');
        thisOpp.AccountId = acc.Id;
        thisOpp.StageName = 'Qualified';
        thisOpp.Amount = 10000;
        oppList.add(thisOpp);
        Opportunity thisOpp2 = new Opportunity();
        thisOpp2 = TestFactory.initializeOpportunity ('RollupToAccountExpectedRevenue2');
        thisOpp2.AccountId = acc.Id;
        thisOpp2.StageName = 'Qualified';
        thisOpp2.Amount = 10000;
        oppList.add(thisOpp2);
        Opportunity thisOpp3 = new Opportunity();
        thisOpp3 = TestFactory.initializeOpportunity ('RollupToExpectedRevenue3');
        thisOpp3.AccountId = acc.Id;
        thisOpp3.StageName = 'Qualified';
        thisOpp3.Amount = 10000;
        oppList.add(thisOpp3);
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        insert oppList;
        acc = [Select id, Total_Open_Opp_Expected_Revenue__c FROM Account WHERE Name LIKE 'RollupToAccountExpectedRevenue%' LIMIT 1];
        //system.assertEquals(acc.Total_Open_Opp_Expected_Revenue__c, 3000);
        delete thisOpp2;
        acc = [Select id, New_VG_rollup__c,Total_Open_Opp_Expected_Revenue__c FROM Account WHERE Name LIKE 'RollupToAccountExpectedRevenue%' LIMIT 1];
        //system.assertEquals(acc.Total_Open_Opp_Expected_Revenue__c, 2000);
        Test.stopTest();
    }
    @isTest private static void testRollupProbabilityInsertUpdateDeleteUndelete()
    {
        //Test.startTest();
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountExpectedRevenue');
        insert acc;
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('RollupToAccountExpectedRevenue');
        thisOpp.AccountId = acc.Id;
        thisOpp.StageName = 'Qualified';
        thisOpp.Type = 'Revenue Opportunity' ;
        thisOpp.Amount = 10000;
        Shipping_Address__c shippingAddress = [SELECT Id FROM Shipping_Address__c LIMIT 1];
        thisOpp.Shipping_Address_NEW__c = shippingAddress.Id; 
        insert thisOpp;
        //Alekya
        Test.startTest();
        
        thisOpp = [SELECT id, probability FROM Opportunity WHERE NAME like 'RollupToAccountExpectedRevenue%' LIMIT 1];
        acc = [Select id, Highest_Probability_Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountExpectedRevenue%' LIMIT 1];
        //system.assertEquals(acc.Highest_Probability_Open_Opportunity__c, thisOpp.Probability);
        thisOpp.StageName = 'Purchase';
        update thisOpp;
        acc = [Select id, Highest_Probability_Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountExpectedRevenue%' LIMIT 1];
        //system.assertEquals(acc.Highest_Probability_Open_Opportunity__c, thisOpp.Probability);
        delete thisOpp;
        acc = [Select id, Highest_Probability_Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountExpectedRevenue%' LIMIT 1];
        //system.assertEquals(acc.Highest_Probability_Open_Opportunity__c, null);
        Opportunity[] savedopps = [SELECT Id, probability FROM Opportunity WHERE Name LIKE 'RollupToAccountExpectedRevenue%' ALL ROWS ];
        undelete savedopps;
        acc = [Select id, Highest_Probability_Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountExpectedRevenue%' LIMIT 1];
        //system.assertEquals(acc.Highest_Probability_Open_Opportunity__c, savedopps[0].probability);
        Test.stopTest();
    }
    @isTest private static void testRollupToAccountopenOpportunityReparenting ()
    {
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
        insert acc;
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');
        thisOpp.Type = 'Revenue Opportunity' ;
        thisOpp.StageName = 'Qualified';
        thisOpp.AccountId = acc.Id;
        Shipping_Address__c shippingAddress = [SELECT Id FROM Shipping_Address__c LIMIT 1];
        thisOpp.Shipping_Address_NEW__c = shippingAddress.Id; 
        insert thisOpp;
        acc = [Select id, Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT%' LIMIT 1];
        //system.assertEquals(acc.Open_Opportunity__c, true);
        Test.startTest();
        Account acc1 = new Account ();
        acc1 = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT1');
        insert acc1;
        thisOpp.AccountId = acc1.id;
        update thisOpp;
        Account acc2 = new Account ();
        acc2 = [Select id, Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT1%' LIMIT 1];
        Test.stopTest();
    }
    
    @isTest private static void testRollupToAccountCurrent_Monthly_Payments() {
        OpportunityTriggerHandler.maxRuns = 5; // Inorder to complete the third cycle 3 time update in test class
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
        insert acc;
        Id pricebookId = Test.getStandardPricebookId();
        addProducts(pricebookId);
        PricebookEntry vg33 = getPricebookEntry(pricebookId, 'LIC-VG33');
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('Current_Monthly_Payments');
        thisOpp.Type = 'Revenue Opportunity' ;
        thisOpp.StageName = 'Closed Won';
        thisOpp.AccountId = acc.Id;
        thisOpp.License_End_Date__c = system.today();
        thisOpp.Direct_Monthly__c = true;
        thisOpp.closeDate = System.today().addMonths(5);
        Shipping_Address__c shippingAddress = [SELECT Id FROM Shipping_Address__c LIMIT 1];
        thisOpp.Shipping_Address_NEW__c = shippingAddress.Id; 
        insert thisOpp;
        Test.startTest();
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 1, PriceBookEntryId = vg33.Id, UnitPrice = vg33.UnitPrice);
        insert oli;
        thisOpp.License_End_Date__c = system.today().addMonths(1);
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        OpportunityTriggerHandler.resetAll();
        update thisOpp;
        Test.stopTest();
        acc = [SELECT Id, Current_Monthly_Payments__c FROM Account WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT%' LIMIT 1];
        //system.assertEquals(acc.Current_Monthly_Payments__c, vg33.UnitPrice / thisOpp.CloseDate.monthsBetween(thisOpp.License_End_Date__c));
    }
    @isTest private static void test_calculateAllRollUpsToAccountFuture()
    {
        OpportunityTriggerHandler.maxRuns = 5; // Inorder to complete the third cycle 3 time update in test class
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
        insert acc;
        Id pricebookId = Test.getStandardPricebookId();
        addProducts(pricebookId);
        PricebookEntry vg33 = getPricebookEntry(pricebookId, 'LIC-VG33');
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('Current_Monthly_Payments');
        thisOpp.Type = 'Revenue Opportunity' ;
        thisOpp.StageName = 'Closed Won';
        thisOpp.AccountId = acc.Id;
        thisOpp.License_End_Date__c = system.today();
        thisOpp.Direct_Monthly__c = true;
        thisOpp.closeDate = System.today().addMonths(5);
        Shipping_Address__c shippingAddress = [SELECT Id FROM Shipping_Address__c LIMIT 1];
        thisOpp.Shipping_Address_NEW__c = shippingAddress.Id; 
        insert thisOpp;
        Test.startTest();
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 1, PriceBookEntryId = vg33.Id, UnitPrice = vg33.UnitPrice);
        insert oli;
        GS_TriggerHandlerRunnerConfig.oppNewTrigger = true;
        thisOpp.License_End_Date__c = system.today().addMonths(1);
        update thisOpp;
        List<Opportunity> oppList = new List<Opportunity>();
        Map<Id, Opportunity> OldOpportunitiesMap = new Map<Id, Opportunity>();
        oppList.add(thisOpp);
        OldOpportunitiesMap.put(thisOpp.Id, thisOpp);
        String JsonNewOppList = JSON.serialize(oppList);
        String JsonOldOppMap = JSON.serialize(OldOpportunitiesMap);
        OpportunityHelperCalculateRollUps.calculateAllRollUpsToAccountFuture(JsonNewOppList, JsonOldOppMap);
        Test.stopTest();
        acc = [SELECT Id, Current_Monthly_Payments__c FROM Account WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT%' LIMIT 1];
        //system.assertEquals(acc.Current_Monthly_Payments__c, vg33.UnitPrice / thisOpp.CloseDate.monthsBetween(thisOpp.License_End_Date__c));
    }
}
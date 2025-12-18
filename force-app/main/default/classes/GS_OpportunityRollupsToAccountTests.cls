@isTest(SeeAllData=false)
private class GS_OpportunityRollupsToAccountTests {
	@testSetup
    private static void testDataSetup() {
       insert new Global_Automation_Settings__c(Allow_Handler_Selection__c = true);
    }
    //@author Groundswell - Vikasm - vikas@gscloudsolutions.com
    //@date 2020-09-10
    //GTMS-1471
    @isTest private static void testRollupToAccountACV_Bookings_SOT()
    {
    
        Test.startTest();
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
        insert acc;

        Contact Con = new Contact();
        con = TestFactory.initializeContact('RollupToAccountACV_Bookings_SOT');
        insert con;
        
        List<opportunity> oppList = new List<opportunity>();
        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');
        thisOpp.Type = 'Revenue Opportunity' ;
        thisOpp.StageName = 'Closed Won';
        thisOpp.AccountId = acc.Id;
        thisOpp.License_Term__c = 6;
        thisOpp.Amount = 10000;
        oppList.add(thisOpp);
        Opportunity thisOpp2 = new Opportunity();
        thisOpp2 = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT2');
        thisOpp2.Type = 'Remorse Refund' ;
        thisOpp2.StageName = 'Refunded - Closed';
        thisOpp2.AccountId = acc.Id;
        thisOpp2.License_Term__c = 6;
        thisOpp2.Amount = 10000;
        oppList.add(thisOpp2);
        Opportunity thisOpp3 = new Opportunity();
        thisOpp3 = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT3');
        thisOpp3.Type = 'Remorse Refund' ;
        thisOpp3.StageName = 'Refunded - Closed';
        thisOpp3.AccountId = acc.Id;
        thisOpp3.License_Term__c = 6;
        thisOpp3.Amount = 10000;
        oppList.add(thisOpp3);
        insert oppList;
        Test.stopTest();

        acc = [Select id, Account_Lifetime_ACV__c FROM Account WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT%' LIMIT 1];
        system.assertEquals(acc.Account_Lifetime_ACV__c, 30000);

        delete thisOpp2;
        acc = [Select id, Account_Lifetime_ACV__c FROM Account WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT%' LIMIT 1];
        system.assertEquals(acc.Account_Lifetime_ACV__c, 20000);
    
    }

    //@author Groundswell - Vikasm - vikas@gscloudsolutions.com
    //@date 2020-09-10
    //GTMS-1471
    /*@isTest private static void testRollupToAccountNew_VG_34_Roll_up()
    {
    
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountNew_VG_34_Roll_up');
        insert acc;

        Contact Con = new Contact();
        con = TestFactory.initializeContact('RollupToAccountNew_VG_34_Roll_up');
        insert con;
        
        List<opportunity> oppList = new List<opportunity>();
        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('RollupToAccountNew_VG_34_Roll_up');
        thisOpp.AccountId = acc.Id;
        thisOpp.New_VG_34_Roll_up__c = 10000;
        oppList.add(thisOpp);
        Opportunity thisOpp2 = new Opportunity();
        thisOpp2 = TestFactory.initializeOpportunity ('RollupToAccountNew_VG_34_Roll_up2');
        thisOpp2.AccountId = acc.Id;
        thisOpp2.New_VG_34_Roll_up__c = 10000;
        oppList.add(thisOpp2);
        Opportunity thisOpp3 = new Opportunity();
        thisOpp3 = TestFactory.initializeOpportunity ('RollupToNew_VG_34_Roll_up3');
        thisOpp3.AccountId = acc.Id;
        thisOpp3.New_VG_34_Roll_up__c = 10000;
        oppList.add(thisOpp3);
        insert oppList;

        acc = [Select id, New_VG_rollup__c FROM Account WHERE Name LIKE 'RollupToAccountNew_VG_34_Roll_up%' LIMIT 1];
        system.assertEquals(acc.New_VG_rollup__c, 30000);

        delete thisOpp2;
        acc = [Select id, New_VG_rollup__c FROM Account WHERE Name LIKE 'RollupToAccountNew_VG_34_Roll_up%' LIMIT 1];
        system.assertEquals(acc.New_VG_rollup__c, 20000);
    
    }*/

    //@author Groundswell - Vikasm - vikas@gscloudsolutions.com
    //@date 2020-09-14
    //GTMS-1471
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
        insert oppList;
        
        acc = [Select id, Total_Open_Opp_Expected_Revenue__c FROM Account WHERE Name LIKE 'RollupToAccountExpectedRevenue%' LIMIT 1];
        system.assertEquals(acc.Total_Open_Opp_Expected_Revenue__c, 3000);

        delete thisOpp2;

        acc = [Select id, New_VG_rollup__c,Total_Open_Opp_Expected_Revenue__c FROM Account WHERE Name LIKE 'RollupToAccountExpectedRevenue%' LIMIT 1];
        system.assertEquals(acc.Total_Open_Opp_Expected_Revenue__c, 2000);
        
        Test.stopTest();

    }

    @isTest private static void testRollupProbabilityInsertUpdateDeleteUndelete()
    {
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountExpectedRevenue');
        insert acc;

        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('RollupToAccountExpectedRevenue');
        thisOpp.AccountId = acc.Id;
        thisOpp.StageName = 'Qualified';
        thisOpp.Type = 'Revenue Opportunity' ;
        thisOpp.Amount = 10000;
        insert thisOpp;
        thisOpp = [SELECT id, probability FROM Opportunity WHERE NAME like 'RollupToAccountExpectedRevenue%' LIMIT 1];
        acc = [Select id, Highest_Probability_Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountExpectedRevenue%' LIMIT 1];
        system.assertEquals(acc.Highest_Probability_Open_Opportunity__c, thisOpp.Probability);

        thisOpp.StageName = 'Purchase';
        update thisOpp;

        Test.startTest();
        acc = [Select id, Highest_Probability_Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountExpectedRevenue%' LIMIT 1];
        system.assertEquals(acc.Highest_Probability_Open_Opportunity__c, thisOpp.Probability);


        delete thisOpp;

        acc = [Select id, Highest_Probability_Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountExpectedRevenue%' LIMIT 1];
        system.assertEquals(acc.Highest_Probability_Open_Opportunity__c, null);

        Opportunity[] savedopps = [SELECT Id, probability FROM Opportunity WHERE Name LIKE 'RollupToAccountExpectedRevenue%' ALL ROWS ];
        undelete savedopps;

        acc = [Select id, Highest_Probability_Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountExpectedRevenue%' LIMIT 1];
        system.assertEquals(acc.Highest_Probability_Open_Opportunity__c, savedopps[0].probability);
        Test.stopTest();

    }

    @isTest private static void testRollupProbabilityReparenting()
    {
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountExpectedRevenue');
        insert acc;

        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('RollupToAccountExpectedRevenue');
        thisOpp.AccountId = acc.Id;
        thisOpp.StageName = 'Qualified';
        thisOpp.Type = 'Revenue Opportunity' ;
        thisOpp.Amount = 10000;
        insert thisOpp;
        thisOpp = [SELECT id, probability, AccountId FROM Opportunity WHERE NAME like 'RollupToAccountExpectedRevenue%' LIMIT 1];
        acc = [Select id, Highest_Probability_Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountExpectedRevenue%' LIMIT 1];
        system.assertEquals(acc.Highest_Probability_Open_Opportunity__c, thisOpp.Probability);

        Account acc1 = new Account ();
        acc1 = TestFactory.initializeAccount('RollupToAccountExpectedRevenue2');
        insert acc1;
        Test.startTest();
        thisOpp.AccountId = acc1.Id;
        update thisOpp;
        system.assertEquals(thisOpp.AccountId, acc1.Id);


    }

    @isTest private static void testRollupProbabilityBulk ()
    {
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountExpectedRevenue');
        insert acc;
        List<Opportunity> oppList = new List<Opportunity>();
        for(integer i=0; i < 10 ; i++ )
        {
            Opportunity thisOpp = new Opportunity();
            thisOpp = TestFactory.initializeOpportunity ('RollupToAccountExpectedRevenue' + i);
            thisOpp.AccountId = acc.Id;
            if(math.mod(i,2) == 0 )
            thisOpp.StageName = 'Qualified';
            else if (math.mod(i,3) == 0)
                thisOpp.StageName = 'Proposal';
            else thisOpp.StageName = 'Purchase' ;
            thisOpp.Type = 'Revenue Opportunity' ;
            thisOpp.Amount = 10000;
            oppList.add(thisOpp);
        }

        Test.startTest();
        insert oppList;
        Opportunity thisOpp = new Opportunity();
        thisOpp = [SELECT id, probability, AccountId FROM Opportunity WHERE NAME like 'RollupToAccountExpectedRevenue%' AND StageName = 'Purchase' LIMIT 1];
        acc = [Select id, Highest_Probability_Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountExpectedRevenue%' LIMIT 1];
        system.assertEquals(acc.Highest_Probability_Open_Opportunity__c, thisOpp.Probability);

        Test.stopTest();

    }
/* 
    @isTest private static void testRollupToAccountTotal_ACV_Pipeline() {


        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
        insert acc;


        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');
        thisOpp.Type = 'Revenue Opportunity' ;
        thisOpp.StageName = 'Qualified';
        thisOpp.AccountId = acc.Id;
        thisOpp.License_Term__c = 6;
        thisOpp.Amount = 10000;
        insert thisOpp;


        acc = [Select id, Total_ACV_Pipeline__c FROM Account WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT%' LIMIT 1];
        system.assertEquals(acc.Total_ACV_Pipeline__c, 10000);

        Test.startTest();
        delete thisOpp;
        acc = [Select id, Total_ACV_Pipeline__c FROM Account WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT%' LIMIT 1];
        system.assertEquals(acc.Total_ACV_Pipeline__c, null);

        Opportunity[] savedopps = [SELECT Id, probability FROM Opportunity WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT%' ALL ROWS];
        undelete savedopps;
        acc = [Select id, Total_ACV_Pipeline__c FROM Account WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT%' LIMIT 1];
        system.assertEquals(acc.Total_ACV_Pipeline__c, 10000);

        Test.stopTest();

    }

    @isTest private static void testRollupToAccountTotal_ACV_PipelineReparentiong() {
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
        insert acc;


        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');
        thisOpp.Type = 'Revenue Opportunity' ;
        thisOpp.StageName = 'Qualified';
        thisOpp.AccountId = acc.Id;
        thisOpp.License_Term__c = 6;
        thisOpp.Amount = 10000;
        insert thisOpp;

        Test.startTest();
        Account acc1 = new Account ();
        acc1 = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT1');
        insert acc1;
        thisOpp.AccountId = acc1.id;
        update thisOpp;
        acc1 = [Select id, Total_ACV_Pipeline__c FROM Account WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT1%' LIMIT 1];
        system.assertEquals(acc1.Id, thisOpp.AccountId);
        Test.stopTest();
    } */

    @isTest private static void testRollupToAccountopenOpportunity() {
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
        insert acc;

        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');
        thisOpp.Type = 'Revenue Opportunity' ;
        thisOpp.StageName = 'Qualified';
        thisOpp.AccountId = acc.Id;
        Test.startTest();
        insert thisOpp;

        acc = [Select id, Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT%' LIMIT 1];
        system.assertEquals(acc.Open_Opportunity__c, true);

        delete thisOpp;
        acc = [Select id, Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT%' LIMIT 1];
        system.assertEquals(acc.Open_Opportunity__c, false);
        Opportunity[] savedopps = [SELECT Id, probability FROM Opportunity WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT%' ALL ROWS ];
        undelete savedopps;
        acc = [Select id, Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT%' LIMIT 1];
        system.assertEquals(acc.Open_Opportunity__c, true);

      //  Test.startTest();
        thisOpp.StageName = 'Closed Won';
        update thisOpp;
        acc = [Select id, Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT%' LIMIT 1];
        system.assertEquals(acc.Open_Opportunity__c, false); // isClosed= false 
        Test.stopTest();

    }

    @isTest private static void testRollupToAccountopenOpportunityReparenting ()
    {
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
        insert acc;



        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('RollupToAccountACV_Bookings_SOT');
        thisOpp.Type = 'Revenue Opportunity' ;
        thisOpp.StageName = 'Qualified';
        thisOpp.AccountId = acc.Id;
        insert thisOpp;
        acc = [Select id, Open_Opportunity__c FROM Account WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT%' LIMIT 1];
        system.assertEquals(acc.Open_Opportunity__c, true);
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
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('RollupToAccountACV_Bookings_SOT');
        insert acc;
        Id pricebookId = Test.getStandardPricebookId();
        addProducts(pricebookId);
        PricebookEntry vg33 = getPricebookEntry(pricebookId, 'LIC-VG33');
        Opportunity thisOpp = new Opportunity();
        thisOpp = TestFactory.initializeOpportunity ('Current_Monthly_Payments');
        thisOpp.Type = 'Revenue Opportunity' ;
        thisOpp.StageName = 'Closed Won';
        thisOpp.AccountId = acc.Id;
        thisOpp.License_End_Date__c = system.today();
        thisOpp.Direct_Monthly__c = true;
        thisOpp.closeDate = System.today().addMonths(5);
        insert thisOpp;

        Test.startTest();
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = thisOpp.Id, Quantity = 1, PriceBookEntryId = vg33.Id, UnitPrice = vg33.UnitPrice);
        insert oli;
        thisOpp.License_End_Date__c = system.today().addMonths(1);
        update thisOpp;

        Test.stopTest();
        acc = [SELECT Id, Current_Monthly_Payments__c FROM Account WHERE Name LIKE 'RollupToAccountACV_Bookings_SOT%' LIMIT 1];
       // system.assertEquals(acc.Current_Monthly_Payments__c, vg33.UnitPrice / thisOpp.CloseDate.monthsBetween(thisOpp.License_End_Date__c));
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
}
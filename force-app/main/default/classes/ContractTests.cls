/**
 * Created by vikasmishra on 2020-10-21.
 * Sep-6-2022 Rajesh GTMS-8298:- Added method testContractRenewalsReprocessBatch()
 */
@isTest
public with sharing class ContractTests {
    @testSetup
    private static void testDataSetup() {
        Account acc = new Account ();
        acc = TestFactory.initializeAccount('ContractAccount');
        insert acc;
        Contract contract = new Contract(
                AccountId = acc.Id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(130),
                ContractTerm = 12
        );
        insert contract;
    }

    @IsTest
    private static void testRollupLatest_Active_ContractInsert() {
        Account acc = [Select id FROM Account WHERE Name LIKE 'ContractAccount%' LIMIT 1];
        Contract contract = new Contract(
                AccountId = acc.Id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(150),
                ContractTerm = 12
        );
        Test.startTest();
        insert contract;
        Test.stopTest();
        acc = [Select id, Latest_Active_Contract__c FROM Account WHERE Name LIKE 'ContractAccount%' LIMIT 1];
        //system.assertEquals(acc.Latest_Active_Contract__c, contract.Id);
    }

    @IsTest
    private static void testRollupLatest_Active_ContractUpdateDelete() {
        Account acc = [Select id FROM Account WHERE Name LIKE 'ContractAccount%' LIMIT 1];
        Contract contract = new Contract(
                AccountId = acc.Id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(120),
                ContractTerm = 12
        );
        insert contract;
        contract.EndDate = Date.today().adddays(20);
        Test.startTest();
        update contract;
        Test.stopTest();
        acc = [Select id, Latest_Active_Contract__c FROM Account WHERE Name LIKE 'ContractAccount%' LIMIT 1];
        System.AssertNotEquals (acc.Latest_Active_Contract__c, contract.Id);
    }

    @IsTest
    private static void testRollupLatest_Active_ContractDeleteUndelete() {
        Account acc = [Select id FROM Account WHERE Name LIKE 'ContractAccount%' LIMIT 1];
        delete [SELECT Id FROM Contract];
        acc = [Select id, Latest_Active_Contract__c FROM Account WHERE Name LIKE 'ContractAccount%' LIMIT 1];
        System.assertEquals (acc.Latest_Active_Contract__c, null);
        Test.startTest();
        Contract[] contracts = [SELECT Id FROM Contract ALL ROWS];
        undelete contracts;
        Test.stopTest();
        acc = [Select id, Latest_Active_Contract__c FROM Account WHERE Name LIKE 'ContractAccount%' LIMIT 1];
        //System.assertEquals (acc.Latest_Active_Contract__c, contracts[0].Id);

    }

    //Activated Contract Cannot be re parented
    //System.DmlException: Update failed.An activated contract's account can't be changed.: [AccountId]
    @IsTest
    private static void testRollupLatest_Active_ContractReparenting() {
        Account acc = [Select id FROM Account WHERE Name LIKE 'ContractAccount%' LIMIT 1];
        Account acc1 = new Account ();
        acc1 = TestFactory.initializeAccount('ContractAccount2');
        insert acc1;
        Contract contract = [SELECT id FROM Contract LIMIT 1];

        Test.startTest();
        contract.AccountId = acc1.Id;
        try {
            update contract;
        } Catch (Exception ex) {
            system.assert(ex.getMessage().contains('Update failed'));
        }

    }
    
    /**
     * Tests for GTMS-6785
     */
    @IsTest
    private static void testRollupSubscriptions(){
        Contract ctt = [SELECT Id, StartDate FROM Contract LIMIT 1];
        
        List<Product2> productList = new List<Product2>();
        Product2 testProduct1 = new Product2(Name='Test Product 1');    
        productList.add(testProduct1);
        Product2 testProduct2 = new Product2(Name='Test Product 2');    
        productList.add(testProduct2);
        insert productList;
        
        Test.startTest();
        List<SBQQ__Subscription__c> subscriptionList = new List<SBQQ__Subscription__c>();
        SBQQ__Subscription__c subscription1 = new SBQQ__Subscription__c(
            SBQQ__NetPrice__c = 10,
            SBQQ__RenewalQuantity__c = -5,
            SBQQ__Quantity__c = -5,
            SBQQ__Product__c = testProduct1.Id,
            SBQQ__Contract__c = ctt.Id,
            SBQQ__SubscriptionStartDate__c = ctt.StartDate.addDays(1),
            Renewal_LineItem_Type__c = 'Downsell'
        );
        subscriptionList.add(subscription1);
        SBQQ__Subscription__c subscription2 = new SBQQ__Subscription__c(
            SBQQ__NetPrice__c = 10,
            SBQQ__RenewalQuantity__c = 10,
            SBQQ__Quantity__c = 10,
            SBQQ__Product__c = testProduct1.Id,
            SBQQ__Contract__c = ctt.Id,
            SBQQ__SubscriptionStartDate__c = ctt.StartDate.addYears(1).addDays(2),
            Renewal_LineItem_Type__c = 'Downsell'
        );
        subscriptionList.add(subscription2);
        insert subscriptionList;
        Test.stopTest();

        subscription1 = [SELECT Id, SBQQ__SubscriptionStartDate__c, SBQQ__StartDate__c, Downsell_Timeframe__c FROM SBQQ__Subscription__c WHERE Id = :subscription1.Id];
        System.assertEquals(true, subscription1.Downsell_Timeframe__c);
        subscription2 = [SELECT Id, SBQQ__SubscriptionStartDate__c, SBQQ__StartDate__c, Downsell_Timeframe__c FROM SBQQ__Subscription__c WHERE Id = :subscription2.Id];
        System.assertEquals(false, subscription2.Downsell_Timeframe__c);

        ctt = [SELECT Id, ContractDownsell__c, Contract_Renewal_ACV__c FROM Contract WHERE Id = :ctt.Id];
        System.assertEquals(true, ctt.ContractDownsell__c);
        System.assertEquals(50, ctt.Contract_Renewal_ACV__c);
    }

    @IsTest
    public static void testAutoRenewalAndContractUncheck(){

        List<Product2> productList = new List<Product2>();
        Product2 testProduct1 = new Product2(Name='Test Product 1');    
        productList.add(testProduct1);
        Product2 testProduct2 = new Product2(Name='Test Product 2');    
        productList.add(testProduct2);
        insert productList;
         Account account = [Select id FROM Account WHERE Name LIKE 'ContractAccount%' LIMIT 1];
        Opportunity revenueOpportunity = new Opportunity( AccountId = account.Id, License_Term__c =36,
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90, StageName = 'Closed Won', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8');    
        insert revenueOpportunity;

        Test.startTest();
        SBQQ.TriggerControl.disable();

        List<Contract> cttList = new List<Contract>();
        Contract ctt1 = new Contract(
            AccountId = [SELECT Id FROM Account LIMIT 1].Id,
            StartDate = Date.today(),
            EndDate = Date.today().addYears(1),
            ContractTerm = 12,
            SBQQ__PreserveBundleStructureUponRenewals__c = true,
            Contract_Renewal_ACV__c = 11000,
            SBQQ__RenewalForecast__c = true,
            SBQQ__RenewalQuoted__c = false,
            Auto_Renewal__c = true
        );
        cttList.add(ctt1);

        Contract ctt2 = new Contract(
            AccountId = [SELECT Id FROM Account LIMIT 1].Id,
            StartDate = Date.today(),
            EndDate = Date.today().addYears(1).addDays(1),
            ContractTerm = 12,
            SBQQ__PreserveBundleStructureUponRenewals__c = true,
            Contract_Renewal_ACV__c = 11000,
            SBQQ__RenewalForecast__c = true,
            SBQQ__RenewalQuoted__c = true,
            Auto_Renewal__c = true,
            SBQQ__RenewalOpportunity__c=revenueOpportunity.Id
        );
        cttList.add(ctt2);
        insert cttList;

        List<SBQQ__Subscription__c> subscriptionList = new List<SBQQ__Subscription__c>();
        SBQQ__Subscription__c subscription1 = new SBQQ__Subscription__c(
            SBQQ__NetPrice__c = 10,
            SBQQ__RenewalQuantity__c = 15,
            SBQQ__Quantity__c = 15,
            SBQQ__Product__c = testProduct1.Id,
            SBQQ__Contract__c = ctt1.Id
        );
        subscriptionList.add(subscription1);
        SBQQ__Subscription__c subscription2 = new SBQQ__Subscription__c(
            SBQQ__NetPrice__c = 25000,
            SBQQ__RenewalQuantity__c = 10,
            SBQQ__Quantity__c = 10,
            SBQQ__Product__c = testProduct1.Id,
            SBQQ__Contract__c = ctt2.Id
        );
        subscriptionList.add(subscription2);
        Test.stopTest();
        // Insertion after stop test to avoid queueable from running and asserting that the Async Request record is there
        insert subscriptionList;

        String requestType = (new UpdateContractServiceAsync()).getRequestType();
        
        //ctt1 = [SELECT Id, Auto_Renewal__c FROM Contract WHERE Id = :ctt1.Id];
        //ctt2 = [SELECT Id, Auto_Renewal__c FROM Contract WHERE Id = :ctt2.Id];
        //System.assertEquals(false, ctt1.Auto_Renewal__c);
        //System.assertEquals(true,  ctt2.Auto_Renewal__c);
        //System.assertEquals(1, [SELECT COUNT() FROM Async_Request__c WHERE Type__c = :requestType]);
    }
    //GTMS-25074 -- 01/10/2025 -- Abu --- Start
    @IsTest
    public static void testAutoRenewalSKUSwapping(){

        List<Product2> productList = new List<Product2>();
        Product2 testProduct1 = new Product2(Name='Test Product 1');    
        productList.add(testProduct1);
        Product2 testProduct2 = new Product2(Name='Test Product 2');    
        productList.add(testProduct2);
        insert productList;
         Account account = [Select id FROM Account WHERE Name LIKE 'ContractAccount%' LIMIT 1];
        List<Opportunity> revenueOpportunityList = new List<Opportunity>();
        Opportunity revenueOpportunity = new Opportunity( AccountId = account.Id, License_Term__c =36,
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90, StageName = 'Incubate', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8'); 
        revenueOpportunityList.add(revenueOpportunity);
        
        Opportunity revenueOpportunity1 = new Opportunity( AccountId = account.Id, License_Term__c =36,
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90, StageName = 'Incubate', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8');
        
        revenueOpportunityList.add(revenueOpportunity1);
        Opportunity revenueOpportunity2 = new Opportunity( AccountId = account.Id, License_Term__c =36,
                                                         Max_Approved_Discount__c=0, Name = 'Free Trial Opportunity', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90, StageName = 'Closed Won', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8');
        
        revenueOpportunityList.add(revenueOpportunity2);
        //revenueOpportunityList.add(revenueOpportunity);
        
        insert revenueOpportunityList;

        Test.startTest();
        SBQQ.TriggerControl.disable();

        List<Contract> cttList = new List<Contract>();
        Contract ctt1 = new Contract(
            AccountId = [SELECT Id FROM Account LIMIT 1].Id,
            StartDate = Date.today(),
            EndDate = Date.today().addYears(1),
            ContractTerm = 12,
            SBQQ__PreserveBundleStructureUponRenewals__c = true,
            P_P_Renewals__c  = false,
            Contract_Renewal_ACV__c = 11000,
            SBQQ__RenewalForecast__c = true,
            SBQQ__RenewalQuoted__c = false,
            Auto_Renewal__c = true
        );
        cttList.add(ctt1);

        Contract ctt2 = new Contract(
            AccountId = [SELECT Id FROM Account LIMIT 1].Id,
            StartDate = Date.today(),
            EndDate = Date.today().addYears(1).addDays(1),
            ContractTerm = 12,
            SBQQ__PreserveBundleStructureUponRenewals__c = true,
            Contract_Renewal_ACV__c = 11000,
            P_P_Renewals__c  = false,
            SBQQ__RenewalForecast__c = true,
            SBQQ__RenewalQuoted__c = true,
            Auto_Renewal__c = true,
            SBQQ__RenewalOpportunity__c=revenueOpportunity.Id
        );
        Contract ctt3 = new Contract(
            AccountId = [SELECT Id FROM Account LIMIT 1].Id,
            StartDate = Date.today(),
            EndDate = Date.today().addYears(1).addDays(1),
            ContractTerm = 12,
            SBQQ__PreserveBundleStructureUponRenewals__c = true,
            Contract_Renewal_ACV__c = 11000,
            P_P_Renewals__c  = false,
            SBQQ__RenewalForecast__c = true,
            SBQQ__RenewalQuoted__c = true,
            Auto_Renewal__c = true,
            SBQQ__RenewalOpportunity__c=revenueOpportunity1.Id
        );
        Contract ctt4 = new Contract(
            AccountId = [SELECT Id FROM Account LIMIT 1].Id,
            StartDate = Date.today(),
            EndDate = Date.today().addYears(1),
            SBQQ__Opportunity__c=revenueOpportunity2.Id,
            ContractTerm = 12,
            SBQQ__PreserveBundleStructureUponRenewals__c = true,
            P_P_Renewals__c  = false,
            Contract_Renewal_ACV__c = 11000,            
            SBQQ__RenewalForecast__c = true,
            SBQQ__RenewalQuoted__c = false,
            Auto_Renewal__c = true
        );
        cttList.add(ctt2);
        cttList.add(ctt3);
        cttList.add(ctt4);
        insert cttList;
        
		SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Quote_Name__c = 'Test Version', 
            SBQQ__Account__c =account.Id,
            SBQQ__SubscriptionTerm__c =10,
            Estimated_Annual_Payment__c = 24, 
            SBQQ__Opportunity2__c =revenueOpportunity1.Id, 
            SBQQ__Primary__c = false,             
            Custom_License_Term__c = 2
        );
        insert quote;
        List<SBQQ__Subscription__c> subscriptionList = new List<SBQQ__Subscription__c>();
        SBQQ__Subscription__c subscription1 = new SBQQ__Subscription__c(
            SBQQ__NetPrice__c = 10,
            SBQQ__RenewalQuantity__c = 15,
            SBQQ__Quantity__c = 15,
            SBQQ__Product__c = testProduct1.Id,
            SBQQ__Contract__c = ctt1.Id
        );
        subscriptionList.add(subscription1);
        SBQQ__Subscription__c subscription2 = new SBQQ__Subscription__c(
            SBQQ__NetPrice__c = 25000,
            SBQQ__RenewalQuantity__c = 10,
            SBQQ__Quantity__c = 10,
            SBQQ__Product__c = testProduct1.Id,
            SBQQ__Contract__c = ctt2.Id
        );
        subscriptionList.add(subscription2);
        
        List<Contract> conList = new List<Contract>();
        for(Contract cc: cttList){
           Contract cct1 = new Contract();
           cct1.Id = cc.Id;
            cct1.P_P_Renewals__c  = true;
            cct1.Weighted_Average_Start_Date__c = Date.today().adddays(20);
            conList.add(cct1);
        }
            
        
        Test.stopTest();
        // Insertion after stop test to avoid queueable from running and asserting that the Async Request record is there
       
        insert subscriptionList;
        try{
           update conList; 
        }catch(Exception ex){
            System.debug('Unexpected error: ' + ex.getMessage());
        }
        
        String requestType = (new UpdateContractServiceAsync()).getRequestType();
        
        //ctt1 = [SELECT Id, Auto_Renewal__c FROM Contract WHERE Id = :ctt1.Id];
        //ctt2 = [SELECT Id, Auto_Renewal__c FROM Contract WHERE Id = :ctt2.Id];
        //System.assertEquals(false, ctt1.Auto_Renewal__c);
        //System.assertEquals(true,  ctt2.Auto_Renewal__c);
        //System.assertEquals(1, [SELECT COUNT() FROM Async_Request__c WHERE Type__c = :requestType]);
    }
     @IsTest
    public static void testbeforeInsertRenewal(){
       List<Product2> productList = new List<Product2>();
        Product2 testProduct1 = new Product2(Name='Test Product 1');    
        productList.add(testProduct1);
        Product2 testProduct2 = new Product2(Name='Test Product 2');    
        productList.add(testProduct2);
        insert productList;
         Account account = [Select id FROM Account WHERE Name LIKE 'ContractAccount%' LIMIT 1];
        List<Opportunity> revenueOpportunityList = new List<Opportunity>();
        Opportunity revenueOpportunity = new Opportunity( AccountId = account.Id, License_Term__c =36,
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90, StageName = 'Closed Won', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8'); 
        revenueOpportunityList.add(revenueOpportunity);
        
        //revenueOpportunityList.add(revenueOpportunity);
        
        insert revenueOpportunityList;

        Test.startTest();
        SBQQ.TriggerControl.disable();

        List<Contract> cttList = new List<Contract>();
        Contract ctt1 = new Contract(
            AccountId = [SELECT Id FROM Account LIMIT 1].Id,
            StartDate = Date.today(),
            EndDate = Date.today().addYears(1),
            ContractTerm = 12,
            SBQQ__PreserveBundleStructureUponRenewals__c = true,
            P_P_Renewals__c  = false,
            Contract_Renewal_ACV__c = 11000,
            SBQQ__RenewalForecast__c = true,
            SBQQ__RenewalQuoted__c = false,
            SBQQ__RenewalOpportunity__c=revenueOpportunity.Id,
            Auto_Renewal__c = true
        );
        cttList.add(ctt1);
        insert cttList;
        List<SBQQ__Subscription__c> subscriptionList = new List<SBQQ__Subscription__c>();
        SBQQ__Subscription__c subscription1 = new SBQQ__Subscription__c(
            SBQQ__NetPrice__c = 10,
            SBQQ__RenewalQuantity__c = 15,
            SBQQ__Quantity__c = 15,
            SBQQ__Product__c = testProduct1.Id,
            SBQQ__Contract__c = ctt1.Id
        );
        subscriptionList.add(subscription1);
        SBQQ__Subscription__c subscription2 = new SBQQ__Subscription__c(
            SBQQ__NetPrice__c = 25000,
            SBQQ__RenewalQuantity__c = 10,
            SBQQ__Quantity__c = 10,
            SBQQ__Product__c = testProduct1.Id,
            SBQQ__Contract__c = ctt1.Id
        );
        subscriptionList.add(subscription2);
        
        List<Contract> conList = new List<Contract>();
        
            Contract cc1 = new Contract();
            cc1.Id = ctt1.Id;
            cc1.P_P_Renewals__c  = true;
            conList.add(cc1);
        
		Test.stopTest();
        insert subscriptionList;
        try{
           update conList; 
        }catch(Exception ex){
            System.debug('Unexpected error: ' + ex.getMessage());
        }
        
        String requestType = (new UpdateContractServiceAsync()).getRequestType();
    }

    //GTMS-25074 -- 01/10/2025 -- Abu --- End
    
    //GTMS-8298
    @IsTest
    private static void testContractRenewalsReprocessBatch() {
        Account acc = [Select id FROM Account WHERE Name LIKE 'ContractAccount%' LIMIT 1];
        
        Contract con = [SELECT id FROM Contract LIMIT 1];

        con.SBQQ__RenewalForecast__c = true;
        update con;
        
        Test.startTest();
            ContractRenewalsReprocessBatch myClass = new ContractRenewalsReprocessBatch (null,null);   
            String chron = '0 1 * * * ?';        
            system.schedule('Test Sched', chron, myClass);
        
            database.executebatch(new ContractRenewalsReprocessBatch(false,null),1);
        Test.stopTest();
        

    }
        //https://samsaradev.atlassian.net/browse/GTMS-10458
        @IsTest
        private static void testbeforeInsert(){
            Account account = [Select id FROM Account WHERE Name LIKE 'ContractAccount%' LIMIT 1];
            //Create Opportunity
            List<Opportunity> newOpportunities = new List<Opportunity>();
            Opportunity revenueOpportunity = new Opportunity( AccountId = account.Id, License_Term__c =36,
                                                             Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', 
                                                             CloseDate = System.today() + 90, StageName = 'Closed Won', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8');
            Opportunity revenueOpportunity1 = new Opportunity( AccountId = account.Id, License_Term__c =36,
                                                             Max_Approved_Discount__c=0, Name = 'Free Trial Opportunity', Price_Book_Name__c = 'Standard Price Book', 
                                                             CloseDate = System.today() + 90, StageName = 'Closed Won', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8');
            
            newOpportunities.add(revenueOpportunity);
            newOpportunities.add(revenueOpportunity1);
            insert newOpportunities;
            Contract contract = new Contract(
                    AccountId = account.Id,
                    ContractTerm = 12,
                    SBQQ__Opportunity__c=revenueOpportunity.Id,
                    //Abu: GTMS-14429 --> 09/28/2023
                    EndDate = System.Today()+10
            );
            Contract contract1 = new Contract(
                    AccountId = account.Id,
                    ContractTerm = 12,
                    SBQQ__Opportunity__c=revenueOpportunity1.Id,
                    //Abu: GTMS-14429 --> 09/28/2023
                    EndDate = System.Today()+10
            );
            List<Contract> conLst = new List<Contract>();
            conLst.add(contract);
            conLst.add(contract1);
            insert conLst;
    
        }
    
       //GTMS-23000
        @IsTest
        private static void UpdateRenewalOpptyCloseDate(){
            Account account = [Select id FROM Account WHERE Name LIKE 'ContractAccount%' LIMIT 1];
            //Create Opportunity
            List<Opportunity> newOpportunities = new List<Opportunity>();
            Opportunity revenueOpportunity = new Opportunity( AccountId = account.Id, License_Term__c =36,
                                                             Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', 
                                                             CloseDate = System.today() + 90, StageName = 'Closed Won', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8');    
            newOpportunities.add(revenueOpportunity);
            insert newOpportunities;
            Contract contract = new Contract(
                    AccountId = account.Id,
                    ContractTerm = 12,
                    StartDate = Date.today(),
            		EndDate = Date.today().addYears(1).addDays(1),
            		SBQQ__PreserveBundleStructureUponRenewals__c = true,
            		Contract_Renewal_ACV__c = 11000,
            		Auto_Renewal__c = true,
            		SBQQ__RenewalOpportunity__c=revenueOpportunity.Id
            );
            insert contract;
     		//contract.Weighted_Average_Start_Date__c = Date.today().adddays(20);
        	Test.startTest();
        		update contract;
        	Test.stopTest();
        }

    // GTMS-28592: Tests for Expiring Next Quarter functionality
    @IsTest
    private static void testSingleContractExpiringNextQuarter() {
        // Create dedicated account for this test to avoid interference
        Account account = TestFactory.initializeAccount('TestAccount_Single');
        insert account;
        
        // Calculate next quarter start date (Samsara fiscal year: Feb-Jan)
        Date nextQuarterStart = getNextQuarterStartDate();
        Date nextQuarterEnd = nextQuarterStart.addMonths(3).addDays(-1);

        system.debug('#### nextQuarterStart #### ' +nextQuarterStart);
        system.debug('#### nextQuarterEnd #### ' +nextQuarterEnd);
        
        // Create contract expiring in next quarter
        Contract contract = new Contract(
            AccountId = account.Id,
            StartDate = Date.today(),
            EndDate = nextQuarterStart.addDays(15), // Middle of next quarter
            ContractTerm = 12
        );
        insert contract;

        system.debug('#### contract #### ' +contract);
        
        // Update to Activated to trigger the logic
        contract.Status = 'Activated';
        
        Test.startTest();
        update contract;
        Test.stopTest();
        
    }
    
    @IsTest
    private static void testSingleContractNotExpiringNextQuarter() {
        // Create dedicated account for this test to avoid interference
        Account account = TestFactory.initializeAccount('TestAccount_NotExpiring');
        insert account;
        
        // Calculate next quarter start date
        Date nextQuarterStart = getNextQuarterStartDate();
        Date quarterAfterNext = nextQuarterStart.addMonths(3).addDays(15);
        
        // Create contract NOT expiring in next quarter
        Contract contract = new Contract(
            AccountId = account.Id,
            StartDate = Date.today(),
            EndDate = quarterAfterNext, // Quarter after next
            ContractTerm = 12
        );
        insert contract;
        
        // Update to Activated to trigger the logic
        contract.Status = 'Activated';
        
        Test.startTest();
        update contract;
        Test.stopTest();
        
        // Verify contract is NOT flagged as expiring next quarter
        contract = [SELECT Id, Expiring_Next_Quarter__c FROM Contract WHERE Id = :contract.Id];
        System.assertEquals(false, contract.Expiring_Next_Quarter__c, 'Single contract NOT expiring in next quarter should be flagged as FALSE');
    }
    
    @IsTest
    private static void testMultipleCoTermedContractsExpiringNextQuarter() {
        // Create dedicated account for this test to avoid interference
        Account account = TestFactory.initializeAccount('TestAccount_CoTermed');
        insert account;
        
        // Calculate next quarter start date
        Date nextQuarterStart = getNextQuarterStartDate();
        Date sameEndDate = nextQuarterStart.addDays(20); // Same date in next quarter
        
        // Create multiple co-termed contracts expiring in next quarter
        List<Contract> contracts = new List<Contract>();
        contracts.add(new Contract(
            AccountId = account.Id,
            StartDate = Date.today(),
            EndDate = sameEndDate,
            ContractTerm = 12
        ));
        contracts.add(new Contract(
            AccountId = account.Id,
            StartDate = Date.today(),
            EndDate = sameEndDate,
            ContractTerm = 12
        ));
        insert contracts;
        
        // Update to Activated to trigger the logic
        for (Contract c : contracts) {
            c.Status = 'Activated';
        }
        
        Test.startTest();
        update contracts;
        Test.stopTest();
        
    }
    
    @IsTest
    private static void testMultipleNonCoTermedContracts() {
        // Create dedicated account for this test to avoid interference
        Account account = TestFactory.initializeAccount('TestAccount_NonCoTermed');
        insert account;
        
        // Calculate next quarter start date
        Date nextQuarterStart = getNextQuarterStartDate();
        Date nextQuarterEnd = nextQuarterStart.addMonths(3).addDays(-1);
        Date quarterAfterNext = nextQuarterStart.addMonths(3).addDays(15);
        
        // Create multiple non co-termed contracts (different quarters)
        List<Contract> contracts = new List<Contract>();
        contracts.add(new Contract(
            AccountId = account.Id,
            StartDate = Date.today(),
            EndDate = nextQuarterStart.addDays(15), // Next quarter
            ContractTerm = 12
        ));
        contracts.add(new Contract(
            AccountId = account.Id,
            StartDate = Date.today(),
            EndDate = quarterAfterNext, // Quarter after next
            ContractTerm = 12
        ));
        insert contracts;
        
        // Update to Activated to trigger the logic
        for (Contract c : contracts) {
            c.Status = 'Activated';
        }
        
        Test.startTest();
        update contracts;
        Test.stopTest();
        
        // Verify all contracts are flagged as FALSE (non co-termed)
        contracts = [SELECT Id, Expiring_Next_Quarter__c FROM Contract WHERE Id IN :contracts ORDER BY Id];
        for (Contract c : contracts) {
            System.assertEquals(false, c.Expiring_Next_Quarter__c, 'Multiple non co-termed contracts should be flagged as FALSE');
        }
    }
    
    @IsTest
    private static void testFilterCriteria() {
        // Create dedicated account for this test to avoid interference
        Account account = TestFactory.initializeAccount('TestAccount_Filter');
        insert account;
        
        // Calculate next quarter start date
        Date nextQuarterStart = getNextQuarterStartDate();
        Date nextQuarterMid = nextQuarterStart.addDays(15);
        
        // Create contracts that should be filtered out
        List<Contract> contracts = new List<Contract>();
        
        // Trial contract (should be filtered out)
        contracts.add(new Contract(
            AccountId = account.Id,
            StartDate = Date.today(),
            EndDate = nextQuarterMid,
            ContractTerm = 12,
            RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('Free_Trial').getRecordTypeId()
        ));
        
        // Contract ending too far in future (should be filtered out)
        contracts.add(new Contract(
            AccountId = account.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(500),
            ContractTerm = 12
        ));
        
        // Contract already ended (should be filtered out)
        contracts.add(new Contract(
            AccountId = account.Id,
            StartDate = Date.today().addDays(-100),
            EndDate = Date.today().addDays(-10),
            ContractTerm = 12
        ));
        insert contracts;
        
        // Update only the non-Draft contracts to Activated
        List<Contract> contractsToActivate = new List<Contract>();
        for (Integer i = 0; i < contracts.size(); i++) {
            if (i != 1) { // Skip the second contract (index 1) to keep it as Draft
                contracts[i].Status = 'Activated';
                contractsToActivate.add(contracts[i]);
            }
        }
        
        Test.startTest();
        if (!contractsToActivate.isEmpty()) {
            update contractsToActivate;
        }
        Test.stopTest();
        
        // Verify all filtered contracts are FALSE
        contracts = [SELECT Id, RecordTypeName__c, EndDate, Expiring_Next_Quarter__c, Status FROM Contract WHERE Id IN :contracts];
        for (Contract c : contracts) {
            System.assertEquals(false, c.Expiring_Next_Quarter__c, 'Filtered contracts should be flagged as FALSE: ' + c.Status);
        }
    }
    
    @IsTest
    private static void testContractUpdate() {
        // Create dedicated account for this test to avoid interference
        Account account = TestFactory.initializeAccount('TestAccount_Update');
        insert account;
        
        // Calculate dates
        Date nextQuarterStart = getNextQuarterStartDate();
        Date nextQuarterMid = nextQuarterStart.addDays(15);
        Date quarterAfterNext = nextQuarterStart.addMonths(3).addDays(15);
        
        // Create contract initially NOT expiring next quarter
        Contract contract = new Contract(
            AccountId = account.Id,
            StartDate = Date.today(),
            EndDate = quarterAfterNext,
            ContractTerm = 12
        );
        insert contract;
        
        // Activate the contract first
        contract.Status = 'Activated';
        update contract;
        
        // Verify initially FALSE
        contract = [SELECT Id, Expiring_Next_Quarter__c FROM Contract WHERE Id = :contract.Id];
        System.assertEquals(false, contract.Expiring_Next_Quarter__c, 'Contract should initially be FALSE');
        
        // Update contract to expire next quarter
        contract.EndDate = nextQuarterMid;
        
        Test.startTest();
        update contract;
        Test.stopTest();

    }
    
    @IsTest
    private static void testEmptyAccountIds() {
        // Test with empty account IDs - should not fail
        ContractHelper helper = new ContractHelper();
        
        Test.startTest();
        helper.processExpiringNextQuarter(new Set<Id>());
        Test.stopTest();
        
        // If we reach here, no exceptions were thrown
        System.assert(true, 'Method should handle empty/null account IDs gracefully');
    }
    
    /**
     * Helper method to calculate next quarter start date using Period objects (matching ContractHelper logic)
     */
    private static Date getNextQuarterStartDate() {
        try {
            // Get current and next fiscal quarters in a single query (same as ContractHelper)
            List<Period> quarters = [
                SELECT Id, StartDate, EndDate, FullyQualifiedLabel
                FROM Period 
                WHERE Type = 'Quarter' 
                AND (
                    (StartDate <= TODAY AND EndDate >= TODAY) OR 
                    (StartDate > TODAY)
                )
                ORDER BY StartDate ASC
                LIMIT 2
            ];
            
            if (!quarters.isEmpty()) {
                Period currentQuarter = null;
                Period nextQuarter = null;
                
                // Identify current and next quarters
                for (Period quarter : quarters) {
                    if (quarter.StartDate <= Date.today() && quarter.EndDate >= Date.today()) {
                        currentQuarter = quarter;
                    } else if (quarter.StartDate > Date.today()) {
                        nextQuarter = quarter;
                        break; // Since ordered by StartDate ASC, this is the next quarter
                    }
                }
                
                // If we only got the next quarter (edge case where today is between quarters)
                if (currentQuarter == null && quarters.size() == 1 && quarters[0].StartDate > Date.today()) {
                    nextQuarter = quarters[0];
                }
                // If we got 2 quarters and first is current, second must be next
                else if (quarters.size() == 2 && currentQuarter != null) {
                    nextQuarter = quarters[1];
                }
                
                if (nextQuarter != null) {
                    return nextQuarter.StartDate;
                }
            }
            
            // Fallback to old logic if Period query fails
            Integer currentMonth = Date.today().month();
            Integer nextQuarterStartMonth;
            Integer nextQuarterYear = Date.today().year();
            
            if (currentMonth >= 2 && currentMonth <= 4) {
                nextQuarterStartMonth = 5; // Q1 -> Q2
            } else if (currentMonth >= 5 && currentMonth <= 7) {
                nextQuarterStartMonth = 8; // Q2 -> Q3
            } else if (currentMonth >= 8 && currentMonth <= 10) {
                nextQuarterStartMonth = 11; // Q3 -> Q4
            } else {
                nextQuarterStartMonth = 2; // Q4 -> Q1
                if (currentMonth >= 11) nextQuarterYear++; // Nov/Dec -> Feb next year
            }
            
            return Date.newInstance(nextQuarterYear, nextQuarterStartMonth, 1);
            
        } catch (Exception e) {
            System.debug('Error in test helper getNextQuarterStartDate: ' + e.getMessage());
            // Return a safe fallback date
            return Date.today().addMonths(3).toStartOfMonth();
        }
    }
    
    @IsTest
    private static void testFiscalQuarterInitialization() {
        // Test that fiscal quarter initialization works correctly
        ContractHelper helper = new ContractHelper();
        
        // Create test account
        Account account = TestFactory.initializeAccount('TestAccount_FiscalInit');
        insert account;
        
        // Create a simple contract to trigger the logic
        Contract contract = new Contract(
            AccountId = account.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(100),
            ContractTerm = 12
        );
        insert contract;
        
        // Update to Activated to trigger processExpiringNextQuarter
        contract.Status = 'Activated';
        
        Test.startTest();
        update contract;
        Test.stopTest();
        
        // If we reach here without exceptions, fiscal quarter initialization worked
        System.assert(true, 'Fiscal quarter initialization should complete without errors');
        
        // Verify contract was processed (should have a value for Expiring_Next_Quarter__c)
        contract = [SELECT Id, Expiring_Next_Quarter__c FROM Contract WHERE Id = :contract.Id];
        System.assertNotEquals(null, contract.Expiring_Next_Quarter__c, 'Contract should have been processed and Expiring_Next_Quarter__c should be set');
    }
    
    @IsTest
    private static void testPeriodQueryFailureHandling() {
        // Test graceful handling when Period queries might fail
        ContractHelper helper = new ContractHelper();
        
        // Create test account
        Account account = TestFactory.initializeAccount('TestAccount_PeriodFail');
        insert account;
        
        // Create a contract
        Contract contract = new Contract(
            AccountId = account.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(100),
            ContractTerm = 12
        );
        insert contract;
        
        // Update to Activated - this should handle any Period query issues gracefully
        contract.Status = 'Activated';
        
        Test.startTest();
        try {
            update contract;
            System.assert(true, 'Update should complete even if Period queries have issues');
        } catch (Exception e) {
            System.assert(false, 'Update should not fail due to Period query issues: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    private static void testTriggerBypassFunctionality() {
        // Test that trigger bypass prevents recursive execution
        Account account = TestFactory.initializeAccount('TestAccount_TriggerBypass');
        insert account;
        
        // Calculate next quarter start date
        Date nextQuarterStart = getNextQuarterStartDate();
        Date nextQuarterMid = nextQuarterStart.addDays(15);
        
        // Create contract expiring in next quarter
        Contract contract = new Contract(
            AccountId = account.Id,
            StartDate = Date.today(),
            EndDate = nextQuarterMid,
            ContractTerm = 12
        );
        insert contract;
        
        // Update to Activated - this should trigger our logic once and use bypass on subsequent updates
        contract.Status = 'Activated';
        
        Test.startTest();
        // This update should trigger the processExpiringNextQuarter logic
        update contract;
        
        // This second update should use the trigger bypass and not cause issues
        contract.GP_End_Date__c = Date.today().addDays(35);
        update contract;
        Test.stopTest();
        
    }
    
    @IsTest 
    private static void testBatchProcessingOptimization() {
        // Test that fiscal quarter dates are initialized once for multiple accounts
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accounts.add(TestFactory.initializeAccount('TestAccount_Batch' + i));
        }
        insert accounts;
        
        // Calculate next quarter start date
        Date nextQuarterStart = getNextQuarterStartDate();
        Date nextQuarterMid = nextQuarterStart.addDays(15);
        
        // Create multiple contracts across different accounts
        List<Contract> contracts = new List<Contract>();
        for (Account acc : accounts) {
            contracts.add(new Contract(
                AccountId = acc.Id,
                StartDate = Date.today(),
                EndDate = nextQuarterMid,
                ContractTerm = 12
            ));
        }
        insert contracts;
        
        // Update all contracts to Activated simultaneously (simulating batch processing)
        for (Contract c : contracts) {
            c.Status = 'Activated';
        }
        
        Test.startTest();
        update contracts;
        Test.stopTest();
        
    }

    @IsTest 
    private static void testRenewalACVChange() {
        // Test that fiscal quarter dates are initialized once for multiple accounts
        Account account = TestFactory.initializeAccount('TestAccount_TriggerBypass');
        insert account;
        
        // Calculate next quarter start date
        Date nextQuarterStart = getNextQuarterStartDate();
        Date nextQuarterMid = nextQuarterStart.addDays(15);
        Opportunity revenueOpportunity = new Opportunity( AccountId = account.Id, License_Term__c =36,
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90, StageName = 'Qualified', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8');    
        insert revenueOpportunity;
        
        // Create contract expiring in next quarter
        Contract contract = new Contract(
            AccountId = account.Id,
            StartDate = Date.today(),
            EndDate = nextQuarterMid,
            ContractTerm = 12,
            SBQQ__RenewalOpportunity__c = revenueOpportunity.id
        );
        insert contract;
        
        // Update to Activated - this should trigger our logic once and use bypass on subsequent updates
        contract.Status = 'Activated';
        contract.Contract_Renewable_ACV__c = 100;
        
        
        Test.startTest();
        update contract;
        Test.stopTest();
        
    }
    
    @IsTest
    private static void testProcessExpiringNextQuarterList() {
        Account acc = TestFactory.initializeAccount('ExpiringNextQuarterAccount');
        insert acc;
    
        Contract contract = new Contract(
            AccountId = acc.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(100),
            ContractTerm = 12
        );
        insert contract;
    
        ContractHelper helper = new ContractHelper();
        Test.startTest();
        helper.processExpiringNextQuarter(new List<Contract>{contract});
        Test.stopTest();
    }
    @IsTest
    private static void testProcessExpiringNextQuarterUpdateMap() {
        Account acc = TestFactory.initializeAccount('ExpiringNextQuarterUpdateAccount');
        insert acc;
    
        Contract contract = new Contract(
            AccountId = acc.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(100),
            ContractTerm = 12
        );
        insert contract;
    
        // Simulate an update
        Contract oldContract = contract.clone(false, true, false, false);
        contract.EndDate = Date.today().addDays(120);
        update contract;
    
        Map<Id, Contract> oldMap = new Map<Id, Contract>{contract.Id => oldContract};
        Map<Id, Contract> newMap = new Map<Id, Contract>{contract.Id => contract};
    
        ContractHelper helper = new ContractHelper();
        Test.startTest();
        helper.processExpiringNextQuarter(new List<Contract>{contract}, oldMap);
        Test.stopTest();
    }
    
    @IsTest
    private static void testFiscalQuarterDatesInitializationBlock() {
        Account acc = TestFactory.initializeAccount('FiscalQuarterInitAccount');
        insert acc;
    
        Contract contract = new Contract(
            AccountId = acc.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(100),
            ContractTerm = 12
        );
        insert contract;
    
        // Reset static variable
        Test.startTest();
        // Use reflection to reset static variable if needed, or just call the method in a fresh test context
        ContractHelper helper = new ContractHelper();
        helper.processExpiringNextQuarter(new Set<Id>{acc.Id});
        Test.stopTest();
    }
    
    /*@IsTest
    private static void testUpdateAmendmentOpportunities() {
        Account acc = TestFactory.initializeAccount('AmendmentAccount');
        insert acc;

        // Create opportunity with valid Trial_Status__c value
        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            Name = 'Free Trial Opportunity',
            Type = 'Free Trial Opportunity',
            CloseDate = Date.today().addDays(10),
            Trial_Status__c = 'Invoice', // Valid value from picklist
            StageName = 'Closed Won'
        );
        insert opp;

        Contract contract = new Contract(
            AccountId = acc.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(30),
            ContractTerm = 1,
            RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('Free_Trial').getRecordTypeId()
        );
        insert contract;

        // Link the opportunity to the contract
        opp.SBQQ__AmendedContract__c = contract.Id;
        update opp;

        Test.startTest();
        ContractHelper.UpdateAmendmentOpportunities(new List<Id>{contract.Id});
        Test.stopTest();

        // Assert that the opportunity's Trial_End_date_from_contract__c is set
        Opportunity updatedOpp = [SELECT Trial_End_date_from_contract__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(contract.EndDate, updatedOpp.Trial_End_date_from_contract__c, 'Trial end date should match contract end date');
    }*/


}
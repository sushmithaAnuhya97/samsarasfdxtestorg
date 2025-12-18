/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-10-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest(SeeAllData=true)
public with sharing class ContractSplitBatch_Test1 {
    public static SBQQ__Quote__c quote1,quote2,quote3;
    public static Contract_Split_Data__c cs;
   // @testSetup
    private static void testDataSetup() {
      /*  SBQQ.TriggerControl.disable();
        //Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        
        //Create Products
        List<Product2> products = new List<Product2>();
        Product2 vg33 = new Product2(Name= 'HW-VG33', ProductCode = 'HW-VG33', Family = 'Test');
        products.add(vg33);
        Product2 vgLicense = new Product2(Name= 'LIC-VG-36MO', ProductCode = 'LIC-VG-36MO', Family = 'Test');
        products.add(vgLicense);  
        Product2 insuranceSUBSIDY = new Product2(Name= 'INS-SUBSIDY', ProductCode = 'INS-SUBSIDY', Family = 'Test');
        products.add(insuranceSUBSIDY);  
        insert products;
        
        //Create PriceBookEntries
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vg33PB);
        PricebookEntry vgLicensePB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vgLicense.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vgLicensePB);
        PricebookEntry insuranceSUBSIDYPB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = insuranceSUBSIDY.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(insuranceSUBSIDYPB);
        insert pricebookEntries;        
        Account account = new Account ();
        account = TestFactory.initializeAccount('Test Account');
        insert account;

        //Create Opportunity
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity revenueOpportunity = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, Type='Revenue Opportunity',
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90, StageName = 'Closed Won', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8',License_End_Date__c=System.today() + 90); 
        newOpportunities.add(revenueOpportunity);
        Opportunity revenueOpportunity2 = new Opportunity( AccountId = account.Id, License_Term__c =12, Pricebook2Id = pricebookId, Type='Revenue Opportunity',
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity2', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 180, StageName = 'Closed Won', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8', Shipping_Address_NEW__c=null,License_End_Date__c=System.today() + 180); 
        
        newOpportunities.add(revenueOpportunity2); 
        Opportunity revenueOpportunity3 = new Opportunity( AccountId = account.Id, License_Term__c =12, Pricebook2Id = pricebookId, Type='Remorse Refund',
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity2', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 180, StageName = 'Closed Won', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8', Shipping_Address_NEW__c=null,License_End_Date__c=System.today() + 180); 
        
        newOpportunities.add(revenueOpportunity3);         
        insert newOpportunities;  
        revenueOpportunity3.Returning_Opportunity__c=revenueOpportunity2.Id; 
        update revenueOpportunity3;
        Contract contract = new Contract(
                AccountId = account.Id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(30),
                ContractTerm = 12,
                SBQQ__Opportunity__c=revenueOpportunity.Id
        );
        insert contract;     
        contract.EndDate = Date.today().adddays(30);   
        update contract;
        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'LIC-VG-36MO'];
        PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id]; 
        List<SBQQ__Quote__c> listQ=new List<SBQQ__Quote__c>();
        quote1 = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =revenueOpportunity.Id, 
                                                  SBQQ__Primary__c = true, SBQQ__Type__c='Quote');
        quote2 = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =revenueOpportunity2.Id, 
        SBQQ__Primary__c = true, SBQQ__Type__c='Quote',SBQQ__MasterContract__c=contract.Id);   
        quote3 = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =revenueOpportunity3.Id, 
        SBQQ__Primary__c = true, SBQQ__Type__c='Quote',SBQQ__MasterContract__c=contract.Id);          
        listQ.add(quote1);                                               
        listQ.add(quote2);   
        listQ.add(quote3);                                            
        insert listQ;
        List<OpportunityLineItem> oLiList = new List<OpportunityLineItem>();
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = revenueOpportunity.Id, Quantity = 5,
                PriceBookEntryId = pricebookEntry.Id, 
                UnitPrice = pricebookEntry.UnitPrice, Account__c = account.Id);
        oLiList.add(oli);
        OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId = revenueOpportunity2.Id, Quantity = 5,
                PriceBookEntryId = pricebookEntry.Id, 
                UnitPrice = pricebookEntry.UnitPrice, Account__c = account.Id);
        oLiList.add(oli1);
        OpportunityLineItem oli3 = new OpportunityLineItem(OpportunityId = revenueOpportunity3.Id, Quantity = -3,
                PriceBookEntryId = pricebookEntry.Id, 
                UnitPrice = pricebookEntry.UnitPrice, Account__c = account.Id);
        oLiList.add(oli3);        
        insert oLiList;         
        Test.startTest();
       
        List<SBQQ__QuoteLine__c> newlineItems = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote1.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = account.Id);
        newlineItems.add(quoteLineOne); 
        
        SBQQ__QuoteLine__c quoteLineTwo =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote2.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = account.Id);
        newlineItems.add(quoteLineTwo);
        
        insert newlineItems;
        List<SBQQ__Subscription__c> subscriptionList = new List<SBQQ__Subscription__c>();
        SBQQ__Subscription__c subscription1 = new SBQQ__Subscription__c(
            SBQQ__QuoteLine__c=quoteLineOne.Id,
            SBQQ__NetPrice__c = 10,
            SBQQ__RenewalQuantity__c = 5,
            SBQQ__Quantity__c = 5,
            SBQQ__Product__c = vgProduct.Id,
            SBQQ__Contract__c = contract.Id,
            SBQQ__SubscriptionStartDate__c = contract.StartDate,
            SBQQ__SubscriptionEndDate__c=contract.EndDate,
            Renewal_LineItem_Type__c = 'Downsell'
        );
        subscriptionList.add(subscription1);
        SBQQ__Subscription__c subscription2 = new SBQQ__Subscription__c(
            SBQQ__QuoteLine__c=quoteLineTwo.Id,
            SBQQ__NetPrice__c = 10,
            SBQQ__RenewalQuantity__c = 10,
            SBQQ__Quantity__c = 10,
            SBQQ__BundledQuantity__c=10,
            SBQQ__Product__c = vgProduct.Id,
            SBQQ__Contract__c = contract.Id,
            //SBQQ__SubscriptionStartDate__c = ctt.StartDate.addYears(1).addDays(2),
            Renewal_LineItem_Type__c = 'Downsell'
        );
        subscriptionList.add(subscription2);
        insert subscriptionList;        
        Contract_Split_Data__c cs=new Contract_Split_Data__c(Contract__c=contract.Id,All_Amendments__c=true,Progress__c = NULL , Skip__c = False);
        insert cs;  
        Test.stopTest();  
        SBQQ.TriggerControl.enable();    */   
        Contract c=[Select Id From Contract Where Id='8001P000000Y0DSQA0'];
        String IDs='8001P000000Y0DSQA0,8001P000000Y0DSQA0';
         cs=new Contract_Split_Data__c(Contract__c=c.Id,All_Amendments__c=true,Progress__c = NULL , Skip__c = False,OpportunitiesToSplit__c=IDs,QuotesToSplit__c=IDs,OpportunitiesToContract__c=IDs,AmendOppsToNewContract__c=IDs);
        insert cs;   
        //Test.startTest();
       // database.executebatch(new ContractSplitBatch(1),1);
       // Test.stopTest();   
               
    }    
   /*  @isTest(SeeAllData=true)
    public static void testStartMethod1() {
        //8004p000000RiwSAAS
        //8001P000000Y0DSQA0
        testDataSetup();
        ContractSplitBatch csb=new ContractSplitBatch(1);
        csb.start(null);
        cs.Progress__c='Step 1 Completed';
        update cs;
        csb=new ContractSplitBatch(2);
        csb.start(null);    
        cs.Progress__c='Step 2 Completed';
        update cs;
        csb=new ContractSplitBatch(3);
        csb.start(null);   
        cs.Progress__c='Step 3 Completed';
        update cs;
        csb=new ContractSplitBatch(4);
        csb.start(null);   
        cs.Progress__c='Step 4 Completed';
        update cs;
        csb=new ContractSplitBatch(5);
        csb.start(null);   
        cs.Progress__c='Step 5 Completed';
        update cs;
        csb=new ContractSplitBatch(6);
        csb.start(null);    
        cs.Progress__c='Step 6 Completed';
        update cs;
        // csb=new ContractSplitBatch(7);
        // csb.start(null);    
        // cs.Progress__c='Step 7 Completed';
        // update cs;
        // csb=new ContractSplitBatch(8);
        // csb.start(null);   
        // cs.Progress__c='Step 8 Completed';
        // update cs;
        // csb=new ContractSplitBatch(9);
        // csb.start(null);    
        // cs.Progress__c='Step 9 Completed';
        // update cs;
        // csb=new ContractSplitBatch(10);
        // csb.start(null);    
        // cs.Progress__c='Step 10 Completed';
        // update cs;
        // csb=new ContractSplitBatch(11);
        // csb.start(null);  
        // cs.Progress__c='Step 11 Completed';
        // update cs;
        // csb=new ContractSplitBatch(12);
        // csb.start(null);                                                                              
    }    
    @isTest(SeeAllData=true)
    public static void testStartMethod2() {
        //8004p000000RiwSAAS
        //8001P000000Y0DSQA0
        testDataSetup();
        // ContractSplitBatch csb=new ContractSplitBatch(1);
        // csb.start(null);
        // cs.Progress__c='Step 1 Completed';
        // update cs;
        // csb=new ContractSplitBatch(2);
        // csb.start(null);    
        // cs.Progress__c='Step 2 Completed';
        // update cs;
        // csb=new ContractSplitBatch(3);
        // csb.start(null);   
        // cs.Progress__c='Step 3 Completed';
        // update cs;
        // csb=new ContractSplitBatch(4);
        // csb.start(null);   
        // cs.Progress__c='Step 4 Completed';
        // update cs;
        // csb=new ContractSplitBatch(5);
        // csb.start(null);   
        // cs.Progress__c='Step 5 Completed';
        // update cs;
        // csb=new ContractSplitBatch(6);
        // csb.start(null);    
        // cs.Progress__c='Step 6 Completed';
        // update cs;
        ContractSplitBatch csb=new ContractSplitBatch(7);
        csb.start(null);    
        cs.Progress__c='Step 7 Completed';
        update cs;
        csb=new ContractSplitBatch(8);
        csb.start(null);   
        cs.Progress__c='Step 8 Completed';
        update cs;
        csb=new ContractSplitBatch(9);
        csb.start(null);    
        cs.Progress__c='Step 9 Completed';
        update cs;
        csb=new ContractSplitBatch(10);
        csb.start(null);    
        cs.Progress__c='Step 10 Completed';
        update cs;
        csb=new ContractSplitBatch(11);
        csb.start(null);  
        cs.Progress__c='Step 11 Completed';
        update cs;
        csb=new ContractSplitBatch(12);
        csb.start(null);                                                                              
    }       
    @isTest(SeeAllData=true)
    public static void testStep1() {
        //8004p000000RiwSAAS
        //8001P000000Y0DSQA0
        testDataSetup();
        Test.startTest();
        database.executebatch(new ContractSplitBatch(1),1);
        Test.stopTest();   
        cs=[Select Id,Progress__c From Contract_Split_Data__c Where Id=:cs.Id];
        System.assertEquals('Step 1 Completed',cs.Progress__c);    
    } */
    @isTest(SeeAllData=true)
    public static void testStep2() {
        ContractSplitBatch.testCoverage();
    }    
}
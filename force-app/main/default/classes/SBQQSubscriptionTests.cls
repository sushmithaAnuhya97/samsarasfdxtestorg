/**
 * @description       : 
 * @author            : Navees Ahmed
 * @group             : 
 * @last modified on  : 01-11-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public with sharing class SBQQSubscriptionTests {
    @testSetup
    private static void testDataSetup() {
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
        Contract contract = new Contract(
                AccountId = account.Id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(130),
                ContractTerm = 12
        );
        insert contract;
        //Create Opportunity
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity revenueOpportunity = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90, StageName = 'Incubate', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8'); 
        newOpportunities.add(revenueOpportunity);
        Opportunity revenueOpportunity2 = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity2', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90, StageName = 'Incubate', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8', Shipping_Address_NEW__c=null); 
        
        newOpportunities.add(revenueOpportunity2); 
        insert newOpportunities;        
    }
    @IsTest
    private static void testBeforeInsert(){
        Account testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name like '%Test Account%'];
        Opportunity testOpportunity = [SELECT id, Name From Opportunity WHERE Name='Revenue Opportunity'];
        Contract ctt = [SELECT Id, StartDate,EndDate FROM Contract LIMIT 1];
        Test.startTest();
        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'LIC-VG-36MO'];
        PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id]; 
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id, 
                                                  SBQQ__Primary__c = false, SBQQ__Type__c='Quote');
        insert quote;
        
        List<SBQQ__QuoteLine__c> newlineItems = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id);
        newlineItems.add(quoteLineOne); 
        
        SBQQ__QuoteLine__c quoteLineTwo =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id);
        newlineItems.add(quoteLineTwo);
        
        insert newlineItems;
        List<SBQQ__Subscription__c> subscriptionList = new List<SBQQ__Subscription__c>();
        SBQQ__Subscription__c subscription1 = new SBQQ__Subscription__c(
            SBQQ__QuoteLine__c=quoteLineOne.Id,
            SBQQ__NetPrice__c = 10,
            SBQQ__RenewalQuantity__c = -5,
            SBQQ__Quantity__c = -5,
            SBQQ__Product__c = vgProduct.Id,
            SBQQ__Contract__c = ctt.Id,
            SBQQ__SubscriptionStartDate__c = ctt.StartDate,
            SBQQ__SubscriptionEndDate__c=ctt.EndDate,
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
            SBQQ__Contract__c = ctt.Id,
            //SBQQ__SubscriptionStartDate__c = ctt.StartDate.addYears(1).addDays(2),
            Renewal_LineItem_Type__c = 'Downsell'
        );
        subscriptionList.add(subscription2);
        insert subscriptionList;       
        subscription1=[Select Id ,SBQQ__SubscriptionStartDate__c,SBQQ__SubscriptionEndDate__c From SBQQ__Subscription__c Where Id=:subscription1.Id]; 
        System.assertEquals(ctt.StartDate, subscription1.SBQQ__SubscriptionStartDate__c);
        //System.assertEquals(ctt.EndDate, subscription1.SBQQ__SubscriptionEndDate__c);
        subscription2=[Select Id ,SBQQ__SubscriptionStartDate__c,SBQQ__SubscriptionEndDate__c From SBQQ__Subscription__c Where Id=:subscription2.Id]; 
        System.assertEquals(null, subscription2.SBQQ__SubscriptionStartDate__c);
        System.assertEquals(null, subscription2.SBQQ__SubscriptionEndDate__c);        
        Test.stopTest();
    }    
    @IsTest
    private static void testContractDeactivation(){
        Contract ctt = [SELECT Id, StartDate FROM Contract LIMIT 1];
        
        /*List<Product2> productList = new List<Product2>();
        Product2 testProduct1 = new Product2(Name='Test Product 1');    
        productList.add(testProduct1);
        Product2 testProduct2 = new Product2(Name='Test Product 2');    
        productList.add(testProduct2);
        insert productList;*/
        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'LIC-VG-36MO'];
        
        Test.startTest();
        List<SBQQ__Subscription__c> subscriptionList = new List<SBQQ__Subscription__c>();
        SBQQ__Subscription__c subscription1 = new SBQQ__Subscription__c(
            SBQQ__NetPrice__c = 10,
            SBQQ__RenewalQuantity__c = -5,
            SBQQ__Quantity__c = -5,
            SBQQ__Product__c = vgProduct.Id,
            SBQQ__Contract__c = ctt.Id,
            SBQQ__SubscriptionStartDate__c = ctt.StartDate.addDays(1),
            Renewal_LineItem_Type__c = 'Downsell'
        );
        subscriptionList.add(subscription1);
        SBQQ__Subscription__c subscription2 = new SBQQ__Subscription__c(
            SBQQ__NetPrice__c = 10,
            SBQQ__RenewalQuantity__c = 10,
            SBQQ__Quantity__c = 10,
            SBQQ__BundledQuantity__c=10,
            SBQQ__Product__c = vgProduct.Id,
            SBQQ__Contract__c = ctt.Id,
            SBQQ__SubscriptionStartDate__c = ctt.StartDate.addYears(1).addDays(2),
            Renewal_LineItem_Type__c = 'Downsell'
        );
        subscriptionList.add(subscription2);
        insert subscriptionList;
        Test.stopTest();

        ctt = [SELECT Id, Deactivated__c FROM Contract WHERE Id = :ctt.Id];
        System.assertEquals(false, ctt.Deactivated__c);
        subscription2.SBQQ__Quantity__c=0;
        update subscription2;
        ctt = [SELECT Id, Deactivated__c FROM Contract WHERE Id = :ctt.Id];
        System.assertEquals(true, ctt.Deactivated__c);     
        subscription2.SBQQ__Quantity__c=10;
        update subscription2;
        ctt = [SELECT Id, Deactivated__c FROM Contract WHERE Id = :ctt.Id];
        System.assertEquals(false, ctt.Deactivated__c);   
        SBQQSubscriptionHelper.skippMethod=new Set<String>();
        delete subscription2;       
        ctt = [SELECT Id, Deactivated__c FROM Contract WHERE Id = :ctt.Id];
        System.assertEquals(true, ctt.Deactivated__c);    
        SBQQSubscriptionHelper.skippMethod=new Set<String>();
        undelete subscription2;       
        ctt = [SELECT Id, Deactivated__c FROM Contract WHERE Id = :ctt.Id];
        System.assertEquals(false, ctt.Deactivated__c);            
    }    
}
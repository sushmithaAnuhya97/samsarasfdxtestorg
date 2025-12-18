/**
 * Jan-10-2023 Rajesh GTMS-10518
 */
@isTest
public with sharing class LegacySubscriptionsFixBatchTest {
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
        List<Contract> contracts = new List<Contract>();
        Contract contract = new Contract(
                AccountId = account.Id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(30),
                ContractTerm = 12
        );
        Contract contract2 = new Contract(
                AccountId = account.Id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(30),
                ContractTerm = 37,
                Sales_Ops_Notes__c = 'Test'
        );
        Contract contract3 = new Contract(
                AccountId = account.Id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(30),
                ContractTerm = 72,
                Sales_Ops_Notes__c = 'Test'
        );
        Contract contract4 = new Contract(
                AccountId = account.Id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(30),
                ContractTerm = 24,
                Sales_Ops_Notes__c = 'Test'
        );
        Contract contract5 = new Contract(
                AccountId = account.Id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(30),
                ContractTerm = 75,
                Sales_Ops_Notes__c = 'Test'
        );
        contracts.add(contract);
        contracts.add(contract2);
        contracts.add(contract3);
        contracts.add(contract4);
        contracts.add(contract5);
        insert contracts;
        
        Opportunity revenueOpportunity = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90, StageName = 'Incubate', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8');
        insert revenueOpportunity;        
    }
    @IsTest
    private static void testBeforeInsert(){
        Account testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name like '%Test Account%'];
        Opportunity testOpportunity = [SELECT id, Name From Opportunity WHERE Name='Revenue Opportunity'];
        List<Contract> ctt = [SELECT Id, StartDate,EndDate FROM Contract];
        
        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'LIC-VG-36MO'];
        PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: vgProduct.Id]; 
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id, 
                                                  SBQQ__Primary__c = false, SBQQ__Type__c='Quote',
                                                  SBQQ__SubscriptionTerm__c=12);
        SBQQ__Quote__c quote2 = new SBQQ__Quote__c(Quote_Name__c = 'Test Version', SBQQ__Opportunity2__c =testOpportunity.Id, 
                                                  SBQQ__Primary__c = false, SBQQ__Type__c='Quote',
                                                  SBQQ__SubscriptionTerm__c=37);
        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        quotes.add(quote);
        quotes.add(quote2);
        insert quotes;
        
        List<SBQQ__QuoteLine__c> newlineItems = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id,
                                                                  SBQQ__ListPrice__c=100);
        newlineItems.add(quoteLineOne); 
        
        SBQQ__QuoteLine__c quoteLineTwo =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote2.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vgProduct.Id, accountLookupTest__c = testAccount.Id,
                                                                  SBQQ__ListPrice__c=100);
        newlineItems.add(quoteLineTwo);
        
        insert newlineItems;
        List<SBQQ__Subscription__c> subscriptionList = new List<SBQQ__Subscription__c>();
        SBQQ__Subscription__c subscription1 = new SBQQ__Subscription__c(
            SBQQ__QuoteLine__c=quoteLineOne.Id,
            SBQQ__NetPrice__c = 10,
            SBQQ__RenewalQuantity__c = -5,
            SBQQ__Quantity__c = -5,
            SBQQ__Product__c = vgProduct.Id,
            SBQQ__Contract__c = ctt[0].Id,
            SBQQ__SubscriptionStartDate__c = ctt[0].StartDate,
            SBQQ__SubscriptionEndDate__c=ctt[0].EndDate,
            Renewal_LineItem_Type__c = 'Downsell',
            NS_Unit_Rate__c = 100
        );
        subscriptionList.add(subscription1);
        SBQQ__Subscription__c subscription2 = new SBQQ__Subscription__c(
            SBQQ__QuoteLine__c=quoteLineTwo.Id,
            SBQQ__NetPrice__c = 10,
            SBQQ__RenewalQuantity__c = 10,
            SBQQ__Quantity__c = 10,
            SBQQ__BundledQuantity__c=10,
            SBQQ__Product__c = vgProduct.Id,
            SBQQ__Contract__c = ctt[0].Id,
            SBQQ__SubscriptionStartDate__c = ctt[0].StartDate,
            SBQQ__SubscriptionEndDate__c=ctt[0].EndDate,
            Renewal_LineItem_Type__c = 'Downsell',
            NS_Unit_Rate__c = 100
        );
        subscriptionList.add(subscription2);
        SBQQ__Subscription__c subscription3 = new SBQQ__Subscription__c(
            SBQQ__QuoteLine__c=quoteLineOne.Id,
            SBQQ__NetPrice__c = 10,
            SBQQ__RenewalQuantity__c = -5,
            SBQQ__Quantity__c = -5,
            SBQQ__Product__c = vgProduct.Id,
            SBQQ__Contract__c = ctt[1].Id,
            SBQQ__SubscriptionStartDate__c = ctt[1].StartDate,
            SBQQ__SubscriptionEndDate__c=ctt[1].EndDate,
            Renewal_LineItem_Type__c = 'Downsell',
            NS_Unit_Rate__c = 100
        );
        subscriptionList.add(subscription3);
        SBQQ__Subscription__c subscription4 = new SBQQ__Subscription__c(
            //SBQQ__QuoteLine__c=quoteLineOne.Id,
            SBQQ__NetPrice__c = 10,
            SBQQ__RenewalQuantity__c = -5,
            SBQQ__Quantity__c = -5,
            SBQQ__Product__c = vgProduct.Id,
            SBQQ__Contract__c = ctt[2].Id,
            SBQQ__SubscriptionStartDate__c = ctt[2].StartDate,
            SBQQ__SubscriptionEndDate__c=ctt[2].EndDate,
            Renewal_LineItem_Type__c = 'Downsell',
            NS_Unit_Rate__c = 100,
            SBQQ__ListPrice__c = 100,
            Prior_OppId_Legacy__c = testOpportunity.id
        );
        subscriptionList.add(subscription4);
        SBQQ__Subscription__c subscription5 = new SBQQ__Subscription__c(
            SBQQ__QuoteLine__c=quoteLineOne.Id,
            SBQQ__NetPrice__c = 10,
            SBQQ__RenewalQuantity__c = -5,
            SBQQ__Quantity__c = -5,
            SBQQ__Product__c = vgProduct.Id,
            SBQQ__Contract__c = ctt[3].Id,
            SBQQ__SubscriptionStartDate__c = ctt[3].StartDate,
            SBQQ__SubscriptionEndDate__c=ctt[3].EndDate,
            Renewal_LineItem_Type__c = 'Downsell',
            NS_Unit_Rate__c = 100
        );
        subscriptionList.add(subscription5);
        SBQQ__Subscription__c subscription6 = new SBQQ__Subscription__c(
            SBQQ__QuoteLine__c=quoteLineOne.Id,
            SBQQ__NetPrice__c = 10,
            SBQQ__RenewalQuantity__c = -5,
            SBQQ__Quantity__c = -5,
            SBQQ__Product__c = vgProduct.Id,
            SBQQ__Contract__c = ctt[4].Id,
            SBQQ__SubscriptionStartDate__c = ctt[4].StartDate,
            SBQQ__SubscriptionEndDate__c=ctt[4].EndDate,
            Renewal_LineItem_Type__c = 'Downsell',
            NS_Unit_Rate__c = 100
        );
        subscriptionList.add(subscription6);
        insert subscriptionList;       
               
        String chron = '0 1 * * * ?';
        Test.startTest();
            database.executebatch(new LegacySubscriptionsFixBatch(),5);
        Test.stopTest();
    }  
}
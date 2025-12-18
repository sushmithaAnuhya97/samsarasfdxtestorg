/**
 * Jan-10-2023 Rajesh GTMS-10332
 */
@isTest
public with sharing class ContractConsolidationBatchTest {
    @testSetup
    private static void testDataSetup() {
        //Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        
        //Create Products
        List<Product2> products = new List<Product2>();
        Product2 vg33 = new Product2(Name= 'HW-VG33', ProductCode = 'HW-VG33', Family = 'Test',SBQQ__SubscriptionPricing__c = 'Fixed Price');
        products.add(vg33);
        Product2 vgLicense = new Product2(Name= 'LIC-VG-36MO', ProductCode = 'LIC-VG-36MO', Family = 'Test',SBQQ__SubscriptionPricing__c = 'Fixed Price');
        products.add(vgLicense);  
        Product2 insuranceSUBSIDY = new Product2(Name= 'INS-SUBSIDY', ProductCode = 'INS-SUBSIDY', Family = 'Test',SBQQ__SubscriptionPricing__c = 'Fixed Price');
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
        Opportunity renewalOpportunity = new Opportunity(
            AccountId = account.Id, 
            Name = 'Renewal Opportunity', 
            CloseDate = System.today() + 30, 
            StageName = 'Prospecting', 
            Probability = 5,
            Finance_Partner__c = null
        );
        insert renewalOpportunity;
        
        Opportunity revenueOpportunity = new Opportunity( AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90, StageName = 'Incubate', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8');
        insert revenueOpportunity; 
        
        List<Contract> contracts = new List<Contract>();
        Contract contract = new Contract(
                AccountId = account.Id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(30),
            	Renewal_Data_Clean__c = true,
            	Status = 'Draft',
                ContractTerm = 12
        );
        contracts.add(contract);
        Contract contract2 = new Contract(
                AccountId = account.Id,
                StartDate = Date.today(),
                EndDate = Date.today().adddays(30),
            	Renewal_Data_Clean__c = true,
            	Status = 'Draft',
                ContractTerm = 12
        );
        contracts.add(contract2);
        insert contracts;
        
        for (Contract con : contracts) {
            con.Status = 'Activated';
            con.SBQQ__RenewalOpportunity__c = renewalOpportunity.Id;
            con.Contract_Renewable_ACV__c = 100;

        }
        update contracts;
        
              
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
               
        String chron = '0 1 * * * ?';
        Test.startTest();
        for(Contract c : ctt){

            c.Contract_Renewal_ACV__c = 100;   
        } 
        update ctt;
            ContractConsolidationBatch myClass = new ContractConsolidationBatch(); 
            system.schedule('Test Sched', chron, myClass);
        
            //database.executebatch(new ContractConsolidationBatch(),2);
        Test.stopTest();
    }  
}
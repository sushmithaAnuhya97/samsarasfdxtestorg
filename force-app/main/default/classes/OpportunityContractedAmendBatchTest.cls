/**
 * Nov-17-2022 Rajesh :- GTMS-10058
 */
@isTest(seealldata=true)
public with sharing class OpportunityContractedAmendBatchTest {
    /*@testSetup
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
        
        Contact contactOne = (Contact) TestFactory.createSObject(new Contact(AccountId = acc.Id));
        insert contactOne;
        
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
        
        
        Opportunity revenueOpportunity = new Opportunity( AccountId = acc.Id, License_Term__c =36, Pricebook2Id = pricebookId, 
                                                         Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', 
                                                         CloseDate = System.today() + 90, StageName = 'Incubate', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8'); 
        
        
        insert revenueOpportunity;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Quote_Name__c = 'Test Version One', 
            SBQQ__Account__c = acc.Id, 
            SBQQ__Opportunity2__c=revenueOpportunity.Id, 
            SBQQ__Primary__c = false);
        
        insert quote;
        
        
        
        //Create QuoteLines
        List<SBQQ__QuoteLine__c> newQuoteLines = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLineOne =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = vg33PB.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c = 0, SBQQ__Product__c = vg33.Id);
        newQuoteLines.add(quoteLineOne);
        SBQQ__QuoteLine__c quoteLineTwo =  new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = vgLicensePB.Id, SBQQ__Quantity__c  = 5, 
                                                                  SBQQ__Discount__c =0, SBQQ__Product__c = vgLicense.Id);
        newQuoteLines.add(quoteLineTwo);
        
        insert newQuoteLines;
    }*/

    
    //GTMS-10282
    @IsTest
    private static void testOpportunityContractedAmendBatch() {
        
        
        String chron = '0 1 * * * ?';
        Test.startTest();
            //database.executebatch(new OpportunityContractedAmendBatch(),1);
            
            OpportunityContractedAmendBatch myClass = new OpportunityContractedAmendBatch(); 
            system.schedule('Test Sched', chron, myClass);
        
            
        Test.stopTest();
    }
}
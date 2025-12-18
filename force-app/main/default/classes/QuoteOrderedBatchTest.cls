/**
 *  Nov-9-2022 Rajesh GTMS-10282:- Added method testOpportunityContractedBatch()
 *  Commenting the code as part of GTMS-28734
 */
@isTest
public with sharing class QuoteOrderedBatchTest {
    
    /*@testSetup
    private static void testDataSetup() {
        
        // Disable Triggers via Custom Setting here
        Global_Automation_Settings__c setting = new Global_Automation_Settings__c(Skip_Trigger__c = true);
        insert setting;

        //Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            Name = 'Standard Price Book',
            IsActive = true
        );
        update standardPricebook;
        
         //Create Products
        List<Product2> products = new List<Product2>();
        Product2 vg33Bundle = new Product2(Name= 'VG33-BUNDLE', ProductCode = 'VG33-BUNDLE', Family = 'Test');
        products.add(vg33Bundle);
        
        Product2 vg33 = new Product2(Name= 'HW-VG33', ProductCode = 'HW-VG33', Family = 'Test');
        products.add(vg33);
        
        Product2 vgLicense = new Product2(Name= 'LIC-VG-36MO', ProductCode = 'LIC-VG-36MO', Family = 'Test');
        products.add(vgLicense);
        
        Product2 em11Bundle = new Product2(Name= 'EM11-Bundle', ProductCode = 'EM11-Bundle', Family = 'Test');
        products.add(em11Bundle);
        
        Product2 em11 = new Product2(Name= 'HW-EM11', ProductCode = 'HW-EM11', Family = 'Test');
        products.add(em11);
        
        Product2 emLicense = new Product2(Name= 'LIC-EM-36MO', ProductCode = 'LIC-EM-36MO', Family = 'Test');
        products.add(emLicense);
        
        Product2 vgCable = new Product2(Name= 'CBL-VG-BTSLA3-19', ProductCode = 'CBL-VG-BTSLA3-19', Family = 'Test');
        products.add(vgCable);
        
        insert products;
        
        Map<String, String> requiredProductMap = new Map<String, String> {
			vg33.Id => vg33Bundle.Id,
            vgLicense.Id => vg33Bundle.Id,
            emLicense.Id => em11Bundle.Id,
            em11.Id => em11Bundle.Id    
        };
        
        //Create PriceBookEntries
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry vg33BundlePB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33Bundle.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vg33BundlePB);
        
        PricebookEntry vg33PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vg33.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vg33PB);
        
        PricebookEntry vgLicensePB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vgLicense.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vgLicensePB);
        
        PricebookEntry em11BundlePB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = em11Bundle.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(em11BundlePB);
        
        PricebookEntry em11PB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = em11.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(em11PB);

        PricebookEntry emLicensePB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = emLicense.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(emLicensePB);
        
        PricebookEntry vgCablePB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vgCable.Id, UnitPrice = 10000, IsActive = true);
        pricebookEntries.add(vgCablePB);
        
        insert pricebookEntries;
        
        Map<Id, Id> priceBookEntryMap = new Map<Id, Id> {
            vg33Bundle.Id => vg33BundlePB.Id,
            vg33.Id => vg33PB.Id,
            vgLicense.Id => vgLicensePB.Id,
            em11Bundle.Id => em11BundlePB.Id,    
            emLicense.Id => emLicensePB.Id,
            em11.Id => em11PB.Id,
            vgCable.Id => vgCablePB.Id
        };
        
        // Create account
        List<Account> newAccounts = new List<Account>();
        Account account = new Account (Name = 'Test Account', Organization_Size__c = '5000+', BillingCountry = 'Canada', Industry = 'Other');
        newAccounts.add(account);
        insert newAccounts;

        // Create Contact
        List<Contact> newContacts = new List<Contact>();
        Contact contact = new Contact (FirstName = 'User', LastName = 'Tester', Email = 'test@test.com', AccountId=account.Id);
        newContacts.add(contact);
        insert newContacts;
        
        //Create Shipping Address
        List<Shipping_Address__c> shippingAddresses = new  List<Shipping_Address__c>();
        
       	Shipping_Address__c shipTo = new Shipping_Address__c(Account__c = account.Id, Shipping_Contact__c = contact.Id, Shipping_Address_Line_1__c = '444 Deharo St'
        	, Shipping_City__c = 'San Francisco', Shipping_State__c = 'California', Shipping_Country__c ='United States', Shipping_Zip_Code__c = '95054', Name = 'Ship To One');
        shippingAddresses.add(shipTo);        
        
        Shipping_Address__c shipToTwo = new Shipping_Address__c(Account__c = account.Id, Shipping_Contact__c = contact.Id, Shipping_Address_Line_1__c = '610 Park View Dr'
        	, Shipping_Address_Line_2__c= 'XYZ', Shipping_City__c = 'Santa Clara', Shipping_State__c = 'California', Shipping_Country__c ='United States'
            , Shipping_Zip_Code__c = '95054', Name = 'Ship To Two');
        shippingAddresses.add(shipToTwo);   
        
        Shipping_Address__c shipToThree = new Shipping_Address__c(Account__c = account.Id, Shipping_Contact__c = contact.Id, 
        	Shipping_Address_Line_1__c = '1 Parliment St', Shipping_City__c = 'London', Shipping_Country__c ='United Kingdom'
            , Shipping_Zip_Code__c = 'SW1A2JR', Name = 'Ship To Three');
        shippingAddresses.add(shipToThree);
        
        Shipping_Address__c shipToFour = new Shipping_Address__c(Account__c = account.Id, Shipping_Contact__c = contact.Id, Shipping_Address_Line_1__c = '1 Parliment St'
        	, Shipping_Address_Line_2__c= 'XYZ', Shipping_City__c = 'London', Shipping_Country__c ='United Kingdom'
            , Shipping_Zip_Code__c = 'SW1A2JR', Name = 'Ship To Four');
        shippingAddresses.add(shipToFour);
        
        Shipping_Address__c shipToMexico = new Shipping_Address__c(Account__c = account.Id, Shipping_Contact__c = contact.Id, Shipping_Address_Line_1__c = '1 Parliment St'
        	, Shipping_Address_Line_2__c= 'XYZ', Shipping_City__c = 'Mexico', Shipping_State__c = 'Distrito Federal', Shipping_Country__c ='Mexico'
            , Shipping_Zip_Code__c = 'SW1A2JR', Name = 'Ship To Mexico');
        shippingAddresses.add(shipToMexico);
        
        insert shippingAddresses;
        
        //Create Opportunity
        List<Opportunity> newOpportunities = new List<Opportunity>();
        Opportunity ftOpportunity = new Opportunity( 
            AccountId = account.Id, Type = 'Free Trial Opportunity', Name = 'Opp Testers 1 Inc', StageName = 'Ready to Ship',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
            Shipping_Contact__c = contact.Id, Selected_Payment_Type__c = 'Direct Annual', Price_Book_Name__c = 'Standard Price Book', 
            Send_Invoice__c = false, CloseDate = System.today() + 90, FT_Conversion_Netsuite_Id__c = '21909166', All_Serial_Numbers__c = '343536-63535'
        );            
        newOpportunities.add(ftOpportunity);
        
        Opportunity revenueOpportunity = new Opportunity( 
            AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId,Shipping_Country__c='United States', 
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId(),
        	Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', 
            CloseDate = System.today() + 90, StageName = 'Not Shipped', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8',
            Type='Revenue Opportunity', Shipping_Address_NEW__c=null); 
        newOpportunities.add(revenueOpportunity); 
                
        TriggerHandler.bypass('OpportunityTriggerHandler');
        
        insert newOpportunities;
        
        SBQQ.TriggerControl.disable();
        
        List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c ftQuote = new SBQQ__Quote__c();
        ftQuote.SBQQ__PricebookId__c = pricebookId;
        ftQuote.Quote_Name__c = 'FT Quote';
        ftQuote.SBQQ__Status__c = 'Approved';
        ftQuote.SBQQ__Opportunity2__c = ftOpportunity.Id;
        ftQuote.SBQQ__Account__c = account.Id;
        ftQuote.RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('Free_Trial').getRecordTypeId();
        ftQuote.SBQQ__Primary__c = true;
        newQuotes.add(ftQuote);
        
        SBQQ__Quote__c revQuote = new SBQQ__Quote__c();
        revQuote.SBQQ__PricebookId__c = pricebookId;
        revQuote.Quote_Name__c = 'RevQuote';
        revQuote.SBQQ__Status__c = 'Approved';
        revQuote.SBQQ__Opportunity2__c = revenueOpportunity.Id;
        revQuote.SBQQ__Account__c = account.Id;
        revQuote.Selected_Payment_Type__c = 'Direct Monthly'; 
        revQuote.SBQQ__Primary__c = true;
        newQuotes.add(revQuote);
        
        insert newQuotes;
        
        ftOpportunity.TrialResolutionOppty__c = revenueOpportunity.Id;
        ftOpportunity.SBQQ__PrimaryQuote__c = ftQuote.Id;
        revenueOpportunity.SBQQ__PrimaryQuote__c = revQuote.Id;
        update new List<Opportunity> { ftOpportunity, revenueOpportunity};
        
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        
        Map<Id, SBQQ__QuoteLine__c> quoteLineMap = new Map<Id, SBQQ__QuoteLine__c>();
        
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        
        for(Product2 product: products) {
            SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
         	quoteLine.SBQQ__Quote__c  = ftQuote.Id;
            quoteLine.SBQQ__Product__c  = product.Id;
            quoteLine.SBQQ__PricebookEntryId__c = priceBookEntryMap.get(product.Id);
            quoteLine.Account__c = account.Id; 
            quoteLine.Ship_To__c  = null;
          	quoteLine.SBQQ__Quantity__c  = 5;
            quoteLine.SBQQ__CustomerPrice__c = 100;
            quoteLine.SBQQ__ListPrice__c = 100;
            quoteLine.SBQQ__NetPrice__c = 100;
            quoteLines.add(quoteLine);
            quoteLineMap.put(product.Id, quoteLine);
            
            OpportunityLineItem oppLineItem = new OpportunityLineItem();
            oppLineItem.Product2Id = product.Id;
            oppLineItem.Account__c = account.Id;
            oppLineItem.PricebookEntryId = priceBookEntryMap.get(product.Id);
           	oppLineItem.OpportunityId = ftOpportunity.Id;
            oppLineItem.Quantity = 5;
            oppLineItem.UnitPrice = 100;
            oppLineItems.add(oppLineItem);
        }
        
        insert quoteLines;
        
        insert oppLineItems;
        
        for(OpportunityLineItem oppLineItem : oppLineItems) {
            SBQQ__QuoteLine__c quoteLine = quoteLineMap.get(oppLineItem.Product2Id);
            oppLineItem.SBQQ__QuoteLine__c = quoteLine.Id;
        }
        
        for(SBQQ__QuoteLine__c quoteLine : quoteLines) {
            Id requiredProdId = requiredProductMap.get(quoteLine.SBQQ__Product__c);
            if(requiredProdId != null) {
                SBQQ__QuoteLine__c requiredLine = quoteLineMap.get(requiredProdId);
            	quoteLine.SBQQ__RequiredBy__c = requiredLine.Id;
            }
        }
        
        update oppLineItems;
        
        update quoteLines;
        
        SBQQ.TriggerControl.enable();
    }
    
    @IsTest
    private static void testQuoteOrderedBatch() {
        
        String chron = '0 1 * * * ?';
        Test.startTest();
        QuoteOrderedBatch myClass = new QuoteOrderedBatch(false,null); 
            system.schedule('Test Sched', chron, myClass);
        Test.stopTest();
    }
    
    @isTest
    private static void testException() {
        
            List<SBQQ__Quote__c> quotes = [SELECT Id, SBQQ__Opportunity2__c FROM SBQQ__Quote__c];
            for(SBQQ__Quote__c quote : quotes) {
                quote.SBQQ__Opportunity2__c = null;
            }
            update quotes;
        
       String chron = '0 1 * * * ?';
       Test.startTest();
       QuoteOrderedBatch myClass = new QuoteOrderedBatch(false,null); 
       system.schedule('Test Sched', chron, myClass);
        Test.stopTest();
    }*/
    
    @isTest
    private static void testException() {
    	//No logic 
    }


}
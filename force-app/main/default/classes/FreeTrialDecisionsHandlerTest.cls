/**********************************************************************
Name: FreeTrialDecisionsHandlerTest
=======================================================================
Purpose: This class will contain test class for Free Trial Decision logic                                                        
=======================================================================
History  

VERSION     AUTHOR               DATE               DETAIL                       
1.0        Rodrigo Carpio        2023-Mar-06        INITIAL DEVELOPMENT FOR GTMS-11881

***********************************************************************/
@IsTest
private class FreeTrialDecisionsHandlerTest {
    
    @testSetup
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
            AccountId = account.Id, Type = 'Free Trial Opportunity', Name = 'Opp Testers 1 Inc', StageName = 'Incubate',
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
        
        Opportunity ammendedOpp1 = new Opportunity( 
            AccountId = account.Id, License_Term__c =36, Pricebook2Id = pricebookId,Shipping_Country__c='United States',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId(),
        	Max_Approved_Discount__c=0, Name = 'Revenue Opportunity', Price_Book_Name__c = 'Standard Price Book', 
            CloseDate = System.today() + 90, StageName = 'Not Shipped', Owner_Role_Copy__c='Fleet IS AE2 NA US Team 8',
            Type='Revenue Opportunity', Shipping_Address_NEW__c=null, FT_Conversion_Netsuite_Id__c = '21905464', All_Serial_Numbers__c = '34356-63575'
        );
        newOpportunities.add(ammendedOpp1); 
        
        TriggerHandler.bypass('OpportunityTriggerHandler');
        
        insert newOpportunities;
        
        ftOpportunity.TrialResolutionOppty__c = revenueOpportunity.Id;
        update ftOpportunity;
        
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        
        SBQQ.TriggerControl.disable();
        
        List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c ftQuote = new SBQQ__Quote__c();
        ftQuote.Quote_Name__c = 'FT Quote';
        ftQuote.SBQQ__Opportunity2__c = ftOpportunity.Id;
        ftQuote.SBQQ__Account__c = account.Id;
        ftQuote.RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('Free_Trial').getRecordTypeId();
        newQuotes.add(ftQuote);
        
        insert newQuotes;
        
        Map<Id, SBQQ__QuoteLine__c> quoteLineMap = new Map<Id, SBQQ__QuoteLine__c>();
        
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        
        for(Product2 product: products) {
            SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
         	quoteLine.SBQQ__Quote__c  = ftQuote.Id;
            quoteLine.SBQQ__Product__c  = product.Id;
            quoteLine.Account__c = account.Id; 
            quoteLine.Ship_To__c  = null;
          	quoteLine.SBQQ__Quantity__c  = 5;
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
        
        //Create Contracts
        List<Contract> newContracts = new List<Contract>();
        Contract contract = new Contract();
        contract.AccountId = account.Id;
        contract.StartDate = Date.today() - 200;
        contract.EndDate = Date.today() + 365;
        contract.SBQQ__Opportunity__c = ftOpportunity.Id;
        newContracts.add(contract);
        insert newContracts;
        
        ammendedOpp1.SBQQ__AmendedContract__c = contract.Id;
        update ammendedOpp1;
        
        delete setting;
    }
    
    @isTest
    private static void testGetProductList_FullBuy() {
        Account account = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        Contract contract = [SELECT Id, SBQQ__Opportunity__c FROM Contract WHERE AccountId =: account.Id];
        Opportunity opportunity = [SELECT Id FROM Opportunity WHERE Type = 'Free Trial Opportunity'];
        
        FreeTrialDecisionsHandler.FreeTrialInfo freeTrialInfo = new FreeTrialDecisionsHandler.FreeTrialInfo();
        
        Test.startTest();
        freeTrialInfo = FreeTrialDecisionsHandler.getProductList(contract.Id, 'Full Buy');
        Test.stopTest();
        
        System.assertEquals(7, freeTrialInfo.productList.size(), 'Expected same number of products');
    }
    
    @isTest
    private static void testGetProductList_NoBuy() {
        Account account = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        Contract contract = [SELECT Id, SBQQ__Opportunity__c FROM Contract WHERE AccountId =: account.Id];
        Opportunity opportunity = [SELECT Id FROM Opportunity WHERE Type = 'Free Trial Opportunity'];
        
        FreeTrialDecisionsHandler.FreeTrialInfo freeTrialInfo = new FreeTrialDecisionsHandler.FreeTrialInfo();
        
        Test.startTest();
        freeTrialInfo = FreeTrialDecisionsHandler.getProductList(contract.Id, 'No Buy');
        Test.stopTest();
        
        System.assertEquals(7, freeTrialInfo.productList.size(), 'Expected same number of products');
    }

	@isTest
    private static void testFullBuy() {
    	Account account = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        Contract contract = [SELECT Id, SBQQ__Opportunity__c FROM Contract WHERE AccountId =: account.Id];
        Opportunity opportunity = [SELECT Id FROM Opportunity WHERE Type = 'Free Trial Opportunity'];
        
        FreeTrialDecisionsHandler.FreeTrialFlowInfo freeTrialInfo = new FreeTrialDecisionsHandler.FreeTrialFlowInfo();
        freeTrialInfo.contractId = contract.Id;
        freeTrialInfo.accountId = account.Id;
        freeTrialInfo.opportunityFTId = opportunity.Id;
        freeTrialInfo.opportunityType = 'Revenue Opportunity';
        
        Test.startTest();
        FreeTrialDecisionsHandler.createOpportunityIM(new List<FreeTrialDecisionsHandler.FreeTrialFlowInfo> {freeTrialInfo});
        Test.stopTest();
        
        List<Opportunity> newOpps = [SELECT Id FROM Opportunity WHERE Type = 'Revenue Opportunity' AND SBQQ__AmendedContract__c = null]; 
        System.assertEquals(1, newopps.size(), 'Expected existing opportunity to be updated');
		
        List<SBQQ__Quote__c> newQuotes = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c =:opportunity.Id];
        System.assertEquals(1, newQuotes.size(), 'Expected quote to be linked to existing opportunity');
    }    
    
    @isTest
    private static void testFullBuyWithNoRevOpp() {
    	Account account = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        Contract contract = [SELECT Id, SBQQ__Opportunity__c FROM Contract WHERE AccountId =: account.Id];
        
        Opportunity opportunity = [SELECT Id, TrialResolutionOppty__c FROM Opportunity WHERE Type = 'Free Trial Opportunity'];
        delete [SELECT Id FROM Opportunity WHERE Id =:opportunity.TrialResolutionOppty__c];
        delete [SELECT Id FROM Clari_Opp__c];
        
        FreeTrialDecisionsHandler.FreeTrialFlowInfo freeTrialInfo = new FreeTrialDecisionsHandler.FreeTrialFlowInfo();
        freeTrialInfo.contractId = contract.Id;
        freeTrialInfo.accountId = account.Id;
        freeTrialInfo.opportunityFTId = opportunity.Id;
        freeTrialInfo.opportunityType = 'Revenue Opportunity';
        
        Test.startTest();
        FreeTrialDecisionsHandler.createOpportunityIM(new List<FreeTrialDecisionsHandler.FreeTrialFlowInfo> {freeTrialInfo});
        Test.stopTest();
        
        List<Opportunity> newOpps = [SELECT Id FROM Opportunity WHERE Type = 'Revenue Opportunity' AND SBQQ__AmendedContract__c = null]; 
        System.assertEquals(1, newopps.size(), 'Expected new opportunity to be created');
		
        List<SBQQ__Quote__c> newQuotes = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c =:newOpps[0].Id];
        System.assertEquals(1, newQuotes.size(), 'Expected quote to be new to existing opportunity');
    }
    
    @isTest
    private static void testNoBuy() {
    	Account account = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        Contract contract = [SELECT Id, SBQQ__Opportunity__c FROM Contract WHERE AccountId =: account.Id];
        Opportunity opportunity = [SELECT Id FROM Opportunity WHERE Type = 'Free Trial Opportunity'];
        
        FreeTrialDecisionsHandler.FreeTrialFlowInfo freeTrialInfo = new FreeTrialDecisionsHandler.FreeTrialFlowInfo();
        freeTrialInfo.contractId = contract.Id;
        freeTrialInfo.accountId = account.Id;
        freeTrialInfo.opportunityFTId = opportunity.Id;
        freeTrialInfo.opportunityType = 'Free Trial Return';
        
        Test.startTest();
        FreeTrialDecisionsHandler.createOpportunityIM(new List<FreeTrialDecisionsHandler.FreeTrialFlowInfo> {freeTrialInfo});
        Test.stopTest();

        List<Opportunity> newOpps = [SELECT Id FROM Opportunity WHERE Type = 'Free Trial Return']; 
        System.assertEquals(1, newopps.size(), 'Expected new opportunity to be created');
		
        List<SBQQ__Quote__c> newQuotes = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c =:newOpps[0].Id];
        System.assertEquals(1, newQuotes.size(), 'Expected quote to be new to existing opportunity');
    }
    
    @isTest
    private static void testPartialBuy1() {
    	Account account = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        Contract contract = [SELECT Id, SBQQ__Opportunity__c FROM Contract WHERE AccountId =: account.Id];
        Opportunity opportunity = [SELECT Id FROM Opportunity WHERE Type = 'Free Trial Opportunity'];
        
        List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id, Ship_From_Location__c FROM SBQQ__QuoteLine__c];
        for(SBQQ__QuoteLine__c quoteLine : quoteLines) {
            quoteLine.Ship_From_Location__c = 'Estafeta';
        }
        update quoteLines;
        
        List<String> productIdList = new List<String>();
        List<OpportunityLineItem> oppLineItems = [SELECT Id FROM OpportunityLineItem WHERE Product2.Name LIKE '%LIC%'];
        for(OpportunityLineItem oppLineItem : oppLineItems) {
            productIdList.add(oppLineItem.Id + '|' + '1');
        }
        
        FreeTrialDecisionsHandler.FreeTrialFlowInfo freeTrialInfo = new FreeTrialDecisionsHandler.FreeTrialFlowInfo();
        freeTrialInfo.contractId = contract.Id;
        freeTrialInfo.accountId = account.Id;
        freeTrialInfo.opportunityFTId = opportunity.Id;
        freeTrialInfo.opportunityType = 'Revenue Opportunity';
        freeTrialInfo.productIdListStr = String.join(productIdList, ';');
        
        Test.startTest();
        FreeTrialDecisionsHandler.createOpportunityIM(new List<FreeTrialDecisionsHandler.FreeTrialFlowInfo> {freeTrialInfo});
        Test.stopTest();

        List<Opportunity> newOpps = [SELECT Id FROM Opportunity WHERE (Type = 'Free Trial Return' OR Type = 'Revenue Opportunity') AND SBQQ__AmendedContract__c = null]; 
        System.assertEquals(2, newopps.size(), 'Expected new opportunity to be created');
		
        List<SBQQ__Quote__c> newQuotes = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c IN:newOpps];
        System.assertEquals(2, newQuotes.size(), 'Expected quote to be linked to new opportunity');
    }
    
    @isTest
    private static void testPartialBuy2() {
    	Account account = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        Contract contract = [SELECT Id, SBQQ__Opportunity__c FROM Contract WHERE AccountId =: account.Id];
        Opportunity opportunity = [SELECT Id FROM Opportunity WHERE Type = 'Free Trial Opportunity'];
        
        List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id, Ship_From_Location__c FROM SBQQ__QuoteLine__c];
        for(SBQQ__QuoteLine__c quoteLine : quoteLines) {
            quoteLine.Ship_From_Location__c = 'VCK';
        }
        update quoteLines;
        
        List<String> productIdList = new List<String>();
        List<OpportunityLineItem> oppLineItems = [SELECT Id FROM OpportunityLineItem WHERE Product2.Name LIKE '%LIC%'];
        for(OpportunityLineItem oppLineItem : oppLineItems) {
            productIdList.add(oppLineItem.Id + '|' + '1');
        }
        
        FreeTrialDecisionsHandler.FreeTrialFlowInfo freeTrialInfo = new FreeTrialDecisionsHandler.FreeTrialFlowInfo();
        freeTrialInfo.contractId = contract.Id;
        freeTrialInfo.accountId = account.Id;
        freeTrialInfo.opportunityFTId = opportunity.Id;
        freeTrialInfo.opportunityType = 'Revenue Opportunity';
        freeTrialInfo.productIdListStr = String.join(productIdList, ';');
        
        Test.startTest();
        FreeTrialDecisionsHandler.createOpportunityIM(new List<FreeTrialDecisionsHandler.FreeTrialFlowInfo> {freeTrialInfo});
        Test.stopTest();

        List<Opportunity> newOpps = [SELECT Id FROM Opportunity WHERE (Type = 'Free Trial Return' OR Type = 'Revenue Opportunity') AND SBQQ__AmendedContract__c = null]; 
        System.assertEquals(2, newopps.size(), 'Expected new opportunity to be created');
		
        List<SBQQ__Quote__c> newQuotes = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c IN:newOpps];
        System.assertEquals(2, newQuotes.size(), 'Expected quote to be linked to new opportunity');
    }
}
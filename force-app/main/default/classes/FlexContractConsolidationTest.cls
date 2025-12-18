/********************************************************************************************************************************************
* 05/06/2025    - Flex         - Pratyush,Rajat,Manglesh/ Accenture 	   - Test class for FlexContractConsolidation & ProductWrapper
*											
*/

@isTest
private class FlexContractConsolidationTest {
    
    /**
     * Utility method to bypass all relevant triggers for testing
     */
    private static void bypassTriggers() {
        // Bypass all relevant triggers
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('GS_SBQQQuoteTriggerHandler');
        TriggerHandler.bypass('OpportunityLineItemTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        TriggerHandler.bypass('ContractTriggerHandler');
        TriggerHandler.bypass('GS_ContactTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        
        // Disable CPQ triggers
        SBQQ.TriggerControl.disable();
    }

    @TestSetup
    static void setupTestData() {
        // Bypass all triggers for testing
        bypassTriggers();
        
        Pricebook2 standardPricebook = new Pricebook2(
        Name = 'Standard Price Book',
        IsActive = true
        );
        insert standardPricebook;
         FlexConstants__c setting = new FlexConstants__c(
            Name = 'FlexConstants',
            Flex_Access_QuoteLine__c = 'FlexAccessQuoteLine',
            Default_Pricebook_ID__c	 = standardPricebook.Id
          
        );
        insert setting;
        // Create test account
        List<Account> newAccounts = new List<Account>();
        Account testAccount = new Account(Name = 'Flex Account',
                                         BillingStreet = '26 Napier Street',
                                         BillingCity = 'London',
                                         Account_C_R_In_Progress__c= true,
                                         BillingPostalCode  = '1030',
                                         BillingCountry = 'United Kingdom',
                                         Billing_Email__c  = 'qdasdas@gmail.com',
                                         Organization_Size__c = '100 - 499',
                                         Industry = 'Other');
        newAccounts.add(testAccount);
        insert newAccounts; 

        // Create shipping address first
        Shipping_Address__c shipTo = new Shipping_Address__c(
            Account__c = testAccount.Id,
            Shipping_Address_Line_1__c = '444 Deharo St',
            Shipping_City__c = 'San Francisco', 
            Shipping_State__c = 'California',
            Shipping_Country__c = 'United States',
            Shipping_Zip_Code__c = '95054',
            Name = 'Ship To One'
            //Is_Active__c = true  // Make sure the address is active
        );
        insert shipTo;

        SBQQ__PricingGuidance__c guid= new SBQQ__PricingGuidance__c(Name='Test');
        insert guid;
        List<Product2> products = new List<Product2>();
       
        Product2 prod1 = new Product2(Name = 'WiFi Hotspot - 2GB Total Data', Flex_SKU_Hierarchy__c = 1,
            Flex_PLTFM_Hierarchy__c = 1,SBQQ__PricingGuidance__c=guid.Id,
            Flex_HW_Hierarchy__c = 1,
                                      Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        products.add(prod1);
        Product2 prod2 = new Product2(Name = 'WiFi Hotspot - 1GB Total Data',  Flex_SKU_Hierarchy__c = 2,
            Flex_PLTFM_Hierarchy__c = 2,SBQQ__PricingGuidance__c=guid.Id,
            Flex_HW_Hierarchy__c = 2,Family = 'Hardware', ProductCode = 'LIC-2GB-WIFI-DATA',Product_Type__c = 'License');
        products.add(prod2);
        insert products;


        // Case 1  isMatchingHierarchyForPnPScreen2
        List<Product2> productsForCase1 = new List<Product2>();
        List<Product2> subproductsForCase1 = new List<Product2>();

        Product2 prod3 = new Product2(
            Name = 'WiFi Hotspot - 3GB Total Data sub',  
            Flex_SKU_Hierarchy__c = 1,
            Flex_PLTFM_Hierarchy__c = 1,
            SBQQ__PricingGuidance__c=guid.Id,
            Flex_HW_Hierarchy__c = 3,
            Family = 'Hardware', 
            ProductCode = 'LIC-2GB-WIFI-DATA',
            Product_Type__c = 'License',
            License_Type__c ='Pro'
        );
        subProductsForCase1.add(prod3);

        Product2 prod4 = new Product2(
            Name = 'sub-product-test-1',  
            Flex_SKU_Hierarchy__c = 1,
            Flex_PLTFM_Hierarchy__c = 1,
            Flex_HW_Hierarchy__c = 2,
            SBQQ__PricingGuidance__c=guid.Id,
            Family = 'Hardware', 
            ProductCode = 'LIC-2GB-WIFI-DATA',
            Product_Type__c = 'License',
            License_Type__c ='Pro'
        );
        productsForCase1.add(prod4);

        insert productsForCase1;
        insert subProductsForCase1;
        
        // Case 2  isMatchingHierarchyForPnPScreen2

        // createing valid contracts with subs and that subs will contain products 

        List<Product2> productList = new List<Product2>();
        Product2 prod5 = new Product2(
            Name = 'sub-product-test-2',  
            Flex_SKU_Hierarchy__c = 2,
            Flex_PLTFM_Hierarchy__c = 2,
            Flex_HW_Hierarchy__c = 3,
            SBQQ__PricingGuidance__c=guid.Id,
            Family = 'Hardware', 
            ProductCode = 'LIC-2GB-WIFI-DATA',
            Product_Type__c = 'License',
            License_Type__c ='Pro'
        );
        productList.add(prod5);

        Product2 prod6 = new Product2(
            Name = 'sub-product-test-3',  
            Flex_SKU_Hierarchy__c = 4,
            Flex_PLTFM_Hierarchy__c = 5,
            Flex_HW_Hierarchy__c = 3,
            SBQQ__PricingGuidance__c=guid.Id,
            Family = 'Hardware', 
            ProductCode = 'LIC-2GB-WIFI-DATA',
            Product_Type__c = 'License',
            License_Type__c ='Pro'
        );
        productList.add(prod6);

        // Add more products for PnP toggle ON scenario
        Product2 prod7 = new Product2(
            Name = 'sub-product-test-4',  
            Flex_SKU_Hierarchy__c = 3,
            Flex_PLTFM_Hierarchy__c = 4,
            Flex_HW_Hierarchy__c = 3,
            SBQQ__PricingGuidance__c=guid.Id,
            Family = 'Hardware', 
            ProductCode = 'LIC-2GB-WIFI-DATA',
            Product_Type__c = 'License',
            License_Type__c ='Pro'
        );
        productList.add(prod7);

        Product2 prod8 = new Product2(
            Name = 'sub-product-test-5',  
            Flex_SKU_Hierarchy__c = 5,
            Flex_PLTFM_Hierarchy__c = 6,
            Flex_HW_Hierarchy__c = 3,
            SBQQ__PricingGuidance__c=guid.Id,
            Family = 'Hardware', 
            ProductCode = 'LIC-2GB-WIFI-DATA',
            Product_Type__c = 'License',
            License_Type__c ='Pro'
        );
        productList.add(prod8);

        insert productList;
        Id standardPbId = Test.getStandardPricebookId();

            // Create Opportunity
        List<Opportunity> newOppsList = new List<Opportunity>();
        Opportunity revenueOpportunity1 = new Opportunity(
            AccountId = testAccount.Id, 
            License_Term__c = 36, 
            Pricebook2Id = standardPbId, 
            Max_Approved_Discount__c = 0, 
            Name = 'Revenue Opportunity1-test', 
            Price_Book_Name__c = 'Standard Price Book', 
            CloseDate = System.today() + 90, 
            StageName = 'Incubate', 
            Owner_Role_Copy__c = 'Fleet IS AE2 NA US Team 8',
            Selected_Payment_Type__c = 'Direct Annual'
        ); 
        newOppsList.add(revenueOpportunity1);
        insert newOppsList;


        // createQuoteData();

        List<SBQQ__Quote__c> quoteList = [SELECT Id FROM SBQQ__Quote__c];
       
        List<Contract> contractList = new List<Contract>(); 
        Contract contract1 = new Contract(
            AccountId = testAccount.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(130),
            ContractTerm = 12,
            SBQQ__Opportunity__c = revenueOpportunity1.Id
           
        );
        contractList.add(contract1);
        insert contractList;

        // Create Subscriptions
        List<SBQQ__Subscription__c> subList = new List<SBQQ__Subscription__c>();
        SBQQ__Subscription__c sub1 = new SBQQ__Subscription__c(
            SBQQ__Quantity__c = 1,
            SBQQ__CustomerPrice__c = 100,
            SBQQ__Contract__c = contractList[0].id,
            SBQQ__Account__c = testAccount.id,
            SBQQ__Product__c = productList[0].Id
        );
        subList.add(sub1);
        insert subList;
        
        // Create pricebook entries
        
        List<PricebookEntry> pbes = new List<PricebookEntry>();
        pbes.add(new PricebookEntry(
            Pricebook2Id = standardPbId,
            Product2Id = prod1.Id,
            UnitPrice = 100,
            IsActive = true
        ));
        pbes.add(new PricebookEntry(
            Pricebook2Id = standardPbId,
            Product2Id = prod2.Id,
            UnitPrice = 200,
            IsActive = true
        ));
        pbes.add(new PricebookEntry(
            Pricebook2Id = standardPbId,
            Product2Id = prod3.Id,
            UnitPrice = 300,
            IsActive = true
        ));
        pbes.add(new PricebookEntry(
            Pricebook2Id = standardPbId,
            Product2Id = prod4.Id,
            UnitPrice = 400,
            IsActive = true
        ));
        pbes.add(new PricebookEntry(
            Pricebook2Id = standardPbId,
            Product2Id = prod5.Id,
            UnitPrice = 400,
            IsActive = true
        ));
        pbes.add(new PricebookEntry(
            Pricebook2Id = standardPbId,
            Product2Id = prod6.Id,
            UnitPrice = 500,
            IsActive = true
        ));
        pbes.add(new PricebookEntry(
            Pricebook2Id = standardPbId,
            Product2Id = prod7.Id,
            UnitPrice = 450,
            IsActive = true
        ));
        pbes.add(new PricebookEntry(
            Pricebook2Id = standardPbId,
            Product2Id = prod8.Id,
            UnitPrice = 550,
            IsActive = true
        ));
        insert pbes;
        
        // Create shipping address
       	Shipping_Address__c shipTo1 = new Shipping_Address__c();
        shipTo.Account__c = testAccount.Id;
        shipTo.Shipping_Address_Line_1__c = '444 Deharo St';
        
        shipTo.Shipping_City__c = 'San Francisco'; 
        shipTo.Shipping_State__c = 'California';
        shipTo.Shipping_Country__c ='United States';
        shipTo.Shipping_Zip_Code__c = '95054';
        shipTo.Name = 'Ship To One';
        
        insert shipTo1;
        
        // Create contract
        Contract testContract =new Contract(
            AccountId = testAccount.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            ContractTerm = 1,
            Status = 'Draft'
        );
        insert testContract;
        
        Opportunity newOpp = new Opportunity();
        newOpp.Name = 'New Deal';
        newOpp.StageName = 'Prospecting';
        newOpp.CloseDate = Date.today().addDays(30);
        newOpp.Amount = 10000;
        newOpp.AccountId = testAccount.Id;
        insert newOpp;
        
        
        
        
        SBQQ__Quote__c newQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,  // Make sure to set the account
            SBQQ__Opportunity2__c = newOpp.Id,
            SBQQ__Status__c = 'Draft',
            SBQQ__BillingStreet__c = '123 Main St',
            SBQQ__BillingCity__c = 'San Francisco',
            SBQQ__BillingState__c = 'CA',
            SBQQ__BillingPostalCode__c = '94105',
            SBQQ__Type__c='Amendment',
            Shipping_Address_NEW__c=shipTo.Id
        );
        insert newQuote;
        
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Product__c = prod1.Id,
            SBQQ__PricebookEntryId__c = pbes[0].Id,
            Ship_To__c = shipTo.Id,
            SBQQ__Number__c = 1,
            SBQQ__Quantity__c = 0,
            SBQQ__Quote__c = newQuote.Id
            //SBQQ__Account__c = testAccount.Id  
        );
        insert quoteLine;   

        List<SBQQ__Subscription__c> subs = new List<SBQQ__Subscription__c>();
        subs.add(new SBQQ__Subscription__c(
            SBQQ__Contract__c = testContract.Id,
            SBQQ__Product__c = prod1.Id,
            SBQQ__Quantity__c = 5,
           	Ship_To__c = shipTo.Id,
            SBQQ__CustomerPrice__c = 100
        ));
        subs.add(new SBQQ__Subscription__c(
            SBQQ__Contract__c = testContract.Id,
            SBQQ__Product__c = prod2.Id,
            SBQQ__Quantity__c = 3,
            SBQQ__QuoteLine__c = quoteLine.Id,
            SBQQ__CustomerPrice__c = 200
        ));
        insert subs;
    }

    public static void createQuoteData() {
        Account testAccount = [SELECT id, Name, BillingCountry FROM Account WHERE Name LIKE 'Test Account%' LIMIT 1];
        Map<String, Opportunity> oppNameToOppMap = new Map<String, Opportunity>();
        for (Opportunity testOpportunity : [SELECT id, Name From Opportunity]) {
            oppNameToOppMap.put(testOpportunity.Name, testOpportunity);
        }        
        
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        for (Opportunity o : oppNameToOppMap.values()) {
            SBQQ__Quote__c quote = new SBQQ__Quote__c(
                Quote_Name__c = 'Test Flex ', 
                SBQQ__Account__c = testAccount.Id, 
                SBQQ__Opportunity2__c = o.Id,
                SBQQ__SubscriptionTerm__c = 10,
                Estimated_Annual_Payment__c = 24, 
                Selected_Payment_Type__c = 'Direct Annual',
                SBQQ__Status__c = 'Draft',
                SBQQ__Primary__c = true
            );
            quoteList.add(quote);
        }
        
        insert quoteList;
    }


    @isTest
    static void testProductMappingForLegacy(){
        List<String> productIds = new List<String>();
        // Contract testContract = [SELECT Id, AccountId FROM Contract LIMIT 1];
        // Query the contract based on the opportunity name
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Revenue Opportunity1-test' LIMIT 1];
        Contract testContract = [SELECT Id, AccountId FROM Contract WHERE SBQQ__Opportunity__c = :opp.Id LIMIT 1];
        
        Id standardPbId = Test.getStandardPricebookId();

        Test.startTest();
        List<FlexContractConsolidation.ContractSubscriptionParentWrapper> results = 
            FlexContractConsolidation.getSubscriptionsByProductAndAddress(
                new List<Id>{testContract.Id}, 
                standardPbId,
                false,
                false,
                new List<String>()
            );
        Test.stopTest();
        for(FlexContractConsolidation.ContractSubscriptionParentWrapper wrapper : results) {
            System.assertNotEquals(null, wrapper.productId, 'Product ID should not be null');
            System.assertNotEquals(null, wrapper.totalQuantity, 'Total quantity should not be null');
            System.assertNotEquals(null, wrapper.subscriptionWrappers, 'Subscription wrappers should not be null');
        }

    }

    @isTest
    static void testProductMappingForPnPScreenTwo(){
        List<String> productIds = new List<String>();
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Revenue Opportunity1-test' LIMIT 1];
        Contract testContract = [SELECT Id, AccountId FROM Contract WHERE SBQQ__Opportunity__c != :opp.Id LIMIT 1];
        List<Product2> products = [SELECT Id FROM Product2 WHERE Name IN ('sub-product-test-1')];
        for(Product2 pod: products){
            productIds.add(pod.Id);
        }
        Id standardPbId = Test.getStandardPricebookId();

        Test.startTest();
        List<FlexContractConsolidation.ContractSubscriptionParentWrapper> results = 
            FlexContractConsolidation.getSubscriptionsByProductAndAddress(
                new List<Id>{testContract.Id}, 
                standardPbId,
                true,
                false,
                productIds
            );
        Test.stopTest();
        for(FlexContractConsolidation.ContractSubscriptionParentWrapper wrapper : results) {
            System.assertNotEquals(null, wrapper.productId, 'Product ID should not be null');
            System.assertNotEquals(null, wrapper.totalQuantity, 'Total quantity should not be null');
            System.assertNotEquals(null, wrapper.subscriptionWrappers, 'Subscription wrappers should not be null');
        }

    }
    
    @isTest
    static void testGetSubscriptionsByProductAndAddress() {
        
        // Get test contract

        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Revenue Opportunity1-test' LIMIT 1];
        Contract testContract = [SELECT Id, AccountId FROM Contract WHERE SBQQ__Opportunity__c != :opp.Id LIMIT 1];
        List<String> productIds = new List<String>();
        List<Product2> products = [SELECT Id FROM Product2];
        for(Product2 pod: products){
            productIds.add(pod.Id);
        }
        
        // Get test pricebook
        Id standardPbId = Test.getStandardPricebookId();
        
        Test.startTest();
        // pnp Screen One Logic 
        List<FlexContractConsolidation.ContractSubscriptionParentWrapper> results = 
            FlexContractConsolidation.getSubscriptionsByProductAndAddress(
                new List<Id>{testContract.Id}, 
                standardPbId,
                true,
                false,
                productIds
            );
        
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testContract.AccountId
        );
        insert testQuote;
        
        Test.stopTest();
        
        for(FlexContractConsolidation.ContractSubscriptionParentWrapper wrapper : results) {
            System.assertNotEquals(null, wrapper.productId, 'Product ID should not be null');
            System.assertNotEquals(null, wrapper.totalQuantity, 'Total quantity should not be null');
            System.assertNotEquals(null, wrapper.subscriptionWrappers, 'Subscription wrappers should not be null');
        }
    }

    @isTest
    static void testGetSubsByProdPnpScreenOne() {
        
        // Get test contract
        Contract testContract = [SELECT Id, AccountId FROM Contract LIMIT 1];
        List<String> productIds = new List<String>();
        List<Product2> products = [SELECT Id FROM Product2];
        for(Product2 pod: products){
            productIds.add(pod.Id);
        }
        
        // Get test pricebook
        Id standardPbId = Test.getStandardPricebookId();
        
        Test.startTest();
        List<FlexContractConsolidation.ContractSubscriptionParentWrapper> results = 
            FlexContractConsolidation.getSubscriptionsByProductAndAddress(
                new List<Id>{testContract.Id}, 
                standardPbId,
                false,
                false,
                productIds
            );
        
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testContract.AccountId
        );
        insert testQuote;
        
        Test.stopTest();
        
        for(FlexContractConsolidation.ContractSubscriptionParentWrapper wrapper : results) {
            System.assertNotEquals(null, wrapper.productId, 'Product ID should not be null');
            System.assertNotEquals(null, wrapper.totalQuantity, 'Total quantity should not be null');
            System.assertNotEquals(null, wrapper.subscriptionWrappers, 'Subscription wrappers should not be null');
        }
    }
    
    @isTest
    static void testMethod2() {
		test.startTest();
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Revenue Opportunity1-test' LIMIT 1];
        Contract testContract = [SELECT Id, AccountId FROM Contract WHERE SBQQ__Opportunity__c != :opp.Id LIMIT 1];
        
        List<SBQQ__Subscription__c> subs = [SELECT Id, Ship_To__c FROM SBQQ__Subscription__c WHERE Ship_To__c != null];
        
        Id standardPbId = Test.getStandardPricebookId();
        
        // Create test quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testContract.AccountId
        );
        insert testQuote;
        
        // Get subscription wrappers
       	List<FlexContractConsolidation.ContractSubscriptionParentWrapper> parentWrappers = 
            FlexContractConsolidation.getSubscriptionsByProductAndAddress(
                new List<Id>{testContract.Id},
                standardPbId,
                false,
                false,
                null
            );
        
		system.debug('wrappers prent::::'+parentWrappers);            
        List<FlexContractConsolidation.ContractSubscriptionWrapper> wrappers = 
            new List<FlexContractConsolidation.ContractSubscriptionWrapper>();
        for(FlexContractConsolidation.ContractSubscriptionParentWrapper parent : parentWrappers) {
            wrappers.addAll(parent.subscriptionWrappers);
        }
        
        system.debug('wrappers:::'+wrappers);
       
        List<sObject> linesToUpdate = new List<sObject>();
        
        List<SBQQ__Subscription__c> subrecrs = [SELECT Id, Ship_To__c, SBQQ__QuoteLine__c  FROM SBQQ__Subscription__c ];
        for(SBQQ__Subscription__c sub: subrecrs){
        	sub.Ship_To__c = null;
        }
        linesToUpdate.addAll(subrecrs);
        upsert linesToUpdate;
        
        List<FlexContractConsolidation.ContractSubscriptionParentWrapper> parentWrappers1 = 
            FlexContractConsolidation.getSubscriptionsByProductAndAddress(
                new List<Id>{testContract.Id},
                standardPbId,
                false,
                false,
                null
            );
        
        // Add assertions to verify the results
        System.assertNotEquals(0, parentWrappers.size(), 'Initial parent wrappers should not be empty');
        System.assertNotEquals(0, wrappers.size(), 'Subscription wrappers should not be empty');
        System.assertNotEquals(0, parentWrappers1.size(), 'Updated parent wrappers should not be empty');
        
        // Verify wrapper data
        for(FlexContractConsolidation.ContractSubscriptionParentWrapper wrapper : parentWrappers) {
            System.assertNotEquals(null, wrapper.productId, 'Product ID should not be null');
            System.assertNotEquals(null, wrapper.totalQuantity, 'Total quantity should not be null');
            System.assertNotEquals(null, wrapper.subscriptionWrappers, 'Subscription wrappers should not be null');
        }
        
        Test.stopTest();
    }


    @isTest
    private static void testIsMatchingHierarchyForPnPToggleOff() {
        // Arrange
        Product2 prod1 = [SELECT Id, Flex_SKU_Hierarchy__c, Flex_PLTFM_Hierarchy__c, Flex_HW_Hierarchy__c 
                          FROM Product2 WHERE Name = 'WiFi Hotspot - 2GB Total Data' LIMIT 1];
        Product2 prod2 = [SELECT Id, Flex_SKU_Hierarchy__c, Flex_PLTFM_Hierarchy__c, Flex_HW_Hierarchy__c 
                          FROM Product2 WHERE Name = 'WiFi Hotspot - 1GB Total Data' LIMIT 1];
        prod1.Flex_SKU_Hierarchy__c = 2;
        prod1.Flex_PLTFM_Hierarchy__c = 2;
        prod1.Flex_HW_Hierarchy__c = 2;
        update prod1;
        
        // Act
        Boolean matchResult = FlexContractConsolidation.isMatchingHierarchyForPnPToggleOff(prod1, prod2);
        Boolean nullProdResult = FlexContractConsolidation.isMatchingHierarchyForPnPToggleOff(null, prod2);
        Boolean nullSubProdResult = FlexContractConsolidation.isMatchingHierarchyForPnPToggleOff(prod1, null);

        // Assert
        System.assertEquals(true, matchResult, 'Expected hierarchies to match for toggle OFF');
        System.assertEquals(false, nullProdResult, 'Expected false when main product is null');
        System.assertEquals(false, nullSubProdResult, 'Expected false when sub product is null');
    }

    @isTest
    private static void testIsMatchingHierarchyForPnPToggleOn() {
        // Arrange
        Product2 prod1 = [SELECT Id, Flex_SKU_Hierarchy__c, Flex_PLTFM_Hierarchy__c, Flex_HW_Hierarchy__c 
                          FROM Product2 WHERE Name = 'WiFi Hotspot - 2GB Total Data' LIMIT 1];
        Product2 prod2 = [SELECT Id, Flex_SKU_Hierarchy__c, Flex_PLTFM_Hierarchy__c, Flex_HW_Hierarchy__c 
                          FROM Product2 WHERE Name = 'WiFi Hotspot - 1GB Total Data' LIMIT 1];

        // Set up hierarchy values for prod1 (available product)
        prod1.Flex_SKU_Hierarchy__c = 3;  // Higher than prod2
        prod1.Flex_PLTFM_Hierarchy__c = 3; // Higher than prod2
        prod1.Flex_HW_Hierarchy__c = 2;    // Equal to prod2
        update prod1;

        // Set up hierarchy values for prod2 (subscription product)
        prod2.Flex_SKU_Hierarchy__c = 2;
        prod2.Flex_PLTFM_Hierarchy__c = 2;
        prod2.Flex_HW_Hierarchy__c = 2;
        update prod2;

        // Act
        Boolean matchResult = FlexContractConsolidation.isMatchingHierarchyForPnPToggleOn(prod1, prod2);

        // Null checks
        Boolean nullProdResult = FlexContractConsolidation.isMatchingHierarchyForPnPToggleOn(null, prod2);
        Boolean nullSubProdResult = FlexContractConsolidation.isMatchingHierarchyForPnPToggleOn(prod1, null);

        // Assert
        System.assertEquals(true, matchResult, 'Expected match when prod1 PLTFM > subProd PLTFM');
        System.assertEquals(false, nullProdResult, 'Expected false when main product is null');
        System.assertEquals(false, nullSubProdResult, 'Expected false when sub product is null');
    }
    
    @IsTest
    static void testAddProductIfNotExists() {
        // Fetch the test products in a predictable order
        List<Product2> products = [
            SELECT Id, Name FROM Product2
            WHERE Name IN ('WiFi Hotspot - 1GB Total Data', 'WiFi Hotspot - 2GB Total Data')
            ORDER BY Name ASC
        ];
    
        Product2 prod1 = products[0]; // 1GB
        Product2 prod2 = products[1]; // 2GB
    
        Map<Id, List<Product2>> productFamilyMap = new Map<Id, List<Product2>>();
    
        Test.startTest();
    
        // Add products in various combinations
        FlexContractConsolidation.addProductIfNotExists(productFamilyMap, prod1.Id, prod1);
        FlexContractConsolidation.addProductIfNotExists(productFamilyMap, prod1.Id, prod1); // duplicate, should not add
        FlexContractConsolidation.addProductIfNotExists(productFamilyMap, prod1.Id, prod2); // different product, same key
        FlexContractConsolidation.addProductIfNotExists(productFamilyMap, prod2.Id, prod2); // different key
    
        Test.stopTest();
    
        // Verify map has 2 keys
        System.assertEquals(2, productFamilyMap.size(), 'Map should contain two entries');
    
        // Verify product counts under each key
        System.assertEquals(2, productFamilyMap.get(prod1.Id).size(), 'prod1.Id key should contain two unique products');
        System.assertEquals(1, productFamilyMap.get(prod2.Id).size(), 'prod2.Id key should contain one product');
    
        // Optional: Spot check one ID match to ensure it's prod2
        System.assertEquals(prod2.Id, productFamilyMap.get(prod2.Id)[0].Id, 'Product under prod2.Id should be prod2');
    }

    // Helper methods
    @isTest
    static void testPnPToggleOff() {
        // Get test contract
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Revenue Opportunity1-test' LIMIT 1];
        Contract testContract = [SELECT Id, AccountId FROM Contract WHERE SBQQ__Opportunity__c = :opp.Id LIMIT 1];
        
        // Get test pricebook
        Id standardPbId = Test.getStandardPricebookId();
        
        Test.startTest();
        // Test PnP toggle OFF case
        List<FlexContractConsolidation.ContractSubscriptionParentWrapper> results = 
            FlexContractConsolidation.getSubscriptionsByProductAndAddress(
                new List<Id>{testContract.Id}, 
                standardPbId,
                true, // accountPilotCustomer = true
                false, // togglePnP = false
                null  // productIdsFromPnpOne = null
            );
        
        Test.stopTest();
        
        // Basic validation
        System.assertNotEquals(0, results.size(), 'Should return at least one result');
        
        // Process results
        for(FlexContractConsolidation.ContractSubscriptionParentWrapper wrapper : results) {
            validateWrapper(wrapper);
        }
    }
    
    private static void validateWrapper(FlexContractConsolidation.ContractSubscriptionParentWrapper wrapper) {
        // Validate basic fields
        System.assertNotEquals(null, wrapper.productId, 'Product ID should not be null');
        System.assertNotEquals(null, wrapper.totalQuantity, 'Total quantity should not be null');
        System.assertNotEquals(null, wrapper.subscriptionWrappers, 'Subscription wrappers should not be null');
        
        // Skip hierarchy validation if no available products
        if(wrapper.availableProducts == null || wrapper.availableProducts.isEmpty() || 
           wrapper.subscriptionWrappers == null || wrapper.subscriptionWrappers.isEmpty()) {
            return;
        }
        
        // Get subscription product
        Product2 subscriptionProduct = [SELECT Flex_SKU_Hierarchy__c, Flex_PLTFM_Hierarchy__c, Flex_HW_Hierarchy__c 
                                     FROM Product2 
                                     WHERE Id = :wrapper.subscriptionWrappers[0].productId];
        
        // Validate hierarchy rules
        for(Product2 prod : wrapper.availableProducts) {
            validateHierarchyRules(prod, subscriptionProduct);
        }
    }
    
    private static void validateHierarchyRules(Product2 prod, Product2 subscriptionProduct) {
        // For toggle OFF, SKU hierarchy should be >= and PLTFM/HW should be equal
        System.assert(prod.Flex_SKU_Hierarchy__c >= subscriptionProduct.Flex_SKU_Hierarchy__c,
            'For toggle OFF, SKU hierarchy should be >= subscription product');
        System.assertEquals(subscriptionProduct.Flex_PLTFM_Hierarchy__c, prod.Flex_PLTFM_Hierarchy__c,
            'For toggle OFF, PLTFM hierarchy should be equal');
        System.assertEquals(subscriptionProduct.Flex_HW_Hierarchy__c, prod.Flex_HW_Hierarchy__c,
            'For toggle OFF, HW hierarchy should be equal');
    }

    @isTest
    static void testPnPToggleOn() {
        // Get the test contract - using the contract created in setup
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Revenue Opportunity1-test' LIMIT 1];
        Contract testContract = [SELECT Id, AccountId FROM Contract WHERE SBQQ__Opportunity__c = :opp.Id LIMIT 1];
        
        // Create a new subscription for the test
        SBQQ__Subscription__c testSubscription = new SBQQ__Subscription__c(
            SBQQ__Quantity__c = 1,
            SBQQ__CustomerPrice__c = 100,
            SBQQ__Contract__c = testContract.Id,
            SBQQ__Account__c = testContract.AccountId,
            SBQQ__Product__c = [SELECT Id, Family FROM Product2 WHERE Name = 'sub-product-test-2' LIMIT 1].Id
        );
        insert testSubscription;
        
        // Get the subscription product
        Product2 subscriptionProduct = [SELECT Id, Name, Flex_SKU_Hierarchy__c, Flex_PLTFM_Hierarchy__c, Flex_HW_Hierarchy__c, Family 
                                     FROM Product2 WHERE Id = :testSubscription.SBQQ__Product__c];
        
        // Get available products
        List<Product2> availableProducts = [SELECT Id, Name, Flex_SKU_Hierarchy__c, Flex_PLTFM_Hierarchy__c, Flex_HW_Hierarchy__c, Family 
                                          FROM Product2 
                                          WHERE Id != :subscriptionProduct.Id
                                          AND Family = :subscriptionProduct.Family
                                          AND Product_Type__c = 'License'
                                          AND License_Type__c = 'Pro'];
        
        
        // Get test pricebook
        Id standardPbId = Test.getStandardPricebookId();
        
        // Test PnP toggle ON
        Test.startTest();
        List<FlexContractConsolidation.ContractSubscriptionParentWrapper> results = 
            FlexContractConsolidation.getSubscriptionsByProductAndAddress(
                new List<Id>{testContract.Id}, 
                standardPbId,
                true, // accountPilotCustomer = true
                true, // togglePnP = true
                null // productIdsFromPnpOne = null
            );
        Test.stopTest();
        
        // Verify results
        System.assert(!results.isEmpty(), 'Results should not be empty');
        
        // Find the subscription in results
        FlexContractConsolidation.ContractSubscriptionParentWrapper subscriptionResult = null;
        for(FlexContractConsolidation.ContractSubscriptionParentWrapper result : results) {
            if(result.subscriptionWrappers != null && !result.subscriptionWrappers.isEmpty() && 
               result.subscriptionWrappers[0].productId == testSubscription.SBQQ__Product__c) {
                subscriptionResult = result;
                break;
            }
        }
        
        System.assert(subscriptionResult != null, 'Should find the test subscription in results');
        System.assert(!subscriptionResult.availableProducts.isEmpty(), 'Should have available products');
        
        // Verify hierarchy values
        Product2 availableProduct = subscriptionResult.availableProducts[0];
        System.assert(availableProduct.Flex_PLTFM_Hierarchy__c > subscriptionProduct.Flex_PLTFM_Hierarchy__c, 
            'Assertion Failed: For toggle ON, PLTFM hierarchy should be > subscription product. ' +
            'Subscription PLTFM: ' + subscriptionProduct.Flex_PLTFM_Hierarchy__c + 
            ', Available Product PLTFM: ' + availableProduct.Flex_PLTFM_Hierarchy__c);
    }


    @isTest
    static void testInvalidSubProductAndProductFamilyMap() {
        // Create test products with invalid data
        Product2 invalidProduct = new Product2(
            Name = 'Invalid Product',
            Family = null,
            Product_Type__c = null,
            License_Type__c = null
        );
        insert invalidProduct;

        // Create a valid product for comparison
        Product2 validProduct = new Product2(
            Name = 'Valid Product',
            Family = 'Hardware',
            Product_Type__c = 'License',
            License_Type__c = 'Pro'
        );
        insert validProduct;

        // Get test contract
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];

        // Create subscription with invalid product
        SBQQ__Subscription__c invalidSub = new SBQQ__Subscription__c(
            SBQQ__Contract__c = testContract.Id,
            SBQQ__Product__c = invalidProduct.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__CustomerPrice__c = 100
        );
        insert invalidSub;

        // Get test pricebook
        Id standardPbId = Test.getStandardPricebookId();

        Test.startTest();
        List<FlexContractConsolidation.ContractSubscriptionParentWrapper> results = 
            FlexContractConsolidation.getSubscriptionsByProductAndAddress(
                new List<Id>{testContract.Id}, 
                standardPbId,
                false,
                false,
                null
            );
        Test.stopTest();

        // Verify results
        System.assert(!results.isEmpty(), 'Results should not be empty');

        // Find the invalid product subscription in results
        FlexContractConsolidation.ContractSubscriptionParentWrapper invalidResult = null;
        for(FlexContractConsolidation.ContractSubscriptionParentWrapper result : results) {
            if(result.productId == invalidProduct.Id) {
                invalidResult = result;
                break;
            }
        }

        // Verify that we found the invalid product subscription
        System.assert(invalidResult != null, 'Should find the invalid product subscription in results');
        System.assertEquals(1, invalidResult.totalQuantity, 'Total quantity should be 1 for invalid product');
        System.assert(!invalidResult.subscriptionWrappers.isEmpty(), 'Should have subscription wrappers');
    }

}
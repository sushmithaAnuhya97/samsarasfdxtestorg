@isTest
public with sharing class FlexContractOpportunityControllerTest {
    @testSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Billing St',
            BillingCity = 'NY',
            BillingState = 'Hawaii',
            BillingPostalCode = '12345',
            BillingCountry = 'United States',
            ShippingStreet = '456 Shipping Ave',
            ShippingCity = 'NY',
            ShippingState = 'Hawaii',
            ShippingPostalCode = '67890',
            ShippingCountry = 'United States',
            Organization_Size__c='1 - 99'
        );
        insert testAccount;
        
        // Create test opportunities
        Opportunity opp1 = new Opportunity(
            Name = 'Test Opportunity 1',
            Free_Trial_Purchase__c  = 'Partial Buy',
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            AccountId = testAccount.Id,
            PO_Number__c = '1234',
            Payment_Terms_Opportunity_only_exception__c = true,
            Payment_Type_Opportunity_only_Exception__c = true,
            Samsara_insolvency__c = 'approved',
            Custom_Schedule__c = true
        );
        // Create a test product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            isActive = true
        );
        insert testProduct;

        Id standardPriceBookId = Test.getStandardPricebookId();
        
        // Create a price book entry for the product in the standard price book
        PricebookEntry standardPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = standardPriceBookId,
            UnitPrice = 3000000.00,
            UseStandardPrice = false,
            IsActive = true
        );
        insert standardPricebookEntry;
        
        Pricebook2 customPriceBook = new Pricebook2(
            Name = 'Samsara FY22',
            IsActive = true
        );
        insert customPriceBook;
        
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = customPriceBook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert testPricebookEntry;
        
        Opportunity opp2 = new Opportunity(
            Name = 'Test Opportunity 2',
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            AccountId = testAccount.Id,
            Free_Trial_Purchase__c  = 'Partial Buy',
            Payment_Terms_Opportunity_only_exception__c = false,
            PO_Number__c = '1134',
            License_Term__c =36
        );
         SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp1.Id,
            SBQQ__Primary__c = true,
            SBQQ__Status__c = 'Approved',
            SBQQ__SubscriptionTerm__c =10,
            Estimated_Annual_Payment__c = 24,
            Custom_License_Term__c = 2,
            Selected_Payment_Type__c='Direct Monthly'
        );
        insert testQuote;
        
        insert new List<Opportunity>{opp1, opp2};
        
        // Create test contract
        Contract testContract = new Contract(
            AccountId = testAccount.Id,
            SBQQ__Opportunity__c = opp1.Id,
            StartDate = System.today(),
            EndDate   = System.today().addDays(30),
            Flex_Replacement_Opportunity__c = opp2.Id,
            ContractTerm = 12,
            Status = 'Draft'
        );
        
        insert testContract;
        
        Opportunity amendedOpp = new Opportunity(
            Name = 'Amended Opportunity',
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            AccountId = testAccount.Id,
            SBQQ__AmendedContract__c = testContract.Id,
            Free_Trial_Purchase__c  = 'Partial Buy',
            Payment_Terms_Opportunity_only_exception__c = true,
            PO_Number__c = '1134',
            License_Term__c =36
        );
        insert amendedOpp;
    }
    
    @isTest
    static void testGetOpportunitiesWithExceptions() {
        // Retrieve the test contract
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        
        // Call the method
        List<FlexContractOpportunityController.OpportunityWrapper> results = 
        FlexContractOpportunityController.getOpportunitiesWithExceptions(new List<Id>{testContract.Id});
        
        // Assert the results
        System.assertEquals(2, results.size(), 'There should be two opportunity with exceptions');
    }
    
    @isTest
    static void testFetchOpportunitiesForUpgradedOpportunity() {
        // Retrieve the test opportunity
        Opportunity testOpportunity = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity 2' LIMIT 1];
        
        // Call the method
        List<FlexContractOpportunityController.OpportunityWrapper> results = 
        FlexContractOpportunityController.fetchOpportunitiesForUpgradedOpportunity(testOpportunity.Id);
        
        // Assert the results
         System.assertEquals(2, results.size(), 'There should be two opportunity with exceptions');
        
    }
    @isTest
    static void testGetContractDetails() {
        // Retrieve the test contract
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        
        // Call the method
        List<Contract> results = FlexSelectedContractDetails.getContractDetails(new List<String>{testContract.Id});
        
        // Assert the results
        System.assertEquals(1, results.size(), 'There should be one contract detail retrieved');
        System.assertEquals(testContract.Id, results[0].Id, 'The contract ID should match');
        
        try {
            FlexSelectedContractDetails.getContractDetails(null);
            System.assert(false, 'An exception should have been thrown for null input');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage(),'Exception message should be "Script-thrown exception"');
        }
    }
    @isTest
    static void testGetContractInfo() {
        // Retrieve the test contract
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        
        // Call the method
        List<Contract> results = FlexUpgradeOpportunityInfo.getContractInfo(new List<String>{testContract.Id});
        
        // Assert the results
        System.assertEquals(1, results.size(), 'There should be one contract info retrieved');
        System.assertEquals(testContract.Id, results[0].Id, 'The contract ID should match');
        
        try {
            FlexUpgradeOpportunityInfo.getContractInfo(null);
            System.assert(false, 'An exception should have been thrown for null input');
        } catch (AuraHandledException e) {
          System.assertEquals('Script-thrown exception', e.getMessage(),'Exception message should be "Script-thrown exception"');  
        }
    }
    
}
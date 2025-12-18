/**
 * @description       : Test class for ShippingHandlingValueUpdateBatch
 * @last modified on  : 01-15-2025
 * @last modified by  : shivam.goyal
 **/
@isTest
public class ShippingHandlingValueUpdateBatchTest {
    
    @TestSetup
    static void setupTestData() {
        BuyoutQuoteLineQueueable.byPassTriggers();
        
        Account testAccount = TestFactory.initializeAccount('ShippingHandlingValueUpdateBatch');
        insert testAccount;
        
        Opportunity testOpp = TestFactory.initializeOpportunity('ShippingHandlingValueUpdateBatch');
        testOpp.AccountId = testAccount.Id;
        testOpp.Type = 'Revenue Opportunity';
        insert testOpp;
        
        List<SBQQ__Quote__c> testQuotes = new List<SBQQ__Quote__c>();
        
        for (Integer i = 0; i < 5; i++) {
            testQuotes.add(new SBQQ__Quote__c(
                SBQQ__Account__c = testAccount.Id,
                SBQQ__Opportunity2__c = testOpp.Id,
                Shipping_and_Handling_Manual__c = 100.00 + (i * 10),
                Shipping_and_Handling_Value__c = null,
                Shipping_Country__c = 'United States',
                of_HW_Products__c = 10,
                of_Accessories__c = 10
            ));
        }
        
        insert testQuotes;
        
        // Update Shipping_and_Handling_Value__c to simulate the formula calculation
        // Since quotes created after 2025-02-10 return Shipping_and_Handling_Value__c from the formula
        List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();
        for (SBQQ__Quote__c quote : testQuotes) {
            quotesToUpdate.add(new SBQQ__Quote__c(
                Id = quote.Id,
                Shipping_and_Handling_Value__c = quote.Shipping_and_Handling_Manual__c
            ));
        }
        update quotesToUpdate;
        
        BuyoutQuoteLineQueueable.clearByPassTrigger();
    }
    
    @isTest
    static void testBatchProcessing() {
        Test.startTest();
        
        List<SBQQ__Quote__c> testQuotes = [SELECT Id, Shipping_and_Handling__c, Shipping_and_Handling_Value__c 
                                          FROM SBQQ__Quote__c 
                                          WHERE SBQQ__Account__r.Name LIKE 'ShippingHandlingValueUpdateBatch%'];
        
        Set<Id> targetQuoteIds = new Set<Id>();
        for (Integer i = 0; i < Math.min(3, testQuotes.size()); i++) {
            targetQuoteIds.add(testQuotes[i].Id);
        }
        
        ShippingHandlingValueUpdateBatch batch1 = new ShippingHandlingValueUpdateBatch(targetQuoteIds);
        ShippingHandlingValueUpdateBatch batch2 = new ShippingHandlingValueUpdateBatch();
        
        // Test the logError method directly
        batch1.logError('testMethod', 'Test error message for coverage');
        
        Database.executebatch(batch1, 200);
        
        Test.stopTest();
    }
    
}
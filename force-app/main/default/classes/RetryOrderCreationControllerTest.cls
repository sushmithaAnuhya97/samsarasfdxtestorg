@istest
public class RetryOrderCreationControllerTest {
    
     @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(Name = 'Testers 1 Inc',
                                         BillingStreet = '26 Napier Street',
                                         BillingCity = 'London',
                                         BillingPostalCode  = '1030',
                                         BillingCountry = 'United Kingdom',
                                         Billing_Email__c  = 'qdasdas@gmail.com',
                                         Organization_Size__c = '100 - 499',
                                         Industry = 'Other');
        insert testAccount;
        
        // Create test opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Ready To Ship',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;
        
        // Create test quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = testOpp.Id,
            SBQQ__Ordered__c = true,
            SBQQ__Primary__C = true
        );
        insert testQuote;
    }
    
    @isTest
    static void testQuoteOrderedQueueable_WithOrder() {
        // Get test quote
        SBQQ__Quote__c testQuote = [SELECT Id, SBQQ__Account__c, SBQQ__Opportunity2__c FROM SBQQ__Quote__c LIMIT 1];
        
        // Create test order
        Order testOrder = new Order(
            SBQQ__Quote__c = testQuote.Id,
            AccountId = testQuote.SBQQ__Account__c,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            OpportunityId = testQuote.SBQQ__Opportunity2__c
        );
        insert testOrder;
        Test.startTest();
        RetryOrderCreationController.makeCallout(new List<Id>{testQuote.SBQQ__Opportunity2__c});
        Test.stopTest();
    }
    
    @isTest
    static void testQuoteOrderedQueueable_WithoutOrder() {
        // Get test quote
        SBQQ__Quote__c testQuote = [SELECT Id, SBQQ__Account__c, SBQQ__Opportunity2__c FROM SBQQ__Quote__c LIMIT 1];
        
        Test.startTest();
        RetryOrderCreationController.makeCallout(new List<Id>{testQuote.SBQQ__Opportunity2__c});
        Test.stopTest();
    }
}
@isTest
private class QuoteExtControllerTests {
    
    testMethod static void testSubmit() {
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Selected_Payment_Type__c='Upfront Payments');
        insert quote;
        
        Test.startTest();
        QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(quote));
        con.onSubmit();
        quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        Test.stopTest();
    }
    
    testMethod static void testSubmitException() {
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        insert quote;
        
        Test.startTest();
        QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(quote));
        con.onSubmit();
        quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        Test.stopTest();
    }    
    
    testMethod static void testRecall() {
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Selected_Payment_Type__c='Upfront Payments');
        insert quote;
        
        Test.startTest();
        QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(quote));
        con.onRecall();
        quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        Test.stopTest();
    }
    
    testMethod static void testCancel() {
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Selected_Payment_Type__c='Upfront Payments');
        insert quote;
        
        Test.startTest();
        QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(quote));
        con.onCancel();
        Test.stopTest();
    }
}
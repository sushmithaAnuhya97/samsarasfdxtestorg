@isTest
private class TestGenerateNewQuote {
    
    @testSetup static void setupTestData(){
        
        

        //Create Test Account
        Account account = new Account(
            Name = 'Testing Account',
            Organization_Size__c = '1 - 99',
            Industry = 'Manufacturing',
            BillingState = 'Alabama',
            ShippingState = 'Alabama',
            BillingCountry = 'United States',
            ShippingCountry = 'United States'
        );        
        insert account;
        
        //Create Contact
          Contact frodo = new Contact(
              FirstName = 'Frodo',
              LastName = 'Baggins',
              AccountId = account.Id
          );
        insert frodo;
        
        //Create Test Opportunity
        Opportunity opp = new Opportunity(
            name = 'Testing Opp',
            StageName = 'Incubate',
            closeDate = Date.today(),
            AccountId = account.Id,
            ForecastCategoryName = 'Omitted'
        );
        insert opp;
 
        //OpportunityContactRole ringBearerRole = new OpportunityContactRole(
        //    ContactId = frodo.Id,
        //    OpportunityId = opp.Id,
         //   Role = 'Decision Maker',
        //    IsPrimary = true
       // );
       // insert ringBearerRole;        
    }
    
    @isTest
    private static void testGenerateNewQuote(){
        
        List<Opportunity> opps = [SELECT Id, AccountID FROM Opportunity];
        System.debug('Opps: ' + opps);
        System.assertEquals(1, opps.size());
        
        Test.startTest();
        PageReference pageRef = Page.GenerateNewQuote;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id',opps[0].id);
        ApexPages.StandardController sc = new ApexPages.standardController(opps[0]);
        GenerateNewQuote genNQ = new GenerateNewQuote(sc);
        genNQ.genQuote();
        
        List<SBQQ__Quote__c> quotes = [SELECT SBQQ__Opportunity2__c, SBQQ__Account__c, SBQQ__Status__c, 
            SBQQ__Type__c, SBQQ__StartDate__c, SBQQ__SubscriptionTerm__c, SBQQ__Primary__c FROM SBQQ__Quote__c];
        System.debug('Quotes: ' + quotes);
        
        System.assertEquals(1, quotes.size());
        System.assertEquals(opps[0].Id, quotes[0].SBQQ__Opportunity2__c);
        //System.assertEquals(Date.today(), quotes[0].SBQQ__StartDate__c);
        System.assertEquals(36, quotes[0].SBQQ__SubscriptionTerm__c);
        //System.assertEquals(true, quotes[0].SBQQ__Primary__c);
        Test.stopTest();

        
    }
}
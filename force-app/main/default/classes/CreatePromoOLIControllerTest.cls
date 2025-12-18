//test class for CreatePromoOLIController
@IsTest
private class CreatePromoOLIControllerTest {

    @TestSetup
    static void setupData() {
        // Create Pricebook + Products
        Id stdPbId = Test.getStandardPricebookId();
        Pricebook2 pb = new Pricebook2(Name = 'Test PB', IsActive = true);
        insert pb;

        Product2 prod = new Product2(Name = 'Promo Product', IsActive = true);
        insert prod;

        insert new PricebookEntry(
            Pricebook2Id = stdPbId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert new PricebookEntry(
            Pricebook2Id = pb.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );

        Account acc = new Account(
            Name = 'Testers 1 Inc',
            BillingStreet = '26 Napier Street',
            BillingCity = 'London',
            BillingPostalCode  = '1030',
            BillingCountry = 'United Kingdom',
            Account_C_R_In_Progress__c= true,
            Billing_Email__c  = 'qdasdas@gmail.com',
            Organization_Size__c = '100 - 499',
            Industry = 'Other'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(5),
            Pricebook2Id = pb.Id,
           // Segment_Sales_Role__c = 'Mid-Market', // must match Segment
            Purchase_Type__c = 'First Purchase',  // must match DealType
            //First_Purchase__c = true,             // to allow condition pass
            Shipping_Country__c = 'United States' // must match Country
        );
        insert opp;
    }

    @IsTest
    static void testWithValidOppId() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];

        Test.startTest();
        String result = CreatePromoOLIController.createOLIPromobutton(opp.Id);
        Test.stopTest();

        System.debug('Result: ' + result);
        System.assertNotEquals(null, result, 'Expected a non-null result string');
    }

    @IsTest
    static void testWithNullOppId() {
        Test.startTest();
        String result = CreatePromoOLIController.createOLIPromobutton(null);
        Test.stopTest();
      
    }


}
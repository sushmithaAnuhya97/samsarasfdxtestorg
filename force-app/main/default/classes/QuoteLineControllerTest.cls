@IsTest
public class QuoteLineControllerTest {
    
    @TestSetup
    static void setupTestData() {
        TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        
        Account acc = new Account(
            Name = 'test Account1',BillingStreet = '26 Napier Street',BillingCity = 'London',BillingPostalCode = '1030',BillingCountry = 'United Kingdom',
            Billing_Email__c = 'test@example.com',Organization_Size__c = '100 - 499',Payment_Terms__c = 'Net 45',Industry = 'Other');
        insert acc;

        Opportunity opp = new Opportunity(Name = 'test oppoty1', StageName = 'Qualification',CloseDate = Date.today());
        opp.AccountId = acc.Id;
        insert opp;

        SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp.Id, SBQQ__Primary__c = true);
        insert quote;

        Id pricebookId = Test.getStandardPricebookId();
        
        Product2 vgLicense = new Product2(Name = 'LIC-VG55-36MO', ProductCode = 'LIC-VG55-36MO', Family = 'Test');
        insert vgLicense;
        
        PricebookEntry vgLicensePB = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = vgLicense.Id, UnitPrice = 10000, IsActive = true);
        insert vgLicensePB;
        
        Product2 vgProduct = [SELECT id FROM Product2 WHERE Name = 'LIC-VG55-36MO' LIMIT 1];
        PricebookEntry pricebookEntry = [SELECT id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id = :vgProduct.Id LIMIT 1]; 
        SBQQ__QuoteLine__c quoteLineOne = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__PricebookEntryId__c = pricebookEntry.Id, 
                                                                 SBQQ__Quantity__c = 5, SBQQ__Product__c = vgProduct.Id,SBQQ__NetPrice__c = 4000);
        insert quoteLineOne;
    }
    
    @IsTest
    static void testGetQuoteLinesByQuoteIdSuccess() {
        TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        
        Test.startTest();
        QuoteLineController.QuoteLineResponse response = QuoteLineController.getQuoteLinesByQuoteId(quote.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testGetQuoteLinesByQuoteIdEmptyQuoteId() {
        TriggerHandler.bypass('SBQQQuoteLineTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('GS_AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandlerContext');
        TriggerHandler.bypass('GS_OpportunityTriggerHandler');
        
        Test.startTest();
        try {
            QuoteLineController.getQuoteLinesByQuoteId('');
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }

}
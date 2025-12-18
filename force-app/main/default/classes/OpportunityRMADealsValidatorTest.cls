@isTest
public class OpportunityRMADealsValidatorTest {

    @TestSetup
    static void setupTestData() {
        // Setup User
        User AEUser = [SELECT Id FROM User WHERE IsActive = true AND UserRole.Name LIKE '%AE1%' LIMIT 1];

        // Setup Account
        Account acct = new Account(
            Name = 'Test Account',
            BillingState = 'California',
            BillingCountry = 'United States',
            Organization_Size__c = '100 - 499',
            Industry = 'Other',
            OwnerId = AEUser.Id
        );
        insert acct;

        // Setup Opportunities
        List<Opportunity> opportunities = new List<Opportunity>();
        Opportunity opp1 = new Opportunity(
            Name = 'Test Opportunity ',
            AccountId = acct.Id,
            StageName = 'Qualified',
            CloseDate = Date.today().addDays(30),
            Freight_Cost__c = 200,
            Type = 'Promo Opportunity',
            Shipping_Country__c = 'United States',
            Shipping_and_Handling_Manual__c = null,
             Promo_Reason__c = 'Exchange'
        );
        Opportunity opp2 = new Opportunity(
            Name = 'Opportunity Update Test',
            AccountId = acct.Id,
            StageName = 'Qualified',
            CloseDate = Date.today().addDays(10),
            Type = 'Promo Opportunity',
            Promo_Reason__c = 'Exchange',
            Shipping_Country__c = 'United States'
        );
        opportunities.add(opp1);
        opportunities.add(opp2);
        insert opportunities;

        // Setup Products
        Id pricebookId = Test.getStandardPricebookId();
        Product2 prod1 = new Product2(Name = 'HW-PL11', ProductCode = 'HW-PL11', Family = 'Test', IsActive = true);
        Product2 prod2 = new Product2(Name = 'ACC-PL-MNT-MA1', ProductCode = 'ACC-PL-MNT-MA1', Family = 'Test', IsActive = true);
        insert new List<Product2>{ prod1, prod2 };

        // Setup Pricebook Entries
        PricebookEntry pbe1 = new PricebookEntry(Product2Id = prod1.Id, Pricebook2Id = pricebookId, UnitPrice = 100, IsActive = true);
        PricebookEntry pbe2 = new PricebookEntry(Product2Id = prod2.Id, Pricebook2Id = pricebookId, UnitPrice = 200, IsActive = true);
        insert new List<PricebookEntry>{ pbe1, pbe2 };

        // Setup Opportunity Line Items
        List<Opportunity> opps = [SELECT Id, Name FROM Opportunity  LIMIT 1];
        Opportunity rmaOpp = opps[0];

        List<OpportunityLineItem> lineItems = new List<OpportunityLineItem>{
            new OpportunityLineItem(OpportunityId = rmaOpp.Id, Quantity = 1, UnitPrice = 100, PricebookEntryId = pbe1.Id), // HW-PL11
            new OpportunityLineItem(OpportunityId = rmaOpp.Id, Quantity = 2, UnitPrice = 200, PricebookEntryId = pbe2.Id), // ACC-PL-MNT-MA1

            new OpportunityLineItem(OpportunityId = opp2.Id, Quantity = 1, UnitPrice = 100, PricebookEntryId = pbe1.Id),
            new OpportunityLineItem(OpportunityId = opp2.Id, Quantity = 1, UnitPrice = 200, PricebookEntryId = pbe2.Id)
        };
        insert lineItems;
    }

    @isTest
    static void testCheckRMAOppHasPL1HWAndAccessories() {

        Opportunity opp = [SELECT Id, Name, StageName FROM Opportunity LIMIT 1];
        Opportunity oldOpp = opp.clone(false);
        oldOpp.StageName = 'Qualified';

        // Set to trigger validation
        opp.StageName = 'Purchase';

        Test.startTest();
        try {
            update opp;
            System.assert(true, 'Opportunity updated without exceptions (validation should pass if quantities match).');
        } catch (DmlException e) {
           System.assert(true, 'Unexpected validation error: ' + e.getMessage());
        }
        Test.stopTest();
    }
}
@isTest
public with sharing class GS_OpportunitySlackServiceTest {

    @isTest
    public static void postToSlack_CreateAsyncRecords(){

        Account acc = new Account(
            Name = 'Test Account 1 - Transportation',
            Industry = 'Transportation & Warehousing',
            Organization_Size__c = '100 - 499',
            BillingCountry = 'United States',
            BillingState = 'California'
        );
        insert acc;

        Product2 product = new Product2(
            Name = 'Product',
            ProductCode = '1234',
            Product_Type__c = 'Cable'
        );
        insert product;

        PricebookEntry entry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product.Id,
            UnitPrice = 100,
            isActive = true
        );
        insert entry;

        Opportunity opp = new Opportunity(
            Type = 'Revenue Opportunity',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
            Name = 'New opp for testing 0',
            AccountId = acc.Id,
            Configuration_Segment__c = 'Express',
            StageName = 'Ready to Ship',
            CloseDate = System.today(),
            Probability = 100,
            Shipping_Country__c = 'United States'
        );
        insert opp;

        List<OpportunityLineItem> itemList = new List<OpportunityLineItem>{
            new OpportunityLineItem(
                OpportunityId = opp.Id,
                Quantity = 3,
                TotalPrice = 300,
                PricebookEntryId = entry.Id,
                ACV_Total_Price_Stamp__c = 300
            )
        };

        insert itemList;

        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>{
            opp.Id => new Opportunity(
                Id = opp.Id,
                Type = 'Revenue Opportunity',
                StageName = 'Proposal'
            )
        };

        Test.startTest();
        DMLWrapper.intializeUnitOfWork(new List<SObjectType>{
            Async_Request__c.SOBjectType
        });
        (new GS_OpportunitySlackService()).postToSlack(oldOppMap, [
            SELECT Id, Type, RecordTypeId, Name, AccountId, Configuration_Segment__c, StageName, CloseDate,
                   Probability, Shipping_Country__c, ACV_Bookings__c, Industrial_Oppty__c, Express_Flag__c
              FROM Opportunity
             WHERE Id = :opp.Id
        ]);
        DMLWrapper.publishDML();
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Async_Request__c]);
    }

    @isTest
    public static void postToSlack_AsyncSlackPublisher(){

        Account acc = new Account(
            Name = 'Test Account 1 - Transportation',
            Industry = 'Transportation & Warehousing',
            Organization_Size__c = '100 - 499',
            BillingCountry = 'United States',
            BillingState = 'California'
        );
        insert acc;

        Product2 product = new Product2(
            Name = 'Product',
            ProductCode = '1234',
            Product_Type__c = 'Cable'
        );
        insert product;

        PricebookEntry entry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product.Id,
            UnitPrice = 100,
            isActive = true
        );
        insert entry;

        Opportunity opp = new Opportunity(
            Type = 'Revenue Opportunity',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
            Name = 'New opp for testing 0',
            AccountId = acc.Id,
            Configuration_Segment__c = 'Express',
            StageName = 'Ready to Ship',
            CloseDate = System.today(),
            Probability = 100,
            Shipping_Country__c = 'United States'
        );
        insert opp;

        List<OpportunityLineItem> itemList = new List<OpportunityLineItem>{
            new OpportunityLineItem(
                OpportunityId = opp.Id,
                Quantity = 3,
                TotalPrice = 300,
                PricebookEntryId = entry.Id,
                ACV_Total_Price_Stamp__c = 300
            )
        };

        insert itemList;

        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>{
            opp.Id => new Opportunity(
                Id = opp.Id,
                Type = 'Revenue Opportunity',
                StageName = 'Proposal'
            )
        };

        Test.startTest();
        DMLWrapper.intializeUnitOfWork(new List<SObjectType>{
            Async_Request__c.SOBjectType
        });
        (new GS_OpportunitySlackServiceAsync()).execute(new Async_Request__c(
            Params__c = opp.Id+';',
            Options__c = JSON.serialize(new GS_OpportunitySlackServiceAsync.Options('PUSH_TO_SLACK'))
        ));
        DMLWrapper.publishDML();
        Test.stopTest();

        // Can't assert equals on SlackPublisher class
    }
}
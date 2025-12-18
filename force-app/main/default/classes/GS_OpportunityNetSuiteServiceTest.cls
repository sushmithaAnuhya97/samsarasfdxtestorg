@isTest
public with sharing class GS_OpportunityNetSuiteServiceTest {
    
    @isTest
    public static void pushToNetSuite_Sync(){
        DMLWrapper.intializeUnitOfWork(new List<SObjectType>{
            Opportunity.SOBjectType,
            Async_Request__c.SOBjectType
        });

        Id fakeId1 = TestFactory.getFakeId(Opportunity.SObjectType);
        Id fakeId2 = TestFactory.getFakeId(Opportunity.SObjectType);
        List<Opportunity> newOppList = new List<Opportunity>{
            new Opportunity(
                Id = fakeId1,
                Type = 'Free Trial Opportunity',
                StageName = 'Ready to Ship'
            ),
            new Opportunity(
                Id = fakeId2,
                Type = 'Revenue Opportunity',
                StageName = 'Ready to Ship'
            )
        };

        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>{
            fakeId1 => new Opportunity(
                Id = fakeId1,
                Type = 'Free Trial Opportunity',
                StageName = 'Proposal'
            ),
            fakeId2 => new Opportunity(
                Id = fakeId2,
                Type = 'Revenue Opportunity',
                StageName = 'Proposal'
            )
        };

        Test.startTest();
        (new GS_OpportunityNetSuiteService()).pushInfoToNetsuite(oldOppMap, newOppList);
        Test.stopTest();

        System.assertEquals(true, newOppList[0].Retry_TO_to_NS__c);
        System.assertEquals(true, newOppList[1].netsuite_conn__Push_To_Netsuite__c);
    }

    @isTest
    public static void pushToNetSuite_AsyncRecords(){
        DMLWrapper.intializeUnitOfWork(new List<SObjectType>{
            Opportunity.SOBjectType,
            Async_Request__c.SOBjectType
        });
        
        Id fakeId1 = TestFactory.getFakeId(Opportunity.SObjectType);
        Id fakeId2 = TestFactory.getFakeId(Opportunity.SObjectType);
        List<Opportunity> newOppList = new List<Opportunity>{
            new Opportunity(
                Id = fakeId1,
                Type = 'Free Trial Opportunity',
                StageName = 'Closed Won'
            ),
            new Opportunity(
                Id = fakeId2,
                Type = 'Revenue Opportunity',
                StageName = 'Closed Won'
            )
        };

        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>{
            fakeId1 => new Opportunity(
                Id = fakeId1,
                Type = 'Free Trial Opportunity',
                StageName = 'Ready to Ship'
            ),
            fakeId2 => new Opportunity(
                Id = fakeId2,
                Type = 'Revenue Opportunity',
                StageName = 'Ready to Ship'
            )
        };

        Test.startTest();
        (new GS_OpportunityNetSuiteService()).pushInfoToNetsuite(oldOppMap, newOppList);
        DMLWrapper.publishDML();
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Async_Request__c]);
    }

    @isTest
    public static void pushToNetSuite_Async_RelatedRecordsUpdate(){
        Account acc = new Account(
            Name = 'Test Account 1 - Transportation',
            Industry = 'Transportation & Warehousing',
            Organization_Size__c = '100 - 499',
            BillingCountry = 'United States',
            BillingState = 'California'
        );
        insert acc;

        List<Opportunity> oppList_related = new List<Opportunity>{
            new Opportunity(
                Type = 'Rebate',
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                Name = 'New opp for testing 0',
                AccountId = acc.Id,
                Configuration_Segment__c = 'Non Express',
                StageName = 'Closed Date',
                CloseDate = System.today(),
                Probability = 100,
                Rebate_Type__c = 'Buyout',
                Shipping_Country__c = 'United States'
            ),
            new Opportunity(
                Type = 'Rebate',
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                Name = 'New opp for testing 1',
                AccountId = acc.Id,
                Configuration_Segment__c = 'Non Express',
                StageName = 'Closed Date',
                CloseDate = System.today(),
                Probability = 100,
                Rebate_Type__c = 'Subsidy',
                Shipping_Country__c = 'United States'
            ),
            new Opportunity(
                Type = 'Rebate',
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Return Opportunity').getRecordTypeId(),
                Name = 'New opp for testing 2',
                AccountId = acc.Id,
                Configuration_Segment__c = 'Non Express',
                StageName = 'Closed Date',
                CloseDate = System.today(),
                Probability = 100,
                Rebate_Type__c = 'Partner Referral',
                Shipping_Country__c = 'United States'
            )
        };
        insert oppList_related;

        List<Opportunity> oppList_main = new List<Opportunity>{
            new Opportunity(
                Type = 'Free Trial Opportunity',
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                Name = 'New opp for testing 0',
                Buyout_Opportunity__c = oppList_related[0].Id,
                AccountId = acc.Id,
                Configuration_Segment__c = 'Non Express',
                StageName = 'Proposal',
                CloseDate = System.today(),
                Probability = 100,
                Shipping_Country__c = 'United States'
            ),
            new Opportunity(
                Type = 'Free Trial Opportunity',
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                Name = 'New opp for testing 1',
                Subsidy_Opportunity__c = oppList_related[1].Id,
                AccountId = acc.Id,
                Configuration_Segment__c = 'Non Express',
                StageName = 'Proposal',
                CloseDate = System.today(),
                Probability = 100,
                Shipping_Country__c = 'United States'
            ),
            new Opportunity(
                Type = 'Free Trial Opportunity',
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Trial').getRecordTypeId(),
                Name = 'New opp for testing 2',
                Partner_Referral_Opportunity__c = oppList_related[2].Id,
                AccountId = acc.Id,
                Configuration_Segment__c = 'Non Express',
                StageName = 'Proposal',
                CloseDate = System.today(),
                Probability = 100,
                Shipping_Country__c = 'United States'
            )
        };
        insert oppList_main;

        Test.startTest();
        (new GS_OpportunityNetSuiteServiceAsync()).execute(new Async_Request__c(
            Params__c = oppList_main[0].Id+';'+oppList_main[1].Id+';'+oppList_main[2].Id+';',
            Options__c = JSON.serialize(new GS_OpportunityNetSuiteServiceAsync.Options('RELATED_RECORDS_UPDATE'))
        ));
        Test.stopTest();

        System.assertEquals(true, [SELECT Push_Return_to_Netsuite__c FROM Opportunity WHERE ID = :oppList_related[0].Id][0].Push_Return_to_Netsuite__c);
        System.assertEquals(true, [SELECT Push_Return_to_Netsuite__c FROM Opportunity WHERE ID = :oppList_related[1].Id][0].Push_Return_to_Netsuite__c);
        System.assertEquals(true, [SELECT Push_Return_to_Netsuite__c FROM Opportunity WHERE ID = :oppList_related[2].Id][0].Push_Return_to_Netsuite__c);
    }
}
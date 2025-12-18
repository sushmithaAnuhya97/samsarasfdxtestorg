/**
 * Created by vikasmishra on 2021-09-26.
 */

@IsTest
private class GS_QuotaOpportunityServiceTest {
    @IsTest
    static void ShouldCreateRunInSync(){
        GS_QuotaOpportunityService thisService = new GS_QuotaOpportunityService();
        thisService.shouldUpdateInSync();
        System.assert(thisService.transactionTypeAsync == false, 'Should run this Service in Sync');
    }

    @IsTest
    static void ShouldCreateRunInASync(){
        GS_QuotaOpportunityService thisService = new GS_QuotaOpportunityService();
        System.assert(thisService.transactionTypeAsync , 'Should run this Service in Async');
    }

    @IsTest
    static void shouldCreateAsyncRecord(){
        List<Schema.SObjectType> sObjectTypesSequence = new List<Schema.SObjectType>{
                Async_Request__c.SObjectType
        };
        DMLWrapper.intializeUnitOfWork(sObjectTypesSequence);
        GS_QuotaOpportunityService thisService = new GS_QuotaOpportunityService();
        thisService.processQuotaOpportunityDeletion(
                new Map<Id, Opportunity>{
                        generateId(Opportunity.SObjectType, 101) =>
                                new Opportunity(
                                        Id = generateId(Opportunity.SObjectType, 101)
                                )
                },
                new List<Opportunity>{
                        new Opportunity(
                                Id = generateId(Opportunity.SObjectType, 101)
                        )
                }
        );
        System.assert(DMLWrapper.uow != null);
    }

    @IsTest
    static void shouldCreateSyncRecord(){
        List<Schema.SObjectType> sObjectTypesSequence = new List<Schema.SObjectType>{
                Async_Request__c.SObjectType
        };
        DMLWrapper.intializeUnitOfWork(sObjectTypesSequence);
        GS_QuotaOpportunityService thisService = new GS_QuotaOpportunityService();
        thisService.shouldUpdateInSync();
        thisService.processQuotaOpportunityDeletion(
                new Map<Id, Opportunity>{
                        generateId(Opportunity.SObjectType, 101) =>
                                new Opportunity(
                                        Id = generateId(Opportunity.SObjectType, 102)
                                )
                },
                new List<Opportunity>{
                        new Opportunity(
                                Id = generateId(Opportunity.SObjectType, 101)
                        )
                }
        );
        System.assert(DMLWrapper.uow != null);
    }

    @IsTest
    static void shouldCreateSyncRecordException(){
        List<Schema.SObjectType> sObjectTypesSequence = new List<Schema.SObjectType>{
                Async_Request__c.SObjectType
        };
        DMLWrapper.intializeUnitOfWork(sObjectTypesSequence);
        GS_QuotaOpportunityService thisService = new GS_QuotaOpportunityService();
        thisService.shouldUpdateInSync();
        try{
            thisService.processQuotaOpportunityDeletion(
                    new Map<Id, Opportunity>{
                            generateId(Opportunity.SObjectType, 102) =>
                                    new Opportunity(
                                            Id = generateId(Opportunity.SObjectType, 102)
                                    )
                    },
                    new List<Opportunity>{
                            new Opportunity(
                                    Id = generateId(Opportunity.SObjectType, 101)
                            )
                    }
            );
        }
        catch(GS_QuotaOpportunityService.GS_QuotaOpportunityServiceException ex){
            System.assert(ex.getMessage() != null);
        }


    }

    @IsTest
    static void shouldCreateSyncRecordException2(){
        List<Schema.SObjectType> sObjectTypesSequence = new List<Schema.SObjectType>{
                Async_Request__c.SObjectType
        };
        DMLWrapper.intializeUnitOfWork(sObjectTypesSequence);
        GS_QuotaOpportunityService thisService = new GS_QuotaOpportunityService();
        thisService.shouldUpdateInSync();
        try{
            thisService.processQuotaOpportunityDeletion(
                    null,
                    new List<Opportunity>{
                            new Opportunity(
                                    Id = generateId(Opportunity.SObjectType, 101)
                            )
                    }
            );
        }
        catch(GS_QuotaOpportunityService.GS_QuotaOpportunityServiceException ex){
            System.assert(ex.getMessage() != null);
        }


    }

    public static Id generateId(SObjectType sobjectType, Integer sequenceNum) {
        String keyPrefix = sobjectType.getDescribe().getKeyPrefix();
        return Id.valueOf(keyPrefix + String.valueOf(sequenceNum).leftPad(12, '0'));
    }
    
    @IsTest
    static void setADRQuotaOnUserTest1()
    {
        Quota__c testQuota = new Quota__c(
            User__c = system.UserInfo.getUserId(),
            Fiscal_Period__c = 'FY23',
            Fiscal_Period_End_Date__c = Date.today().addDays(10),
            Fiscal_Period_Start_Date__c = Date.today().addDays(-10),
            ADR_Quota__c = 100
        );
        Test.startTest();
        insert testQuota;
        testQuota.ADR_Quota__c = 1000;
        update testQuota;
        Test.stopTest();
    }
    @IsTest
    static void setADRQuotaOnUserTest2()
    {
        Quota__c testQuota = new Quota__c(
            User__c = system.UserInfo.getUserId(),
            Fiscal_Period__c = 'FY23',
            Fiscal_Period_End_Date__c = Date.today().addDays(-10),
            Fiscal_Period_Start_Date__c = Date.today().addDays(-20),
            ADR_Quota__c = 100
        );
        Test.startTest();
        insert testQuota;
        testQuota.ADR_Quota__c = 1000;
        update testQuota;
        Test.stopTest();
    }
    
    @IsTest
    static void setAEQuotaOnUserTest1()
    {
        Quota__c testQuota = new Quota__c(
            User__c = system.UserInfo.getUserId(),
            Fiscal_Period__c = 'FY23',
            Fiscal_Period_End_Date__c = Date.today().addDays(10),
            Fiscal_Period_Start_Date__c = Date.today().addDays(-10),
            Quota__c = 100
        );
        Test.startTest();
        insert testQuota;
        testQuota.Quota__c = 1000;
        update testQuota;
        Test.stopTest();
    }
    @IsTest
    static void setAEQuotaOnUserTest2()
    {
        Quota__c testQuota = new Quota__c(
            User__c = system.UserInfo.getUserId(),
            Fiscal_Period__c = 'FY23',
            Fiscal_Period_End_Date__c = Date.today().addDays(-10),
            Fiscal_Period_Start_Date__c = Date.today().addDays(-20),
            Quota__c = 100
        );
        Test.startTest();
        insert testQuota;
        testQuota.Quota__c = 1000;
        update testQuota;
        Test.stopTest();
    }
}
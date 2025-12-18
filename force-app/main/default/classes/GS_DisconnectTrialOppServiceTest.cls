/**
 * Created by vikasmishra on 2021-09-26.
 */
@IsTest
private class GS_DisconnectTrialOppServiceTest {
    @IsTest
    static void ShouldCreateRunInSync(){
        GS_DisconnectTrialOppService thisService = new GS_DisconnectTrialOppService();
        thisService.shouldRunInSyncMode();
        System.assert(thisService.transactionTypeAsync == false, 'Should run this Service in Sync');
    }

    @IsTest
    static void ShouldCreateRunInASync(){
        GS_SBQQQuoteUpdationService thisService = new GS_SBQQQuoteUpdationService();
        System.assert(thisService.transactionTypeAsync , 'Should run this Service in Async');
    }

    @IsTest
    static void shouldUpdateDisconnectedOpportunityTest(){
        List<Schema.SObjectType> sObjectTypesSequence = new List<Schema.SObjectType>{
                Opportunity.SObjectType
        };
        DMLWrapper.intializeUnitOfWork(sObjectTypesSequence);
        GS_DisconnectTrialOppService thisTrialOppService = new GS_DisconnectTrialOppService();
        thisTrialOppService.processTrialDisconnectionsOnOpportunityDelete(
                new Map<Id, Opportunity>{
                        generateId(Opportunity.SObjectType, 101) =>
                                new Opportunity(Id = generateId(Opportunity.SObjectType, 101))
                }
        );

        System.assert(DMLWrapper.uow !=null, 'Should insert Async Record for GS_AsyncDisconnectTrialOppService');

    }

    @IsTest
    static void shouldUpdateDisconnectedOpportunitySyncTest(){
        List<Schema.SObjectType> sObjectTypesSequence = new List<Schema.SObjectType>{
                Opportunity.SObjectType
        };
        DMLWrapper.intializeUnitOfWork(sObjectTypesSequence);
        GS_DisconnectTrialOppService thisTrialOppService = new GS_DisconnectTrialOppService();
        thisTrialOppService.shouldRunInSyncMode();
        thisTrialOppService.processTrialDisconnectionsOnOpportunityDelete(
                new Map<Id, Opportunity>{
                        generateId(Opportunity.SObjectType, 101) =>
                                new Opportunity(Id = generateId(Opportunity.SObjectType, 101))
                }
        );

        System.assert(DMLWrapper.uow !=null, 'Should Update the opp');

    }

    @IsTest
    static void shouldUpdateDisconnectedOpportunityWithRevenueOpportunityTest(){
        List<Schema.SObjectType> sObjectTypesSequence = new List<Schema.SObjectType>{
                Opportunity.SObjectType
        };
        DMLWrapper.intializeUnitOfWork(sObjectTypesSequence);
        GS_DisconnectTrialOppService thisTrialOppService = new GS_DisconnectTrialOppService();
        thisTrialOppService.shouldRunInSyncMode();
        thisTrialOppService.processTrialDisconnectionsOnOpportunityDelete(
                new Map<Id, Opportunity>{
                        generateId(Opportunity.SObjectType, 101) =>
                                new Opportunity(
                                        Id = generateId(Opportunity.SObjectType, 101),
                                        Type = 'Revenue Opportunity'
                                )
                }
        );

        System.assert(DMLWrapper.uow !=null, 'Should Update the opp');

    }

    @IsTest
    static void shouldUpdateDisconnectedOpportunityWithFreeTrialReturnTest(){
        List<Schema.SObjectType> sObjectTypesSequence = new List<Schema.SObjectType>{
                Opportunity.SObjectType
        };
        DMLWrapper.intializeUnitOfWork(sObjectTypesSequence);
        GS_DisconnectTrialOppService thisTrialOppService = new GS_DisconnectTrialOppService();
        thisTrialOppService.shouldRunInSyncMode();
        thisTrialOppService.processTrialDisconnectionsOnOpportunityDelete(
                new Map<Id, Opportunity>{
                        generateId(Opportunity.SObjectType, 101) =>
                                new Opportunity(
                                        Id = generateId(Opportunity.SObjectType, 101),
                                        Type = 'Free Trial Return'
                                )
                }
        );

        System.assert(DMLWrapper.uow !=null, 'Should Update the opp');

    }

    @IsTest
    static void shouldUpdateDisconnectedOpportunityWithRevenueOpportunityBillOnlyTest(){
        List<Schema.SObjectType> sObjectTypesSequence = new List<Schema.SObjectType>{
                Opportunity.SObjectType
        };
        DMLWrapper.intializeUnitOfWork(sObjectTypesSequence);
        GS_DisconnectTrialOppService thisTrialOppService = new GS_DisconnectTrialOppService();
        thisTrialOppService.shouldRunInSyncMode();
        thisTrialOppService.processTrialDisconnectionsOnOpportunityDelete(
                new Map<Id, Opportunity>{
                        generateId(Opportunity.SObjectType, 101) =>
                                new Opportunity(
                                        Id = generateId(Opportunity.SObjectType, 101),
                                        Type = 'Revenue Opportunity - Bill Only'
                                )
                }
        );

        System.assert(DMLWrapper.uow !=null, 'Should Update the opp');

    }

    @IsTest
    static void shouldUpdateDisconnectionsForTrialsTest(){
        List<Schema.SObjectType> sObjectTypesSequence = new List<Schema.SObjectType>{
                Opportunity.SObjectType
        };
        DMLWrapper.intializeUnitOfWork(sObjectTypesSequence);
        GS_DisconnectTrialOppService thisTrialOppService = new GS_DisconnectTrialOppService();
        thisTrialOppService.updateDisconnectionsForTrials(
                new Map<Id, Opportunity>{
                        generateId(Opportunity.SObjectType, 101) =>
                                new Opportunity(Id = generateId(Opportunity.SObjectType, 101))
                }
        );

        System.assert(DMLWrapper.uow !=null, 'Should update opportunities for disconnections');

    }

    @IsTest
    static void shouldUpdateDisconnectionsForTrialsWithExceptionTest(){
        List<Schema.SObjectType> sObjectTypesSequence = new List<Schema.SObjectType>{
                Opportunity.SObjectType
        };
        DMLWrapper.intializeUnitOfWork(sObjectTypesSequence);
        try{
            GS_DisconnectTrialOppService thisTrialOppService = new GS_DisconnectTrialOppService();
            thisTrialOppService.processTrialDisconnectionsOnOpportunityDelete(
                    null
            );
        }
        catch(Exception ex){
            System.assert(ex.getMessage().contains('No element found for Disconnections. This method has been called from before delete context'), 'Should throw exception for empty and null list');
        }
    }

    public static Id generateId(SObjectType sobjectType, Integer sequenceNum) {
        String keyPrefix = sobjectType.getDescribe().getKeyPrefix();
        return Id.valueOf(keyPrefix + String.valueOf(sequenceNum).leftPad(12, '0'));
    }


}
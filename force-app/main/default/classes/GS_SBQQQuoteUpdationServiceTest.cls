/**
 * Created by vikasmishra on 2021-09-21.
 */
@IsTest
public with sharing class GS_SBQQQuoteUpdationServiceTest {

    @IsTest
    static void ShouldCreateRunInSync(){
        GS_SBQQQuoteUpdationService thisService = new GS_SBQQQuoteUpdationService();
        thisService.shouldUpdateSBQQQuoteInSync();
        System.assert(thisService.transactionTypeAsync == false, 'Should run this Service in Sync');
    }

    @IsTest
    static void ShouldCreateRunInASync(){
        GS_SBQQQuoteUpdationService thisService = new GS_SBQQQuoteUpdationService();
        System.assert(thisService.transactionTypeAsync , 'Should run this Service in Async');
    }

    @IsTest
    static void ShouldProcessQuoteFromOpportunitiesTest(){
        GS_SBQQQuoteUpdationService thisService = new GS_SBQQQuoteUpdationService();
        thisService.processQuoteFromOpportunities(
                new Map<Id, Opportunity>{
                        generateId(Opportunity.SObjectType, 101) => new Opportunity (
                        Id = generateId(Opportunity.SObjectType, 101),
                        VAT_Number__c ='101',
                        CloseDate = System.today().addDays(-1)
                        )
                },
                new List<Opportunity>{
                        new Opportunity (
                        Id = generateId(Opportunity.SObjectType, 101),
                        VAT_Number__c ='102',
                        CloseDate = System.today().addDays(-1)
                        )
                }
        );
        System.assert(!thisService.targetOpportunityIdsForQuoteUpdate.isEmpty() , 'Should set the target opp map');
        System.assert(thisService.targetOpportunityIdsForQuoteUpdate.values()[0].Id == generateId(Opportunity.SObjectType, 101) , 'Should set the target opp map');
    }

    @IsTest
    static void ShouldProcessQuoteFromOpportunitiesResellerChangedTest(){
        GS_SBQQQuoteUpdationService thisService = new GS_SBQQQuoteUpdationService();
        thisService.processQuoteFromOpportunities(
                new Map<Id, Opportunity>{
                        generateId(Opportunity.SObjectType, 101) => new Opportunity (
                                Id = generateId(Opportunity.SObjectType, 101),
                                VAT_Number__c ='101',
                                Reseller__c = generateId(Account.SObjectType, 101)
                        )
                },
                new List<Opportunity>{
                        new Opportunity (
                                Id = generateId(Opportunity.SObjectType, 101),
                                VAT_Number__c ='101',
                                Reseller__c = generateId(Account.SObjectType, 102)
                        )
                }
        );
        System.assert(!thisService.targetOpportunityIdsForQuoteUpdate.isEmpty() , 'Should set the target opp map');
        System.assert(thisService.targetOpportunityIdsForQuoteUpdate.values()[0].Id == generateId(Opportunity.SObjectType, 101) , 'Should set the target opp map');
    }

    @IsTest
    static void ShouldProcessQuoteFromOpportunitiesInsurancePartnerChangedTest(){
        GS_SBQQQuoteUpdationService thisService = new GS_SBQQQuoteUpdationService();
        thisService.processQuoteFromOpportunities(
                new Map<Id, Opportunity>{
                        generateId(Opportunity.SObjectType, 101) => new Opportunity (
                                Id = generateId(Opportunity.SObjectType, 101),
                                VAT_Number__c ='101',
                                Insurance_Partner__c = generateId(Account.SObjectType, 101)
                        )
                },
                new List<Opportunity>{
                        new Opportunity (
                                Id = generateId(Opportunity.SObjectType, 101),
                                VAT_Number__c ='101',
                                Insurance_Partner__c = generateId(Account.SObjectType, 102)
                        )
                }
        );
        System.assert(!thisService.targetOpportunityIdsForQuoteUpdate.isEmpty() , 'Should set the target opp map');
        System.assert(thisService.targetOpportunityIdsForQuoteUpdate.values()[0].Id == generateId(Opportunity.SObjectType, 101) , 'Should set the target opp map');
    }

    @IsTest
    static void ShouldProcessQuoteFromOpportunitiesResellerPartnerChangedTest(){
        GS_SBQQQuoteUpdationService thisService = new GS_SBQQQuoteUpdationService();
        thisService.processQuoteFromOpportunities(
                new Map<Id, Opportunity>{
                        generateId(Opportunity.SObjectType, 101) => new Opportunity (
                                Id = generateId(Opportunity.SObjectType, 101),
                                VAT_Number__c ='101',
                                Reseller_Partner__c = generateId(Account.SObjectType, 101)
                        )
                },
                new List<Opportunity>{
                        new Opportunity (
                                Id = generateId(Opportunity.SObjectType, 101),
                                VAT_Number__c ='101',
                                Reseller_Partner__c = generateId(Account.SObjectType, 102)
                        )
                }
        );
        System.assert(!thisService.targetOpportunityIdsForQuoteUpdate.isEmpty() , 'Should set the target opp map');
        System.assert(thisService.targetOpportunityIdsForQuoteUpdate.values()[0].Id == generateId(Opportunity.SObjectType, 101) , 'Should set the target opp map');
    }

    @IsTest
    static void ShouldProcessQuoteFromOpportunitiesReferralPartnerChangedTest(){
        GS_SBQQQuoteUpdationService thisService = new GS_SBQQQuoteUpdationService();
        thisService.processQuoteFromOpportunities(
                new Map<Id, Opportunity>{
                        generateId(Opportunity.SObjectType, 101) => new Opportunity (
                                Id = generateId(Opportunity.SObjectType, 101),
                                VAT_Number__c ='101',
                                Referral_Partner__c = generateId(Account.SObjectType, 101)
                        )
                },
                new List<Opportunity>{
                        new Opportunity (
                                Id = generateId(Opportunity.SObjectType, 101),
                                VAT_Number__c ='101',
                                Referral_Partner__c = generateId(Account.SObjectType, 102)
                        )
                }
        );
        System.assert(!thisService.targetOpportunityIdsForQuoteUpdate.isEmpty() , 'Should set the target opp map');
        System.assert(thisService.targetOpportunityIdsForQuoteUpdate.values()[0].Id == generateId(Opportunity.SObjectType, 101) , 'Should set the target opp map');
    }

    @IsTest
    static void ShouldProcessQuoteFromOpportunitiesCloseDateChangedTest(){
        GS_SBQQQuoteUpdationService thisService = new GS_SBQQQuoteUpdationService();
        thisService.processQuoteFromOpportunities(
                new Map<Id, Opportunity>{
                        generateId(Opportunity.SObjectType, 101) => new Opportunity (
                                Id = generateId(Opportunity.SObjectType, 101),
                                VAT_Number__c ='101',
                                Referral_Partner__c = generateId(Account.SObjectType, 101),
                                CloseDate = System.today().addDays(1)
                        )
                },
                new List<Opportunity>{
                        new Opportunity (
                                Id = generateId(Opportunity.SObjectType, 101),
                                VAT_Number__c ='101',
                                Referral_Partner__c = generateId(Account.SObjectType, 101),
                                CloseDate = System.today().addDays(2)
                        )
                }
        );
        System.assert(!thisService.targetOpportunityIdsForQuoteUpdate.isEmpty() , 'Should set the target opp map');
        System.assert(thisService.targetOpportunityIdsForQuoteUpdate.values()[0].Id == generateId(Opportunity.SObjectType, 101) , 'Should set the target opp map');
    }

    @IsTest
    static void ShouldThrowEmptyOldMapExceptionTest(){
        GS_SBQQQuoteUpdationService thisService = new GS_SBQQQuoteUpdationService();
        try{
            thisService.processQuoteFromOpportunities(
                    null,
                    new List<Opportunity>{
                            new Opportunity (
                                    Id = generateId(Opportunity.SObjectType, 101),
                                    VAT_Number__c ='101',
                                    Referral_Partner__c = generateId(Account.SObjectType, 101),
                                    CloseDate = System.today().addDays(2)
                            )
                    }
            );
        }
        catch(GS_SBQQQuoteUpdationService.GS_SBQQQuoteUpdationServiceException ex){
            System.assert(ex.getMessage() == 'Old Map is null. This method is only getting called in After Update Context.');
        }

    }

    @IsTest
    static void ShouldThrowElementNoInOldMapExceptionTest(){
        GS_SBQQQuoteUpdationService thisService = new GS_SBQQQuoteUpdationService();
        try{
            thisService.processQuoteFromOpportunities(
                    new Map<Id, Opportunity>{
                            generateId(Opportunity.SObjectType, 101) => new Opportunity (
                                    Id = generateId(Opportunity.SObjectType, 101),
                                    VAT_Number__c ='101',
                                    Referral_Partner__c = generateId(Account.SObjectType, 101),
                                    CloseDate = System.today().addDays(1)
                            )
                    },
                    new List<Opportunity>{
                            new Opportunity (
                                    Id = generateId(Opportunity.SObjectType, 102),
                                    VAT_Number__c ='101',
                                    Referral_Partner__c = generateId(Account.SObjectType, 101),
                                    CloseDate = System.today().addDays(2)
                            )
                    }
            );
        }
        catch(GS_SBQQQuoteUpdationService.GS_SBQQQuoteUpdationServiceException ex){
            System.assert(ex.getMessage() == 'No element found in old Map.');
        }

    }

    @IsTest
    static void ShouldCreateAsyncRequestRecordTest(){
        List<Schema.SObjectType> sObjectTypesSequence = new List<Schema.SObjectType>{
                Async_Request__c.SObjectType
        };
        DMLWrapper.intializeUnitOfWork(sObjectTypesSequence);
        GS_SBQQQuoteUpdationService thisService = new GS_SBQQQuoteUpdationService();
        thisService.updateSBQQQuotesFromOpportunity(
                new Map<Id, Opportunity>{
                        generateId(Opportunity.SObjectType, 101) => new Opportunity (
                                Id = generateId(Opportunity.SObjectType, 101),
                                VAT_Number__c ='101',
                                CloseDate = System.today().addDays(-1)
                        )
                },
                new List<Opportunity>{
                        new Opportunity (
                                Id = generateId(Opportunity.SObjectType, 101),
                                VAT_Number__c ='102',
                                CloseDate = System.today().addDays(-1)
                        )
                }
        );
        DMLWrapper.publishDML();
        System.assert(![SELECT Id FROM Async_Request__c].isEmpty(), 'Should create a sync record');
    }

    @IsTest
    static void shouldUpdateSBQQQuotesFromOpportunityTest(){
        GS_UpdateQuoteFromOpportunityMock thisMock = new GS_UpdateQuoteFromOpportunityMock();
        GS_SBQQQuoteUpdationService thisService = new GS_SBQQQuoteUpdationService();
        GS_SBQQQuoteUpdationService.thisGS_UpdateQuoteFromOpportunity = thisMock;
        thisService.updateSBQQQuotesFromOpportunity(new Map<Id, Opportunity>(), new Map<Id,SBQQ__Quote__c>());
        thisService.shouldUpdateSBQQQuoteInSync();
        thisService.updateSBQQQuotesFromOpportunity(
                new Map<Id, Opportunity>{
                        generateId(Opportunity.SObjectType, 101) => new Opportunity (
                                Id = generateId(Opportunity.SObjectType, 101),
                                VAT_Number__c ='101',
                                Referral_Partner__c = generateId(Account.SObjectType, 101),
                                CloseDate = System.today().addDays(1)
                        )
                },
                new List<Opportunity>{
                        new Opportunity (
                                Id = generateId(Opportunity.SObjectType, 101),
                                VAT_Number__c ='101',
                                Referral_Partner__c = generateId(Account.SObjectType, 101),
                                CloseDate = System.today().addDays(2)
                        )
                }
        );
        System.assert(thisMock.processQuoteForUpdateCalled, 'Should call processQuoteForUpdate method');
    }

    @IsTest
    static void processQuoteForUpdateTest(){
        List<Schema.SObjectType> sObjectTypesSequence = new List<Schema.SObjectType>{
                SBQQ__Quote__c.SObjectType
        };
        DMLWrapper.intializeUnitOfWork(sObjectTypesSequence);
        GS_SBQQQuoteUpdationService.GS_UpdateQuoteFromOpportunity thisService = new GS_SBQQQuoteUpdationService.GS_UpdateQuoteFromOpportunity();
        thisService.processQuoteForUpdate(
                new Map<Id, Opportunity>{
                        generateId(Opportunity.SObjectType, 101) => new Opportunity (
                                Id = generateId(Opportunity.SObjectType, 101),
                                VAT_Number__c ='101',
                                Referral_Partner__c = generateId(Account.SObjectType, 101),
                                CloseDate = System.today().addDays(1)
                        )
                },
                new Map<Id, SBQQ__Quote__c>{
                        generateId(SBQQ__Quote__c.SObjectType, 101) => new SBQQ__Quote__c (
                                Id = generateId(SBQQ__Quote__c.SObjectType, 101),
                                SBQQ__Opportunity2__c = generateId(Opportunity.SObjectType, 101)
                        )
                }
        );

        System.assert(DMLWrapper.uow != null);
    }

    @IsTest
    static void shouldProcessQuoteForUpdateHasInsurancePartnerTest(){
        List<Schema.SObjectType> sObjectTypesSequence = new List<Schema.SObjectType>{
                SBQQ__Quote__c.SObjectType
        };
        DMLWrapper.intializeUnitOfWork(sObjectTypesSequence);
        GS_SBQQQuoteUpdationService.GS_UpdateQuoteFromOpportunity thisService = new GS_SBQQQuoteUpdationService.GS_UpdateQuoteFromOpportunity();
        thisService.processQuoteForUpdate(
                new Map<Id, Opportunity>{
                        generateId(Opportunity.SObjectType, 101) => new Opportunity (
                                Id = generateId(Opportunity.SObjectType, 101),
                                VAT_Number__c ='101',
                                Insurance_Partner__c = generateId(Account.SObjectType, 101),
                                CloseDate = System.today().addDays(1)
                        )
                },
                new Map<Id, SBQQ__Quote__c>{
                        generateId(SBQQ__Quote__c.SObjectType, 101) => new SBQQ__Quote__c (
                                Id = generateId(SBQQ__Quote__c.SObjectType, 101),
                                SBQQ__Opportunity2__c = generateId(Opportunity.SObjectType, 101)
                        )
                }
        );

        System.assert(DMLWrapper.uow != null);
    }

    @IsTest
    static void shouldProcessQuoteForUpdateHasResellerPartnerTest(){
        List<Schema.SObjectType> sObjectTypesSequence = new List<Schema.SObjectType>{
                SBQQ__Quote__c.SObjectType
        };
        DMLWrapper.intializeUnitOfWork(sObjectTypesSequence);
        GS_SBQQQuoteUpdationService.GS_UpdateQuoteFromOpportunity thisService = new GS_SBQQQuoteUpdationService.GS_UpdateQuoteFromOpportunity();
        thisService.processQuoteForUpdate(
                new Map<Id, Opportunity>{
                        generateId(Opportunity.SObjectType, 101) => new Opportunity (
                                Id = generateId(Opportunity.SObjectType, 101),
                                VAT_Number__c ='101',
                                Reseller_Partner__c = generateId(Account.SObjectType, 101),
                                CloseDate = System.today().addDays(1)
                        )
                },
                new Map<Id, SBQQ__Quote__c>{
                        generateId(SBQQ__Quote__c.SObjectType, 101) => new SBQQ__Quote__c (
                                Id = generateId(SBQQ__Quote__c.SObjectType, 101),
                                SBQQ__Opportunity2__c = generateId(Opportunity.SObjectType, 101)
                        )
                }
        );

        System.assert(DMLWrapper.uow != null);
    }

    @IsTest
    static void shouldProcessQuoteForUpdateHasCustomContractValidationTest(){
        List<Schema.SObjectType> sObjectTypesSequence = new List<Schema.SObjectType>{
                SBQQ__Quote__c.SObjectType
        };
        DMLWrapper.intializeUnitOfWork(sObjectTypesSequence);
        GS_SBQQQuoteUpdationService.GS_UpdateQuoteFromOpportunity thisService = new GS_SBQQQuoteUpdationService.GS_UpdateQuoteFromOpportunity();
        thisService.processQuoteForUpdate(
                new Map<Id, Opportunity>{
                        generateId(Opportunity.SObjectType, 101) => new Opportunity (
                                Id = generateId(Opportunity.SObjectType, 101),
                                VAT_Number__c ='101',
                                Reseller_Partner__c = generateId(Account.SObjectType, 101),
                                CloseDate = System.today().addDays(1),
                                Probability = 80,
                                Type = 'Revenue Opportunity',
                                SBQQ__AmendedContract__c = generateId(Contract.SObjectType, 101)
                        )
                },
                new Map<Id, SBQQ__Quote__c>{
                        generateId(SBQQ__Quote__c.SObjectType, 101) => new SBQQ__Quote__c (
                                Id = generateId(SBQQ__Quote__c.SObjectType, 101),
                                SBQQ__Opportunity2__c = generateId(Opportunity.SObjectType, 101)
                        )
                }
        );

        System.assert(DMLWrapper.uow != null);
    }


    public static Id generateId(SObjectType sobjectType, Integer sequenceNum) {
        String keyPrefix = sobjectType.getDescribe().getKeyPrefix();
        return Id.valueOf(keyPrefix + String.valueOf(sequenceNum).leftPad(12, '0'));
    }

    public class GS_UpdateQuoteFromOpportunityMock implements GS_SBQQQuoteUpdationService.IInternalService{
        Boolean processQuoteForUpdateCalled = false;
        public void processQuoteForUpdate(Map<Id, Opportunity> mapOfOpportunities, Map<Id, SBQQ__Quote__c> mapOfQuote){
            processQuoteForUpdateCalled = true;
        }
    }
}
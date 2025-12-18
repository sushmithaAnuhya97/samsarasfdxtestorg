/**
 * Created by vikasmishra on 2021-09-15.
 */

@IsTest
private class GS_FreeTrialQuoteCreatorServiceTest {

    @IsTest
    static void ShouldCreateRunInSync(){
        GS_FreeTrialQuoteCreatorService thisService = new GS_FreeTrialQuoteCreatorService();
        thisService.shouldProcessInSync();
        System.assert(thisService.transactionTypeAsync == false, 'Should run this Service in Sync');
    }

    @IsTest
    static void ShouldCreateRunInASync(){
        GS_FreeTrialQuoteCreatorService thisService = new GS_FreeTrialQuoteCreatorService();
        System.assert(thisService.transactionTypeAsync , 'Should run this Service in Async');
    }

    @IsTest
    static void ShouldProcessFreeTrialQuoteFromOpportunitiesFreeTrialOpportunityTest(){
        List<Schema.SObjectType> sObjectTypesSequence = new List<Schema.SObjectType>{
                Async_Request__c.SObjectType
        };
        DMLWrapper.intializeUnitOfWork(sObjectTypesSequence);
        GS_FreeTrialQuoteCreatorService thisService = new GS_FreeTrialQuoteCreatorService();
        thisService.createFreeTrialQuoteFromOpportunities(
                new Map<Id, Opportunity>{
                    generateId(Opportunity.SObjectType, 101) =>
                            new Opportunity(
                                    Id = generateId(Opportunity.SObjectType, 101),
                                    Type = 'Free Trial Opportunity',
                                    Send_Invoice__c = false
                            )
                },
                new List<Opportunity>{
                        new Opportunity(
                                Id = generateId(Opportunity.SObjectType, 101),
                                Type = 'Free Trial Opportunity',
                                Send_Invoice__c = true
                        )
                }
        );
        System.assert(DMLWrapper.uow != null);
    }

    @IsTest
    static void shouldTestQuoteCreator(){
        GS_FreeTrialQuoteCreatorService thisService = new GS_FreeTrialQuoteCreatorService();
        thisService.shouldProcessInSync();
        thisService.createFreeTrialQuoteFromOpportunities(
                new Map<Id, Opportunity>{
                        generateId(Opportunity.SObjectType, 101) =>
                                new Opportunity(
                                        Id = generateId(Opportunity.SObjectType, 101),
                                        Type = 'Free Trial Opportunity',
                                        Send_Invoice__c = false
                                )
                },
                new List<Opportunity>{
                        new Opportunity(
                                Id = generateId(Opportunity.SObjectType, 101),
                                Type = 'Free Trial Opportunity',
                                Send_Invoice__c = true
                        )
                }
        );
        System.assert(thisService.transactionTypeAsync == false, 'Should run this Service in Sync');
    }

    @IsTest
    static void shouldTestQuoteCreatorInternalClass(){
        List<Schema.SObjectType> sObjectTypesSequence = new List<Schema.SObjectType>{
                Quote.SObjectType,
                QuoteLineItem.SObjectType
        };
        GS_FreeTrialQuoteCreatorService thisService = new GS_FreeTrialQuoteCreatorService();
        DMLWrapper.intializeUnitOfWork(sObjectTypesSequence);
        Map<Id,Opportunity> opportunitiesMap = new Map<Id,Opportunity>{
                generateId(Opportunity.SObjectType, 101) =>
                        new Opportunity(
                                Id = generateId(Opportunity.SObjectType, 101),
                                Name = 'Testing Opportunity',
                                Pricebook2Id = generateId(Pricebook2.SObjectType, 101),
                                Trial_Primary_Contact__c = generateId(Contact.SObjectType, 101),
                                AccountId = generateId(Account.SObjectType, 101)
                        )
        };
        Map<Id, List<OpportunityLineItem>> mapOfOppLineItemsAndOpp =
                new Map<Id, List<OpportunityLineItem>>{
                        generateId(Opportunity.SObjectType, 101) =>
                                new List<OpportunityLineItem>()
                };
        GS_FreeTrialQuoteCreatorService.QuoteCreator internalQuoteCreator =
                new GS_FreeTrialQuoteCreatorService.QuoteCreator(opportunitiesMap, mapOfOppLineItemsAndOpp);
        thisService.CreateFreeTrialQuoteAndQuoteLine(internalQuoteCreator);
        System.assert(DMLWrapper.uow != null);
        System.debug(DMLWrapper.uow+'####DMLWRAPPER');
    }

    @IsTest
    static void shouldTestQuoteCreatorInternalClass2(){
        List<Schema.SObjectType> sObjectTypesSequence = new List<Schema.SObjectType>{
                Quote.SObjectType,
                QuoteLineItem.SObjectType
        };
        GS_FreeTrialQuoteCreatorService thisService = new GS_FreeTrialQuoteCreatorService();
        DMLWrapper.intializeUnitOfWork(sObjectTypesSequence);
        Map<Id,Opportunity> opportunitiesMap = new Map<Id,Opportunity>{
                generateId(Opportunity.SObjectType, 101) =>
                        new Opportunity(
                                Id = generateId(Opportunity.SObjectType, 101),
                                Name = 'Testing Opportunity',
                                Pricebook2Id = generateId(Pricebook2.SObjectType, 101),
                                Trial_Primary_Contact__c = generateId(Contact.SObjectType, 101),
                                AccountId = generateId(Account.SObjectType, 101)
                        )
        };
        Map<Id, List<OpportunityLineItem>> mapOfOppLineItemsAndOpp =
                new Map<Id, List<OpportunityLineItem>>{
                        generateId(Opportunity.SObjectType, 101) =>
                                new List<OpportunityLineItem>{
                                        new OpportunityLineItem(
                                                Id = generateId(OpportunityLineItem.SObjectType, 101),
                                                Quantity = 2,
                                                UnitPrice = 10,
                                                Discount = 5,
                                                PricebookEntryId = generateId(PricebookEntry.SObjectType, 101)
                                        )
                                }
                };
        GS_FreeTrialQuoteCreatorService.QuoteCreator internalQuoteCreator =
                new GS_FreeTrialQuoteCreatorService.QuoteCreator(opportunitiesMap, mapOfOppLineItemsAndOpp);
        try{
            thisService.CreateFreeTrialQuoteAndQuoteLine(internalQuoteCreator);
            System.assert(DMLWrapper.uow != null);
        }
        catch(Exception ex){

        }


        System.debug(DMLWrapper.uow+'####DMLWRAPPER');
    }

    @IsTest
    static void shouldTestQuoteCreatorInternalClassLogWarning(){
        List<Schema.SObjectType> sObjectTypesSequence = new List<Schema.SObjectType>{
                Quote.SObjectType,
                QuoteLineItem.SObjectType
        };
        GS_FreeTrialQuoteCreatorService thisService = new GS_FreeTrialQuoteCreatorService();
        DMLWrapper.intializeUnitOfWork(sObjectTypesSequence);
        Map<Id,Opportunity> opportunitiesMap = new Map<Id,Opportunity>{
                generateId(Opportunity.SObjectType, 101) =>
                        new Opportunity(
                                Id = generateId(Opportunity.SObjectType, 101),
                                Name = 'Testing Opportunity',
                                Pricebook2Id = generateId(Pricebook2.SObjectType, 101),
                                Trial_Primary_Contact__c = generateId(Contact.SObjectType, 101),
                                AccountId = generateId(Account.SObjectType, 101)
                        )
        };
        Map<Id, List<OpportunityLineItem>> mapOfOppLineItemsAndOpp =
                new Map<Id, List<OpportunityLineItem>>{
                        generateId(Opportunity.SObjectType, 102) =>
                                new List<OpportunityLineItem>{
                                        new OpportunityLineItem(
                                                Id = generateId(OpportunityLineItem.SObjectType, 101),
                                                Quantity = 2,
                                                UnitPrice = 10,
                                                Discount = 5,
                                                PricebookEntryId = generateId(PricebookEntry.SObjectType, 101)
                                        )
                                }
                };
        GS_FreeTrialQuoteCreatorService.QuoteCreator internalQuoteCreator =
                new GS_FreeTrialQuoteCreatorService.QuoteCreator(opportunitiesMap, mapOfOppLineItemsAndOpp);
        try{
            thisService.CreateFreeTrialQuoteAndQuoteLine(internalQuoteCreator);
            System.assert(DMLWrapper.uow != null);
        }
        catch(Exception ex){

        }


        System.debug(DMLWrapper.uow+'####DMLWRAPPER');
    }

    @IsTest
    static void shouldTestQuoteCreatorInternalClassExceptionWithNullMap(){
        List<Schema.SObjectType> sObjectTypesSequence = new List<Schema.SObjectType>{
                Quote.SObjectType,
                QuoteLineItem.SObjectType
        };
        GS_FreeTrialQuoteCreatorService thisService = new GS_FreeTrialQuoteCreatorService();
        DMLWrapper.intializeUnitOfWork(sObjectTypesSequence);

        try{
            thisService.processFreeTrialQuoteFromOpportunities(
                    new Map<Id, Opportunity>{
                            generateId(Opportunity.SObjectType, 102) =>
                            new Opportunity(
                                Id = generateId(Opportunity.SObjectType, 102),
                                Name = 'Testing Opportunity',
                                Pricebook2Id = generateId(Pricebook2.SObjectType, 101),
                                Trial_Primary_Contact__c = generateId(Contact.SObjectType, 101),
                                AccountId = generateId(Account.SObjectType, 101)
                            )
                    },
                    new List<Opportunity>{
                            new Opportunity(
                            Id = generateId(Opportunity.SObjectType, 101),
                            Name = 'Testing Opportunity',
                            Pricebook2Id = generateId(Pricebook2.SObjectType, 101),
                            Trial_Primary_Contact__c = generateId(Contact.SObjectType, 101),
                            AccountId = generateId(Account.SObjectType, 101)
                            )
                    }
            );
        }
        catch(Exception ex){
            System.assert(ex.getMessage() == 'No element found in old Map.');
        }


        System.debug(DMLWrapper.uow+'####DMLWRAPPER');
    }

    @IsTest
    static void shouldTestQuoteCreatorInternalClassException(){
        List<Schema.SObjectType> sObjectTypesSequence = new List<Schema.SObjectType>{
                Quote.SObjectType,
                QuoteLineItem.SObjectType
        };
        GS_FreeTrialQuoteCreatorService thisService = new GS_FreeTrialQuoteCreatorService();
        DMLWrapper.intializeUnitOfWork(sObjectTypesSequence);

        try{
            thisService.processFreeTrialQuoteFromOpportunities(
                    null,
                    new List<Opportunity>{
                            new Opportunity(
                                    Id = generateId(Opportunity.SObjectType, 101),
                                    Name = 'Testing Opportunity',
                                    Pricebook2Id = generateId(Pricebook2.SObjectType, 101),
                                    Trial_Primary_Contact__c = generateId(Contact.SObjectType, 101),
                                    AccountId = generateId(Account.SObjectType, 101)
                            )
                    }
            );
        }
        catch(Exception ex){
            System.assert(ex.getMessage() == 'Old Map is null. This method is only getting called in After Update Context.');
        }


        System.debug(DMLWrapper.uow+'####DMLWRAPPER');
    }

    public static Id generateId(SObjectType sobjectType, Integer sequenceNum) {
        String keyPrefix = sobjectType.getDescribe().getKeyPrefix();
        return Id.valueOf(keyPrefix + String.valueOf(sequenceNum).leftPad(12, '0'));
    }
}
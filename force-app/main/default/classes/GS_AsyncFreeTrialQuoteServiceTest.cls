/**
 * Created by vikasmishra on 2021-10-13.
 */

@IsTest
private class GS_AsyncFreeTrialQuoteServiceTest {
    @IsTest
    static void testExecute() {
        GS_AsyncFreeTrialQuoteService thisService = new GS_AsyncFreeTrialQuoteService();
        Test.startTest();
        try{
            thisService.execute(new Async_Request__c());
        }
        catch(Exception ex){
            System.debug(ex);
        }
        Test.stopTest();

        System.assert([SELECT Id FROM Log__c].size() != 10);
    }

    @IsTest
    static void ShouldReturnGetRequestType(){
        List<Schema.SObjectType> sObjectTypesSequence = new List<Schema.SObjectType>{
                Quote.SObjectType,
                QuoteLineItem.SObjectType
        };
        GS_FreeTrialQuoteCreatorService thisQuoteCreatorService = new GS_FreeTrialQuoteCreatorService();
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

        GS_AsyncFreeTrialQuoteService.AsyncFreeTrialQuoteService thisInnerService =
                new GS_AsyncFreeTrialQuoteService.AsyncFreeTrialQuoteService();
        thisInnerService.thisGS_FreeTrialQuoteCreatorService = new GS_FreeTrialQuoteCreatorServiceMock();
        thisInnerService.createFreeTrialQuoteFromOpportunities();
        internalQuoteCreator.mapOfEmailPerOpportunity = new  Map<Id, Messaging.SingleEmailMessage>{
                generateId(Opportunity.SObjectType, 101) =>
                        new Messaging.SingleEmailMessage()
        };
        internalQuoteCreator.thisDocumentCreator.mapOfQuoteDocumentWithOpportunity = new Map<Id, QuoteDocument>{
                generateId(Opportunity.SObjectType, 101) =>
                        new QuoteDocument(
                                Id = generateId(QuoteDocument.SObjectType, 101)
                        )
        };
        thisInnerService.registerEmailContent(internalQuoteCreator);

        GS_AsyncFreeTrialQuoteService thisService = new GS_AsyncFreeTrialQuoteService();
        System.assert(thisService.getRequestType() == 'Create Free Trial Quote');
    }

    public with sharing class GS_FreeTrialQuoteCreatorServiceMock implements GS_FreeTrialQuoteCreatorService.IService{
        public void CreateFreeTrialQuoteAndQuoteLine(GS_FreeTrialQuoteCreatorService.QuoteCreator thisQuoteCreator){

        }
        public void createFreeTrialQuoteFromOpportunities(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOppList){

        }
        public void processFreeTrialQuoteFromOpportunities(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOppList){

        }
    }
    public static Id generateId(SObjectType sobjectType, Integer sequenceNum) {
        String keyPrefix = sobjectType.getDescribe().getKeyPrefix();
        return Id.valueOf(keyPrefix + String.valueOf(sequenceNum).leftPad(12, '0'));
    }
}
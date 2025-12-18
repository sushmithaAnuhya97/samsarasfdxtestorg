/**
 * Created by vikasmishra on 2021-09-16.
 */

public with sharing class GS_AsyncSBQQQuoteFromOpportunityService extends BaseAsyncHandler{
    SamsaraLoggerService thisLoggerService = new SamsaraLoggerService();
    public override String getRequestType(){
        return 'Update SBQQ Quote From Opportunity';
    }

    public override void execute(Async_Request__c ar){
        try{
            new AsyncSBQQQuoteFromOpportunityService().updateQuotes(ar);
        }
        catch(Exception ex){
            thisLoggerService.logger.logError(
                    'Failed to update SBQQ QUote',
                    new SamsaraLoggerObjectMVP(
                            ex,
                            ar.Params__c.split(PARAMETERS_SPLITTER)
                    )
            );
            throw ex;
        }
        finally {
            thisLoggerService.logger.dispatch();
        }

    }

    public class AsyncSBQQQuoteFromOpportunityService implements IService{
        List<Schema.SObjectType> sObjectTypesSequence = new List<Schema.SObjectType> {
                SBQQ__Quote__c.SObjectType
        };
        List<Id> recordsIds = new List<Id>();
        public void updateQuotes(Async_Request__c ar){
            DMLWrapper.intializeUnitOfWork(sObjectTypesSequence);
            recordsIds = ar.Params__c.split(BaseAsyncHandler.PARAMETERS_SPLITTER);
            Map<Id, Opportunity> mapOfOpportunities = new Map<Id, Opportunity>(getOpportunityFromIds(recordsIds));
            Map<Id, SBQQ__Quote__c> quotesByIds = new  Map<Id, SBQQ__Quote__c>(getQuotesFromOppIds(recordsIds));
            new GS_SBQQQuoteUpdationService().updateSBQQQuotesFromOpportunity(mapOfOpportunities, quotesByIds);
            DMLWrapper.publishDML();
        }

        @TestVisible
        private List<SBQQ__Quote__c> getQuotesFromOppIds(List<Id> ids) {
            return new GS_SBQQQuoteSelector(true)
                    .checkFatalError()
                    .getQuoteFromOpportunityIds(new Set<Id>(ids));
        }

        @TestVisible
        private List<Opportunity> getOpportunityFromIds(List<Id> ids) {
            return new GS_OpportunitySelector(true)
                    .checkFatalError()
                    .getOpportunityFromIds(new Set<Id>(ids));
        }
    }

    public interface IService{
        void updateQuotes(Async_Request__c ar);
    }

}
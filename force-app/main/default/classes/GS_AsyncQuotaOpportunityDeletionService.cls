/**
 * Created by vikasmishra on 2021-09-16.
 */

public with sharing class GS_AsyncQuotaOpportunityDeletionService extends BaseAsyncHandler{

    SamsaraLoggerService thisLoggerService = new SamsaraLoggerService();
    public override String getRequestType() {
        return 'Delete Quota Opportunity';
    }

    public override void execute(Async_Request__c ar) {
        try{
            new AsyncQuotaOpportunityDeletionService().deleteRelatedQuotaOpportunities(ar);
        }
        catch(Exception ex){
            thisLoggerService.logger.logError(
                    'Unable to process Quota Opportunity for Job# ::'+ ar.Id,
                    new SamsaraLoggerObjectMVP(ex, ar.Params__c.split(PARAMETERS_SPLITTER))
            );
            throw ex;
        }
        finally {
            thisLoggerService.logger.dispatch();
        }
    }

    public class AsyncQuotaOpportunityDeletionService implements IService{
        List<Schema.SObjectType> sObjectTypesSequence = new List<Schema.SObjectType>{
                Quota_Opportunity__c.SObjectType
        };
        List<Id> recordsIds = new List<Id>();
        public void deleteRelatedQuotaOpportunities(Async_Request__c ar) {
            DMLWrapper.intializeUnitOfWork(sObjectTypesSequence);
            recordsIds = ar.Params__c.split(BaseAsyncHandler.PARAMETERS_SPLITTER);
            Map<Id, Quota_Opportunity__c> quotaOpportunitiesByIds = new Map<Id, Quota_Opportunity__c>(getQuotaOpportunitiesFromOppIds(recordsIds));
            new GS_QuotaOpportunityService().processQuotaOpportunityDeletion(quotaOpportunitiesByIds);
            DMLWrapper.publishDML();
        }

        @TestVisible
        private List<Quota_Opportunity__c> getQuotaOpportunitiesFromOppIds(List<Id> ids) {
            return new GS_QuotaOpportunitySelector(true)
                    .checkFatalError()
                    .getQuotaOpportunitiesFromOpportunityIds(new Set<Id>(ids));

        }
    }

    public interface IService{
        void deleteRelatedQuotaOpportunities(Async_Request__c ar);
    }

}
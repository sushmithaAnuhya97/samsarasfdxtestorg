/**
 * Created by vikasmishra on 2021-09-21.
 */

public with sharing class GS_AsyncDisconnectTrialOppService extends BaseAsyncHandler{
    SamsaraLoggerService thisLoggerService = new SamsaraLoggerService();
    public override String getRequestType() {
    return 'Trial Opportunity Disconnections';
    }

    public override void execute(Async_Request__c ar) {
        try{
            new AsyncDisconnectTrialOppService().updateDisconnectionsForTrials(ar);
        }
        catch(Exception ex){
            thisLoggerService.logger.logError(
                    'Unable to process Trail Opportunity for disconnections for Job# ::'+ ar.Id,
                    new SamsaraLoggerObjectMVP(ex, ar.Params__c?.split(PARAMETERS_SPLITTER))
            );
            throw ex;
        }
        finally {
            thisLoggerService.logger.dispatch();
        }
    }

    public class AsyncDisconnectTrialOppService implements IService{
        List<Schema.SObjectType> sObjectTypesSequence = new List<Schema.SObjectType>{
                Opportunity.SObjectType
        };
        List<Id> recordsIds = new List<Id>();
        public void updateDisconnectionsForTrials(Async_Request__c ar) {
            DMLWrapper.intializeUnitOfWork(sObjectTypesSequence);
            recordsIds = ar.Params__c?.split(BaseAsyncHandler.PARAMETERS_SPLITTER);
            new GS_DisconnectTrialOppService().updateDisconnectionsForTrials(
                    new Map<Id, Opportunity>(
                            new GS_OpportunitySelector(true)
                                    .checkFatalError()
                                    .getTrialOpportunitiesFromTrialResolutionIds(new Set<Id>(recordsIds))
                    )
            );
            DMLWrapper.publishDML();
        }
    }
    public interface IService{
        void updateDisconnectionsForTrials(Async_Request__c ar);
    }
}
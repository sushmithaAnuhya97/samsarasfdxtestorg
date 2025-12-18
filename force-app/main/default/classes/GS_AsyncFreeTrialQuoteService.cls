/**
 * Created by vikasmishra on 2021-09-15.
 */

public with sharing class GS_AsyncFreeTrialQuoteService extends BaseAsyncHandler {

    SamsaraLoggerService thisLoggerService = new SamsaraLoggerService();


    public override String getRequestType(){
        return 'Create Free Trial Quote';
    }

    public override void execute(Async_Request__c ar) {
        try{
            new AsyncFreeTrialQuoteService().processQuoteAndQuoteLine(ar);
        }
        catch (Exception ex){
            thisLoggerService.logger.logError('Failed to create Trial Quote for following job::'+ ar.Id, new SamsaraLoggerObjectMVP(ex, ar.Params__c?.split(PARAMETERS_SPLITTER)));
            throw ex;
        }
        finally {
            thisLoggerService.logger.dispatch();
        }

    }


    public class AsyncFreeTrialQuoteService implements IService{
        @TestVisible
        GS_FreeTrialQuoteCreatorService.IService thisGS_FreeTrialQuoteCreatorService = new GS_FreeTrialQuoteCreatorService();
        List<Schema.SObjectType> sObjectTypesSequence = new List<Schema.SObjectType> {
                Quote.SObjectType,
                QuoteLineItem.SObjectType,
                QuoteDocument.SObjectType
        };
        List<Id> recordsIds = new List<Id>();

        public void processQuoteAndQuoteLine(Async_Request__c ar){
            DMLWrapper.intializeUnitOfWork(sObjectTypesSequence);
            recordsIds = ar.Params__c?.split(BaseAsyncHandler.PARAMETERS_SPLITTER);
            Map<Id, Opportunity> mapOfOpportunities = getOpportunityMapFromIds();
            Map<Id, List<OpportunityLineItem>> OppLineItemMapPerOpp = getOppLineItemMapPerOpp();
            System.debug('recordsIds****'+recordsIds);
            GS_FreeTrialQuoteCreatorService.QuoteCreator thisQuoteCreator =
                    new GS_FreeTrialQuoteCreatorService.QuoteCreator(
                            mapOfOpportunities,
                            OppLineItemMapPerOpp
                    );
            thisGS_FreeTrialQuoteCreatorService.CreateFreeTrialQuoteAndQuoteLine(thisQuoteCreator);
            DMLWrapper.publishDML();
            DMLWrapper.intializeUnitOfWork(sObjectTypesSequence);
            registerEmailContent(thisQuoteCreator);
            DMLWrapper.publishDML();
        }

        @TestVisible
        private void registerEmailContent(GS_FreeTrialQuoteCreatorService.QuoteCreator thisQuoteCreator){
            for(String opportunityId : thisQuoteCreator.thisDocumentCreator.getMapOfQuoteDocument().keySet()){
                if(thisQuoteCreator.mapOfEmailPerOpportunity.containsKey(opportunityId)){
                    Messaging.SingleEmailMessage email = thisQuoteCreator.mapOfEmailPerOpportunity.get(opportunityId);
                    Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                    attach.setContentType('application/pdf');
                    attach.setFileName('SamsaraTrialInvoice.pdf');
                    attach.setInline(false);
                    attach.body = thisQuoteCreator.thisDocumentCreator.getMapOfQuoteDocument().get(opportunityId).Document;
                    email.setFileAttachments(new Messaging.EmailFileAttachment[] { attach });
                    DMLWrapper.uow.registerEmail(email);
                }

            }
        }
        public void createFreeTrialQuoteFromOpportunities(){
            GS_FreeTrialQuoteCreatorService.QuoteCreator thisQuoteCreator =
                    new GS_FreeTrialQuoteCreatorService.QuoteCreator(
                            getOpportunityMapFromIds(),
                            getOppLineItemMapPerOpp()
                    );
            thisGS_FreeTrialQuoteCreatorService.CreateFreeTrialQuoteAndQuoteLine(thisQuoteCreator);
        }

        private Map<Id, List<OpportunityLineItem>> getOppLineItemMapPerOpp() {
            Map<Id, List<OpportunityLineItem>> mapOfOppLineWithOpp = new  Map<Id, List<OpportunityLineItem>>();
            for( OpportunityLineItem oppLineItem : new GS_OpportunityLineItemSelector(true)
                    .checkFatalError()
                    .getOpportunityLineItemByOpportunityIds(new Set<Id>(recordsIds))){

                if(!mapOfOppLineWithOpp.containsKey(oppLineItem.OpportunityId)){
                    mapOfOppLineWithOpp.put(oppLineItem.OpportunityId, new List<OpportunityLineItem>());
                }
                mapOfOppLineWithOpp.get(oppLineItem.OpportunityId).add(oppLineItem);

            }
            return mapOfOppLineWithOpp;
        }

        private Map<Id, Opportunity> getOpportunityMapFromIds() {
            return new GS_OpportunitySelector(true)
                    .checkFatalError()
                    .getOpportunityMapFromIds(new Set<Id>(recordsIds));
        }
    }

    public interface IService{
         void processQuoteAndQuoteLine(Async_Request__c ar);
         void createFreeTrialQuoteFromOpportunities();
    }




}
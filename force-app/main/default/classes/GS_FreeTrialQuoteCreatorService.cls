/**
 * Created by vikasmishra on 2021-09-15.
 */

public with sharing class GS_FreeTrialQuoteCreatorService implements IService{


    SamsaraLoggerService thisLoggerService = new SamsaraLoggerService();
    public Set<Id> targetOpportunityIdsForFreeTrialCreation = new Set<Id>();
    @TestVisible
    Boolean transactionTypeAsync = true;

    //TODO: Can be moved to Sync if needed but small dev work needed
    @TestVisible
    private void shouldProcessInSync(){
        transactionTypeAsync = false;
    }
    public void CreateFreeTrialQuoteAndQuoteLine(QuoteCreator thisQuoteCreator){
        thisQuoteCreator.thisDocumentCreator = new GS_QuoteDocumentCreator();
        DMLWrapper.uow.registerWork(thisQuoteCreator.thisDocumentCreator);
        thisQuoteCreator.createQuotesAndLineItems();
    }
    public void createFreeTrialQuoteFromOpportunities(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOppList){
        processFreeTrialQuoteFromOpportunities(oldOppMap, newOppList);
        if(transactionTypeAsync){
            invokeAsyncFreeTrialQuoteCreationProcess();
        }
        else{
            invokeFreeTrialQuoteCreationProcess();
        }

    }

    public void processFreeTrialQuoteFromOpportunities(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOppList){
        Boolean isUpdate = oldOppMap != null && !oldOppMap.isEmpty();
        for(Opportunity thisOpp : newOppList){
            Opportunity oldOpp;
            if(isUpdate){
                if(oldOppMap.containsKey(thisOpp.Id)){
                    oldOpp = oldOppMap.get(thisOpp.Id);
                }
                else{
                    throw new freeTrialQuoteException('No element found in old Map.');
                }
            }
            else {
                throw new freeTrialQuoteException('Old Map is null. This method is only getting called in After Update Context.');
            }
            if (ShouldCreateFreeTrialQuote(thisOpp, oldOpp)){
                collectTargetOpportunityIds(thisOpp);
                }
        }
    }

    private Boolean ShouldCreateFreeTrialQuote(Opportunity newOpp, Opportunity oldOpp) {
       return  newOpp.Type == 'Free Trial Opportunity'
               && newOpp.Send_Invoice__c == true
               && oldOpp.Send_Invoice__c != newOpp.Send_Invoice__c;
    }

    private void collectTargetOpportunityIds(Opportunity thisOpp) {
        targetOpportunityIdsForFreeTrialCreation.add(thisOpp.Id);
    }

    private void invokeAsyncFreeTrialQuoteCreationProcess(){
        DMLWrapper.doInsert (
                (List<SObject>) new GS_AsyncFreeTrialQuoteService()
                        .prepareAsyncRequests(
                        targetOpportunityIdsForFreeTrialCreation
                )
        );
    }

    private void invokeFreeTrialQuoteCreationProcess() {

    }

    public class QuoteCreator implements IInternalService{
        public Map<Id,Opportunity> opportunitiesMap = new Map<Id,Opportunity>();
        public Map<Id, List<OpportunityLineItem>> mapOfOppLineItemsAndOpp = new Map<Id, List<OpportunityLineItem>>();
        public GS_QuoteDocumentCreator thisDocumentCreator = new GS_QuoteDocumentCreator();
        public Map<Id, Messaging.SingleEmailMessage> mapOfEmailPerOpportunity = new  Map<Id, Messaging.SingleEmailMessage>();
        public QuoteCreator (Map<Id,Opportunity> opportunities, Map<Id, List<OpportunityLineItem>> mapOfOppLineItemsAndOpp){
            this.opportunitiesMap = opportunities;
            this.mapOfOppLineItemsAndOpp = mapOfOppLineItemsAndOpp;
        }

        public void createQuotesAndLineItems(){
            for (Opportunity thisOpp : this.opportunitiesMap.values()) {

                Quote thisQuote = setQuoteForCreation(thisOpp);
                DMLWrapper.doInsert(thisQuote);
                setQuoteLineItemsForCreation(thisQuote);
                thisDocumentCreator.register_QuoteDocument(thisQuote);
                //generateQuoteDocument(thisQuote);
                mapOfEmailPerOpportunity.put(thisOpp.Id, setUpEmailMessageForFreeTrialInvoicing(thisQuote, thisOpp, null));
            }
        }

        private Messaging.SingleEmailMessage setUpEmailMessageForFreeTrialInvoicing(Quote thisQuote, Opportunity thisOpp, Blob body) {
            return new GS_FreeTrialInvoicingEmailService().getEmailMessage(thisQuote, thisOpp, body);
        }

        private void setQuoteLineItemsForCreation(Quote thisQuote) {
            if(! mapOfOppLineItemsAndOpp.containsKey(thisQuote.OpportunityId)){
                new SamsaraLoggerService().logger.logWarning(
                        'No OpportunityLineItem Found Corresponding to this Opportunity:' + thisQuote.OpportunityId,
                        opportunitiesMap.get(thisQuote.OpportunityId)
                );
               return;
            }
            for (OpportunityLineItem oppLineItem : mapOfOppLineItemsAndOpp.get(thisQuote.OpportunityId)) {
                    QuoteLineItem lineItem = new QuoteLineItem();
                    lineItem.QuoteId = thisQuote.Id;
                    lineItem.Quantity = oppLineItem.Quantity;
                    lineItem.UnitPrice = oppLineItem.UnitPrice;
                    lineItem.Discount = oppLineItem.Discount;
                    lineItem.PricebookEntryId = oppLineItem.PricebookEntryId;
                    DMLWrapper.doInsert(lineItem, QuoteLineItem.QuoteId, thisQuote);
            }
        }

        private Quote setQuoteForCreation(Opportunity thisOpp) {
            Quote thisQuote = new Quote();
            thisQuote.Name = 'FT Quote-' + thisOpp.Name;
            thisQuote.OpportunityId = thisOpp.Id;
            thisQuote.Pricebook2Id = thisOpp.Pricebook2Id;
            thisQuote.ContactId = thisOpp.Trial_Primary_Contact__c;
            thisQuote.BillingName = thisOpp.Account.Name;
            thisQuote.Email = thisOpp.Account.Billing_Email__c;
            return thisQuote;
        }

    }
    public interface IService{
        void CreateFreeTrialQuoteAndQuoteLine(QuoteCreator thisQuoteCreator);
        void createFreeTrialQuoteFromOpportunities(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOppList);
        void processFreeTrialQuoteFromOpportunities(Map<Id, Opportunity> oldOppMap, List<Opportunity> newOppList);
    }

    public interface IInternalService{
        void createQuotesAndLineItems();
    }
    public class freeTrialQuoteException extends Exception{

    }


}
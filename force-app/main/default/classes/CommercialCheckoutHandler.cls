public class CommercialCheckoutHandler extends OrderTransactionHandler {
    
    @TestVisible
    protected override Boolean isOrderValid(Request_Tracker__c tracker) {
        return true;
    }
    
    @TestVisible
    protected override void processTransaction(Request_Tracker__c tracker) {
        OrderPayload payload = CommercialCheckoutHandler.deserializePayload(tracker.Request__c);
        tracker.Opportunity_Id__c = payload?.opportunity?.Id;
        
        InsertShippingAddress insertShippingAddress = new InsertShippingAddress(tracker, 'Step-2',payload, 0);
        CommercialCheckoutAccountUpdate commercialCheckoutAccountUpdate = new CommercialCheckoutAccountUpdate(tracker,'Step-3',payload,0);
        CommercialCheckoutOpportunityUpdate commercialCheckoutOpportunityUpdate = new CommercialCheckoutOpportunityUpdate(tracker,'Step-4',payload,0);
        CommercialCheckoutQuoteUpdate commercialCheckoutQuoteUpdate = new CommercialCheckoutQuoteUpdate(tracker,'Step-5',payload,0);
        QuoteRecalculationJob quoteRecalculationJob = new QuoteRecalculationJob(tracker, 'Step-6',payload, 0);
        OrderResultToWorkatoService orderResultToWorkatoService = new OrderResultToWorkatoService(tracker, 'Step-7',payload,0);
        
        // Chain the jobs in the correct order
        insertShippingAddress.setNextJob(commercialCheckoutAccountUpdate);
        commercialCheckoutAccountUpdate.setNextJob(commercialCheckoutOpportunityUpdate);
        commercialCheckoutOpportunityUpdate.setNextJob(commercialCheckoutQuoteUpdate);
        commercialCheckoutQuoteUpdate.setNextJob(quoteRecalculationJob);
        quoteRecalculationJob.setNextJob(orderResultToWorkatoService);
        
        // Enqueue the first job in the chain using the existing method in QueueableChainJob
        OrderUtil.enqueueJobIfPossible(insertShippingAddress);
    }
    
    private static OrderPayload deserializePayload(String originalPayload) {
        return OrderProcessorSingleton.getInstance().deserializePayload(originalPayload); 
    }
}
public class DigitalRenewalCheckoutHandler extends OrderTransactionHandler {
    
    protected override Boolean isOrderValid(Request_Tracker__c tracker) {
        return true;
    }
    
    protected override void processTransaction(Request_Tracker__c tracker) {
        OrderPayload payload = DigitalRenewalCheckoutHandler.deserializePayload(tracker.Request__c); 
        tracker.Opportunity_Id__c = payload?.opportunity?.Id;
        
        InsertShippingAddress insertShippingAddress = new InsertShippingAddress(tracker, 'Step-2',payload, 0);
        DigitalRenewalAccountUpdate digitalRenewalAccountUpdate = new DigitalRenewalAccountUpdate(tracker,'Step-3',payload,0);
        DigitalRenewalOpportunityUpdate digitalRenewalOpportunityUpdate = new DigitalRenewalOpportunityUpdate(tracker,'Step-4',payload,0);
        DigitalRenewalQuoteUpdate digitalRenewalQuoteUpdate = new DigitalRenewalQuoteUpdate(tracker,'Step-5',payload,2);
        QuoteRecalculationJob quoteRecalculationJob = new QuoteRecalculationJob(tracker, 'Step-6',payload, 0);
        OrderResultToWorkatoService orderResultToWorkatoService = new OrderResultToWorkatoService(tracker, 'Step-7',payload,0);
        
        // Chain the jobs in the correct order
        insertShippingAddress.setNextJob(digitalRenewalAccountUpdate);
        digitalRenewalAccountUpdate.setNextJob(digitalRenewalOpportunityUpdate);
        digitalRenewalOpportunityUpdate.setNextJob(digitalRenewalQuoteUpdate);
        digitalRenewalQuoteUpdate.setNextJob(quoteRecalculationJob);
        quoteRecalculationJob.setNextJob(orderResultToWorkatoService);
        
        // Enqueue the first job in the chain using the existing method in QueueableChainJob
        OrderUtil.enqueueJobIfPossible(insertShippingAddress);
    }

    private static OrderPayload deserializePayload(String originalPayload) {
        return OrderProcessorSingleton.getInstance().deserializePayload(originalPayload);
    }
}
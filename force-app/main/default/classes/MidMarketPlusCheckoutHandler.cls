public class MidMarketPlusCheckoutHandler extends OrderTransactionHandler {
    
    protected override Boolean isOrderValid(Request_Tracker__c tracker) {
        return true;
    }
    
    protected override void processTransaction(Request_Tracker__c tracker) {
        OrderPayload payload = deserializePayload(tracker.Request__c); 
        tracker.Opportunity_Id__c = payload?.opportunity?.Id;
        
        InsertShippingAddress insertShippingAddress = new InsertShippingAddress(tracker, 'Step-2',payload, 0);
        //UpdateAccount updateAccount = new UpdateAccount(tracker,'Step-3',payload,0);
        MidMarketCheckoutOpportunityUpdate midMarketCheckoutOpportunityUpdate = new MidMarketCheckoutOpportunityUpdate(tracker,'Step-3',payload,0);
        MidMarketCheckoutQuoteUpdate midMarketCheckoutQuoteUpdate = new MidMarketCheckoutQuoteUpdate(tracker,'Step-4',payload,0);
        OrderResultToWorkatoService orderResultToWorkatoService = new OrderResultToWorkatoService(tracker, 'Step-5',payload,0); 
        
        // Chain the jobs in the correct order
        insertShippingAddress.setNextJob(midMarketCheckoutOpportunityUpdate);
        //updateAccount.setNextJob(midMarketCheckoutOpportunityUpdate);
        midMarketCheckoutOpportunityUpdate.setNextJob(midMarketCheckoutQuoteUpdate);
        midMarketCheckoutQuoteUpdate.setNextJob(orderResultToWorkatoService);
        
        // Enqueue the first job in the chain using the existing method in QueueableChainJob
        OrderUtil.enqueueJobIfPossible(insertShippingAddress);
    }

    private static OrderPayload deserializePayload(String originalPayload) {
        return OrderProcessorSingleton.getInstance().deserializePayload(originalPayload);
    }
}
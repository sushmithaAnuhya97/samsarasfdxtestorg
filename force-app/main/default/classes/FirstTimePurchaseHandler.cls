public class FirstTimePurchaseHandler extends OrderTransactionHandler {

    @TestVisible
    protected override Boolean isOrderValid(Request_Tracker__c tracker) {
        return true; // Additional validation can be added if needed
    }

    @TestVisible
    protected override void processTransaction(Request_Tracker__c tracker) {
        OrderPayload payload = OrderProcessorSingleton.getInstance().deserializePayload(tracker.Request__c);
        Request_Tracker__c requestTracker = new Request_Tracker__c(Id=tracker.Id,Request__c = tracker.Request__c,Transaction_Type__c=tracker.Transaction_Type__c);
        
        // Create instances of queueable jobs
        InsertShippingAddress insertShippingAddress = new InsertShippingAddress(requestTracker, 'Step-2',payload, 0);
        FirstTimePurchaseAccountUpdate firstTimePurchaseAccountUpdate = new FirstTimePurchaseAccountUpdate(requestTracker, 'Step-3',payload, 0);
        InsertOpportunity insertOpportunity = new InsertOpportunity(requestTracker, 'Step-4',payload, 0);
        InsertQuote insertQuote = new InsertQuote(requestTracker, 'Step-5',payload, 0);
        InsertQuoteLines insertQuoteLines = new InsertQuoteLines(payload, 'Step-6',requestTracker, 0);
        QuoteRecalculationJob quoteRecalculationJob = new QuoteRecalculationJob(requestTracker, 'Step-7',payload, 0);
        OrderResultToWorkatoService orderResultToWorkatoService = new OrderResultToWorkatoService(requestTracker, 'Step-8',payload, 0);

        // Chain the jobs together
        insertShippingAddress.setNextJob(firstTimePurchaseAccountUpdate); 
        firstTimePurchaseAccountUpdate.setNextJob(insertOpportunity);
        insertOpportunity.setNextJob(insertQuote);
        insertQuote.setNextJob(insertQuoteLines); 
        insertQuoteLines.setNextJob(quoteRecalculationJob); 
        quoteRecalculationJob.setNextJob(orderResultToWorkatoService); 

        // Enqueue the first job in the chain using the existing method in QueueableChainJob
        OrderUtil.enqueueJobIfPossible(insertShippingAddress);
    }
}
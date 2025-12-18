public class FreeTrialHandler extends OrderTransactionHandler {
    
    @TestVisible
    protected override Boolean isOrderValid(Request_Tracker__c tracker) {
        try {
            // Deserialize and validate payload
            OrderPayload payload = OrderProcessorSingleton.getInstance().deserializePayload(tracker?.Request__c);
                        
            // Validate opportunity exists
            if (OrderProcessorSingleton.getInstance().queryOpportunity(payload.opportunity?.trialResolutionOppty) == null) {
                logError(tracker, 'Revenue Opportunity with Id ' + payload.opportunity?.trialResolutionOppty + ' not found');
                System.enqueueJob(new OrderErrorResultToWorkato(tracker,OrderUtil.STEP_1,'Revenue Opportunity with Id ' + payload.opportunity?.trialResolutionOppty + ' not found'));
                return false;
            }
            
            // Log success
            logSuccess(tracker);
            return true;
            
        } catch (Exception e) {
            logException(tracker, e);
            return false;
        }
    }
    
    /**
     * @description Log error message
     */
    private void logError(Request_Tracker__c tracker, String errorMessage) {
        Orderutil.logJob(
            tracker,
            OrderUtil.STEP_1 + ': Error',
            errorMessage + '. Cannot proceed with free trial order. Request Tracker Id: ' + tracker.Id + ' at: ' + DateTime.now(),
            DateTime.now(),
            DateTime.now(),
            true
        );
    }
    
    /**
     * @description Log success message
     */
    private void logSuccess(Request_Tracker__c tracker) {
        Orderutil.logJob(
            tracker,
            OrderUtil.STEP_1 + ': Validation Success',
            'Payload validation completed successfully. Request Tracker Id: ' + tracker.Id + ' at: ' + DateTime.now(),
            DateTime.now(),
            DateTime.now(),
            false
        );
    }
    
    /**
     * @description Log exception
     */
    private void logException(Request_Tracker__c tracker, Exception e) {
        Orderutil.logJob(
            tracker,
            OrderUtil.STEP_1 + ': Validation Exception',
            'Unexpected error during payload validation: ' + e.getMessage() + '\nStack Trace: ' + e.getStackTraceString() + '\nRequest Tracker Id: ' + tracker.Id + ' at: ' + DateTime.now(),
            DateTime.now(),
            DateTime.now(),
            true
        );
    }
    
    @TestVisible
    protected override void processTransaction(Request_Tracker__c tracker) {
        OrderPayload payload = FreeTrialHandler.deserializePayload(tracker?.Request__c);
        
        // Create instances of queueable jobs in the required order
        InsertShippingAddress insertShippingAddress = new InsertShippingAddress(tracker, 'Step-2', payload, 0);
        //FreeTrialAccountUpdate freeTrialAccountUpdate = new FreeTrialAccountUpdate(tracker, 'Step-3', payload, 0);
        FreeTrialOpportunityInsert freeTrialOpportunityInsert = new FreeTrialOpportunityInsert(tracker, 'Step-3', payload, 0);
        InsertFreeTrialQuoteJob insertFreeTrialQuoteJob = new InsertFreeTrialQuoteJob(tracker, 'Step-4', payload, 0);
        InsertFreeTrialQuoteLineJob insertFreeTrialQuoteLineJob = new InsertFreeTrialQuoteLineJob(tracker, 'Step-5', payload, 0);
        FreeTrialQuoteRecalculationJob freeTrialQuoteRecalculationJob = new FreeTrialQuoteRecalculationJob(tracker, 'Step-6', payload, 0);
        ///RevenueOpportunityUpdateJob revenueOpportunityUpdateJob = new RevenueOpportunityUpdateJob(tracker, 'Step-7', payload, 0);
        OrderResultToWorkatoService orderResultToWorkatoService = new OrderResultToWorkatoService(tracker, 'Step-6', payload, 0);

        // Chain the jobs together in the correct order
        //insertShippingAddress.setNextJob(freeTrialAccountUpdate);
        //freeTrialAccountUpdate.setNextJob(freeTrialOpportunityInsert);
        
        // Chain the jobs together in the correct order
        insertShippingAddress.setNextJob(freeTrialOpportunityInsert);
        freeTrialOpportunityInsert.setNextJob(insertFreeTrialQuoteJob);
        insertFreeTrialQuoteJob.setNextJob(insertFreeTrialQuoteLineJob);
        insertFreeTrialQuoteLineJob.setNextJob(freeTrialQuoteRecalculationJob);
        freeTrialQuoteRecalculationJob.setNextJob(orderResultToWorkatoService);
        //revenueOpportunityUpdateJob.setNextJob(orderResultToWorkatoService);
        

        // Enqueue the first job in the chain using the existing method in QueueableChainJob
        OrderUtil.enqueueJobIfPossible(insertShippingAddress);
    }
    
    private static OrderPayload deserializePayload(String originalPayload) {
        return OrderProcessorSingleton.getInstance().deserializePayload(originalPayload);
    }
}
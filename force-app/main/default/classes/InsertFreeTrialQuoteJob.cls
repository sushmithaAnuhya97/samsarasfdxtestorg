public with sharing class InsertFreeTrialQuoteJob extends QueueableChainJob {
    private Request_Tracker__c tracker;
    private OrderPayload payload;
    private String stepStatus;
    
    public InsertFreeTrialQuoteJob(Request_Tracker__c tracker, String stepStatus, OrderPayload payload, Integer retryCount) {
        super(retryCount, stepStatus, tracker);
        this.tracker = tracker;
        this.payload = payload;
        this.stepStatus = stepStatus;
    }
    
    public override void processJob() {
        try {
            createLog('Started processing: Insert Free Trial Quote Job.');
            OrderUtil.initializeUnitOfWork();
            
            // Validate opportunity ID from tracker
            if (String.isBlank(tracker?.Opportunity_Id__c)) {
                throw new RequestTrackerException('Opportunity ID is missing in tracker. Cannot proceed with free trial quote insertion.');
            }
            
            // Get the opportunity
            Opportunity opportunity = OrderProcessorSingleton.getInstance().queryOpportunity(tracker.Opportunity_Id__c);
            if (opportunity == null) {
                throw new RequestTrackerException('Opportunity not found with ID: ' + tracker.Opportunity_Id__c);
            }
            
            // Create free trial quote
            SBQQ__Quote__c freeTrialQuote = JsonToSFDCMapper.mapFreeTrialQuoteData(payload);

            if (freeTrialQuote == null) {
                throw new RequestTrackerException('Mapped Quote payload is invalid.');
            }
            
            freeTrialQuote.Shipping_Address_NEW__c = tracker.Shipping_Address_Id__c;
            freeTrialQuote.SBQQ__Opportunity2__c=tracker.Opportunity_Id__c;
            
            DMLWrapper.doInsert(freeTrialQuote);
        
            DMLWrapper.publishDML();
            
            // Update tracker with quote ID
            tracker.Quote_Id__c = freeTrialQuote?.Id;
            
            createLog('Finished processing: Insert Free Trial Quote. Quote ID: ' + freeTrialQuote.Id);
        } catch (RequestTrackerException e) {
            throw e;
        }catch (Exception e) {
            throw new RequestTrackerException('Insert Free Trial Quote Job Failed.retryCount:'+retryCount + 'Error Body:' + JSON.serialize(e.getMessage()));
        }
    }
    
    @TestVisible
    protected override Queueable newInstanceWithRetry(Integer retryCount) {
        return new InsertFreeTrialQuoteJob(tracker, stepStatus, payload, retryCount);
    }
    
    private void createLog(String logMessage) {
        DateTime now = DateTime.now();
        transactionFinalizer.createLog(stepStatus + ': Info', logMessage, now, now);
    }
}
public class FreeTrialQuoteRecalculationJob extends QueueableChainJob {
    
    private Request_Tracker__c tracker;
    private OrderPayload payload;
    

    public FreeTrialQuoteRecalculationJob(Request_Tracker__c tracker, String stepStatus, OrderPayload payload, Integer retryCount) {
        super(retryCount, stepStatus, tracker);
        this.tracker = tracker;
        this.payload = payload;
        System.debug('FreeTrial payload: '+ JSON.serializePretty(payload));
    }
    
    public override void processJob() {
        createLog('Starting: Free Trial Quote Recalculation Job.'); 
        processMappingAndDML();
    }

    private void processMappingAndDML() {        
        //Method-1: caused by: System.AsyncException: hasMaxStackDepth is not allowed outside a Queueable of Finalizer execution
        //SBQQ__Quote__c quote = new SBQQ__Quote__c(Id=tracker.Quote_Id__c, Recalculate_Quote__c =true);
        //UPDATE quote;
        
        //Method-2: caused by: System.AsyncException: hasMaxStackDepth is not allowed outside a Queueable of Finalizer execution
        //SBQQ__Quote__c quote = new SBQQ__Quote__c(Id=tracker.Quote_Id__c, SBQQ__Primary__c=true);
        //update quote;
        
        //Method-3: Recalculates the quote correctly, but not syncing the Quote lines to Opportunity Products.(3 API calls with huge payload - Not recommanded approach - serialization/deserialization takes more time)
        //new QuoteCalculator().calculate(new QuoteReader().read(tracker.Quote_Id__c), 'QuoteAmenderCallback');
        
        //Method-4
        updateQuoteViaRest(tracker?.Quote_Id__c);
    }

    public void updateQuoteViaRest(String quoteId) {
        String endpoint = System.Url.getOrgDomainUrl().toExternalForm() + orderProcessingSettings?.Quote_Endpoint__c + quoteId;
		createLog('Free Trial Quote Endpoint:'+endpoint);
        
        Map<String, Object> body = new Map<String, Object>{
            'SBQQ__Primary__c' => true
        };
        String jsonBody = JSON.serialize(body);
		createLog('Free Trial Quote Recalculation:'+jsonBody);
        
        // Setup HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('PATCH');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId()); // Only works internally
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000); //Default timeout is 10 seconds; customizable per callout (1 ms to 120,000 ms range).
        req.setBody(jsonBody);

        // Send request
        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
            createLog('Free Trial Quote updated successfully via REST API. Status Code:' + res.getStatusCode() + ', Status:'+res.getStatus()+ ', Response Body:' + res.getBody());
        } else {
            createLog('Free Trial Quote Recalculation Job Failed.RetryCount '+retryCount+', Status Code:' + res.getStatusCode() + ', Status:'+res.getStatus()+ ', Response Body:' + res.getBody());
            throw new RequestTrackerException('Free Trial Quote Recalculation Job Failed.retryCount:'+retryCount + 'Error Body:' + JSON.serialize(res.getBody()));
        }
    }
    
    @TestVisible
    protected override Queueable newInstanceWithRetry(Integer retryCount) {
        return new FreeTrialQuoteRecalculationJob(tracker, stepStatus, payload, retryCount);
    }

    private void createLog(String logMessage) {
        transactionFinalizer.createLog(stepStatus + ': Info', logMessage, DateTime.now(), DateTime.now());
    }
}
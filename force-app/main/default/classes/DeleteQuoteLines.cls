public class DeleteQuoteLines extends QueueableChainJob {
    
    private String stepStatus;
    private final Request_Tracker__c tracker;
    private final OrderPayload originalPayload;
    
    public DeleteQuoteLines(OrderPayload originalPayload, String stepStatus,Request_Tracker__c tracker, Integer retryCount) {
        super(retryCount, stepStatus,tracker);
        this.tracker = tracker;
        this.stepStatus=stepStatus;
        this.originalPayload = originalPayload;
    }
    
    public override void processJob() {
         createLog('Started processing: Delete QuoteLines Job.Quote ID:'+tracker?.Quote_Id__c);
        //Approach-1: caused by: System.AsyncException: hasMaxStackDepth is not allowed outside a Queueable of Finalizer executions
        Orderutil.initializeUnitOfWork();
        
        if (String.isBlank(tracker?.Quote_Id__c)) {
       		throw new RequestTrackerException('Invalid QuoteId provided.');
        }
        
        //Each webstore order quote must not exceed 200 quote lines.
        List<SBQQ__QuoteLine__c> quoteLinesToDelete = OrderProcessorSingleton.queryQuoteLines(tracker?.Quote_Id__c);
        if(quoteLinesToDelete!=null && !quoteLinesToDelete.isEmpty()){
        	DMLWrapper.doDelete(quoteLinesToDelete);
        	createLog('Deleted QuoteLines for the CPQ Quote:'+tracker.Quote_Id__c);
        }
        
        createLog('QuoteLineItems to delete:'+quoteLinesToDelete); 
        OrderUtil.disableTriggers();
        SBQQ.TriggerControl.disable();
        DMLWrapper.publishDML();
        SBQQ.TriggerControl.enable();
        OrderUtil.enableTriggers(); 
        createLog('Successfully executed logic to delete the QuoteLines in the Amendment flow.'); 
        
        //Approach-2:
        //deleteQuoteLinesByQuoteId(tracker.Quote_Id__c); 
        
        /* Approach-3: Success. Limitation: Need to think about large number of quote lines pass in the URL
        List<SBQQ__QuoteLine__c> quoteLines = OrderProcessorSingleton.queryQuoteLines(tracker.Quote_Id__c);
        List<Id> childRecordIds = new List<Id>();
        for(SBQQ__QuoteLine__c quoteLine:quoteLines){
            childRecordIds.add(quoteLine.Id);
        }
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        // Construct the endpoint URL
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        String idsParam = String.join(childRecordIds, ',');
        String endpoint = baseUrl + '/services/data/v63.0/composite/sobjects?ids=' + idsParam + '&allOrNone=false';
        
        request.setEndpoint(endpoint);
        request.setMethod('DELETE');
        request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId()); // For production, use Named Credentials
        request.setHeader('Content-Type', 'application/json');
        
        HttpResponse response = http.send(request);
        
        if (response.getStatusCode() == 200) {
            System.debug('Child records deleted successfully.');
        } else {
            System.debug('Failed to delete records: ' + response.getBody());
        }
        
        //Approach-4: Success
        DeleteRecordsBatch deleteRecordsBatch = new DeleteRecordsBatch(tracker);
		Id jobId = Database.executeBatch(deleteRecordsBatch);
        createLog('Successfully executed logic to delete the QuoteLines in the Amendment flow.JobId:'+jobId); */
    }/*
    public void deleteQuoteLinesByQuoteId(String quoteId) {
        // Prepare endpoint
        String baseUrl = System.Url.getOrgDomainUrl().toExternalForm();
        String endpoint = baseUrl + '/services/apexrest/deletequotelines?recordId=' + quoteId;

        // Create HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('DELETE');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');

        // Send the request
        Http http = new Http();
        HTTPResponse res = http.send(req);

        // Handle response
        if (res.getStatusCode() == 200 || res.getStatusCode() == 204) {
            createLog('QuoteLines deleted successfully.');
        } else {
            throw new CalloutException('Failed to delete quotelines. Status: ' + res.getStatus()+',Body:'+ res.getBody());
        }
    }*/
    protected override Queueable newInstanceWithRetry(Integer retryCount) {
        return new DeleteQuoteLines(originalPayload, stepStatus,tracker, retryCount);
    }
    
    private void createLog(String logMessage){
        transactionFinalizer.createLog(stepStatus + ': Info', logMessage, DateTime.now(), DateTime.now());
    }
}
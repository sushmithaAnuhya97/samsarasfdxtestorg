public class UpdateOpportunity extends QueueableChainJob {
    
    private Request_Tracker__c tracker;
    private OrderPayload payload;
    private String stepStatus;
    
    public UpdateOpportunity(Request_Tracker__c tracker, String stepStatus, OrderPayload payload, Integer retryCount) {
        super(retryCount, stepStatus, tracker);
        this.tracker = tracker;
        this.payload = payload;
        this.stepStatus = stepStatus;
    }
    
    public override void processJob() {
        createLog('Started processing: Update Opportunity Job.');
        //OrderUtil.initializeUnitOfWork();
       /* 
        Shipping_Address__c shippingAddress = new Shipping_Address__c(Id=tracker.Shipping_Address_Id__c);
        
        // Define all old records
        Opportunity oldOpp = null;
        Opportunity newOpp = JsonToSFDCMapper.mapOpportunityData(payload.opportunity);
        oldOpp = newOpp != null ? OrderProcessorSingleton.getInstance().queryOpportunity(tracker.Opportunity_Id__c) : null;
        
        SBQQ__Quote__c newQuote = new SBQQ__Quote__c(Id=tracker.Quote_Id__c);

        
        if (newOpp != null) newOpp.Id = tracker.Opportunity_Id__c;
        newOpp = processOpportunity(newOpp, oldOpp, shippingAddress, newQuote);
        
        // Update opportunity with primary quote
        if (newOpp != null) {
           handleDmlUpdate(newOpp, newOpp, 'Opportunity', Opportunity.SBQQ__PrimaryQuote__c, newQuote);
        }
        */
        // Method-1: Error: Queueable job limit reached. Cannot enqueue job.
        //DMLWrapper.publishDML();

        // Method-2: Working fine, but not safe.
        /*OrderUtil.disableTriggers();
        DMLWrapper.publishDML();
        OrderUtil.enableTriggers();*/
        
        //Method-3: Working as expected, but need to think about timed out issues (Max time limit for API call is 2min ) 
        updateOpportunityViaRest(tracker);
        createLog('Finished processing: Update Opportunity.');
    }
    
    public void updateOpportunityViaRest(Request_Tracker__c tracker) {
        String endpoint = System.Url.getOrgDomainUrl().toExternalForm() + orderProcessingSettings.Opportunity_Endpoint__c  + tracker.Opportunity_Id__c;
        createLog('Initiating Opportunity update via REST. Tracker ID: ' + tracker?.Id +', Opportunity ID: ' + tracker?.Opportunity_Id__c +', Account ID from payload: ' + payload?.order?.account_id);
        createLog('Endpoint: ' + endpoint);
        
		Opportunity valuesToUpdateFromPayload = JsonToSFDCMapper.mapOpportunityData(payload);
        if(valuesToUpdateFromPayload==null) {
            createLog('Opportunity update skipped: No relevant opportunity values found in the payload.');
            return;
        }
        
        Account accnt = OrderProcessorSingleton.getInstance().queryAccount(payload.order.account_id);
        createLog('Mapped Opportunity OwnerId from Account ID: ' + accnt?.Id + ', OwnerId: ' + accnt?.OwnerId);

        valuesToUpdateFromPayload.OwnerId = accnt?.OwnerId;
        valuesToUpdateFromPayload.Shipping_Address_NEW__c=tracker?.Shipping_Address_Id__c;
        valuesToUpdateFromPayload.SBQQ__PrimaryQuote__c=tracker?.Quote_Id__c;
        
        Map<String, Object> body = valuesToUpdateFromPayload.getPopulatedFieldsAsMap();
        String jsonBody = JSON.serialize(body);

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
            createLog('Opportunity updated successfully via REST API. Status Code: ' + res.getStatusCode());
        } else {
            createLog('Update Opportunity Job Failed.RetryCount '+retryCount+', Status Code:' + res.getStatusCode() + ', Status:'+res.getStatus()+ ', Response Body:' + res.getBody());
            throw new RequestTrackerException('Update Opportunity Job Failed.retryCount:'+retryCount + 'Error Body:' + JSON.serialize(res.getBody()));
        }
    }
    /*
    private Opportunity processOpportunity(Opportunity newOpp, Opportunity oldOpp, Shipping_Address__c shippingAddress, SBQQ__Quote__c quote) {
        if (newOpp != null && shippingAddress != null){
            handleDmlUpdate(oldOpp, newOpp, 'Opportunity', Opportunity.Shipping_Address_New__c, shippingAddress);
        }
        
        //Not needed this entire if block
        if (newOpp != null && quote != null && quote.SBQQ__Primary__c == true) {
            handleDmlUpdate(oldOpp, newOpp, 'Opportunity', Opportunity.SBQQ__PrimaryQuote__c, quote);
        }
        return newOpp;
    }*/
    
    protected override Queueable newInstanceWithRetry(Integer retryCount) {
        return new UpdateOpportunity(tracker, stepStatus, payload, retryCount);
    }
    /*
    private void handleDmlUpdate(SObject oldRecord, SObject newRecord, String objectName, SObjectField relatedField, SObject relatedValue) {
        if (hasFieldChanged(oldRecord, newRecord)) {
            DMLWrapper.doUpdate(newRecord, relatedField, relatedValue);
            createLog(objectName + ' Updated: ' + newRecord.Id);
        } else {
            createLog('Nothing to update on ' + objectName + '. Field values remain the same. ' + newRecord.Id);
        }
    }
    
    public static Boolean hasFieldChanged(SObject oldRecord, SObject newRecord) {
        if (oldRecord == null || newRecord == null) return false;
        
        Map<String, Object> oldMap = oldRecord.getPopulatedFieldsAsMap();
        Map<String, Object> newMap = newRecord.getPopulatedFieldsAsMap();
        
        for (String fieldName : newMap.keySet()) {
            Object oldVal = oldMap.get(fieldName);
            Object newVal = newMap.get(fieldName);
            if (oldVal != newVal && (oldVal == null || !oldVal.equals(newVal))) {
                return true;
            }
        }
        return false;
    }*/
    
    private void createLog(String logMessage) {
        transactionFinalizer.createLog(stepStatus + ': Info', logMessage, DateTime.now(), DateTime.now());
    }
}
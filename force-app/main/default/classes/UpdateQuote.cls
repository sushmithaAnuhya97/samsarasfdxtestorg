public class UpdateQuote extends QueueableChainJob {
    
    private Request_Tracker__c tracker;
    private OrderPayload payload;
    private String stepStatus;
    
    public UpdateQuote(Request_Tracker__c tracker, String stepStatus, OrderPayload payload, Integer retryCount) {
        super(retryCount, stepStatus, tracker);
        this.tracker = tracker;
        this.payload = payload;
        this.stepStatus = stepStatus;
    }
    
    public override void processJob() {
        createLog('Started processing: Update Quote Job.');
        //OrderUtil.initializeUnitOfWork();
        
        //Shipping_Address__c shippingAddress = new Shipping_Address__c(Id=tracker.Shipping_Address_Id__c);
        // Define all old records
        //Opportunity oldOpp = null;
        //SBQQ__Quote__c oldQuote = null;
        
        // Process each object
        //Opportunity newOpp = JsonToSFDCMapper.mapOpportunityData(payload.opportunity);
        //oldOpp = newOpp != null ? OrderProcessorSingleton.getInstance().queryOpportunity(tracker.Opportunity_Id__c) : null;
        
        //SBQQ__Quote__c newQuote = JsonToSFDCMapper.mapAmendmenteQuoteData(payload);
        //oldQuote = newQuote != null ? OrderProcessorSingleton.getInstance().queryQuote(tracker.Quote_Id__c) : null;
        //if (newQuote != null) newQuote.Id = tracker.Quote_Id__c;
        

        //if (newOpp != null) newOpp.Id = tracker.Opportunity_Id__c;
        //newOpp = processOpportunity(newOpp, oldOpp, shippingAddress, newQuote);
        
        //newQuote = processQuote(newQuote, oldQuote, new Opportunity(Id=tracker.Opportunity_Id__c));
        
        /*
        // Update opportunity with primary quote
        if (newOpp != null && newQuote != null) {
            handleDmlUpdate(newOpp, newOpp, 'Opportunity', Opportunity.SBQQ__PrimaryQuote__c, newQuote);
        }*/
        
        // Method-1: Without disabling triggers
        // Error-1: caused by: System.AsyncException: hasMaxStackDepth is not allowed outside a Queueable of Finalizer execution
        // Error-2: Too many queueable jobs added to the queue: 2
        // Error-3: UNABLE_TO_LOCK_ROW
        // DMLWrapper.publishDML();
        
        //Method-2: Working as expected, but not safe - disabling the triggers
        /*OrderUtil.disableTriggers();
        DMLWrapper.publishDML();
        OrderUtil.enableTriggers();*/
        
        //Method-3
        updateQuoteViaRest(tracker);
        createLog('Finished processing: Update Quote.');
    }
    
    public void updateQuoteViaRest(Request_Tracker__c tracker) {
        if(String.isBlank(tracker?.Quote_Id__c)){
            createLog('Quote update skipped: no quoteId found.');
            return;
        }
        String endpoint = System.Url.getOrgDomainUrl().toExternalForm() + orderProcessingSettings.Quote_Endpoint__c  + tracker.Quote_Id__c;
        createLog('Endpoint:'+endpoint);
        
        SBQQ__Quote__c valuesToUpdateFromPayload = JsonToSFDCMapper.mapAmendmenteQuoteData(payload);
        if(valuesToUpdateFromPayload==null){
            createLog('Quote update skipped: no relevant quote values found in the payload.');
            return;
        }  
       
        valuesToUpdateFromPayload.SBQQ__Opportunity2__c=tracker?.Opportunity_Id__c;
        valuesToUpdateFromPayload.Shipping_Address_NEW__c=tracker?.Shipping_Address_Id__c;
        
        Map<String, Object> body = valuesToUpdateFromPayload.getPopulatedFieldsAsMap();
        String jsonBody = JSON.serialize(body);
        createLog('Quote values to update:'+jsonBody);
        
        // Setup HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('PATCH');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId()); 
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000); //Default timeout is 10 seconds; customizable per callout (1 ms to 120,000 ms range).
        req.setBody(jsonBody);
        
        // Send request
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
            createLog('Quote updated successfully via REST API.Status Code:' + res.getStatusCode() + ', Status:'+res.getStatus()+ ', Response Body:' + res.getBody());
        } else {
            createLog('Update Quote Job Failed.RetryCount '+retryCount+', Status Code:' + res.getStatusCode() + ', Status:'+res.getStatus()+ ', Response Body:' + res.getBody());
            throw new RequestTrackerException('Update Quote Job Failed.retryCount:'+retryCount + 'Error Body:' + JSON.serialize(res.getBody()));
        }
    }


    // private Opportunity processOpportunity(Opportunity newOpp, Opportunity oldOpp, Shipping_Address__c shippingAddress, SBQQ__Quote__c quote) {
    //     if (newOpp != null && shippingAddress != null){
    //         handleDmlUpdate(oldOpp, newOpp, 'Opportunity', Opportunity.Shipping_Address_New__c, shippingAddress);
    //     }
        
    //     if (newOpp != null && quote != null && quote.SBQQ__Primary__c == true) {
    //         handleDmlUpdate(oldOpp, newOpp, 'Opportunity', Opportunity.SBQQ__PrimaryQuote__c, quote);
    //     }
    //     return newOpp;
    // }
    
    // private SBQQ__Quote__c processQuote(SBQQ__Quote__c newQuote, SBQQ__Quote__c oldQuote, Opportunity opportunity) {
    //     if (newQuote != null) {
    //         handleDmlUpdate(oldQuote, newQuote, 'Quote', SBQQ__Quote__c.SBQQ__Opportunity2__c, opportunity);
    //     }
    //     return newQuote;
    // }

    protected override Queueable newInstanceWithRetry(Integer retryCount) {
        return new UpdateQuote(tracker, stepStatus, payload, retryCount);
    }

    // private void handleDmlUpdate(SObject oldRecord, SObject newRecord, String objectName, SObjectField relatedField, SObject relatedValue) {
    //     if (hasFieldChanged(oldRecord, newRecord)) {
    //         DMLWrapper.doUpdate(newRecord, relatedField, relatedValue);
    //         createLog(objectName + ' Updated: ' + newRecord.Id);
    //     } else {
    //         createLog('Nothing to update on ' + objectName + '. Field values remain the same. ' + newRecord.Id);
    //     }
    // }
    
    // public static Boolean hasFieldChanged(SObject oldRecord, SObject newRecord) {
    //     if (oldRecord == null || newRecord == null) return false;
        
    //     Map<String, Object> oldMap = oldRecord.getPopulatedFieldsAsMap();
    //     Map<String, Object> newMap = newRecord.getPopulatedFieldsAsMap();
        
    //     for (String fieldName : newMap.keySet()) {
    //         Object oldVal = oldMap.get(fieldName);
    //         Object newVal = newMap.get(fieldName);
    //         if (oldVal != newVal && (oldVal == null || !oldVal.equals(newVal))) {
    //             return true;
    //         }
    //     }
    //     return false;
    // }
    
    private void createLog(String logMessage) {
        transactionFinalizer.createLog(stepStatus + ': Info', logMessage, DateTime.now(), DateTime.now());
    }
}
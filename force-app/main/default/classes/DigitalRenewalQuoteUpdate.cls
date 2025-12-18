public with sharing class DigitalRenewalQuoteUpdate extends QueueableChainJob {
    private Request_Tracker__c tracker;
    private OrderPayload payload;
    private String stepStatus;
    
    public DigitalRenewalQuoteUpdate(Request_Tracker__c tracker, String stepStatus, OrderPayload payload, Integer retryCount) {
        super(retryCount, stepStatus, tracker);
        this.tracker = tracker;
        this.payload = payload;
        this.stepStatus = stepStatus;
    }
    
    public override void processJob() {
        SBQQ__Quote__c quote = JsonToSFDCMapper.mapDigitalRenewalQuoteData(payload);
        Id opportunityId = payload?.opportunity?.id;
        Opportunity opp = OrderProcessorSingleton.getInstance().queryOpportunity(opportunityId);
        if(quote==null){
            createLog('Quote update: no relevant quote values found in the payload.');
            quote=new SBQQ__Quote__c();
        }
        SBQQ__Quote__c quoteDb = OrderProcessorSingleton.getInstance().queryQuote(opp?.SBQQ__PrimaryQuote__r?.Id);
        
        // quote.Shipping_Method__c = opp?.Shipping_Method__c;
        // quote.Shipping_Carrier__c = opp?.Shipping_Carrier__c;
        // quote.Ship_From_Location__c = opp?.Ship_From_Location__c;
        Id shippingAddressId = String.isNotBlank(tracker?.Shipping_Address_Id__c) ? tracker.Shipping_Address_Id__c : opp?.shipping_address_new__c;
        quote.Shipping_Address_NEW__c = String.isNotBlank(shippingAddressId) ? shippingAddressId : quoteDb?.Shipping_Address_NEW__c;

        if(String.isBlank(payload.quote?.id)){
            throw new RequestTrackerException('Quote Id is missing in the request payload. Cannot proceed with order processing.');
        }
        
        /*OrderUtil.initializeUnitOfWork();
        updateRecord(quote);
        DMLWrapper.publishDML();*/
        
        String quoteId = payload.quote?.id;
        tracker.Quote_Id__c = quoteId;
        quote.BypassQuoteToOptySynDate__c = System.now();
        updateQuoteViaRest(quote,quoteId);
        createLog('Finished processing: Quote.'+quoteId);
    }
    /*
    private SObject updateRecord(SObject newRecord) {
        if (newRecord != null) {
            handleDmlUpdate(newRecord, newRecord.getSObjectType().getDescribe().getName());
        }
        return newRecord;
    }

 	private void handleDmlUpdate(SObject newRecord, String objectName) {
        DMLWrapper.doUpdate(newRecord);
        createLog(objectName + ' Updated: ' + newRecord.Id);
    }
    */
    @TestVisible
    protected override Queueable newInstanceWithRetry(Integer retryCount) {
        return new DigitalRenewalQuoteUpdate(tracker, stepStatus, payload, retryCount);
    }
    
    public void updateQuoteViaRest(SBQQ__Quote__c quote,String quoteId) {
        if(String.isBlank(quoteId)){
            throw new RequestTrackerException('Update Quote Job Failed.QuoteId missed in the payload.'); 
        }
        
        String endpoint = System.Url.getOrgDomainUrl().toExternalForm() + orderProcessingSettings.Quote_Endpoint__c  + quoteId;
        
        Map<String, Object> body = quote.getPopulatedFieldsAsMap();
        String jsonBody = JSON.serialize(body);
        
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
            createLog('Quote updated successfully via REST API');
        } else {
            createLog('Update Quote Job Failed.RetryCount '+retryCount+', Status Code:' + res.getStatusCode() + ', Status:'+res.getStatus()+ ', Response Body:' + res.getBody());
            throw new RequestTrackerException('Update Quote Job Failed.retryCount:'+retryCount); 
        }
    }
    
    @TestVisible
    private void createLog(String logMessage) {
        DateTime now = DateTime.now();
        transactionFinalizer.createLog(stepStatus + ': Info', logMessage, now, now);
    }
}
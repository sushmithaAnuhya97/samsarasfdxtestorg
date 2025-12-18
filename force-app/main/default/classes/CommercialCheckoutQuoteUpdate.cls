public with sharing class CommercialCheckoutQuoteUpdate extends QueueableChainJob {
    private Request_Tracker__c tracker;
    private OrderPayload payload;
    private String stepStatus;
    
    public CommercialCheckoutQuoteUpdate(Request_Tracker__c tracker, String stepStatus, OrderPayload payload, Integer retryCount) {
        super(retryCount, stepStatus, tracker);
        this.tracker = tracker;
        this.payload = payload;
        this.stepStatus = stepStatus;
    }
    
    public override void processJob() {
        //OrderUtil.initializeUnitOfWork();opportunity
        Id opportunityId = payload?.opportunity?.id;
        Opportunity opp = OrderProcessorSingleton.getInstance().queryOpportunity(opportunityId);
        if(String.isBlank(opp?.SBQQ__PrimaryQuote__r.Id)){
            throw new RequestTrackerException('Primary Quote does not exist for Opportunity with Id: ' + opportunityId + '. Unable to update quote details.');
        }
        
        SBQQ__Quote__c quote = JsonToSFDCMapper.mapCommercialCheckoutQuoteData(payload);
        if(quote==null){
            createLog('Quote update: no relevant quote values found in the payload.');
            quote=new SBQQ__Quote__c();
        }

        SBQQ__Quote__c quoteDb = OrderProcessorSingleton.getInstance().queryQuote(opp?.SBQQ__PrimaryQuote__r?.Id);

		//quote.Shipping_Method__c = opp?.Shipping_Method__c;
        //quote.Shipping_Carrier__c = opp?.Shipping_Carrier__c;
       // quote.Ship_From_Location__c = opp?.Ship_From_Location__c;
        Id shippingAddressId = String.isNotBlank(tracker?.Shipping_Address_Id__c) ? tracker.Shipping_Address_Id__c : opp?.shipping_address_new__c;
        quote.Shipping_Address_NEW__c = String.isNotBlank(shippingAddressId) ? shippingAddressId : quoteDb?.Shipping_Address_NEW__c;
        
        /* Method-1: caused by: System.AsyncException: hasMaxStackDepth is not allowed outside a Queueable of Finalizer execution 
        updateRecord(quote);
        DMLWrapper.publishDML();*/
        
        Id quoteId = opp.SBQQ__PrimaryQuote__r.Id;
        tracker.Quote_Id__c = quoteId;
        quote.BypassQuoteToOptySynDate__c = System.now();
        updateQuoteViaRest(quote,quoteId);
        createLog('Finished processing: Quote.');
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
    }*/
    
    @TestVisible
    protected override Queueable newInstanceWithRetry(Integer retryCount) {
        return new CommercialCheckoutQuoteUpdate(tracker, stepStatus, payload, retryCount);
    }
    
    public void updateQuoteViaRest(SBQQ__Quote__c quote,Id quoteId) {
        if(String.isBlank(quoteId)){
            createLog('SBQQ__PrimaryQuote__c field value is empty on Opportunity. Cannot proceed with order processing.');
            return;
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
            throw new RequestTrackerException('Update Quote Job Failed.retryCount:'+retryCount+ ', Error: ' + JSON.serialize(res.getBody())); 
        }
    }
    
    private void createLog(String logMessage) {
        DateTime now = DateTime.now();
        transactionFinalizer.createLog(stepStatus + ': Info', logMessage, now, now);
    }
}
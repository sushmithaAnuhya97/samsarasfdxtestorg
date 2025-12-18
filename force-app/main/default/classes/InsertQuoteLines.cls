public class InsertQuoteLines extends QueueableChainJob {
    
    private String stepStatus;
    private final Request_Tracker__c tracker;
    private final OrderPayload originalPayload;
    
    public InsertQuoteLines(OrderPayload originalPayload, String stepStatus,Request_Tracker__c tracker, Integer retryCount) {
        super(retryCount, stepStatus,tracker);
        this.tracker = tracker;
        this.stepStatus=stepStatus;
        this.originalPayload = originalPayload;
    }
    
    public override void processJob() {
        createLog('Started processing: Insert QuoteLines Job.');
        //Approach-1: Failed - System.AsyncException: hasMaxStackDepth is not allowed outside a Queueable of Finalizer execution
       /*Orderutil.initializeUnitOfWork(); 
        
        if (String.isBlank(tracker.Quote_Id__c)) {
            throw new RequestTrackerException('Invalid QuoteId provided.');
        }

        List<SBQQ__QuoteLine__c> quoteLineItemsToInsert = JsonToSFDCMapper.mapQuoteLines(originalPayload?.quote?.quoteLines);
        if(quoteLineItemsToInsert!=null && !quoteLineItemsToInsert.isEmpty()){
            createLog('Number of quote lines to insert: ' + quoteLineItemsToInsert.size());
            
            for(SBQQ__QuoteLine__c quoteLine:quoteLineItemsToInsert){
                quoteLine.Account__c = originalPayload.order.account_id;
                quoteLine.SBQQ__Quote__c = tracker.Quote_Id__c;
                quoteLine.Ship_To__c = tracker.Shipping_Address_Id__c;
                
                // Add debug logging for each quote line
                createLog('Quote Line Details - Product: ' + quoteLine.SBQQ__Product__c + ', Quantity: ' + quoteLine.SBQQ__Quantity__c +', List Price: ' + quoteLine.SBQQ__ListPrice__c);
            }
            
            DMLWrapper.doInsert(quoteLineItemsToInsert);
        } else {
            createLog('No quote lines to insert. quoteLineItemsToInsert is null or empty.');
        }
        
        OrderUtil.disableTriggers();
        SBQQ.TriggerControl.disable();
        DMLWrapper.publishDML();
        SBQQ.TriggerControl.enable();
        OrderUtil.enableTriggers(); 
        createLog('Successfully executed logic to re-insert the QuoteLines in the Amendment flow.'); */
        //-----------------------------------------------------------------------------------------------
        //Approach-2: Success 
   		insertQuoteLines();
    }
    
    public void insertQuoteLines() {
        List<Map<String, Object>> records = new List<Map<String, Object>>();
        
        //List<OrderPayload.QuoteLine> quoteLineData = originalPayload?.quote?.quote_lines;
        List<SBQQ__QuoteLine__c> quoteLinesData = JSONToSFDCMapper.mapQuoteLines(originalPayload);
        if(quoteLinesData==null ||quoteLinesData.isEmpty()){
            createLog('No Quote Line data found in the payload. Skipping Quote Line creation.');
            return;
        }
        
        for (SBQQ__QuoteLine__c quoteLine : quoteLinesData) {
            quoteLine.Account__c = originalPayload.order.account_id;
            quoteLine.SBQQ__Quote__c = tracker.Quote_Id__c;
            quoteLine.Ship_To__c = tracker.Shipping_Address_Id__c;
            
            // First, add the attributes map
            Map<String, Object> quoteLineMap = new Map<String, Object>();
            quoteLineMap.put('attributes', new Map<String, String>{'type' => 'SBQQ__QuoteLine__c'});
            
            // Get all populated fields from the quote line and add to map
            Map<String, Object> populatedFields = quoteLine.getPopulatedFieldsAsMap();
            quoteLineMap.putAll(populatedFields);
            
            records.add(quoteLineMap);
        }
        /*
        for (OrderPayload.QuoteLine ql:quoteLineData) {
            Map<String, Object> quoteLines = new Map<String, Object>();
            quoteLines.put('attributes', new Map<String, String>{'type' => 'SBQQ__QuoteLine__c'});
            quoteLines.put('SBQQ__Product__c',ql.product);
            quoteLines.put('SBQQ__PricebookEntryId__c',ql.pricebookEntryId);
            quoteLines.put('CurrencyIsoCode',ql.CurrencyIsoCode);
            quoteLines.put('SBQQ__ListPrice__c',ql.listPrice);
            quoteLines.put('SBQQ__Discount__c',ql.discount);
            quoteLines.put('SBQQ__Quantity__c',ql.quantity);
            
            quoteLines.put('Account__c',originalPayload.order.account_id);
            quoteLines.put('SBQQ__Quote__c',tracker.Quote_Id__c);
            quoteLines.put('Ship_To__c',tracker.Shipping_Address_Id__c);
            
            records.add(quoteLines);
        }
		*/
        // Create request body
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('records', records);
        payload.put('allOrNone',true);

        createLog('QuoteLines before creation:'+payload);
        HttpRequest req = new HttpRequest();
        req.setEndpoint(System.Url.getOrgDomainUrl().toExternalForm() + orderProcessingSettings.QuoteLines_Endpoint__c);
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000); //Default timeout is 10 seconds; customizable per callout (1 ms to 120,000 ms range).
        req.setBody(JSON.serialize(payload));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
            createLog('QuoteLines created successfully via REST API.'+res.getBody()+',Status Code:'+res.getStatusCode()+ ', Status:'+res.getStatus());
        } else {
            createLog('Insert QuoteLines Job Failed.RetryCount '+retryCount+', Status Code:' + res.getStatusCode() + ', Status:'+res.getStatus()+ ', Response Body:' + res.getBody());
            throw new RequestTrackerException('Insert QuoteLines Job Failed.retryCount:'+retryCount + 'Error Body:' + JSON.serialize(res.getBody()));
        }
    }
    
    protected override Queueable newInstanceWithRetry(Integer retryCount) {
        return new InsertQuoteLines(originalPayload, stepStatus,tracker, retryCount);
    }
    
    private void createLog(String logMessage){
        transactionFinalizer.createLog(stepStatus + ': Info', logMessage, DateTime.now(), DateTime.now());
    }
}
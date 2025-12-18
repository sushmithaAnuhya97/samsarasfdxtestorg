public class InsertQuote extends QueueableChainJob {
    private Request_Tracker__c tracker;
    private OrderPayload payload;

    public InsertQuote(Request_Tracker__c tracker, String stepStatus, OrderPayload payload, Integer retryCount) {
        super(retryCount, stepStatus, tracker);
        this.tracker = tracker;
        this.payload = payload;
    }

    public override void processJob() {
        createLog('Starting: Create Quotes.');

        OrderUtil.initializeUnitOfWork();
        processMappingAndDML();
    }

    private void processMappingAndDML() {
        //Shipping_Address__c shippingAddress = new Shipping_Address__c(Id=tracker.Shipping_Address_Id__c);
        //Opportunity opportunty = new Opportunity(Id=tracker.Opportunity_Id__c);
        createLog('Shipping Address Id.'+tracker.Shipping_Address_Id__c);
        createLog('Opportunity ID.'+tracker.Opportunity_Id__c);
        SBQQ__Quote__c quote = JsonToSFDCMapper.mapFirstTimePurchaseQuoteData(payload); 
        createLog('Quote Details.'+quote);
        if (quote == null) {
            throw new RequestTrackerException('Invalid Quote payload. Skipping.');
        }
        quote.Shipping_Address_NEW__c = tracker.Shipping_Address_Id__c;
        quote.SBQQ__Opportunity2__c=tracker.Opportunity_Id__c;
        
        //DMLWrapper.doInsert(quote, SBQQ__Quote__c.SBQQ__Opportunity2__c, opportunty); 
        DMLWrapper.doInsert(quote);
        
        DMLWrapper.publishDML();
        tracker.Quote_Id__c = quote.Id;
        createLog('Quote inserted.'+quote.Id);
    }

    protected override Queueable newInstanceWithRetry(Integer retryCount) {
        return new InsertQuote(tracker, stepStatus, payload, retryCount);
    }

    private void createLog(String logMessage) {
        transactionFinalizer.createLog(stepStatus + ': Info', logMessage, DateTime.now(), DateTime.now());
    }
}
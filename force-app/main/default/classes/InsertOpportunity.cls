public class InsertOpportunity extends QueueableChainJob {
    
    private Request_Tracker__c tracker;
    private OrderPayload payload;
    
    public InsertOpportunity(Request_Tracker__c tracker, String stepStatus, OrderPayload payload, Integer retryCount) {
        super(retryCount, stepStatus, tracker);
        this.tracker = tracker;
        this.payload = payload;
    }
    
    public override void processJob() {
        createLog('Starting: Create Opportunity.');
        
        OrderUtil.initializeUnitOfWork();
        processMappingAndDML();
    }
    
    private void processMappingAndDML() {
        Shipping_Address__c shippingAddress = new Shipping_Address__c(Id=tracker.Shipping_Address_Id__c);
        Account accnt = OrderProcessorSingleton.getInstance().queryAccount(payload?.order?.account_id);
        
        // Map & insert Opportunity
        Opportunity opportunty = JsonToSFDCMapper.mapOpportunityData(payload);
        if (opportunty == null) {
            throw new RequestTrackerException('Invalid Opportunity payload. Skipping.');
        }
        opportunty.OwnerId = accnt.OwnerId;
        
        DMLWrapper.doInsert(opportunty, Opportunity.Shipping_Address_NEW__c, shippingAddress);
        
        DMLWrapper.publishDML();
        tracker.Opportunity_Id__c = opportunty?.Id;
        createLog('Opportunity inserted.'+tracker.Opportunity_Id__c);
    }
    
    @testVisible
    protected override Queueable newInstanceWithRetry(Integer retryCount) {
        return new InsertOpportunity(tracker, stepStatus, payload, retryCount);
    }
    
    private void createLog(String logMessage) {
        transactionFinalizer.createLog(stepStatus + ': Info', logMessage, DateTime.now(), DateTime.now());
    }
}
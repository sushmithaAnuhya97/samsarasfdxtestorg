public with sharing class CommercialCheckoutOpportunityUpdate extends QueueableChainJob {
    private Request_Tracker__c tracker;
    private OrderPayload payload;
    private String stepStatus;
    
    public CommercialCheckoutOpportunityUpdate(Request_Tracker__c tracker, String stepStatus, OrderPayload payload, Integer retryCount) {
        super(retryCount, stepStatus, tracker);
        this.tracker = tracker;
        this.payload = payload;
        this.stepStatus = stepStatus;
    }
    
    public override void processJob() {
        OrderUtil.initializeUnitOfWork();
        
        Opportunity newOpportunity = JsonToSFDCMapper.mapCommercialCheckoutOpportunityData(payload);
        newOpportunity.Shipping_Address_NEW__c = String.isNotBlank(tracker?.Shipping_Address_Id__c) ? 
            									tracker?.Shipping_Address_Id__c : newOpportunity.Shipping_Address_NEW__c;
        
        updateRecord(newOpportunity);
        
        SBQQ.TriggerControl.disable();
        DMLWrapper.publishDML();
        SBQQ.TriggerControl.enable();
        
        createLog('Finished processing: Opportunity:'+newOpportunity?.Id);
    }
    
    private SObject updateRecord(SObject newRecord) {
        if (newRecord != null) {
            handleDmlUpdate(newRecord, newRecord.getSObjectType().getDescribe().getName());
        }
        return newRecord;
    }
    
    @TestVisible
    protected override Queueable newInstanceWithRetry(Integer retryCount) {
        return new CommercialCheckoutOpportunityUpdate(tracker, stepStatus, payload, retryCount);
    }
    
    private void handleDmlUpdate(SObject newRecord, String objectName) {
        DMLWrapper.doUpdate(newRecord);
        createLog(objectName + ' Updated: ' + newRecord.Id);
    }
    
    @TestVisible
    private void createLog(String logMessage) {
        DateTime now = DateTime.now();
        transactionFinalizer.createLog(stepStatus + ': Info', logMessage, now, now);
    }
}
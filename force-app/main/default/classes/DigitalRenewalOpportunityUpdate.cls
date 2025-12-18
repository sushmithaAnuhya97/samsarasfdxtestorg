public with sharing class DigitalRenewalOpportunityUpdate extends QueueableChainJob {
    private Request_Tracker__c tracker;
    private OrderPayload payload;
    private String stepStatus;
    
    public DigitalRenewalOpportunityUpdate(Request_Tracker__c tracker, String stepStatus, OrderPayload payload, Integer retryCount) {
        super(retryCount, stepStatus, tracker);
        this.tracker = tracker;
        this.payload = payload;
        this.stepStatus = stepStatus;
    }
    
    public override void processJob() {
        OrderUtil.initializeUnitOfWork();

        Opportunity opp = OrderProcessorSingleton.getInstance().queryOpportunity(payload?.opportunity?.id);
        
        Opportunity newOpportunity = JsonToSFDCMapper.mapDigitalRenewalOpportunityData(payload);

        newOpportunity.Shipping_Address_NEW__c = String.isNotBlank(tracker?.Shipping_Address_Id__c) ? tracker?.Shipping_Address_Id__c : opp?.Shipping_Address_NEW__c;
        newOpportunity.Shipping_Country__c = String.isNotBlank(payload?.shipping_address?.shippingCountry) ? payload?.shipping_address?.shippingCountry?.trim() : opp?.Shipping_Country__c;
        
        
        //newOpportunity = OrderProcessorSingleton.getInstance().setShippingDefaults(newOpportunity, payload.shipping_address?.shippingCountry?.trim());
        
        if (payload?.opportunity?.expressAgreementAcceptedDate != null){
            if(opp?.SBQQ__PrimaryQuote__r?.Co_Term_Contract__c != null && opp?.SBQQ__RenewedContract__r?.Weighted_Average_Start_Date__c == null && opp?.closeDate<Date.today() && opp?.Probability <= 95 && opp?.stageName != 'Closed Lost'){
                	newOpportunity.CloseDate = Date.valueOf(payload?.opportunity?.expressAgreementAcceptedDate);
        	}
        }
        
        
        updateRecord(newOpportunity);
        
         SBQQ.TriggerControl.disable();
        DMLWrapper.publishDML();
         SBQQ.TriggerControl.enable();
        
        createLog('Finished processing: Opportunity.');
    }
    
    private SObject updateRecord(SObject newRecord) {
        if (newRecord != null) {
            handleDmlUpdate(newRecord, newRecord.getSObjectType().getDescribe().getName());
        }
        return newRecord;
    }
    
    protected override Queueable newInstanceWithRetry(Integer retryCount) {
        return new DigitalRenewalOpportunityUpdate(tracker, stepStatus, payload, retryCount);
    }
    
    private void handleDmlUpdate(SObject newRecord, String objectName) {
        DMLWrapper.doUpdate(newRecord);
        createLog(objectName + ' Updated: ' + newRecord.Id);
    }
    
    private void createLog(String logMessage) {
        DateTime now = DateTime.now();
        transactionFinalizer.createLog(stepStatus + ': Info', logMessage, now, now);
    }
}
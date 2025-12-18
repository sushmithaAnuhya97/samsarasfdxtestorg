public with sharing class FreeTrialOpportunityInsert extends QueueableChainJob {
    private Request_Tracker__c tracker;
    private OrderPayload payload;
    private String stepStatus;
    
    public FreeTrialOpportunityInsert(Request_Tracker__c tracker, String stepStatus, OrderPayload payload, Integer retryCount) {
        super(retryCount, stepStatus, tracker);
        this.tracker = tracker;
        this.payload = payload;
        this.stepStatus = stepStatus;
    }
    
    public override void processJob() {
        createLog('Started processing: Free Trial Opportunity Insert Job.');
        OrderUtil.initializeUnitOfWork();
                
        try {
            Account accnt = OrderProcessorSingleton.getInstance().queryAccount(payload?.order?.account_id);
            if (accnt == null) {
                throw new RequestTrackerException('Account not found for the order.');
            }
            
            if (tracker?.Shipping_Address_Id__c == null) {
                throw new RequestTrackerException('Shipping Address Id is missing.');
            }

            Shipping_Address__c shippingAddress = OrderProcessorSingleton.getInstance().queryShiippingAddressById(tracker?.Shipping_Address_Id__c);
        
            // Create free trial opportunity
            Opportunity freeTrialOpportunity = JsonToSFDCMapper.mapFreeTrialOpportunityData(payload);

            if (freeTrialOpportunity == null) {
                throw new RequestTrackerException('Invalid Opportunity payload. Skipping.');
            }

            freeTrialOpportunity.OwnerId = accnt?.OwnerId;
            freeTrialOpportunity.Trial_Primary_Contact__c = shippingAddress.Shipping_Contact__c;
            DMLWrapper.doInsert(freeTrialOpportunity, Opportunity.Shipping_Address_NEW__c, shippingAddress);
            DMLWrapper.publishDML();
            
            // Update tracker with free trial opportunity ID
            tracker.Opportunity_Id__c = freeTrialOpportunity?.Id;
            
            createLog('Finished processing: Free Trial Opportunity Insert. Free Trial Opportunity ID: ' + (freeTrialOpportunity?.Id != null ? freeTrialOpportunity.Id : 'NOT Generated'));
        } catch (RequestTrackerException e) {
            throw e;
        }catch (Exception e) {
            throw new RequestTrackerException('Free Trial Opportunity Insert Job Failed.retryCount:'+retryCount + 'Error Body:' + JSON.serialize(e.getMessage()));
        }
    }

    @TestVisible
    protected override Queueable newInstanceWithRetry(Integer retryCount) {
        return new FreeTrialOpportunityInsert(tracker, stepStatus, payload, retryCount);
    }
    
    private void createLog(String logMessage) {
        DateTime now = DateTime.now();
        transactionFinalizer.createLog(stepStatus + ': Info', logMessage, now, now);
    }
}
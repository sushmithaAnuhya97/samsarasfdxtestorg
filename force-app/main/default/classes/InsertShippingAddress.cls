public class InsertShippingAddress extends QueueableChainJob {
    private Request_Tracker__c tracker;
    private OrderPayload payload;
    private String stepStatus;
    
    public InsertShippingAddress(Request_Tracker__c tracker, String stepStatus, OrderPayload payload, Integer retryCount) {
        super(retryCount, stepStatus, tracker);
        this.tracker = tracker;
        this.payload = payload;
        this.stepStatus = stepStatus;
    }
    
    public override void processJob() {
        createLog('Started processing: Insert ShippingAddress Job.');
        OrderUtil.initializeUnitOfWork();

        // Define all old records
        Shipping_Address__c oldShippingAddress = OrderProcessorSingleton.getInstance().queryShippingAddress(payload);
        
        if (oldShippingAddress != null && String.isNotBlank(oldShippingAddress.Id)) {
            createLog('Shipping Address already exists. Skipping creation.'+oldShippingAddress.Id);
            tracker.Shipping_Address_Id__c = oldShippingAddress.Id;
            return ;
        }

        // Create new Shipping Address
        Shipping_Address__c shippingAddress = processShippingAddress();
        if (shippingAddress == null) {
            createLog('No Shipping Address created. Ending job.');
            return;
        }
        
        DMLWrapper.publishDML();
        
        // Update tracker with shipping address ID after DML 
        tracker.Shipping_Address_Id__c = shippingAddress?.Id;
        
        createLog('Finished processing: Create Shipping Address.'+shippingAddress?.Id);
    }
    
    private Shipping_Address__c processShippingAddress() {
        Shipping_Address__c newAddress = JsonToSFDCMapper.mapShippingAddress(payload);
        
        if (newAddress == null) {
            createLog('Shipping Address mapping returned null. Skipping creation.');
            return null;
        }
        
        Contact cnt = OrderProcessorSingleton.getInstance().queryContact(payload.order.account_id); 
        if (cnt != null) {
            newAddress.Shipping_Contact__c = cnt.Id;
            createLog('Mapped Contact to Shipping Address: ' + cnt.Id);
        } else {
            createLog('No Contact found for AccountId: ' + payload.order.account_id);
        }
        
        DMLWrapper.doInsert(newAddress);
        return newAddress;
    }
    
    @TestVisible
    protected override Queueable newInstanceWithRetry(Integer retryCount) {
        return new InsertShippingAddress(tracker, stepStatus, payload, retryCount);
    }
    
    private void createLog(String logMessage) {
        transactionFinalizer.createLog(stepStatus + ': Info', logMessage, DateTime.now(), DateTime.now());
    }
}
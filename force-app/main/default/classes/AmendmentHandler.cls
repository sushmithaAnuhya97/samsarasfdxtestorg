public class AmendmentHandler extends OrderTransactionHandler {
    private static final String RECORD_ID = 'Id';
    private static final String OPPORTUNITY = 'SBQQ__Opportunity2__c';
    
    // Business Validations
    public static final String IS_ENTERPRISE_KEY_NOT_FOUND = 'Unexpected error during order validation in the Amendment flow. Missing or invalid \'is_enterprise\' key in the \'order\' node. Please ensure the key exists and is correctly populated.';
    public static final String LATEST_ACTIVE_CONTRACT_NOT_FOUND = 'Latest active contract not found for the account: ';
    public static final String LATEST_ACTIVE_CONTRACT_INELIGIBLE_FOR_AMENDMENT = 'Latest active contract ineligible for amendment: either not \'Activated\', expired end date, or no valid subscriptions. At least one active subscription is required.';
    public static final String DUPLICATE_ORDER_SUBMITTED = 'Order already submitted and currently in \'Processing\' status. Duplicate submission prevented.';
    
    @TestVisible
    protected override Boolean isOrderValid(Request_Tracker__c tracker) {
        OrderPayload payload;
        
        try {
            // Deserialize payload
            payload = deserializePayload(tracker.Request__c);
            
            Id contractId = getContractId(payload.order.is_enterprise, payload.order.account_id);
            if (String.isBlank(contractId)) {
                return handleInvalidOrder(tracker, payload,OrderUtil.STEP_1 + ': Info', LATEST_ACTIVE_CONTRACT_NOT_FOUND + payload.order.account_id);
            }
            
            // Prevent ROW LOCK & CPU timeouts due to parallel amendments on the same contract/account
            // The amendment process is driven by multiple async jobs (e.g., Queueables).These jobs may run concurrently with no guaranteed execution order.
            // Parallel updates to the same contract and related records (subscriptions, quotes, opportunity, opportunity-products etc.) causing record locking and  CPU timeout exceptions.
            Request_tracker__c requestTracker = isOrderProcessing(payload.order.account_id,contractId);
            if(requestTracker!=null && 'Processing'.equalsIgnoreCase(requestTracker.Status__c)){
                return handleInvalidOrder(tracker, payload,OrderUtil.STEP_1 + ': Info',DUPLICATE_ORDER_SUBMITTED+'.Current OrderId:'+payload.order.id+'.Previous Submitted OrderId:'+requestTracker.OrderId__c);
            }
            
            // Validate subscriptions
            if (!hasValidSubscriptions(contractId)) {
                return handleInvalidOrder(tracker, payload,OrderUtil.STEP_1 + ': Info',LATEST_ACTIVE_CONTRACT_INELIGIBLE_FOR_AMENDMENT);
            }
            
            upsertAccountOnShippingAddress(contractId,payload.order.account_id,tracker);
        } catch (System.JSONException jsonEx) {
            String errorMsg = 'JSON parsing error: ' + jsonEx.getMessage();
            System.debug(errorMsg);
            return handleInvalidOrder(tracker, null, OrderUtil.STEP_1 + ': JSON Error', errorMsg);
        } catch (Exception ex) {
            String errorMsg = IS_ENTERPRISE_KEY_NOT_FOUND + ex.getMessage();
            System.debug(errorMsg);
            return handleInvalidOrder(tracker, payload, OrderUtil.STEP_1 + ': Exception', errorMsg);
        }
        return true;
    }
    
    
    private Boolean handleInvalidOrder(Request_Tracker__c tracker, OrderPayload payload, String step, String message) {
        DateTime now = DateTime.now();
        logInvalidStep(tracker, step, message, now);
        return markTrackerInvalid(tracker, payload, message);
    }
    
    private void logInvalidStep(Request_Tracker__c tracker, String step, String message, DateTime timestamp) {
        OrderUtil.logJob(tracker, step, message, timestamp, timestamp, true);
    }
    
    private Boolean markTrackerInvalid(Request_Tracker__c tracker, OrderPayload payload, String message) {
        tracker.Status__c = 'Invalid';
        tracker.Step_Status__c = 'Step2 Error Occurred'; 
        
        tracker.Error_Details__c = message;
        OrderService.saveRequestTracker(tracker);
        
        OrderUtil.enqueueJobIfPossible(new OrderErrorResultToWorkato(tracker, tracker.Step_Status__c, message));
        return false;
    }
    
    public static Request_Tracker__c isOrderProcessing(String accountId, String contractId) {
        return OrderProcessorSingleton.getInstance().findRequestTracker(contractId, accountId);
    }
    
    public static Id getContractId(Boolean isEnterprise, Id accountId){
        Id contractId= isEnterprise?queryCustomer360Record(accountId):null;
        return String.isBlank(contractId)?queryLatestActiveContract(accountId)?.Latest_Active_Contract__c:contractId;
    }
    
    public static Id queryCustomer360Record(Id accountId) {
        return OrderProcessorSingleton.getInstance().queryCustomer360(accountId);
    }
    
    public static Account queryLatestActiveContract(Id accountId) {
        return OrderProcessorSingleton.getInstance().queryAccount(accountId);
    }
    
    private Boolean hasValidSubscriptions(Id latestActiveContract) {
        Integer activeSubscriptions = OrderProcessorSingleton.getInstance().getActiveSubscriptionsCount(latestActiveContract);
        return activeSubscriptions>0;
    }
    
    @TestVisible
    protected override void processTransaction(Request_Tracker__c tracker) {
        AmendmentBatch amendmentBatch = new AmendmentBatch(tracker.Id);
        try{
            Id jobId = Database.executeBatch(amendmentBatch, 1);
            Orderutil.logJob(tracker,OrderUtil.STEP_1+': Info','Amendment process initiated via Apex Batch Job: '+jobId + ' and Request Tracker Id : '+tracker.Id + ' at: '+DateTime.now(),DateTime.now(), DateTime.now(), OrderUtil.IS_INSERT_LOG_JOB);
        }catch(Exception exp){
            Orderutil.logJob(tracker,OrderUtil.STEP_1+': Error','Failed to enqueue Batch Apex Job for Amendment process. Details: '+exp?.getMessage()+'. Request Tracker Id : '+tracker.Id + ' at: '+DateTime.now(),DateTime.now(), DateTime.now(), OrderUtil.IS_INSERT_LOG_JOB);
        }
    }
    
    private static OrderPayload deserializePayload(String originalPayload) {
        return OrderProcessorSingleton.getInstance().deserializePayload(originalPayload);
    }
    
    @testVisible
    private static void upsertAccountOnShippingAddress(String contractId, Id accountId, Request_Tracker__c tracker) {
        // Query subscriptions related to the contract
        List<SBQQ__Subscription__c> subscriptionsList = [SELECT Id, Ship_To__c, Ship_To__r.Account__c FROM SBQQ__Subscription__c WHERE SBQQ__Contract__c = :contractId];
        
        // Map to store one Ship_To__c per accountId (in this case only accountId parameter)
        Id defaultShipToId = null;
        for (SBQQ__Subscription__c sub : subscriptionsList) {
            if (sub.Ship_To__c != null && sub.Ship_To__r != null && sub.Ship_To__r.Account__c == accountId) {
                defaultShipToId = sub.Ship_To__c;
                break; // stop after finding the first matching Ship_To__c for accountId
            }
        }
        
        List<SBQQ__Subscription__c> subscriptionsRecordsToUpdate = new List<SBQQ__Subscription__c>();
        // Prepare subscriptions that have missing Ship_To__c but for which we have a default Ship_To__c for the account
        for (SBQQ__Subscription__c sub : subscriptionsList) {
            if (sub.Ship_To__c == null && defaultShipToId != null) {
                subscriptionsRecordsToUpdate.add(new SBQQ__Subscription__c(Id = sub.Id, Ship_To__c = defaultShipToId));
            }
        }
        
        // Update subscriptions with missing Ship_To__c
        if (!subscriptionsRecordsToUpdate.isEmpty()) {
            try {
                Database.SaveResult[] results = Database.update(subscriptionsRecordsToUpdate, true); 
                
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult sr = results[i];
                    if (!sr.isSuccess()) {
                        for (Database.Error err : sr.getErrors()) {
                            Orderutil.logJob(tracker,OrderUtil.STEP_1 + ': Info','Error updating Subscription Id: ' + subscriptionsRecordsToUpdate[i].Id + ' - ' + err.getMessage() + ' at: ' + DateTime.now(),DateTime.now(), DateTime.now(), true);
                        }
                    }
                }
                Orderutil.logJob(tracker,OrderUtil.STEP_1 + ': Info','Successfully updated Ship_To__c on ' + subscriptionsRecordsToUpdate.size() + ' Subscription(s) at: ' + DateTime.now(),DateTime.now(), DateTime.now(), true);
            } catch (Exception exp) {
                Orderutil.logJob(tracker,OrderUtil.STEP_1 + ': Error','Error occurred while updating Subscriptions. Details: ' + exp.getMessage() + '. Request Tracker Id: ' + tracker.Id + ' at: ' + DateTime.now(),DateTime.now(), DateTime.now(), true);
            }
        }
        
        // Now prepare shipping addresses that need account correction
        List<Shipping_Address__c> shippingAddressList = new List<Shipping_Address__c>();
        
        List<Contact> contactList = [SELECT Id FROM Contact WHERE AccountId = :accountId LIMIT 1];
        Id contactId = !contactList.isEmpty() ? contactList[0].Id : null;
        
        if(String.isNotBlank(contactId)){
            for (SBQQ__Subscription__c subscription : subscriptionsList) {
                if (subscription.Ship_To__c != null && subscription.Ship_To__r != null && subscription.Ship_To__r.Account__c != accountId) {
                    shippingAddressList.add(new Shipping_Address__c(Id = subscription.Ship_To__c,Account__c = accountId, Shipping_Contact__c =contactId));
                }
            }
        }
        
        // Upsert shipping addresses with corrected Account__c
        if (!shippingAddressList.isEmpty()) {
            try {
                Database.UpsertResult[] results = Database.upsert(shippingAddressList, true); 
                
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult res = results[i];
                    if (!res.isSuccess()) {
                        for (Database.Error err : res.getErrors()) {
                            Orderutil.logJob(tracker,OrderUtil.STEP_1 + ': Info','Error updating Shipping Address Id: ' + shippingAddressList[i].Id + ' - ' + err.getMessage() + ' at: ' + DateTime.now(),DateTime.now(), DateTime.now(), true);
                        }
                    }
                }
                Orderutil.logJob(tracker,OrderUtil.STEP_1 + ': Info','Successfully updated Account__c on ' + shippingAddressList.size() + ' Shipping Address(es) at: ' + DateTime.now(),DateTime.now(), DateTime.now(), true);
            } catch (Exception exp) {
                Orderutil.logJob(tracker,OrderUtil.STEP_1 + ': Error','Error occurred while updating Shipping Addresses. Details: ' + exp.getMessage() + '. Request Tracker Id: ' + tracker.Id + ' at: ' + DateTime.now(),DateTime.now(), DateTime.now(), true);
            }
        }
    }
}
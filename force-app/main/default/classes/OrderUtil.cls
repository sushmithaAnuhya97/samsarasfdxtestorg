public class OrderUtil {
    // HTTP Status Codes
    public static final Integer STATUS_SUCCESS = 201;
    public static final Integer STATUS_BAD_REQUEST = 400;
    public static final Integer STATUS_SERVER_ERROR = 500;
    
    // Validation Messages
    //public static final String INVALID_PAYLOAD = 'Invalid request payload.';
    //public static final String INVALID_ORDER_ID = 'Invalid Order Id.';
    //public static final String ORDER_DETAILS_MISSING = 'Order details should not be null or empty.';
    //public static final String INVALID_ACCOUNT_ID = 'AccountId is invalid. It should be 15 or 18 characters in length and cannot be null or empty.';
    //public static final String TRANSACTION_TYPE_MISSING = 'Order transaction type cannot be null or empty.';
    //public static final String INVALID_TRANSACTION_TYPE = 'Invalid transaction type: ';
    //public static final String ORDER_RECEIVED = 'Order received successfully. Salesforce will respond once processing is complete.';
    public static final String UNEXPECTED_ERROR = 'Unexpected error occurred while processing order: ';
    //public static final String ERROR_DESERIALIZATION = 'Error during deserialization: ';
    public static final String ERROR_SAVING_REQUEST = 'Failed to save Request Tracker record.';
    //public static final String ERROR_UPDATE_REQUEST = 'Failed to update Request Tracker record status.';
    public static final String ERROR_DATABASE = 'Database error: ';
    public static final String ERROR_LOGGING = 'Failed to log error: ';
    //public static final String ERROR_SENDING_RESPONSE = 'Error sending response: ';
    //public static final String ERROR_FLUSHING_LOGS = 'Failed to flush logs: ';
    private static final String ROW_LOCK_ERROR = 'UNABLE_TO_LOCK_ROW';
    private static final String UNABLE_TO_LOCK_ERROR='unable to obtain exclusive access to this record';
    public static final String STEP_1 = 'Step-1';
    public static final String STEP_2 = 'Step-2';
    //public static final String ADD_ON_PURCHASE_TYPE = 'Add-On';
    public static final String SHIPPING_CONTACT_NOT_FOUND = 'The shipping contact "{0}" does not exist in the system.';
    public static final String SHIPPING_ADDRESS_NOT_FOUND = 'No shipping address found for contact "{0}".';
    
    // Static variable to control log flushing
    public static Boolean IS_INSERT_LOG_JOB = false;
    
    // List of trigger handlers (moved to a custom label)
    /*private static final List<String> TRIGGER_HANDLERS = new List<String>{
        'GS_OpportunityTriggerHandler', 'OpportunityTriggerHandler', 'GS_SBQQQuoteTriggerHandler', 'SBQQQuoteTriggerHandler',
        'SBQQQuoteLineTriggerHandler', 'OpportunityLineItemTriggerHandler', 'AccountTriggerHandler', 'GS_AccountTriggerHandler',
        'ContractTriggerHandler', 'GS_ContactTriggerHandler', 'ContactTriggerHandler'}; */
    
        private static final List<String> TRIGGER_HANDLERS = new List<String>{'OpportunityTriggerHandler', 'GS_SBQQQuoteTriggerHandler'};
        
            /*
        // Validate the order details and account ID
       public static String validateOrder(OrderPayload orderDetails) {
            
            if (orderDetails == null || orderDetails.order == null) {
                return ORDER_DETAILS_MISSING;
            }
            
            String orderId = orderDetails.order.Id;
            String txnType = orderDetails.order.transaction_type;
            String accountId = orderDetails.order.account_id;
            
            if(String.isBlank(orderId)){
                return INVALID_ORDER_ID;
            }
            
            if (String.isBlank(txnType)) {
                return TRANSACTION_TYPE_MISSING;
            } else if (!isValidTransactionType(txnType)) {
                return (INVALID_TRANSACTION_TYPE + txnType);
            }
            
            if (!isValidAccountId(accountId)) {
                return INVALID_ACCOUNT_ID;
            }
            
            return null;
        }
    
    // Check if the transaction type is valid
    public static Boolean isValidTransactionType(String txnType) {
        try {
            TransactionType.valueOf(txnType); // Consider specifying the exact exception to catch if needed
            return true;
        } catch (Exception e) {
            // If the exception type is more specific, you can handle it here
            return false;
        }
    } 
    
    // Helper method to validate the account ID
    public static Boolean isValidAccountId(String accountId) {
        return !String.isBlank(accountId) && (accountId.length() == 15 || accountId.length() == 18);
    }*/
    
    private static Boolean isSandbox() {
        return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }
    
    public static Order_Processing_Settings__mdt getOrderProcessingSettings(){
        String envronment = isSandbox()?'Workato_Sandbox':'Workato_Production';
        return Order_Processing_Settings__mdt.getInstance(envronment);
    }
    
    // Disable triggers based on predefined list
    public static void disableTriggers() {
        for (String handler : TRIGGER_HANDLERS) {
            TriggerHandler.bypass(handler);
        }
        SBQQ.TriggerControl.disable();
    }
    
    // Enable triggers based on predefined list
    public static void enableTriggers() {
        for (String handler : TRIGGER_HANDLERS) {
            TriggerHandler.clearByPass(handler);
        }
        SBQQ.TriggerControl.enable();
    }
    
    
    // Helper method to check the queueable job limit and enqueue the job
    public static Boolean canEnqueueJob() {
        return Limits.getQueueableJobs() < Limits.getLimitQueueableJobs();
    }
    
    public static void enqueueJobIfPossible(Queueable job) {
        enqueueJobWithOptionalDelay(job, null);
    }
    
    public static void enqueueJobIfPossibleWithDelay(Queueable job,Integer delay) {
        enqueueJobWithOptionalDelay(job, delay);
    }
    
    private static void enqueueJobWithOptionalDelay(Queueable job, Integer delay) {
        if (!canEnqueueJob()) {
            throw new RequestTrackerException('Queueable job limit reached. Cannot enqueue job.');
        }
        
        try {
            Id jobId = (delay != null)? System.enqueueJob(job, delay): System.enqueueJob(job);
            System.debug('Queueable job enqueued. JobId: ' + jobId);
        } catch (Exception e) {
            throw new RequestTrackerException('Failed to enqueue job. Error: ' + e.getMessage());
        }
    }
    
    public static void initializeUnitOfWork() {
        List<Schema.SObjectType> UOW_SOBJECTS = new List<Schema.SObjectType>{Shipping_Address__c.SObjectType, Account.SObjectType, Opportunity.SObjectType, SBQQ__Quote__c.SObjectType, SBQQ__QuoteLine__c.SObjectType};
        DMLWrapper.intializeUnitOfWork(UOW_SOBJECTS);
    }
    
    public static void logJob(Request_Tracker__c tracker, String stepStatus, String message, DateTime startTime, DateTime endTime, Boolean isInsert) {
        LogManager.log(tracker.Id, tracker.Transaction_Type__c, stepStatus, message, startTime, endTime);
        if(isInsert){
            LogManager.flushLogs();
        }
    }
    
    public static Boolean isRowLockIssue(Exception e) {
        return e.getMessage() != null && (e.getMessage().contains(ROW_LOCK_ERROR) || e.getMessage().contains(UNABLE_TO_LOCK_ERROR));
    }
    
    public static Boolean shouldRetry(Integer retryCount) {
        //return retryCount < orderProcessingSettings.Maximum_Retries__c;
        return retryCount < 3;
    }
    
    public static void flushLogs() {
        LogManager.flushLogs();
    }
}
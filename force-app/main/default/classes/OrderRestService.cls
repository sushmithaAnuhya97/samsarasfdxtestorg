@RestResource(urlMapping='/orders/v1')
global class OrderRestService {
    
    // Static constants
    private static final String ERROR_EMPTY_PAYLOAD         = 'Invalid or empty payload.';
    private static final String ERROR_ORDER_FOUND           = 'Order details missing in the payload. Cannot proceed with order processing.';
    private static final String ERROR_INVALID_ORDER_ID      = 'Invalid Order Id.';
    private static final String ERROR_INVALID_TRANSACTION   = 'Invalid Transaction Type.';
    private static final String ERROR_INVALID_ACCOUNT_ID    = 'Invalid AccountId';
    private static final String ERROR_DUPLICATE_ORDER       = 'Duplicate Order Received';
    private static final String ERROR_RETRY_LIMIT           = 'Order [{0}] has already been retried {1} times. Skipping further reprocessing.';
    private static final String MSG_ORDER_RECEIVED          = 'Order received successfully. Salesforce will notify once order processing is completed.';
    
    private static final String STEP_1                      = 'Step-1';
    private static final String STATUS_PROCESSING           = 'Processing';
    private static final String STEP_1_STATUS               = 'Step-1: Success';
    
    private static final RestRequest request = RestContext.request;
    private static final RestResponse response = RestContext.response;
    
    @HttpPost
    global static void processOrder() {
        try {
            // Step 1: Read and log raw request body
            String requestBody = request?.requestBody?.toString()?.trim();
            System.debug('Request------>'+requestBody);
            
            // Step 2: Validate order payload and parseOrderInfo
            OrderPayload payload = parseOrderPayload(requestBody);
            OrderInfo orderInfo = parseOrderInfo(payload);
            
            // Step 3: Fetch existing tracker and retry count
            Request_Tracker__c existingTracker = OrderService.findRequestTrackerCount(orderInfo?.orderId);
            Integer retryCount = existingTracker != null ? Integer.valueOf(existingTracker.Retry_Count__c) : 0;
            
            // Step 4: Check retry limit
            Order_Processing_Settings__mdt settings = OrderUtil.getOrderProcessingSettings();
            if (retryCount >= settings.Maximum_Retries__c) {
                String errorMessage = String.format(ERROR_RETRY_LIMIT, new List<String>{orderInfo?.orderId, String.valueOf(retryCount)});
                sendErrorResponse(existingTracker?.Id, errorMessage);
                return;
            }
            
            // Step 5: Create or update tracker with basic info
            Request_Tracker__c tracker = new Request_Tracker__c(Id = existingTracker?.Id,Request__c = requestBody,Retry_Count__c = retryCount + 1);
            OrderService.saveRequestTracker(tracker);
            
            // Step 6: Empty or malformed payload check
            if (isEmptyPayload(requestBody)) {
                sendErrorResponse(tracker.Id, ERROR_EMPTY_PAYLOAD);
                return;
            }
            
            // Step 7: Null check for parsed OrderInfo
            if (orderInfo == null) {
                sendErrorResponse(tracker.Id, ERROR_ORDER_FOUND);
                return;
            }
            
            // Step 8: Update tracker with details from payload
            tracker.Transaction_Type__c = orderInfo.transactionType;
            tracker.OrderId__c          = orderInfo.orderId;
            tracker.Account_Id__c       = orderInfo.accountId;
            tracker.Requestor__c        = UserInfo.getUserId();
            tracker.Step_Status__c      = 'Step1 Error Occurred'; 
            tracker.Status__c           = 'Received';
            tracker.Opportunity_Id__c   = payload.opportunity?.Id;
            OrderService.saveRequestTracker(tracker);
            
            // Step 9: Run business validations
            String validationError = validateOrderInfo(orderInfo);
            if (validationError != null) {
                logError(tracker.Id, orderInfo.transactionType, validationError, STEP_1);
                sendErrorResponse(validationError, orderInfo.transactionType, tracker.Id);
                return;
            }
            
            // Step 10: Ready for processing
            tracker.Status__c = STATUS_PROCESSING;
            tracker.Step_Status__c = STEP_1_STATUS;
            OrderService.saveRequestTracker(tracker);
            
            if (!Test.isRunningTest()) {
                System.enqueueJob(new ProcessOrderAsync(tracker));
            }
            
            // Step 11: Send success response
            sendResponse(OrderUtil.STATUS_SUCCESS, OrderResponse.success(MSG_ORDER_RECEIVED, orderInfo.transactionType, tracker.Id));
            
        } catch (Exception e) {
            handleException(e);
        }
    }
    
    private static String validateOrderInfo(OrderInfo info) {
        if (String.isBlank(info.orderId)) return ERROR_INVALID_ORDER_ID;
        if (String.isBlank(info.transactionType) || !isValidTransactionType(info.transactionType)) return ERROR_INVALID_TRANSACTION;
        if (String.isBlank(info.accountId) || info.accountId.length() != 18 || doesAccountExist(info.accountId)) return ERROR_INVALID_ACCOUNT_ID;
        return null;
    }
    
    private static Boolean doesAccountExist(String accountId) {
        return [SELECT Id FROM Account WHERE Id = :accountId LIMIT 1].isEmpty();
    }
    
    private static Boolean isEmptyPayload(String body) {
        return String.isBlank(body) || body.equalsIgnoreCase('{}') || body.equalsIgnoreCase('{ }');
    }
    
    private static void handleException(Exception e) {
        String errorMessage = OrderUtil.UNEXPECTED_ERROR + e.getMessage();
        logError(null, null, errorMessage, STEP_1);
        if (e.getMessage().contains('DUPLICATE_VALUE')) {
            errorMessage = ERROR_DUPLICATE_ORDER;
        }
        sendErrorResponse(errorMessage);
    }
    
    private static Boolean isValidTransactionType(String txnType) {
        try {
            TransactionType.valueOf(txnType);
            return true;
        } catch (Exception e) {
            return false;
        }
    }
    
    private static void logError(Id trackerId, String txnType, String errorMsg, String step) {
        try {
            OrderService.createLogEntry(trackerId, txnType, errorMsg, step + ': Error');
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, OrderUtil.ERROR_LOGGING + e.getMessage());
        }
    }
    
    private static void sendErrorResponse(String message) {
        sendResponse(OrderUtil.STATUS_BAD_REQUEST, OrderResponse.error(message));
    }
    
    private static void sendErrorResponse(String trackerId, String message) {
        sendResponse(OrderUtil.STATUS_BAD_REQUEST, OrderResponse.error(message, trackerId));
    }
    
    private static void sendErrorResponse(String message, String txnType, String trackerId) {
        sendResponse(OrderUtil.STATUS_BAD_REQUEST, OrderResponse.error(message, txnType, trackerId));
    }
    
    private static void sendResponse(Integer statusCode, OrderResponse responseObj) {
        try {
            response.statusCode = statusCode;
            response.responseBody = Blob.valueOf(JSON.serialize(responseObj));
        } catch (Exception e) {
            response.statusCode = OrderUtil.STATUS_SERVER_ERROR;
            response.responseBody = Blob.valueOf(JSON.serialize(OrderResponse.error(OrderUtil.UNEXPECTED_ERROR)));
        }
    }
    
    public class OrderInfo {
        public String orderId;
        public String accountId;
        public String transactionType;
        
        public OrderInfo(String orderId, String accountId, String transactionType) {
            this.orderId = orderId;
            this.accountId = accountId;
            this.transactionType = transactionType;
        }
    }
    
    public static OrderPayload parseOrderPayload(String jsonPayload) {
        try {
            return (OrderPayload)OrderProcessorSingleton.getInstance().deserializePayload(jsonPayload);
        } catch (Exception e) {
            Request_Tracker__c tracker = new Request_Tracker__c();
            tracker.Request__c = jsonPayload;
            tracker.Error_Details__c = 'Deserialization Error: ' + e.getMessage();
            tracker.Step_Status__c = 'Step-1: Deserialization Failed';
            tracker.Status__c = 'Invalid';
            tracker.Requestor__c = UserInfo.getUserId();
            Id trackerId = OrderService.saveRequestTracker(tracker);
            sendErrorResponse('Invalid JSON payload: ' + e.getMessage(), trackerId);
            return null;
        }
    }

    public static OrderInfo parseOrderInfo(OrderPayload payload) {
        if(payload != null && payload.order != null) {
            return new OrderInfo(payload.order.id, payload.order.account_id, payload.order.transaction_type);
        }
        return null;
    }
    
    // Async processing class
    public class ProcessOrderAsync implements Queueable {
        public Request_Tracker__c tracker;
        
        public ProcessOrderAsync(Request_Tracker__c tracker) {
            this.tracker = tracker;
        }
        
        public void execute(QueueableContext context) {
            OrderTransactionHandler handler = OrderTransactionHandlerFactory.getHandler(tracker.Transaction_Type__c);
            handler.processOrder(tracker);
        }
    }
}
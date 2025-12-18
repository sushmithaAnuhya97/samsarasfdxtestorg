public class OrderResultToWorkatoService extends QueueableChainJob {
    
    private final OrderPayload payload;
    
    public OrderResultToWorkatoService(Request_Tracker__c tracker, String stepStatus, OrderPayload payload, Integer retryCount) {
        super(retryCount, stepStatus, tracker);
        this.payload = payload;
    }
    
    public override void processJob() {
        createLog('Info', 'Preparing to call Workato API...');
        validatePreconditions();
        
        String requestBody = createRequest();
        createLog('Info', 'HTTP RequestBody to Workato:'+requestBody);
        if (String.isBlank(requestBody)) {
            throw new RequestTrackerException('Request body cannot be blank');
        }
        
        HttpRequest request = buildHttpRequest(requestBody);
        createLog('Info', 'Sending request to Workato...');
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        
        logHttpResponse(response);
    }
    
    @TestVisible
    protected override Queueable newInstanceWithRetry(Integer retryCount) {
        return new OrderResultToWorkatoService(tracker, stepStatus, payload, retryCount);
    }
    
    private void validatePreconditions() {
        if (payload == null) {
            throw new RequestTrackerException('Payload cannot be null');
        }
        if (orderProcessingSettings == null) {
            throw new RequestTrackerException('OrderProcessingSettings metadata is missing');
        }
        if (String.isBlank(orderProcessingSettings.Header_Value__c)) {
            throw new RequestTrackerException('OrderProcessingSettings.Header_Value__c is blank');
        }
    }
    
    private HttpRequest buildHttpRequest(String requestBody) {
        HttpRequest request = new HttpRequest();
        String endpoint = 'callout:' + orderProcessingSettings.Named_Credential__c + orderProcessingSettings.Endpoint__c;
        createLog('Info', 'Workato Endpoint:'+endpoint);
        request.setEndpoint(endpoint);
        request.setMethod(orderProcessingSettings.Http_Method__c);
        request.setHeader('Content-Type', orderProcessingSettings.Content_Type__c);
        request.setHeader(orderProcessingSettings.Header_Key__c, orderProcessingSettings.Header_Value__c);
        request.setTimeout(Integer.valueOf(orderProcessingSettings.Callout_Timeout__c));
        request.setBody(requestBody);
        return request;
    }
    
    private void logHttpResponse(HttpResponse res) {
        if (res == null) {
            createLog('Error', 'Received null response from Workato.');
            return;
        }
        
        Integer statusCode = res.getStatusCode();
        Boolean isSuccess = statusCode == orderProcessingSettings.Status_Code__c;
        
        String logLevel = isSuccess ? 'Info' : 'Error';
        String logMessage = String.format('{0}. Response:\nStatus Code: {1}\nStatus: {2}\nBody: {3}',new List<String>{isSuccess ? 'HTTP Callout Success' : 'HTTP Callout Failed',String.valueOf(statusCode),res.getStatus(),res.getBody()});
        createLog(logLevel, logMessage);
    }
    
    private String createRequest() {
        Opportunity opp = OrderProcessorSingleton.getInstance().queryOpportunity(tracker?.Opportunity_Id__c);
        
        createLog('Info', 'Quote Recalculation Needed: ' + opp?.SBQQ__PrimaryQuote__r?.SBQQ__Uncalculated__c);
        createLog('Info', 'Quote Amount Received: ' + opp?.SBQQ__PrimaryQuote__r?.Amount_Received__c);
        createLog('Info', 'Opportunity Amount: ' + opp?.Amount);
        createLog('Info', 'Opportunity Record: ' + opp);
        
        Boolean isQuoteRecalcNeeded = opp?.SBQQ__PrimaryQuote__r?.SBQQ__Uncalculated__c == true;
        //Boolean isOppInvalid = (opp == null || opp?.SBQQ__PrimaryQuote__r?.Amount_Received__c == null);
        Boolean isMaxRetryReached = retryCount >= orderProcessingSettings?.Maximum_Retries__c;
        
        if (isQuoteRecalcNeeded) {
            return createErrorPayload(opp, 'Order Processing Failed. Quote Recalculation Needed. Retry Count: ' + retryCount);
        }
        /*
        if (isOppInvalid) {
            return createErrorPayload(opp, 'Order Processing Failed. Opportunity Amount is invalid. [OpportunityId: ' + tracker?.Opportunity_Id__c + '] Retry Count: ' + retryCount);
        }*/
        if (isMaxRetryReached) {
            return createErrorPayload(opp, 'Maximum retry attempts reached. Retry Count: ' + retryCount);
        }
        
        return createSuccessPayload(opp);
    }
    
    private String createErrorPayload(Opportunity opp, String errorMessage) {
        String finalMessage = String.isNotBlank(tracker?.Error_Details__c) ? tracker.Error_Details__c : errorMessage;
        Payload errorPayload = buildPayload(opp);
        errorPayload.exceptionMessage = finalMessage;
        return serializeAndLogPayload(errorPayload, 'Error Payload');
    }
    
    private String createSuccessPayload(Opportunity opp) {
        Payload successPayload = buildPayload(opp);
        //successPayload.amount = opp?.SBQQ__PrimaryQuote__r?.Amount_Received__c;
        return serializeAndLogPayload(successPayload, 'Success Payload');
    }
    
    private Payload buildPayload(Opportunity opp) {
        Payload payload = new Payload();
        populateCommonFields(payload, opp);
        return payload;
    }
    
    private String serializeAndLogPayload(Payload payload, String logPrefix) {
        String serialized = JSON.serialize(payload);
        String retryInfo = (logPrefix == 'Success Payload') ? '. Retry Count: ' + retryCount : '';
        createLog('Info', logPrefix + ': ' + serialized + retryInfo);
        return serialized;
    }
    
    private void populateCommonFields(Payload p, Opportunity opp) {
        p.opportunityId = opp?.Id;
        p.quoteId = opp?.SBQQ__PrimaryQuote__r?.Id;
        p.netSuiteCustomerId = this.payload?.order?.transaction_type != TransactionType.WEBSTORE_FREE_TRIAL.name() ? opp?.Account?.Netsuite_Id__c : null;
        p.requestTrackerId = tracker?.Id;
        p.orderId = this.payload != null ? this.payload.order?.Id : null;
        if (this.payload != null && this.payload.order?.transaction_type != TransactionType.WEBSTORE_FREE_TRIAL.name()) {
            // For non-free trial, assign amount as 0 (or any other logic as needed for free trial)
            p.amount = this.payload.quote?.amountReceived != null ? this.payload.quote.amountReceived : this.payload.opportunity?.amountReceived;
            p.stripeChargeId = String.isNotBlank(this.payload.quote?.stripeChargeId) ? this.payload.quote.stripeChargeId : this.payload.opportunity?.stripeChargeId;
            p.stripeIntentId = String.isNotBlank(this.payload.quote?.stripeIntentId) ? this.payload.quote.stripeIntentId : this.payload.opportunity?.stripeIntentId;
            p.paymentStatus = this.payload.order?.payment_status;
            p.paymentCurrency = opp?.currencyIsoCode;
        }
    }
    
    private void createLog(String logLevel, String logMessage) {
        transactionFinalizer.createLog(stepStatus + ': ' + logLevel, logMessage, DateTime.now(), DateTime.now());
    }
    
    public class Payload {
        public String orderId;
        public String quoteId;
        public String opportunityId;
        public String requestTrackerId;
        public String stripeIntentId;
        public String stripeChargeId;
        public String netSuiteCustomerId;
        public String paymentStatus;
        public String paymentCurrency;
        public String exceptionMessage; // Only for error payload
        public Decimal amount;          // Only for success payload
    }
}
public class OrderErrorResultToWorkato implements Queueable, Database.AllowsCallouts {
    private Request_Tracker__c tracker;
    private String stepStatus;
    private String errorMessage;
    private OrdersLogTransactionFinalizer transactionFinalizer;

    public OrderErrorResultToWorkato(Request_Tracker__c tracker, String stepStatus, String errorMessage) {
        this.tracker = tracker;
        this.stepStatus = stepStatus;
        this.errorMessage = errorMessage;
        this.transactionFinalizer = new OrdersLogTransactionFinalizer(tracker);
    }

    public void execute(QueueableContext context) {
        System.attachFinalizer(transactionFinalizer);
        
        try {
            Order_Processing_Settings__mdt settings = OrderUtil.getOrderProcessingSettings();
            if (settings == null) {
                log('Info', 'Order_Processing_Settings__mdt is null. Cannot proceed with Workato callout.');
                return;
            }

            OrderPayload payload = extractPayloadFromTracker();
            String requestBody = createRequestBody(payload);
            HttpRequest request = buildHttpRequest(requestBody, settings);

            log('Info', 'Sending request to Workato. Body: ' + requestBody);
            Http http = new Http();
            HttpResponse response = http.send(request);

            handleResponse(response, settings);
        } catch (Exception ex) {
            log('Error', 'Unexpected exception during Workato callout: ' + ex.getMessage());
        }
    }

    private OrderPayload extractPayloadFromTracker() {
        if (tracker == null || String.isBlank(tracker.Request__c)) {
            log('Error', 'Request_Tracker__c or its Request_Tracker__c.Request__c is missing.');
            return null;
        }

        try {
            return (OrderPayload) JSON.deserialize(tracker.Request__c, OrderPayload.class);
        } catch (Exception ex) {
            log('Error', 'Deserialization failed: ' + ex.getMessage());
            return null;
        }
    }

    private String createRequestBody(OrderPayload payload) {
        Payload workatoPayload = new Payload();
        Opportunity opp = OrderProcessorSingleton.getInstance().queryOpportunity(tracker?.Opportunity_Id__c);

        workatoPayload.exceptionMessage = errorMessage;
        workatoPayload.requestTrackerId = tracker?.Id;
        workatoPayload.opportunityId = opp?.Id;
        workatoPayload.quoteId = opp?.SBQQ__PrimaryQuote__r?.Id;
        workatoPayload.netSuiteCustomerId = opp?.Account?.Netsuite_Id__c;
        workatoPayload.paymentCurrency = opp?.CurrencyIsoCode;

        if (payload != null && payload.order != null) {
            workatoPayload.orderId = payload.order.Id;
            workatoPayload.paymentStatus = payload.order.payment_status;
        }

        if (payload != null) {
            workatoPayload.stripeIntentId = String.isNotBlank(payload.quote?.stripeIntentId) 
                                                ? payload.quote.stripeIntentId 
                                                : payload.opportunity?.stripeIntentId;
            workatoPayload.stripeChargeId = String.isNotBlank(payload.quote?.stripeChargeId) 
                                                ? payload.quote.stripeChargeId 
                                                : payload.opportunity?.stripeChargeId;
        }

        return JSON.serialize(workatoPayload);
    }

    private HttpRequest buildHttpRequest(String body, Order_Processing_Settings__mdt settings) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:' + settings.Named_Credential__c + settings.Endpoint__c);
        request.setMethod(settings.Http_Method__c);
        request.setHeader('Content-Type', settings.Content_Type__c);
        request.setHeader(settings.Header_Key__c, settings.Header_Value__c);
        request.setTimeout(Integer.valueOf(settings.Callout_Timeout__c));
        request.setBody(body);
        return request;
    }

    private void handleResponse(HttpResponse response, Order_Processing_Settings__mdt settings) {
        if (response == null) {
            log('Error', 'Received null response from Workato.');
            return;
        }

        Integer statusCode = response.getStatusCode();
        Boolean isSuccess = statusCode == settings.Status_Code__c;
        String logLevel = isSuccess ? 'Info' : 'Error';

        log(logLevel, String.format(
            'Workato Response:\nStatus Code: {0}\nStatus: {1}\nBody: {2}',
            new List<String>{ String.valueOf(statusCode), response.getStatus(), response.getBody() }
        ));
    }

    private void log(String level, String message) {
        transactionFinalizer.createLog(stepStatus + ': ' + level, message, DateTime.now(), DateTime.now());
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
        public String exceptionMessage;
        public Decimal amount;
    }
}
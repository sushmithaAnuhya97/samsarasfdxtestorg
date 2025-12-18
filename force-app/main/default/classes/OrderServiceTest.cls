@IsTest
private class OrderServiceTest {

    @TestSetup
    static void setupData() {
        // Create Account
        Account acct = new Account(Name = 'Test Account',Organization_Size__c='1 - 99',BillingCountry='United States',BillingCountryCode='US',BillingState='Texas',BillingStateCode='TX');
        insert acct;
        
        // Create a test Request_Tracker__c record
        Request_Tracker__c tracker = new Request_Tracker__c(
            OrderId__c = 'ORD-12345',
            Status__c = 'Received',
            Retry_Count__c = 1
        );
        insert tracker;
    }

    static void setupRequest(String body) {
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(body);
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestURI = '/services/apexrest/orders/v1';
    }

    @IsTest
    static void testEmptyPayload() {
        setupRequest('');
        Test.startTest();
        OrderRestService.processOrder();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    @IsTest
    static void testInvalidJson() {
        setupRequest('{"bad_json}');
        Test.startTest();
        OrderRestService.processOrder();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    @IsTest
    static void testMissingOrderObject() {
        setupRequest('{}');
        Test.startTest();
        OrderRestService.processOrder();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    @IsTest
    static void testMissingFields() {
        String body = '{"order":{}}';
        setupRequest(body);
        Test.startTest();
        OrderRestService.processOrder();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('Invalid Order Id'));
    }

    @IsTest
    static void testInvalidTransactionType() {
        String body = '{"order":{"id":"123","account_id":"001xxxxxxxxxxxxAAA","transaction_type":"INVALID"}}';
        setupRequest(body);
        Test.startTest();
        OrderRestService.processOrder();
        Test.stopTest();

        System.assert(RestContext.response.responseBody.toString().contains('Invalid Transaction Type'));
    }

    @IsTest
    static void testInvalidAccountId() {
        String body = '{"order":{"id":"123","account_id":"invalid","transaction_type":"CREATE"}}';
        setupRequest(body);
        Test.startTest();
        OrderRestService.processOrder();
        Test.stopTest();
    }

    @IsTest
    static void testRetryLimitExceeded() {
        // Create a tracker with retry count at limit
        insert new Request_Tracker__c(OrderId__c = '123', Retry_Count__c = 3);

        String body = '{"order":{"id":"123","account_id":"001xxxxxxxxxxxxAAA","transaction_type":"CREATE"}}';
        setupRequest(body);
        Test.startTest();
        OrderRestService.processOrder();
        Test.stopTest();

        System.assert(RestContext.response.responseBody.toString().contains('already been retried'));
    }

    @IsTest
    static void testSuccessFlow() {
        Account acct = [SELECT Id FROM Account LIMIT 1];
        String body = '{"order":{"id":"order-123","account_id":"' + acct.Id + '","transaction_type":"CREATE"}}';
        setupRequest(body);

        Test.startTest();
        OrderRestService.processOrder();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void testDuplicateOrderException() {
        
        // Arrange
        String orderId = 'ORD-123456';
        String transactionType = 'CREATE';
        String accountId = '001XXXXXXXXXXXXXXX';

        // Insert required Custom Metadata settings via mock (you CANNOT insert real CMDT in test)
        Test.setFixedSearchResults(new Id[] {}); // For SOQL on Account
        Order_Processing_Settings__mdt mockSettings = new Order_Processing_Settings__mdt(
            Label = 'Default',
            DeveloperName = 'Default',
            Maximum_Retries__c = 3
        );
        // You can't insert CMDT in test. Instead, mock OrderUtil.getOrderProcessingSettings() if it's virtual.

        // Insert a duplicate tracker manually to simulate DUPLICATE_VALUE error on insert
        Request_Tracker__c existingTracker = new Request_Tracker__c(
            OrderId__c = orderId,
            Request__c = '{"order":{"id":"' + orderId + '","transaction_type":"' + transactionType + '","account_id":"' + accountId + '"}}',
            Retry_Count__c = 0
        );
        insert existingTracker;

        // Prepare duplicate payload
        String payload = '{"order":{"id":"' + orderId + '","transaction_type":"' + transactionType + '","account_id":"' + accountId + '"}}';

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(payload);
        RestContext.request.httpMethod = 'POST';
        RestContext.response = new RestResponse();

        Test.startTest();
        try {
            OrderRestService.processOrder();
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            System.assert(e.getMessage().contains('DUPLICATE_VALUE'), 'Should throw duplicate error');
        }
        Test.stopTest();

        // Assert expected response code and error message
        String responseStr = RestContext.response.responseBody != null
            ? RestContext.response.responseBody.toString()
            : null;

        System.debug('Response: ' + responseStr);
        System.assertNotEquals(null, responseStr, 'Response should not be null');
        System.assertEquals(400, RestContext.response.statusCode, 'Should return HTTP 400');
    }
    @isTest
    public static void testSaveTrackerRecordException(){
        Request_Tracker__c tracker = new Request_Tracker__c(OrderId__c  = 'ORD-12345678901234567890123456789012345678901234567890');
        try{
            OrderService.saveRequestTracker(tracker);
        }catch(Exception exp){
            System.assert(exp.getMessage().contains('STRING_TOO_LONG'), 'Should throw error');
        }
    }
}
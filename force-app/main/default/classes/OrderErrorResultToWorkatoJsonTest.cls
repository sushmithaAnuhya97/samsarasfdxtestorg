@IsTest
private class OrderErrorResultToWorkatoJsonTest {
    private static String getMockPayload() {
        return '{"order":{"id":1014211,"payment_status":""},"account":{"autoRenewalOptOut":true},"opportunity":{"stripeIntentId":"seti_1RU8FsIbzZlMbYFSHEO7tyjV","stripeChargeId":"","currencyIsoCode":"USD"},"quote":{"stripeIntentId":"seti_1RU8FsIbzZlMbYFSHEO7tyjV","stripeChargeId":""}}';
    }
    
    private static Request_Tracker__c createMockTracker() {
        Request_Tracker__c tracker = new Request_Tracker__c(Request__c = getMockPayload(),Opportunity_Id__c = '006000000000001AAA');
        insert tracker;
        return tracker;
    }
    
    // Mock for a successful callout
    private class SuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('Success');
            res.setStatus('OK');
            return res;
        }
    }
    
    // Mock for null response
    private class NullMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(0); // invalid/unknown
            res.setStatus('');     // empty status
            res.setBody('');       // empty body
            return res;
        }
    }
    
    // Mock that throws an exception to cover catch block
    private class ThrowingMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new CalloutException('Simulated exception');
        }
    }
    
    @IsTest
    static void testSuccessCallout() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Request_Tracker__c tracker = createMockTracker();
        
        Test.startTest();
        System.enqueueJob(new OrderErrorResultToWorkato(tracker, 'FAILED', 'Test error message'));
        Test.stopTest();
    }
    
    @IsTest
    static void testNullHttpResponse() {
        Test.setMock(HttpCalloutMock.class, new NullMock());
        Request_Tracker__c tracker = createMockTracker();
        
        Test.startTest();
        System.enqueueJob(new OrderErrorResultToWorkato(tracker, 'FAILED', 'Test error message'));
        Test.stopTest();
    }
    
    @IsTest
    static void testHttpCalloutThrowsException() {
        Test.setMock(HttpCalloutMock.class, new ThrowingMock());
        Request_Tracker__c tracker = createMockTracker();
        
        Test.startTest();
        System.enqueueJob(new OrderErrorResultToWorkato(tracker, 'FAILED', 'Simulated failure'));
        Test.stopTest();
    }
}
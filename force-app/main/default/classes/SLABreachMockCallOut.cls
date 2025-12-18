@isTest
global class SLABreachMockCallOut implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"quote": {"id":1, "name":"test"}}');
        response.setStatusCode(200);
        return response;
    }
}
@isTest
global class DclHttpCalloutMock implements HttpCalloutMock{
    global HTTPResponse respond(HTTPRequest request){
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"error_code": 0, "error_message": "", "items": [{"item_number": "HW-VG34", "description": "Vehicle IoT Gateway", "available": 14963, "net_available": 14691, "inventory_type": "ZKTC", "min_quantity": 0, "dcl_quantity": 0, "lots": null}]}');
        response.setStatusCode(200);
        return response;
    }
}
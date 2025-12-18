/* 
 * Test Class : VCKHttpCalloutMock
 * Class Created: 01/18/2024 
 */
//GTMS-15414
@isTest
global class VCKHttpCalloutMock implements HttpCalloutMock{
    global HTTPResponse respond(HTTPRequest request){
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"total": 10, "length": 5, "Results": [{"skuCode": "HW-VG34", "productCode": "HW-VG34", "description": "Vehicle IoT Gateway", "qtyOnHand": 14963, "qtyInbound": 14691, "qtyReserved": 20, "qtyAvailable": 146910}]}');
        response.setStatusCode(200);
        return response;
    }
}